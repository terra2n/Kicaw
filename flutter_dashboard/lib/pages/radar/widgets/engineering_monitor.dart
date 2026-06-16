import 'package:flutter/material.dart';
import '../../../models/radar_config.dart';
import '../../../theme/app_colors.dart';

class EngineeringMonitor extends StatelessWidget {
  final EngineeringData data;
  final bool isActive;

  const EngineeringMonitor({
    super.key,
    required this.data,
    this.isActive = false,
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
                Icon(Icons.monitor_heart_outlined,
                    color: isActive ? AppColors.primary : Colors.grey,
                    size: 20),
                const SizedBox(width: 8),
                Text('Engineering Monitor',
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'LIVE' : 'OFF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              if (data.presenceDistanceCm > 0)
                _distanceRow(theme, 'Presence', data.presenceDistanceCm, AppColors.primary),
              if (data.movingDistanceCm > 0)
                _distanceRow(theme, 'Moving', data.movingDistanceCm, AppColors.primary),
              if (data.stationaryDistanceCm > 0)
                _distanceRow(theme, 'Stationary', data.stationaryDistanceCm, Colors.orangeAccent),
              const SizedBox(height: 16),
              const Text('Energy per Gate', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              for (int g = 0; g < 9; g++)
                _gateEnergyRow(theme, g, data.movingEnergy[g], data.stationaryEnergy[g]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _distanceRow(ThemeData theme, String label, int cm, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Text('$cm cm', style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          )),
        ],
      ),
    );
  }

  Widget _gateEnergyRow(ThemeData theme, int gate, int moving, int stationary) {
    if (moving == 0 && stationary == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('G$gate', style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 16,
                color: AppColors.primary.withOpacity(0.1),
                child: Row(
                  children: [
                    FractionallySizedBox(
                      widthFactor: moving / 100.0,
                      heightFactor: 1,
                      child: Container(color: AppColors.primary.withOpacity(0.6)),
                    ),
                    FractionallySizedBox(
                      widthFactor: stationary / 100.0,
                      heightFactor: 1,
                      child: Container(color: Colors.orangeAccent.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text('M${moving.toString().padLeft(2)}',
                style: TextStyle(fontSize: 10, color: AppColors.primary)),
          ),
          SizedBox(
            width: 40,
            child: Text('S${stationary.toString().padLeft(2)}',
                style: TextStyle(fontSize: 10, color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }
}
