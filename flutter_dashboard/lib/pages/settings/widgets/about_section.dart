import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        children: [
          _tile(context, 'Version', '1.0.0'),
          const Divider(height: 0.5),
          _tile(context, 'Platform', 'Flutter'),
          const Divider(height: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text('Team', style: TextStyle(fontSize: 13, color: context.textPrimary)),
                const Spacer(),
                Text('KICAW', style: TextStyle(fontSize: 13, color: context.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: context.textPrimary)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, color: context.textSecondary)),
        ],
      ),
    );
  }
}
