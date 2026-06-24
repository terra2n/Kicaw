#include <Arduino.h>

// =========================================================================
// FITUR: JIKA UART RADAR BERMASALAH (ATAU BELUM DIHUBUNGKAN TX/RX-NYA),
// SEHINGGA MUNCUL ERROR [UART] No response from radar, ANDA BISA MENJADIKAN
// BARIS DI BAWAH SEBAGAI KOMENTAR (DENGAN MENAMBAHKAN // DI DEPANNYA).
// JIKA DI-NONAKTIFKAN, ESP32 HANYA AKAN MEMBACA GERAKAN LEWAT PIN DIGITAL OUT (GPIO 14).
// =========================================================================
#define USE_RADAR_UART
#define ENABLE_USER_AUTH
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <esp_task_wdt.h>
#include <Preferences.h>
#include <time.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#define ENABLE_DATABASE
#include <FirebaseClient.h>
#include "secrets.h"              // WiFi, Firebase & Supabase credentials
#include "firebase_cmd.h"         // Radar configuration via Firebase
#include "supabase_client.h"      // Supabase client library


// =========================================================================
// 1. KONFIGURASI PIN HARDWARE (Sesuai Rangkaian Kelompok 5)
// =========================================================================
const int PIN_RADAR    = 14;   // OUT Sensor Radar -> GPIO 14 (digital)
const int PIN_RELAY    = 27;   // IN1 Relay -> GPIO 27
// PIN_RADAR_RX dan PIN_RADAR_TX didefinisikan di ld2410_uart.h

// =========================================================================
// 2. DEFAULT GATE RADAR (disimpan ke NVS, bisa diubah dari Flutter)
// =========================================================================
// Gate 0 = radius < 75cm (paling dekat, cocok untuk area ~45cm)
// Gate 1 = radius 75-150cm, Gate 8 = 600-675cm (jangkauan penuh)
const byte BATAS_GERBANG_DEFAULT = 0;  // Default: Gate 0 (~45-75cm)

// =========================================================================
// 3. KONFIGURASI PARAMETER AUDIT ENERGI
// =========================================================================
const float DAYA_LAMPU_WATT   = 3.0;
const float FAKTOR_EMISI_GRID = 0.85;

// Threshold counter (delay loop = 50 ms):
// - HIGH stabil 10x (0.5 detik) -> nyalakan lampu
// - LOW  stabil 5x  (0.25 detik) -> matikan lampu
const int THRESHOLD_MASUK  = 1;
const int THRESHOLD_KOSONG = 1;

// =========================================================================
// 4. KREDENSIAL WiFi, FIREBASE & SUPABASE
// =========================================================================
// Semua kredensial disimpan di file secrets.h (WiFi + Firebase + Supabase)
// File secrets.h sudah di-gitignore untuk keamanan

// =========================================================================
// 5. VARIABEL KONTROL & TIMER INTERNAL
// =========================================================================
bool  lampuNyala       = false;
bool  radarTerdeteksi  = false;
unsigned long lastLampToggle = 0;
int   hitungLow        = 0;
int   hitungHigh       = 0;
unsigned long waktuMulaiMati = 0;
float totalEnergi_Wh   = 0.0;
float totalCO2_mg      = 0.0;
byte  radarMaxGate     = BATAS_GERBANG_DEFAULT;

unsigned long lastUpdateFirebase = 0;
unsigned long lastUpdateSupabase = 0;
const unsigned long SUPABASE_UPDATE_INTERVAL = 5000;  // 5 detik

Preferences prefs;
unsigned long lastSaveNVS = 0;
const unsigned long NVS_SAVE_INTERVAL_MS = 60000;

