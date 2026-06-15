import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class MonthlyTargets extends StatelessWidget {
  final double co2Percent;
  final double energyPercent;

  const MonthlyTargets({super.key, required this.co2Percent, required this.energyPercent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _bar('CO\u2082 prevented', co2Percent, AppColors.primary),
          const SizedBox(height: 20),
          _bar('Energy saved', energyPercent, AppColors.blue),
        ],
      ),
    );
  }

  Widget _bar(String label, double percent, Color color) {
    final clamped = percent.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            const Spacer(),
            Text('${clamped.toStringAsFixed(0)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: clamped / 100,
            backgroundColor: AppColors.trackBg,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
