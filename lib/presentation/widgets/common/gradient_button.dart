import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/responsive_utils.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? child;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool enabled;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.child,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.boxShadow,
    this.enabled = true,
    this.isLoading = false,
  });

  /// Primary gradient button with default styling
  factory GradientButton.primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    Widget? child,
    double? width,
    double? height,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      child: child,
      width: width,
      height: height,
      enabled: enabled,
      isLoading: isLoading,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primary, AppColors.secondary],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Secondary gradient button
  factory GradientButton.secondary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    Widget? child,
    double? width,
    double? height,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      child: child,
      width: width,
      height: height,
      enabled: enabled,
      isLoading: isLoading,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.info, AppColors.primary],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.info.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Success style button
  factory GradientButton.success({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    Widget? child,
    double? width,
    double? height,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      child: child,
      width: width,
      height: height,
      enabled: enabled,
      isLoading: isLoading,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.success, AppColors.info],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.success.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Warning style button
  factory GradientButton.warning({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    Widget? child,
    double? width,
    double? height,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      child: child,
      width: width,
      height: height,
      enabled: enabled,
      isLoading: isLoading,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.warning, AppColors.error],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.warning.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Outlined button style
  factory GradientButton.outlined({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    Widget? child,
    double? width,
    double? height,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      child: child,
      width: width,
      height: height,
      enabled: enabled,
      isLoading: isLoading,
      backgroundColor: Colors.transparent,
      textColor: AppColors.primary,
    );
  }

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enabled && !widget.isLoading && widget.onPressed != null) {
      HapticFeedback.mediumImpact();
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled && !widget.isLoading;
    final height = widget.height ?? ResponsiveUtils.hp(6);
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(12);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              onTap: _handleTap,
              child: Container(
                width: widget.width,
                height: height,
                padding: widget.padding ?? EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.wp(4),
                  vertical: ResponsiveUtils.hp(1),
                ),
                decoration: BoxDecoration(
                  gradient: isEnabled ? widget.gradient : null,
                  color: !isEnabled 
                      ? Colors.grey.withOpacity(0.3)
                      : widget.backgroundColor,
                  borderRadius: borderRadius,
                  border: widget.gradient == null && widget.backgroundColor == Colors.transparent
                      ? Border.all(
                          color: isEnabled ? AppColors.primary : Colors.grey,
                          width: 2,
                        )
                      : null,
                  boxShadow: isEnabled ? widget.boxShadow : null,
                ),
                child: _buildButtonContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: ResponsiveUtils.sp(20),
          height: ResponsiveUtils.sp(20),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.textColor ?? Colors.white,
            ),
          ),
        ),
      );
    }

    if (widget.child != null) {
      return Center(child: widget.child!);
    }

    final textColor = widget.enabled 
        ? (widget.textColor ?? Colors.white)
        : Colors.grey;

    final textStyle = TextStyle(
      fontSize: ResponsiveUtils.sp(16),
      fontWeight: FontWeight.bold,
      color: textColor,
      letterSpacing: 0.5,
    );

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon!,
            color: textColor,
            size: ResponsiveUtils.sp(20),
          ),
          SizedBox(width: ResponsiveUtils.wp(2)),
          Text(
            widget.text,
            style: textStyle,
          ),
        ],
      );
    }

    return Center(
      child: Text(
        widget.text,
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Extended gradient button with more customization options
class CustomGradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool enabled;

  const CustomGradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.boxShadow,
    this.border,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: Ink(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: enabled ? gradient : null,
              color: !enabled 
                  ? Colors.grey.withOpacity(0.3)
                  : backgroundColor,
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              border: border,
              boxShadow: enabled ? boxShadow : null,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Floating action gradient button
class FloatingGradientButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final double size;
  final String? tooltip;
  final String? heroTag;

  const FloatingGradientButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.gradient,
    this.size = 56.0,
    this.tooltip,
    this.heroTag,
  });

  @override
  State<FloatingGradientButton> createState() => _FloatingGradientButtonState();
}

class _FloatingGradientButtonState extends State<FloatingGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            tooltip: widget.tooltip,
            heroTag: widget.heroTag,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: widget.gradient ?? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(widget.size / 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: widget.size * 0.4,
              ),
            ),
          ),
        );
      },
    );
  }
}