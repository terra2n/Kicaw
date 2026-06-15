import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/section_header.dart';
import '../../services/settings_service.dart';

class HomePage extends StatelessWidget {
  final SettingsService settingsService;

  const HomePage({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Room'),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.dotGreen,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'ESP32 Online',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () {},
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
              const SectionHeader(title: 'ROOM STATUS'),
              _buildPlaceholderCard(Icons.meeting_room_outlined, 'Home Dashboard', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'ENERGY AUDIT — TODAY'),
              _buildPlaceholderCard(Icons.bolt_outlined, 'Energy Grid 2×2', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'LAST 7 DAYS'),
              _buildPlaceholderCard(Icons.bar_chart_outlined, 'Weekly Chart', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              const SectionHeader(title: 'RECENT ACTIVITY'),
              _buildPlaceholderCard(Icons.history, 'Activity Log', 'Coming soon in Patch 3'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(IconData icon, String title, String subtitle) {
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
