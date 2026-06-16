import 'package:flutter/material.dart';
import '../../../models/radar_config.dart';
import '../../../theme/app_colors.dart';

class GateSensitivityCard extends StatefulWidget {
  final GateSensitivity gate;
  final bool expanded;
  final Function(int moving, int stationary)? onApply;

  const GateSensitivityCard({
    super.key,
    required this.gate,
    this.expanded = false,
    this.onApply,
  });

  @override
  State<GateSensitivityCard> createState() => _GateSensitivityCardState();
}

class _GateSensitivityCardState extends State<GateSensitivityCard> {
  late double _moving;
  late double _stationary;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _moving = widget.gate.moving.toDouble();
    _stationary = widget.gate.stationary.toDouble();
    _isExpanded = widget.expanded;
  }

  @override
  void didUpdateWidget(GateSensitivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gate != widget.gate) {
      _moving = widget.gate.moving.toDouble();
      _stationary = widget.gate.stationary.toDouble();
    }
  }

  double get rangeMin => widget.gate.gate * 0.75;
  double get rangeMax => (widget.gate.gate + 1) * 0.75;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChanges = _moving.toInt() != widget.gate.moving ||
        _stationary.toInt() != widget.gate.stationary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _gateBadge(theme),
                  const SizedBox(width: 12),
                  Expanded(child: _gateLabel(theme)),
                  _energyBar(widget.gate.moving, AppColors.primary),
                  const SizedBox(width: 4),
                  _energyBar(widget.gate.stationary, Colors.orangeAccent),
                  const SizedBox(width: 8),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.textTheme.bodySmall?.color),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _slider(theme, 'Moving', _moving, AppColors.primary, (v) {
                    setState(() => _moving = v);
                  }),
                  const SizedBox(height: 4),
                  _slider(theme, 'Stationary', _stationary,
                      Colors.orangeAccent, (v) {
                    setState(() => _stationary = v);
                  }),
                  if (hasChanges) ...[n                    const SizedBox(height: 12),n                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => widget.onApply
                            ?.call(_moving.toInt(), _stationary.toInt()),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          'Apply M${_moving.toInt()} S${_stationary.toInt()}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _gateBadge(ThemeData theme) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text('G${widget.gate.gate}',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
      ),
    );
  }

  Widget _gateLabel(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gate ${widget.gate.gate}', style: theme.textTheme.titleSmall),
        Text('${rangeMin.toStringAsFixed(0)}-${rangeMax.toStringAsFixed(0)}m',
            style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _energyBar(int value, Color color) {
    return Container(
      width: 32, height: 6,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (value / 100.0).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _slider(ThemeData theme, String label, double value,
      Color color, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withOpacity(0.12),
              inactiveTrackColor: color.withOpacity(0.15),
            ),
            child: Slider(
              value: value,
              min: 0, max: 100,
              divisions: 100,
              label: '${value.toInt()}',
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text('${value.toInt()}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              )),
        ),
      ],
    );
  }
}
