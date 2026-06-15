import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);
  final notif = NotificationService();

  try {
    await notif.init(settings);
    debugPrint('Notification service initialized');
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }

  runApp(App(settingsService: settings, notificationService: notif));
}
