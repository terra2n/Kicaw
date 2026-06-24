import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'radar_config_service.dart';
import 'radar_ble_service.dart';
import '../models/radar_config.dart';

class RadarConnectionManager {
  static final RadarConnectionManager _instance = RadarConnectionManager._internal();
  factory RadarConnectionManager() => _instance;
  RadarConnectionManager._internal();

  final _firebaseService = RadarConfigService();
  final _bleService = RadarBleService();
  
  SharedPreferences? _prefs;
  String _connectionMode = 'cloud'; // 'cloud' (Firebase) or 'ble' (Direct Bluetooth)

  // Stream controllers to aggregate data based on active mode
  final _configController = StreamController<RadarConfig>.broadcast();
  final _engineeringController = StreamController<EngineeringData>.broadcast();
  final _commandStatusController = StreamController<String>.broadcast();

  StreamSubscription? _configSub;
  StreamSubscription? _engSub;
  StreamSubscription? _statusSub;

  String get connectionMode => _connectionMode;
  RadarBleService get bleService => _bleService;
  RadarConfigService get firebaseService => _firebaseService;

  Stream<RadarConfig> get configStream => _configController.stream;
  Stream<EngineeringData> get engineeringStream => _engineeringController.stream;
  Stream<String> get commandStatusStream => _commandStatusController.stream;

  /// Initialize and load saved mode
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _connectionMode = _prefs?.getString('radar_connection_mode') ?? 'cloud';
    _updateSubscriptions();
  }

  /// Change connection mode and persist preference
  Future<void> setConnectionMode(String mode) async {
    if (mode != 'cloud' && mode != 'ble') return;
    _connectionMode = mode;
    await _prefs?.setString('radar_connection_mode', mode);
    _updateSubscriptions();
  }

  void _updateSubscriptions() {
    _configSub?.cancel();
    _engSub?.cancel();
    _statusSub?.cancel();

    if (_connectionMode == 'cloud') {
      _configSub = _firebaseService.configStream.listen((cfg) => _configController.add(cfg));
      _engSub = _firebaseService.engineeringStream.listen((data) => _engineeringController.add(data));
      _statusSub = _firebaseService.commandStatusStream.listen((status) => _commandStatusController.add(status));
    } else {
      _configSub = _bleService.configStream.listen((cfg) => _configController.add(cfg));
      _engSub = _bleService.engineeringStream.listen((data) => _engineeringController.add(data));
      _statusSub = _bleService.commandStatusStream.listen((status) => _commandStatusController.add(status));
    }
  }

  /// Send command based on connection mode
  Future<void> sendCommand(String command, {Map<String, dynamic>? params}) async {
    if (_connectionMode == 'cloud') {
      await _firebaseService.sendCommand(command, params: params);
    } else {
      await _bleService.sendCommand(command, params: params);
    }
  }

  // Helper delegates
  Future<void> readConfig() => sendCommand('read_config');
  Future<void> readFirmware() => sendCommand('read_firmware');
  Future<void> startEngineeringMode() => sendCommand('engineering_on');
  Future<void> stopEngineeringMode() => sendCommand('engineering_off');
  Future<void> factoryReset() => sendCommand('factory_reset');
  Future<void> restart() => sendCommand('restart_radar');

  Future<void> setMaxGate({
    required int movingGate,
    required int stationaryGate,
    required int timeoutSeconds,
  }) => sendCommand('set_max_gate', params: {
    'moving_gate': movingGate,
    'stationary_gate': stationaryGate,
    'timeout': timeoutSeconds,
  });

  Future<void> setSingleGateSensitivity({
    required int gate,
    required int moving,
    required int stationary,
  }) => sendCommand('set_gate_sens', params: {
    'gate': gate,
    'moving': moving,
    'stationary': stationary,
  });

  Future<void> setAllGateSensitivities(List<GateSensitivity> gates) async {
    final params = <String, dynamic>{};
    for (final g in gates) {
      params['m${g.gate}'] = g.moving;
      params['s${g.gate}'] = g.stationary;
    }
    await sendCommand('set_all_gates_sens', params: params);
  }

  /// Change BLE password. Returns true if successful.
  Future<bool> changeBlePassword(String newPassword) async {
    if (_connectionMode == 'ble') {
      return await _bleService.changeBlePassword(newPassword);
    }
    return false;
  }
}
