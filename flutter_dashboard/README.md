# Smart Room eCO2 Dashboard

Aplikasi Flutter (Android) untuk monitoring otomatisasi lampu ruangan berbasis ESP32-C3 + HLK-LD2410C. **Dual-backend**: Firebase Realtime DB (live status, energi, heartbeat) + Supabase PostgreSQL (riwayat sensor, aktivitas, ringkasan harian). **Tidak ada kontrol jarak jauh** — lampu 100% otomatis berdasarkan deteksi radar.

## 📱 Features

- **Live Status**: Status lampu, deteksi radar, heartbeat ESP32 — real-time via Firebase `.onValue`
- **Energy Audit**: Total Wh dihemat, CO₂ dicegah (kumulatif + sesi berjalan)
- **Weekly Chart**: Grafik Wh/minggu dari Supabase `daily_summaries`
- **Recent Activity**: 7 event terbaru (`lamp_on`/`lamp_off`) dari Supabase `activity_logs`
- **Statistics**: 30-day chart, all-time total, monthly targets, best day card
- **Carbon Tracking**: CO₂ equivalents (pohon, mobil km, cas HP)
- **Health Check**: Firebase & Supabase reachability via HTTP ping (10s interval) — tidak bergantung heartbeat ESP32
- **Dark/Light Theme**: Material Design 3
- **Navigasi 4 tab**: Home, Statistics, Carbon, Settings

## 🏗️ Architecture

```
lib/
├── main.dart                       # Entry point, init Firebase + Supabase + dotenv
├── app.dart                        # Root widget, bottom nav (4 tab), theme
├── config/
│   ├── firebase_config.dart        # Baca Firebase credentials dari .env
│   └── supabase_config.dart        # Baca Supabase credentials dari .env
├── models/                         # Data models (RoomStatus, EnergyMetric, dll)
│   └── supabase/                   # Supabase-specific models (SensorLog, ActivityLog, dll)
├── services/
│   ├── realtime_service.dart       # Firebase .onValue streams (status, energi, heartbeat, online)
│   ├── supabase_service.dart       # Supabase queries (room_status, logs, summaries)
│   ├── firebase_health_service.dart  # HTTP GET ping ke Firebase RTDB (10s)
│   ├── supabase_health_service.dart  # HTTP HEAD ping ke Supabase REST (10s)
│   ├── carbon_service.dart         # Perhitungan emisi CO2
│   ├── settings_service.dart       # SharedPreferences + theme mode
│   └── firestore_service.dart      # Legacy — tidak digunakan aktif
├── pages/
│   ├── home/                       # Dashboard real-time
│   │   ├── home_page.dart
│   │   └── widgets/
│   │       ├── status_hero_card.dart   # Status lampu + radar
│   │       ├── energy_grid.dart        # Wh, CO2, minutes off
│   │       ├── weekly_chart.dart       # Grafik Wh/minggu
│   │       └── recent_activity.dart    # 7 aktivitas terbaru
│   ├── statistics/                 # Data historis & grafik
│   ├── carbon/                     # Tracking CO2
│   └── settings/                   # Konfigurasi + health check
│       ├── settings_page.dart
│       └── widgets/
│           ├── firebase_section.dart    # Status koneksi Firebase
│           ├── supabase_section.dart    # Status koneksi Supabase
│           ├── theme_section.dart
│           ├── device_section.dart
│           ├── about_section.dart
│           └── ...
├── widgets/                        # Shared components (metric_card, status_chip, dll)
└── theme/                          # Material Design 3
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0 <4.0.0`
- Firebase project with Realtime Database enabled
- Supabase project with 4 tables (`room_status`, `sensor_logs`, `activity_logs`, `daily_summaries`)
- ESP32-C3 hardware (opsional)

### Installation

1. **Clone & enter directory**
   ```bash
   git clone <repository-url>
   cd flutter_dashboard
   ```

2. **Configure `.env`**
   ```bash
   cp .env.example .env
   ```
   Isi dengan kredensial:
   - `SUPABASE_URL` + `SUPABASE_ANON_KEY`
   - `FIREBASE_DATABASE_URL` + `FIREBASE_API_KEY`
   - `FIREBASE_AUTH_EMAIL` + `FIREBASE_AUTH_PASSWORD` (untuk fallback sign-in)

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Firebase Realtime Database
Path: `ruangan_01/`

| Field | Type | Deskripsi |
|-------|------|-----------|
| `status_lampu` | bool | true = nyala, false = mati |
| `status_radar` | bool | true = ada orang |
| `energi_dihemat_wh` | float | Kumulatif Wh |
| `co2_dicegah_mg` | float | Kumulatif CO₂ (mg) |
| `last_heartbeat` | int | Epoch timestamp |
| `radar_distance_cm` | int | Perkiraan jarak (cm) |
| `waktu_mulai_mati` | int | Epoch saat lampu mati |

**Health check**: `FirebaseHealthService` melakukan GET `/.json?shallow=true` setiap 10 detik. Response HTTP apapun = server reachable.

### Supabase Tables
| Tabel | Isi | Diakses dari |
|-------|-----|-------------|
| `room_status` | Status live (single row, UPSERT) | Settings health check |
| `sensor_logs` | Riwayat sensor per 5 detik | Statistics charts |
| `daily_summaries` | Agregasi harian (total Wh, avg CO₂) | Weekly chart, Statistics |
| `activity_logs` | Event: `lamp_on`, `lamp_off`, `motion_detected` | Home (7 terbaru) |

Semua tabel punya kolom `room_name TEXT NOT NULL DEFAULT 'ruangan_01'`.

**Health check**: `SupabaseHealthService` melakukan HEAD `/rest/v1/room_status?select=id&limit=1` dengan header `apikey` + `Authorization: Bearer <key>` setiap 10 detik.

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_database` | Realtime data sync (`.onValue`) |
| `supabase_flutter` | Supabase PostgreSQL queries |
| `flutter_dotenv` | Load `.env` variables |
| `fl_chart` | Interactive charts (weekly, monthly) |
| `google_fonts` | Typography |
| `shared_preferences` | Theme mode + settings cache |
| `http` | Health check HTTP pings |

## 🎨 Pages Overview

### Home
- **Status Hero Card**: Indikator lampu (hijau/abu) + radar (bergerak/diam) + heartbeat (online/offline)
- **Energy Grid**: Wh dihemat, CO₂ dicegah, menit lampu mati
- **Weekly Chart**: Bar chart energi/minggu (fl_chart)
- **Recent Activity**: 7 item terbaru dari Supabase `activity_logs`

### Statistics
- 30-day trend chart, all-time totals, monthly targets, best day card, emission factor info

### Carbon
- Total CO₂ hero, real-world equivalents (pohon, mobil km, cas HP)

### Settings
- **Firebase Section**: Status koneksi (Connected/Disconnected), diperbarui tiap 10s oleh `FirebaseHealthService`
- **Supabase Section**: Status koneksi (Connected/Disconnected), diperbarui tiap 10s oleh `SupabaseHealthService`
- Theme toggle (light/dark)
- Device info + About section

## 🛠️ Development

```bash
# Build APK
flutter build apk --release

# Run tests
flutter test

# Format
flutter format lib/
```

## 📄 License

Academic IoT lab assignment.
