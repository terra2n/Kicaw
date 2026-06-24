import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radar_config.dart';

class RadarBleService {
  static final RadarBleService _instance = RadarBleService._internal();
  factory RadarBleService() => _instance;
  RadarBleService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _notifySub;

  final _rxBuffer = <int>[];
  bool _isAuthenticated = false;
  String _activePassword = 'HiLink';

  // Stream controllers
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  final _configController = StreamController<RadarConfig>.broadcast();
  final _engineeringController = StreamController<EngineeringData>.broadcast();
  final _commandStatusController = StreamController<String>.broadcast();

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isAuthenticated => _isAuthenticated;
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<RadarConfig> get configStream => _configController.stream;
  Stream<EngineeringData> get engineeringStream => _engineeringController.stream;
  Stream<String> get commandStatusStream => _commandStatusController.stream;

  // BLE UUIDs
  static const String serviceUuid = "fff0";
  static const String notifyCharUuid = "fff1";
  static const String writeCharUuid = "writeCharUuid"; // fff2 character

  // Password from dotenv (fallback)
  String get _fallbackPassword => dotenv.env['RADAR_BLE_PASSWORD'] ?? 'HiLink';

  /// Scan for HLK-LD2410 devices
  Stream<List<ScanResult>> scanForRadar() {
    // Start scan
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      androidUsesFineLocation: true,
    );
    
