# Quick Start Guide - Supabase Edition

Setup Smart Room dashboard dengan Supabase dalam 30 menit.

---

## 📦 Apa yang Kamu Butuhkan

### Hardware
- [ ] ESP32 Dev Board
- [ ] PIR Motion Sensor
- [ ] Relay Module
- [ ] HLK-LD2410 Radar Sensor (opsional)
- [ ] USB Cable + Power Supply

### Software
- [ ] Arduino IDE / PlatformIO
- [ ] Flutter SDK
- [ ] Akun Supabase (free)

---

## 🚀 Setup dalam 5 Langkah

### Step 1: Buat Supabase Project (5 menit)

1. Buka [supabase.com](https://supabase.com) → Sign up
2. Klik **New Project**:
   - Name: `smart-room`
   - Password: (catat!)
   - Region: Singapore
3. Tunggu project ready (2-3 menit)
4. Catat **Project URL** dan **anon key**:
   - Settings → API
   - Copy `Project URL` dan `anon public` key

### Step 2: Setup Database (5 menit)

1. Di Supabase dashboard → **SQL Editor**
2. Klik **New Query**
3. Copy-paste isi file `supabase/schema.sql`
4. Klik **Run**
5. Verifikasi: Table Editor harus muncul 4 tabel:
   - `room_status`
   - `sensor_logs`
   - `daily_summaries`
   - `activity_logs`

### Step 3: Update ESP32 (10 menit)

1. Buka `esp32_iot/secrets.h`
2. Isi credentials (semua dalam satu file):
   ```cpp
   // WiFi
   #define WIFI_SSID "nama_wifi_kamu"
   #define WIFI_PASSWORD "password_wifi"
   
   // Firebase (jika masih pakai)
   #define API_KEY "your-firebase-api-key"
   #define DATABASE_URL "https://your-project.firebaseio.com"
   
   // Supabase
   #define SUPABASE_URL "https://xxxxx.supabase.co"
   #define SUPABASE_ANON_KEY "eyJhbGc..."
   ```
3. Buka `esp32_iot/esp32_iot.ino` di Arduino IDE
4. Install library (jika belum):
   - ArduinoJson (by Benoit Blanchon)
5. Upload ke ESP32
6. Buka Serial Monitor (115200 baud)
7. Tunggu sampai muncul: `Supabase connection: SUCCESS`

### Step 4: Update Flutter (5 menit)

1. Salin `.env.example` menjadi `.env` di folder `flutter_dashboard`:
   ```bash
   cp flutter_dashboard/.env.example flutter_dashboard/.env
   ```
2. Isi kredensial di `.env`:
   ```env
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGc...
   ```
3. Install dependencies:
   ```bash
   cd flutter_dashboard
   flutter pub get
   ```
4. Run app:
   ```bash
   flutter run
   ```

### Step 5: Test (5 menit)

1. **Cek ESP32**:
   - Serial Monitor harus push data setiap 5 detik
   - Cek Supabase Table Editor → `sensor_logs` harus ada data baru

2. **Cek Flutter**:
   - Home page harus tampilkan data real-time
   - Gerakkan tangan → motion indicator harus update
   - Statistics page harus tampilkan chart dari data historical

---

## ✅ Checklist Sukses

- [ ] ESP32 connect ke WiFi
- [ ] ESP32 connect ke Supabase (Serial Monitor: "SUCCESS")
- [ ] Data muncul di `room_status` table
- [ ] Data muncul di `sensor_logs` table
- [ ] Flutter app launch tanpa error
- [ ] Flutter tampilkan data real-time
- [ ] Motion detection bekerja

---

## 🎯 Fitur yang Sudah Jalan

### ✅ Real-time Data
- Motion detection
- Lamp control
- Sensor readings (temperature, humidity, CO2)

### ✅ Historical Data
- Sensor logs (setiap 5 detik)
- Daily summaries (aggregated)
- Activity logs (events)

### ✅ Dashboard
- Home: Real-time status + recent activity
- Statistics: 30-day trend + monthly targets
- Carbon: CO2 tracking + real-world equivalents

---

## 🔧 Troubleshooting Cepat

### ESP32 tidak connect Supabase
```
Supabase connection: FAILED
```
**Fix**: Cek URL dan anon key di `secrets.h` (bagian Supabase credentials)

### Flutter tidak dapat data
**Fix**: 
1. Cek berkas `.env` (URL dan Key)
2. Pastikan ESP32 sudah push data (cek Table Editor)
3. Restart Flutter app

### Data tidak real-time
**Fix**: Pastikan sudah jalankan SQL schema (enable realtime)

---

## 📚 Dokumentasi Lengkap

- **Migration Guide**: `MIGRATION_GUIDE.md` - Panduan detail migrasi dari Firebase
- **Technical Guide**: `SUPABASE_MIGRATION_GUIDE.md` - Detail teknis dan arsitektur
- **Schema Reference**: `supabase/schema.sql` - SQL schema lengkap

---

## 💡 Tips

1. **Test di Supabase dulu**: Sebelum upload ESP32, test manual insert di Table Editor
2. **Monitor usage**: Cek Supabase dashboard → Usage untuk track API calls
3. **Backup data**: Enable automatic backups di Settings → Database
4. **Debug ESP32**: Gunakan Serial Monitor untuk lihat semua request/response

---

## 🎉 Done!

Smart Room dashboard kamu sekarang pakai Supabase - **FREE forever, no credit card required!**

**Next steps**:
- Customize dashboard UI
- Add more sensors
- Setup alerts/notifications
- Share dengan tim

**Questions?** Cek `MIGRATION_GUIDE.md` atau buka issue di GitHub.
