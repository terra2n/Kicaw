# Kicaw — Smart Room eCO2

[![Flutter CI](https://github.com/terra2n/Kicaw/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/terra2n/Kicaw/actions/workflows/flutter_ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Prototipe Otomatisasi Lampu Ruangan Berbasis ESP32 untuk Memantau Emisi Karbon Secara Jarak Jauh.

> Referensi: Singh & Dhanekar (2026)

---

## Arsitektur Sistem

```
+-------------+          +------------------+          +------------------+
|   ESP32     |  WiFi    |  Firebase        |  Stream  |  Flutter         |
|  + Radar    |--------->|  Realtime DB     |<---------|  Dashboard       |
|  + Relay    |  HTTPS   |  (Cloud)         |  onValue |  (Mobile/Web)    |
+-------------+          +------------------+          +------------------+
      |                           |
      | Sensor Radar mendeteksi   | Data: status_lampu,
      | gerakan dalam <75cm       | energi_dihemat_wh,
      | → relay ON/OFF            | co2_dicegah_mg
      | Kalkulasi emisi CO2       |
```

## Struktur Repositori

```
├── esp32_iot/              # Firmware ESP32 (Arduino C++)
│   ├── esp32_iot.ino       # Source code utama
│   └── README.md           # 📘 Dokumentasi hardware & firmware
├── flutter_dashboard/      # Aplikasi dashboard (Flutter)
│   ├── lib/
│   │   ├── main.dart
│   │   └── firebase_options.dart
│   └── README.md           # 📗 Dokumentasi Flutter app
├── .github/workflows/      # GitHub Actions CI
├── .gitignore
├── .gitattributes
├── LICENSE
└── README.md               # 📖 Dokumentasi utama (ini)
```

### 📚 Dokumentasi Lengkap

- **[ESP32 IoT Documentation](esp32_iot/README.md)** - Hardware wiring, pin configuration, Firebase setup, dan troubleshooting
- **[Flutter Dashboard Documentation](flutter_dashboard/README.md)** - App features, installation guide, dan API reference

## Kebutuhan Hardware

| Komponen | Spesifikasi | Keterangan |
|----------|-------------|------------|
| ESP32 | Dev Board (30/38 pin) | Microcontroller dengan WiFi |
| Sensor Radar HLK-LD2410C | 5V, UART + digital OUT | Deteksi gerakan (gate < 75cm) |
| Relay Module | 1-channel 5V | Kontrol lampu |
| Lampu LED | 3W (simulasi) | Beban yang dikontrol |
| Kabel Jumper | Male-Female / Male-Male | Koneksi komponen |

### Wiring

| Pin ESP32 | Terhubung ke |
|-----------|-------------|
| GPIO 14 | OUT Sensor Radar |
| GPIO 16 | RX (UART) Sensor Radar |
| GPIO 17 | TX (UART) Sensor Radar |
| GPIO 27 | IN Relay Module |
| 5V / 3.3V | VCC Sensor Radar & Relay |
| GND | GND Sensor Radar & Relay |

### Logika Deteksi

Sistem menggunakan **threshold counter** dengan delay loop 50ms:
- **HIGH stabil ≥10x** (~0.5 detik) → lampu menyala
- **LOW stabil ≥20x** (~1.0 detik) → lampu mati

## Setup Firebase

Project Firebase sudah dibuat: **`kicaw-smart-room`**

### Konfigurasi Realtime Database

1. Buka [Firebase Console](https://console.firebase.google.com/project/kicaw-smart-room/overview)
2. Pilih **Realtime Database** → **Rules**
3. Atur rules (untuk testing):

```json
{
  "rules": {
    ".read": "true",
    ".write": "true"
  }
}
```

## Setup ESP32 (Arduino CLI)

**📘 Dokumentasi lengkap: [ESP32 IoT README](esp32_iot/README.md)**

### Quick Start

1. Masuk ke folder `esp32_iot/`
2. Edit `secrets.h` dengan WiFi, Firebase, dan Supabase credentials Anda:

```cpp
// WiFi
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Firebase (jika masih pakai)
#define API_KEY "your-firebase-api-key"
#define DATABASE_URL "https://your-project.firebaseio.com"

// Supabase
#define SUPABASE_URL "https://xxxxx.supabase.co"
#define SUPABASE_ANON_KEY "eyJhbGc..."
```

3. Compile firmware:

```bash
arduino-cli compile --fqbn esp32:esp32:esp32 esp32_iot.ino
```

5. Cari port ESP32:

```bash
arduino-cli board list
```

6. Upload ke ESP32:

```bash
arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 esp32_iot.ino
```

7. Monitor serial output:

```bash
arduino-cli monitor -p /dev/ttyUSB0 -c baudrate=115200
```

> **Perlu panduan lengkap?** Lihat [dokumentasi ESP32 lengkap](esp32_iot/README.md) untuk wiring diagram, troubleshooting, dan alur compile → upload → monitor → Flutter.

## Setup Flutter Dashboard

**📗 Dokumentasi lengkap: [Flutter Dashboard README](flutter_dashboard/README.md)**

### Quick Start

### Prasyarat
- Flutter SDK (>=3.0)
- Sudah menjalankan `flutterfire configure` (file `firebase_options.dart` sudah tersedia)

### Instalasi

```bash
cd flutter_dashboard
flutter pub get
# Hapus komentar Firebase.initializeApp() di lib/main.dart sudah dilakukan
flutter run
```

> **Catatan untuk Linux**: Jika `flutterfire configure` perlu dijalankan ulang:
> ```bash
> dart pub global activate flutterfire_cli
> flutterfire configure --project=kicaw-smart-room
> ```

> **Perlu panduan lengkap?** Lihat [dokumentasi Flutter lengkap](flutter_dashboard/README.md) untuk architecture, features, dan development guide.

## Parameter Emisi

Perhitungan emisi CO2 yang dicegah berdasarkan jurnal Singh & Dhanekar (2026):

| Parameter | Nilai | Satuan |
|-----------|-------|--------|
| Daya lampu simulasi | 3 | Watt |
| Faktor emisi grid | 0.85 | kg CO2/kWh |
| Energi dihemat | `P × t` | Wh |
| CO2 dicegah | `(Wh / 1000) × 0.85 × 1.000.000` | mg |

## Kontribusi

1. Fork repo ini
2. Buat branch baru: `git checkout -b fitur-anda`
3. Commit perubahan: `git commit -m "feat: menambahkan fitur X"`
4. Push ke branch: `git push origin fitur-anda`
5. Buat Pull Request

## LICENSE

[MIT](LICENSE) © 2026 terra2n
