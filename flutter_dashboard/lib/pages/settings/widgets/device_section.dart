import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class DeviceSection extends StatelessWidget {
  const DeviceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ESP32-C3 · HLK-LD2410C', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _row('RTDB', 'kicaw-smart-room'),
          _row('Room ID', 'ruangan_01'),
          _row('Sensor', 'HLK-LD2410C (Gate0 <75cm)'),
          _row('Timeout', '1 second'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
