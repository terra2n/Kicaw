import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _tile('Version', '1.0.0'),
          const Divider(height: 0.5),
          _tile('Platform', 'Flutter'),
          const Divider(height: 0.5),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text('Team', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                Spacer(),
                Text('KICAW', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