    // Filter scan results to only show devices containing 'HLK' or 'LD2410'
    return FlutterBluePlus.scanResults.map((results) {
      return results.where((r) {
        final name = r.device.platformName.toUpperCase();
        return name.contains("HLK") || name.contains("LD2410") || name.contains("RADAR");
      }).toList();
    });
  }

  /// Stop scan
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to the radar BLE device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      _connectedDevice = device;
      
      // Listen to connection state
      device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == BluetoothConnectionState.disconnected) {
          _cleanConnection();
        }
      });

      // Load active password (preferences first, then dotenv fallback)
      final prefs = await SharedPreferences.getInstance();
      _activePassword = prefs.getString('radar_ble_password_override') ?? _fallbackPassword;

      await device.connect(autoConnect: false, license: License.nonprofit);
      
      // Discover services
      final services = await device.discoverServices();
      BluetoothService? radarService;
      for (var s in services) {
        if (s.uuid.toString().toLowerCase().contains(serviceUuid)) {
          radarService = s;
          break;
        }
      }

      if (radarService == null) {
        debugPrint("[BLE] Radar config service (fff0) not found");
        await disconnect();
        return false;
      }

      // Find characteristics
      for (var c in radarService.characteristics) {
        final uuidStr = c.uuid.toString().toLowerCase();
        if (uuidStr.contains("fff1")) {
          _notifyChar = c;
        } else if (uuidStr.contains("fff2")) {
          _writeChar = c;
        }
      }

      if (_notifyChar == null || _writeChar == null) {
        debugPrint("[BLE] BLE characteristics missing");
        await disconnect();
        return false;
      }

      // Enable notifications
      await _notifyChar!.setNotifyValue(true);
      _notifySub = _notifyChar!.lastValueStream.listen(_onDataReceived);

      // Perform Authentication handshake
      _isAuthenticated = false;
      final authOk = await _authenticate();
      if (!authOk) {
        debugPrint("[BLE] Bluetooth authentication failed");
        await disconnect();
        return false;
      }

      _isAuthenticated = true;
      debugPrint("[BLE] Connected & Authenticated successfully!");
      return true;
    } catch (e) {
      debugPrint("[BLE] Connection error: $e");
      _cleanConnection();
      return false;
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _cleanConnection();
  }

  void _cleanConnection() {
    _notifySub?.cancel();
    _notifySub = null;
    _notifyChar = null;
    _writeChar = null;
    _connectedDevice = null;
    _isAuthenticated = false;
    _rxBuffer.clear();
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  /// Change BLE password. New password must be exactly 6 characters.
  Future<bool> changeBlePassword(String newPassword) async {
    if (!_isAuthenticated) {
      _commandStatusController.add("error: Bluetooth not connected");
      return false;
    }
    if (newPassword.length != 6) {
      _commandStatusController.add("error: Password must be exactly 6 characters");
      return false;
    }

    _commandStatusController.add("processing");

    // Cmd 0x00A9. Payload: 6 bytes new password
    final pwdBytes = newPassword.codeUnits;
    final packet = [
      0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01, // ON
      0xFD, 0xFC, 0xFB, 0xFA, 0x08, 0x00, 0xA9, 0x00,
      ...pwdBytes,
      0x04, 0x03, 0x02, 0x01, // Set password
      0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01 // OFF
    ];

    await _writeBytes(packet);
    
    // Save to SharedPreferences so the app uses this password next time!
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('radar_ble_password_override', newPassword);
    
    _commandStatusController.add("done");
    
    // Restart radar so it takes effect
    await sendCommand('restart_radar');
    return true;
  }

  /// Send password verification frame
  Future<bool> _authenticate() async {
    final pwdBytes = _activePassword.codeUnits;
    if (pwdBytes.length != 6) {
      debugPrint("[BLE] Error: BLE password must be exactly 6 characters");
      return false;
    }

    // Packet: Header (4) | Len (2) | Cmd (2) | Pwd (6) | Footer (4)
    final packet = <int>[
      0xFD, 0xFC, 0xFB, 0xFA, // Header
      0x08, 0x00,             // Length (8 bytes)
      0xA8, 0x00,             // Command 0x00A8 (Auth)
      ...pwdBytes,            // Password
      0x04, 0x03, 0x02, 0x01  // Footer
    ];

    _commandStatusController.add("processing");
    await _writeBytes(packet);

    // Wait for auth confirmation in notifications
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_isAuthenticated) return true;
    }
    return false;
  }

  /// Write raw bytes to the radar
  Future<void> _writeBytes(List<int> bytes) async {
    if (_writeChar == null) return;
    try {
      await _writeChar!.write(bytes, allowLongWrite: false);
    } catch (e) {
      debugPrint("[BLE] Write characteristic error: $e");
    }
  }

  /// Send standard settings configuration command
  Future<void> sendCommand(String command, {Map<String, dynamic>? params}) async {
    if (!_isAuthenticated) {
      _commandStatusController.add("error: Bluetooth not connected");
      return;
    }

    _commandStatusController.add("processing");

    List<int> packet;
    if (command == "read_config") {
      packet = [0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01, // Config Mode ON
                0xFD, 0xFC, 0xFB, 0xFA, 0x00, 0x00, 0x61, 0x00, 0x04, 0x03, 0x02, 0x01,             // Read Config
                0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01];            // Config Mode OFF
    } else if (command == "read_firmware") {
      packet = [0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01, // Config Mode ON
                0xFD, 0xFC, 0xFB, 0xFA, 0x00, 0x00, 0x70, 0x00, 0x04, 0x03, 0x02, 0x01,             // Read Firmware
                0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01];            // Config Mode OFF
    } else if (command == "set_max_gate") {
      final mGate = params?['moving_gate'] ?? 3;
      final sGate = params?['stationary_gate'] ?? 2;
      final timeout = params?['timeout'] ?? 1;

      packet = [
        0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01, // ON
        0xFD, 0xFC, 0xFB, 0xFA, 0x10, 0x00, 0x60, 0x00,
        mGate, 0x00, sGate, 0x00,
        timeout & 0xFF, (timeout >> 8) & 0xFF,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x04, 0x03, 0x02, 0x01, // Set gate
        0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01 // OFF
      ];
    } else if (command == "set_gate_sens") {
      final gate = params?['gate'] ?? 0;
      final moving = params?['moving'] ?? 50;
      final stationary = params?['stationary'] ?? 50;

      packet = [
        0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01, // ON
        0xFD, 0xFC, 0xFB, 0xFA, 0x06, 0x00, 0x60, 0x00,
        gate, moving, stationary, 0x00,
        0x04, 0x03, 0x02, 0x01, // Set single gate
        0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01 // OFF
      ];
    } else if (command == "set_all_gates_sens") {
      final payload = <int>[];
      for (int g = 0; g < 9; g++) {
        payload.add(g);
        payload.add(params?['m$g'] ?? 50);
        payload.add(params?['s$g'] ?? 50);
      }

      packet = [
        0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01, // ON
        0xFD, 0xFC, 0xFB, 0xFA, payload.length + 2, 0x00, 0x60, 0x00,
        ...payload,
        0x04, 0x03, 0x02, 0x01, // Set all gates
        0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01 // OFF
      ];
    } else if (command == "factory_reset") {
      packet = [
        0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01, // ON
        0xFD, 0xFC, 0xFB, 0xFA, 0x00, 0x00, 0x62, 0x00, 0x04, 0x03, 0x02, 0x01, // Reset
        0xFD, 0xFC, 0xFB, 0xFA, 0x02, 0x00, 0xFE, 0x00, 0x04, 0x03, 0x02, 0x01 // OFF
      ];
    } else if (command == "restart_radar") {
      packet = [
        0xFD, 0xFC, 0xFB, 0xFA, 0x04, 0x00, 0xFF, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01, // ON
        0xFD, 0xFC, 0xFB, 0xFA, 0x00, 0x00, 0x64, 0x00, 0x04, 0x03, 0x02, 0x01 // Restart
      ];
    } else if (command == "engineering_on") {
      packet = [
        0xFD, 0xFC, 0xFB, 0xFA, 0x01, 0x00, 0x63, 0x00, 0x01, 0x00, 0x04, 0x03, 0x02, 0x01 // Eng mode ON
      ];
    } else if (command == "engineering_off") {
      packet = [
        0xFD, 0xFC, 0xFB, 0xFA, 0x01, 0x00, 0x63, 0x00, 0x00, 0x00, 0x04, 0x03, 0x02, 0x01 // Eng mode OFF
      ];
    } else {
      _commandStatusController.add("error: Unknown command");
      return;
    }

    await _writeBytes(packet);
    
    // Auto done for settings writes
    if (command != "read_config" && command != "read_firmware") {
      _commandStatusController.add("done");
    }
  }

  /// BLE notifications handler
  void _onDataReceived(List<int> data) {
    if (data.isEmpty) return;
    _rxBuffer.addAll(data);

    while (_rxBuffer.length >= 10) {
      // Look for headers
      int idxCmd = _findSequence(_rxBuffer, [0xFD, 0xFC, 0xFB, 0xFA]);
      int idxReport = _findSequence(_rxBuffer, [0xF4, 0xF3, 0xF2, 0xF1]);

      if (idxCmd == -1 && idxReport == -1) {
        // No header found, clear buffer to prevent leakage if buffer size grows too large
        if (_rxBuffer.length > 512) {
          _rxBuffer.clear();
        }
        break;
      }

      // Handle Command response frame
      if (idxCmd != -1 && (idxReport == -1 || idxCmd < idxReport)) {
        if (idxCmd > 0) {
          _rxBuffer.removeRange(0, idxCmd);
          continue;
        }

        // Header at index 0, check length
        if (_rxBuffer.length < 6) break;
        int dLen = _rxBuffer[4] | (_rxBuffer[5] << 8);
        int totalLen = 6 + dLen + 4; // Header (4) + Len (2) + Data (dLen) + Footer (4)

        if (_rxBuffer.length < totalLen) break;

        // We have the full packet, extract it
        final frame = _rxBuffer.sublist(0, totalLen);
        _rxBuffer.removeRange(0, totalLen);
        _parseCommandFrame(frame);
      }
      // Handle report frame
      else if (idxReport != -1 && (idxCmd == -1 || idxReport < idxCmd)) {
        if (idxReport > 0) {
          _rxBuffer.removeRange(0, idxReport);
          continue;
        }

        // Header at index 0, check length
        if (_rxBuffer.length < 6) break;
        int dLen = _rxBuffer[4] | (_rxBuffer[5] << 8);
        int totalLen = 6 + dLen + 4; // Header (4) + Len (2) + Data (dLen) + Footer (4)

        if (_rxBuffer.length < totalLen) break;

        // We have the full packet, extract it
        final frame = _rxBuffer.sublist(0, totalLen);
        _rxBuffer.removeRange(0, totalLen);
        _parseReportFrame(frame);
      }
    }
  }

  int _findSequence(List<int> list, List<int> seq) {
    for (int i = 0; i <= list.length - seq.length; i++) {
      bool found = true;
      for (int j = 0; j < seq.length; j++) {
        if (list[i + j] != seq[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  void _parseCommandFrame(List<int> frame) {
    if (frame.length < 10) return;
    int cmdType = frame[6];
    
    // Auth acknowledgement
    if (cmdType == 0xA8) {
      int status = frame[8];
      if (status == 0x00) {
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } 
    // Read config response (0x61)
    else if (cmdType == 0x61) {
      try {
        final maxMoving = frame[8];
        final maxStationary = frame[9];
        final timeout = frame[10] | (frame[11] << 8);

        final gates = <GateSensitivity>[];
        int offset = 12;
        int gateCount = 0;

        while (offset + 2 < frame.length - 4 && gateCount <= 8) {
          int gIdx = frame[offset];
          if (gIdx <= 8) {
            gates.add(GateSensitivity(
              gate: gIdx,
              moving: frame[offset + 1],
              stationary: frame[offset + 2],
            ));
            gateCount++;
            offset += 3;
          } else {
            offset++;
          }
        }
        
        gates.sort((a, b) => a.gate.compareTo(b.gate));

        final cfg = RadarConfig(
          maxMovingGate: maxMoving,
          maxStationaryGate: maxStationary,
          inactivityTimeout: timeout,
          firmwareVersion: "BLE Mode Configured",
          gates: gates,
          lastUpdate: DateTime.now(),
        );

        _configController.add(cfg);
        _commandStatusController.add("done");
      } catch (e) {
        _commandStatusController.add("error: Failed to parse BLE config: $e");
      }
    } 
    // Read firmware response (0x70)
    else if (cmdType == 0x70) {
      final maj = frame[8];
      final min = frame[9];
      final bug = (frame[10] << 16) | (frame[11] << 8) | frame[12];
      
      final cfg = RadarConfig(
        maxMovingGate: 0,
        maxStationaryGate: 0,
        inactivityTimeout: 0,
        firmwareVersion: "v$maj.$min.${bug.toString().padLeft(4, '0')} (BLE)",
        gates: const [],
        lastUpdate: DateTime.now(),
      );
      _configController.add(cfg);
      _commandStatusController.add("done");
    }
  }

  void _parseReportFrame(List<int> frame) {
    if (frame.length < 12) return;
    int type = frame[6];
    int start = frame[7];
    
    if (start != 0xAA) return;

    if (type == 0x02) {
      // Basic Mode Report
      final mDist = frame[9] | (frame[10] << 8);
      final sDist = frame[12] | (frame[13] << 8);
      final pDist = frame[15] | (frame[16] << 8);

      final data = EngineeringData(
        presenceDistanceCm: pDist,
        movingDistanceCm: mDist,
        stationaryDistanceCm: sDist,
        movingEnergy: List.filled(9, 0),
        stationaryEnergy: List.filled(9, 0),
        timestamp: DateTime.now(),
      );
      _engineeringController.add(data);
    } 
    else if (type == 0x01) {
      // Engineering Mode Report
      final mDist = frame[9] | (frame[10] << 8);
      final sDist = frame[12] | (frame[13] << 8);
      final pDist = frame[15] | (frame[16] << 8);

      // Gate energy offsets
      final movingEng = <int>[];
      for (int i = 0; i < 9; i++) {
        movingEng.add(frame[19 + i]);
      }

      final stationaryEng = <int>[];
      for (int i = 0; i < 9; i++) {
        stationaryEng.add(frame[28 + i]);
      }

      final data = EngineeringData(
        presenceDistanceCm: pDist,
        movingDistanceCm: mDist,
        stationaryDistanceCm: sDist,
        movingEnergy: movingEng,
        stationaryEnergy: stationaryEng,
        timestamp: DateTime.now(),
      );
      _engineeringController.add(data);
    }
  }
}
