# Smart Room eCO2 Dashboard

Flutter dashboard application for real-time monitoring of Smart Room environmental data (eCO2, temperature, humidity, occupancy) using ESP32 sensors with Firebase backend.

## 📱 Features

- **Real-time Monitoring**: Live eCO2, temperature, humidity, and radar occupancy data
- **Statistics & Analytics**: Historical data visualization with interactive charts
- **Carbon Footprint**: Track and analyze CO2 emissions over time
- **Radar Detection**: Human presence detection with configurable gate sensitivity
- **Push Notifications**: Customizable alerts for threshold breaches
- **Dark/Light Theme**: Adaptive UI with Material Design 3
- **Offline Support**: Local data caching with SharedPreferences

## 🏗️ Architecture

```
lib/
├── main.dart              # App entry point
├── app.dart               # Root widget & navigation
├── models/                # Data models
├── services/              # Business logic & Firebase integration
│   ├── settings_service.dart
│   └── notification_service.dart
├── pages/                 # Feature screens
│   ├── home/             # Dashboard overview
│   ├── statistics/       # Historical data charts
│   ├── carbon/           # Carbon footprint tracking
│   ├── radar/            # Radar sensor controls
│   └── settings/         # App configuration
├── widgets/              # Shared UI components
└── theme/                # App-wide styling
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0 <4.0.0`
- Firebase project with Realtime Database enabled
- ESP32 hardware setup (optional, for sensor integration)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter_dashboard
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   
   Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective platform directories, or run:
   ```bash
   flutterfire configure
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Firebase Database Structure

Expected Realtime Database structure:
```json
{
  "sensors": {
    "eco2": <number>,
    "temperature": <number>,
    "humidity": <number>,
    "timestamp": <timestamp>
  },
  "radar": {
    "occupied": <boolean>,
    "moving_sensitivity": <number>,
    "stationary_sensitivity": <number>
  }
}
```

### Notification Settings

Configure alert thresholds in **Settings** page:
- eCO2 threshold (ppm)
- Temperature range (°C)
- Humidity range (%)
- Notification toggle

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_database` | Realtime data sync |
| `cloud_firestore` | Historical data storage |
| `fl_chart` | Interactive charts |
| `google_fonts` | Typography |
| `shared_preferences` | Local settings cache |
| `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Local alerts |

## 🎨 Pages Overview

### Home Page
Real-time sensor readings with status indicators and quick actions.

### Statistics Page
Historical data visualization with date range filters and trend analysis.

### Carbon Page
Carbon footprint tracking with daily/weekly/monthly breakdowns.

### Radar Page
Occupancy detection controls with adjustable gate sensitivity for moving and stationary targets.

### Settings Page
App configuration including notification thresholds, theme selection, and device info.

## 🛠️ Development

### Build for Android
```bash
flutter build apk --release
```

### Build for iOS
```bash
flutter build ios --release
```

### Run tests
```bash
flutter test
```

### Code formatting
```bash
flutter format lib/
```

## 📄 License

This project is part of an academic IoT lab assignment.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For issues or questions, please open an issue on the repository.
