import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final bool active;
  final String activeLabel;
  final String inactiveLabel;

  const StatusChip({
    super.key,
    required this.active,
    this.activeLabel = 'ON',
    this.inactiveLabel = 'OFF',
  });

  @override
  Widget build(BuildContext context) {
    final isOn = active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOn ? AppColors.statusOccupied : AppColors.statusEmpty,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? AppColors.dotGreen : AppColors.dotGray,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isOn ? activeLabel : inactiveLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isOn ? AppColors.dotGreen : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
