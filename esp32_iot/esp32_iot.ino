#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#define ENABLE_DATABASE
#include <FirebaseClient.h>
#include "firebase_cmd.h"  // Radar configuration via Firebase


// =========================================================================
// 1. KONFIGURASI PIN HARDWARE (Sesuai Rangkaian Kelompok 5)
// =========================================================================
const int PIN_RADAR    = 14;   // OUT Sensor Radar -> GPIO 14 (digital)
const int PIN_RELAY    = 27;   // IN1 Relay -> GPIO 27
const int PIN_RADAR_RX = 16;   // UART RX Radar -> GPIO 16
const int PIN_RADAR_TX = 17;   // UART TX Radar -> GPIO 17

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
// 4. KREDENSIAL WiFi & FIREBASE (ISI SESUAI MILIK ANDA)
// =========================================================================
#define WIFI_SSID "NAMA_WIFI_ANDA"
#define WIFI_PASSWORD "PASSWORD_WIFI_ANDA"
#define API_KEY "AIzaSyC4Xkz95z-hRSMszA4VUi8mLARpd7QdVFc"
#define DATABASE_URL "https://kicaw-smart-room-default-rtdb.firebaseio.com"

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
NoAuth noAuth;
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient async_client(ssl_client);
RealtimeDatabase Database;

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
// SETUP
// =========================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

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
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Menghubungkan ke Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Terhubung! IP: ");
  Serial.println(WiFi.localIP());

  // --- Koneksi Firebase ---
  ssl_client.setInsecure();
  ssl_client.setConnectionTimeout(1000);
  ssl_client.setHandshakeTimeout(5);

  initializeApp(async_client, app, getAuth(noAuth));
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);

  Serial.println("Berhasil terhubung ke Firebase!");
  Serial.println("------------------------------------------------");

  // Setup Firebase command listener
  setupFirebaseCommands();

  pushKeFirebase();
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
  app.loop();

  unsigned long sekarang = millis();

  // Cek command dari Firebase (setiap 500ms)
  cmdCheckFirebase();

  // Engineering mode loop (setiap 1 detik)
  cmdEngineeringLoop();

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
