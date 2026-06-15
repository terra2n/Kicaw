import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../services/settings_service.dart';

class NotificationSection extends StatefulWidget {
  final SettingsService service;

  const NotificationSection({super.key, required this.service});

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  bool _pushEnabled = true;
  bool _localEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.service;
    _pushEnabled = await s.getBool('push_notif', true);
    _localEnabled = await s.getBool('local_notif', true);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _tile('Push notifications', _pushEnabled, (v) async {
            await widget.service.setBool('push_notif', v);
            setState(() => _pushEnabled = v);
          }),
          const Divider(height: 0.5),
          _tile('Local notifications', _localEnabled, (v) async {
            await widget.service.setBool('local_notif', v);
            setState(() => _localEnabled = v);
          }),
        ],
      ),
    );
  }

  Widget _tile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          const Spacer(),
          SizedBox(
            height: 28,
              child: Switch.adaptive(
              value: value,
              activeTrackColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
