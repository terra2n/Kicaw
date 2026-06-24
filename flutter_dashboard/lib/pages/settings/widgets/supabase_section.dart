import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/context_ext.dart';
import '../../../widgets/status_chip.dart';

class SupabaseSection extends StatefulWidget {
  const SupabaseSection({super.key});

  @override
  State<SupabaseSection> createState() => _SupabaseSectionState();
}

class _SupabaseSectionState extends State<SupabaseSection> {
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() {
    try {
      Supabase.instance.client;
      _isOnline = true;
    } catch (_) {
      _isOnline = false;
    }
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
                Text('Supabase Connection', style: TextStyle(fontSize: 13, color: context.textPrimary)),
                const SizedBox(height: 4),
                Text('PostgreSQL + Realtime', style: TextStyle(fontSize: 11, color: context.textSecondary)),
              ],
            ),
          ),
          StatusChip(
            active: _isOnline,
            activeLabel: 'Connected',
            inactiveLabel: 'Disconnected',
          ),
        ],
      ),
    );
  }
}
