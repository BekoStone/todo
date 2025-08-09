import 'package:flutter/material.dart';
import 'dart:math' as math;

/// AnimatedCounter provides smooth number animations for scores and statistics.
/// Optimized for 60 FPS performance with efficient rendering and minimal rebuilds.
/// Supports various animation curves and customizable formatting.
class AnimatedCounter extends StatefulWidget {
  /// The target count to animate to
  final int count;
  
  /// Animation duration
  final Duration duration;
  
  /// Text style for the counter
  final TextStyle? style;
  
  /// Curve for the animation
  final Curve curve;
  
  /// Number formatting function
  final String Function(int)? formatter;
  
  /// Whether to start animation automatically
  final bool autoStart;
  
  /// Callback when animation completes
  final VoidCallback? onAnimationComplete;
  
  /// Decimal places for floating point animation
  final int decimalPlaces;
  
  /// Prefix text
  final String prefix;
  
  /// Suffix text  
  final String suffix;
  
  /// Whether to use comma separators for large numbers
  final bool useCommaSeparator;
  
  /// Animation type
  final CounterAnimationType animationType;

  const AnimatedCounter({
    super.key,
    required this.count,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.curve = Curves.easeOut,
    this.formatter,
    this.autoStart = true,
    this.onAnimationComplete,
    this.decimalPlaces = 0,
    this.prefix = '',
    this.suffix = '',
    this.useCommaSeparator = true,
    this.animationType = CounterAnimationType.smooth,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;
  
  int _previousCount = 0;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    
    if (widget.autoStart) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If count changed, animate to new value
    if (oldWidget.count != widget.count) {
      _previousCount = oldWidget.count;
      _startAnimation();
    }
    
    // If duration changed, update animation
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  void _startAnimation() {
    _hasStarted = true;
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted && widget.autoStart) {
      return _buildText(_previousCount);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _calculateCurrentValue();
        return _buildText(currentValue);
      },
    );
  }

  Widget _buildText(dynamic value) {
    final formattedValue = _formatValue(value);
    final fullText = '${widget.prefix}$formattedValue${widget.suffix}';
    
    return Text(
      fullText,
      style: widget.style,
    );
  }

  dynamic _calculateCurrentValue() {
    switch (widget.animationType) {
      case CounterAnimationType.smooth:
        return _calculateSmoothValue();
      case CounterAnimationType.rolling:
        return _calculateRollingValue();
      case CounterAnimationType.typewriter:
        return _calculateTypewriterValue();
    }
  }

  double _calculateSmoothValue() {
    final start = _previousCount.toDouble();
    final end = widget.count.toDouble();
    return start + (end - start) * _animation.value;
  }

  int _calculateRollingValue() {
    final start = _previousCount;
    final end = widget.count;
    final difference = end - start;
    
    // Create a rolling effect by animating through digits
    final progress = _animation.value;
    final currentStep = (difference * progress).round();
    
    return start + currentStep;
  }

  int _calculateTypewriterValue() {
    final targetString = widget.count.toString();
    final progress = _animation.value;
    final visibleLength = (targetString.length * progress).ceil();
    
    if (visibleLength >= targetString.length) {
      return widget.count;
    }
    
    // Show partial number during typewriter effect
    final partialString = targetString.substring(0, visibleLength);
    return int.tryParse(partialString) ?? 0;
  }

  String _formatValue(dynamic value) {
    if (widget.formatter != null) {
      return widget.formatter!(value is double ? value.round() : value as int);
    }

    if (value is double) {
      if (widget.decimalPlaces > 0) {
        return value.toStringAsFixed(widget.decimalPlaces);
      } else {
        return value.round().toString();
      }
    }

    final intValue = value as int;
    
    if (widget.useCommaSeparator) {
      return _addCommaSeparators(intValue.toString());
    }
    
    return intValue.toString();
  }

  String _addCommaSeparators(String value) {
    final reversed = value.split('').reversed.toList();
    final withCommas = <String>[];
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        withCommas.add(',');
      }
      withCommas.add(reversed[i]);
    }
    
    return withCommas.reversed.join();
  }

  /// Manually start the animation
  void startAnimation() {
    _startAnimation();
  }

  /// Reset the animation to the beginning
  void resetAnimation() {
    _controller.reset();
    _hasStarted = false;
  }

  /// Check if animation is currently running
  bool get isAnimating => _controller.isAnimating;
}

/// Animation type enumeration
enum CounterAnimationType {
  /// Smooth interpolation between values
  smooth,
  
  /// Rolling number effect (digits rolling up/down)
  rolling,
  
  /// Typewriter effect (digits appearing one by one)
  typewriter,
}

