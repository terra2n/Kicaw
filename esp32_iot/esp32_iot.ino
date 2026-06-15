#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#define ENABLE_DATABASE
#include <FirebaseClient.h>

// =========================================================================
// 1. KONFIGURASI PIN HARDWARE (TETAP Sesuai Rangkaian Kelompok 5)
// =========================================================================
const int PIN_RADAR = 14;  // TETAP: Pin OUT Radar masuk ke GPIO 14
const int PIN_RELAY = 27;  // TETAP: Pin IN1 Relai masuk ke GPIO 27

// =========================================================================
// 2. KUNCI JARAK PALING MENTOK (GATE 0 = RADIUS DI BAWAH 75 CM)
// =========================================================================
const byte BATAS_GERBANG_JARAK = 0;

// =========================================================================
// 3. KONFIGURASI PARAMETER AUDIT ENERGI & TIMEOUT 1 DETIK
// =========================================================================
const float DAYA_LAMPU_WATT = 10.0;
const float FAKTOR_EMISI_GRID = 0.85;

// REQUEST: Lampu otomatis mati jika 1 detik tidak terdeteksi objek (1000 ms)
const unsigned long TIMEOUT_LAMPU_MS = 1000;

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
unsigned long waktuMulaiMati = 0;
unsigned long waktuGerakanTerakhir = 0;
float totalEnergiDiselamatkan_Wh = 0.0;
float totalCO2Dicegah_mg = 0.0;
bool statusLampuSebelumnya = false;

unsigned long lastUpdateFirebase = 0;
unsigned long lastMonitorLog = 0;

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
// FUNGSI: Konfigurasi jarak radar HLK-LD2410C
// =========================================================================
void konfigurasiJarakRadarFisik(byte gateTerap) {
  Serial.println("[RADAR] Menghubungi sensor untuk mengunci ke jarak terpendek (< 75cm)...");

  HardwareSerial RadarSerial(2);
  RadarSerial.begin(256000, SERIAL_8N1, PIN_RADAR, PIN_RELAY);
  delay(500);

  // 1. Perintah masuk Mode Konfigurasi
  byte cmdEnableConfig[] = {0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01};
  RadarSerial.write(cmdEnableConfig, sizeof(cmdEnableConfig));
  delay(200);

  // 2. Perintah mengunci Max Distance Gate ke Gate 0
  byte cmdMaxDistance[] = {0xFD, 0xFC, 0xFB, 0xFA, 0x14, 0x00, 0x60, 0x00, 0x00, 0x00, gateTerap, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x03, 0x02, 0x01};
  RadarSerial.write(cmdMaxDistance, sizeof(cmdMaxDistance));
  delay(200);

  // 3. Perintah keluar Mode Konfigurasi & Save permanen
  byte cmdEndConfig[] = {0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01};
  RadarSerial.write(cmdEndConfig, sizeof(cmdEndConfig));
  delay(500);

  RadarSerial.end();
  Serial.println("[SUCCESS] Jangkauan maksimal dikunci pada Gate 0 (Radius < 75 cm)!");
}

// =========================================================================
// SETUP
// =========================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println("=================================================");
  Serial.println("    SISTEM OTOMATISASI LAMPU - RADAR HLK-LD2410C ");
  Serial.println("    TIMEOUT 1 DETIK | KELOMPOK 5                ");
  Serial.println("=================================================");

  konfigurasiJarakRadarFisik(BATAS_GERBANG_JARAK);

  pinMode(PIN_RADAR, INPUT);
  pinMode(PIN_RELAY, OUTPUT);
  digitalWrite(PIN_RELAY, HIGH);

  Serial.println("[READY] Jarak dikunci terpendek. Sistem siap!");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Menghubungkan ke Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Terhubung! IP Address: ");
  Serial.println(WiFi.localIP());

  ssl_client.setInsecure();
  ssl_client.setConnectionTimeout(1000);
  ssl_client.setHandshakeTimeout(5);

  initializeApp(async_client, app, getAuth(noAuth));
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);

  Serial.println("Berhasil terhubung ke Firebase!");
  Serial.println("-------------------------------------------------");
}

