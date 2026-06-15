import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  final SettingsService settingsService;

  const SettingsPage({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSectionHeader('DEVICE'),
              _placeholder(Icons.devices, 'Device info', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              _buildSectionHeader('AUTOMATION'),
              _placeholder(Icons.timer_outlined, 'Light timeout, power, toggle', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              _buildSectionHeader('NOTIFICATIONS'),
              _placeholder(Icons.notifications_outlined, 'Toggle switches', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              _buildSectionHeader('FIREBASE'),
              _placeholder(Icons.cloud_outlined, 'Connection status', 'Coming soon in Patch 3'),
              const SizedBox(height: 24),
              _buildSectionHeader('ABOUT'),
              _placeholder(Icons.info_outline, 'App version, team, platform', 'Coming soon in Patch 3'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
          color: AppColors.textSecondary,
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
