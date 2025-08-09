import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;
  final Curve curve;
  final TextAlign textAlign;
  final bool useCommaForThousands;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix,
    this.suffix,
    this.curve = Curves.easeOutCubic,
    this.textAlign = TextAlign.center,
    this.useCommaForThousands = true,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _previousValue = widget.value;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    final intValue = value.round();
    
    if (!widget.useCommaForThousands) {
      return intValue.toString();
    }
    
    // Add comma separators for thousands
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return intValue.toString().replaceAllMapped(
      formatter,
      (Match match) => '${match[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final displayValue = _formatNumber(_animation.value);
        final text = '${widget.prefix ?? ''}$displayValue${widget.suffix ?? ''}';
        
        return Text(
          text,
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}

/// Advanced animated counter with more visual effects
class FancyAnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;
  final Color? highlightColor;
  final bool showPlusAnimation;
  final VoidCallback? onAnimationComplete;

  const FancyAnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.prefix,
    this.suffix,
    this.highlightColor,
    this.showPlusAnimation = false,
    this.onAnimationComplete,
  });

  @override
  State<FancyAnimatedCounter> createState() => _FancyAnimatedCounterState();
}

class _FancyAnimatedCounterState extends State<FancyAnimatedCounter>
    with TickerProviderStateMixin {
  late AnimationController _counterController;
  late AnimationController _scaleController;
  late AnimationController _glowController;
  
  late Animation<double> _counterAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  int _previousValue = 0;
  bool _isIncreasing = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _previousValue = widget.value;
    _startAnimation();
  }

  void _setupAnimations() {
    _counterController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _counterAnimation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _counterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(FancyAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _isIncreasing = widget.value > oldWidget.value;
      _previousValue = oldWidget.value;
      
      _counterAnimation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _counterController,
        curve: Curves.easeOutCubic,
      ));
      
      _startAnimation();
    }
  }

  void _startAnimation() {
    _counterController.reset();
    _counterController.forward();
    
    if (_isIncreasing) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      
      if (widget.highlightColor != null) {
        _glowController.forward().then((_) {
          _glowController.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _counterController.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    final intValue = value.round();
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return intValue.toString().replaceAllMapped(
      formatter,
      (Match match) => '${match[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _counterAnimation,
        _scaleAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        final displayValue = _formatNumber(_counterAnimation.value);
        final text = '${widget.prefix ?? ''}$displayValue${widget.suffix ?? ''}';
        
        Widget textWidget = Text(
          text,
          style: widget.style,
        );

        // Apply scale animation
        textWidget = Transform.scale(
          scale: _scaleAnimation.value,
          child: textWidget,
        );

        // Apply glow effect if highlight color is provided
        if (widget.highlightColor != null && _glowAnimation.value > 0) {
          textWidget = Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.highlightColor!.withOpacity(_glowAnimation.value * 0.5),
                  blurRadius: 10 * _glowAnimation.value,
                  spreadRadius: 2 * _glowAnimation.value,
                ),
              ],
            ),
            child: textWidget,
          );
        }

        return textWidget;
      },
    );
  }
}

/// Rolling counter animation (like slot machine)
class RollingCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final int numberOfDigits;
  final String? prefix;
  final String? suffix;

  const RollingCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.numberOfDigits = 6,
    this.prefix,
    this.suffix,
  });

  @override
  State<RollingCounter> createState() => _RollingCounterState();
}

class _RollingCounterState extends State<RollingCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _digitAnimations;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _previousValue = widget.value;
    _controller.forward();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _digitAnimations = List.generate(widget.numberOfDigits, (index) {
      final delay = index * 0.1;
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          delay,
          math.min(1.0, delay + 0.8),
          curve: Curves.easeOutCubic,
        ),
      ));
    });
  }

  @override
  void didUpdateWidget(RollingCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDigit(int digitIndex, String digit, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final currentDigit = (int.tryParse(digit) ?? 0);
        final targetDigit = currentDigit;
        final animatedDigit = (currentDigit * animation.value).round();
        
        return ClipRect(
          child: Transform.translate(
            offset: Offset(0, -20 * (1 - animation.value)),
            child: Opacity(
              opacity: animation.value,
              child: Text(
                animatedDigit.toString(),
                style: widget.style,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final valueString = widget.value.toString().padLeft(widget.numberOfDigits, '0');
    final digits = valueString.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.prefix != null)
          Text(widget.prefix!, style: widget.style),
        ...digits.asMap().entries.map((entry) {
          final index = entry.key;
          final digit = entry.value;
          return _buildDigit(index, digit, _digitAnimations[index]);
        }),
        if (widget.suffix != null)
          Text(widget.suffix!, style: widget.style),
      ],
    );
  }
}

/// Speedometer-style counter
class SpeedometerCounter extends StatefulWidget {
  final double value;
  final double maxValue;
  final TextStyle? style;
  final Color? progressColor;
  final Color? backgroundColor;
  final double size;
  final Duration duration;

  const SpeedometerCounter({
    super.key,
    required this.value,
    required this.maxValue,
    this.style,
    this.progressColor,
    this.backgroundColor,
    this.size = 100.0,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<SpeedometerCounter> createState() => _SpeedometerCounterState();
}

class _SpeedometerCounterState extends State<SpeedometerCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.value / widget.maxValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(SpeedometerCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: oldWidget.value / widget.maxValue,
        end: widget.value / widget.maxValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: SpeedometerPainter(
              progress: 1.0,
              color: widget.backgroundColor ?? Colors.grey.withOpacity(0.3),
              strokeWidth: 8,
            ),
          ),
          
          // Progress arc
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: SpeedometerPainter(
                  progress: _animation.value,
                  color: widget.progressColor ?? Colors.blue,
                  strokeWidth: 8,
                ),
              );
            },
          ),
          
          // Center text
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final displayValue = (widget.value * _animation.value).round();
              return Text(
                displayValue.toString(),
                style: widget.style ?? const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  SpeedometerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}