// =========================================================================
// 6. OBJEK FIREBASE & SUPABASE
// =========================================================================
bool firebaseReady = false;
bool supabaseReady = false;
bool initialConfigPushed = false;  // One-time radar config push after Firebase ready
unsigned long lastWiFiRetry = 0;
const unsigned long WIFI_RETRY_INTERVAL_MS = 15000;
unsigned long wifiRetryInterval = WIFI_RETRY_INTERVAL_MS;
const unsigned long WIFI_CONNECT_TIMEOUT_MS = 15000;
unsigned long wifiConnectStart = 0;

enum WiFiState { WIFI_IDLE, WIFI_CONNECTING, WIFI_CONNECTED, WIFI_FAILED };
WiFiState wifiState = WIFI_IDLE;
firebase_ns::UserAuth userAuth(API_KEY, FIREBASE_AUTH_EMAIL, FIREBASE_AUTH_PASSWORD);
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient async_client(ssl_client);
RealtimeDatabase Database;

// Supabase Client - akan diinisialisasi di setup()
SupabaseClient* supabaseClient = nullptr;

void onWiFiEvent(WiFiEvent_t event) {
  switch (event) {
    case ARDUINO_EVENT_WIFI_READY:
      Serial.println("[WIFI] READY");
      break;
    case ARDUINO_EVENT_WIFI_STA_START:
      Serial.println("[WIFI] STA START");
      break;
    case ARDUINO_EVENT_WIFI_STA_CONNECTED:
      Serial.println("[WIFI] CONNECTED TO AP");
      break;
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("[WIFI] GOT IP: ");
      Serial.println(WiFi.localIP());
      wifiState = WIFI_CONNECTED;
      wifiRetryInterval = WIFI_RETRY_INTERVAL_MS;
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("[WIFI] DISCONNECTED");
      if (wifiState == WIFI_CONNECTING || wifiState == WIFI_CONNECTED) {
        wifiState = WIFI_FAILED;
      }
      break;
    default:
      Serial.print("[WIFI] EVENT: ");
      Serial.println((int)event);
      break;
  }
}

// =========================================================================
// FUNGSI: Konfigurasi jarak radar HLK-LD2410C via UART
// Default = gate 0 (<75cm, sekitar 45cm), bisa diubah dari Flutter.
// Konfigurasi disimpan di NVS agar persisten setelah reboot.
// =========================================================================
void konfigurasiJarakRadarFisik(byte gateTerap) {
  Serial.print("[RADAR] Mengatur jangkauan ke Gate ");
  Serial.print(gateTerap);
  Serial.print(" (<");
  Serial.print((gateTerap + 1) * 75);
  Serial.println("cm)...");

  if (radarSetMaxGate(gateTerap, gateTerap, 1)) {
    Serial.println("[SUCCESS] Konfigurasi gate berhasil!");
    radarMaxGate = gateTerap;
    // Simpan ke NVS agar persisten setelah reboot
    prefs.putInt("radar_gate", gateTerap);
    Serial.print("[NVS] Gate tersimpan: "); Serial.println(gateTerap);
  } else {
    Serial.println("[WARN] Radar mungkin tidak merespon, lanjut...");
  }

  // Verifikasi konfigurasi
  delay(200);
  RadarConfig cfg;
  if (radarBacaKonfigurasi(&cfg)) {
    Serial.print("[RADAR] Max gate terkonfirmasi: moving=");
    Serial.print(cfg.max_moving_gate);
    Serial.print(" stationary=");
    Serial.println(cfg.max_stationary_gate);
  }
}

// =========================================================================
// FUNGSI: NTP Timestamp (WIB = UTC+7)
// =========================================================================
String getTimestamp() {
  time_t now = time(nullptr);
  if (now < 100000) return "syncing";
  struct tm *t = localtime(&now);
  char buf[20];
  strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", t);
  return String(buf);
}

