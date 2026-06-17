import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/room_status.dart';

class RealtimeService {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('ruangan_01');

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
  Stream<RoomStatus> get liveStatusStream {
    RoomStatus? last;
    final controller = StreamController<RoomStatus>.broadcast();

    // Listen to Firebase for data changes
    final sub = statusStream.listen((status) {
      last = status;
      if (!controller.isClosed) controller.add(status);
    });

    // Periodic timer to re-evaluate heartbeat staleness
    final timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (last != null && !controller.isClosed) {
        // Re-create with same data so isOnline re-checks vs DateTime.now()
        controller.add(last!);
      }
    });

    controller.onCancel = () {
      sub.cancel();
      timer.cancel();
      controller.close();
    };

    return controller.stream;
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
}
