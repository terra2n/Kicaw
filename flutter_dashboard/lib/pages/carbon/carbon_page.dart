import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase/sensor_log.dart';
import '../../models/supabase/daily_summary.dart';
import '../../widgets/fade_slide.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/empty_state.dart';
import 'widgets/total_co2_hero.dart';
import 'widgets/real_world_equivalents.dart';
import 'widgets/daily_co2_chart.dart';
import 'widgets/emission_info.dart';

class CarbonPage extends StatefulWidget {
  const CarbonPage({super.key});

  @override
  State<CarbonPage> createState() => _CarbonPageState();
}

class _CarbonPageState extends State<CarbonPage> {
  final SupabaseService _supa = SupabaseService();
  List<SensorLog>? _sensorLogs;
  List<DailySummary>? _dailySummaries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load sensor logs for real-time data
      _sensorLogs = await _supa.getSensorLogs(limit: 100);
      // Load daily summaries for historical data
      _dailySummaries = await _supa.getDailySummaries(days: 30);
    } catch (e) {
      debugPrint('Error loading carbon data: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carbon')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const FadeSlide(index: 0, child: SectionHeader(title: 'THIS MONTH')),
                    FadeSlide(index: 1, child: _dailySummaries == null || _dailySummaries!.isEmpty
                        ? const ErrorBanner(message: 'Carbon data unavailable')
                        : _buildTotalCo2Hero()),
                    const SizedBox(height: 24),
                    const FadeSlide(index: 2, child: SectionHeader(title: 'REAL-WORLD EQUIVALENTS')),
                    FadeSlide(index: 3, child: _dailySummaries == null || _dailySummaries!.isEmpty
                        ? const ErrorBanner(message: 'Equivalents unavailable')
                        : _buildRealWorldEquivalents()),
                    const SizedBox(height: 24),
                    const FadeSlide(index: 4, child: SectionHeader(title: 'CO₂ PER DAY — LAST 30 DAYS')),
                    FadeSlide(index: 5, child: _dailySummaries == null
                        ? const ErrorBanner(message: 'Chart unavailable')
                        : _dailySummaries!.isEmpty
                            ? const EmptyState(icon: Icons.eco, title: 'No CO₂ data yet')
                            : _buildDailyCo2Chart()),
                    const SizedBox(height: 24),
                    const FadeSlide(index: 6, child: SectionHeader(title: 'DETAILS')),
                    FadeSlide(index: 7, child: _sensorLogs == null || _sensorLogs!.isEmpty
                        ? const ErrorBanner(message: 'Details unavailable')
                        : _buildDetails()),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTotalCo2Hero() {
    if (_dailySummaries == null || _dailySummaries!.isEmpty) return const SizedBox.shrink();

    final totalLampMinutes = _dailySummaries!.fold<int>(0, (sum, s) => sum + s.lampOnMinutes);
    final totalCo2Grams = totalLampMinutes * (3.0 / 60.0) * 0.85;
    return TotalCo2Hero(co2Grams: totalCo2Grams);
  }

  Widget _buildRealWorldEquivalents() {
    if (_dailySummaries == null || _dailySummaries!.isEmpty) return const SizedBox.shrink();

    final totalLampMinutes = _dailySummaries!.fold<int>(0, (sum, s) => sum + s.lampOnMinutes);
    final totalCo2Grams = totalLampMinutes * (3.0 / 60.0) * 0.85;
    return RealWorldEquivalents(co2Grams: totalCo2Grams);
  }

  Widget _buildDailyCo2Chart() {
    if (_dailySummaries == null || _dailySummaries!.isEmpty) return const SizedBox.shrink();

    final co2GramsValues = _dailySummaries!.reversed.map((s) => (s.lampOnMinutes * (3.0 / 60.0) * 0.85).toDouble()).toList();
    return DailyCo2Chart(co2GramsValues: co2GramsValues);
  }

  Widget _buildDetails() {
    if (_sensorLogs == null || _sensorLogs!.isEmpty) return const SizedBox.shrink();

    // Calculate average CO2 from recent sensor logs
    final avgCo2 = _sensorLogs!.fold<double>(0, (sum, log) => sum + (log.co2Ppm ?? 0)) / _sensorLogs!.length;

    // Calculate total CO2 this month from daily summaries
    final totalLampMinutes = _dailySummaries != null && _dailySummaries!.isNotEmpty
        ? _dailySummaries!.fold<int>(0, (sum, s) => sum + s.lampOnMinutes)
        : 0;
    final totalCo2Grams = totalLampMinutes * (3.0 / 60.0) * 0.85;

    // Count lamp cycles from activity logs
    final lampCycles = _sensorLogs!.where((log) => log.lampStatus == true).length;

    return Column(children: [
      EmissionInfo(label: 'Average CO₂', value: '${avgCo2.toStringAsFixed(0)} ppm'),
      const SizedBox(height: 8),
      const EmissionInfo(label: 'Grid factor', value: '850 g CO₂/kWh'),
      const SizedBox(height: 8),
      EmissionInfo(label: 'Total this month', value: '${totalCo2Grams.toStringAsFixed(2)} g'),
      const SizedBox(height: 8),
      EmissionInfo(label: 'Lamp cycles', value: '$lampCycles on/off events'),
    ]);
  }
}
