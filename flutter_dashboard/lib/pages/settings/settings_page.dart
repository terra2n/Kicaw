import 'package:flutter/material.dart';
import '../../widgets/section_header.dart';
import '../../services/settings_service.dart';
import 'widgets/device_section.dart';
import 'widgets/automation_section.dart';
import 'widgets/notification_section.dart';
import 'widgets/firebase_section.dart';
import 'widgets/about_section.dart';

class SettingsPage extends StatelessWidget {
  final SettingsService service;

  const SettingsPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const SectionHeader(title: 'DEVICE'),
              const DeviceSection(),
              const SizedBox(height: 24),
              const SectionHeader(title: 'AUTOMATION'),
              AutomationSection(service: service),
              const SizedBox(height: 24),
              const SectionHeader(title: 'NOTIFICATIONS'),
              NotificationSection(service: service),
              const SizedBox(height: 24),
              const SectionHeader(title: 'FIREBASE'),
              const FirebaseSection(),
              const SizedBox(height: 24),
              const SectionHeader(title: 'ABOUT'),
              const AboutSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
