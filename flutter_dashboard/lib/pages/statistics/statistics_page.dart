import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../services/firestore_service.dart';
import '../../widgets/fade_slide.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/error_banner.dart';
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
  final FirestoreService _fs = FirestoreService();

  Future<void> _onRefresh() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: StreamBuilder<List<double>>(
          stream: _fs.getDailyLogs(30).map((logs) => logs.reversed.map((l) => l.whSaved).toList()),
          builder: (context, snap) {
            final hasError = snap.hasError;
            final hasData = snap.hasData;
            final dailyVals = snap.data ?? [];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  FadeSlide(index: 0, child: const SectionHeader(title: 'MONTHLY TARGETS')),
                  FadeSlide(index: 1, child: hasError
                    ? const ErrorBanner(message: 'Targets unavailable')
                    : const MonthlyTargets(co2Percent: 50, energyPercent: 30)),
                  const SizedBox(height: 24),
                  FadeSlide(index: 2, child: const SectionHeader(title: 'CONSUMPTION TREND — 30 DAYS')),
                  FadeSlide(index: 3, child: hasError
                    ? const ErrorBanner(message: 'Trend data unavailable')
                    : !hasData
                      ? const ShimmerBlock(height: 120)
                      : TrendLineChart(
                          values: dailyVals.isNotEmpty ? dailyVals
                            : [0.02, 0.015, 0.03, 0.01, 0.025, 0.018, 0.022, 0.019, 0.027, 0.014])),
                  const SizedBox(height: 24),
                  FadeSlide(index: 4, child: const SectionHeader(title: 'ALL-TIME')),
                  FadeSlide(index: 5, child: hasError
                    ? const ErrorBanner(message: 'Summary unavailable')
                    : const AlltimeSummary(sessions: 24, hoursSaved: 3.2, co2Grams: 1630)),
                  const SizedBox(height: 24),
                  FadeSlide(index: 6, child: const SectionHeader(title: 'BEST DAY')),
                  FadeSlide(index: 7, child: hasError
                    ? const ErrorBanner(message: 'Best day data unavailable')
                    : const BestDayCard(date: 'Jun 12, 2026', subtitle: '0.045 Wh saved \u2014 38.25 mg CO\u2082')),
                  const SizedBox(height: 24),
                  FadeSlide(index: 8, child: const SectionHeader(title: 'EMISSION FACTOR')),
                  FadeSlide(index: 9, child: hasError
                    ? const ErrorBanner(message: 'Emission data unavailable')
                    : Column(children: const [
                        EmissionFactorTile(label: 'Grid intensity', value: '850 g CO\u2082/kWh'),
                        SizedBox(height: 8),
                        EmissionFactorTile(label: 'Source', value: 'Indonesia (IPCC 2026)'),
                      ])),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
