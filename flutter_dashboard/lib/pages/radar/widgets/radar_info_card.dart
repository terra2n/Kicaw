import 'package:flutter/material.dart';
import '../../../models/radar_config.dart';
import '../../../theme/app_colors.dart';

class RadarInfoCard extends StatelessWidget {
  final RadarConfig config;
  final VoidCallback onReadConfig;
  final VoidCallback onReadFirmware;
  final bool isLoading;

  const RadarInfoCard({
    super.key,
    required this.config,
    required this.onReadConfig,
    required this.onReadFirmware,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.radar, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HLK-LD2410C', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('24GHz FMCW Radar', style: theme.textTheme.bodySmall),
                  ],
                ),
                const Spacer(),
                if (isLoading)
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow(theme, 'Firmware', config.firmwareVersion),
            _infoRow(theme, 'Max Moving Gate', config.maxMovingGate.toString()),
            _infoRow(theme, 'Max Stationary Gate', config.maxStationaryGate.toString()),
            _infoRow(theme, 'Inactivity Timeout', '${config.inactivityTimeout}s'),
            if (config.gates.isNotEmpty)
              _infoRow(theme, 'Active Gates', '${config.gates.length} gate(s)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onReadConfig,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Read Config'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : onReadFirmware,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Firmware'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            )),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
