import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../services/firestore_service.dart';
import '../../models/daily_log.dart';
import '../../widgets/fade_slide.dart';
import '../../widgets/loading_shimmer.dart';
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
  final FirestoreService _fs = FirestoreService();

  Future<void> _onRefresh() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carbon')),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: StreamBuilder<List<DailyLog>>(
          stream: _fs.getDailyLogs(30),
          builder: (context, snap) {
            final hasError = snap.hasError;
            final hasData = snap.hasData;
            final logs = snap.data ?? [];
            final totalCo2Mg = logs.fold<double>(0, (sum, l) => sum + l.co2Mg);
            final co2Values = logs.reversed.map((l) => l.co2Mg).toList();
            final avgDailyMg = logs.isNotEmpty ? totalCo2Mg / logs.length : 0.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const FadeSlide(index: 0, child: SectionHeader(title: 'THIS MONTH')),
                  FadeSlide(index: 1, child: hasError
                    ? const ErrorBanner(message: 'Carbon data unavailable')
                    : !hasData
                      ? const ShimmerBlock(height: 140)
                      : TotalCo2Hero(co2Mg: totalCo2Mg)),
                  const SizedBox(height: 24),
                  const FadeSlide(index: 2, child: SectionHeader(title: 'REAL-WORLD EQUIVALENTS')),
                  FadeSlide(index: 3, child: hasError
                    ? const ErrorBanner(message: 'Equivalents unavailable')
                    : RealWorldEquivalents(co2Grams: totalCo2Mg / 1000)),
                  const SizedBox(height: 24),
                  const FadeSlide(index: 4, child: SectionHeader(title: 'CO\u2082 PER DAY — LAST 30 DAYS')),
                  FadeSlide(index: 5, child: hasError
                    ? const ErrorBanner(message: 'Chart unavailable')
                    : !hasData
                      ? const ShimmerBlock(height: 140)
                      : co2Values.isEmpty
                        ? const EmptyState(icon: Icons.eco, title: 'No CO\u2082 data yet')
                        : DailyCo2Chart(co2MgValues: co2Values)),
                  const SizedBox(height: 24),
                  const FadeSlide(index: 6, child: SectionHeader(title: 'DETAILS')),
                  FadeSlide(index: 7, child: hasError
                    ? const ErrorBanner(message: 'Details unavailable')
                    : Column(children: [
                        EmissionInfo(label: 'Average daily', value: '${avgDailyMg.toStringAsFixed(1)} mg'),
                        const SizedBox(height: 8),
                        const EmissionInfo(label: 'Grid factor', value: '850 g CO\u2082/kWh'),
                        const SizedBox(height: 8),
                        EmissionInfo(label: 'Total this month', value: '${(totalCo2Mg / 1000).toStringAsFixed(2)} g'),
                        const SizedBox(height: 8),
                        EmissionInfo(label: 'Lamp avoided', value: '${logs.length} on/off cycles'),
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
