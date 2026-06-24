# ESP32 Smart Room IoT Firmware

Firmware ESP32-C3 untuk otomatisasi lampu ruangan dengan sensor radar HLK-LD2410C (digital OUT GPIO14), kontrol relay active LOW, dan dual-write ke Firebase Realtime Database + Supabase PostgreSQL.

## 🔧 Hardware Requirements

### Components
- **ESP32-C3 Dev Board** (XIAO ESP32C3 atau compatible)
- **HLK-LD2410C Radar Sensor** (24GHz mmWave presence detection, digital OUT + UART)
- **Relay Module** (1-channel, 5V trigger, Active LOW)
- **Power Supply** (5V/2A minimum)
- **LED/Lamp** (3W, controlled via relay)

### Pin Configuration

| Component | ESP32 Pin | Notes |
|-----------|-----------|-------|
| Radar OUT (Digital) | GPIO 14 | Presence detection signal |
| Radar RX (UART) | GPIO 16 | UART communication (TX → RX) |
| Radar TX (UART) | GPIO 17 | UART communication (RX → TX) |
| Relay IN1 | GPIO 27 | Active LOW relay control |
| Radar VCC | 5V | Power supply |
| Radar GND | GND | Ground |
| Relay VCC | 5V | Power supply |
| Relay GND | GND | Ground |

## 📐 Wiring Diagram

### Visual Diagram

> **📸 Tambahkan gambar rangkaian Anda di sini:**
> 
> Letakkan file gambar di folder `assets/` lalu uncomment salah satu baris di bawah:

```markdown
<!-- Uncomment setelah menambahkan gambar -->
<!-- ![Wiring Diagram](assets/wiring_diagram.png) -->
<!-- ![Breadboard Layout](assets/breadboard_layout.png) -->
<!-- ![Assembled Hardware](assets/assembled_hardware.jpg) -->
```

### ASCII Diagram (Text-Based)

```
ESP32                    HLK-LD2410C Radar
┌──────────┐            ┌───────────────┐
│ GPIO 14  ├────────────┤ OUT (Digital) │
│ GPIO 16  ├────────────┤ TX (UART)     │
│ GPIO 17  ├────────────┤ RX (UART)     │
│ 5V       ├────────────┤ VCC           │
│ GND      ├────────────┤ GND           │
└──────────┘            └───────────────┘

ESP32                    Relay Module
┌──────────┐            ┌──────────┐
│ GPIO 27  ├────────────┤ IN1      │
│ 5V       ├────────────┤ VCC      │
│ GND      ├────────────┤ GND      │
└──────────┘            └──────────┘
                        │ COM  NO  NC│
                        └────┬───────┘
                             │
                          [LAMP/LED]
```

## 🚀 Getting Started

### 1. Install Arduino CLI & Libraries

**Required Libraries** (via Library Manager / Arduino CLI environment):
- **FirebaseClient** by Mobizt (v1.3.0+)
- **ArduinoJson** by Benoit Blanchon (v6.20.0+ / v7.0.0+)
- **WiFi** (built-in)
- **WiFiClientSecure** (built-in)

> Kalau belum ada Arduino CLI atau core ESP32, install dulu sebelum compile.

### 2. Configure WiFi & Firebase

**⚠️ PENTING:** Sebelum compile, Anda **HARUS** mengisi kredensial WiFi dan Firebase.

#### Step-by-Step Configuration:

**A. Setup Secrets File**

1. **Buat file `secrets.h`** dengan text editor (Arduino IDE, VS Code, Notepad++, dll)

2. **Isi credentials** untuk WiFi, Firebase, dan Supabase:

```cpp
// WiFi
#define WIFI_SSID "Rumah_WiFi_5G"
#define WIFI_PASSWORD "password12345"

// Firebase (jika masih pakai)
#define API_KEY "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#define DATABASE_URL "https://your-project-id-default-rtdb.firebaseio.com"

// Supabase
#define SUPABASE_URL "https://xxxxx.supabase.co"
#define SUPABASE_ANON_KEY "eyJhbGc..."
```

> **Catatan:** Semua credentials sekarang dalam satu file `secrets.h` (WiFi + Firebase + Supabase)

**B. WiFi Credentials**

Edit `secrets.h`, cari bagian WiFi:

