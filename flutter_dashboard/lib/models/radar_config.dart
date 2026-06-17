class GateSensitivity {
  final int gate;
  final int moving;
  final int stationary;

  const GateSensitivity({
    required this.gate,
    required this.moving,
    required this.stationary,
  });

  factory GateSensitivity.fromMap(Map<String, dynamic> map, int gateIndex) {
    return GateSensitivity(
      gate: gateIndex,
      moving: (map['moving'] ?? 50).toInt(),
      stationary: (map['stationary'] ?? 50).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'moving': moving,
    'stationary': stationary,
  };
}

class RadarConfig {
  final int maxMovingGate;
  final int maxStationaryGate;
  final int inactivityTimeout;
  final String firmwareVersion;
  final List<GateSensitivity> gates;
  final DateTime? lastUpdate;

  const RadarConfig({
    required this.maxMovingGate,
    required this.maxStationaryGate,
    required this.inactivityTimeout,
    required this.firmwareVersion,
    required this.gates,
    this.lastUpdate,
  });

  factory RadarConfig.fromMap(Map<String, dynamic> map) {
    final gates = <GateSensitivity>[];
    if (map['gates'] != null) {
      final gatesMap = Map<String, dynamic>.from(map['gates'] as Map);
      gatesMap.forEach((key, value) {
        final gateIdx = int.tryParse(key.replaceAll('g', '')) ?? 0;
        gates.add(GateSensitivity.fromMap(
          Map<String, dynamic>.from(value as Map), gateIdx));
      });
    }
    // Sort by gate index
    gates.sort((a, b) => a.gate.compareTo(b.gate));

    return RadarConfig(
      maxMovingGate: (map['max_moving_gate'] ?? 2).toInt(),
      maxStationaryGate: (map['max_stationary_gate'] ?? 1).toInt(),
      inactivityTimeout: (map['inactivity_timeout'] ?? 5).toInt(),
      firmwareVersion: _buildFwVersion(map),
      gates: gates,
      lastUpdate: map['last_updated'] != null
          ? DateTime.tryParse(map['last_updated'].toString())
          : null,
    );
  }

  static String _buildFwVersion(Map<String, dynamic> map) {
    final maj = map['firmware_major'];
    final min = map['firmware_minor'];
    final bug = map['firmware_bugfix'];
    if (maj != null && min != null) {
      return 'v$maj.$min.${(bug ?? 0).toString().padLeft(4, '0')}';
    }
    return 'Unknown';
  }

  static final empty = RadarConfig(
    maxMovingGate: 2,
    maxStationaryGate: 1,
    inactivityTimeout: 5,
    firmwareVersion: 'Unknown',
    gates: List.generate(3, (i) => GateSensitivity(gate: i, moving: 50, stationary: 50)),
  );
}

class EngineeringData {
  final int presenceDistanceCm;
  final int movingDistanceCm;
  final int stationaryDistanceCm;
  final List<int> movingEnergy;
  final List<int> stationaryEnergy;
  final DateTime timestamp;

  const EngineeringData({
    required this.presenceDistanceCm,
    required this.movingDistanceCm,
    required this.stationaryDistanceCm,
    required this.movingEnergy,
    required this.stationaryEnergy,
    required this.timestamp,
  });

  factory EngineeringData.fromMap(Map<String, dynamic> map) {
    List<int> movingEng = List.filled(9, 0);
    List<int> stationaryEng = List.filled(9, 0);

    if (map['energy'] != null) {
      final engMap = Map<String, dynamic>.from(map['energy'] as Map);
      engMap.forEach((key, value) {
        final gateIdx = int.tryParse(key.replaceAll('g', '')) ?? 0;
        if (gateIdx < 9) {
          final v = Map<String, dynamic>.from(value as Map);
          movingEng[gateIdx] = (v['moving'] ?? 0).toInt();
          stationaryEng[gateIdx] = (v['stationary'] ?? 0).toInt();
        }
      });
    }

    return EngineeringData(
      presenceDistanceCm: (map['presence_distance_cm'] ?? 0).toInt(),
      movingDistanceCm: (map['moving_distance_cm'] ?? 0).toInt(),
      stationaryDistanceCm: (map['stationary_distance_cm'] ?? 0).toInt(),
      movingEnergy: movingEng,
      stationaryEnergy: stationaryEng,
      timestamp: _parseTimestamp(map['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.now();
  }

  static final empty = EngineeringData(
    presenceDistanceCm: 0,
    movingDistanceCm: 0,
    stationaryDistanceCm: 0,
    movingEnergy: List.filled(9, 0),
    stationaryEnergy: List.filled(9, 0),
    timestamp: DateTime.now(),
  );
}
