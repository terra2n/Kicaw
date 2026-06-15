import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';

class EmissionFactorTile extends StatelessWidget {
  final String label;
  final String value;

  const EmissionFactorTile({super.key, required this.label, required this.value});

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
          Text(label, style: TextStyle(fontSize: 13, color: context.textSecondary)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
        ],
      ),
    );
  }
}
