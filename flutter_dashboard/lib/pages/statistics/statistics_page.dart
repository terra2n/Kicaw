import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_header.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Text('June 2025', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const SectionHeader(title: 'MONTHLY TARGETS'),
              _placeholder(Icons.flag_outlined, 'Monthly Targets', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: '30-DAY TREND'),
              _placeholder(Icons.show_chart, 'Trend Line Chart', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'ALL TIME SUMMARY'),
              _placeholder(Icons.grid_view, 'Summary Grid', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'BEST DAY'),
              _placeholder(Icons.star_outline, 'Best Day Card', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'EMISSION FACTOR'),
              _placeholder(Icons.electric_bolt, 'Emission Factor', 'Coming soon in Patch 3'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
