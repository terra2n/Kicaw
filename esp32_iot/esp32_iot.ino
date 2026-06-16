#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#define ENABLE_DATABASE
#include <FirebaseClient.h>
#include "secrets.h"        // WiFi & Firebase credentials
#include "firebase_cmd.h"   // Radar configuration via Firebase


// =========================================================================
// 1. KONFIGURASI PIN HARDWARE (Sesuai Rangkaian Kelompok 5)
// =========================================================================
const int PIN_RADAR    = 14;   // OUT Sensor Radar -> GPIO 14 (digital)
const int PIN_RELAY    = 27;   // IN1 Relay -> GPIO 27
// PIN_RADAR_RX dan PIN_RADAR_TX didefinisikan di ld2410_uart.h

// =========================================================================
// 2. KUNCI JARAK RADAR (GATE 0 = Radius < 75 cm)
// =========================================================================
const byte BATAS_GERBANG_JARAK = 0;

// =========================================================================
// 3. KONFIGURASI PARAMETER AUDIT ENERGI
// =========================================================================
const float DAYA_LAMPU_WATT   = 3.0;
const float FAKTOR_EMISI_GRID = 0.85;

// Threshold counter (delay loop = 50 ms):
// - HIGH stabil 10x (0.5 detik) -> nyalakan lampu
// - LOW  stabil 20x (1.0 detik) -> matikan lampu
const int THRESHOLD_MASUK  = 10;
const int THRESHOLD_KOSONG = 20;

// =========================================================================
// 4. KREDENSIAL WiFi & FIREBASE
// =========================================================================
// Kredensial disimpan di file secrets.h (lihat secrets.example.h)
// File secrets.h sudah di-gitignore untuk keamanan

// =========================================================================
// 5. VARIABEL KONTROL & TIMER INTERNAL
// =========================================================================
bool  lampuNyala       = false;
int   hitungLow        = 0;
int   hitungHigh       = 0;
unsigned long waktuMulaiMati = 0;
float totalEnergi_Wh   = 0.0;
float totalCO2_mg      = 0.0;

unsigned long lastUpdateFirebase = 0;

// =========================================================================
// 6. OBJEK FIREBASE
// =========================================================================
bool firebaseReady = false;
unsigned long lastWiFiRetry = 0;
const unsigned long WIFI_RETRY_INTERVAL_MS = 15000;
NoAuth noAuth;
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient async_client(ssl_client);
RealtimeDatabase Database;

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
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("[WIFI] DISCONNECTED");
      break;
    default:
      Serial.print("[WIFI] EVENT: ");
      Serial.println((int)event);
      break;
  }
}

