import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String event;
  final String type;
  final double whSaved;
  final double co2Mg;
  final DateTime timestamp;

  const ActivityLog({
    required this.event,
    required this.type,
    required this.whSaved,
    required this.co2Mg,
    required this.timestamp,
  });

  factory ActivityLog.fromFirestore(Map<String, dynamic> data) {
    return ActivityLog(
      event: data['event'] ?? '',
      type: data['type'] ?? '',
      whSaved: (data['wh_saved'] ?? 0).toDouble(),
      co2Mg: (data['co2_mg'] ?? 0).toDouble(),
      // Firestore menyimpan timestamp sebagai objek Timestamp, bukan String
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

