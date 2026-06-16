class CarbonService {
  static const double gridFactorKgPerKwh = 0.85;
  static const double lampPowerW = 3.0;

  double whToCo2Mg(double wh) {
    final kwh = wh / 1000.0;
    final kgCo2 = kwh * gridFactorKgPerKwh;
    return kgCo2 * 1000000.0;
  }

  double treesEquivalent(double co2Mg) {
    final co2Kg = co2Mg / 1000000.0;
    return co2Kg / 21.0;
  }

  double carKmEquivalent(double co2Mg) {
    final co2Kg = co2Mg / 1000000.0;
    return co2Kg / 0.12;
  }

  double phoneChargesEquivalent(double wh) {
    return wh / 15.0;
  }
}