/// Specialized animated counter for scores
class AnimatedScoreCounter extends StatelessWidget {
  final int score;
  final Duration duration;
  final TextStyle? style;
  final VoidCallback? onAnimationComplete;

  const AnimatedScoreCounter({
    super.key,
    required this.score,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      count: score,
      duration: duration,
      style: style,
      onAnimationComplete: onAnimationComplete,
      curve: Curves.easeOutCubic,
      useCommaSeparator: true,
      animationType: CounterAnimationType.smooth,
    );
  }
}

/// Specialized animated counter for currencies/coins
class AnimatedCoinCounter extends StatelessWidget {
  final int coins;
  final Duration duration;
  final TextStyle? style;
  final VoidCallback? onAnimationComplete;

  const AnimatedCoinCounter({
    super.key,
    required this.coins,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      count: coins,
      duration: duration,
      style: style,
      onAnimationComplete: onAnimationComplete,
      prefix: '🪙 ',
      curve: Curves.elasticOut,
      useCommaSeparator: true,
      animationType: CounterAnimationType.smooth,
    );
  }
}

/// Specialized animated counter for levels
class AnimatedLevelCounter extends StatelessWidget {
  final int level;
  final Duration duration;
  final TextStyle? style;
  final VoidCallback? onAnimationComplete;

  const AnimatedLevelCounter({
    super.key,
    required this.level,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      count: level,
      duration: duration,
      style: style,
      onAnimationComplete: onAnimationComplete,
      prefix: 'Level ',
      curve: Curves.bounceOut,
      useCommaSeparator: false,
      animationType: CounterAnimationType.rolling,
    );
  }
}

/// Specialized animated counter for statistics
class AnimatedStatCounter extends StatelessWidget {
  final int value;
  final String label;
  final Duration duration;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final VoidCallback? onAnimationComplete;
  final MainAxisAlignment alignment;

  const AnimatedStatCounter({
    super.key,
    required this.value,
    required this.label,
    this.duration = const Duration(milliseconds: 1200),
    this.valueStyle,
    this.labelStyle,
    this.onAnimationComplete,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCounter(
          count: value,
          duration: duration,
          style: valueStyle ?? Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          onAnimationComplete: onAnimationComplete,
          curve: Curves.easeOutBack,
          useCommaSeparator: true,
          animationType: CounterAnimationType.smooth,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: labelStyle ?? Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

/// Animated percentage counter
class AnimatedPercentageCounter extends StatelessWidget {
  final double percentage;
  final Duration duration;
  final TextStyle? style;
  final VoidCallback? onAnimationComplete;
  final int decimalPlaces;

  const AnimatedPercentageCounter({
    super.key,
    required this.percentage,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.onAnimationComplete,
    this.decimalPlaces = 1,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      count: (percentage * math.pow(10, decimalPlaces)).round(),
      duration: duration,
      style: style,
      onAnimationComplete: onAnimationComplete,
      curve: Curves.easeInOut,
      decimalPlaces: decimalPlaces,
      suffix: '%',
      useCommaSeparator: false,
      formatter: (value) {
        final actualValue = value / math.pow(10, decimalPlaces);
        return actualValue.toStringAsFixed(decimalPlaces);
      },
    );
  }
}

/// Factory methods for common counter configurations
extension AnimatedCounterFactory on AnimatedCounter {
  /// Create a quick counter for UI feedback
  static AnimatedCounter quick({
    required int count,
    TextStyle? style,
    String prefix = '',
    String suffix = '',
  }) {
    return AnimatedCounter(
      count: count,
      duration: const Duration(milliseconds: 300),
      style: style,
      prefix: prefix,
      suffix: suffix,
      curve: Curves.easeOut,
      animationType: CounterAnimationType.smooth,
    );
  }

  /// Create a dramatic counter for important numbers
  static AnimatedCounter dramatic({
    required int count,
    TextStyle? style,
    VoidCallback? onComplete,
  }) {
    return AnimatedCounter(
      count: count,
      duration: const Duration(milliseconds: 2000),
      style: style,
      onAnimationComplete: onComplete,
      curve: Curves.elasticOut,
      animationType: CounterAnimationType.smooth,
    );
  }

  /// Create a rolling odometer-style counter
  static AnimatedCounter odometer({
    required int count,
    TextStyle? style,
    Duration? duration,
  }) {
    return AnimatedCounter(
      count: count,
      duration: duration ?? const Duration(milliseconds: 1500),
      style: style,
      curve: Curves.decelerate,
      animationType: CounterAnimationType.rolling,
      useCommaSeparator: true,
    );
  }
}