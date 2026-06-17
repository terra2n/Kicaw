class RoomStatus {
  final bool isOccupied;
  final bool lampOn;
  final double savedEnergyWh;
  final double preventedCo2Mg;
  final int radarDistanceCm;
  final DateTime? lastHeartbeat;
  final DateTime? lastChange;

  /// Timeout: kalau heartbeat > 15 detik lalu → ESP dianggap offline
  static const offlineThresholdSeconds = 15;

  RoomStatus({
    required this.isOccupied,
    required this.lampOn,
    required this.savedEnergyWh,
    required this.preventedCo2Mg,
    this.radarDistanceCm = 0,
    this.lastHeartbeat,
    this.lastChange,
  });

  /// ESP32 online? Berdasarkan heartbeat timestamp.
  bool get isOnline {
    if (lastHeartbeat == null) return false;
    final diff = DateTime.now().difference(lastHeartbeat!);
    return diff.inSeconds < offlineThresholdSeconds;
  }

  /// Status radar yang "real" — kalau ESP offline, always false.
  bool get realOccupied => isOnline && isOccupied;

  /// Status lampu yang "real" — kalau ESP offline, always false.
  bool get realLampOn => isOnline && lampOn;

  factory RoomStatus.fromMap(Map<String, dynamic> data) {
    return RoomStatus(
      isOccupied: data['status_radar'] == true,
      lampOn: data['status_lampu'] == true,
      savedEnergyWh: (data['energi_dihemat_wh'] ?? 0).toDouble(),
      preventedCo2Mg: (data['co2_dicegah_mg'] ?? 0).toDouble(),
      radarDistanceCm: (data['radar_distance_cm'] ?? 0).toInt(),
      lastHeartbeat: _parseHeartbeat(data['last_heartbeat']),
    );
  }

  static DateTime? _parseHeartbeat(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      // Epoch seconds dari ESP32
      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed;
    }
    return null;
  }

  static final empty = RoomStatus(
    isOccupied: false,
    lampOn: false,
    savedEnergyWh: 0,
    preventedCo2Mg: 0,
  );
}
