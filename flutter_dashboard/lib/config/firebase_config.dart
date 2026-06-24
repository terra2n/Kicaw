import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  static String get databaseUrl => dotenv.env['FIREBASE_DATABASE_URL'] ?? '';
  static String get apiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get authEmail => dotenv.env['FIREBASE_AUTH_EMAIL'] ?? '';
  static String get authPassword => dotenv.env['FIREBASE_AUTH_PASSWORD'] ?? '';
}
