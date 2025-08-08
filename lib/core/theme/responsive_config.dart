import 'package:flutter/material.dart';

class ResponsiveConfig {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Device Types
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }
  
  // Responsive Values
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }
  
  // Grid Configuration
  static GridConfig getGridConfig(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final deviceType = getDeviceType(context);
    
    // Calculate optimal cell size based on screen dimensions
    final availableWidth = size.width - (2 * getPadding(context));
    final availableHeight = size.height * 0.6; // Reserve space for UI
    
    final maxGridSize = availableWidth < availableHeight 
        ? availableWidth 
        : availableHeight;
        
    final cellSize = (maxGridSize - (7 * 3)) / 8; // 8 cells, 7 gaps of 3px
    
    return GridConfig(
      cellSize: cellSize.clamp(32.0, 56.0), // Min 32, Max 56
      spacing: deviceType == DeviceType.mobile ? 2.0 : 3.0,
      padding: getPadding(context),
    );
  }
  
  // UI Dimensions
  static double getPadding(BuildContext context) {
    return responsive(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);
  }
  
  static double getMargin(BuildContext context) {
    return responsive(context, mobile: 8.0, tablet: 12.0, desktop: 16.0);
  }
  
  static double getBorderRadius(BuildContext context) {
    return responsive(context, mobile: 8.0, tablet: 12.0, desktop: 16.0);
  }
  
  static double getIconSize(BuildContext context) {
    return responsive(context, mobile: 24.0, tablet: 28.0, desktop: 32.0);
  }
  
  static double getButtonHeight(BuildContext context) {
    return responsive(context, mobile: 48.0, tablet: 56.0, desktop: 64.0);
  }
  
  // Typography Scaling
  static double getTextScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
    }
  }
  
  // Layout Configurations
  static LayoutConfig getLayoutConfig(BuildContext context) {
    final deviceType = getDeviceType(context);
    final size = MediaQuery.of(context).size;
    
    return LayoutConfig(
      deviceType: deviceType,
      screenSize: size,
      isLandscape: size.width > size.height,
      safeAreaInsets: MediaQuery.of(context).viewInsets,
      appBarHeight: responsive(context, mobile: 56.0, tablet: 64.0, desktop: 72.0),
      bottomBarHeight: responsive(context, mobile: 80.0, tablet: 90.0, desktop: 100.0),
      sideMargin: getPadding(context),
    );
  }
}

enum DeviceType { mobile, tablet, desktop }

class GridConfig {
  final double cellSize;
  final double spacing;
  final double padding;
  
  const GridConfig({
    required this.cellSize,
    required this.spacing,
    required this.padding,
  });
  
  double get totalGridSize => (cellSize * 8) + (spacing * 7);
}

class LayoutConfig {
  final DeviceType deviceType;
  final Size screenSize;
  final bool isLandscape;
  final EdgeInsets safeAreaInsets;
  final double appBarHeight;
  final double bottomBarHeight;
  final double sideMargin;
  
  const LayoutConfig({
    required this.deviceType,
    required this.screenSize,
    required this.isLandscape,
    required this.safeAreaInsets,
    required this.appBarHeight,
    required this.bottomBarHeight,
    required this.sideMargin,
  });
  
  double get availableHeight => 
      screenSize.height - appBarHeight - bottomBarHeight - safeAreaInsets.vertical;
      
  double get availableWidth => 
      screenSize.width - (sideMargin * 2) - safeAreaInsets.horizontal;
}