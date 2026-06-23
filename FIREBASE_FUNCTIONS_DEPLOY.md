# 🚀 Firebase Cloud Functions Deployment Guide

## 📋 Overview

Cloud Functions ini akan otomatis sync data dari **Realtime Database** (ESP32) ke **Firestore** (Flutter Dashboard).

### Data Flow
```
ESP32 → Realtime DB → Cloud Functions → Firestore → Flutter
```

### Functions yang Dibuat

1. **onLampChange** - Log aktivitas saat lampu nyala/mati
2. **onEnergyUpdate** - Update daily & monthly logs saat energi berubah
3. **onRadarChange** - Log aktivitas saat ada/tidak ada orang

---

## 🔧 Prerequisites

### 1. Install Firebase CLI
```bash
# macOS/Linux
curl -sL https://firebase.tools | bash

# Windows
# Download dari https://firebase.google.com/docs/cli
```

### 2. Install Node.js (v18+)
```bash
# Check version
node --version

# Install via nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

### 3. Login ke Firebase
```bash
firebase login
```

---

## 📦 Deploy Cloud Functions

### Step 1: Install Dependencies
```bash
cd functions
npm install
```

### Step 2: Build TypeScript
```bash
npm run build
```

### Step 3: Deploy ke Firebase
```bash
# Deploy hanya functions
firebase deploy --only functions

# Atau deploy semua (database rules, firestore rules, functions)
firebase deploy
```

**Expected Output:**
```
✔  functions: Finished running predeploy script.
i  functions: preparing functions directory for uploading
i  functions: packaged functions (X.XX MB) for uploading
✔  functions: functions folder uploaded successfully
i  functions: creating Node.js 18 function onLampChange(us-central1)...
i  functions: creating Node.js 18 function onEnergyUpdate(us-central1)...
i  functions: creating Node.js 18 function onRadarChange(us-central1)...
✔  functions: all functions deployed successfully
```

---

## ✅ Verify Deployment

### Check di Firebase Console
1. Buka https://console.firebase.google.com
2. Pilih project: **kicaw-smart-room**
3. Klik menu **Functions** di sidebar
4. Pastikan 3 functions muncul:
   - `onLampChange`
   - `onEnergyUpdate`
   - `onRadarChange`

### Check Logs
```bash
# Real-time logs
firebase functions:log

# Filter specific function
firebase functions:log --only onLampChange
```

---

## 🧪 Testing

### Test 1: Trigger onLampChange
1. Nyalakan lampu (ESP32 detect motion)
2. Check Firestore → `activity_logs` collection
3. Harus muncul document baru dengan:
   ```json
   {
     "event": "Lampu dinyalakan",
     "type": "on",
     "timestamp": "2026-06-17T..."
   }
   ```

### Test 2: Trigger onEnergyUpdate
1. Tunggu energi berubah (ESP32 push setiap 5 detik)
2. Check Firestore → `daily_logs` collection
3. Harus muncul document dengan tanggal hari ini (e.g., `2026-06-17`)

### Test 3: Trigger onRadarChange
1. Masuk/keluar ruangan
2. Check Firestore → `activity_logs` collection
3. Harus muncul:
   ```json
   {
     "event": "Orang terdeteksi",
     "type": "presence"
   }
   ```

---

## 🔍 Troubleshooting

### Error: "functions predeploy error"
```bash
# Masuk ke folder functions
cd functions

# Clean install
rm -rf node_modules
npm install
npm run build

# Deploy lagi
firebase deploy --only functions
```

### Error: "Permission denied"
```bash
# Pastikan udah login
firebase login

