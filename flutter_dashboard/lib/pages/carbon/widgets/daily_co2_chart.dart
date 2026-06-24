import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/context_ext.dart';

class DailyCo2Chart extends StatelessWidget {
  final List<double> co2GramsValues;

  const DailyCo2Chart({super.key, required this.co2GramsValues});

  @override
  Widget build(BuildContext context) {
    if (co2GramsValues.isEmpty) return const SizedBox(height: 120);
    final maxVal = co2GramsValues.reduce((a, b) => a > b ? a : b).clamp(0.001, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: SizedBox(
        height: 120,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.3,
            barTouchData: BarTouchData(enabled: false),
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(co2GramsValues.length, (i) {
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: co2GramsValues[i].clamp(0.001, double.infinity),
                  color: Colors.green,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
