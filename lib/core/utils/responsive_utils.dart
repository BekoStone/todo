import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Responsive utility class for handling different screen sizes and orientations.
/// Provides consistent sizing, spacing, and layout calculations across devices.
/// Optimized for puzzle game UI with focus on mobile-first design.
class ResponsiveUtils {
  // Private constructor to prevent instantiation
  ResponsiveUtils._();

  // Cached values for performance optimization
  static Size? _screenSize;
  static MediaQueryData? _mediaQueryData;
  static double? _scaleFactor;
  static DeviceType? _deviceType;
  static bool _isInitialized = false;

  // Base design dimensions (iPhone 12 Pro as reference)
  static const double _baseWidth = 390.0;
  static const double _baseHeight = 844.0;
  static const double _baseDensity = 3.0;

  /// Initialize responsive utilities with MediaQuery data
  static void initialize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _mediaQueryData = mediaQuery;
    _screenSize = mediaQuery.size;
    _scaleFactor = _calculateScaleFactor();
    _deviceType = _determineDeviceType();
    _isInitialized = true;
  }

  /// Ensure initialization before use
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('ResponsiveUtils not initialized. Call initialize(context) first.');
    }
  }

  // ========================================
  // DIMENSION CALCULATIONS
  // ========================================

  /// Get screen width
  static double get screenWidth {
    _ensureInitialized();
    return _screenSize!.width;
  }

  /// Get screen height
  static double get screenHeight {
    _ensureInitialized();
    return _screenSize!.height;
  }

  /// Get device pixel ratio
  static double get pixelRatio {
    _ensureInitialized();
    return _mediaQueryData!.devicePixelRatio;
  }

  /// Get text scale factor
  static double get textScaleFactor {
    _ensureInitialized();
    return _mediaQueryData!.textScaleFactor.clamp(0.8, 1.3);
  }

  /// Get status bar height
  static double get statusBarHeight {
    _ensureInitialized();
    return _mediaQueryData!.padding.top;
  }

  /// Get bottom safe area height
  static double get bottomSafeArea {
    _ensureInitialized();
    return _mediaQueryData!.padding.bottom;
  }

  /// Get keyboard height
  static double get keyboardHeight {
    _ensureInitialized();
    return _mediaQueryData!.viewInsets.bottom;
  }

  // ========================================
  // RESPONSIVE SIZING
  // ========================================

  /// Width percentage of screen
  static double wp(double percentage) {
    _ensureInitialized();
    return (screenWidth * percentage) / 100;
  }

  /// Height percentage of screen
  static double hp(double percentage) {
    _ensureInitialized();
    return (screenHeight * percentage) / 100;
  }

  /// Responsive width based on design width
  static double rw(double designWidth) {
    _ensureInitialized();
    return (designWidth / _baseWidth) * screenWidth;
  }

  /// Responsive height based on design height
  static double rh(double designHeight) {
    _ensureInitialized();
    return (designHeight / _baseHeight) * screenHeight;
  }

  /// Responsive font size with automatic scaling
  static double sp(double fontSize) {
    _ensureInitialized();
    final scaledSize = (fontSize / _baseWidth) * screenWidth;
    final textScaled = scaledSize * textScaleFactor;
    
    // Apply device-specific adjustments
    double adjustmentFactor = 1.0;
    switch (_deviceType!) {
      case DeviceType.mobile:
        adjustmentFactor = 1.0;
        break;
      case DeviceType.tablet:
        adjustmentFactor = 0.9; // Slightly smaller on tablets
        break;
      case DeviceType.desktop:
        adjustmentFactor = 0.8; // Smaller on desktop
        break;
    }
    
    return textScaled * adjustmentFactor;
  }

  /// Responsive radius
  static double radius(double designRadius) {
    _ensureInitialized();
    return (designRadius * _scaleFactor!).clamp(2.0, 30.0);
  }

  /// Responsive border width
  static double borderWidth(double designWidth) {
    _ensureInitialized();
    return (designWidth * _scaleFactor!).clamp(0.5, 4.0);
  }

  // ========================================
  // DEVICE TYPE DETECTION
  // ========================================

  /// Check if device is mobile
  static bool isMobile(BuildContext? context) {
    if (context != null && !_isInitialized) {
      initialize(context);
    }
    _ensureInitialized();
    return _deviceType == DeviceType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext? context) {
    if (context != null && !_isInitialized) {
      initialize(context);
    }
    _ensureInitialized();
    return _deviceType == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext? context) {
    if (context != null && !_isInitialized) {
      initialize(context);
    }
    _ensureInitialized();
    return _deviceType == DeviceType.desktop;
  }

  /// Check if screen is in landscape mode
  static bool isLandscape() {
    _ensureInitialized();
    return screenWidth > screenHeight;
  }

  /// Check if screen is in portrait mode
  static bool isPortrait() {
    _ensureInitialized();
    return screenHeight > screenWidth;
  }

  // ========================================
  // GAME-SPECIFIC CONFIGURATIONS
  // ========================================

  /// Get game configuration based on screen size
  static GameConfig getGameConfig(Size screenSize) {
    // Calculate optimal grid size and cell size for the screen
    final availableWidth = screenSize.width * 0.9; // Leave 10% padding
    final availableHeight = screenSize.height * 0.6; // Leave space for UI
    
    final maxDimension = math.min(availableWidth, availableHeight);
    final gridSize = AppConstants.gridSize;
    final cellSize = (maxDimension - (gridSize - 1) * AppConstants.cellSpacing) / gridSize;
    
    // Ensure minimum cell size for usability
    final adjustedCellSize = math.max(cellSize, 30.0);
    final totalGridSize = adjustedCellSize * gridSize + (gridSize - 1) * AppConstants.cellSpacing;
    
    // Calculate scale factor for responsive adjustments
    final scale = _calculateGameScale(screenSize);
    
    return GameConfig(
      gridSize: gridSize,
      cellSize: adjustedCellSize,
      gridSpacing: AppConstants.cellSpacing,
      totalGridSize: totalGridSize,
      scale: scale,
    );
  }

  /// Calculate game-specific scale factor
  static double _calculateGameScale(Size screenSize) {
    final baseArea = _baseWidth * _baseHeight;
    final currentArea = screenSize.width * screenSize.height;
    final areaRatio = currentArea / baseArea;
    
    // Apply logarithmic scaling to prevent extreme scaling
    return math.pow(areaRatio, 0.3).clamp(0.8, 1.5).toDouble();
  }

  // ========================================
  // LAYOUT HELPERS
  // ========================================

  /// Get optimal padding for current device
  static EdgeInsets getDefaultPadding() {
    _ensureInitialized();
    
    switch (_deviceType!) {
      case DeviceType.mobile:
        return EdgeInsets.all(wp(4));
      case DeviceType.tablet:
        return EdgeInsets.all(wp(3));
      case DeviceType.desktop:
        return EdgeInsets.all(wp(2));
    }
  }

  /// Get optimal margin for current device
  static EdgeInsets getDefaultMargin() {
    _ensureInitialized();
    
    switch (_deviceType!) {
      case DeviceType.mobile:
        return EdgeInsets.all(wp(2));
      case DeviceType.tablet:
        return EdgeInsets.all(wp(1.5));
      case DeviceType.desktop:
        return EdgeInsets.all(wp(1));
    }
  }

  /// Get content max width for better readability
  static double getContentMaxWidth() {
    _ensureInitialized();
    
    switch (_deviceType!) {
      case DeviceType.mobile:
        return screenWidth;
      case DeviceType.tablet:
        return math.min(screenWidth * 0.8, 600);
      case DeviceType.desktop:
        return math.min(screenWidth * 0.6, 800);
    }
  }

  /// Get button height for current device
  static double getButtonHeight() {
    _ensureInitialized();
    return hp(6).clamp(44.0, 60.0); // iOS/Android standards
  }

  /// Get icon size for current device
  static double getIconSize(IconSize size) {
    _ensureInitialized();
    
    switch (size) {
      case IconSize.small:
        return sp(16);
      case IconSize.medium:
        return sp(24);
      case IconSize.large:
        return sp(32);
      case IconSize.extraLarge:
        return sp(48);
    }
  }

  // ========================================
  // PRIVATE HELPERS
  // ========================================

  /// Calculate overall scale factor
  static double _calculateScaleFactor() {
    final widthRatio = screenWidth / _baseWidth;
    final heightRatio = screenHeight / _baseHeight;
    return math.sqrt(widthRatio * heightRatio).clamp(0.8, 2.0);
  }

  /// Determine device type based on screen size
  static DeviceType _determineDeviceType() {
    final diagonal = math.sqrt(
      math.pow(screenWidth, 2) + math.pow(screenHeight, 2)
    ) / pixelRatio;
    
    if (diagonal < 7) {
      return DeviceType.mobile;
    } else if (diagonal < 13) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Get safe area constraints
  static BoxConstraints getSafeConstraints() {
    _ensureInitialized();
    
    return BoxConstraints(
      minWidth: 0,
      maxWidth: screenWidth,
      minHeight: 0,
      maxHeight: screenHeight - statusBarHeight - bottomSafeArea,
    );
  }

  /// Check if device has notch or dynamic island
  static bool hasNotch() {
    _ensureInitialized();
    return statusBarHeight > 24; // Standard status bar height
  }

  /// Get optimal grid columns for current screen
  static int getOptimalColumns(double itemWidth, {double spacing = 16}) {
    _ensureInitialized();
    
    final availableWidth = screenWidth - wp(8); // Account for padding
    final itemWithSpacing = itemWidth + spacing;
    final columns = (availableWidth / itemWithSpacing).floor();
    
    return math.max(1, columns);
  }

  /// Get debug info for development
  static Map<String, dynamic> getDebugInfo() {
    if (!_isInitialized) return {'error': 'Not initialized'};
    
    return {
      'screenSize': '${screenWidth.toStringAsFixed(1)} x ${screenHeight.toStringAsFixed(1)}',
      'deviceType': _deviceType.toString(),
      'scaleFactor': _scaleFactor!.toStringAsFixed(2),
      'pixelRatio': pixelRatio.toStringAsFixed(2),
      'textScaleFactor': textScaleFactor.toStringAsFixed(2),
      'statusBarHeight': statusBarHeight.toStringAsFixed(1),
      'bottomSafeArea': bottomSafeArea.toStringAsFixed(1),
      'isLandscape': isLandscape(),
      'hasNotch': hasNotch(),
    };
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Icon size enumeration
enum IconSize {
  small,
  medium,
  large,
  extraLarge,
}

/// Game configuration class
class GameConfig {
  final int gridSize;
  final double cellSize;
  final double gridSpacing;
  final double totalGridSize;
  final double scale;

  const GameConfig({
    required this.gridSize,
    required this.cellSize,
    required this.gridSpacing,
    required this.totalGridSize,
    required this.scale,
  });

  @override
  String toString() {
    return 'GameConfig(gridSize: $gridSize, cellSize: ${cellSize.toStringAsFixed(1)}, '
           'totalSize: ${totalGridSize.toStringAsFixed(1)}, scale: ${scale.toStringAsFixed(2)})';
  }
}