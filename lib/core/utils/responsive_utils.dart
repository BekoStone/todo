import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/game_constants.dart';

/// ResponsiveUtils provides adaptive design utilities for Box Hooks.
/// Handles screen size detection, responsive scaling, and device-specific optimizations.
/// Optimized for performance with cached calculations and minimal rebuilds.
class ResponsiveUtils {
  // Private constructor to prevent instantiation
  ResponsiveUtils._();

  // Cached values for performance
  static Size? _screenSize;
  static double? _pixelRatio;
  static Orientation? _orientation;
  static DeviceType? _deviceType;
  static ScreenSize? _screenSizeCategory;
  static bool _isInitialized = false;

  // Performance optimization: cache frequently used calculations
  static final Map<String, double> _cachedValues = {};
  static MediaQueryData? _lastMediaQuery;

  // ========================================
  // INITIALIZATION
  // ========================================

  /// Initialize ResponsiveUtils with context (call once at app start)
  static void initialize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _updateCachedValues(mediaQuery);
    _isInitialized = true;
  }

  /// Update cached values when MediaQuery changes
  static void _updateCachedValues(MediaQueryData mediaQuery) {
    if (_lastMediaQuery != mediaQuery) {
      _screenSize = mediaQuery.size;
      _pixelRatio = mediaQuery.devicePixelRatio;
      _orientation = mediaQuery.orientation;
      _deviceType = _calculateDeviceType(mediaQuery.size);
      _screenSizeCategory = _calculateScreenSizeCategory(mediaQuery.size);
      _cachedValues.clear(); // Clear cache when screen changes
      _lastMediaQuery = mediaQuery;
    }
  }

  /// Ensure initialization before using utilities
  static void _ensureInitialized(BuildContext? context) {
    if (!_isInitialized && context != null) {
      initialize(context);
    }
    assert(_isInitialized, 'ResponsiveUtils must be initialized with a BuildContext');
  }

  // ========================================
  // SCREEN SIZE DETECTION
  // ========================================

  /// Check if device is mobile (phones)
  static bool isMobile([BuildContext? context]) {
    _ensureInitialized(context);
    return _deviceType == DeviceType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet([BuildContext? context]) {
    _ensureInitialized(context);
    return _deviceType == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop([BuildContext? context]) {
    _ensureInitialized(context);
    return _deviceType == DeviceType.desktop;
  }

  /// Check if screen is in landscape orientation
  static bool isLandscape([BuildContext? context]) {
    _ensureInitialized(context);
    return _orientation == Orientation.landscape;
  }

  /// Check if screen is in portrait orientation
  static bool isPortrait([BuildContext? context]) {
    _ensureInitialized(context);
    return _orientation == Orientation.portrait;
  }

  /// Get current device type
  static DeviceType getDeviceType([BuildContext? context]) {
    _ensureInitialized(context);
    return _deviceType ?? DeviceType.mobile;
  }

  /// Get current screen size category
  static ScreenSize getScreenSizeCategory([BuildContext? context]) {
    _ensureInitialized(context);
    return _screenSizeCategory ?? ScreenSize.small;
  }

  // ========================================
  // RESPONSIVE DIMENSIONS
  // ========================================

  /// Get screen width
  static double width([BuildContext? context]) {
    _ensureInitialized(context);
    return _screenSize?.width ?? 375.0; // iPhone fallback
  }

  /// Get screen height
  static double height([BuildContext? context]) {
    _ensureInitialized(context);
    return _screenSize?.height ?? 812.0; // iPhone fallback
  }

  /// Get pixel ratio
  static double pixelRatio([BuildContext? context]) {
    _ensureInitialized(context);
    return _pixelRatio ?? 2.0;
  }

  /// Get responsive width percentage
  static double wp(double percentage, [BuildContext? context]) {
    final cacheKey = 'wp_$percentage';
    if (_cachedValues.containsKey(cacheKey)) {
      return _cachedValues[cacheKey]!;
    }
    
    final value = width(context) * percentage / 100;
    _cachedValues[cacheKey] = value;
    return value;
  }

  /// Get responsive height percentage
  static double hp(double percentage, [BuildContext? context]) {
    final cacheKey = 'hp_$percentage';
    if (_cachedValues.containsKey(cacheKey)) {
      return _cachedValues[cacheKey]!;
    }
    
    final value = height(context) * percentage / 100;
    _cachedValues[cacheKey] = value;
    return value;
  }

  /// Get responsive font size
  static double sp(double size, [BuildContext? context]) {
    final cacheKey = 'sp_$size';
    if (_cachedValues.containsKey(cacheKey)) {
      return _cachedValues[cacheKey]!;
    }
    
    final screenWidth = width(context);
    final scaleFactor = _getScaleFactor(screenWidth);
    final value = size * scaleFactor;
    _cachedValues[cacheKey] = value;
    return value;
  }

  // ========================================
  // GAME-SPECIFIC RESPONSIVE UTILITIES
  // ========================================

  /// Get optimal grid size for current screen
  static int getOptimalGridSize([BuildContext? context]) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return isLandscape(context) ? 12 : 10;
      case DeviceType.tablet:
        return 12;
      case DeviceType.desktop:
        return 14;
    }
  }

  /// Get optimal cell size for game grid
  static double getOptimalCellSize([BuildContext? context]) {
    final screenWidth = width(context);
    final gridSize = getOptimalGridSize(context);
    final padding = GameConstants.gridPadding * 2;
    final availableWidth = screenWidth - padding;
    return (availableWidth / gridSize).floorToDouble();
  }

  /// Get game UI scale factor
  static double getGameUIScale([BuildContext? context]) {
    final deviceType = getDeviceType(context);
    final screenSize = getScreenSizeCategory(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return screenSize == ScreenSize.small ? 0.8 : 1.0;
      case DeviceType.tablet:
        return 1.2;
      case DeviceType.desktop:
        return 1.4;
    }
  }

  /// Get HUD element size
  static double getHUDElementSize([BuildContext? context]) {
    final baseSize = hp(6, context);
    final scale = getGameUIScale(context);
    return baseSize * scale;
  }

  /// Get button size for current device
  static double getButtonSize([BuildContext? context]) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return hp(6, context);
      case DeviceType.tablet:
        return hp(5, context);
      case DeviceType.desktop:
        return hp(4, context);
    }
  }

  // ========================================
  // ADAPTIVE LAYOUT UTILITIES
  // ========================================

  /// Get number of columns for grid layouts
  static int getGridColumns([BuildContext? context]) {
    final screenWidth = width(context);
    if (screenWidth < AppConstants.mobileBreakpoint) {
      return 2;
    } else if (screenWidth < AppConstants.tabletBreakpoint) {
      return 3;
    } else if (screenWidth < AppConstants.desktopBreakpoint) {
      return 4;
    } else {
      return 5;
    }
  }

  /// Get optimal padding for current screen
  static double getAdaptivePadding([BuildContext? context]) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return AppConstants.defaultPadding;
      case DeviceType.tablet:
        return AppConstants.largePadding;
      case DeviceType.desktop:
        return AppConstants.extraLargePadding;
    }
  }

  /// Get adaptive margin
  static double getAdaptiveMargin([BuildContext? context]) {
    return getAdaptivePadding(context) * 0.5;
  }

  /// Get adaptive border radius
  static double getAdaptiveBorderRadius([BuildContext? context]) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return AppConstants.buttonBorderRadius;
      case DeviceType.tablet:
        return AppConstants.buttonBorderRadius * 1.2;
      case DeviceType.desktop:
        return AppConstants.buttonBorderRadius * 1.4;
    }
  }

  // ========================================
  // PERFORMANCE OPTIMIZATIONS
  // ========================================

  /// Check if device should use performance mode
  static bool shouldUsePerformanceMode([BuildContext? context]) {
    final deviceType = getDeviceType(context);
    final pixelRatio = ResponsiveUtils.pixelRatio(context);
    
    // Use performance mode on older/slower devices
    return deviceType == DeviceType.mobile && pixelRatio < 2.0;
  }

  /// Get recommended FPS target for device
  static int getRecommendedFPS([BuildContext? context]) {
    if (shouldUsePerformanceMode(context)) {
      return 30; // Lower FPS for performance mode
    }
    return 60; // Standard 60 FPS
  }

  /// Check if device supports advanced graphics
  static bool supportsAdvancedGraphics([BuildContext? context]) {
    final deviceType = getDeviceType(context);
    final pixelRatio = ResponsiveUtils.pixelRatio(context);
    
    return deviceType != DeviceType.mobile || pixelRatio >= 2.0;
  }

  // ========================================
  // SAFE AREA UTILITIES
  // ========================================

  /// Get safe area top padding
  static double getSafeAreaTop(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get safe area bottom padding  
  static double getSafeAreaBottom(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get safe area left padding
  static double getSafeAreaLeft(BuildContext context) {
    return MediaQuery.of(context).padding.left;
  }

  /// Get safe area right padding
  static double getSafeAreaRight(BuildContext context) {
    return MediaQuery.of(context).padding.right;
  }

  /// Get usable screen height (excluding safe areas)
  static double getUsableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;
  }

  /// Get usable screen width (excluding safe areas)
  static double getUsableWidth(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width - mediaQuery.padding.left - mediaQuery.padding.right;
  }

  // ========================================
  // PRIVATE HELPER METHODS
  // ========================================

  /// Calculate device type based on screen size
  static DeviceType _calculateDeviceType(Size screenSize) {
    final shortestSide = math.min(screenSize.width, screenSize.height);
    
    if (shortestSide < AppConstants.mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (shortestSide < AppConstants.tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Calculate screen size category
  static ScreenSize _calculateScreenSizeCategory(Size screenSize) {
    final shortestSide = math.min(screenSize.width, screenSize.height);
    
    if (shortestSide < GameConstants.smallScreenWidth) {
      return ScreenSize.small;
    } else if (shortestSide < GameConstants.mediumScreenWidth) {
      return ScreenSize.medium;
    } else if (shortestSide < GameConstants.largeScreenWidth) {
      return ScreenSize.large;
    } else {
      return ScreenSize.xlarge;
    }
  }

  /// Get scale factor for font sizes
  static double _getScaleFactor(double screenWidth) {
    if (screenWidth < AppConstants.mobileBreakpoint) {
      return 1.0;
    } else if (screenWidth < AppConstants.tabletBreakpoint) {
      return 1.1;
    } else if (screenWidth < AppConstants.desktopBreakpoint) {
      return 1.2;
    } else {
      return 1.3;
    }
  }

  // ========================================
  // DEBUGGING UTILITIES
  // ========================================

  /// Get responsive info for debugging
  static Map<String, dynamic> getResponsiveInfo([BuildContext? context]) {
    _ensureInitialized(context);
    
    return {
      'screenSize': _screenSize?.toString() ?? 'Unknown',
      'deviceType': _deviceType?.name ?? 'Unknown',
      'screenSizeCategory': _screenSizeCategory?.name ?? 'Unknown',
      'orientation': _orientation?.name ?? 'Unknown',
      'pixelRatio': _pixelRatio ?? 0.0,
      'isLandscape': isLandscape(context),
      'isMobile': isMobile(context),
      'isTablet': isTablet(context),
      'isDesktop': isDesktop(context),
      'gridSize': getOptimalGridSize(context),
      'cellSize': getOptimalCellSize(context).toStringAsFixed(1),
      'uiScale': getGameUIScale(context).toStringAsFixed(2),
      'performanceMode': shouldUsePerformanceMode(context),
      'recommendedFPS': getRecommendedFPS(context),
    };
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop;
  
  String get name => toString().split('.').last;
}

/// Screen size category enumeration
enum ScreenSize {
  small,
  medium,
  large,
  xlarge;
  
  String get name => toString().split('.').last;
}

/// Extension methods for BuildContext responsive utilities
extension ResponsiveContext on BuildContext {
  /// Get responsive width percentage
  double get wp => (percentage) => ResponsiveUtils.wp(percentage, this);
  
  /// Get responsive height percentage  
  double get hp => (percentage) => ResponsiveUtils.hp(percentage, this);
  
  /// Get responsive font size
  double get sp => (size) => ResponsiveUtils.sp(size, this);
  
  /// Check if mobile device
  bool get isMobile => ResponsiveUtils.isMobile(this);
  
  /// Check if tablet device
  bool get isTablet => ResponsiveUtils.isTablet(this);
  
  /// Check if desktop device
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  
  /// Check if landscape orientation
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  
  /// Check if portrait orientation
  bool get isPortrait => ResponsiveUtils.isPortrait(this);
  
  /// Get screen width
  double get screenWidth => ResponsiveUtils.width(this);
  
  /// Get screen height
  double get screenHeight => ResponsiveUtils.height(this);
  
  /// Get adaptive padding
  double get adaptivePadding => ResponsiveUtils.getAdaptivePadding(this);
  
  /// Get adaptive margin
  double get adaptiveMargin => ResponsiveUtils.getAdaptiveMargin(this);
  
  /// Get game UI scale
  double get gameUIScale => ResponsiveUtils.getGameUIScale(this);
}