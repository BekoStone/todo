import 'package:flutter/material.dart';

class AnimatedCounter extends ImplicitlyAnimatedWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    Duration duration = const Duration(milliseconds: 250),
  }) : super(duration: duration);

  @override
  AnimatedWidgetBaseState<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends AnimatedWidgetBaseState<AnimatedCounter> {
  IntTween? _tween;

  @override
  Widget build(BuildContext context) {
    _tween ??= IntTween(begin: widget.value, end: widget.value);
    return Text(_tween!.evaluate(animation).toString(), style: widget.style);
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _tween = visitor(_tween, widget.value, (dynamic value) => IntTween(begin: value as int)) as IntTween?;
  }
}
