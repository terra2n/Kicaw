import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/context_ext.dart';

class TrendLineChart extends StatelessWidget {
  final List<double> values;

  const TrendLineChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox(height: 100);
    final maxV = values.reduce((a, b) => a > b ? a : b).clamp(0.001, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: SizedBox(
        height: 100,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxV * 1.3,
            lineTouchData: const LineTouchData(enabled: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i].clamp(0.001, double.infinity))),
                color: context.primary,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: context.primaryLight.withValues(alpha: 0.4),
                ),
                isCurved: true,
                curveSmoothness: 0.3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