// =========================================================================
// FUNGSI: Konfigurasi jarak radar HLK-LD2410C via UART
// (Refactored: pakai library ld2410_uart.h)
// =========================================================================
void konfigurasiJarakRadarFisik(byte gateTerap) {
  Serial.println("[RADAR] Mengunci jangkauan ke Gate 0 (< 75cm)...");

  if (radarSetMaxGate(gateTerap, gateTerap, 5)) {
    Serial.println("[SUCCESS] Konfigurasi selesai!");
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
// FUNGSI: Push data ke Firebase
// =========================================================================
void pushKeFirebase() {
  if (!app.ready()) return;

  // Hitung total real-time (akumulasi + durasi mati berjalan)
  float totalWh = totalEnergi_Wh;
  float totalMg = totalCO2_mg;

  if (!lampuNyala && waktuMulaiMati > 0) {
    unsigned long durasiMati_ms = millis() - waktuMulaiMati;
    float durasiMati_jam = (float)durasiMati_ms / 3600000.0;
    float energiBerjalan_Wh = DAYA_LAMPU_WATT * durasiMati_jam;
    float co2Berjalan_mg = (energiBerjalan_Wh / 1000.0) * FAKTOR_EMISI_GRID * 1000000.0;
    totalWh += energiBerjalan_Wh;
    totalMg += co2Berjalan_mg;
  }

  Database.set<bool>(async_client, "ruangan_01/status_lampu", lampuNyala);
  Database.set<bool>(async_client, "ruangan_01/status_radar", lampuNyala);
  Database.set<float>(async_client, "ruangan_01/energi_dihemat_wh", totalWh);
  Database.set<float>(async_client, "ruangan_01/co2_dicegah_mg", totalMg);
}

// =========================================================================
// FUNGSI: Sambung WiFi dengan timeout
// =========================================================================
bool connectWiFi(unsigned long timeoutMs = 15000) {
  if (WiFi.status() == WL_CONNECTED) return true;

  WiFi.disconnect(true, true);
  delay(100);
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Menghubungkan ke Wi-Fi");
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < timeoutMs) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Terhubung! IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("[WIFI] SSID: ");
    Serial.println(WiFi.SSID());
    Serial.print("[WIFI] BSSID: ");
    Serial.println(WiFi.BSSIDstr());
    Serial.print("[WIFI] Channel: ");
    Serial.println(WiFi.channel());
    Serial.print("[WIFI] RSSI: ");
    Serial.println(WiFi.RSSI());
    return true;
  }

  wl_status_t status = WiFi.status();
  Serial.print("[WARN] WiFi gagal connect. Status: ");
  Serial.println((int)status);

  int networks = WiFi.scanNetworks();
  bool found = false;
  for (int i = 0; i < networks; i++) {
    if (WiFi.SSID(i) == WIFI_SSID) {
      found = true;
      Serial.print("[INFO] SSID ditemukan di scan: ");
      Serial.print(WiFi.SSID(i));
      Serial.print(" | RSSI: ");
      Serial.println(WiFi.RSSI(i));
      break;
    }
  }

  if (!found) {
    Serial.println("[INFO] SSID hotspot tidak terdeteksi saat scan.");
    Serial.println("[HINT] Nama hotspot tidak muncul atau bukan 2.4GHz.");
  } else {
    Serial.println("[HINT] SSID terlihat, tapi koneksi gagal.");
    Serial.println("[HINT] Kemungkinan password salah atau security mode tidak cocok.");
  }

  if (status == WL_CONNECT_FAILED) {
    Serial.println("[ERROR] Password/auth failed.");
  } else if (status == WL_NO_SSID_AVAIL) {
    Serial.println("[ERROR] SSID not available.");
  } else {
    Serial.println("[ERROR] Unknown WiFi issue.");
  }

  WiFi.scanDelete();

  Serial.println("[INFO] Pastikan hotspot 2.4GHz aktif dan password benar.");
  return false;
}

// =========================================================================
// FUNGSI: Inisialisasi Firebase
// =========================================================================
bool initFirebaseServices() {
  if (WiFi.status() != WL_CONNECTED) return false;
  if (firebaseReady) return true;

  ssl_client.setInsecure();
  ssl_client.setConnectionTimeout(1000);
  ssl_client.setHandshakeTimeout(5);

  initializeApp(async_client, app, getAuth(noAuth));
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);

  Serial.println("Berhasil terhubung ke Firebase!");
  Serial.println("------------------------------------------------");

  setupFirebaseCommands();
  pushKeFirebase();
  firebaseReady = true;
  return true;
}

