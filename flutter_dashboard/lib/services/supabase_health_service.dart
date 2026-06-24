import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class SupabaseHealthService {
  StreamController<bool>? _controller;
  Timer? _timer;

  Stream<bool> get onlineStream {
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<bool>.broadcast(
        onListen: _start,
        onCancel: _stop,
      );
    }
    return _controller!.stream;
  }

  void _start() {
    _ping();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _ping(),
    );
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _ping() async {
    try {
      final baseUrl = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;
      final url = '$baseUrl/rest/v1/room_status?select=id&limit=1';
      final response = await http
          .head(Uri.parse(url), headers: {
            'apikey': anonKey,
            'Authorization': 'Bearer $anonKey',
          })
          .timeout(const Duration(seconds: 5));
      final isOnline = response.statusCode == 200 ||
                        response.statusCode == 401;
      if (_controller != null && !_controller!.isClosed) {
        _controller!.add(isOnline);
      }
    } catch (e) {
      debugPrint('Supabase health ping failed: $e');
      if (_controller != null && !_controller!.isClosed) {
        _controller!.add(false);
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller?.close();
    _controller = null;
    _timer = null;
  }
}
