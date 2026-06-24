# Smart Room eCO2 Dashboard

Flutter dashboard application for real-time monitoring of Smart Room environmental data (eCO2, temperature, humidity, occupancy) using ESP32 sensors with dual-backend support (Firebase and Supabase).

## 📱 Features

- **Dual-Backend Support**: Live real-time dashboard updates via Firebase Realtime DB, and historical logs, daily summaries, and activity event feeds powered by Supabase PostgreSQL.
- **Real-time Monitoring**: Live eCO2, temperature, humidity, and radar occupancy data.
- **Statistics & Analytics**: Historical data visualization with interactive charts.
- **Carbon Footprint**: Track and analyze CO2 emissions saved/prevented over time based on actual lamp OFF duration.
- **Radar Detection**: Human presence detection via ESP32 digital OUT (GPIO14). Radar parameter configuration redirected to **HLKRadarTool** app from Play Store.
- **Push Notifications**: Customizable alerts for threshold breaches and token pendaftaran securely stored in Firestore.
- **Dark/Light Theme**: Adaptive UI with Material Design 3.
- **Offline Support**: Local data caching with SharedPreferences.

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
│   └── settings/         # App config + radar config page
├── widgets/              # Shared UI components
└── theme/                # App-wide styling
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0 <4.0.0`
- Firebase project with Realtime Database and Cloud Messaging enabled
- Supabase project with PostgreSQL tables initialized (`supabase/schema.sql`)
- ESP32 hardware setup (optional, for sensor integration)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter_dashboard
   ```

2. **Configure Environment Variables (.env)**
   Copy `.env.example` to `.env` and fill in your Supabase and Firebase credentials:
   ```bash
   cp .env.example .env
   # Open .env in your editor and input the values
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Firebase**
   Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective platform directories, or run:
   ```bash
   flutterfire configure
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Database Architecture

The application implements a dual-backend architecture:
1. **Firebase Realtime Database:** Used for high-frequency live sensor readings and occupancy status updates.
2. **Supabase PostgreSQL:** Used for storing historical logs, daily aggregated summaries, and activity event feeds.

### Firebase Realtime Database Structure
```json
{
  "sensors": {
    "eco2": 450,
    "temperature": 27.5,
    "humidity": 60,
    "timestamp": 1718625900
  },
  "radar": {
    "occupied": true,
    "moving_sensitivity": 50,
    "stationary_sensitivity": 50
  }
}
```

### Supabase Table Schemas
- **`room_status`**: Live status of the room (single row).
- **`sensor_logs`**: Historical sensor records pushed every 5 seconds.
- **`daily_summaries`**: Aggregated stats per room per day (averages, min/max values, total lamp-off duration).
- **`activity_logs`**: Room events (e.g. `motion_detected`, `motion_cleared`, `lamp_on`, `lamp_off`).

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
| `cloud_firestore` | Push notification token storage (`/fcm_tokens`) |
| `supabase_flutter` | Accessing historical records, daily aggregation, and activity logs |
| `flutter_dotenv` | Load environment variables from `.env` file |
| `fl_chart` | Interactive charts |
| `google_fonts` | Typography |
| `shared_preferences` | Local settings cache |
| `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Local alerts |
| `url_launcher` | Open external apps (Play Store)

## 🎨 Pages Overview

### Home Page
Real-time sensor readings with status indicators and quick actions.

### Statistics Page
Historical data visualization with date range filters and trend analysis.

### Carbon Page
Carbon footprint tracking with daily/weekly/monthly breakdowns.

### Settings Page
App configuration including notification thresholds, theme selection, device info, and radar config redirect to HLKRadarTool app.

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
