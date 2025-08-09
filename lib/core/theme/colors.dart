import 'package:flutter/material.dart';

/// AppColors defines the color palette for the Box Hooks application.
/// Provides consistent colors for both light and dark themes.
/// Follows Material Design 3 color system with custom game branding.
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ========================================
  // PRIMARY COLORS
  // ========================================
  
  /// Primary brand color - Teal
  static const Color primary = Color(0xFF4ECDC4);
  
  /// Primary variant - Darker teal
  static const Color primaryVariant = Color(0xFF26A69A);
  
  /// On primary color - What goes on top of primary
  static const Color onPrimary = Color(0xFF000000);

  // ========================================
  // SECONDARY COLORS
  // ========================================
  
  /// Secondary color - Blue
  static const Color secondary = Color(0xFF45B7D1);
  
  /// Secondary variant - Darker blue
  static const Color secondaryVariant = Color(0xFF1976D2);
  
  /// On secondary color
  static const Color onSecondary = Color(0xFF000000);

  // ========================================
  // ACCENT COLORS
  // ========================================
  
  /// Accent color - Purple
  static const Color accent = Color(0xFF533483);
  
  /// On accent color
  static const Color onAccent = Color(0xFFFFFFFF);

  // ========================================
  // SEMANTIC COLORS
  // ========================================
  
  /// Error color - Red
  static const Color error = Color(0xFFFF5252);
  
  /// On error color
  static const Color onError = Color(0xFFFFFFFF);
  
  /// Success color - Green
  static const Color success = Color(0xFF4CAF50);
  
  /// On success color
  static const Color onSuccess = Color(0xFFFFFFFF);
  
  /// Warning color - Orange
  static const Color warning = Color(0xFFFF9800);
  
  /// On warning color
  static const Color onWarning = Color(0xFF000000);
  
  /// Info color - Light blue
  static const Color info = Color(0xFF2196F3);
  
  /// On info color
  static const Color onInfo = Color(0xFFFFFFFF);

  // ========================================
  // LIGHT THEME COLORS
  // ========================================
  
  /// Light theme background
  static const Color lightBackground = Color(0xFFFAFAFA);
  
  /// Light theme surface
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  /// Light theme surface variant
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);
  
  /// Light theme on background
  static const Color lightOnBackground = Color(0xFF1C1B1F);
  
  /// Light theme on surface
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  
  /// Light theme on surface variant
  static const Color lightOnSurfaceVariant = Color(0xFF49454F);
  
  /// Light theme outline
  static const Color lightOutline = Color(0xFF79747E);
  
  /// Light theme outline variant
  static const Color lightOutlineVariant = Color(0xFFCAC4D0);

  // ========================================
  // DARK THEME COLORS
  // ========================================
  
  /// Dark theme background
  static const Color darkBackground = Color(0xFF0F0E23);
  
  /// Dark theme surface
  static const Color darkSurface = Color(0xFF1A1A2E);
  
  /// Dark theme surface variant
  static const Color darkSurfaceVariant = Color(0xFF16213E);
  
  /// Dark theme on background
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  
  /// Dark theme on surface
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  
  /// Dark theme on surface variant
  static const Color darkOnSurfaceVariant = Color(0xFFCAC4D0);
  
  /// Dark theme outline
  static const Color darkOutline = Color(0xFF938F99);
  
  /// Dark theme outline variant
  static const Color darkOutlineVariant = Color(0xFF49454F);

  // ========================================
  // NEUTRAL COLORS
  // ========================================
  
  /// Shadow color
  static const Color shadow = Color(0xFF000000);
  
  /// Scrim color
  static const Color scrim = Color(0xFF000000);
  
  /// Transparent color
  static const Color transparent = Color(0x00000000);

  // ========================================
  // GAME-SPECIFIC COLORS
  // ========================================
  
  /// Game background color
  static const Color gameBackground = darkBackground;
  
  /// Game grid background
  static const Color gridBackground = Color(0xFF1A1A2E);
  
  /// Game grid border
  static const Color gridBorder = Color(0xFF16213E);
  
  /// Empty cell color
  static const Color cellEmpty = Color(0xFF0F3460);
  
  /// Cell border color
  static const Color cellBorder = Color(0xFF2A2A3E);
  
  /// Cell highlight color (for placement preview)
  static const Color cellHighlight = Color(0xFF533483);
  
  /// HUD background color
  static const Color hudBackground = Color(0xFF16213E);
  
  /// Score text color
  static const Color scoreText = primary;
  
  /// Level text color
  static const Color levelText = secondary;
  
  /// Combo text color
  static const Color comboText = accent;

  // ========================================
  // BLOCK COLORS (8 DISTINCT COLORS)
  // ========================================
  
  /// Block color 1 - Teal
  static const Color block1 = Color(0xFF4ECDC4);
  
  /// Block color 2 - Blue
  static const Color block2 = Color(0xFF45B7D1);
  
  /// Block color 3 - Green
  static const Color block3 = Color(0xFF96CEB4);
  
  /// Block color 4 - Yellow
  static const Color block4 = Color(0xFFFCEAA7);
  
  /// Block color 5 - Orange
  static const Color block5 = Color(0xFFFFAB91);
  
  /// Block color 6 - Purple
  static const Color block6 = Color(0xFFD1A3FF);
  
  /// Block color 7 - Red
  static const Color block7 = Color(0xFFFF8A80);
  
  /// Block color 8 - Lavender
  static const Color block8 = Color(0xFFB39DDB);

  /// List of all block colors for easy iteration
  static const List<Color> blockColors = [
    block1, block2, block3, block4,
    block5, block6, block7, block8,
  ];

  // ========================================
  // POWER-UP COLORS
  // ========================================
  
  /// Undo power-up color
  static const Color powerUpUndo = Color(0xFFFFB74D);
  
  /// Hint power-up color
  static const Color powerUpHint = Color(0xFF81C784);
  
  /// Bomb power-up color
  static const Color powerUpBomb = Color(0xFFE57373);
  
  /// Shuffle power-up color
  static const Color powerUpShuffle = Color(0xFFBA68C8);

  // ========================================
  // UI STATE COLORS
  // ========================================
  
  /// Disabled color
  static const Color disabled = Color(0xFF9E9E9E);
  
  /// Loading color
  static const Color loading = primary;
  
  /// Placeholder color
  static const Color placeholder = Color(0xFFBDBDBD);
  
  /// Divider color
  static const Color divider = Color(0xFFE0E0E0);

  // ========================================
  // GRADIENT COLORS
  // ========================================
  
  /// Primary gradient
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryVariant],
  );
  
  /// Secondary gradient
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryVariant],
  );
  
  /// Game background gradient
  static const Gradient gameBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBackground, darkSurfaceVariant],
  );
  
  /// Button gradient
  static const Gradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // ========================================
  // UTILITY METHODS
  // ========================================
  
  /// Get block color by index (0-7)
  static Color getBlockColor(int index) {
    return blockColors[index % blockColors.length];
  }
  
  /// Get block color with opacity
  static Color getBlockColorWithOpacity(int index, double opacity) {
    return getBlockColor(index).withOpacity(opacity);
  }
  
  /// Get contrasting text color for a given background
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Get color for achievement rarity
  static Color getAchievementRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return const Color(0xFF9E9E9E); // Gray
      case 'rare':
        return const Color(0xFF2196F3); // Blue
      case 'epic':
        return const Color(0xFF9C27B0); // Purple
      case 'legendary':
        return const Color(0xFFFF9800); // Orange
      default:
        return disabled;
    }
  }
  
  /// Get color with brightness adjusted
  static Color adjustBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness * factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Get complementary color
  static Color getComplementaryColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final complementaryHue = (hsl.hue + 180) % 360;
    return hsl.withHue(complementaryHue).toColor();
  }

  // ========================================
  // ACCESSIBILITY COLORS
  // ========================================
  
  /// High contrast text color for accessibility
  static const Color highContrastText = Color(0xFF000000);
  
  /// High contrast background for accessibility
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  
  /// Focus indicator color for accessibility
  static const Color focusIndicator = Color(0xFF1976D2);

  // ========================================
  // ANIMATION COLORS
  // ========================================
  
  /// Particle effect colors
  static const List<Color> particleColors = [
    primary,
    secondary,
    accent,
    Color(0xFFFFD54F), // Amber
    Color(0xFF66BB6A), // Light green
  ];
  
  /// Explosion effect colors
  static const List<Color> explosionColors = [
    Color(0xFFFF5722), // Deep orange
    Color(0xFFFF9800), // Orange
    Color(0xFFFFC107), // Amber
    Color(0xFFFFEB3B), // Yellow
  ];
}