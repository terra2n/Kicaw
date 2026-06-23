import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/room_status.dart';

class RealtimeService {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('ruangan_01');

  // [FLU-H1 fix] Controller dibuat sekali dan di-reuse, bukan buat baru tiap akses getter
  StreamController<RoomStatus>? _liveController;
  StreamSubscription<RoomStatus>? _liveSub;
  Timer? _liveTimer;

  /// Raw stream — fires only when Firebase data changes.
  Stream<RoomStatus> get statusStream {
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
  /// [FLU-H1 fix] Controller + timer dibuat sekali dan di-reuse agar tidak memory leak.
  Stream<RoomStatus> get liveStatusStream {
    if (_liveController == null || _liveController!.isClosed) {
      _liveController = StreamController<RoomStatus>.broadcast();
      RoomStatus? last;

      // Listen to Firebase for data changes
      _liveSub = statusStream.listen((status) {
        last = status;
        if (!_liveController!.isClosed) _liveController!.add(status);
      });

      // Periodic timer to re-evaluate heartbeat staleness
      _liveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (last != null && !_liveController!.isClosed) {
          // Re-create with same data so isOnline re-checks vs DateTime.now()
          _liveController!.add(last!);
        }
      });
    }
    return _liveController!.stream;
  }

  /// Stream data energi dari RTDB — diambil langsung dari node ruangan_01.
  /// Menghindari perhitungan yang salah dengan menggunakan nilai aktual dari ESP32.
  Stream<Map<String, dynamic>> get energyStream {
    return _ref.onValue.map((event) {
      if (event.snapshot.value == null) {
        return {'wh_saved': 0.0, 'co2_mg': 0.0, 'minutes_off': 0};
      }
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final whSaved = (data['energi_dihemat_wh'] as num?)?.toDouble() ?? 0.0;
      // 0.85 kg CO₂/kWh (faktor emisi grid Indonesia) → konversi ke mg
      final co2Mg = (whSaved / 1000.0) * 0.85 * 1000000;
      final minutesOff = (data['waktu_off_menit'] as num?)?.toInt() ?? 0;
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
