import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/settings_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');

    // Anonymous sign-in for Firebase Auth (required by database rules)
    try {
      await FirebaseAuth.instance.signInAnonymously();
      debugPrint('Firebase Auth: anonymous sign-in OK');
    } catch (e) {
      debugPrint('Firebase Auth: anonymous sign-in failed: $e');
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Supabase
  try {
    final supabaseUrl = SupabaseConfig.supabaseUrl;
    final supabaseKey = SupabaseConfig.supabaseAnonKey;
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      debugPrint('Supabase initialization skipped: credentials missing in .env');
    } else {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      debugPrint('Supabase initialized successfully');
    }
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsService(prefs);

  runApp(App(settingsService: settings));
}
