import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';

class TotalCo2Hero extends StatelessWidget {
  final double co2Grams;

  const TotalCo2Hero({super.key, required this.co2Grams});

  @override
  Widget build(BuildContext context) {
    final g = co2Grams;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_outlined, size: 36, color: context.textTertiary),
          const SizedBox(height: 12),
          Text(
            '${g.toStringAsFixed(2)} g',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: context.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'CO\u2082 prevented this month',
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
