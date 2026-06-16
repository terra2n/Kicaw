import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';

class DeviceSection extends StatelessWidget {
  const DeviceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ESP32-C3 · HLK-LD2410C', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.textPrimary)),
          const SizedBox(height: 8),
          _row(context, 'RTDB', 'kicaw-smart-room'),
          _row(context, 'Room ID', 'ruangan_01'),
          _row(context, 'Sensor', 'HLK-LD2410C (Gate0 <75cm)'),
          _row(context, 'Timeout', '1 second'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/radar'),
              icon: const Icon(Icons.radar, size: 18),
              label: const Text('Radar Configuration'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 13, color: context.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, color: context.textPrimary)),
        ],
      ),
    );
  }
}