**SEBELUM:**
```cpp
#define WIFI_SSID "NAMA_WIFI_ANDA"
#define WIFI_PASSWORD "PASSWORD_WIFI_ANDA"
```

**SESUDAH** (contoh):
```cpp
#define WIFI_SSID "Rumah_WiFi_5G"
#define WIFI_PASSWORD "password12345"
```

> **Catatan:** ESP32 hanya support WiFi 2.4GHz, pastikan router Anda tidak restricted ke 5GHz saja.

**C. Firebase Credentials**

Dapatkan kredensial dari Firebase Console:

1. **Buka** [Firebase Console](https://console.firebase.google.com/)
2. **Pilih** project Anda (contoh: `kicaw-smart-room`)
3. **Klik** ⚙️ Settings → **Project Settings**
4. **Copy** **Web API Key** dari tab **General**
5. **Buka** tab **Realtime Database** di sidebar
6. **Copy** Database URL (contoh: `https://kicaw-smart-room-default-rtdb.firebaseio.com`)

Edit `secrets.h`, cari bagian Firebase:

**SEBELUM:**
```cpp
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "https://YOUR_PROJECT-default-rtdb.firebaseio.com"
```

**SESUDAH** (ganti dengan milik Anda):
```cpp
#define API_KEY "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#define DATABASE_URL "https://your-project-id-default-rtdb.firebaseio.com"
```

> **⚠️ KEAMANAN:** File `secrets.h` sudah otomatis di-gitignore. Jangan commit credentials ke Git!

**D. Verify Configuration**

Sebelum upload, pastikan:
- ✅ File `secrets.h` sudah dibuat dengan semua credentials (WiFi + Firebase + Supabase)
- ✅ WiFi SSID dan password sudah diisi
- ✅ Firebase API Key sudah diisi (bukan yang default)
- ✅ Database URL sesuai dengan project Firebase Anda
- ✅ Tidak ada typo atau kutip ganda yang hilang

### 3. Compile with Arduino CLI

**Pastikan Arduino CLI sudah terpasang** dan core ESP32 tersedia.

Compile firmware dari folder `esp32_iot/`:

```bash
arduino-cli compile --fqbn esp32:esp32:esp32 esp32_iot.ino
```

Jika ingin cek core ESP32 yang terinstall:

```bash
arduino-cli core list
```

### 4. Cari Port ESP32

Sambungkan ESP32 via USB lalu cari portnya:

```bash
arduino-cli board list
```

Contoh port yang muncul:
- `/dev/ttyUSB0`
- `/dev/ttyACM0`

### 5. Upload Firmware ke ESP32

Ganti `/dev/ttyUSB0` sesuai port Anda:

```bash
arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 esp32_iot.ino
```

Kalau upload sukses, firmware akan masuk ke board ESP32.

### 6. Monitor Serial Output

Buka serial monitor dengan baud rate 115200:

```bash
arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200
```

Yang perlu dicek di serial monitor:
- WiFi connection status
- Firebase sync status
- Radar detection events
- Energy consumption logs

### 7. Jalankan Flutter Dashboard

Setelah ESP32 sukses jalan, buka dashboard Flutter:

```bash
cd ../flutter_dashboard
flutter pub get
flutter run
```

> **Catatan:** Jika Anda ingin pakai Arduino IDE, alurnya tetap sama: pilih board, pilih port, lalu upload. Namun panduan utama di repo ini sekarang memakai **Arduino CLI** agar lebih konsisten dan reproducible.

## 📊 Firebase Database Structure

Firmware menulis ke path `ruangan_01/`:

```json
{
  "ruangan_01": {
    "status_lampu": true,            // true = nyala, false = mati
    "status_radar": true,            // true = ada orang, false = kosong
    "radar_distance_cm": 37,         // Perkiraan jarak (gate × 75 + 37)
    "energi_dihemat_wh": 1.9,        // Kumulatif energi dihemat (Wh)
    "co2_dicegah_mg": 1615.0,        // Kumulatif CO2 dicegah (mg)
    "waktu_mulai_mati": 1719234567,  // Epoch timestamp saat lampu mati (0 = lampu nyala)
    "last_heartbeat": 1719234567,    // Epoch timestamp heartbeat
    "last_heartbeat_ts": "2024-06-24 14:30:00"  // Timestamp WIB
  }
}
```

Data dibaca oleh Flutter via `.onValue` — setiap perubahan langsung terlihat di dashboard.

## ⚙️ Configuration Parameters

### Radar Settings

```cpp
const byte BATAS_GERBANG_DEFAULT = 0;  // Gate 0 = < 75 cm detection range
const int THRESHOLD_MASUK  = 1;        // Trigger ON after 1 detection (~50ms)
const int THRESHOLD_KOSONG = 1;        // Trigger OFF after 1 detection (~50ms)
```

Threshold = 1 berarti **satu deteksi langsung eksekusi relay**. HLK-LD2410C sudah melakukan filtering internal, sehingga tidak perlu debounce tambahan.

**Adjust Detection Range:**
- `Gate 0` = 0-75 cm (default, untuk area meja ~45cm)
- `Gate 1` = 75-150 cm
- `Gate 2` = 150-225 cm
- ... (up to Gate 8 = 525-600 cm)

### Energy Audit

```cpp
const float DAYA_LAMPU_WATT   = 3.0;   // Lamp power consumption (W)
const float FAKTOR_EMISI_GRID = 0.85;  // Grid emission factor (kgCO2/kWh)
```

**Customize for Your Lamp:**
- Measure actual lamp wattage with power meter
- Update `DAYA_LAMPU_WATT` accordingly
- Adjust `FAKTOR_EMISI_GRID` based on your region's grid mix

## 🔍 How It Works

### 1. Radar Detection Flow

```
Radar HIGH (person detected)
    ↓
hitungHigh++ (increment counter)
    ↓
hitungHigh >= THRESHOLD_MASUK (1)?
    ↓ YES (instan, ~50ms)
Turn ON relay (digitalWrite LOW) → Lamp ON
    ↓
Log activity ke Supabase (lamp_on)
```

```
Radar LOW (no person)
    ↓
hitungLow++ (increment counter)
    ↓
hitungLow >= THRESHOLD_KOSONG (1)?
    ↓ YES (instan, ~50ms)
Turn OFF relay (digitalWrite HIGH) → Lamp OFF
    ↓
Hitung energi & CO2 selama periode mati
Simpan ke NVS
    ↓
Log activity ke Supabase (lamp_off)
```

**PENTING:** Tidak ada `pushKeFirebase()` di blok ON/OFF. Cloud push hanya terjadi di siklus monitoring 5 detik, sehingga latensi jaringan tidak mempengaruhi responsivitas relay.

### 2. Firebase Commands (Legacy)

Fungsi command Firebase (`set_lampu`, `test_mode`) sudah **dinonaktifkan** — kontrol lampu 100% otomatis berdasarkan radar, tanpa override manual dari aplikasi.

**Radar UART:** Parameter konfigurasi radar (gate sensitivity, max distance, engineering mode) tersedia di `firebase_cmd.h` untuk keperluan engineering/debug, tapi tidak digunakan dalam operasi normal. Untuk mengatur parameter radar, gunakan **HLKRadarTool** app dari Play Store (radar dilepas dari ESP32).

### 3. Energy Calculation

Energi dihitung saat lampu berubah dari OFF → ON (durasi periode mati):

```cpp
energi_Wh  = DAYA_LAMPU_WATT × durasi_jam        // durasi_jam = durasi_ms / 3600000
co2_mg     = (energi_Wh / 1000.0) × FAKTOR_EMISI_GRID × 1000000
```

Nilai tersimpan di NVS (flash ESP32) dan dipulihkan setelah reboot. Total energi real-time (termasuk sesi mati berjalan) dihitung ulang setiap 5 detik untuk push ke cloud.

### 4. Key Design Decisions

* **Threshold = 1 (instant detection):** HLK-LD2410C sudah melakukan filtering internal, sehingga satu deteksi langsung memicu relay. Tidak ada debounce tambahan — respons ~50ms.
* **Cloud push di siklus 5 detik (bukan di jalur deteksi):** `pushKeFirebase()` dan `pushKeSupabase()` hanya dipanggil dalam blok monitoring periodik, bukan di blok ON/OFF. Ini memastikan relay tidak terblokir oleh latensi jaringan.
* **Non-blocking WiFi & Supabase reconnection:** WiFi state machine + Supabase retry 30 detik — radar tetap responsif meskipun koneksi cloud bermasalah.
* **NVS persistensi:** Energi total dan gate radar disimpan di NVS flash setiap 60 detik, dipulihkan setelah reboot.
* **Radar Config via HLKRadarTool:** Konfigurasi parameter radar (gate, sensitivity) dilakukan melalui aplikasi **HLKRadarTool** dari Play Store, bukan dari firmware.

## 🛠️ Troubleshooting

### Issue: WiFi Connection Failed

**Check:**
- SSID and password are correct
- Router is 2.4GHz (ESP32 doesn't support 5GHz)
- WiFi signal strength is adequate

**Fix:**
```cpp
Serial.println(WiFi.localIP());  // Should print valid IP
```

### Issue: Firebase Not Syncing

**Check:**
- `API_KEY`, `DATABASE_URL`, `FIREBASE_AUTH_EMAIL`, `FIREBASE_AUTH_PASSWORD` are correct
- Firebase Realtime Database rules allow writes with auth:
  ```json
  {
    "rules": {
      "ruangan_01": {
        ".read": true,
        ".write": "auth.uid != null"
      }
    }
  }
  ```
- ESP32 menggunakan **email/password auth** — pastikan user `esp32@smartroom.local` sudah dibuat di Firebase Authentication

### Issue: Supabase Not Syncing

**Check:**
- `SUPABASE_URL` dan `SUPABASE_ANON_KEY` benar
- Supabase RLS policy mengizinkan anon insert/update pada semua 4 tabel
- Serial monitor menunjukkan `[SUPABASE] Connection successful!`
- Firmware menggunakan non-blocking retry setiap 30 detik jika gagal

### Issue: Radar Not Detecting

**Check:**
- Wiring: GPIO 14 connected to OUT pin
- Power: Radar VCC connected to 5V (not 3.3V)
- Serial output shows `[RADAR] Occupancy: HIGH/LOW`

**Test Radar UART:**
```cpp
radarBacaKonfigurasi(&cfg);
Serial.println(cfg.maxMovingGate);  // Should print 0-8
```

### Issue: Relay Not Switching

**Check:**
- Relay module is active LOW (HIGH = OFF, LOW = ON)
- GPIO 27 → IN1 connection is secure
- Relay VCC connected to 5V power source

**Test Relay:**
```cpp
digitalWrite(PIN_RELAY, LOW);   // Should turn ON
digitalWrite(PIN_RELAY, HIGH);  // Should turn OFF
```

## 📁 Project Structure

```
esp32_iot/
├── esp32_iot.ino         # Main firmware (manages loops, dual-write to Firebase & Supabase)
├── firebase_cmd.h        # Firebase command handlers & config parser (via ArduinoJson)
├── supabase_client.h     # Supabase client helper (updates room status, logs, & activity)
├── ld2410_uart.h         # HLK-LD2410C UART protocol library
├── secrets.h             # WiFi & Cloud databases credentials (git-ignored)
└── README.md             # This file
```

## 🔐 Security Notes

**⚠️ WARNING:** Credentials disimpan dalam plaintext di `secrets.h` (sudah git-ignored).

**Yang sudah dilakukan:**
1. Firebase RTDB `.write` dibatasi dengan auth (`auth.uid != null`)
2. ESP32 menggunakan email/password auth khusus (bukan anonymous)
3. File `secrets.h` di-gitignore — tidak tercommit ke repositori

**Untuk produksi (jika diperlukan):**
1. Gunakan **Environment Variables** atau **Secrets Manager** untuk ESP32
2. Enable **Firebase App Check** untuk proteksi tambahan

## 📚 References

- [HLK-LD2410C Datasheet](https://www.hlktech.net/index.php?id=988)
- [ESP32 Arduino Core](https://github.com/espressif/arduino-esp32)
- [FirebaseClient Library](https://github.com/mobizt/FirebaseClient)
- [Firebase Realtime Database Docs](https://firebase.google.com/docs/database)

## 📄 License

This project is part of an academic IoT lab assignment.

## 🤝 Contributing

Issues and pull requests are welcome for bug fixes and improvements.
