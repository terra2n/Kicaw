class RoomStatus {
  final int? id;
  final String roomName;
  final double? temperatureC;
  final double? humidityPercent;
  final int? co2Ppm;
  final bool motionDetected;
  final bool lampStatus;
  final bool fanStatus;
  final DateTime updatedAt;

  RoomStatus({
    this.id,
    required this.roomName,
    this.temperatureC,
    this.humidityPercent,
    this.co2Ppm,
    required this.motionDetected,
    required this.lampStatus,
    required this.fanStatus,
    required this.updatedAt,
  });

  factory RoomStatus.fromJson(Map<String, dynamic> json) {
    return RoomStatus(
      id: json['id'] as int?,
      roomName: json['room_name'] as String,
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      humidityPercent: (json['humidity_percent'] as num?)?.toDouble(),
      co2Ppm: json['co2_ppm'] as int?,
      motionDetected: json['motion_detected'] as bool? ?? false,
      lampStatus: json['lamp_status'] as bool? ?? false,
      fanStatus: json['fan_status'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'room_name': roomName,
      'temperature_c': temperatureC,
      'humidity_percent': humidityPercent,
      'co2_ppm': co2Ppm,
      'motion_detected': motionDetected,
      'lamp_status': lampStatus,
      'fan_status': fanStatus,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RoomStatus copyWith({
    int? id,
    String? roomName,
    double? temperatureC,
    double? humidityPercent,
    int? co2Ppm,
    bool? motionDetected,
    bool? lampStatus,
    bool? fanStatus,
    DateTime? updatedAt,
  }) {
    return RoomStatus(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      temperatureC: temperatureC ?? this.temperatureC,
      humidityPercent: humidityPercent ?? this.humidityPercent,
      co2Ppm: co2Ppm ?? this.co2Ppm,
      motionDetected: motionDetected ?? this.motionDetected,
      lampStatus: lampStatus ?? this.lampStatus,
      fanStatus: fanStatus ?? this.fanStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
