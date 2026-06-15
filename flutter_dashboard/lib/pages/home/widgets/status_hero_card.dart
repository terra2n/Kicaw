import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';
import '../../../models/room_status.dart';
import '../../../widgets/status_chip.dart';

class StatusHeroCard extends StatelessWidget {
  final RoomStatus status;
  final DateTime? lastChange;

  const StatusHeroCard({super.key, required this.status, this.lastChange});

  @override
  Widget build(BuildContext context) {
    final occupied = status.isOccupied;
    final bgColor = occupied ? context.statusOccupied : context.statusEmpty;
    final iconColor = occupied ? Colors.amber : context.textTertiary;
    final statusText = occupied ? 'Occupied' : 'Empty';
    final subText = occupied ? 'Radar detecting presence' : 'No motion detected';
    final icon = occupied ? Icons.people_outline : Icons.night_shelter_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600,
              color: occupied ? context.textPrimary : context.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusChip(active: status.lampOn, activeLabel: 'Light ON', inactiveLabel: 'Light OFF'),
              if (lastChange != null) ...[
                const SizedBox(width: 12),
                Text(
                  '${lastChange!.hour.toString().padLeft(2, '0')}:${lastChange!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: context.textTertiary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