// =========================================================================
// SETUP
// =========================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  WiFi.onEvent(onWiFiEvent);

  Serial.println("================================================");
  Serial.println("  SISTEM HEMAT ENERGI OTOMATIS - KELOMPOK 5");
  Serial.println("  ESP32 + HLK-LD2410C + Firebase");
  Serial.println("================================================");

  konfigurasiJarakRadarFisik(BATAS_GERBANG_JARAK);

  pinMode(PIN_RADAR, INPUT);
  pinMode(PIN_RELAY, OUTPUT);
  digitalWrite(PIN_RELAY, HIGH);

  hitungLow      = 0;
  hitungHigh     = 0;
  lampuNyala     = false;
  waktuMulaiMati = millis();

  Serial.println("  Status Awal : LAMPU MATI");
  Serial.println("  Daya Lampu  : 3 Watt");
  Serial.println("------------------------------------------------");

  // --- Koneksi WiFi ---
  if (!connectWiFi()) {
    Serial.println("[WARN] Sistem lanjut tanpa Firebase sampai WiFi tersambung.");
  }

  // --- Koneksi Firebase ---
  if (WiFi.status() == WL_CONNECTED) {
    initFirebaseServices();
  } else {
    Serial.println("[INFO] Firebase akan dicoba lagi saat WiFi sudah connect.");
  }
}

// =========================================================================
// PROSES SETELAH FIREBASE CONNECT — Setup command listener
// =========================================================================
void setupFirebaseCommands() {
  if (!app.ready()) return;
  Database.set<String>(async_client, FB_CMD_PATH, "none");
  Database.set<String>(async_client, FB_CMD_STATUS, "idle");
  Database.set<String>(async_client, FB_CMD_PARAMS, "{}");
  Database.set<uint32_t>(async_client, FB_RADAR_CFG "/command_ts", 0);
  Serial.println("[CMD] Firebase command paths initialized");
}

// =========================================================================
// LOOP UTAMA
// =========================================================================
void loop() {
  if (!firebaseReady) {
    if (WiFi.status() == WL_CONNECTED) {
      initFirebaseServices();
    } else if (millis() - lastWiFiRetry >= WIFI_RETRY_INTERVAL_MS) {
      lastWiFiRetry = millis();
      Serial.println("[INFO] Retry koneksi WiFi...");
      if (connectWiFi(10000)) {
        initFirebaseServices();
      }
    }
  }

  if (firebaseReady) {
    app.loop();
  }

  unsigned long sekarang = millis();

  // Cek command dari Firebase (setiap 500ms)
  if (firebaseReady) {
    cmdCheckFirebase();
  }

  // Engineering mode loop (setiap 1 detik)
  if (firebaseReady) {
    cmdEngineeringLoop();
  }

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
    }

    Serial.println("[STATUS] Orang Terdeteksi. Lampu Menyala.");
    Serial.println("------------------------------------------------");

    pushKeFirebase();
  }

  // ── KONDISI MATI: LOW stabil >= 20x (~1 detik) ──
  if (hitungLow >= THRESHOLD_KOSONG && lampuNyala) {
    digitalWrite(PIN_RELAY, HIGH);
    lampuNyala     = false;
    waktuMulaiMati = sekarang;
    hitungHigh     = 0;

    Serial.println("[STATUS] Kosong (1 Detik). Lampu Dimatikan.");
    Serial.println("------------------------------------------------");

    pushKeFirebase();
  }

  // ── MONITORING & UPDATE FIREBASE setiap 5 detik saat lampu mati ──
  if (sekarang - lastUpdateFirebase >= 5000) {
    lastUpdateFirebase = sekarang;

    float totalWh = totalEnergi_Wh;
    float totalMg = totalCO2_mg;

    if (!lampuNyala && waktuMulaiMati > 0) {
      float durasi_jam     = (sekarang - waktuMulaiMati) / 3600000.0;
      float energiBerjalan = DAYA_LAMPU_WATT * durasi_jam;
      float co2Berjalan    = (energiBerjalan / 1000.0) * FAKTOR_EMISI_GRID * 1000000.0;
      totalWh += energiBerjalan;
      totalMg += co2Berjalan;
    }

    Serial.print("[MONITORING] Energi Hemat: ");
    Serial.print(totalWh, 4);
    Serial.print(" Wh | CO2 Dicegah: ");
    Serial.print(totalMg, 2);
    Serial.println(" mg");

    pushKeFirebase();
  }

  delay(50);
}
