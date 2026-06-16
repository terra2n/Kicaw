class EnergyMetric {
  final double whSaved;
  final double co2Mg;
  final int minutesOff;
  final double lampPowerW;

  const EnergyMetric({
    required this.whSaved,
    required this.co2Mg,
    required this.minutesOff,
    required this.lampPowerW,
  });

  static const empty = EnergyMetric(
    whSaved: 0,
    co2Mg: 0,
    minutesOff: 0,
    lampPowerW: 3,
  );
}
