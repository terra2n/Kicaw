import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../widgets/section_header.dart';
import '../../widgets/fade_slide.dart';
import '../../services/radar_connection_manager.dart';
import '../../models/radar_config.dart';
import '../../theme/app_colors.dart';
import 'widgets/gate_sensitivity_card.dart';
import 'widgets/engineering_monitor.dart';
import 'widgets/radar_visualization.dart';

class RadarPage extends StatefulWidget {
  const RadarPage({super.key});

  @override
  State<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage>
    with SingleTickerProviderStateMixin {
  final RadarConnectionManager _manager = RadarConnectionManager();
  StreamSubscription<RadarConfig>? _configSub;
  StreamSubscription<EngineeringData>? _engSub;
  StreamSubscription<String>? _cmdStatusSub;

  // Bug #11 fix: Safety timeout agar _isLoading tidak stuck selamanya
  Timer? _loadingTimeout;
  static const _loadingTimeoutDuration = Duration(seconds: 10);

  late TabController _tabController;

  RadarConfig _config = RadarConfig.empty;
  EngineeringData _engData = EngineeringData.empty;
  bool _isLoading = false;
  bool _isEngActive = false;
  String _pendingEngCommand = '';

  static const _tabLabels = ['All', 'Moving', 'Stationary'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _configSub = _manager.configStream.listen((cfg) {
      if (mounted) setState(() {
        _config = cfg;
        _isLoading = false;
      });
    });
    _engSub = _manager.engineeringStream.listen((data) {
      if (mounted) setState(() => _engData = data);
    });
    _cmdStatusSub = _manager.commandStatusStream.listen((status) {
      if (!mounted) return;
      if (status == 'done') {
        _loadingTimeout?.cancel();
        setState(() {
          _isLoading = false;
          if (_pendingEngCommand == 'engineering_on') _isEngActive = true;
          if (_pendingEngCommand == 'engineering_off') _isEngActive = false;
          _pendingEngCommand = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Command completed'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      } else if (status.startsWith('error')) {
        _loadingTimeout?.cancel();
        setState(() {
          _isLoading = false;
          _pendingEngCommand = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Command failed: $status'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    Future.wait([_manager.init(), _manager.bleService.init()]).then((_) {
      if (mounted) {
        setState(() {});
        if (_manager.connectionMode == 'cloud') {
          _readConfig();
        }
      }
    });
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _engSub?.cancel();
    _cmdStatusSub?.cancel();
    _loadingTimeout?.cancel();  // Bug #11 fix: Pastikan timer dibersihkan
    _tabController.dispose();
    super.dispose();
  }

  // ── Commands ──

  // Track perintah terakhir untuk sinkronisasi state engineering
  String lastCommand = '';

  // Bug #11 fix: Mulai timeout saat loading dimulai
  void _startLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(_loadingTimeoutDuration, () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _sendCommand(String command, {Map<String, dynamic>? params}) async {
    setState(() => _isLoading = true);
    lastCommand = command;
    _startLoadingTimeout();
    await _manager.sendCommand(command, params: params);
  }

  Future<void> _readConfig() async {
    await _sendCommand('read_config');
  }

  Future<void> _readFirmware() async {
    await _sendCommand('read_firmware');
  }

  Future<void> _toggleEngineering() async {
    final cmd = _isEngActive ? 'engineering_off' : 'engineering_on';
    _pendingEngCommand = cmd;
    await _sendCommand(cmd);
  }

  Future<void> _applyGate(int gate, int moving, int stationary) async {
    await _sendCommand('set_gate_sens',
        params: {'gate': gate, 'moving': moving, 'stationary': stationary});
  }

  Future<void> _factoryReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Factory Reset?'),
          ],
        ),
        content: const Text(
          'This will reset all radar settings to factory defaults.\n'
          'Your custom sensitivity profiles will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _sendCommand('factory_reset');
    }
  }

  // ── Helpers ──

  String get _activeTabName {
    switch (_tabController.index) {
      case 0:
        return 'all';
      case 1:
        return 'moving';
      case 2:
        return 'stationary';
      default:
        return 'all';
    }
  }

  double _movingDistanceM() => (_config.maxMovingGate * 0.75 + 0.75);
  double _stationaryDistanceM() => (_config.maxStationaryGate * 0.75 + 0.75);

  int _avgMovingSens() {
    if (_config.gates.isEmpty) return 0;
    final sum = _config.gates.fold<int>(0, (prev, g) => prev + g.moving);
    return (sum / _config.gates.length).round();
  }

  int _avgStationarySens() {
    if (_config.gates.isEmpty) return 0;
    final sum =
        _config.gates.fold<int>(0, (prev, g) => prev + g.stationary);
    return (sum / _config.gates.length).round();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar Settings'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Config',
            onPressed: _isLoading ? null : _readConfig,
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'firmware') await _readFirmware();
              if (val == 'restart') {
                await _sendCommand('restart_radar');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'firmware',
                child: ListTile(
                  leading: Icon(Icons.info_outline, size: 20),
                  title: Text('Read Firmware'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'restart',
                child: ListTile(
                  leading: Icon(Icons.restart_alt, size: 20),
                  title: Text('Restart Radar'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _readConfig,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tab Switcher ──
              FadeSlide(index: 0, child: _buildTabSwitcher()),

              // ── Connection Selector (Cloud vs BLE) ──
              FadeSlide(index: 1, child: _buildConnectionSelector()),

              // ── Radar Visualization ──
              FadeSlide(index: 2, child: _buildVisualizationCard()),

              // ── Summary Stats ──
              FadeSlide(index: 3, child: _buildSummaryStats()),

              // ── Content Sections ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const FadeSlide(
                      index: 4,
                      child: SectionHeader(title: 'DETECTION RANGE'),
                    ),
                    FadeSlide(
                      index: 5,
                      child: _buildDetectionRangeCard(),
                    ),

                    const SizedBox(height: 24),
                    const FadeSlide(
                      index: 6,
                      child: SectionHeader(title: 'QUICK PRESETS'),
                    ),
                    FadeSlide(index: 7, child: _buildPresets()),

                    const SizedBox(height: 24),
                    FadeSlide(
                      index: 8,
                      child: SectionHeader(
                        title: _tabController.index == 0
                            ? 'GATE SENSITIVITY'
                            : _tabController.index == 1
                                ? 'MOVING SENSITIVITY'
                                : 'STATIONARY SENSITIVITY',
                      ),
                    ),
                    FadeSlide(index: 9, child: _buildGateList()),

                    const SizedBox(height: 24),
                    const FadeSlide(
                      index: 10,
                      child: SectionHeader(title: 'ENGINEERING MODE'),
                    ),
                    FadeSlide(
                      index: 11,
                      child: _buildEngineeringSection(),
                    ),

                    const SizedBox(height: 16),
                    FadeSlide(index: 12, child: _buildDangerZone()),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Connection Selector ──

  Widget _buildConnectionSelector() {
    final mode = _manager.connectionMode;
    final isBle = mode == 'ble';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBle ? Colors.blue.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isBle ? Icons.bluetooth : Icons.cloud_queue,
                    color: isBle ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode Koneksi',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isBle ? 'Lokal (Bluetooth BLE)' : 'Cloud (Firebase Database)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isBle,
                activeColor: Colors.blue,
                activeTrackColor: Colors.blue.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.green,
                inactiveTrackColor: Colors.green.withValues(alpha: 0.3),
                onChanged: (val) async {
                  await _manager.setConnectionMode(val ? 'ble' : 'cloud');
                  setState(() {});
                  if (!val) {
                    _readConfig();
                  }
                },
              ),
            ],
          ),
          if (isBle) ...[
            const Divider(height: 24),
            _buildBleConnectionPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildBleConnectionPanel() {
    final bleService = _manager.bleService;
    final device = bleService.connectedDevice;
    final isConnected = device != null && bleService.isAuthenticated;

    if (isConnected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.platformName.isNotEmpty ? device.platformName : 'Radar HLK-LD2410',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Remote ID: ${device.remoteId.str}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          TextButton.icon(
            icon: const Icon(Icons.bluetooth_disabled, size: 16),
            label: const Text('Disconnect'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              await bleService.disconnect();
              setState(() {});
            },
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                'Bluetooth belum terhubung',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.search, size: 16),
            label: const Text('Scan Radar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _showBleScanDialog,
          ),
        ],
      );
    }
  }

  void _showBleScanDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String? scanError;
            return StreamBuilder<List<ScanResult>>(
              stream: _manager.bleService.scanForRadar(),
              builder: (context, snapshot) {
                final results = snapshot.data ?? [];

                return StreamBuilder<String>(
                  stream: _manager.bleService.scanErrorStream,
                  builder: (context, errSnapshot) {
                    scanError = errSnapshot.data;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pilih Perangkat Radar',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _manager.bleService.stopScan();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (scanError != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                scanError!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (results.isEmpty && scanError == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(strokeWidth: 3),
                                    SizedBox(height: 12),
                                    Text(
                                      'Mencari radar HLK-LD2410...',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            else if (results.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: results.length,
                                itemBuilder: (context, idx) {
                                  final r = results[idx];
                                  final mac = r.device.remoteId.str;
                                  final isLastConnected = mac == _manager.bleService.lastConnectedMac;
                                  return ListTile(
                                    leading: Icon(
                                      Icons.bluetooth,
                                      color: isLastConnected ? Colors.green : Colors.blue,
                                    ),
                                    title: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            r.device.platformName.isNotEmpty
                                                ? r.device.platformName
                                                : 'Unknown Device',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isLastConnected) ...[
                                          const SizedBox(width: 6),
                                          Icon(Icons.check_circle,
                                              size: 14, color: Colors.green),
                                          const SizedBox(width: 3),
                                          Text('Sebelumnya',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green)),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text(mac),
                                    trailing: Text('${r.rssi} dBm'),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      setState(() => _isLoading = true);
                                      final success = await _manager.bleService.connect(r.device);
                                      setState(() => _isLoading = false);
                                      if (success) {
                                        _readConfig();
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Gagal menghubungkan atau Password salah'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _manager.bleService.stopScan();
    });
  }

  // ── Tab Switcher ──

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final isSelected = _tabController.index == i;
          final color = i == 2 ? Colors.orangeAccent : AppColors.primary;

          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      i == 0
                          ? Icons.layers_outlined
                          : i == 1
                              ? Icons.directions_run
                              : Icons.chair_outlined,
                      size: 20,
                      color: isSelected ? color : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tabLabels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Radar Visualization ──

  Widget _buildVisualizationCard() {
    final movingList = _config.gates.map((g) => g.moving).toList();
    final statList = _config.gates.map((g) => g.stationary).toList();

    while (movingList.length < 9) {
      movingList.add(0);
    }
    while (statList.length < 9) {
      statList.add(0);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.radar, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detection Map',
                          style: Theme.of(context).textTheme.titleSmall),
                      Text('HLK-LD2410C · 24GHz FMCW',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                _statusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.shade100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: RadarVisualization(
                  movingSensitivity: movingList,
                  stationarySensitivity: statList,
                  maxMovingGate: _config.maxMovingGate,
                  maxStationaryGate: _config.maxStationaryGate,
                  activeTab: _activeTabName,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _vizLegend(),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    // Gunakan gates.isNotEmpty sebagai indikator data sudah diterima dari Firebase
    final isConfigLoaded = _config.gates.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isConfigLoaded
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConfigLoaded ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConfigLoaded ? 'Config Loaded' : 'No Data',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isConfigLoaded ? Colors.green.shade700 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vizLegend() {
    final showMoving = _activeTabName == 'all' || _activeTabName == 'moving';
    final showStat =
        _activeTabName == 'all' || _activeTabName == 'stationary';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showMoving) ...[
          _legendDot(AppColors.primary, 'Moving'),
          if (showStat) const SizedBox(width: 20),
        ],
        if (showStat) _legendDot(Colors.orangeAccent, 'Stationary'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  // ── Summary Stats ──

  Widget _buildSummaryStats() {
    final showMoving = _activeTabName == 'all' || _activeTabName == 'moving';
    final showStat = _activeTabName == 'all' || _activeTabName == 'stationary';

    final stats = <_StatItem>[];
    if (showMoving) {
      stats.add(_StatItem(
        icon: Icons.speed,
        color: AppColors.primary,
        label: 'Moving Range',
        value: '${_movingDistanceM().toStringAsFixed(1)}m',
        sub: 'Gate 0-${_config.maxMovingGate}',
      ));
    }
    if (showStat) {
      stats.add(_StatItem(
        icon: Icons.anchor,
        color: Colors.orangeAccent,
        label: 'Stat. Range',
        value: '${_stationaryDistanceM().toStringAsFixed(1)}m',
        sub: 'Gate 0-${_config.maxStationaryGate}',
      ));
    }
    if (showMoving) {
      stats.add(_StatItem(
        icon: Icons.tune,
        color: AppColors.primary,
        label: 'Avg Moving',
        value: '${_avgMovingSens()}%',
        sub: '${_config.gates.length} gates',
      ));
    }
    if (showStat) {
      stats.add(_StatItem(
        icon: Icons.tune,
        color: Colors.orangeAccent,
        label: 'Avg Stat.',
        value: '${_avgStationarySens()}%',
        sub: '${_config.gates.length} gates',
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
        ),
        itemCount: stats.length,
        itemBuilder: (_, i) => _statCard(stats[i]),
      ),
    );
  }

  Widget _statCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stat.color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(stat.label,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: stat.color,
                  ),
                ),
                Text(stat.sub,
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Detection Range ──

  Widget _buildDetectionRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_input_antenna,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Range Configuration',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showMaxGateDialog(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _rangeIndicator('Moving', _config.maxMovingGate,
                _movingDistanceM(), AppColors.primary),
            const SizedBox(height: 12),
            _rangeIndicator('Stationary', _config.maxStationaryGate,
                _stationaryDistanceM(), Colors.orangeAccent),
            const SizedBox(height: 12),
            _infoChip(
              Icons.timer_outlined,
              'Inactivity timeout: ${_config.inactivityTimeout}s',
            ),
          ],
        ),
      ),
    );
  }

  Widget _rangeIndicator(
      String label, int gate, double distance, Color color) {
    final fraction = (gate + 1) / 9;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, constraints) {
            return Container(
              height: 24,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Gate $gate',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        '${distance.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _showMaxGateDialog() {
    int mGate = _config.maxMovingGate;
    int sGate = _config.maxStationaryGate;
    int timeout = _config.inactivityTimeout;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings_input_antenna, size: 22),
              SizedBox(width: 8),
              Text('Set Detection Range'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogSlider(ctx, 'Moving Max Gate', mGate, 0, 9,
                  Icons.directions_run, AppColors.primary, (v) {
                setDialogState(() => mGate = v);
              }),
              const SizedBox(height: 4),
              Text(
                '~${(mGate * 0.75 + 0.75).toStringAsFixed(1)}m range',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _dialogSlider(ctx, 'Stationary Max Gate', sGate, 0, 9,
                  Icons.chair_outlined, Colors.orangeAccent, (v) {
                setDialogState(() => sGate = v);
              }),
              const SizedBox(height: 4),
              Text(
                '~${(sGate * 0.75 + 0.75).toStringAsFixed(1)}m range',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(height: 32),
              _dialogSlider(ctx, 'Timeout (seconds)', timeout, 1, 60,
                  Icons.timer_outlined, Colors.grey, (v) {
                setDialogState(() => timeout = v);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _sendCommand('set_max_gate', params: {
                  'moving_gate': mGate,
                  'stationary_gate': sGate,
                  'timeout': timeout,
                });
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogSlider(
    BuildContext ctx,
    String label,
    int value,
    int min,
    int max,
    IconData icon,
    Color color,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$value',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(ctx).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.12),
            inactiveTrackColor: color.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: value.toString(),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
      ],
    );
  }

  // ── Presets ──

  static const _presets = <String, _PresetData>{
    'Office': _PresetData(
      icon: Icons.business,
      desc: 'Balanced for desks',
      values: [80, 70, 60, 50, 40, 30, 20, 10, 10],
    ),
    'Hallway': _PresetData(
      icon: Icons.straight,
      desc: 'Uniform corridor',
      values: [50, 50, 50, 50, 50, 50, 50, 50, 50],
    ),
    'Open Space': _PresetData(
      icon: Icons.grid_view,
      desc: 'High near, gradual far',
      values: [90, 80, 70, 60, 50, 40, 30, 20, 10],
    ),
    'Near Only': _PresetData(
      icon: Icons.near_me,
      desc: 'Immediate area focus',
      values: [100, 60, 30, 10, 10, 10, 10, 10, 10],
    ),
  };

  Widget _buildPresets() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 4),
        itemCount: _presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final entry = _presets.entries.elementAt(i);
          return _presetCard(entry.key, entry.value);
        },
      ),
    );
  }

  Widget _presetCard(String name, _PresetData preset) {
    return GestureDetector(
      onTap: () => _applyPreset(preset.values),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(preset.icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(height: 8),
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              preset.desc,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyPreset(List<int> values) async {
    // Build params m0-m8, s0-s8 sesuai format set_all_gates_sens
    final params = <String, dynamic>{};
    for (int i = 0; i < 9 && i < values.length; i++) {
      params['m$i'] = values[i];
      params['s$i'] = values[i];
    }
    await _sendCommand('set_all_gates_sens', params: params);
  }

  // ── Gate List ──

  Widget _buildGateList() {
    if (_config.gates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.radar, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No gate data loaded',
                    style: TextStyle(color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _readConfig,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Read Config'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredGates = _config.gates.where((g) {
      if (_tabController.index == 0) return true;
      if (_tabController.index == 1) return g.gate <= _config.maxMovingGate;
      return g.gate <= _config.maxStationaryGate;
    }).toList();

    return Column(
      children: filteredGates
          .map((g) => GateSensitivityCard(
                gate: g,
                onApply: (m, s) => _applyGate(g.gate, m, s),
              ))
          .toList(),
    );
  }

  // ── Engineering ──

  Widget _buildEngineeringSection() {
    return Column(
      children: [
        Card(
          child: SwitchListTile(
            title: const Text('Engineering Mode'),
            subtitle: Text(
              _isEngActive
                  ? 'Live energy data streaming'
                  : 'Enable for real-time per-gate data',
              style: TextStyle(
                fontSize: 12,
                color: _isEngActive ? Colors.green.shade600 : null,
              ),
            ),
            value: _isEngActive,
            onChanged: (_) => _toggleEngineering(),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (_isEngActive ? Colors.green : Colors.grey)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isEngActive
                    ? Icons.monitor_heart
                    : Icons.monitor_heart_outlined,
                color: _isEngActive ? Colors.green : Colors.grey,
                size: 22,
              ),
            ),
          ),
        ),
        if (_isEngActive) ...[
          const SizedBox(height: 8),
          EngineeringMonitor(data: _engData, isActive: _isEngActive),
        ],
      ],
    );
  }

  // BLE settings card for password management
  Widget _buildBleSettingsCard() {
    final isBle = _manager.connectionMode == 'ble';
    if (!isBle) return const SizedBox.shrink();

    final bleService = _manager.bleService;
    final isConnected = bleService.connectedDevice != null && bleService.isAuthenticated;
    if (!isConnected) return const SizedBox.shrink();

    final textController = TextEditingController();

    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock_outline, color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Pengaturan Password Bluetooth',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Ubah password BLE radar Anda. Password baru harus tepat 6 karakter. Radar akan otomatis di-restart setelah diubah.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: 'Password Baru (6 char)',
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final pwd = textController.text.trim();
                    if (pwd.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password harus tepat 6 karakter!'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Ubah Password BLE?'),
                        content: Text('Apakah Anda yakin ingin mengubah password Bluetooth radar ke "$pwd"?\nRadar akan segera di-restart.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Ubah & Restart'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      setState(() => _isLoading = true);
                      final success = await _manager.changeBlePassword(pwd);
                      setState(() => _isLoading = false);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password berhasil diubah & Radar di-restart. Silakan hubungkan kembali.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        await _manager.bleService.disconnect();
                        setState(() {});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal mengubah password Bluetooth'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Danger Zone ──

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 2),
                  Text('Reset radar to factory defaults',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _factoryReset,
              icon: const Icon(Icons.factory_outlined,
                  color: Colors.redAccent, size: 18),
              label: const Text('Reset',
                  style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper classes ──

class _StatItem {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });
}

class _PresetData {
  final IconData icon;
  final String desc;
  final List<int> values;

  const _PresetData({
    required this.icon,
    required this.desc,
    required this.values,
  });
}
