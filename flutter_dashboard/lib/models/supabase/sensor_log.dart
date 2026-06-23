class SensorLog {
  final int? id;
  final String roomName;
  final double? temperatureC;
  final double? humidityPercent;
  final int? co2Ppm;
  final bool? motionDetected;
  final bool? lampStatus;
  final bool? fanStatus;
  final DateTime recordedAt;

  SensorLog({
    this.id,
    required this.roomName,
    this.temperatureC,
    this.humidityPercent,
    this.co2Ppm,
    this.motionDetected,
    this.lampStatus,
    this.fanStatus,
    required this.recordedAt,
  });

  factory SensorLog.fromJson(Map<String, dynamic> json) {
    return SensorLog(
      id: json['id'] as int?,
      roomName: json['room_name'] as String,
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      humidityPercent: (json['humidity_percent'] as num?)?.toDouble(),
      co2Ppm: json['co2_ppm'] as int?,
      motionDetected: json['motion_detected'] as bool?,
      lampStatus: json['lamp_status'] as bool?,
      fanStatus: json['fan_status'] as bool?,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'].toString()) ?? DateTime.now()
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
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}
