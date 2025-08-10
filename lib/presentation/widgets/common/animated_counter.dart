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
  
  // Animation controller - CRITICAL: Must be disposed properly
  late AnimationController _controller;
  late Animation<double> _animation;
  
  int _previousCount = 0;
  bool _hasStarted = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    
    if (widget.autoStart) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // CRITICAL: Dispose animation controller to prevent memory leaks
    _controller.dispose();
    
    super.dispose();
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
      if (!_isDisposed && status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  void _startAnimation() {
    if (_isDisposed) return;
    
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
    if (!_isDisposed) {
      _startAnimation();
    }
  }

  /// Reset the animation to the beginning
  void resetAnimation() {
    if (!_isDisposed) {
      _controller.reset();
      _hasStarted = false;
    }
  }

  /// Check if animation is currently running
  bool get isAnimating => !_isDisposed && _controller.isAnimating;
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
  final bool showPercentageSign;

  const AnimatedPercentageCounter({
    super.key,
    required this.percentage,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.onAnimationComplete,
    this.showPercentageSign = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      count: percentage.round(),
      duration: duration,
      style: style,
      onAnimationComplete: onAnimationComplete,
      suffix: showPercentageSign ? '%' : '',
      curve: Curves.easeInOutCubic,
      useCommaSeparator: false,
      animationType: CounterAnimationType.smooth,
    );
  }
}

/// Animated timer counter (for countdowns)
class AnimatedTimerCounter extends StatelessWidget {
  final Duration duration;
  final Duration animationDuration;
  final TextStyle? style;
  final VoidCallback? onAnimationComplete;
  final String Function(Duration)? formatter;

  const AnimatedTimerCounter({
    super.key,
    required this.duration,
    this.animationDuration = const Duration(milliseconds: 500),
    this.style,
    this.onAnimationComplete,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = formatter?.call(duration) ?? _defaultTimeFormatter(duration);
    
    return AnimatedSwitcher(
      duration: animationDuration,
      child: Text(
        formattedTime,
        key: ValueKey(formattedTime),
        style: style,
      ),
    );
  }

  String _defaultTimeFormatter(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Multi-value animated counter for complex statistics
class AnimatedMultiCounter extends StatelessWidget {
  final List<AnimatedCounterData> counters;
  final Duration duration;
  final MainAxisAlignment alignment;
  final CrossAxisAlignment crossAlignment;
  final double spacing;

  const AnimatedMultiCounter({
    super.key,
    required this.counters,
    this.duration = const Duration(milliseconds: 1000),
    this.alignment = MainAxisAlignment.center,
    this.crossAlignment = CrossAxisAlignment.center,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: alignment,
      crossAxisAlignment: crossAlignment,
      children: counters.map((counter) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: spacing / 2),
          child: AnimatedStatCounter(
            value: counter.value,
            label: counter.label,
            duration: duration,
            valueStyle: counter.valueStyle,
            labelStyle: counter.labelStyle,
            onAnimationComplete: counter.onComplete,
          ),
        );
      }).toList(),
    );
  }
}

/// Data class for multi-counter
class AnimatedCounterData {
  final int value;
  final String label;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final VoidCallback? onComplete;

  const AnimatedCounterData({
    required this.value,
    required this.label,
    this.valueStyle,
    this.labelStyle,
    this.onComplete,
  });
}