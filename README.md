# Smart Room eCO2 — Kicaw

[![Flutter CI](https://github.com/terra2n/Kicaw/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/terra2n/Kicaw/actions/workflows/flutter_ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Prototipe otomatisasi lampu ruangan berbasis **ESP32** dengan sensor radar **HLK-LD2410C** untuk memantau dan mengurangi emisi karbon secara jarak jauh. Menggunakan arsitektur **dual-backend**: **Firebase** (real-time) + **Supabase** (PostgreSQL untuk data historis & analitik).

> Referensi: Singh & Dhanekar (2026)

---

## 🏗️ Arsitektur Sistem

```
+-------------+    WiFi/HTTPS    +------------------+     Stream      +------------------+
|   ESP32     | +-------------->  |  Firebase        | <-------------+  Flutter          |
|  + Radar    |    (dual-write)  |  Realtime DB     |    onValue     |  Dashboard        |
|  + Relay    |                  |  (Live Status)   |                |  (Mobile/Web)     |
|  + NVS      | +------------->  +------------------+                +------------------+
|  Persist    |    REST/HTTPS    |  Supabase        |  Realtime      |                   |
+-------------+                  |  PostgreSQL      | <-------------+                   |
      |                          |  (Historical)    |    Stream     +------------------+
      | Sensor Radar             +------------------+
      |  mendeteksi gerakan            |
      |  → relay ON/OFF               | Cloud Functions (Firebase)
      |  → kalkulasi emisi            |  - onLampChange
      |  → dual push (FB + SB)         |  - onEnergyUpdate
                                       |  - onRadarChange
                                       v
                               +------------------+
                               |  Firestore       |
                               |  (Daily/Monthly  |
                               |   Logs + Activity|
                               +------------------+
```

---

## 📁 Struktur Repositori

```
├── esp32_iot/                  # Firmware ESP32 (Arduino C++)
│   ├── esp32_iot.ino          # Source code utama
│   ├── firebase_cmd.h         # Handler command radar via Firebase
│   ├── supabase_client.h      # Client HTTP untuk Supabase REST API
│   ├── ld2410_uart.h          # Library protokol UART HLK-LD2410C
│   ├── secrets.h              # Credentials WiFi + Firebase + Supabase (git-ignored)
│   ├── secrets.h.template     # Template credentials
│   ├── wifi_test/             # Test koneksi WiFi
│   └── README.md              # 📘 Dokumentasi firmware
│
├── flutter_dashboard/          # Aplikasi dashboard (Flutter)
│   ├── lib/
│   │   ├── main.dart          # Entry point, init Firebase + Supabase
│   │   ├── app.dart           # Root widget & navigasi bottom bar
│   │   ├── config/            # Konfigurasi (SupabaseConfig)
│   │   ├── models/            # Data model (Firebase + Supabase)
│   │   ├── pages/             # Halaman fitur
│   │   │   ├── home/          # Dashboard utama real-time
│   │   │   ├── statistics/    # Data historis & grafik
│   │   │   ├── carbon/        # Tracking emisi CO2
│   │   │   ├── radar/         # Kontrol & visualisasi radar
│   │   │   └── settings/      # Konfigurasi aplikasi
│   │   ├── services/          # Business logic & integrasi database
│   │   ├── widgets/           # Shared UI components
│   │   └── theme/             # Tema Material Design 3
│   ├── test/                  # Unit & widget test
│   └── README.md              # 📗 Dokumentasi Flutter
│
├── functions/                  # Cloud Functions (Firebase - TypeScript)
│   ├── src/index.ts           # Triggers: onLampChange, onEnergyUpdate, onRadarChange
│   ├── package.json
│   └── tsconfig.json
│
├── supabase/                   # Database Supabase (PostgreSQL)
│   ├── config.toml            # Konfigurasi CLI lokal
│   ├── schema.sql             # Schema utama (4 tabel)
│   └── migrations/            # Migrasi database
│
├── .github/workflows/         # CI/CD (Flutter CI)
├── .github/ISSUE_TEMPLATE/    # Template issue (bug report & feature request)
├── firebase.json              # Konfigurasi Firebase
├── firestore.rules            # Aturan Firestore
├── database.rules.json        # Aturan Realtime Database
├── MIGRATION_GUIDE.md         # 📘 Panduan migrasi Firebase → Supabase
├── SUPABASE_MIGRATION_GUIDE.md# Panduan teknis migrasi detail
├── QUICKSTART_SUPABASE.md     # Panduan setup cepat Supabase (30 menit)
├── LICENSE
└── README.md                  # 📖 Dokumentasi utama (ini)
```

### 📚 Dokumentasi Lengkap

| Dokumen | Isi |
|---------|-----|
| **[ESP32 IoT README](esp32_iot/README.md)** | Wiring hardware, pin konfigurasi, compile/upload, troubleshooting |
| **[Flutter Dashboard README](flutter_dashboard/README.md)** | Fitur aplikasi, arsitektur, dependency, build guide |
| **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** | Panduan migrasi dari Firebase ke Supabase (bahasa Indonesia) |
| **[SUPABASE_MIGRATION_GUIDE.md](SUPABASE_MIGRATION_GUIDE.md)** | Technical battle plan migrasi (English, detail) |
| **[QUICKSTART_SUPABASE.md](QUICKSTART_SUPABASE.md)** | Setup Supabase dalam 30 menit |

---

## 🛠️ Komponen & Arsitektur

### 🔧 Kebutuhan Hardware

| Komponen | Spesifikasi | Keterangan |
|----------|-------------|------------|
| ESP32 | Dev Board (30/38 pin) | Microcontroller dengan WiFi + Bluetooth |
| Sensor Radar HLK-LD2410C | 24GHz mmWave, UART + digital OUT | Deteksi presence (hingga 9 gate/6m) |
| Relay Module | 1-channel 5V (Active LOW) | Kontrol lampu/LED |
| Lampu LED | 3W (simulasi) | Beban yang dikontrol |
| Power Supply | 5V / 2A | Catu daya ESP32 + relay |

### Pin Wiring

| Pin ESP32 | Terhubung ke |
|-----------|-------------|
| GPIO 14 | OUT (Digital) Sensor Radar |
| GPIO 16 | RX (UART) → TX Sensor Radar |
| GPIO 17 | TX (UART) → RX Sensor Radar |
| GPIO 27 | IN Relay Module (Active LOW) |
| 5V | VCC Sensor Radar & Relay |
| GND | GND Sensor Radar & Relay |

### 🧠 Logika Deteksi

Sistem menggunakan **threshold counter** dengan delay *loop* 50ms:
- **HIGH stabil ≥10x** (~0.5 detik) → relay ON → lampu menyala
- **LOW stabil ≥20x** (~1.0 detik) → relay OFF → lampu mati
- **Gate 0** = deteksi radius < 75 cm (bisa dikonfigurasi via Firebase)

---

## ☁️ Backend Architecture

Proyek menggunakan arsitektur **dual-backend**:

### Firebase Realtime Database (Live Data)
- **Fungsi**: Menyimpan status real-time (lampu, radar, heartbeat, energi)
- **Streaming**: Flutter menggunakan `.onValue` untuk update instan
- **Path**: `ruangan_01/{status_lampu, status_radar, energi_dihemat_wh, co2_dicegah_mg, last_heartbeat}`

### Firebase Firestore (Aggregated Logs)
- **Daily Logs**: Ringkasan harian energi & CO2
- **Monthly Logs**: Agregasi bulanan
- **Activity Logs**: Event log (lamp on/off, radar change)
- **Cloud Functions**: Trigger otomatis saat data di RTDB berubah

### Supabase PostgreSQL (Historical & Analytics)

| Tabel | Fungsi |
|-------|--------|
| `room_status` | Status live ruangan (single row, id=1) |
| `sensor_logs` | Riwayat sensor per 5 detik |
| `daily_summaries` | Agregasi harian (avg, max, min) |
| `activity_logs` | Event: motion_detected, lamp_on, dll |

Semua tabel menggunakan **Row Level Security (RLS)** dengan policy anon read/insert/update.

### Firebase Cloud Functions (TypeScript)

| Function | Trigger | Fungsi |
|----------|---------|--------|
| `onLampChange` | `status_lampu` berubah | Catat activity log, hitung energi, update daily/monthly |
| `onEnergyUpdate` | `energi_dihemat_wh` berubah | Update daily log & monthly log (incremental) |
| `onRadarChange` | `status_radar` berubah | Catat event presence/empty |

---

## 📊 Parameter Emisi

Perhitungan emisi CO₂ berdasarkan Singh & Dhanekar (2026):

| Parameter | Nilai | Satuan |
|-----------|-------|--------|
| Daya lampu simulasi (`DAYA_LAMPU_WATT`) | 3.0 | Watt |
| Faktor emisi grid (`FAKTOR_EMISI_GRID`) | 0.85 | kg CO₂/kWh |
| Energi dihemat | `P × t` | Wh |
| CO₂ dicegah | `(Wh / 1000) × 0.85 × 1.000.000` | mg |
| Setara pohon | `CO₂ kg / 21` | pohon/hari |
| Setara mobil | `CO₂ kg / 0.12` | km |
| Setara cas HP | `Wh / 15` | kali cas |

---

## 🚀 Quick Start (30 Menit)

### Prasyarat

| Hardware | Software |
|----------|----------|
| ESP32 Dev Board | Arduino IDE / Arduino CLI |
| HLK-LD2410C Radar Sensor | Flutter SDK ≥3.0 |
| Relay Module 1ch 5V | Akun Firebase (free) |
| Lampu LED 3W + kabel jumper | Akun Supabase (free) |
| USB Cable + Power Supply 5V/2A | Node.js ≥18 (untuk Cloud Functions) |

### 1. Setup Database (5 menit)

#### A. Firebase
```bash
# Buka Firebase Console, buat/aktifkan project "kicaw-smart-room"
# Aktifkan Realtime Database & Firestore (mode test)

# Deploy Cloud Functions
cd functions
npm install
npm run build
npm run deploy
```

#### B. Supabase
```bash
# 1. Buka https://supabase.com → New Project
#    Name: smart-room-eco2 | Region: Singapore
# 2. Buka SQL Editor → paste isi supabase/schema.sql → Run
# 3. Settings → API → catat Project URL & anon public key
```
📖 Panduan detail: [QUICKSTART_SUPABASE.md](QUICKSTART_SUPABASE.md)

### 2. Wired Hardware

```
ESP32 GPIO   →   HLK-LD2410C        Relay
─────────────────────────────────────────
GPIO 14      →   OUT (digital)
GPIO 16 (RX) →   TX (UART)
GPIO 17 (TX) →   RX (UART)
GPIO 27      →                    IN1
5V           →   VCC               VCC
GND          →   GND               GND
```

> **Relay Active LOW**: `HIGH` = mati, `LOW` = nyala

### 3. Setup ESP32 (10 menit)

```bash
# 1. Install library yang diperlukan (via Arduino Library Manager):
#    - FirebaseClient by Mobizt
#    - ArduinoJson by Benoit Blanchon (v7)

# 2. Buat & isi credentials
cd esp32_iot
cp secrets.h.template secrets.h
nano secrets.h   # isi WiFi, Firebase, & Supabase

# 3. Compile
arduino-cli compile --fqbn esp32:esp32:esp32 esp32_iot.ino

# 4. Upload
arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 esp32_iot.ino

# 5. Monitor (cek "Supabase connection: SUCCESS")
arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200
```

📘 **Panduan lengkap wiring & troubleshooting**: [ESP32 README](esp32_iot/README.md)

### 4. Setup Flutter Dashboard (10 menit)

```bash
cd flutter_dashboard
cp .env.example .env
nano .env        # isi SUPABASE_URL, SUPABASE_ANON_KEY
flutter pub get
flutter run
```

📗 **Panduan lengkap fitur & arsitektur**: [Flutter README](flutter_dashboard/README.md)

### 5. Verifikasi (5 menit)

| Cek | Harapan |
|-----|---------|
| Serial Monitor ESP32 | `Supabase connection: SUCCESS`, push data tiap 5 detik |
| Supabase Table Editor | `sensor_logs` terisi data baru |
| Flutter Dashboard | Home page tampil status real-time |
| Gerakan di depan sensor | Motion indicator berubah, lampu menyala |

---

## 📱 Fitur Dashboard

| Halaman | Fitur | Sumber Data |
|---------|-------|-------------|
| **🏠 Home** | Status ruangan real-time, indikator motion, energi, aktivitas terbaru | Firebase RTDB + Supabase |
| **📊 Statistics** | Grafik 30 hari, total all-time, target bulanan, best day card | Firestore (daily/monthly logs) |
| **🌿 Carbon** | CO₂ tracking, real-world equivalents (pohon, mobil, cas HP) | Firebase RTDB + CarbonService |
| **📡 Radar** | Visualisasi gate, sensitivitas per gate, engineering mode | Firebase RTDB (radar_config) |
| **⚙️ Settings** | Tema, notifikasi, otomasi, device info | SharedPreferences + Firebase |

---

## 🧪 CI/CD

Proyek menggunakan **GitHub Actions** untuk:
- **Flutter CI**: Analisis kode (`flutter analyze`) + testing (`flutter test`) otomatis
  - Trigger: Push/PR ke branch `master` dengan perubahan di `flutter_dashboard/**`
  - Konfigurasi: [`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)

---

## 🔐 Pengelolaan Credentials

### ESP32 (`secrets.h`)
- File sudah di-**gitignore** — tidak akan tercommit
- Isi: WiFi SSID/Password, Firebase API Key/URL, Supabase URL/Anon Key
- Lihat template: [`secrets.h.template`](esp32_iot/secrets.h.template)

### Flutter (`.env`)
- File `.env` sudah di-**gitignore**
- Isi: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `FIREBASE_API_KEY`, `FIREBASE_DATABASE_URL`
- Lihat template: [`.env.example`](flutter_dashboard/.env.example)

### Firebase (`google-services.json`)
- File `google-services.json` sudah di-**gitignore**
- Generate dengan: `flutterfire configure`

---

## 📊 Panduan Presentasi Dosen

Jika dosen meminta kode program dilampirkan di dalam slide presentasi Canva secara interaktif:

### Embed GitHub Gist ke Canva
1. Buka [gist.github.com](https://gist.github.com) (login GitHub)
2. Buat **public gist** (tempel kode penting, misal `ld2410_uart.h`)
3. Salin URL gist
4. Di Canva: **Apps** → **Embeds** → tempel URL → **Add to design**

> **Catatan**: Metode ini butuh koneksi internet saat presentasi.

---

## 🤝 Kontribusi

1. Fork repo ini
2. Buat branch baru: `git checkout -b fitur-anda`
3. Commit perubahan: `git commit -m "feat: menambahkan fitur X"`
4. Push ke branch: `git push origin fitur-anda`
5. Buat Pull Request

---

## 📄 Lisensi

[MIT](LICENSE) © 2026 terra2n
