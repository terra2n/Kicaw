class RoomStatus {
  final bool isOccupied;
  final bool lampOn;
  final double savedEnergyWh;
  final double preventedCo2Mg;
  final DateTime? lastChange;

  RoomStatus({
    required this.isOccupied,
    required this.lampOn,
    required this.savedEnergyWh,
    required this.preventedCo2Mg,
    this.lastChange,
  });

  factory RoomStatus.fromMap(Map<String, dynamic> data) {
    return RoomStatus(
      isOccupied: data['status_radar'] == true,
      lampOn: data['status_lampu'] == true,
      savedEnergyWh: (data['energi_dihemat_wh'] ?? 0).toDouble(),
      preventedCo2Mg: (data['co2_dicegah_mg'] ?? 0).toDouble(),
    );
  }

  static final empty = RoomStatus(
    isOccupied: false,
    lampOn: false,
    savedEnergyWh: 0,
    preventedCo2Mg: 0,
  );
}
