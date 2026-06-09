# Smart Room eCO2

Proyek Tugas Besar: Prototipe Otomatisasi Lampu Ruangan Berbasis ESP32 untuk Memantau Emisi Karbon Secara Jarak Jauh (Referensi: Singh & Dhanekar, 2026).

## Struktur Repositori
- `esp32_iot/` - Berisi source code C++ (Arduino) untuk mikrokontroler ESP32, sensor PIR, Relay, dan koneksi Firebase.
- `flutter_dashboard/` - Berisi source code Flutter App untuk dashboard pemantauan realtime eCO2.

## Panduan Setup

### 1. Firebase Setup
1. Buat project baru di [Firebase Console](https://console.firebase.google.com/).
2. Aktifkan **Realtime Database**.
3. Atur Rules (hanya untuk testing lokal):
```json
{
  "rules": {
    ".read": "true",
    ".write": "true"
  }
}
```
4. Dapatkan **Database URL** dan **Web API Key** (Project Settings).

### 2. ESP32 Setup
1. Buka `esp32_iot/main.ino` di Arduino IDE.
2. Pastikan Anda telah menginstal library: `Firebase ESP32 Client` (oleh Mobizt).
3. Ubah `WIFI_SSID`, `WIFI_PASSWORD`, `API_KEY`, dan `DATABASE_URL` sesuai milik Anda.
4. Upload ke ESP32.

### 3. Flutter Setup
Karena kita membuat scaffold secara manual, jalankan perintah berikut di dalam folder `flutter_dashboard`:
```bash
# Untuk mengunduh dependensi dan men-generate folder platform (android, web, ios, dll)
flutter create . 
flutter pub get
```
Lalu konfigurasi Firebase untuk Flutter:
```bash
# Pastikan Firebase CLI terinstall
dart pub global activate flutterfire_cli
flutterfire configure --project=NAMA_PROJECT_FIREBASE_ANDA
```
Hapus *comment* `Firebase.initializeApp()` pada `lib/main.dart` dan jalankan aplikasi.

---

## 🚀 Mengunggah ke GitHub (via gh CLI)

Repositori ini siap untuk diunggah menggunakan akun GitHub `terra2n`.
Jalankan skrip berikut di terminal pada direktori `smart_room_eco2`:

```bash
# Pastikan Anda telah login menggunakan akun terra2n
# gh auth login

# 1. Tambahkan semua file ke git tracking
git add .

# 2. Buat commit pertama
git commit -m "feat: inisialisasi project ESP32 IoT dan Flutter Dashboard untuk Tugas Besar eCO2"

# 3. Buat repositori baru di GitHub dengan gh cli
gh repo create terra2n/smart_room_eco2 --public --source=. --remote=origin --push
```
