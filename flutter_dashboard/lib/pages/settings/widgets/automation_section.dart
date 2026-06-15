import 'package:flutter/material.dart';
import '../../../theme/context_ext.dart';
import '../../../services/settings_service.dart';

class AutomationSection extends StatefulWidget {
  final SettingsService service;

  const AutomationSection({super.key, required this.service});

  @override
  State<AutomationSection> createState() => _AutomationSectionState();
}

class _AutomationSectionState extends State<AutomationSection> {
  double _autoOff = 60;
  bool _autoMode = true;
  bool _awayMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = widget.service;
    _autoOff = await s.getDouble('auto_off_sec', 60);
    _autoMode = await s.getBool('auto_mode', true);
    _awayMode = await s.getBool('away_mode', false);
    if (mounted) setState(() {});
  }

  Future<void> _pickSlider() async {
    final result = await showModalBottomSheet<double>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        double val = _autoOff;
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Auto-off timeout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimary)),
                const SizedBox(height: 4),
                Text('${val.toInt()} seconds', style: TextStyle(fontSize: 13, color: context.textSecondary)),
                Slider(
                  value: val,
                  min: 5,
                  max: 300,
                  divisions: 59,
                  activeColor: context.primary,
                  inactiveColor: context.trackBg,
                  label: '${val.toInt()} s',
                  onChanged: (v) => setSheetState(() => val = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx, val),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
    if (result != null) {
      await widget.service.setDouble('auto_off_sec', result);
      setState(() => _autoOff = result);
    }
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
          _tile(context, 'Auto mode', _autoMode, (v) async {
            await widget.service.setBool('auto_mode', v);
            setState(() => _autoMode = v);
          }),
          const Divider(height: 0.5),
          _tile(context, 'Away mode', _awayMode, (v) async {
            await widget.service.setBool('away_mode', v);
            setState(() => _awayMode = v);
          }),
          const Divider(height: 0.5),
          InkWell(
            onTap: _pickSlider,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text('Auto-off timeout', style: TextStyle(fontSize: 13, color: context.textPrimary)),
                  const Spacer(),
                  Text('${_autoOff.toInt()}s', style: TextStyle(fontSize: 13, color: context.textSecondary)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: context.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String label, bool value, ValueChanged<bool> onChanged) {
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
