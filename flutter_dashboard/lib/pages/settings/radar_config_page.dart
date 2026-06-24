import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/context_ext.dart';

class RadarConfigPage extends StatelessWidget {
  const RadarConfigPage({super.key});

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.hlk.hlkradartool';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfigurasi Radar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 24),
              _infoCard(context),
              const SizedBox(height: 24),
              _playStoreCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.radar, size: 40, color: context.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HLK-LD2410C',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '24GHz mmWave Radar Presence Sensor',
                style: TextStyle(fontSize: 13, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfigurasi Radar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Konfigurasi parameter radar (jarak deteksi, sensitivitas gate, '
            'dll.) dilakukan melalui aplikasi HLKRadarTool dari Play Store.',
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 12),
          _infoRow(context, Icons.info_outline, 'Default BLE password: HiLink'),
          const SizedBox(height: 4),
          _infoRow(
            context,
            Icons.bluetooth_disabled,
            'BLE hanya aktif saat radar tidak terhubung ke ESP32',
          ),
          const SizedBox(height: 4),
          _infoRow(
            context,
            Icons.sensors,
            'Deteksi keberadaan otomatis berjalan lewat GPIO OUT (digital)',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: context.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playStoreCard(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => launchUrl(Uri.parse(_playStoreUrl),
            mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Buka di Play Store'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
