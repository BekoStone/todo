import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A widget that animates changes to a numeric value with customizable styling
class AnimatedCounter extends StatefulWidget {
  /// The current value to display
  final int value;
  
  /// Text style for the counter
  final TextStyle? style;
  
  /// Duration of the animation
  final Duration duration;
  
  /// Animation curve
  final Curve curve;
  
  /// Prefix text (e.g., "$", "Level ")
  final String prefix;
  
  /// Suffix text (e.g., "pts", "%", "coins")
  final String suffix;
  
  /// Whether to format numbers with comma separators
  final bool useCommaFormat;
  
  /// Whether to use compact notation for large numbers (1K, 1M, etc.)
  final bool useCompactFormat;
  
  /// Text alignment
  final TextAlign textAlign;
  
  /// Whether to animate digits individually (more visually appealing)
  final bool animateDigitsIndividually;
  
  /// Whether to show a subtle bounce effect when value changes
  final bool enableBounceEffect;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
    this.useCommaFormat = false,
    this.useCompactFormat = false,
    this.textAlign = TextAlign.center,
    this.animateDigitsIndividually = true,
    this.enableBounceEffect = true,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _bounceController;
  late Animation<double> _animation;
  late Animation<double> _bounceAnimation;
  
  int _previousValue = 0;
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _currentValue = widget.value;
    _previousValue = widget.value;
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _previousValue = _currentValue;
      _currentValue = widget.value;
      
      _controller.reset();
      _controller.forward();
      
      if (widget.enableBounceEffect) {
        _bounceController.reset();
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _bounceAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableBounceEffect ? _bounceAnimation.value : 1.0,
          child: widget.animateDigitsIndividually
              ? _buildDigitAnimatedCounter()
              : _buildSimpleAnimatedCounter(),
        );
      },
    );
  }

  Widget _buildSimpleAnimatedCounter() {
    final currentDisplayValue = (_previousValue + 
        (_currentValue - _previousValue) * _animation.value).round();
    
    return Text(
      '${widget.prefix}${_formatNumber(currentDisplayValue)}${widget.suffix}',
      style: widget.style,
      textAlign: widget.textAlign,
    );
  }

  Widget _buildDigitAnimatedCounter() {
    final formattedPrevious = _formatNumber(_previousValue);
    final formattedCurrent = _formatNumber(_currentValue);
    final maxLength = math.max(formattedPrevious.length, formattedCurrent.length);
    
    // Pad both strings to same length
    final paddedPrevious = formattedPrevious.padLeft(maxLength, ' ');
    final paddedCurrent = formattedCurrent.padLeft(maxLength, ' ');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        if (widget.prefix.isNotEmpty)
          Text(
            widget.prefix,
            style: widget.style,
          ),
        ...List.generate(maxLength, (index) {
          return _buildAnimatedDigit(
            paddedPrevious[index],
            paddedCurrent[index],
            index,
          );
        }),
        if (widget.suffix.isNotEmpty)
          Text(
            widget.suffix,
            style: widget.style,
          ),
      ],
    );
  }

  Widget _buildAnimatedDigit(String previousChar, String currentChar, int index) {
    if (previousChar == currentChar) {
      return Text(
        currentChar,
        style: widget.style,
      );
    }

    // Animate between different characters
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;
        
        // Calculate vertical offset for sliding effect
        final offset = (1.0 - progress) * 30.0;
        
        return SizedBox(
          height: (widget.style?.fontSize ?? 14) * 1.2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Previous character sliding up and fading out
              Transform.translate(
                offset: Offset(0, -offset),
                child: Opacity(
                  opacity: 1.0 - progress,
                  child: Text(
                    previousChar,
                    style: widget.style,
                  ),
                ),
              ),
              // Current character sliding in from bottom
              Transform.translate(
                offset: Offset(0, 30.0 - offset),
                child: Opacity(
                  opacity: progress,
                  child: Text(
                    currentChar,
                    style: widget.style,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (widget.useCompactFormat) {
      return _formatCompactNumber(number);
    }
    
    if (widget.useCommaFormat) {
      return _formatWithCommas(number);
    }
    
    return number.toString();
  }

  String _formatCompactNumber(int number) {
    if (number.abs() >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number.abs() >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number.abs() >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _formatWithCommas(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }
}

/// A specialized animated counter for scores with built-in styling
class ScoreCounter extends StatelessWidget {
  final int score;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Duration duration;
  final bool showPlusSign;

  const ScoreCounter({
    super.key,
    required this.score,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.duration = const Duration(milliseconds: 1000),
    this.showPlusSign = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      value: score,
      duration: duration,
      prefix: showPlusSign && score > 0 ? '+' : '',
      useCommaFormat: true,
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: fontSize ?? 24,
        fontWeight: fontWeight ?? FontWeight.bold,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 3,
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}

/// A specialized animated counter for coins with coin icon
class CoinCounter extends StatelessWidget {
  final int coins;
  final Color? color;
  final double? fontSize;
  final Duration duration;
  final bool showIcon;

  const CoinCounter({
    super.key,
    required this.coins,
    this.color,
    this.fontSize,
    this.duration = const Duration(milliseconds: 800),
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(
            Icons.monetization_on_rounded,
            color: color ?? Colors.amber,
            size: fontSize ?? 20,
          ),
          const SizedBox(width: 4),
        ],
        AnimatedCounter(
          value: coins,
          duration: duration,
          useCommaFormat: true,
          style: TextStyle(
            color: color ?? Colors.amber,
            fontSize: fontSize ?? 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// A specialized animated counter for timers (formats as MM:SS)
class TimerCounter extends StatelessWidget {
  final int totalSeconds;
  final Color? color;
  final double? fontSize;
  final Duration duration;

  const TimerCounter({
    super.key,
    required this.totalSeconds,
    this.color,
    this.fontSize,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCounter(
          value: minutes,
          duration: duration,
          suffix: ':',
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: fontSize ?? 18,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        AnimatedCounter(
          value: seconds,
          duration: duration,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: fontSize ?? 18,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}