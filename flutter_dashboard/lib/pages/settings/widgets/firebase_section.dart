import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';
import '../../../widgets/status_chip.dart';
import '../../../services/realtime_service.dart';

class FirebaseSection extends StatefulWidget {
  const FirebaseSection({super.key});

  @override
  State<FirebaseSection> createState() => _FirebaseSectionState();
}

class _FirebaseSectionState extends State<FirebaseSection> {
  final RealtimeService _rtdb = RealtimeService();

  @override
  void dispose() {
    _rtdb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Firebase Connection', style: TextStyle(fontSize: 13, color: context.textPrimary)),
                const SizedBox(height: 4),
                Text('RTDB + Firestore', style: TextStyle(fontSize: 11, color: context.textSecondary)),
              ],
            ),
          ),
          StreamBuilder<bool>(
            stream: _rtdb.onlineStream,
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? false;
              return StatusChip(
                active: isOnline,
                activeLabel: 'Connected',
                inactiveLabel: 'Disconnected',
              );
            },
          ),
        ],
      ),
    );
  }
}
