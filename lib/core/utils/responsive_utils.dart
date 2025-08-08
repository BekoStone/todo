import 'package:flutter/material.dart';
import '../theme/responsive_config.dart';
import '../constants/app_constants.dart';

class ResponsiveUtils {
  // Static screen size cache for performance
  static Size? _cachedScreenSize;
  static double? _cachedPixelRatio;
  
  /// Initialize screen size cache (call this in main.dart)
  static void initialize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _cachedScreenSize = mediaQuery.size;
    _cachedPixelRatio = mediaQuery.devicePixelRatio;
  }
  
  /// Get current screen size with fallback
  static Size _getScreenSize(BuildContext? context) {
    if (context != null) {
      return MediaQuery.of(context).size;
    }
    return _cachedScreenSize ?? const Size(375, 812); // iPhone 12 fallback
  }
  
  /// Width percentage - wp(50) = 50% of screen width
  static double wp(double percentage, [BuildContext? context]) {
    final screenSize = _getScreenSize(context);
    return (percentage / 100) * screenSize.width;
  }
  
  /// Height percentage - hp(50) = 50% of screen height  
  static double hp(double percentage, [BuildContext? context]) {
    final screenSize = _getScreenSize(context);
    return (percentage / 100) * screenSize.height;
  }
  
  /// Scaled pixels - sp(16) = 16dp with device scaling applied
  static double sp(double fontSize, [BuildContext? context]) {
    if (context != null) {
      final mediaQuery = MediaQuery.of(context);
      final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.4);
      final deviceScale = _getDeviceScale(context);
      return fontSize * deviceScale * textScaleFactor;
    }
    
    // Fallback without context
    final pixelRatio = _cachedPixelRatio ?? 2.0;
    final baseScale = pixelRatio > 3.0 ? 1.2 : 1.0; // High DPI adjustment
    return fontSize * baseScale;
  }
  
  /// Get device scale factor
  static double _getDeviceScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 1.4; // Desktop
    if (screenWidth > 600) return 1.2; // Tablet
    return 1.0; // Mobile
  }

  // Calculate optimal game layout based on screen size
  static GameLayout calculateGameLayout(BuildContext context) {
    final config = ResponsiveConfig.getLayoutConfig(context);
    final gridConfig = ResponsiveConfig.getGridConfig(context);
    
    // Calculate UI element sizes based on available space
    final availableHeight = config.availableHeight;
    final availableWidth = config.availableWidth;
    
    // Reserve space for different UI elements
    final hudHeight = ResponsiveUtils.scale(context, 80);
    final slotsHeight = ResponsiveUtils.scale(context, 100);
    final powerUpHeight = ResponsiveUtils.scale(context, 70);
    
    // Calculate grid area
    final reservedHeight = hudHeight + slotsHeight + powerUpHeight;
    final gridAreaHeight = availableHeight - reservedHeight;
    final gridAreaWidth = availableWidth;
    
    // Ensure grid fits properly
    final maxGridSize = gridAreaWidth < gridAreaHeight ? gridAreaWidth : gridAreaHeight;
    final adjustedCellSize = (maxGridSize - (AppConstants.gridSize - 1) * gridConfig.spacing) / AppConstants.gridSize;
    
    return GameLayout(
      screenSize: config.screenSize,
      deviceType: config.deviceType,
      gridConfig: GridConfig(
        cellSize: adjustedCellSize.clamp(28.0, 60.0),
        spacing: gridConfig.spacing,
        padding: gridConfig.padding,
      ),
      hudHeight: hudHeight,
      slotsHeight: slotsHeight,
      powerUpHeight: powerUpHeight,
      sideMargin: config.sideMargin,
      isLandscape: config.isLandscape,
    );
  }
  
  // Responsive scaling function
  static double scale(BuildContext context, double baseValue) {
    final deviceType = ResponsiveConfig.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return baseValue;
      case DeviceType.tablet:
        return baseValue * 1.2;
      case DeviceType.desktop:
        return baseValue * 1.4;
      default:
        return baseValue;
    }
  }
  
  // Scale font size responsively
  static double scaleFontSize(BuildContext context, double fontSize) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.8, 1.4);
    final deviceScale = ResponsiveConfig.getTextScale(context);
    
    return fontSize * deviceScale * textScaleFactor;
  }
  
  // Get optimal button size
  static Size getButtonSize(BuildContext context, {Size? base}) {
    final baseSize = base ?? const Size(120, 48);
    final scale = ResponsiveConfig.getDeviceType(context) == DeviceType.mobile ? 1.0 : 1.2;
    
    return Size(
      baseSize.width * scale,
      baseSize.height * scale,
    );
  }
  
  // Get optimal icon size
  static double getIconSize(BuildContext context, {double base = 24}) {
    return ResponsiveConfig.responsive(
      context,
      mobile: base,
      tablet: base * 1.2,
      desktop: base * 1.4,
    );
  }
  
  // Calculate safe padding considering notches and navigation
  static EdgeInsets getSafePadding(BuildContext context, {EdgeInsets? additional}) {
    final mediaQuery = MediaQuery.of(context);
    EdgeInsets basePadding = EdgeInsets.only(
      top: mediaQuery.viewPadding.top,
      bottom: mediaQuery.viewPadding.bottom,
      left: ResponsiveConfig.getPadding(context),
      right: ResponsiveConfig.getPadding(context),
    );
    
    if (additional != null) {
      return EdgeInsets.only(
        top: basePadding.top + additional.top,
        bottom: basePadding.bottom + additional.bottom,
        left: basePadding.left + additional.left,
        right: basePadding.right + additional.right,
      );
    }
    
    return basePadding;
  }
  
  // Responsive grid calculation for block slots
  static SlotLayout calculateSlotLayout(BuildContext context, int slotCount) {
    final layout = calculateGameLayout(context);
    final totalWidth = layout.screenSize.width - (layout.sideMargin * 2);
    
    // Calculate slot size and spacing
    final minSlotSize = scale(context, 80);
    final maxSlotSize = scale(context, 120);
    
    final totalSpacing = (slotCount - 1) * scale(context, 16);
    final availableSlotWidth = totalWidth - totalSpacing;
    final idealSlotSize = availableSlotWidth / slotCount;
    
    final slotSize = idealSlotSize.clamp(minSlotSize, maxSlotSize);
    final actualTotalWidth = (slotSize * slotCount) + totalSpacing;
    
    return SlotLayout(
      slotSize: Size(slotSize, slotSize),
      spacing: scale(context, 16),
      totalWidth: actualTotalWidth,
      centerOffset: (totalWidth - actualTotalWidth) / 2,
    );
  }
  
  // Animation duration scaling based on device performance
  static Duration getAnimationDuration(
    BuildContext context,
    Duration baseDuration, {
    bool respectAccessibility = true,
  }) {
    var duration = baseDuration;
    
    // Scale animation duration for accessibility
    if (respectAccessibility) {
      final mediaQuery = MediaQuery.of(context);
      final accessibilityFeatures = mediaQuery.accessibleNavigation;
      if (accessibilityFeatures) {
        duration = Duration(milliseconds: (duration.inMilliseconds * 1.5).round());
      }
    }
    
    // Scale for device performance
    final deviceType = ResponsiveConfig.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return duration;
      case DeviceType.tablet:
        return Duration(milliseconds: (duration.inMilliseconds * 0.9).round());
      case DeviceType.desktop:
        return Duration(milliseconds: (duration.inMilliseconds * 0.8).round());
      default:
        return duration;
    }
  }

  /// Get responsive breakpoint
  static ResponsiveBreakpoint getBreakpoint(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return ResponsiveBreakpoint.desktop;
    if (screenWidth >= 600) return ResponsiveBreakpoint.tablet;
    return ResponsiveBreakpoint.mobile;
  }

  /// Get game configuration for Flame game initialization
  static GameConfig getGameConfig(Size screenSize) {
    // Calculate device type based on screen size
    final deviceType = screenSize.width >= 1200 
        ? DeviceType.desktop 
        : screenSize.width >= 600 
            ? DeviceType.tablet 
            : DeviceType.mobile;
    
    // Calculate optimal grid size based on available space
    final availableSize = screenSize.width < screenSize.height 
        ? screenSize.width 
        : screenSize.height;
    
    final gridSize = AppConstants.gridSize;
    final cellSize = (availableSize * 0.6) / gridSize; // Use 60% of available space
    
    return GameConfig(
      gridSize: gridSize,
      cellSize: cellSize.clamp(28.0, 60.0),
      deviceType: deviceType,
      screenSize: screenSize,
    );
  }

  // Build responsive widget
  static Widget buildResponsiveWidget({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case ResponsiveBreakpoint.mobile:
        return mobile;
      case ResponsiveBreakpoint.tablet:
        return tablet ?? mobile;
      case ResponsiveBreakpoint.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
}

/// Responsive breakpoint enumeration
enum ResponsiveBreakpoint {
  mobile,
  tablet,
  desktop,
}

/// Game layout configuration
class GameLayout {
  final Size screenSize;
  final DeviceType deviceType;
  final GridConfig gridConfig;
  final double hudHeight;
  final double slotsHeight;
  final double powerUpHeight;
  final double sideMargin;
  final bool isLandscape;

  const GameLayout({
    required this.screenSize,
    required this.deviceType,
    required this.gridConfig,
    required this.hudHeight,
    required this.slotsHeight,
    required this.powerUpHeight,
    required this.sideMargin,
    required this.isLandscape,
  });
}

/// Slot layout configuration
class SlotLayout {
  final Size slotSize;
  final double spacing;
  final double totalWidth;
  final double centerOffset;

  const SlotLayout({
    required this.slotSize,
    required this.spacing,
    required this.totalWidth,
    required this.centerOffset,
  });
}

/// Game configuration for Flame game
class GameConfig {
  final int gridSize;
  final double cellSize;
  final DeviceType deviceType;
  final Size screenSize;

  const GameConfig({
    required this.gridSize,
    required this.cellSize,
    required this.deviceType,
    required this.screenSize,
  });
}