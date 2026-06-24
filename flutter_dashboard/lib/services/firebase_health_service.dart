import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseHealthService {
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
      final baseUrl = dotenv.env['FIREBASE_DATABASE_URL'] ?? '';
      if (baseUrl.isEmpty) {
        if (_controller != null && !_controller!.isClosed) {
          _controller!.add(false);
        }
        return;
      }
      await http
          .get(Uri.parse('$baseUrl/.json?shallow=true'))
          .timeout(const Duration(seconds: 5));
      if (_controller != null && !_controller!.isClosed) {
        _controller!.add(true);
      }
    } catch (e) {
      debugPrint('Firebase health ping failed: $e');
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
