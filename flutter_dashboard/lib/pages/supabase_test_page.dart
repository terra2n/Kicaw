import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTestPage extends StatefulWidget {
  const SupabaseTestPage({super.key});

  @override
  State<SupabaseTestPage> createState() => _SupabaseTestPageState();
}

class _SupabaseTestPageState extends State<SupabaseTestPage> {
  String _status = 'Ready to test';
  List<String> _logs = [];
  bool _testing = false;

  void _addLog(String message, {bool isError = false}) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _logs = [];
      _status = 'Testing...';
    });

    try {
      _addLog('🧪 Starting Supabase connection test...');

      // Check environment variables
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (url.isEmpty || key.isEmpty) {
        _addLog('❌ Supabase credentials not found in .env', isError: true);
        _addLog('   SUPABASE_URL: ${url.isEmpty ? "MISSING" : "✓"}');
        _addLog('   SUPABASE_ANON_KEY: ${key.isEmpty ? "MISSING" : "✓"}');
        setState(() => _status = 'Failed - Missing credentials');
        return;
      }

      _addLog('✅ Environment variables loaded');
      _addLog('📋 URL: ${url.substring(0, 30)}...');

      // Test 1: Check Supabase client
      _addLog('');
      _addLog('🧪 Test 1: Supabase client initialization...');
      final client = Supabase.instance.client;
      _addLog('✅ Supabase client available');

      // Test 2: Database connectivity
      _addLog('');
      _addLog('🧪 Test 2: Database connectivity...');
      final response = await client
          .from('room_status')
          .select()
          .limit(1);
      _addLog('✅ Database connection successful');
      _addLog('   Retrieved ${response.length} record(s)');

      // Test 3: Read sensor_logs
      _addLog('');
      _addLog('🧪 Test 3: Read sensor_logs...');
      final logs = await client
          .from('sensor_logs')
          .select()
          .order('recorded_at', ascending: false)
          .limit(1);

      if (logs.isNotEmpty) {
        _addLog('✅ sensor_logs: ${logs.length} record(s)');
        final log = logs.first;
        _addLog('   Latest: ${log['temperature_c'] ?? "?"}°C, ${log['co2_ppm'] ?? "?"} ppm');
      } else {
        _addLog('⚠️  sensor_logs: empty (OK if no data yet)');
      }

      // Test 4: Read activity_logs
      _addLog('');
      _addLog('🧪 Test 4: Read activity_logs...');
      final activities = await client
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (activities.isNotEmpty) {
        _addLog('✅ activity_logs: ${activities.length} record(s)');
        final act = activities.first;
        _addLog('   Latest: ${act['event_type'] ?? "?"}');
      } else {
        _addLog('⚠️  activity_logs: empty (OK if no data yet)');
      }

      // Success
      _addLog('');
      _addLog('=' * 50);
      _addLog('🎉 All tests passed!');
      _addLog('✅ Supabase is properly configured');
      _addLog('=' * 50);

      setState(() => _status = '✅ Success - All tests passed');

    } on PostgrestException catch (e) {
      _addLog('❌ Database error: ${e.message}', isError: true);
      _addLog('   Code: ${e.code}');
      _addLog('');
      _addLog('💡 Tip: Run schema.sql in Supabase SQL Editor');
      setState(() => _status = '❌ Database error');
    } on AuthException catch (e) {
      _addLog('❌ Authentication error: ${e.message}', isError: true);
      _addLog('');
      _addLog('💡 Tip: Check SUPABASE_ANON_KEY in .env');
      setState(() => _status = '❌ Authentication error');
    } catch (e) {
      _addLog('❌ Error: $e', isError: true);
      _addLog('');
      _addLog('💡 Tip: Check internet connection and URL');
      setState(() => _status = '❌ Connection error');
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _status.startsWith('✅')
                ? Colors.green.shade100
                : _status.startsWith('❌')
                    ? Colors.red.shade100
                    : Colors.blue.shade100,
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _status.startsWith('✅')
                    ? Colors.green.shade900
                    : _status.startsWith('❌')
                        ? Colors.red.shade900
                        : Colors.blue.shade900,
              ),
            ),
          ),

          // Logs
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _logs.map((log) {
                    final isError = log.contains('❌') || log.contains('error');
                    final isSuccess = log.contains('✅') || log.contains('🎉');
                    return Text(
                      log,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: isError
                            ? Colors.red.shade300
                            : isSuccess
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Test button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _testing ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  _testing ? 'Testing...' : 'Test Connection',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
