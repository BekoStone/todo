import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Responsive utility class providing consistent scaling and layout calculations
/// across different device sizes and orientations.
/// Uses static methods for optimal performance and memory usage.
class ResponsiveUtils {
  // Private constructor to prevent instantiation
  ResponsiveUtils._();
  
  // Cache for performance optimization
  static MediaQueryData? _cachedMediaQuery;
  static Size? _cachedScreenSize;
  static DeviceType? _cachedDeviceType;
  static GameConfig? _cachedGameConfig;

  /// Initialize responsive utils with context (call once during app startup)
  static void initialize(BuildContext context) {
    _cachedMediaQuery = MediaQuery.of(context);
    _updateCache();
  }

  /// Update cached values when screen changes
  static void _updateCache() {
    if (_cachedMediaQuery == null) return;
    
    _cachedScreenSize = _cachedMediaQuery!.size;
    _cachedDeviceType = _calculateDeviceType(_cachedScreenSize!);
    _cachedGameConfig = _calculateGameConfig(_cachedScreenSize!);
  }

  /// Force refresh cache (call when orientation changes)
  static void refresh(BuildContext context) {
    _cachedMediaQuery = MediaQuery.of(context);
    _updateCache();
  }

  // ========================================
  // DEVICE TYPE DETECTION
  // ========================================

