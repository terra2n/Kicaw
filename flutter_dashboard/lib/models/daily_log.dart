class DailyLog {
  final String date;
  final double whSaved;
  final double co2Mg;
  final int sessions;
  final int minutesOff;

  const DailyLog({
    required this.date,
    required this.whSaved,
    required this.co2Mg,
    required this.sessions,
    required this.minutesOff,
  });

  factory DailyLog.fromFirestore(Map<String, dynamic> data) {
    return DailyLog(
      date: data['date'] ?? '',
      whSaved: (data['wh_saved'] ?? 0).toDouble(),
      co2Mg: (data['co2_mg'] ?? 0).toDouble(),
      sessions: (data['sessions'] ?? 0).toInt(),
      minutesOff: (data['minutes_off'] ?? 0).toInt(),
    );
  }
}
