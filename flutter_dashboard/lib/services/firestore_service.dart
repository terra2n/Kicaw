import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_log.dart';
import '../models/activity_log.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<DailyLog>> getDailyLogs(int limit) {
    return _firestore
        .collection('daily_logs')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DailyLog.fromFirestore(doc.data()))
            .toList());
  }

  Stream<List<DailyLog>> getMonthlyLogs(String month) {
    return _firestore
        .collection('monthly_logs')
        .doc(month)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return [DailyLog.fromFirestore(doc.data()!)];
      }
      return [];
    });
  }

  Stream<List<ActivityLog>> getRecentActivity(int limit) {
    return _firestore
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ActivityLog.fromFirestore(doc.data()))
            .toList());
  }

  Future<Map<String, dynamic>> getMonthlyAggregate(String month) async {
    final doc = await _firestore
        .collection('monthly_logs')
        .doc(month)
        .get();
    if (doc.exists) {
      return doc.data()!;
    }
    return {};
  }
}
