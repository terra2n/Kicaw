import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';

class BestDayCard extends StatelessWidget {
  final String date;
  final String subtitle;

  const BestDayCard({super.key, required this.date, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: context.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Best', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.primary)),
          ),
        ],
      ),
    );
  }
}
