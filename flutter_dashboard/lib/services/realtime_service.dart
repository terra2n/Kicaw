import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/room_status.dart';

class RealtimeService {
  bool get _isFirebaseReady {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  DatabaseReference get _ref => FirebaseDatabase.instance.ref('ruangan_01');

  // [FLU-H1 fix] Controller dibuat sekali dan di-reuse, bukan buat baru tiap akses getter
  StreamController<RoomStatus>? _liveController;
  StreamSubscription<RoomStatus>? _liveSub;
  Timer? _liveTimer;

  /// Raw stream — fires only when Firebase data changes.
  Stream<RoomStatus> get statusStream {
    if (!_isFirebaseReady) return Stream.value(RoomStatus.empty);
    return _ref.onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return RoomStatus.fromMap(data);
      }
      return RoomStatus.empty;
    });
  }

  /// Heartbeat-aware stream — re-evaluates `isOnline` every 5 seconds
  /// even when Firebase data doesn't change (so offline is detected).
  /// [FLU-H1 fix] Controller + timer dibuat sekali dan di-reuse dengan cleanup listener.
  Stream<RoomStatus> get liveStatusStream {
    if (!_isFirebaseReady) {
      return Stream<RoomStatus>.value(RoomStatus.empty).asBroadcastStream();
    }
    if (_liveController == null || _liveController!.isClosed) {
      RoomStatus? last;
      _liveController = StreamController<RoomStatus>.broadcast(
        onListen: () {
          // Listen to Firebase for data changes
          _liveSub = statusStream.listen((status) {
            last = status;
            if (_liveController != null && !_liveController!.isClosed) {
              _liveController!.add(status);
            }
          });

          // Periodic timer to re-evaluate heartbeat staleness
          _liveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
            if (last != null && _liveController != null && !_liveController!.isClosed) {
              // Re-create with same data so isOnline re-checks vs DateTime.now()
              _liveController!.add(last!);
            }
          });
        },
        onCancel: () {
          _liveSub?.cancel();
          _liveSub = null;
          _liveTimer?.cancel();
          _liveTimer = null;
        },
      );
    }
    return _liveController!.stream;
  }

  Stream<Map<String, dynamic>> get energyStream {
    if (!_isFirebaseReady) {
      return Stream.value({'wh_saved': 0.0, 'co2_mg': 0.0, 'minutes_off': 0});
    }
    return _ref.onValue.map((event) {
      if (event.snapshot.value == null) {
        return {'wh_saved': 0.0, 'co2_mg': 0.0, 'minutes_off': 0};
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final whSaved = (data['energi_dihemat_wh'] as num?)?.toDouble() ?? 0.0;
      // 0.85 kg CO₂/kWh (faktor emisi grid Indonesia) → konversi ke mg
      final co2Mg = (whSaved / 1000.0) * 0.85 * 1000000;
      final minutesOff = whSaved > 0 ? (whSaved / 3.0 * 60).round() : 0;
      return {'wh_saved': whSaved, 'co2_mg': co2Mg, 'minutes_off': minutesOff};
    });
  }

  Stream<bool> get occupancyStream {
    return liveStatusStream.map((s) => s.realOccupied);
  }

  Stream<bool> get lampStream {
    return liveStatusStream.map((s) => s.realLampOn);
  }

  Stream<bool> get onlineStream {
    return liveStatusStream.map((s) => s.isOnline);
  }

  /// Bersihkan semua resource: timer, subscription, controller.
  /// Panggil dari dispose() widget yang menggunakan RealtimeService.
  void dispose() {
    _liveTimer?.cancel();
    _liveSub?.cancel();
    _liveController?.close();
    _liveController = null;
    _liveTimer = null;
    _liveSub = null;
  }
}
