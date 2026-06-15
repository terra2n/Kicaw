import 'package:flutter/material.dart';
import '../theme/context_ext.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'No data yet',
    this.subtitle = 'Data will appear here once available',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 40, color: context.textTertiary),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: context.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, color: context.textSecondary)),
        ],
      ),
    );
  }
}
