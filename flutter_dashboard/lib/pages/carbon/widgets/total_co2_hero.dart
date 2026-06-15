import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class TotalCo2Hero extends StatelessWidget {
  final double co2Mg;

  const TotalCo2Hero({super.key, required this.co2Mg});

  @override
  Widget build(BuildContext context) {
    final g = co2Mg / 1000;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_outlined, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            '${g.toStringAsFixed(2)} g',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'CO\u2082 prevented this month',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
