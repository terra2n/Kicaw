import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';

class RealWorldEquivalents extends StatelessWidget {
  final double co2Grams;

  const RealWorldEquivalents({super.key, required this.co2Grams});

  @override
  Widget build(BuildContext context) {
    final bulbHours = co2Grams * 0.85;
    return Row(
      children: [
        _card(context, '💡', '${bulbHours.toStringAsFixed(1)} h', 'LED bulb'),
        const SizedBox(width: 12),
        _card(context, '🌳', (co2Grams * 0.05).toStringAsFixed(2), 'tree-days'),
      ],
    );
  }

  Widget _card(BuildContext context, String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border, width: 0.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimary)),
            Text(label, style: TextStyle(fontSize: 11, color: context.textSecondary)),
          ],
        ),
      ),
    );
  }
}
