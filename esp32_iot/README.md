# ESP32 Smart Room IoT Firmware

Firmware ESP32 untuk monitoring ruangan pintar dengan sensor radar HLK-LD2410C, kontrol relay otomatis, dan integrasi Firebase Realtime Database.

## 🔧 Hardware Requirements

### Components
- **ESP32 DevKit** (NodeMCU-32S atau compatible)
- **HLK-LD2410C Radar Sensor** (24GHz mmWave presence detection)
- **Relay Module** (1-channel, 5V trigger)
- **Power Supply** (5V/2A minimum)
- **LED/Lamp** (controlled via relay)

### Pin Configuration

| Component | ESP32 Pin | Notes |
|-----------|-----------|-------|
| Radar OUT (Digital) | GPIO 14 | Presence detection signal |
| Radar RX (UART) | GPIO 16 | UART communication (TX → RX) |
| Radar TX (UART) | GPIO 17 | UART communication (RX → TX) |
| Relay IN1 | GPIO 27 | Active LOW relay control |
| Radar VCC | 5V | Power supply |
| Radar GND | GND | Ground |
| Relay VCC | 5V | Power supply |
| Relay GND | GND | Ground |

## 📐 Wiring Diagram

### Visual Diagram

> **📸 Tambahkan gambar rangkaian Anda di sini:**
> 
> Letakkan file gambar di folder `assets/` lalu uncomment salah satu baris di bawah:

```markdown
<!-- Uncomment setelah menambahkan gambar -->
<!-- ![Wiring Diagram](assets/wiring_diagram.png) -->
<!-- ![Breadboard Layout](assets/breadboard_layout.png) -->
<!-- ![Assembled Hardware](assets/assembled_hardware.jpg) -->
```

### ASCII Diagram (Text-Based)

```
ESP32                    HLK-LD2410C Radar
┌──────────┐            ┌───────────────┐
│ GPIO 14  ├────────────┤ OUT (Digital) │
│ GPIO 16  ├────────────┤ TX (UART)     │
│ GPIO 17  ├────────────┤ RX (UART)     │
│ 5V       ├────────────┤ VCC           │
│ GND      ├────────────┤ GND           │
└──────────┘            └───────────────┘

ESP32                    Relay Module
┌──────────┐            ┌──────────┐
│ GPIO 27  ├────────────┤ IN1      │
│ 5V       ├────────────┤ VCC      │
│ GND      ├────────────┤ GND      │
└──────────┘            └──────────┘
                        │ COM  NO  NC│
                        └────┬───────┘
                             │
                          [LAMP/LED]
```

## 🚀 Getting Started

### 1. Install Arduino IDE & Libraries

**Required Libraries** (via Library Manager):
- **FirebaseClient** by Mobizt (v1.3.0+)
- **WiFi** (built-in)
- **WiFiClientSecure** (built-in)

### 2. Configure WiFi & Firebase

**⚠️ PENTING:** Sebelum compile, Anda **HARUS** mengisi kredensial WiFi dan Firebase.

#### Step-by-Step Configuration:

**A. Setup Secrets File**

1. **Copy file template:**
   ```bash
   cd esp32_iot
   cp secrets.example.h secrets.h
   ```

2. **Edit `secrets.h`** dengan text editor (Arduino IDE, VS Code, Notepad++, dll)

**B. WiFi Credentials**

Edit `secrets.h`, cari bagian WiFi:

**SEBELUM:**
```cpp
#define WIFI_SSID "NAMA_WIFI_ANDA"
#define WIFI_PASSWORD "PASSWORD_WIFI_ANDA"
```

**SESUDAH** (contoh):
```cpp
#define WIFI_SSID "Rumah_WiFi_5G"
#define WIFI_PASSWORD "password12345"
```

> **Catatan:** ESP32 hanya support WiFi 2.4GHz, pastikan router Anda tidak restricted ke 5GHz saja.

**C. Firebase Credentials**

Dapatkan kredensial dari Firebase Console:

