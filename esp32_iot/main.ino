#include <WiFi.h>
#include <Firebase_ESP_Client.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"
// Provide the RTDB payload printing info and other helper functions.
#include "addons/RTDBHelper.h"

// ==========================================
// 1. Kredensial WiFi & Firebase
// ==========================================
#define WIFI_SSID "NAMA_WIFI_ANDA"
#define WIFI_PASSWORD "PASSWORD_WIFI_ANDA"

// Ganti dengan API Key dan Database URL Firebase Anda
#define API_KEY "API_KEY_FIREBASE_ANDA"
#define DATABASE_URL "URL_DATABASE_FIREBASE_ANDA" 

// ==========================================
// 2. Definisi Pin pada ESP32
// ==========================================
const int PIN_PIR = 14;   // SEKARANG: Hubungkan ke pin OUT pada Sensor PIR
const int PIN_RELAY = 27; // SEKARANG: Hubungkan ke pin IN pada Modul Relay

// ==========================================
// 3. Parameter Kalkulasi Emisi (Sesuai Jurnal)
// ==========================================
const float DAYA_LAMPU_WATT = 10.0; // Simulasi beban daya lampu jalan mini
const float FAKTOR_EMISI_GRID = 0.85; // Faktor konversi emisi jaringan (tCO2/MWh setara kg/kWh)

// Variabel Global
unsigned long waktuMulaiMati = 0;
float totalEnergiDihemat_Wh = 0;
float totalCO2Dicegah_mg = 0;
bool statusLampuSebelumnya = false;
unsigned long lastUpdateFirebase = 0;

// Objek Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool signupOK = false;

void setup() {
  Serial.begin(115200);
  
  // Pengaturan Input / Output Pin
  pinMode(PIN_PIR, INPUT);
  pinMode(PIN_RELAY, OUTPUT);
  
  // Kondisi awal: Matikan lampu
  digitalWrite(PIN_RELAY, HIGH); 
  Serial.println("Sistem Otomatisasi Lampu Jalan eCO2 (Pin Baru) Siap!");

  // Koneksi ke WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Menghubungkan ke Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Terhubung! IP Address: ");
  Serial.println(WiFi.localIP());

  // Konfigurasi Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Sign up anonim 
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Berhasil terhubung ke Firebase!");
    signupOK = true;
  } else {
    Serial.printf("%s\n", config.signer.signupError.message.c_str());
  }

  // Assign callback fungsi helper
  config.token_status_callback = tokenStatusCallback; 
  
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // 1. Membaca data dari Sensor PIR
  int statusPIR = digitalRead(PIN_PIR);
  
  // 2. Logika Kontrol Sakelar Relai
  if (statusPIR == HIGH) {
    // JIKA ADA GERAKAN -> NYALAKAN LAMPU
    digitalWrite(PIN_RELAY, LOW); 
    
    if (statusLampuSebelumnya == false) {
      Serial.println("[STATUS] Objek Terdeteksi! Lampu Jalan Menyala.");
      statusLampuSebelumnya = true;
      waktuMulaiMati = 0; // Reset timer karena sedang tidak berhemat
      
      // Update Firebase (Lampu Menyala)
      if (Firebase.ready() && signupOK) {
        Firebase.RTDB.setBool(&fbdo, "ruangan_01/status_lampu", true);
      }
    }
  } else {
    // JIKA KOSONG -> MATIKAN LAMPU
    digitalWrite(PIN_RELAY, HIGH);
    
    if (statusLampuSebelumnya == true) {
      Serial.println("[STATUS] Jalan Sepi. Lampu Dimatikan Otomatis.");
      statusLampuSebelumnya = false;
      waktuMulaiMati = millis(); // Mulai hitung durasi penghematan
      
      // Update Firebase (Lampu Mati)
      if (Firebase.ready() && signupOK) {
        Firebase.RTDB.setBool(&fbdo, "ruangan_01/status_lampu", false);
      }
    }
    
    // 3. Kalkulasi & Kirim Data secara periodik
    if (waktuMulaiMati > 0) {
      unsigned long durasiMati_ms = millis() - waktuMulaiMati;
      float durasiMati_jam = (float)durasiMati_ms / 3600000.0;
      
      float energiBaru_Wh = DAYA_LAMPU_WATT * durasiMati_jam;
      float energiTotal_Wh = totalEnergiDihemat_Wh + energiBaru_Wh;
      
      // (Wh / 1000 = kWh) -> kWh * 0.82 kg/kWh * 1,000,000 = mg CO2
      float co2Total_mg = (energiTotal_Wh / 1000.0) * FAKTOR_EMISI_GRID * 1000000.0;
      
      // Print ke Serial Monitor & Push Firebase tiap 5 detik
      if (millis() - lastUpdateFirebase >= 5000) {
        lastUpdateFirebase = millis();
        
        Serial.print(">> [AUDIT] Energi Dihemat: ");
        Serial.print(energiTotal_Wh, 4);
        Serial.print(" Wh | CO2 Dicegah: ");
        Serial.print(co2Total_mg, 2);
        Serial.println(" mg");
        
        if (Firebase.ready() && signupOK) {
          Firebase.RTDB.setFloat(&fbdo, "ruangan_01/energi_dihemat_wh", energiTotal_Wh);
          Firebase.RTDB.setFloat(&fbdo, "ruangan_01/co2_dicegah_mg", co2Total_mg);
          Firebase.RTDB.setTimestamp(&fbdo, "ruangan_01/terakhir_update");
        }
        
        // Simpan akumulasi, reset waktu
        totalEnergiDihemat_Wh = energiTotal_Wh;
        totalCO2Dicegah_mg = co2Total_mg;
        waktuMulaiMati = millis(); 
      }
    }
  }
  
  delay(50); // Jeda stabilitas sensor
}
