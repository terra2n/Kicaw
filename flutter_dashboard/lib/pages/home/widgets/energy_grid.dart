import 'package:flutter/material.dart';
import '../../../widgets/metric_card.dart';

class EnergyGrid extends StatelessWidget {
  final double whSaved;
  final double co2Mg;
  final int minutesOff;
  final double lampPowerW;

  const EnergyGrid({
    super.key,
    required this.whSaved,
    required this.co2Mg,
    required this.minutesOff,
    required this.lampPowerW,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        MetricCard(
          icon: Icons.bolt,
          iconColor: const Color(0xFFF59E0B),
          value: whSaved.toStringAsFixed(3),
          unit: 'Wh',
          label: 'Wh saved',
        ),
        MetricCard(
          icon: Icons.eco,
          iconColor: const Color(0xFF10B981),
          value: co2Mg.toStringAsFixed(1),
          unit: 'mg',
          label: 'CO\u2082 reduced',
        ),
        MetricCard(
          icon: Icons.timer_outlined,
          iconColor: const Color(0xFF3B82F6),
          value: minutesOff.toString(),
          unit: 'min',
          label: 'light off',
        ),
        MetricCard(
          icon: Icons.whatshot,
          iconColor: const Color(0xFFF97316),
          value: lampPowerW.toStringAsFixed(0),
          unit: 'W',
          label: 'lamp power',
        ),
      ],
    );
  }
}
