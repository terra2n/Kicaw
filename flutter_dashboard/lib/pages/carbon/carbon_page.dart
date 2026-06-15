import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_header.dart';

class CarbonPage extends StatelessWidget {
  const CarbonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carbon footprint'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(color: AppColors.border, height: 0.5),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const SectionHeader(title: 'TOTAL CO\u2082 PREVENTED'),
              _placeholder(Icons.eco, 'CO\u2082 Hero Card', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'REAL-WORLD EQUIVALENTS'),
              _placeholder(Icons.nature, 'Tree / Car / Phone', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'DAILY CO\u2082 REDUCTION'),
              _placeholder(Icons.bar_chart, 'Horizontal Bar Chart', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'EMISSION INFO'),
              _placeholder(Icons.info_outline, 'Emission Info', 'Coming soon in Patch 3'),
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
