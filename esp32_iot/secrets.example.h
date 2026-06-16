// secrets.example.h
// Template untuk konfigurasi WiFi dan Firebase
// CARA PAKAI:
// 1. Copy file ini menjadi "secrets.h"
// 2. Isi dengan kredensial Anda yang sebenarnya
// 3. secrets.h sudah otomatis di-gitignore, aman dari commit

#ifndef SECRETS_H
#define SECRETS_H

// =========================================================================
// KONFIGURASI WiFi
// =========================================================================
#define WIFI_SSID "NAMA_WIFI_ANDA"           // Ganti dengan SSID WiFi Anda
#define WIFI_PASSWORD "PASSWORD_WIFI_ANDA"   // Ganti dengan password WiFi

// =========================================================================
// KONFIGURASI FIREBASE
// =========================================================================
#define API_KEY "YOUR_FIREBASE_API_KEY"                              // Web API Key dari Firebase Console
#define DATABASE_URL "https://YOUR_PROJECT-default-rtdb.firebaseio.com"  // Realtime Database URL

// =========================================================================
// CARA MENDAPATKAN KREDENSIAL FIREBASE:
// =========================================================================
// 1. Buka https://console.firebase.google.com/
// 2. Pilih project Anda
// 3. Klik ⚙️ Settings → Project Settings
// 4. Copy "Web API Key" → paste ke API_KEY
// 5. Buka tab "Realtime Database" di sidebar
// 6. Copy Database URL → paste ke DATABASE_URL
//
// Contoh:
// #define API_KEY "AIzaSyC4Xkz95z-hRSMszA4VUi8mLARpd7QdVFc"
// #define DATABASE_URL "https://kicaw-smart-room-default-rtdb.firebaseio.com"

#endif
