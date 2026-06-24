import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/radar_config.dart';

class RadarConfigService {
  final DatabaseReference _ref =
      FirebaseDatabase.instance.ref('ruangan_01/radar_config');

  /// Stream konfigurasi radar terbaru
  Stream<RadarConfig> get configStream {
    return _ref.child('config_data').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return RadarConfig.fromMap(data);
      }
      return RadarConfig.empty;
    });
  }

  /// Stream data engineering mode real-time
  Stream<EngineeringData> get engineeringStream {
    return _ref.child('engineering_data').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return EngineeringData.fromMap(data);
      }
      return EngineeringData.empty;
    });
  }

  /// Stream status command
  Stream<String> get commandStatusStream {
    return _ref.child('command_status').onValue.map((event) {
      return event.snapshot.value?.toString() ?? 'idle';
    });
  }

  /// Kirim command ke Firebase
  Future<void> sendCommand(String command,
      {Map<String, dynamic>? params}) async {
    await _ref.child('command').set(command);
    await _ref.child('command_params').set(params ?? {});
    await _ref.child('command_ts').set(DateTime.now().millisecondsSinceEpoch);
    // Note: ESP32 is the sole writer of command_status to avoid race conditions
  }

  /// Baca konfigurasi radar
  Future<void> readConfig() => sendCommand('read_config');

  /// Baca firmware version
  Future<void> readFirmware() => sendCommand('read_firmware');

  /// Set max detection gates
  Future<void> setMaxGate({
    required int movingGate,
    required int stationaryGate,
    required int timeoutSeconds,
  }) =>
      sendCommand('set_max_gate', params: {
        'moving_gate': movingGate,
        'stationary_gate': stationaryGate,
        'timeout': timeoutSeconds,
      });

  /// Set sensitivitas satu gate
  Future<void> setSingleGateSensitivity({
    required int gate,
    required int moving,
    required int stationary,
  }) =>
      sendCommand('set_gate_sens', params: {
        'gate': gate,
        'moving': moving,
        'stationary': stationary,
      });

  /// Set sensitivitas semua gate sekaligus
  Future<void> setAllGateSensitivities(List<GateSensitivity> gates) async {
    final params = <String, dynamic>{};
    for (final g in gates) {
      params['m${g.gate}'] = g.moving;
      params['s${g.gate}'] = g.stationary;
    }
    await sendCommand('set_all_gates_sens', params: params);
  }

  /// Aktifkan engineering mode
  Future<void> startEngineeringMode() =>
      sendCommand('engineering_on');

  /// Nonaktifkan engineering mode
  Future<void> stopEngineeringMode() =>
      sendCommand('engineering_off');

  /// Factory reset radar
  Future<void> factoryReset() =>
      sendCommand('factory_reset');

  /// Restart radar
  Future<void> restart() => sendCommand('restart_radar');
}
