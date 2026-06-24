import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase/room_status.dart';
import '../models/supabase/sensor_log.dart';
import '../models/supabase/daily_summary.dart';
import '../models/supabase/activity_log.dart';

class SupabaseService {
  // Bug A fix: Gunakan getter (bukan field) agar tidak crash jika Supabase
  // belum diinisialisasi (misalnya .env belum diisi).
  // Akses _client ditunda sampai saat query pertama dipanggil.
  SupabaseClient get _client => Supabase.instance.client;

  // Helper: cek apakah Supabase sudah siap sebelum query
  bool get _isReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===== REALTIME: Room Status =====

  Future<RoomStatus?> getRoomStatus() async {
    if (!_isReady) return null;
    try {
      final response = await _client
          .from('room_status')
          .select()
          .eq('room_name', 'ruangan_01')
          .maybeSingle();
      if (response == null) return null;
      return RoomStatus.fromJson(response);
    } catch (e) {
      debugPrint('Error getting room status: $e');
      return null;
    }
  }

  Stream<RoomStatus?> streamRoomStatus() {
    if (!_isReady) return Stream<RoomStatus?>.value(null).asBroadcastStream();
    return _client
        .from('room_status')
        .stream(primaryKey: ['id'])
        .eq('room_name', 'ruangan_01')
        .map((data) => data.isEmpty ? null : RoomStatus.fromJson(data.first));
  }

  // ===== HISTORICAL: Sensor Logs =====

  Future<List<SensorLog>> getSensorLogs({
    int limit = 100,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (!_isReady) return [];
    try {
      var query = _client
          .from('sensor_logs')
          .select()
          .eq('room_name', 'ruangan_01');

      if (startTime != null) {
        query = query.gte('recorded_at', startTime.toIso8601String());
      }
      if (endTime != null) {
        query = query.lte('recorded_at', endTime.toIso8601String());
      }

      final response = await query
          .order('recorded_at', ascending: false)
          .limit(limit);

      return response.map((json) => SensorLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting sensor logs: $e');
      return [];
    }
  }

  // Menggunakan polling non-blocking berkala karena Supabase Realtime Stream 
  // tidak mendukung pengurutan kolom non-PK, sehingga membatasi pembacaan data terlama.
  Stream<List<SensorLog>> streamSensorLogs({int limit = 100}) {
    if (!_isReady) return Stream<List<SensorLog>>.value([]).asBroadcastStream();
    
    late StreamController<List<SensorLog>> controller;
    Timer? timer;
    
    controller = StreamController<List<SensorLog>>.broadcast(
      onListen: () {
        getSensorLogs(limit: limit).then((logs) {
          if (!controller.isClosed) controller.add(logs);
        });
        
        timer = Timer.periodic(const Duration(seconds: 5), (_) async {
          final logs = await getSensorLogs(limit: limit);
          if (!controller.isClosed) controller.add(logs);
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );
    
    return controller.stream;
  }

  // ===== AGGREGATED: Daily Summaries =====

  Future<List<DailySummary>> getDailySummaries({
    int days = 30,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_isReady) return [];
    try {
      final from = startDate ?? DateTime.now().subtract(Duration(days: days));

      var query = _client
          .from('daily_summaries')
          .select()
          .eq('room_name', 'ruangan_01')
          .gte('date', from.toIso8601String().split('T')[0]);

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('date', ascending: false)
          .limit(days);

      return response.map((json) => DailySummary.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting daily summaries: $e');
      return [];
    }
  }

  // ===== EVENTS: Activity Logs =====

  Future<List<ActivityLog>> getActivityLogs({
    int limit = 50,
    String? eventType,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    if (!_isReady) return [];
    try {
      var query = _client
          .from('activity_logs')
          .select()
          .eq('room_name', 'ruangan_01');

      if (eventType != null) {
        query = query.eq('event_type', eventType);
      }
      if (startTime != null) {
        query = query.gte('created_at', startTime.toIso8601String());
      }
      if (endTime != null) {
        query = query.lte('created_at', endTime.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => ActivityLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting activity logs: $e');
      return [];
    }
  }

  // Menggunakan polling berkala karena alasan yang sama dengan streamSensorLogs
  Stream<List<ActivityLog>> streamActivityLogs({int limit = 50}) {
    if (!_isReady) return Stream<List<ActivityLog>>.value([]).asBroadcastStream();
    
    late StreamController<List<ActivityLog>> controller;
    Timer? timer;
    
    controller = StreamController<List<ActivityLog>>.broadcast(
      onListen: () {
        getActivityLogs(limit: limit).then((logs) {
          if (!controller.isClosed) controller.add(logs);
        });
        
        timer = Timer.periodic(const Duration(seconds: 5), (_) async {
          final logs = await getActivityLogs(limit: limit);
          if (!controller.isClosed) controller.add(logs);
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );
    
    return controller.stream;
  }

  // ===== WRITE =====

  Future<bool> insertSensorLog(SensorLog log) async {
    if (!_isReady) return false;
    try {
      await _client.from('sensor_logs').insert(log.toJson());
      return true;
    } catch (e) {
      debugPrint('Error inserting sensor log: $e');
      return false;
    }
  }

  Future<bool> insertActivityLog(ActivityLog log) async {
    if (!_isReady) return false;
    try {
      await _client.from('activity_logs').insert(log.toJson());
      return true;
    } catch (e) {
      debugPrint('Error inserting activity log: $e');
      return false;
    }
  }

  Future<bool> updateRoomStatus(RoomStatus status) async {
    if (!_isReady) return false;
    try {
      await _client
          .from('room_status')
          .update(status.toJson())
          .eq('room_name', 'ruangan_01');
      return true;
    } catch (e) {
      debugPrint('Error updating room status: $e');
      return false;
    }
  }
}
