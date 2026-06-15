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
|  + PIR      |--------->|  Realtime DB     |<---------|  Dashboard       |
|  + Relay    |  HTTPS   |  (Cloud)         |  onValue |  (Mobile/Web)    |
+-------------+          +------------------+          +------------------+
     |                           |
     | Sensor PIR mendeteksi     | Data: status_lampu,
     | gerakan → relay ON/OFF    | energi_dihemat_wh,
     | Kalkulasi emisi CO2       | co2_dicegah_mg
```

## Struktur Repositori

```
├── esp32_iot/              # Firmware ESP32 (Arduino C++)
│   └── esp32_iot.ino       # Source code utama
├── flutter_dashboard/      # Aplikasi dashboard (Flutter)
│   └── lib/
│       ├── main.dart
│       └── firebase_options.dart
├── .github/workflows/      # GitHub Actions CI
├── .gitignore
├── .gitattributes
├── LICENSE
└── README.md
```

## Kebutuhan Hardware

| Komponen | Spesifikasi | Keterangan |
|----------|-------------|------------|
| ESP32 | Dev Board (30/38 pin) | Microcontroller dengan WiFi |
| Sensor PIR HC-SR501 | 5V, output digital | Deteksi gerakan |
| Relay Module | 1-channel 5V | Kontrol lampu |
| Lampu LED | 10W (simulasi) | Beban yang dikontrol |
| Kabel Jumper | Male-Female / Male-Male | Koneksi komponen |

### Wiring

| Pin ESP32 | Terhubung ke |
|-----------|-------------|
| GPIO 14 | OUT Sensor PIR |
| GPIO 27 | IN Relay Module |
| 5V / 3.3V | VCC Sensor PIR & Relay |
| GND | GND Sensor PIR & Relay |

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

## Setup ESP32 (Arduino IDE)

1. Buka `esp32_iot/esp32_iot.ino` di **Arduino IDE**
2. Install library **Firebase ESP32 Client** oleh Mobizt via Library Manager
3. Ubah kredensial WiFi sesuai jaringan Anda:

```cpp
#define WIFI_SSID "NAMA_WIFI_ANDA"
#define WIFI_PASSWORD "PASSWORD_WIFI_ANDA"
```

4. Upload ke ESP32
5. Buka **Serial Monitor** (115200 baud) untuk melihat status koneksi

## Setup Flutter Dashboard

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

## Parameter Emisi

Perhitungan emisi CO2 yang dicegah berdasarkan jurnal Singh & Dhanekar (2026):

| Parameter | Nilai | Satuan |
|-----------|-------|--------|
| Daya lampu simulasi | 10 | Watt |
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