// =========================================================================
// FUNGSI: Hitung total energi real-time (akumulasi + durasi mati berjalan)
// =========================================================================
void hitungTotalEnergi(float &totalWh, float &totalMg) {
  totalWh = totalEnergi_Wh;
  totalMg = totalCO2_mg;

  if (!lampuNyala && waktuMulaiMati > 0) {
    unsigned long durasiMati_ms = millis() - waktuMulaiMati;
    float durasiMati_jam = (float)durasiMati_ms / 3600000.0;
    float energiBerjalan_Wh = DAYA_LAMPU_WATT * durasiMati_jam;
    float co2Berjalan_mg = (energiBerjalan_Wh / 1000.0) * FAKTOR_EMISI_GRID * 1000000.0;
    totalWh += energiBerjalan_Wh;
    totalMg += co2Berjalan_mg;
  }
}

// =========================================================================
// FUNGSI: Push data ke Firebase
// =========================================================================
void pushKeFirebase() {
  if (!app.ready()) return;
  esp_task_wdt_reset();

  float totalWh, totalMg;
  hitungTotalEnergi(totalWh, totalMg);

  uint16_t jarakCm = radarTerdeteksi
      ? (radarMaxGate * 75 + 37) : 0;

  Database.set<bool>(async_client, "ruangan_01/status_lampu", lampuNyala);
  esp_task_wdt_reset();
  Database.set<bool>(async_client, "ruangan_01/status_radar", radarTerdeteksi);
  esp_task_wdt_reset();
  Database.set<uint16_t>(async_client, "ruangan_01/radar_distance_cm", jarakCm);
  esp_task_wdt_reset();
  Database.set<float>(async_client, "ruangan_01/energi_dihemat_wh", totalWh);
  esp_task_wdt_reset();
  Database.set<float>(async_client, "ruangan_01/co2_dicegah_mg", totalMg);
  esp_task_wdt_reset();

  // Push waktu_mulai_mati (epoch timestamp saat lampu mati)
  // Cloud Functions pakai ini buat hitung durasi lampu OFF
  if (waktuMulaiMati > 0 && lampuNyala == false) {
    // Lampu mati, push timestamp epoch
    time_t now = time(nullptr);
    if (now > 100000) {
      uint32_t epochMati = (uint32_t)(now - (millis() - waktuMulaiMati) / 1000);
      Database.set<uint32_t>(async_client, "ruangan_01/waktu_mulai_mati", epochMati);
      esp_task_wdt_reset();
    }
  } else {
    // Lampu nyala, clear timestamp
    Database.set<uint32_t>(async_client, "ruangan_01/waktu_mulai_mati", 0);
    esp_task_wdt_reset();
  }

  // Heartbeat: epoch seconds biar Flutter bisa detect kalau ESP mati
  time_t now = time(nullptr);
  if (now > 100000) { // NTP synced
    Database.set<uint32_t>(async_client, "ruangan_01/last_heartbeat",
        (uint32_t)now);
    esp_task_wdt_reset();
  }
  Database.set<String>(async_client, "ruangan_01/last_heartbeat_ts", getTimestamp());
  esp_task_wdt_reset();
}


// =========================================================================
// FUNGSI: Log activity ke Supabase (motion/lamp changes)
// =========================================================================
void logActivitySupabase(const String& eventType, const String& description) {
  if (!supabaseClient) return;

  bool success = supabaseClient->insertActivityLog(eventType, description);

  if (success) {
    Serial.printf("[SUPABASE] Activity logged: %s\n", eventType.c_str());
  }
}

// =========================================================================
// FUNGSI: Push data sensor dan room status ke Supabase
// =========================================================================
void pushKeSupabase() {
  if (!supabaseReady || !supabaseClient) return;

  // Update room status (UPSERT)
  supabaseClient->updateRoomStatus(lampuNyala, radarTerdeteksi);

  // Insert historical sensor log
  supabaseClient->insertSensorLog(lampuNyala, radarTerdeteksi);
}

