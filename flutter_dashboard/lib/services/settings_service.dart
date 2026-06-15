import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyRoomName = 'room_name';
  static const _keyLightTimeout = 'light_timeout';
  static const _keyLampPower = 'lamp_power';
  static const _keyAutoShutoff = 'auto_shutoff';
  static const _keyMotionAlerts = 'motion_alerts';
  static const _keyCo2Report = 'co2_report';
  static const _keyWeeklySummary = 'weekly_summary';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  String get roomName => _prefs.getString(_keyRoomName) ?? 'Lab IoT K5';
  int get lightTimeout => _prefs.getInt(_keyLightTimeout) ?? 5;
  double get lampPower => _prefs.getDouble(_keyLampPower) ?? 10.0;
  bool get autoShutoff => _prefs.getBool(_keyAutoShutoff) ?? true;
  bool get motionAlerts => _prefs.getBool(_keyMotionAlerts) ?? true;
  bool get co2Report => _prefs.getBool(_keyCo2Report) ?? false;
  bool get weeklySummary => _prefs.getBool(_keyWeeklySummary) ?? false;

  Future<void> setRoomName(String v) => _prefs.setString(_keyRoomName, v);
  Future<void> setLightTimeout(int v) => _prefs.setInt(_keyLightTimeout, v);
  Future<void> setLampPower(double v) => _prefs.setDouble(_keyLampPower, v);
  Future<void> setAutoShutoff(bool v) => _prefs.setBool(_keyAutoShutoff, v);
  Future<void> setMotionAlerts(bool v) => _prefs.setBool(_keyMotionAlerts, v);
  Future<void> setCo2Report(bool v) => _prefs.setBool(_keyCo2Report, v);
  Future<void> setWeeklySummary(bool v) => _prefs.setBool(_keyWeeklySummary, v);
}
