import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A custom-painted circular radial gauge displaying quota consumption percentage.
class RadialGauge extends StatelessWidget {
  final double percent; // 0.0 to 1.0+
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? trackColor;
  final Widget? child;
  final Duration animationDuration;

  const RadialGauge({
    super.key,
    required this.percent,
    this.size = 180.0,
    this.strokeWidth = 14.0,
    this.progressColor,
    this.trackColor,
    this.child,
    this.animationDuration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTrackColor = trackColor ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final clampedPercent = percent.clamp(0.0, 1.0);
    final statusColor = progressColor ??
        AppColors.statusForUsagePercent(clampedPercent * 100);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: clampedPercent),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedPercent, _) {
        return CustomPaint(
          size: Size(size, size),
          painter: _RadialGaugePainter(
            percent: animatedPercent,
            strokeWidth: strokeWidth,
            trackColor: effectiveTrackColor,
            progressColor: statusColor,
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _RadialGaugePainter({
    required this.percent,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  // 240 degree arc from 150 deg (5pi/6) to 390 deg (13pi/6)
  static const double _startAngle = 150 * (math.pi / 180);
  static const double _sweepAngleTotal = 240 * (math.pi / 180);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngleTotal,
      false,
      trackPaint,
    );

    // Progress arc
    if (percent > 0.0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final currentSweep = _sweepAngleTotal * percent.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        currentSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
