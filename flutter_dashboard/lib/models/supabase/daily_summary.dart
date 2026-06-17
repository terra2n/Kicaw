class DailySummary {
  final int? id;
  final String roomName;
  final DateTime date;
  final double? avgTemperatureC;
  final double? avgHumidityPercent;
  final double? avgCo2Ppm;
  final int? maxCo2Ppm;
  final int? minCo2Ppm;
  final int motionCount;
  final int lampOnMinutes;

  DailySummary({
    this.id,
    required this.roomName,
    required this.date,
    this.avgTemperatureC,
    this.avgHumidityPercent,
    this.avgCo2Ppm,
    this.maxCo2Ppm,
    this.minCo2Ppm,
    required this.motionCount,
    required this.lampOnMinutes,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      id: json['id'] as int?,
      roomName: json['room_name'] as String,
      date: DateTime.parse(json['date'] as String),
      avgTemperatureC: (json['avg_temperature_c'] as num?)?.toDouble(),
      avgHumidityPercent: (json['avg_humidity_percent'] as num?)?.toDouble(),
      avgCo2Ppm: (json['avg_co2_ppm'] as num?)?.toDouble(),
      maxCo2Ppm: json['max_co2_ppm'] as int?,
      minCo2Ppm: json['min_co2_ppm'] as int?,
      motionCount: json['motion_count'] as int? ?? 0,
      lampOnMinutes: json['lamp_on_minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'room_name': roomName,
      'date': date.toIso8601String().split('T')[0],
      'avg_temperature_c': avgTemperatureC,
      'avg_humidity_percent': avgHumidityPercent,
      'avg_co2_ppm': avgCo2Ppm,
      'max_co2_ppm': maxCo2Ppm,
      'min_co2_ppm': minCo2Ppm,
      'motion_count': motionCount,
      'lamp_on_minutes': lampOnMinutes,
    };
  }
}
