import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase/daily_summary.dart';
import '../../widgets/fade_slide.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/empty_state.dart';
import 'widgets/monthly_targets.dart';
import 'widgets/trend_line_chart.dart';
import 'widgets/alltime_summary.dart';
import 'widgets/best_day_card.dart';
import 'widgets/emission_factor_tile.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final SupabaseService _supa = SupabaseService();
  List<DailySummary>? _summaries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _summaries = await _supa.getDailySummaries(days: 30);
    } catch (e) {
      debugPrint('Error loading summaries: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
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
                    const FadeSlide(index: 0, child: SectionHeader(title: 'MONTHLY TARGETS')),
                    FadeSlide(index: 1, child: _summaries == null || _summaries!.isEmpty
                        ? const ErrorBanner(message: 'Targets unavailable')
                        : _buildMonthlyTargets()),
                    const SizedBox(height: 24),
                    const FadeSlide(index: 2, child: SectionHeader(title: 'CO₂ TREND — 30 DAYS')),
                    FadeSlide(index: 3, child: _summaries == null
                        ? const ErrorBanner(message: 'Trend data unavailable')
                        : _summaries!.isEmpty
                            ? const EmptyState(icon: Icons.trending_up, title: 'No CO₂ data yet')
                            : TrendLineChart(
                                values: _summaries!.reversed.map((s) => (s.avgCo2Ppm ?? 0).toDouble()).toList())),
                    const SizedBox(height: 24),
                    const FadeSlide(index: 4, child: SectionHeader(title: 'ALL-TIME')),
                    FadeSlide(index: 5, child: _summaries == null || _summaries!.isEmpty
                        ? const ErrorBanner(message: 'Summary unavailable')
                        : _buildAllTimeSummary()),
                    const SizedBox(height: 24),
                    const FadeSlide(index: 6, child: SectionHeader(title: 'BEST DAY')),
                    FadeSlide(index: 7, child: _summaries == null || _summaries!.isEmpty
                        ? const ErrorBanner(message: 'Best day data unavailable')
                        : _buildBestDayCard()),
                    const SizedBox(height: 24),
                    const FadeSlide(index: 8, child: SectionHeader(title: 'EMISSION FACTOR')),
                    FadeSlide(index: 9, child: const Column(children: [
                        EmissionFactorTile(label: 'Grid intensity', value: '850 g CO₂/kWh'),
                        SizedBox(height: 8),
                        EmissionFactorTile(label: 'Source', value: 'Indonesia (IPCC 2026)'),
                      ])),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMonthlyTargets() {
    if (_summaries == null || _summaries!.isEmpty) return const SizedBox.shrink();

    final totalLampMinutes = _summaries!.fold<int>(0, (sum, s) => sum + s.lampOnMinutes);
    final totalWhSaved = totalLampMinutes * (3.0 / 60.0);
    final totalCo2Grams = totalWhSaved * 0.85;

    const targetMonthlyGrams = 50.0;
    const targetMonthlyWh = 1000.0;

    final co2Percent = (totalCo2Grams / targetMonthlyGrams) * 100;
    final energyPercent = (totalWhSaved / targetMonthlyWh) * 100;

    return MonthlyTargets(
      co2Percent: co2Percent,
      energyPercent: energyPercent,
    );
  }

  Widget _buildAllTimeSummary() {
    if (_summaries == null || _summaries!.isEmpty) return const SizedBox.shrink();

    final totalMotion = _summaries!.fold<int>(0, (sum, s) => sum + s.motionCount);
    final totalLampMinutes = _summaries!.fold<int>(0, (sum, s) => sum + s.lampOnMinutes);

    // [FLU-H5 fix] avgCo2Ppm adalah konsentrasi udara (PPM sensor), bukan massa emisi CO₂.
    // Hitung emisi dari energi yang terpakai: lampOnMinutes × 3W × faktor emisi grid Indonesia
    final totalWhUsed = totalLampMinutes * (3.0 / 60.0);             // Wh
    final totalCo2Grams = (totalWhUsed / 1000.0) * 0.85 * 1000.0;   // gram

    return AlltimeSummary(
      sessions: totalMotion,
      hoursSaved: totalLampMinutes / 60.0,
      co2Grams: totalCo2Grams,
    );
  }

  Widget _buildBestDayCard() {
    if (_summaries == null || _summaries!.isEmpty) return const SizedBox.shrink();

    // Find day with highest motion count (most activity)
    final bestDay = _summaries!.reduce((a, b) => a.motionCount > b.motionCount ? a : b);
    final dateStr = '${bestDay.date.day}/${bestDay.date.month}/${bestDay.date.year}';
    final subtitle = '${bestDay.motionCount} motion events — ${bestDay.lampOnMinutes} min lamp on';

    return BestDayCard(date: dateStr, subtitle: subtitle);
  }
}
