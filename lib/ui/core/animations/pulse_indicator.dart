import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A pulsing halo indicator for live network speed and throughput activity.
/// Encapsulated inside a [RepaintBoundary] to isolate animations from parent layout passes.
class PulseIndicator extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;

  const PulseIndicator({
    super.key,
    this.isActive = true,
    this.color = AppColors.wifi,
    this.size = 12.0,
  });

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * 2.4,
        height: widget.size * 2.4,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isActive)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(alpha: _opacityAnimation.value),
                        ),
                      ),
                    );
                  },
                ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive ? widget.color : widget.color.withValues(alpha: 0.4),
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 4.0,
                            spreadRadius: 1.0,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