1. **Buka** [Firebase Console](https://console.firebase.google.com/)
2. **Pilih** project Anda (contoh: `kicaw-smart-room`)
3. **Klik** ⚙️ Settings → **Project Settings**
4. **Copy** **Web API Key** dari tab **General**
5. **Buka** tab **Realtime Database** di sidebar
6. **Copy** Database URL (contoh: `https://kicaw-smart-room-default-rtdb.firebaseio.com`)

Edit `secrets.h`, cari bagian Firebase:

**SEBELUM:**
```cpp
#define API_KEY "YOUR_FIREBASE_API_KEY"
#define DATABASE_URL "https://YOUR_PROJECT-default-rtdb.firebaseio.com"
```

**SESUDAH** (ganti dengan milik Anda):
```cpp
#define API_KEY "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
#define DATABASE_URL "https://your-project-id-default-rtdb.firebaseio.com"
```

> **⚠️ KEAMANAN:** File `secrets.h` sudah otomatis di-gitignore. Jangan commit credentials ke Git!

**D. Verify Configuration**

Sebelum upload, pastikan:
- ✅ File `secrets.h` sudah dibuat (copy dari `secrets.example.h`)
- ✅ WiFi SSID dan password sudah diisi
- ✅ Firebase API Key sudah diisi (bukan yang default)
- ✅ Database URL sesuai dengan project Firebase Anda
- ✅ Tidak ada typo atau kutip ganda yang hilang

### 3. Upload Firmware

1. Connect ESP32 via USB
2. Select board: **Tools** → **Board** → **ESP32 Dev Module**
3. Select port: **Tools** → **Port** → **(your COM port)**
4. Upload: **Sketch** → **Upload** (or Ctrl+U)

### 4. Monitor Serial Output

Open Serial Monitor (Ctrl+Shift+M) at **115200 baud** to view:
- WiFi connection status
- Firebase sync status
- Radar detection events
- Energy consumption logs

## 📊 Firebase Database Structure

The firmware writes to the following paths:

```json
{
  "sensors": {
    "eco2": 400.5,           // Calculated CO2 (ppm)
    "temperature": 28.3,     // Room temperature (°C)
    "humidity": 65.2,        // Relative humidity (%)
    "timestamp": 1234567890, // Unix timestamp
    "occupied": true         // Radar presence status
  },
  "energy": {
    "total_wh": 125.4,       // Cumulative energy (Wh)
    "total_co2_mg": 106.59,  // Cumulative CO2 (mg)
    "lamp_on": true          // Current lamp state
  },
  "radar": {
    "gate_moving": 50,       // Moving sensitivity (0-100)
    "gate_stationary": 50    // Stationary sensitivity (0-100)
  }
}
```

## ⚙️ Configuration Parameters

### Radar Settings

```cpp
const byte BATAS_GERBANG_JARAK = 0;  // Gate 0 = < 75 cm detection range
const int THRESHOLD_MASUK  = 10;      // Trigger ON after 0.5s (10 × 50ms)
const int THRESHOLD_KOSONG = 20;      // Trigger OFF after 1.0s (20 × 50ms)
```

**Adjust Detection Range:**
- `Gate 0` = 0-75 cm
- `Gate 1` = 75-150 cm
- `Gate 2` = 150-225 cm
- ... (up to Gate 8 = 525-600 cm)

### Energy Audit

```cpp
const float DAYA_LAMPU_WATT   = 3.0;   // Lamp power consumption (W)
const float FAKTOR_EMISI_GRID = 0.85;  // Grid emission factor (kgCO2/kWh)
```

**Customize for Your Lamp:**
- Measure actual lamp wattage with power meter
- Update `DAYA_LAMPU_WATT` accordingly
- Adjust `FAKTOR_EMISI_GRID` based on your region's grid mix

## 🔍 How It Works

### 1. Radar Detection Flow

```
Radar HIGH (person detected)
    ↓
hitungHigh++ (increment counter)
    ↓
hitungHigh >= THRESHOLD_MASUK (10)?
    ↓ YES
Turn ON relay → Lamp ON
    ↓
Update Firebase: occupied = true
```

```
Radar LOW (no person)
    ↓
hitungLow++ (increment counter)
    ↓
hitungLow >= THRESHOLD_KOSONG (20)?
    ↓ YES
Turn OFF relay → Lamp OFF
    ↓
Update Firebase: occupied = false
Calculate energy & CO2 emission
```

### 2. Firebase Live Config

The firmware listens to `/radar/gate_moving` and `/radar/gate_stationary` for real-time sensitivity adjustments from the Flutter dashboard.

**Example:**
```json
{
  "radar": {
    "gate_moving": 75,       // Set moving sensitivity to 75%
    "gate_stationary": 60    // Set stationary sensitivity to 60%
  }
}
```

The ESP32 will automatically apply these values to the HLK-LD2410C via UART.

### 3. Energy Calculation

```cpp
energyDelta_Wh = (DAYA_LAMPU_WATT × duration_ms) / 3600000
co2Delta_mg = energyDelta_Wh × FAKTOR_EMISI_GRID
```

## 🛠️ Troubleshooting

### Issue: WiFi Connection Failed

**Check:**
- SSID and password are correct
- Router is 2.4GHz (ESP32 doesn't support 5GHz)
- WiFi signal strength is adequate

**Fix:**
```cpp
Serial.println(WiFi.localIP());  // Should print valid IP
```

### Issue: Firebase Not Syncing

**Check:**
- `API_KEY` and `DATABASE_URL` are correct
- Firebase Realtime Database rules allow writes:
  ```json
  {
    "rules": {
      ".read": true,
      ".write": true
    }
  }
  ```

### Issue: Radar Not Detecting

**Check:**
- Wiring: GPIO 14 connected to OUT pin
- Power: Radar VCC connected to 5V (not 3.3V)
- Serial output shows `[RADAR] Occupancy: HIGH/LOW`

**Test Radar UART:**
```cpp
radarBacaKonfigurasi(&cfg);
Serial.println(cfg.maxMovingGate);  // Should print 0-8
```

### Issue: Relay Not Switching

**Check:**
- Relay module is active LOW (HIGH = OFF, LOW = ON)
- GPIO 27 → IN1 connection is secure
- Relay VCC connected to 5V power source

**Test Relay:**
```cpp
digitalWrite(PIN_RELAY, LOW);   // Should turn ON
digitalWrite(PIN_RELAY, HIGH);  // Should turn OFF
```

## 📁 Project Structure

```
esp32_iot/
├── esp32_iot.ino         # Main firmware
├── firebase_cmd.h        # Firebase command handlers (radar config)
├── ld2410_uart.h         # HLK-LD2410C UART protocol library
└── README.md             # This file
```

## 🔐 Security Notes

**⚠️ WARNING:** The current code exposes Firebase credentials in plaintext.

**For Production:**
1. Use **Environment Variables** or **Secrets Manager**
2. Set **Firebase Security Rules** to restrict unauthorized access
3. Enable **Firebase App Check** for additional protection

## 📚 References

- [HLK-LD2410C Datasheet](https://www.hlktech.net/index.php?id=988)
- [ESP32 Arduino Core](https://github.com/espressif/arduino-esp32)
- [FirebaseClient Library](https://github.com/mobizt/FirebaseClient)
- [Firebase Realtime Database Docs](https://firebase.google.com/docs/database)

## 📄 License

This project is part of an academic IoT lab assignment.

## 🤝 Contributing

Issues and pull requests are welcome for bug fixes and improvements.