// =========================================================================
// LOOP UTAMA
// =========================================================================
void loop() {
  app.loop();

  int statusRadar = digitalRead(PIN_RADAR);

  if (statusRadar == HIGH) {
    waktuGerakanTerakhir = millis();
  }

  if (millis() - waktuGerakanTerakhir < TIMEOUT_LAMPU_MS) {
    digitalWrite(PIN_RELAY, LOW);

    if (statusLampuSebelumnya == false) {
      Serial.println("\n[STATUS] Objek Terdeteksi Dekat! Lampu Menyala.");

      if (app.ready()) {
        Database.set<bool>(async_client, "ruangan_01/status_lampu", true);
        Database.set<bool>(async_client, "ruangan_01/status_radar", true);
      }

      if (waktuMulaiMati > 0) {
        unsigned long durasiMati_ms = millis() - waktuMulaiMati;
        float durasiMati_jam = (float)durasiMati_ms / 3600000.0;

        float energiDihemat_Wh = DAYA_LAMPU_WATT * durasiMati_jam;
        float co2Dicegah_mg = (energiDihemat_Wh / 1000.0) * FAKTOR_EMISI_GRID * 1000000.0;

        totalEnergiDiselamatkan_Wh += energiDihemat_Wh;
        totalCO2Dicegah_mg += co2Dicegah_mg;

        Serial.println("-------------------------------------------------");
        Serial.print(">> [AUDIT] Lampu Mati Selama: "); Serial.print(durasiMati_ms / 1000); Serial.println(" detik");
        Serial.print(">> [AUDIT] Energi Diselamatkan: "); Serial.print(energiDihemat_Wh, 4); Serial.println(" Wh");
        Serial.print(">> [AUDIT] Reduksi Emisi CO2: "); Serial.print(co2Dicegah_mg, 2); Serial.println(" mg");
        Serial.println("-------------------------------------------------");

        if (app.ready()) {
          Database.set<float>(async_client, "ruangan_01/energi_dihemat_wh", totalEnergiDiselamatkan_Wh);
          Database.set<float>(async_client, "ruangan_01/co2_dicegah_mg", totalCO2Dicegah_mg);
        }

        waktuMulaiMati = 0;
      }
      statusLampuSebelumnya = true;
    }
  }
  else {
    digitalWrite(PIN_RELAY, HIGH);

    if (statusLampuSebelumnya == true) {
      Serial.println("\n[STATUS] Kosong (1 Detik). Lampu Dimatikan Otomatis.");

      if (app.ready()) {
        Database.set<bool>(async_client, "ruangan_01/status_lampu", false);
        Database.set<bool>(async_client, "ruangan_01/status_radar", false);
      }

      waktuMulaiMati = millis();
      statusLampuSebelumnya = false;
    }

    if (millis() - lastUpdateFirebase >= 5000) {
      lastUpdateFirebase = millis();

      unsigned long berjalanMati_ms = millis() - waktuMulaiMati;
      float berjalanMati_jam = (float)berjalanMati_ms / 3600000.0;

      float energiBerjalan_Wh = DAYA_LAMPU_WATT * berjalanMati_jam;
      float co2Berjalan_mg = (energiBerjalan_Wh / 1000.0) * FAKTOR_EMISI_GRID * 1000000.0;

      float totalWh = totalEnergiDiselamatkan_Wh + energiBerjalan_Wh;
      float totalMg = totalCO2Dicegah_mg + co2Berjalan_mg;

      Serial.print("[MONITOR] Total Energi: ");
      Serial.print(totalWh, 4); Serial.print(" Wh | Total CO2: ");
      Serial.print(totalMg, 2); Serial.println(" mg");

      if (app.ready()) {
        Database.set<float>(async_client, "ruangan_01/energi_dihemat_wh", totalWh);
        Database.set<float>(async_client, "ruangan_01/co2_dicegah_mg", totalMg);
      }
    }
  }

  delay(50);
}