// =========================================================================
// FUNGSI: Sambung WiFi dengan timeout
// =========================================================================
bool connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    wifiState = WIFI_CONNECTED;
    return true;
  }

  WiFi.disconnect(true, true);
  delay(100);
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  wifiState = WIFI_CONNECTING;
  wifiConnectStart = millis();

  Serial.print("[WIFI] Connecting to ");
  Serial.println(WIFI_SSID);
  return false;
}

// =========================================================================
// FUNGSI: Inisialisasi Firebase
// =========================================================================
bool initFirebaseServices() {
  if (WiFi.status() != WL_CONNECTED) return false;
  if (firebaseReady) return true;

  configTime(7 * 3600, 0, "pool.ntp.org", "time.google.com");
  Serial.println("[NTP] Syncing time (WIB)...");

  ssl_client.setInsecure();
  ssl_client.setConnectionTimeout(1000);
  ssl_client.setHandshakeTimeout(5);

  initializeApp(async_client, app, getAuth(userAuth));
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);

  Serial.println("Berhasil terhubung ke Firebase!");
  Serial.println("------------------------------------------------");

  pushKeFirebase();
  firebaseReady = true;
  return true;
}

// =========================================================================
// FUNGSI: Inisialisasi Supabase
// =========================================================================
void initSupabase() {
  if (WiFi.status() != WL_CONNECTED) return;
  if (supabaseClient) return;

  Serial.println("[SUPABASE] Initializing client...");
  supabaseClient = new SupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  // Test koneksi
  if (supabaseClient->testConnection()) {
    Serial.println("[SUPABASE] Connection successful!");
    supabaseReady = true;
  } else {
    Serial.println("[SUPABASE] Connection failed!");
    supabaseReady = false;
  }
}

// =========================================================================
// SETUP
// =========================================================================
void setup() {
  esp_task_wdt_config_t wdt_config = {
    .timeout_ms = 60000,
    .idle_core_mask = 0x3,
    .trigger_panic = true
  };
  esp_task_wdt_reconfigure(&wdt_config);
  esp_task_wdt_add(NULL);

  Serial.begin(115200);
  delay(1000);

  WiFi.onEvent(onWiFiEvent);

  Serial.println("================================================");
  Serial.println("  SISTEM HEMAT ENERGI OTOMATIS - KELOMPOK 5");
  Serial.println("  ESP32 + HLK-LD2410C + Firebase");
  Serial.println("================================================");

#ifdef USE_RADAR_UART
  Serial.println("[DEBUG] === ESP32 INFO ===");
  Serial.print("PSRAM Size: "); Serial.println(ESP.getPsramSize());
  Serial.print("Free Heap: "); Serial.println(ESP.getFreeHeap());
  Serial.print("Chip Model: "); Serial.println(ESP.getChipModel());
  Serial.print("Chip Revision: "); Serial.println(ESP.getChipRevision());
  Serial.println("[DEBUG] Initializing Radar UART...");
  radarInit();
  delay(500);
  Serial.println("[DEBUG] Testing UART with firmware version read...");
  uint8_t major, minor;
  uint32_t bugfix;
  if (radarBacaFirmware(&major, &minor, &bugfix)) {
    Serial.println("[DEBUG] UART BERHASIL - Radar firmware detected!");
  } else {
    Serial.println("[DEBUG] UART GAGAL - No response from radar");
  }
#endif

  // Buka NVS sekali di sini (namespace 'energi' untuk energi + radar_gate)
  prefs.begin("energi");

#ifdef USE_RADAR_UART
  // Load gate radar dari NVS (default = BATAS_GERBANG_DEFAULT jika belum pernah disimpan)
  radarMaxGate = (byte)prefs.getInt("radar_gate", BATAS_GERBANG_DEFAULT);
  Serial.print("[NVS] Load radar gate: "); Serial.println(radarMaxGate);
  konfigurasiJarakRadarFisik(radarMaxGate);
#endif

  pinMode(PIN_RADAR, INPUT);
  pinMode(PIN_RELAY, OUTPUT);
  digitalWrite(PIN_RELAY, HIGH);

  hitungLow      = 0;
  hitungHigh     = 0;
  lampuNyala     = false;
  waktuMulaiMati = 0;  // [ESP-C5 fix] 0 = belum ada baseline; guard (> 0) mencegah phantom energy saat boot

  // Load data energi dari NVS (prefs sudah dibuka di atas)
  totalEnergi_Wh = prefs.getFloat("wh", 0.0);
  totalCO2_mg = prefs.getFloat("co2", 0.0);
  Serial.print("  Energi tersimpan: ");
  Serial.print(totalEnergi_Wh, 4);
  Serial.print(" Wh | CO2: ");
  Serial.print(totalCO2_mg, 2);
  Serial.println(" mg");

  Serial.println("  Status Awal : LAMPU MATI");
  Serial.println("  Daya Lampu  : 3 Watt");
  Serial.println("------------------------------------------------");

  // --- DIAG: Cek apakah ada data di UART radar ---
  delay(100);
  int radarAvail = RadarSerial.available();
  int radarOut = digitalRead(PIN_RADAR);
  Serial.print("[DIAG] RadarSerial.available="); Serial.print(radarAvail);
  Serial.print(" | OUT(pin14)="); Serial.println(radarOut ? "HIGH" : "LOW");

  // --- Koneksi WiFi (non-blocking) ---
  connectWiFi();

  // Inisialisasi Supabase (setelah WiFi terhubung)
  initSupabase();
}

