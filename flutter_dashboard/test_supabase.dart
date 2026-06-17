import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('🧪 Testing Supabase Connection...\n');

  // Load environment variables
  await dotenv.load(fileName: ".env");
  print('✅ Environment variables loaded\n');

  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || key.isEmpty) {
    print('❌ Error: Supabase credentials not found in .env file');
    print('   SUPABASE_URL: ${url.isEmpty ? "MISSING" : "FOUND"}');
    print('   SUPABASE_ANON_KEY: ${key.isEmpty ? "MISSING" : "FOUND"}');
    return;
  }

  print('📋 Configuration:');
  print('   URL: $url');
  print('   Key: ${key.substring(0, 20)}...\n');

  try {
    // Initialize Supabase
    print('🔄 Initializing Supabase client...');
    await Supabase.initialize(
      url: url,
      anonKey: key,
    );
    print('✅ Supabase client initialized\n');

    final client = Supabase.instance.client;

    // Test 1: Check if we can access the database
    print('🧪 Test 1: Database connectivity...');
    final response = await client
        .from('room_status')
        .select()
        .limit(1);

    print('✅ Database connection successful');
    print('   Retrieved ${response.length} record(s)\n');

    // Test 2: Check if we can read data
    print('🧪 Test 2: Read room_status data...');
    if (response.isNotEmpty) {
      print('✅ Successfully read room_status:');
      print('   ${response.first}');
    } else {
      print('⚠️  No data in room_status table (this is OK if table is empty)');
    }
    print('');

    // Test 3: Check if we can read sensor_logs
    print('🧪 Test 3: Read sensor_logs...');
    final logs = await client
        .from('sensor_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(1);

    if (logs.isNotEmpty) {
      print('✅ Successfully read sensor_logs:');
      print('   ${logs.first}');
    } else {
      print('⚠️  No data in sensor_logs table (this is OK if table is empty)');
    }
    print('');

    // Test 4: Check if we can read activity_logs
    print('🧪 Test 4: Read activity_logs...');
    final activities = await client
        .from('activity_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(1);

    if (activities.isNotEmpty) {
      print('✅ Successfully read activity_logs:');
      print('   ${activities.first}');
    } else {
      print('⚠️  No data in activity_logs table (this is OK if table is empty)');
    }
    print('');

    print('=' * 50);
    print('🎉 All connection tests passed!');
    print('✅ Supabase is properly configured and accessible');
    print('=' * 50);

  } on PostgrestException catch (e) {
    print('❌ Database error: ${e.message}');
    print('   Code: ${e.code}');
    print('   Details: ${e.details}');
    print('\n💡 Tip: Make sure you ran the schema.sql in Supabase SQL Editor');
  } on AuthException catch (e) {
    print('❌ Authentication error: ${e.message}');
    print('\n💡 Tip: Check your SUPABASE_ANON_KEY in .env file');
  } catch (e) {
    print('❌ Unexpected error: $e');
    print('\n💡 Tip: Check your internet connection and Supabase URL');
  }
}
