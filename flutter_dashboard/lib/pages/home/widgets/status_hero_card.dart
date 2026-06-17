import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';
import '../../../models/supabase/room_status.dart';
import '../../../widgets/status_chip.dart';

class StatusHeroCard extends StatelessWidget {
  final RoomStatus status;
  final DateTime? lastChange;

  const StatusHeroCard({super.key, required this.status, this.lastChange});

  @override
  Widget build(BuildContext context) {
    final online = _isOnline();
    final occupied = status.motionDetected;

    // Offline state
    if (!online) {
      return _buildOfflineCard(context);
    }

    final bgColor = occupied ? context.statusOccupied : context.statusEmpty;
    final iconColor = occupied ? Colors.amber : context.textTertiary;
    final statusText = occupied ? 'Occupied' : 'Empty';
    final subText = occupied
        ? (status.co2Ppm != null
            ? 'Radar detecting — ~${status.co2Ppm} cm'
            : 'Radar detecting presence')
        : 'No motion detected';
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
              StatusChip(active: status.lampStatus, activeLabel: 'Light ON', inactiveLabel: 'Light OFF'),
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

  bool _isOnline() {
    final diff = DateTime.now().difference(status.updatedAt);
    return diff.inSeconds < 15; // Consider online if updated within 15 seconds
  }

  Widget _buildOfflineCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Device Offline',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ESP32 not responding — check power/WiFi',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          Text(
            'Last seen: ${_formatTimeAgo(status.updatedAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
