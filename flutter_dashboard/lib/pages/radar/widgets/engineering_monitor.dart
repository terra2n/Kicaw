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
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
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
              const SizedBox(height: 20),
              Text('Energy per Gate',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color)),
              const SizedBox(height: 12),
              _verticalBarChart(theme),
              const SizedBox(height: 12),
              _legend(theme),
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

  Widget _verticalBarChart(ThemeData theme) {
    const maxBarHeight = 100.0;
    return SizedBox(
      height: maxBarHeight + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(9, (gate) {
          final moving = data.movingEnergy[gate];
          final stationary = data.stationaryEnergy[gate];
          final total = (moving + stationary).clamp(0, 200);
          final movingH = (moving / 100.0) * maxBarHeight;
          final stationaryH = (stationary / 100.0) * maxBarHeight;
          final hasEnergy = total > 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: maxBarHeight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasEnergy) ...[
                          if (stationary > 0)
                            Container(
                              height: stationaryH,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withValues(alpha: 0.7),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3)),
                              ),
                            ),
                          if (moving > 0)
                            Container(
                              height: movingH,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                borderRadius: stationary > 0
                                    ? BorderRadius.zero
                                    : const BorderRadius.vertical(
                                        top: Radius.circular(3)),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('G$gate',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: hasEnergy ? FontWeight.bold : FontWeight.normal,
                        color: hasEnergy ? theme.textTheme.bodyMedium?.color : Colors.grey,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _legend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppColors.primary, 'Moving'),
        const SizedBox(width: 16),
        _legendDot(Colors.orangeAccent, 'Stationary'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
