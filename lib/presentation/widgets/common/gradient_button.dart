import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_utils.dart';

/// GradientButton provides a customizable button with gradient background support.
/// Optimized for performance with efficient rendering and minimal rebuilds.
/// Supports both gradient and solid color backgrounds with consistent styling.
class GradientButton extends StatefulWidget {
  /// Button text
  final String text;
  
  /// Optional icon to display before text
  final IconData? icon;
  
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// Gradient background (takes priority over backgroundColor)
  final Gradient? gradient;
  
  /// Solid background color (used if gradient is null)
  final Color? backgroundColor;
  
  /// Text color
  final Color? textColor;
  
  /// Button width (null for intrinsic width)
  final double? width;
  
  /// Button height
  final double? height;
  
  /// Border radius
  final double? borderRadius;
  
  /// Elevation when not pressed
  final double elevation;
  
  /// Elevation when pressed
  final double pressedElevation;
  
  /// Text style override
  final TextStyle? textStyle;
  
  /// Padding inside button
  final EdgeInsetsGeometry? padding;
  
  /// Margin around button
  final EdgeInsetsGeometry? margin;
  
  /// Whether to show loading indicator
  final bool isLoading;
  
  /// Loading indicator color
  final Color? loadingColor;
  
  /// Whether button is compact (smaller padding)
  final bool isCompact;
  
  /// Border configuration
  final BorderSide? border;
  
  /// Splash color for touch feedback
  final Color? splashColor;

