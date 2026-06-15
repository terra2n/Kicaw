import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/room_status.dart';

class RealtimeService {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('ruangan_01');

  Stream<RoomStatus> get statusStream {
    return _ref.onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return RoomStatus.fromMap(data);
      }
      return RoomStatus.empty;
    });
  }

  Stream<bool> get occupancyStream {
    return _ref.child('status_radar').onValue.map((event) {
      return event.snapshot.value == true;
    });
  }

  Stream<bool> get lampStream {
    return _ref.child('status_lampu').onValue.map((event) {
      return event.snapshot.value == true;
    });
  }
}
