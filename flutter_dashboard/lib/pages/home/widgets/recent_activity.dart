import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ActivityItem {
  final String event;
  final String type;
  final double whSaved;
  final double co2Mg;
  final DateTime timestamp;

  const ActivityItem({
    required this.event,
    required this.type,
    required this.whSaved,
    required this.co2Mg,
    required this.timestamp,
  });
}

class RecentActivity extends StatelessWidget {
  final List<ActivityItem> items;

  const RecentActivity({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLightOn = item.type == 'on';
          final dotColor = isLightOn ? AppColors.dotGreen : AppColors.dotGray;
          return Column(
            children: [
              if (i > 0) const Divider(height: 0.5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.event,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                          if (item.whSaved > 0)
                            Text(
                              'saved ${item.whSaved.toStringAsFixed(3)} Wh · ${item.co2Mg.toStringAsFixed(1)} mg CO\u2082',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
