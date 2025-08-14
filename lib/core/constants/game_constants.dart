import 'package:flutter/material.dart';

class GameConstants {
  GameConstants._();

  // Grid
  static const int gridRows = 8;
  static const int gridCols = 8;
  static const double cellSize = 48.0;

  // UI layout (sticky panels)
  static const double topPadding = 16.5;
  static const double gridGapToPanel = 8.0;
  static const double panelHeight = 56.0; // power-up panel height
  static const double panelGapToDock = 8.0;
  static const double dockHeight = 140.0;
  static const double dockPadding = 12.0;

  // Rendering
  static const double shapeCellPadding = 2.0;
  static const Color shapeFillColor = Color(0xFF6A5AE0); // ← single color for all blocks

  // Drag
  static const double dragSnapThreshold = 0.4;

  // Particles (future)
  static const int particlePoolSize = 128;
  static const int particleBurstMax = 20;

  // Audio
  static const double sfxVolume = 0.7;
  static const double musicVolume = 0.4;

  // Ads
  static const double adBannerHeight = 60.0;
  static const double adBottomExtraPadding = 12.0; // ensure visible

  /// 🎨 Available random colors for shape pieces
  static const List<Color> shapeColors = [
    Color(0xFFE57373), // red
    Color(0xFF64B5F6), // blue
    Color(0xFF81C784), // green
    Color(0xFFFFD54F), // yellow
    Color(0xFFBA68C8), // purple
    Color(0xFFFFB74D), // orange
  ];
}
