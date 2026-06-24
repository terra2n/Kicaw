# Panduan Migrasi: Firebase ke Supabase

Panduan lengkap untuk memindahkan Smart Room dashboard dari Firebase ke Supabase.

---

## 📋 Checklist Migrasi

### Phase 1: Setup Supabase (15-30 menit)
- [x] Buat akun Supabase
- [x] Buat project baru
- [x] Jalankan SQL schema
- [x] Dapatkan credentials (URL + Anon Key)

### Phase 2: Update Flutter (10-15 menit)
- [x] Install dependencies
- [x] Update `supabase_config.dart`
- [ ] Test koneksi

### Phase 3: Update ESP32 (15-20 menit)
- [ ] Install library
- [x] Update `secrets.h` (WiFi + Firebase + Supabase)
- [ ] Upload firmware
- [ ] Test koneksi

### Phase 4: Testing & Verification (10 menit)
- [ ] Test real-time data
- [ ] Test historical data
- [ ] Test activity logs
- [ ] Cleanup Firebase (opsional)

---

## 🚀 Phase 1: Setup Supabase

### 1.1 Buat Akun Supabase

1. Buka [supabase.com](https://supabase.com)
2. Klik "Start your project"
3. Sign up dengan GitHub/Google/Email
4. **PENTING**: Pilih "Hobby" plan (FREE, no credit card)

### 1.2 Buat Project Baru

1. Klik "New Project"
2. Isi detail:
   - **Name**: `smart-room-eco2` (atau nama lain)
   - **Database Password**: Buat password yang kuat (catat!)
   - **Region**: Pilih yang terdekat (Singapore untuk Indonesia)
   - **Pricing Plan**: Hobby (Free)
3. Klik "Create new project"
4. Tunggu 2-3 menit sampai project ready

### 1.3 Jalankan SQL Schema

1. Di dashboard Supabase, klik **SQL Editor** (icon `</>` di sidebar kiri)
2. Klik **New Query**
3. Copy isi file `supabase/schema.sql`
4. Paste ke SQL Editor
5. Klik **Run** (atau tekan Ctrl+Enter)
6. Tunggu sampai muncul "Success. No rows returned"

**Verifikasi**:
- Klik **Table Editor** di sidebar
- Harus muncul 4 tabel:
  - `room_status`
  - `sensor_logs`
  - `daily_summaries`
  - `activity_logs`

**(Opsional) Seeding Data**:
Untuk mengisi data simulasi historis 30 hari ke database cloud Supabase, Anda dapat mengeksekusi berkas seeder menggunakan Supabase CLI:
```bash
supabase db query --linked --file supabase/seed.sql
```
Atau salin kode di `supabase/seed.sql` ke SQL Editor, lalu klik **Run**.


### 1.4 Dapatkan Credentials

1. Klik **Project Settings** (icon gear di sidebar kiri)
2. Klik **API**
3. Catat 2 hal ini:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGc...` (panjang banget)

**PENTING**:
- Gunakan `anon public key`, BUKAN `service_role key`
- Anon key aman untuk ESP32 dan Flutter
- Service role key HANYA untuk backend (jangan di-expose!)

---

## 📱 Phase 2: Update Flutter

### 2.1 Install Dependencies

```bash
cd flutter_dashboard
flutter pub get
```

**Dependencies yang ditambah**:
- `supabase_flutter: ^2.0.0`

### 2.2 Update Supabase Config

Salin berkas `.env.example` menjadi `.env` di direktori `flutter_dashboard`:

```bash
cp .env.example .env
```

Edit berkas `.env` tersebut dan isi kredensial Supabase Anda:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
```

**Tips**:
- Salin URL dan Key dari Supabase dashboard (Settings > API)
- Pastikan tidak ada spasi tambahan di awal/akhir baris
- Key anon public sangat panjang, pastikan tersalin seutuhnya

### 2.3 Test Koneksi

```bash
flutter run
```

**Yang harus dicek**:
1. App harus launch tanpa error
2. Di debug console, harus muncul: `✓ Supabase initialized`
3. Home page harus load (walau data masih kosong)

**Jika error**:
- `Supabase initialization failed`: Cek URL dan Key
- `Connection refused`: Cek internet
- `401 Unauthorized`: Key salah atau RLS policy blokir

---

## 🔌 Phase 3: Update ESP32

### 3.1 Install Library

Di Arduino IDE:
1. **Tools** > **Manage Libraries**
2. Search dan install:
   - `ArduinoJson` (by Benoit Blanchon)
   - `WiFiClientSecure` (built-in ESP32)

Di PlatformIO, edit `platformio.ini`:
```ini
lib_deps =
    bblanchon/ArduinoJson@^6.21.0
```

### 3.2 Update Secrets

Edit file `secrets.h` (semua credentials dalam satu file):

```cpp
// WiFi
#define WIFI_SSID "YOUR_WIFI_SSID"           // GANTI
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"   // GANTI

// Firebase (jika masih pakai)
#define API_KEY "your-firebase-api-key"
#define DATABASE_URL "https://your-project.firebaseio.com"

// Supabase
#define SUPABASE_URL "https://xxxxx.supabase.co"  // GANTI
#define SUPABASE_ANON_KEY "eyJhbGc..."             // GANTI
```

**Tips**:
- Semua credentials sekarang dalam satu file `secrets.h`
- WiFi credentials sama seperti yang lama
- Copy URL dan Key dari Supabase dashboard
- Pastikan tidak ada typo

### 3.3 Upload Firmware

**PENTING**: Gunakan file `esp32_iot.ino` (sudah di-update untuk support Supabase)

1. Buka `esp32_iot.ino` di Arduino IDE
2. Pilih board: **ESP32 Dev Module**
3. Pilih port yang benar
4. Klik **Upload**

**Verifikasi di Serial Monitor** (115200 baud):
```
=== Smart Room ESP32 - Supabase Edition ===
Connecting to WiFi...
WiFi connected!
IP: 192.168.1.x
Waiting for NTP sync...
NTP synced!
Radar initialized
Testing Supabase connection...
Supabase connection: SUCCESS

=== Setup Complete ===
```

**Jika error**:
- `WiFi connected failed`: Cek WiFi credentials
- `NTP sync failed`: Cek internet
- `Supabase connection: FAILED`: Cek URL dan Key

### 3.4 Test Data Push

Setelah upload sukses, ESP32 akan otomatis:
1. Push ke `room_status` setiap 5 detik
2. Insert ke `sensor_logs` setiap 5 detik
3. Insert ke `activity_logs` saat motion detected/cleared

**Cek di Supabase**:
1. Buka **Table Editor**
2. Klik `room_status` → harus ada 1 row dengan data terbaru
3. Klik `sensor_logs` → harus ada rows baru setiap 5 detik
4. Klik `activity_logs` → coba gerakkan tangan di depan sensor

---

## ✅ Phase 4: Testing & Verification

### 4.1 Test Real-time Data

1. Buka Flutter app
2. Di Home page, cek:
   - **Room Status**: Harus update real-time saat motion detected
   - **Motion indicator**: Harus berubah saat ada/tidak ada gerakan
   - **Lamp status**: Harus sinkron dengan relay

**Test manual**:
- Gerakkan tangan di depan sensor → Flutter harus update dalam 2-3 detik
- Tunggu sampai motion clear → Flutter harus update dalam 2-3 detik

### 4.2 Test Historical Data

1. Tunggu 5-10 menit agar ada data di `sensor_logs`
2. Buka Flutter app → Statistics page
3. Cek:
   - **30 Days Chart**: Harus muncul grafik dari data historical
   - **Daily Summaries**: Harus ada data aggregasi

**Verifikasi di Supabase**:
- Buka **Table Editor** → `sensor_logs`
- Harus ada ratusan rows (1 row setiap 5 detik)
- Timestamp harus benar (UTC)

### 4.3 Test Activity Logs

1. Buka Flutter app → Home page
2. Scroll ke bawah, cek **Recent Activity**
3. Harus muncul list aktivitas:
   - "Motion detected in room"
   - "Motion cleared"

**Verifikasi di Supabase**:
- Buka **Table Editor** → `activity_logs`
- Harus ada rows dengan `event_type` = `motion_detected` atau `motion_cleared`

### 4.4 Test Edge Cases

**WiFi disconnect**:
1. Matikan WiFi router sebentar
2. ESP32 harus auto-reconnect
3. Flutter harus auto-recover saat data datang lagi

**Supabase downtime** (rare):
1. Jika Supabase maintenance, ESP32 akan retry otomatis
2. Data tidak akan hilang (stored di ESP32 memory)

**ESP32 restart**:
1. Restart ESP32
2. Flutter harus detect offline (no heartbeat)
3. Setelah restart, Flutter harus online lagi

---

## 🧹 Cleanup Firebase (Opsional)

Setelah yakin Supabase berjalan lancar, kamu bisa:

### Opsi A: Keep Firebase (Recommended)
- Biarkan Firebase tetap jalan sebagai backup
- ESP32 tetap push ke Firebase (dual-write)
- Flutter pakai Supabase, Firebase sebagai fallback

### Opsi B: Remove Firebase
1. Hapus Firebase dependencies dari `pubspec.yaml`:
   ```yaml
   # Hapus:
   # firebase_core: ^2.24.2
   # firebase_database: ^10.4.0
   # cloud_firestore: ^4.13.5
   ```
2. Hapus import Firebase dari `main.dart`
3. Hapus file `firebase_options.dart`
4. Hapus Firebase code dari ESP32

**WARNING**: Pastikan Supabase sudah stabil sebelum remove Firebase!

---

## 🐛 Troubleshooting

### Problem: ESP32 tidak connect ke Supabase

**Symptoms**:
```
Supabase connection: FAILED
```

**Solutions**:
1. Cek URL dan Key di `secrets.h` (bagian Supabase credentials)
2. Cek WiFi credentials
3. Cek apakah project Supabase sudah active
4. Coba test URL di browser: `https://xxxxx.supabase.co/rest/v1/`

### Problem: Flutter tidak dapat data

**Symptoms**:
- Home page loading terus
- Tidak ada data yang muncul

**Solutions**:
1. Cek file `.env` (URL dan Key)
2. Cek RLS policies di Supabase (harus allow anonymous read)
3. Cek apakah ESP32 sudah push data (cek Table Editor)
4. Restart Flutter app

### Problem: Data tidak real-time

**Symptoms**:
- Data update tapi lambat (lebih dari 5 detik)
- Perlu refresh manual

**Solutions**:
1. Pastikan `ALTER PUBLICATION supabase_realtime ADD TABLE ...` sudah dijalankan
2. Cek apakah menggunakan `.stream()` bukan `.select()`
3. Cek koneksi internet (ESP32 dan Flutter)

### Problem: Timestamp salah

**Symptoms**:
- Waktu di database tidak sesuai waktu lokal

**Solutions**:
- Supabase simpan dalam UTC (normal)
- Flutter akan convert ke local time otomatis
- Jangan manual adjust timezone di ESP32

---

## 📊 Perbandingan Firebase vs Supabase

| Feature | Firebase | Supabase |
|---------|----------|----------|
| **Database** | Realtime DB + Firestore | PostgreSQL |
| **Real-time** | ✓ Native | ✓ Native |
| **Free Tier** | Limited (need Blaze for more) | Generous (no credit card) |
| **Pricing** | Pay-as-you-go (Blaze) | Free forever (Hobby plan) |
| **Query Language** | NoSQL | SQL (lebih powerful) |
| **Setup** | Easy | Easy |
| **Migration Effort** | - | Medium (2-3 hours) |

---

## 🎯 Next Steps

Setelah migrasi sukses:

1. **Monitor usage**: Cek Supabase dashboard → Usage
   - Database size
   - API requests
   - Bandwidth

2. **Setup backups**: Enable automatic backups (Settings > Database)

3. **Optimize queries**: 
   - Add indexes jika query lambat
   - Use pagination untuk large datasets

4. **Add more features**:
   - User authentication (Supabase Auth)
   - File storage (Supabase Storage)
   - Edge Functions (Supabase Functions)

---

## 📞 Support

**Supabase**:
- Docs: https://supabase.com/docs
- Discord: https://discord.supabase.com
- GitHub: https://github.com/supabase/supabase

**Project Issues**:
- Cek file `SUPABASE_MIGRATION_GUIDE.md` untuk detail teknis
- Review kode di `supabase_client.h` dan `supabase_service.dart`

---

**Good luck! 🚀**