// =========================================================================
// LOOP UTAMA
// =========================================================================
void loop() {
  esp_task_wdt_reset();

  // ── WiFi State Machine ──
  switch (wifiState) {
    case WIFI_IDLE:
      connectWiFi();
      break;

    case WIFI_CONNECTING:
      if (millis() - wifiConnectStart >= WIFI_CONNECT_TIMEOUT_MS) {
        Serial.println("[WIFI] Connect timeout");
        wifiState = WIFI_FAILED;
        lastWiFiRetry = millis();
        wifiRetryInterval = min(wifiRetryInterval * 2, 300000UL);
      }
      break;

    case WIFI_CONNECTED:
      if (!firebaseReady) {
        initFirebaseServices();
      }
      // Push radar config ke Firebase setelah Firebase siap (sekali saja)
      if (firebaseReady && !initialConfigPushed) {
#ifdef USE_RADAR_UART
        RadarConfig cfg;
        if (radarBacaKonfigurasi(&cfg)) {
          cmdPushConfigResult(&cfg);
          Serial.println("[RADAR] Initial config pushed to Firebase");
        }
#endif
        initialConfigPushed = true;
      }
      if (!supabaseReady) {
        static unsigned long lastSupabaseRetry = 0;
        unsigned long nowMs = millis();
        if (nowMs - lastSupabaseRetry >= 30000 || lastSupabaseRetry == 0) {
          lastSupabaseRetry = nowMs;
          if (supabaseClient) {
            delete supabaseClient;
            supabaseClient = nullptr;
          }
          initSupabase();
        }
      }
      break;

    case WIFI_FAILED:
      if (millis() - lastWiFiRetry >= wifiRetryInterval) {
        Serial.print("[WIFI] Retry (interval ");
        Serial.print(wifiRetryInterval / 1000);
        Serial.println("s)");
        connectWiFi();
      }
      break;
  }

  if (firebaseReady) {
    app.loop();
  }

  unsigned long sekarang = millis();

  // Engineering mode loop (setiap 1 detik)
#ifdef USE_RADAR_UART
  if (firebaseReady) {
    cmdEngineeringLoop();
  }
#endif

  int rawRadar = digitalRead(PIN_RADAR);

  // ── Stabilisasi counter ──
  if (rawRadar == HIGH) {
    hitungHigh++;
    hitungLow = 0;
    if (hitungHigh > THRESHOLD_MASUK + 1)
      hitungHigh = THRESHOLD_MASUK + 1;
  } else {
    hitungLow++;
    hitungHigh = 0;
    if (hitungLow > THRESHOLD_KOSONG + 1)
      hitungLow = THRESHOLD_KOSONG + 1;
  }

  // ── KONDISI NYALA: HIGH stabil >= 10x (~0.5 detik) ──
  if (hitungHigh >= THRESHOLD_MASUK && !lampuNyala) {
    digitalWrite(PIN_RELAY, LOW);
    lampuNyala = true;
    radarTerdeteksi = true;
    hitungLow  = 0;

    // Audit energi selama periode mati sebelumnya
    if (waktuMulaiMati > 0) {
      unsigned long durasi_ms = sekarang - waktuMulaiMati;
      float durasi_jam        = durasi_ms / 3600000.0;
      float energi_Wh         = DAYA_LAMPU_WATT * durasi_jam;
      float co2_mg            = (energi_Wh / 1000.0) * FAKTOR_EMISI_GRID * 1000000.0;
      totalEnergi_Wh         += energi_Wh;
      totalCO2_mg            += co2_mg;

      Serial.println("------------------------------------------------");
      Serial.print  ("  Mati selama    : ");
      Serial.print  (durasi_ms / 1000);
      Serial.println(" detik");
      Serial.print  ("  Energi dihemat : ");
      Serial.print  (energi_Wh, 4);
      Serial.println(" Wh");
      Serial.print  ("  Reduksi CO2    : ");
      Serial.print  (co2_mg, 2);
      Serial.println(" mg");
      Serial.println("------------------------------------------------");
      waktuMulaiMati = 0;

      prefs.putFloat("wh", totalEnergi_Wh);
      prefs.putFloat("co2", totalCO2_mg);
      lastSaveNVS = sekarang;
    }

    Serial.println("[STATUS] Orang Terdeteksi. Lampu Menyala.");
    Serial.println("------------------------------------------------");

    // Log activity ke Supabase
    if (supabaseReady) {
      logActivitySupabase("lamp_on", "Lampu menyala karena ada orang terdeteksi");
    }
  }

  // ── KONDISI MATI: LOW stabil >= 5x (~0.25 detik) ──
  if (hitungLow >= THRESHOLD_KOSONG && lampuNyala) {
    digitalWrite(PIN_RELAY, HIGH);
    lampuNyala     = false;
    radarTerdeteksi = false;
    waktuMulaiMati = sekarang;
    hitungHigh     = 0;

    Serial.println("[STATUS] Kosong (1 Detik). Lampu Dimatikan.");
    Serial.println("------------------------------------------------");

    // Log activity ke Supabase
    if (supabaseReady) {
      logActivitySupabase("lamp_off", "Lampu dimatikan karena tidak ada orang");
    }
  }

  // ── MONITORING & UPDATE FIREBASE setiap 5 detik ──
  if (sekarang - lastUpdateFirebase >= 5000) {
    lastUpdateFirebase = sekarang;

    float totalWh, totalMg;
    hitungTotalEnergi(totalWh, totalMg);

    Serial.print("[MONITORING] Energi Hemat: ");
    Serial.print(totalWh, 4);
    Serial.print(" Wh | CO2 Dicegah: ");
    Serial.print(totalMg, 2);
    Serial.println(" mg");

    pushKeFirebase();

    // Push ke Supabase setiap 5 detik
    if (supabaseReady) {
      pushKeSupabase();
    }
  }

  // ── Periodic NVS save (every 60 seconds) ──
  if (sekarang - lastSaveNVS >= NVS_SAVE_INTERVAL_MS) {
    lastSaveNVS = sekarang;
    prefs.putFloat("wh", totalEnergi_Wh);
    prefs.putFloat("co2", totalCO2_mg);
  }

  delay(50);
}
