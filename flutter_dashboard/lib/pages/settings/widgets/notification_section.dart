import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';
import '../../../services/notification_service.dart';

class NotificationSection extends StatefulWidget {
  final NotificationService notifService;

  const NotificationSection({super.key, required this.notifService});

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  bool _pushEnabled = true;
  bool _localEnabled = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(
        children: [
          _tile('Push notifications', _pushEnabled, (v) async {
            await widget.notifService.setPushEnabled(v);
            setState(() => _pushEnabled = v);
          }),
          const Divider(height: 0.5),
          _tile('Local notifications', _localEnabled, (v) async {
            await widget.notifService.setLocalEnabled(v);
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
          Text(label, style: TextStyle(fontSize: 13, color: context.textPrimary)),
          const Spacer(),
          SizedBox(
            height: 28,
              child: Switch.adaptive(
              value: value,
              activeTrackColor: context.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
