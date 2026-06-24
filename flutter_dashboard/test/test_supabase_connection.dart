import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🧪 Testing Supabase Connection...\n');

  // Load environment variables
  await dotenv.load(fileName: ".env");
  print('✅ Loaded .env file');

  // Check credentials
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty) {
    print('❌ SUPABASE_URL not found in .env');
    return;
  }

  if (anonKey == null || anonKey.isEmpty) {
    print('❌ SUPABASE_ANON_KEY not found in .env');
    return;
  }

  print('✅ SUPABASE_URL: ${url.substring(0, 30)}...');
  print('✅ SUPABASE_ANON_KEY: ${anonKey.substring(0, 20)}...\n');

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    print('✅ Supabase initialized successfully\n');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
    return;
  }

  final client = Supabase.instance.client;

  // Test 1: Check connection
  print('📡 Test 1: Database Connection');
  try {
    final response = await client.from('room_status').select().limit(1);
    print('✅ Connected to Supabase database');
    print('   Response: $response\n');
  } catch (e) {
    print('❌ Connection failed: $e\n');
  }

  // Test 2: Query room_status
  print('📊 Test 2: Query room_status table');
  try {
    final data = await client.from('room_status').select();
    print('✅ Successfully queried room_status');
    print('   Records: ${data.length}');
    if (data.isNotEmpty) {
      print('   Sample: ${data.first}\n');
    } else {
      print('   (Empty table)\n');
    }
  } catch (e) {
    print('❌ Query failed: $e\n');
  }

  // Test 3: Query sensor_logs
  print('📊 Test 3: Query sensor_logs table');
  try {
    final data = await client
        .from('sensor_logs')
        .select()
        .order('recorded_at', ascending: false)
        .limit(3);
    print('✅ Successfully queried sensor_logs');
    print('   Records: ${data.length}');
    if (data.isNotEmpty) {
      print('   Latest: ${data.first}\n');
    } else {
      print('   (Empty table)\n');
    }
  } catch (e) {
    print('❌ Query failed: $e\n');
  }

  // Test 4: Query activity_logs
  print('📊 Test 4: Query activity_logs table');
  try {
    final data = await client
        .from('activity_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(3);
    print('✅ Successfully queried activity_logs');
    print('   Records: ${data.length}');
    if (data.isNotEmpty) {
      print('   Latest: ${data.first}\n');
    } else {
      print('   (Empty table)\n');
    }
  } catch (e) {
    print('❌ Query failed: $e\n');
  }

  print('🎉 All tests completed!');
}
