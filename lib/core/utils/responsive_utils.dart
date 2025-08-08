import 'package:flutter/material.dart';
import '../theme/responsive_config.dart';
import '../constants/game_constants.dart';

class ResponsiveUtils {
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
    final adjustedCellSize = (maxGridSize - (GameConstants.gridSize - 1) * gridConfig.spacing) / GameConstants.gridSize;
    
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
    final basePadding = EdgeInsets.only(
      top: mediaQuery.viewPadding.top,
      bottom: mediaQuery.viewPadding.bottom,
      left: ResponsiveConfig.getPadding(context),
      right: ResponsiveConfig.getPadding(context),
    );
    
    if (additional != null) {
      return basePadding.add(additional);
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
    
    // Scale based on device type (assume mobile might need slightly faster)
    final deviceType = ResponsiveConfig.getDeviceType(context);
    if (deviceType == DeviceType.mobile) {
      duration = Duration(milliseconds: (duration.inMilliseconds * 0.9).round());
    }
    
    // Respect accessibility settings
    if (respectAccessibility) {
      final mediaQuery = MediaQuery.of(context);
      final reduceAnimations = mediaQuery.disableAnimations;
      if (reduceAnimations) {
        return Duration(milliseconds: (duration.inMilliseconds * 0.3).round());
      }
    }
    
    return duration;
  }
  
  // Check if device can handle complex animations
  static bool canHandleComplexAnimations(BuildContext context) {
    final deviceType = ResponsiveConfig.getDeviceType(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Disable complex animations for accessibility or low-end devices
    if (mediaQuery.disableAnimations) return false;
    if (deviceType == DeviceType.mobile && MediaQuery.of(context).size.width < 375) {
      return false; // Very small screens
    }
    
    return true;
  }
  
  // Get optimal particle count based on device
  static int getOptimalParticleCount(BuildContext context) {
    final deviceType = ResponsiveConfig.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 10;
      case DeviceType.tablet:
        return 15;
      case DeviceType.desktop:
        return 20;
    }
  }
}

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
  
  // Calculate grid position on screen
  Offset get gridPosition {
    final gridSize = gridConfig.totalGridSize;
    final x = (screenSize.width - gridSize) / 2;
    final y = hudHeight + ((screenSize.height - hudHeight - slotsHeight - powerUpHeight - gridSize) / 2);
    
    return Offset(x, y);
  }
  
  // Calculate slots position
  Offset get slotsPosition {
    return Offset(
      sideMargin,
      screenSize.height - slotsHeight - ResponsiveUtils.scale(null, 20),
    );
  }
  
  // Calculate power-up panel position
  Offset get powerUpPosition {
    return Offset(
      sideMargin,
      screenSize.height - slotsHeight - powerUpHeight - ResponsiveUtils.scale(null, 10),
    );
  }
}

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
  
  // Get position for slot at index
  Offset getSlotPosition(int index) {
    final x = centerOffset + (index * (slotSize.width + spacing));
    return Offset(x, 0);
  }
}