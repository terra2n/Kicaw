import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../services/firestore_service.dart';
import '../../models/daily_log.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carbon')),
      body: StreamBuilder<List<DailyLog>>(
        stream: _fs.getDailyLogs(30),
        builder: (context, snap) {
          final logs = snap.data ?? [];
          final totalCo2Mg = logs.fold<double>(0, (sum, l) => sum + l.co2Mg);
          final co2Values = logs.reversed.map((l) => l.co2Mg).toList();
          final avgDailyMg = logs.isNotEmpty ? totalCo2Mg / logs.length : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const SectionHeader(title: 'THIS MONTH'),
                TotalCo2Hero(co2Mg: totalCo2Mg),
                const SizedBox(height: 24),
                const SectionHeader(title: 'REAL-WORLD EQUIVALENTS'),
                RealWorldEquivalents(co2Grams: totalCo2Mg / 1000),
                const SizedBox(height: 24),
                const SectionHeader(title: 'CO\u2082 PER DAY — LAST 30 DAYS'),
                DailyCo2Chart(co2MgValues: co2Values.isNotEmpty ? co2Values : [6.8, 5.1, 8.3, 4.2, 7.0]),
                const SizedBox(height: 24),
                const SectionHeader(title: 'DETAILS'),
                EmissionInfo(label: 'Average daily', value: '${avgDailyMg.toStringAsFixed(1)} mg'),
                const SizedBox(height: 8),
                EmissionInfo(label: 'Grid factor', value: '850 g CO\u2082/kWh'),
                const SizedBox(height: 8),
                EmissionInfo(label: 'Total this month', value: '${(totalCo2Mg / 1000).toStringAsFixed(2)} g'),
                const SizedBox(height: 8),
                EmissionInfo(label: 'Lamp avoided', value: '${logs.length} on/off cycles'),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