  /// Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    _cachedMediaQuery ??= MediaQuery.of(context);
    return _cachedDeviceType ?? _calculateDeviceType(_cachedMediaQuery!.size);
  }

  /// Calculate device type based on screen size
  static DeviceType _calculateDeviceType(Size screenSize) {
    final width = screenSize.width;
    final height = screenSize.height;
    final diagonal = math.sqrt(width * width + height * height);
    
    // Use diagonal and width for better classification
    if (width < AppConstants.mobileBreakpoint || diagonal < 700) {
      return DeviceType.mobile;
    } else if (width < AppConstants.tabletBreakpoint || diagonal < 1100) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }

  // ========================================
  // SCREEN DIMENSIONS
  // ========================================

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return !isLandscape(context);
  }

  // ========================================
  // RESPONSIVE SCALING
  // ========================================

  /// Scale value based on device type
  static double scale(BuildContext context, double value) {
    final deviceType = getDeviceType(context);
    final scaleFactor = AppConstants.scalingFactors[deviceType.name] ?? 1.0;
    return value * scaleFactor;
  }

  /// Scale font size with device type and accessibility settings
  static double scaleFontSize(BuildContext context, double fontSize) {
    final mediaQuery = MediaQuery.of(context);
    final deviceScale = scale(context, 1.0);
    final accessibilityScale = mediaQuery.textScaler.scale(1.0);
    
    // Combine device scaling with accessibility scaling
    return fontSize * deviceScale * accessibilityScale;
  }

  /// Get responsive padding based on device type
  static EdgeInsets getPadding(BuildContext context, {
    double mobile = AppConstants.defaultPadding,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    final padding = switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile * 1.2,
      DeviceType.desktop => desktop ?? tablet ?? mobile * 1.5,
    };
    
    return EdgeInsets.all(padding);
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {
    double mobile = AppConstants.defaultPadding,
    double? tablet,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    return switch (deviceType) {
      DeviceType.mobile => mobile,
      DeviceType.tablet => tablet ?? mobile * 1.2,
      DeviceType.desktop => desktop ?? tablet ?? mobile * 1.5,
    };
  }

  // ========================================
  // RESPONSIVE BREAKPOINTS
  // ========================================

  /// Get responsive breakpoint
  static ResponsiveBreakpoint getBreakpoint(BuildContext context) {
    final width = getScreenWidth(context);
    
    if (width < AppConstants.mobileBreakpoint) {
      return ResponsiveBreakpoint.mobile;
    } else if (width < AppConstants.tabletBreakpoint) {
      return ResponsiveBreakpoint.tablet;
    } else {
      return ResponsiveBreakpoint.desktop;
    }
  }

  /// Build responsive widget based on breakpoints
  static Widget buildResponsiveWidget({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final breakpoint = getBreakpoint(context);
    return switch (breakpoint) {
      ResponsiveBreakpoint.mobile => mobile,
      ResponsiveBreakpoint.tablet => tablet ?? mobile,
      ResponsiveBreakpoint.desktop => desktop ?? tablet ?? mobile,
    };
  }

  // ========================================
  // GAME-SPECIFIC CALCULATIONS
  // ========================================

  /// Get game configuration for current screen size
  static GameConfig getGameConfig(Size screenSize) {
    // Use cached config if available and screen size hasn't changed
    if (_cachedGameConfig != null && _cachedScreenSize == screenSize) {
      return _cachedGameConfig!;
    }
    
    return _calculateGameConfig(screenSize);
  }

  /// Calculate game configuration based on screen size
  static GameConfig _calculateGameConfig(Size screenSize) {
    final deviceType = _calculateDeviceType(screenSize);
    final minDimension = math.min(screenSize.width, screenSize.height);
    
    // Calculate optimal cell size for the grid
    final availableSpace = minDimension - (AppConstants.gridPadding * 2);
    final totalSpacing = (AppConstants.gridSize - 1) * AppConstants.cellSpacing;
    final cellSize = (availableSpace - totalSpacing) / AppConstants.gridSize;
    
    // Ensure minimum cell size for usability
    final minCellSize = switch (deviceType) {
      DeviceType.mobile => 32.0,
      DeviceType.tablet => 40.0,
      DeviceType.desktop => 48.0,
    };
    
    final finalCellSize = math.max(cellSize, minCellSize);
    
    return GameConfig(
      gridSize: AppConstants.gridSize,
      cellSize: finalCellSize,
      deviceType: deviceType,
      screenSize: screenSize,
    );
  }

  /// Get game layout configuration
  static GameLayout getGameLayout(BuildContext context) {
    final screenSize = getScreenSize(context);
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);
    
    // Calculate layout dimensions
    final gameConfig = getGameConfig(screenSize);
    final gridTotalSize = (gameConfig.cellSize * AppConstants.gridSize) + 
                         ((AppConstants.gridSize - 1) * AppConstants.cellSpacing);
    
    // Calculate UI element heights
    final hudHeight = switch (deviceType) {
      DeviceType.mobile => 80.0,
      DeviceType.tablet => 100.0,
      DeviceType.desktop => 120.0,
    };
    
    final slotsHeight = switch (deviceType) {
      DeviceType.mobile => 120.0,
      DeviceType.tablet => 140.0,
      DeviceType.desktop => 160.0,
    };
    
    final powerUpHeight = switch (deviceType) {
      DeviceType.mobile => 60.0,
      DeviceType.tablet => 70.0,
      DeviceType.desktop => 80.0,
    };
    
    final sideMargin = switch (deviceType) {
      DeviceType.mobile => 16.0,
      DeviceType.tablet => 24.0,
      DeviceType.desktop => 32.0,
    };
    
    return GameLayout(
      screenSize: screenSize,
      deviceType: deviceType,
      gridConfig: gameConfig,
      hudHeight: hudHeight,
      slotsHeight: slotsHeight,
      powerUpHeight: powerUpHeight,
      sideMargin: sideMargin,
      isLandscape: isLandscapeMode,
    );
  }

  /// Get slot layout configuration
  static SlotLayout getSlotLayout(BuildContext context, int slotCount) {
    final screenSize = getScreenSize(context);
    final deviceType = getDeviceType(context);
    
    // Calculate slot size
    final baseSlotSize = switch (deviceType) {
      DeviceType.mobile => 80.0,
      DeviceType.tablet => 100.0,
      DeviceType.desktop => 120.0,
    };
    
    final spacing = switch (deviceType) {
      DeviceType.mobile => 12.0,
      DeviceType.tablet => 16.0,
      DeviceType.desktop => 20.0,
    };
    
    final totalWidth = (baseSlotSize * slotCount) + (spacing * (slotCount - 1));
    final centerOffset = (screenSize.width - totalWidth) / 2;
    
    return SlotLayout(
      slotSize: Size(baseSlotSize, baseSlotSize),
      spacing: spacing,
      totalWidth: totalWidth,
      centerOffset: centerOffset,
    );
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Get safe area insets
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get bottom safe area height
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get top safe area height
  static double getTopSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Check if device has notch
  static bool hasNotch(BuildContext context) {
    return getTopSafeArea(context) > 24;
  }

  /// Get device pixel ratio
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop;
  
  String get name => toString().split('.').last;
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
  final GameConfig gridConfig;
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

  /// Get total game area height
  double get totalGameHeight => 
      hudHeight + gridConfig.totalGridSize + slotsHeight + powerUpHeight;

  /// Check if layout fits in screen
  bool get fitsInScreen => totalGameHeight <= screenSize.height;
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

  /// Get total grid size including spacing
  double get totalGridSize {
    return (cellSize * gridSize) + ((gridSize - 1) * AppConstants.cellSpacing);
  }

  /// Get grid bounds
  Rect get gridBounds {
    final totalSize = totalGridSize;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: totalSize,
      height: totalSize,
    );
  }
}