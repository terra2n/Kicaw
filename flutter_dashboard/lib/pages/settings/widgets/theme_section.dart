import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';

class ThemeSection extends StatelessWidget {
  final VoidCallback onToggle;
  final bool isDark;

  const ThemeSection({super.key, required this.onToggle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20, color: context.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dark mode', style: TextStyle(fontSize: 13, color: context.textPrimary)),
                    Text(
                      isDark ? 'Dark theme active' : 'Light theme active',
                      style: TextStyle(fontSize: 11, color: context.textTertiary),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isDark,
                activeTrackColor: context.primary,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
