import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AlltimeSummary extends StatelessWidget {
  final int sessions;
  final double hoursSaved;
  final double co2Grams;

  const AlltimeSummary({super.key, required this.sessions, required this.hoursSaved, required this.co2Grams});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _box('${sessions}', 'sessions'),
        const SizedBox(width: 12),
        _box(hoursSaved.toStringAsFixed(1), 'hrs saved'),
        const SizedBox(width: 12),
        _box('${co2Grams.toStringAsFixed(1)} g', 'CO\u2082 cut'),
      ],
    );
  }

  Widget _box(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
