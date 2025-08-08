import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/core/theme/app_theme.dart';
import 'package:puzzle_box/core/utils/responsive_utils.dart';

/// A customizable gradient button with animations and haptic feedback
class GradientButton extends StatefulWidget {
  /// Button child widget (usually Text or Icon)
  final Widget child;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Gradient for the button background
  final Gradient? gradient;
  
  /// Button width (defaults to auto-sizing)
  final double? width;
  
  /// Button height
  final double? height;
  
  /// Border radius
  final double borderRadius;
  
  /// Padding inside the button
  final EdgeInsetsGeometry? padding;
  
  /// Margin around the button
  final EdgeInsetsGeometry? margin;
  
  /// Shadow elevation
  final double elevation;
  
  /// Whether button is enabled
  final bool enabled;
  
  /// Animation duration for press effect
  final Duration animationDuration;
  
  /// Scale factor when pressed
  final double pressedScale;
  
  /// Whether to show ripple effect
  final bool showRipple;
  
  /// Whether to provide haptic feedback
  final bool hapticFeedback;
  
  /// Custom border
  final BorderSide? border;
  
  /// Icon to show on the left (optional)
  final IconData? leadingIcon;
  
  /// Icon to show on the right (optional)
  final IconData? trailingIcon;
  
  /// Icon size
  final double? iconSize;
  
  /// Spacing between icon and text
  final double iconSpacing;

  const GradientButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.gradient,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.padding,
    this.margin,
    this.elevation = 4.0,
    this.enabled = true,
    this.animationDuration = const Duration(milliseconds: 150),
    this.pressedScale = 0.95,
    this.showRipple = true,
    this.hapticFeedback = true,
    this.border,
    this.leadingIcon,
    this.trailingIcon,
    this.iconSize,
    this.iconSpacing = 8.0,
  });

  /// Factory constructor for primary button style
  factory GradientButton.primary({
    required Widget child,
    required VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool enabled = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return GradientButton(
      onPressed: onPressed,
      gradient: AppTheme.primaryGradient,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      enabled: enabled,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: child,
    );
  }

  /// Factory constructor for secondary button style
  factory GradientButton.secondary({
    required Widget child,
    required VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool enabled = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return GradientButton(
      onPressed: onPressed,
      gradient: AppTheme.secondaryGradient,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      enabled: enabled,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: child,
    );
  }

  /// Factory constructor for success button style
  factory GradientButton.success({
    required Widget child,
    required VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool enabled = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return GradientButton(
      onPressed: onPressed,
      gradient: const LinearGradient(
        colors: [AppTheme.successColor, Color(0xFF66BB6A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      enabled: enabled,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: child,
    );
  }

  /// Factory constructor for danger button style
  factory GradientButton.danger({
    required Widget child,
    required VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool enabled = true,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return GradientButton(
      onPressed: onPressed,
      gradient: const LinearGradient(
        colors: [Colors.red, Color(0xFFE57373)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      enabled: enabled,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: child,
    );
  }

  /// Factory constructor for outlined button style
  factory GradientButton.outlined({
    required Widget child,
    required VoidCallback? onPressed,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool enabled = true,
    Color borderColor = AppTheme.primaryColor,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return GradientButton(
      onPressed: onPressed,
      gradient: const LinearGradient(
        colors: [Colors.transparent, Colors.transparent],
      ),
      border: BorderSide(color: borderColor, width: 2),
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      enabled: enabled,
      elevation: 0,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      child: child,
    );
  }

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;
    
    setState(() {
      _isPressed = true;
    });
    
    _scaleController.forward();
    
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _onTapEnd();
  }

  void _onTapCancel() {
    _onTapEnd();
  }

  void _onTapEnd() {
    if (!mounted) return;
    
    setState(() {
      _isPressed = false;
    });
    
    _scaleController.reverse();
  }

  void _onTap() {
    if (!widget.enabled || widget.onPressed == null) return;
    
    widget.onPressed!();
    
    // Add shimmer effect on successful tap
    _shimmerController.forward().then((_) {
      _shimmerController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || widget.onPressed == null;
    
    return Container(
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(isDisabled),
          );
        },
      ),
    );
  }

  Widget _buildButton(bool isDisabled) {
    return Container(
      width: widget.width,
      height: widget.height ?? ResponsiveUtils.hp(6),
      decoration: BoxDecoration(
        gradient: isDisabled
            ? const LinearGradient(
                colors: [Colors.grey, Colors.grey],
              )
            : widget.gradient ?? AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border != null
            ? Border.all(
                color: isDisabled 
                    ? Colors.grey.withOpacity(0.5)
                    : widget.border!.color,
                width: widget.border!.width,
              )
            : null,
        boxShadow: widget.elevation > 0 && !isDisabled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: widget.elevation * 2,
                  offset: Offset(0, widget.elevation),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Shimmer effect
          if (!isDisabled)
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: Alignment(_shimmerAnimation.value - 1, 0),
                          end: Alignment(_shimmerAnimation.value, 0),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          
          // Button content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : _onTap,
              onTapDown: isDisabled ? null : _onTapDown,
              onTapUp: isDisabled ? null : _onTapUp,
              onTapCancel: isDisabled ? null : _onTapCancel,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              splashColor: widget.showRipple 
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                padding: widget.padding ?? EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.wp(6),
                  vertical: ResponsiveUtils.hp(1.5),
                ),
                child: _buildContent(isDisabled),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDisabled) {
    final widgets = <Widget>[];
    
    // Leading icon
    if (widget.leadingIcon != null) {
      widgets.add(
        Icon(
          widget.leadingIcon,
          size: widget.iconSize ?? ResponsiveUtils.sp(18),
          color: isDisabled ? Colors.grey.shade400 : Colors.white,
        ),
      );
      widgets.add(SizedBox(width: widget.iconSpacing));
    }
    
    // Main content
    widgets.add(
      Flexible(
        child: DefaultTextStyle(
          style: TextStyle(
            color: isDisabled ? Colors.grey.shade400 : Colors.white,
          ),
          child: widget.child,
        ),
      ),
    );
    
    // Trailing icon
    if (widget.trailingIcon != null) {
      widgets.add(SizedBox(width: widget.iconSpacing));
      widgets.add(
        Icon(
          widget.trailingIcon,
          size: widget.iconSize ?? ResponsiveUtils.sp(18),
          color: isDisabled ? Colors.grey.shade400 : Colors.white,
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgets,
    );
  }
}

/// A floating action button with gradient background
class GradientFAB extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Gradient? gradient;
  final double? elevation;
  final String? heroTag;

  const GradientFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.elevation,
    this.heroTag,
  });

  @override
  State<GradientFAB> createState() => _GradientFABState();
}

class _GradientFABState extends State<GradientFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.gradient ?? AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: widget.elevation ?? 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              heroTag: widget.heroTag,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}