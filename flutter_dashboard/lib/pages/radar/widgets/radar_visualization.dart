import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// A visual representation of radar detection zones
/// Shows moving and stationary sensitivity per gate as concentric arcs
class RadarVisualization extends StatelessWidget {
  final List<int> movingSensitivity; // 0-100 per gate
  final List<int> stationarySensitivity; // 0-100 per gate
  final int maxMovingGate;
  final int maxStationaryGate;
  final String activeTab; // 'moving', 'stationary', or 'all'

  const RadarVisualization({
    super.key,
    required this.movingSensitivity,
    required this.stationarySensitivity,
    required this.maxMovingGate,
    required this.maxStationaryGate,
    this.activeTab = 'all',
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: CustomPaint(
        painter: _RadarPainter(
          movingSensitivity: movingSensitivity,
          stationarySensitivity: stationarySensitivity,
          maxMovingGate: maxMovingGate,
          maxStationaryGate: maxStationaryGate,
          activeTab: activeTab,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<int> movingSensitivity;
  final List<int> stationarySensitivity;
  final int maxMovingGate;
  final int maxStationaryGate;
  final String activeTab;

  _RadarPainter({
    required this.movingSensitivity,
    required this.stationarySensitivity,
    required this.maxMovingGate,
    required this.maxStationaryGate,
    required this.activeTab,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final maxRadius = size.height * 0.75;
    final gateWidth = maxRadius / 9;

    // Draw background grid arcs
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 9; i++) {
      final radius = gateWidth * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 * 0.85,
        3.14159 * 0.7,
        false,
        gridPaint,
      );
    }

    // Draw radial lines
    for (int i = 0; i <= 6; i++) {
      final angle = -3.14159 * 0.85 + (3.14159 * 0.7 * i / 6);
      final endPoint = Offset(
        center.dx + maxRadius * 0.95 * (angle.cos()),
        center.dy + maxRadius * 0.95 * (angle.sin()),
      );
      canvas.drawLine(center, endPoint, gridPaint);
    }

    // Draw stationary zones (orange, outer)
    if (activeTab == 'stationary' || activeTab == 'all') {
      final showCount = activeTab == 'stationary'
          ? maxStationaryGate + 1
          : maxStationaryGate + 1;

      for (int gate = 0; gate < showCount && gate < stationarySensitivity.length; gate++) {
        final sens = stationarySensitivity[gate] / 100.0;
        if (sens <= 0) continue;

        final outerR = gateWidth * (gate + 1);

        final paint = Paint()
          ..color = Colors.orangeAccent.withOpacity(0.15 + sens * 0.35)
          ..style = PaintingStyle.fill;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerR),
          -3.14159 * 0.85,
          3.14159 * 0.7,
          false,
          paint,
        );

        // Draw border for active gates
        final borderPaint = Paint()
          ..color = Colors.orangeAccent.withOpacity(0.5 + sens * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerR),
          -3.14159 * 0.85,
          3.14159 * 0.7,
          false,
          borderPaint,
        );
      }
    }

    // Draw moving zones (blue, inner)
    if (activeTab == 'moving' || activeTab == 'all') {
      final showCount = activeTab == 'moving'
          ? maxMovingGate + 1
          : maxMovingGate + 1;

      for (int gate = 0; gate < showCount && gate < movingSensitivity.length; gate++) {
        final sens = movingSensitivity[gate] / 100.0;
        if (sens <= 0) continue;

        final outerR = gateWidth * (gate + 1);

        final paint = Paint()
          ..color = AppColors.primary.withOpacity(0.15 + sens * 0.35)
          ..style = PaintingStyle.fill;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerR),
          -3.14159 * 0.85,
          3.14159 * 0.7,
          false,
          paint,
        );

        final borderPaint = Paint()
          ..color = AppColors.primary.withOpacity(0.5 + sens * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerR),
          -3.14159 * 0.85,
          3.14159 * 0.7,
          false,
          borderPaint,
        );
      }
    }

    // Draw center dot (radar position)
    final centerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerPaint);

    // Glow effect
    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, glowPaint);

    // Distance labels
    _drawLabel(canvas, '0.75m', Offset(center.dx, center.dy - gateWidth * 1 - 4), 9);
    _drawLabel(canvas, '2.25m', Offset(center.dx, center.dy - gateWidth * 3 - 4), 9);
    _drawLabel(canvas, '4.5m', Offset(center.dx, center.dy - gateWidth * 6 - 4), 9);
    _drawLabel(canvas, '6.75m', Offset(center.dx, center.dy - gateWidth * 9 - 4), 9);

    // Gate labels along bottom
    for (int i = 0; i <= 8; i++) {
      final label = 'G$i';
      final x = center.dx - maxRadius * 0.8 + (i * maxRadius * 1.6 / 8);
      _drawLabel(canvas, label, Offset(x, center.dy + 16), 8, Colors.grey);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset position, double fontSize,
      [Color? color]) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? Colors.white70,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.movingSensitivity != movingSensitivity ||
        oldDelegate.stationarySensitivity != stationarySensitivity ||
        oldDelegate.activeTab != activeTab ||
        oldDelegate.maxMovingGate != maxMovingGate ||
        oldDelegate.maxStationaryGate != maxStationaryGate;
  }
}

extension on double {
  double cos() => _cos(this);
  double sin() => _sin(this);
}

double _cos(double x) {
  // Taylor approximation for performance
  x = x % (2 * 3.14159265);
  double result = 1;
  double term = 1;
  for (int i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}

double _sin(double x) {
  x = x % (2 * 3.14159265);
  double result = x;
  double term = x;
  for (int i = 1; i <= 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}
