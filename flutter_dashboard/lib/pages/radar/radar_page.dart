import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../widgets/fade_slide.dart';
import '../../services/radar_config_service.dart';
import '../../models/radar_config.dart';
import 'widgets/radar_info_card.dart';
import 'widgets/gate_sensitivity_card.dart';
import 'widgets/engineering_monitor.dart';

class RadarPage extends StatefulWidget {
  const RadarPage({super.key});

  @override
  State<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage> {
  final RadarConfigService _service = RadarConfigService();
  StreamSubscription<RadarConfig>? _configSub;
  StreamSubscription<EngineeringData>? _engSub;

  RadarConfig _config = RadarConfig.empty;
  EngineeringData _engData = EngineeringData.empty;
  bool _isLoading = false;
  bool _isEngActive = false;

  @override
  void initState() {
    super.initState();
    _configSub = _service.configStream.listen((cfg) {
      if (mounted) setState(() => _config = cfg);
    });
    _engSub = _service.engineeringStream.listen((data) {
      if (mounted) setState(() => _engData = data);
    });
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _engSub?.cancel();
    super.dispose();
  }

  Future<void> _readConfig() async {
    setState(() => _isLoading = true);
    await _service.readConfig();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _readFirmware() async {
    setState(() => _isLoading = true);
    await _service.readFirmware();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _toggleEngineering() async {
    if (_isEngActive) {
      await _service.stopEngineeringMode();
    } else {
      await _service.startEngineeringMode();
    }
    setState(() => _isEngActive = !_isEngActive);
  }

  Future<void> _applyGate(int gate, int moving, int stationary) async {
    await _service.setSingleGateSensitivity(
      gate: gate, moving: moving, stationary: stationary);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gate $gate: M$moving S$stationary applied'),
          duration: const Duration(seconds: 2)));
  }

  Future<void> _factoryReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Factory Reset?'),
        content: const Text('This resets radar to factory defaults. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirm == true) {
      await _service.factoryReset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Factory reset sent to radar')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Restart Radar',
            onPressed: () async {
              await _service.restart();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restart command sent')));
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _readConfig,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const FadeSlide(index: 0, child: SectionHeader(title: 'DEVICE INFO')),
              FadeSlide(index: 1, child: RadarInfoCard(
                config: _config,
                isLoading: _isLoading,
                onReadConfig: _readConfig,
                onReadFirmware: _readFirmware,
              )),
              const SizedBox(height: 24),
              const FadeSlide(index: 2, child: SectionHeader(title: 'DETECTION RANGE')),
              FadeSlide(index: 3, child: _buildMaxGateSection()),
              const SizedBox(height: 24),
              const FadeSlide(index: 4, child: SectionHeader(title: 'GATE SENSITIVITY')),
              FadeSlide(index: 5, child: _buildGateList()),
              const SizedBox(height: 24),
              const FadeSlide(index: 6, child: SectionHeader(title: 'ENGINEERING MODE')),
              FadeSlide(index: 7, child: _buildEngineeringSection()),
              const SizedBox(height: 16),
              FadeSlide(index: 8, child: _buildDangerZone()),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMaxGateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Moving: Gate ${_config.maxMovingGate} '
                '(~${(_config.maxMovingGate * 0.75 + 0.75).toStringAsFixed(1)}m)'),
            const SizedBox(height: 4),
            Text('Stationary: Gate ${_config.maxStationaryGate} '
                '(~${(_config.maxStationaryGate * 0.75 + 0.75).toStringAsFixed(1)}m)'),
            const SizedBox(height: 4),
            Text('Inactivity Timeout: ${_config.inactivityTimeout}s'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showMaxGateDialog(),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Change Range'),
            ),
          ],
        ),
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
          title: const Text('Set Detection Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _rangeSlider(ctx, 'Moving Max Gate', mGate, 0, 9, (v) {
                setDialogState(() => mGate = v);
              }),
              _rangeSlider(ctx, 'Stationary Max Gate', sGate, 0, 9, (v) {
                setDialogState(() => sGate = v);
              }),
              _rangeSlider(ctx, 'Timeout (seconds)', timeout, 1, 60, (v) {
                setDialogState(() => timeout = v);
              }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(onPressed: () {
              Navigator.pop(ctx);
              _service.setMaxGate(
                movingGate: mGate,
                stationaryGate: sGate,
                timeoutSeconds: timeout,
              );
            }, child: const Text('Apply')),
          ],
        ),
      ),
    );
  }

  Widget _rangeSlider(BuildContext ctx, String label, int value,
      int min, int max, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label)),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(), max: max.toDouble(),
              divisions: max - min,
              label: value.toString(),
              onChanged: (v) => onChanged(v.toInt()),
            ),
          ),
          SizedBox(width:32, child: Text('$value', textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildGateList() {
    if (_config.gates.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No gate data. Tap Read Config to load.')),
        ),
      );
    }
    return Column(
      children: _config.gates.map((g) => GateSensitivityCard(
        gate: g,
        onApply: (m, s) => _applyGate(g.gate, m, s),
      )).toList(),
    );
  }

  Widget _buildEngineeringSection() {
    return Column(
      children: [
        Card(
          child: SwitchListTile(
            title: const Text('Engineering Mode'),
            subtitle: const Text('Real-time energy data per gate'),
            value: _isEngActive,
            onChanged: (_) => _toggleEngineering(),
            secondary: Icon(
              _isEngActive ? Icons.monitor_heart : Icons.monitor_heart_outlined,
              color: _isEngActive ? Colors.green : null,
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

  Widget _buildDangerZone() {
    return Card(
      color: Colors.red.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone', style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 2),
                  Text('Reset radar to factory defaults',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _factoryReset,
              icon: const Icon(Icons.factory, color: Colors.redAccent, size: 18),
              label: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
