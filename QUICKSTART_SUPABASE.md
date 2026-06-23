# Quick Start Guide - Dual-Backend Edition

Setup Smart Room dashboard dengan **Firebase** (real-time) + **Supabase** (historis) dalam 30 menit.

---

## 📦 Prasyarat

### Hardware
- [ ] ESP32 Dev Board
- [ ] **HLK-LD2410C Radar Sensor** (sensor utama — deteksi presence)
- [ ] Relay Module 1-channel 5V
- [ ] Lampu LED 3W + kabel jumper
- [ ] USB Cable + Power Supply 5V/2A

### Software
- [ ] Arduino IDE / Arduino CLI (dengan core ESP32)
- [ ] Flutter SDK ≥3.0
- [ ] Akun Firebase (free)
- [ ] Akun Supabase (free)
- [ ] Node.js ≥18

---

## 🚀 Setup dalam 6 Langkah

### Step 1: Setup Firebase (5 menit)

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Buat project (atau pakai `kicaw-smart-room`)
3. Aktifkan **Realtime Database** & **Cloud Firestore** (mode test)
4. Deploy Cloud Functions:
   ```bash
   cd functions
   npm install
   npm run build
   npm run deploy
   ```

### Step 2: Buat Supabase Project (5 menit)

1. Buka [supabase.com](https://supabase.com) → Sign up
2. Klik **New Project**:
   - Name: `smart-room-eco2`
   - Password: (catat!)
   - Region: Singapore
3. Tunggu project ready (2-3 menit)
4. Catat **Project URL** dan **anon key**:
   - Settings → API
   - Copy `Project URL` dan `anon public` key

### Step 3: Setup Database Supabase (5 menit)

1. Di Supabase dashboard → **SQL Editor**
2. Klik **New Query**
3. Copy-paste isi file `supabase/schema.sql`
4. Klik **Run**
5. Verifikasi di **Table Editor**:
   - `room_status`
   - `sensor_logs`
   - `daily_summaries`
   - `activity_logs`

### Step 4: Wiring Hardware (5 menit)

```
ESP32          HLK-LD2410C        Relay Module
GPIO 14     →  OUT (digital)
GPIO 16(RX) →  TX (UART)
GPIO 17(TX) →  RX (UART)
GPIO 27     →                    IN1
5V          →  VCC               VCC
GND         →  GND               GND
```

> **Relay Active LOW**: `HIGH` = mati, `LOW` = nyala

### Step 5: Update ESP32 (10 menit)

> ⚠️ **PENTING**: Install library sebelum compile.

1. **Install library** via Arduino Library Manager:
   - `FirebaseClient` by Mobizt
   - `ArduinoJson` by Benoit Blanchon (**v7**)

2. Buat & isi `esp32_iot/secrets.h`:
   ```cpp
   // WiFi
   #define WIFI_SSID "nama_wifi_kamu"
   #define WIFI_PASSWORD "password_wifi"

   // Firebase
   #define API_KEY "your-firebase-api-key"
   #define DATABASE_URL "https://your-project.firebaseio.com"

   // Supabase
   #define SUPABASE_URL "https://xxxxx.supabase.co"
   #define SUPABASE_ANON_KEY "eyJhbGc..."
   ```

3. Compile & upload:
   ```bash
   cd esp32_iot
   arduino-cli compile --fqbn esp32:esp32:esp32 esp32_iot.ino
   arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 esp32_iot.ino
   ```

4. Buka Serial Monitor & tunggu:
   ```
   Supabase connection: SUCCESS
   ```

### Step 6: Setup Flutter Dashboard (5 menit)

```bash
cd flutter_dashboard
cp .env.example .env
nano .env   # isi SUPABASE_URL & SUPABASE_ANON_KEY
flutter pub get
flutter run
```

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

- **Migration Guide**: `MIGRATION_GUIDE.md` — Panduan detail migrasi dari Firebase
- **Technical Guide**: `SUPABASE_MIGRATION_GUIDE.md` — Detail teknis dan arsitektur
- **Schema Reference**: `supabase/schema.sql` — SQL schema lengkap

---

## 💡 Tips

1. **Test di Supabase dulu**: Sebelum upload ESP32, test manual insert di Table Editor
2. **Monitor usage**: Cek Supabase dashboard → Usage untuk track API calls
3. **Backup data**: Enable automatic backups di Settings → Database
4. **Debug ESP32**: Gunakan Serial Monitor untuk lihat semua request/response

---

## 🎉 Done!

Smart Room dashboard kamu sekarang pakai **Firebase + Supabase** — dual-backend!

**Questions?** Cek `MIGRATION_GUIDE.md` atau buka issue di GitHub.
