import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/status_chip.dart';

class FirebaseSection extends StatelessWidget {
  const FirebaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Firebase Connection', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('RTDB + Firestore', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const StatusChip(active: true, activeLabel: 'Connected', inactiveLabel: 'Disconnected'),
        ],
      ),
    );
  }
}
