import 'package:flutter/material.dart';
import '../../../../core/utils/byte_formatter.dart';

/// An animated text widget that smoothly counts up or down to a target numeric value.
class CountUpText extends ImplicitlyAnimatedWidget {
  final double value;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String Function(double value)? formatter;

  const CountUpText({
    super.key,
    required this.value,
    this.style,
    this.textAlign,
    this.formatter,
    super.duration = const Duration(milliseconds: 650),
    super.curve = Curves.easeOutCubic,
  });

  /// Factory for formatting byte counts (e.g. "1.45 GB") smoothly.
  factory CountUpText.bytes({
    Key? key,
    required int bytes,
    TextStyle? style,
    TextAlign? textAlign,
    Duration duration = const Duration(milliseconds: 650),
    Curve curve = Curves.easeOutCubic,
    int decimals = 2,
  }) {
    return CountUpText(
      key: key,
      value: bytes.toDouble(),
      style: style,
      textAlign: textAlign,
      duration: duration,
      curve: curve,
      formatter: (val) => ByteFormatter.format(val.round(), decimals: decimals),
    );
  }

  /// Factory for formatting speed rates (e.g. "2.4 MB/s") smoothly.
  factory CountUpText.speed({
    Key? key,
    required int bytesPerSecond,
    TextStyle? style,
    TextAlign? textAlign,
    bool useBits = false,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    int decimals = 1,
  }) {
    return CountUpText(
      key: key,
      value: bytesPerSecond.toDouble(),
      style: style,
      textAlign: textAlign,
      duration: duration,
      curve: curve,
      formatter: (val) => ByteFormatter.formatSpeed(
        val.round(),
        useBits: useBits,
        decimals: decimals,
      ),
    );
  }

  @override
  ImplicitlyAnimatedWidgetState<CountUpText> createState() =>
      _CountUpTextState();
}

class _CountUpTextState extends AnimatedWidgetBaseState<CountUpText> {
  Tween<double>? _valueTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _valueTween = visitor(
      _valueTween,
      widget.value,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = _valueTween?.evaluate(animation) ?? widget.value;
    final text = widget.formatter != null
        ? widget.formatter!(currentValue)
        : currentValue.toStringAsFixed(0);

    return Text(
      text,
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }
}