# Re-authenticate
firebase login --reauth
```

### Functions tidak trigger
1. Check logs: `firebase functions:log`
2. Pastikan ESP32 push ke path yang benar:
   - `ruangan_01/status_lampu`
   - `ruangan_01/energi_dihemat_wh`
   - `ruangan_01/status_radar`

3. Check Realtime Database di Firebase Console, pastikan data berubah

### Firestore tidak terupdate
1. Check Firestore rules (harus allow write):
   ```
   match /{document=**} {
     allow read, write: if true;
   }
   ```
2. Check function logs untuk error messages
3. Verify Firestore collections: `activity_logs`, `daily_logs`, `monthly_logs`

---

## 📊 Expected Firestore Collections

### 1. activity_logs
```json
{
  "event": "Lampu dinyalakan",
  "type": "on",
  "wh_saved": 12.5,
  "co2_mg": 8.9,
  "timestamp": Timestamp("2026-06-17T10:30:00")
}
```

### 2. daily_logs (document ID = "2026-06-17")
```json
{
  "date": "2026-06-17",
  "wh_saved": 12.5,
  "co2_mg": 8.9,
  "sessions": 5,
  "minutes_off": 250,
  "updated_at": Timestamp("2026-06-17T12:00:00")
}
```

### 3. monthly_logs (document ID = "2026-06")
```json
{
  "month": "2026-06",
  "total_wh": 12.5,
  "total_co2": 8.9,
  "total_sessions": 5,
  "total_minutes_off": 250,
  "updated_at": Timestamp("2026-06-17T12:00:00")
}
```

---

## 🔄 Update Functions

Kalau ada perubahan di `src/index.ts`:

```bash
cd functions
npm run build
firebase deploy --only functions
```

### Recent Improvements & Optimizations

* **Zero-Read Incremental DB Updates:** Previously, updating daily logs required querying the entire activity collection to calculate session counts, and monthly updates queried all daily logs. We optimized this by using Firestore `admin.firestore.FieldValue.increment()`. Count increments are triggered directly during state transitions, reducing Firestore reads to **0 reads** during updates.
* **Lamp Off Duration Correction:** Corrected the unit mismatch where `Date.now()` (milliseconds) was subtracted by `waktuMulaiMati` (seconds). The calculation is now properly normalized: `(Date.now() / 1000) - waktuMulaiMati`.
* **WIB Timezone Consistency:** Local date methods (`getFullYear`, `getMonth`) were replaced with UTC methods (`getUTCFullYear`, `getUTCMonth`) to guarantee consistent WIB (UTC+7) calculations on serverless cloud servers.

---

## 💰 Cost Estimation

Firebase Cloud Functions **Free Tier**:
- ✅ 2M invocations/month
- ✅ 400,000 GB-seconds compute time
- ✅ 200,000 CPU-seconds
- ✅ 200,000 outgoing requests

**Smart Room Usage**:
- ~300 invocations/day (lamp on/off + energy updates + radar changes)
- ~9,000 invocations/month
- **Well within free tier** ✅

---

## 🗑️ Undeploy (Kalau Perlu)

```bash
# Hapus semua functions
firebase functions:delete onLampChange onEnergyUpdate onRadarChange

# Atau hapus semua
firebase functions:delete --force
```

---

## 📞 Support

Kalau ada masalah:
1. Check `firebase functions:log`
2. Check Firestore console untuk data baru
3. Verify ESP32 push data ke Realtime DB
4. Check Firebase Console → Functions → Logs

---

## ✅ Deployment Checklist

- [ ] Firebase CLI installed (`firebase --version`)
- [ ] Node.js v18+ installed (`node --version`)
- [ ] Logged in to Firebase (`firebase login`)
- [ ] Dependencies installed (`npm install` di folder `functions`)
- [ ] TypeScript compiled (`npm run build`)
- [ ] Functions deployed (`firebase deploy --only functions`)
- [ ] Functions visible di Firebase Console
- [ ] ESP32 push data ke Realtime DB
- [ ] Firestore collections terisi otomatis
- [ ] Flutter Dashboard bisa baca data dari Firestore

---

## 🎯 Next Steps

Setelah Cloud Functions jalan:
1. ✅ ESP32 push data → Realtime DB
2. ✅ Cloud Functions trigger → Firestore
3. ✅ Flutter Dashboard baca dari Firestore
4. 📊 Weekly Chart & Recent Activity widgets update otomatis

**Done!** 🎉 Dashboard sekarang fully connected ke Firebase!