  const GradientButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.elevation = 2.0,
    this.pressedElevation = 1.0,
    this.textStyle,
    this.padding,
    this.margin,
    this.isLoading = false,
    this.loadingColor,
    this.isCompact = false,
    this.border,
    this.splashColor,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
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

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.pressedElevation,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    return Container(
      width: widget.width,
      height: widget.height ?? AppConstants.buttonHeight,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(context, theme, isEnabled),
          );
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme, bool isEnabled) {
    return Material(
      elevation: _elevationAnimation.value,
      borderRadius: BorderRadius.circular(
        widget.borderRadius ?? AppConstants.buttonBorderRadius,
      ),
      shadowColor: theme.shadowColor,
      color: Colors.transparent,
      child: Container(
        decoration: _buildDecoration(theme, isEnabled),
        child: InkWell(
          onTap: isEnabled ? _handleTap : null,
          onTapDown: isEnabled ? _handleTapDown : null,
          onTapUp: isEnabled ? _handleTapUp : null,
          onTapCancel: isEnabled ? _handleTapCancel : null,
          onHover: isEnabled ? _handleHover : null,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppConstants.buttonBorderRadius,
          ),
          splashColor: widget.splashColor ?? 
              (widget.textColor ?? theme.colorScheme.onPrimary).withValues(alpha:0.3),
          highlightColor: (widget.textColor ?? theme.colorScheme.onPrimary)
              .withValues(alpha:0.1),
          child: _buildContent(theme, isEnabled),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(ThemeData theme, bool isEnabled) {
    Color? backgroundColor;
    Gradient? gradient;

    if (isEnabled) {
      if (widget.gradient != null) {
        gradient = widget.gradient;
      } else {
        backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
      }
    } else {
      backgroundColor = (widget.backgroundColor ?? theme.colorScheme.primary)
          .withValues(alpha:0.3);
    }

    // Apply hover effect
    if (_isHovered && isEnabled) {
      if (gradient != null) {
        // Brighten gradient colors slightly
        gradient = _brightenGradient(gradient, 0.1);
      } else if (backgroundColor != null) {
        backgroundColor = _brightenColor(backgroundColor, 0.1);
      }
    }

    return BoxDecoration(
      gradient: gradient,
      color: backgroundColor,
      borderRadius: BorderRadius.circular(
        widget.borderRadius ?? AppConstants.buttonBorderRadius,
      ),
      border: widget.border != null ? Border.fromBorderSide(widget.border!) : null,
    );
  }

  Widget _buildContent(ThemeData theme, bool isEnabled) {
    final textColor = isEnabled
        ? (widget.textColor ?? theme.colorScheme.onPrimary)
        : (widget.textColor ?? theme.colorScheme.onPrimary).withValues(alpha:0.5);

    final padding = widget.padding ?? 
        (widget.isCompact 
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12));

    return Container(
      padding: padding,
      child: widget.isLoading
          ? _buildLoadingContent(textColor)
          : _buildNormalContent(theme, textColor),
    );
  }

  Widget _buildLoadingContent(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: ResponsiveUtils.sp(16),
          height: ResponsiveUtils.sp(16),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.loadingColor ?? textColor,
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.wp(2)),
        Text(
          'Loading...',
          style: _getTextStyle().copyWith(color: textColor),
        ),
      ],
    );
  }

  Widget _buildNormalContent(ThemeData theme, Color textColor) {
    if (widget.icon == null) {
      return Text(
        widget.text,
        style: _getTextStyle().copyWith(color: textColor),
        textAlign: TextAlign.center,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.icon,
          color: textColor,
          size: ResponsiveUtils.sp(18),
        ),
        SizedBox(width: ResponsiveUtils.wp(2)),
        Flexible(
          child: Text(
            widget.text,
            style: _getTextStyle().copyWith(color: textColor),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  TextStyle _getTextStyle() {
    if (widget.textStyle != null) {
      return widget.textStyle!;
    }

    final baseStyle = Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    
    return baseStyle.copyWith(
      fontSize: ResponsiveUtils.sp(widget.isCompact ? 14 : 16),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  Gradient _brightenGradient(Gradient gradient, double factor) {
    if (gradient is LinearGradient) {
      return LinearGradient(
        colors: gradient.colors.map((c) => _brightenColor(c, factor)).toList(),
        stops: gradient.stops,
        begin: gradient.begin,
        end: gradient.end,
      );
    } else if (gradient is RadialGradient) {
      return RadialGradient(
        colors: gradient.colors.map((c) => _brightenColor(c, factor)).toList(),
        stops: gradient.stops,
        center: gradient.center,
        radius: gradient.radius,
      );
    }
    return gradient;
  }

  Color _brightenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }
}

/// Factory methods for common button styles
extension GradientButtonStyles on GradientButton {
  /// Create a primary gradient button
  static GradientButton primary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      width: width,
      height: height,
      isLoading: isLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFF4ECDC4), Color(0xFF45B7D1)],
      ),
    );
  }

  /// Create a secondary outline button
  static GradientButton secondary({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      width: width,
      height: height,
      isLoading: isLoading,
      backgroundColor: Colors.transparent,
      textColor: const Color(0xFF4ECDC4),
      border: const BorderSide(color: Color(0xFF4ECDC4)),
      elevation: 0,
      pressedElevation: 0,
    );
  }

  /// Create a success button
  static GradientButton success({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      width: width,
      height: height,
      isLoading: isLoading,
      backgroundColor: const Color(0xFF4CAF50),
    );
  }

  /// Create a warning button
  static GradientButton warning({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      width: width,
      height: height,
      isLoading: isLoading,
      backgroundColor: const Color(0xFFFF9800),
      textColor: Colors.black,
    );
  }

  /// Create an error button
  static GradientButton error({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      width: width,
      height: height,
      isLoading: isLoading,
      backgroundColor: const Color(0xFFFF5252),
    );
  }

  /// Create a compact button
  static GradientButton compact({
    required String text,
    IconData? icon,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    bool isLoading = false,
  }) {
    return GradientButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      width: width,
      height: 32,
      isLoading: isLoading,
      isCompact: true,
      backgroundColor: backgroundColor,
      textColor: textColor,
      elevation: 1,
      pressedElevation: 0.5,
    );
  }
}