import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import '../constants/app_constants.dart';

/// AppTheme provides consistent theming throughout the Box Hooks application.
/// Defines light and dark themes with proper color schemes, typography, and component styling.
/// Follows Material Design 3 principles with custom game-specific styling.
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // ========================================
  // COLOR SCHEMES
  // ========================================

  /// Light theme color scheme
  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.onAccent,
    error: AppColors.error,
    onError: AppColors.onError,
    background: AppColors.lightBackground,
    onBackground: AppColors.lightOnBackground,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutlineVariant,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkOnSurface,
    inversePrimary: AppColors.primaryVariant,
  );

  /// Dark theme color scheme
  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.onAccent,
    error: AppColors.error,
    onError: AppColors.onError,
    background: AppColors.darkBackground,
    onBackground: AppColors.darkOnBackground,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutlineVariant,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightOnSurface,
    inversePrimary: AppColors.primaryVariant,
  );

  // ========================================
  // TYPOGRAPHY
  // ========================================

  /// Base text theme using Poppins font
  static const TextTheme _baseTextTheme = TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.25,
      height: 1.3,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.3,
    ),
    
    // Headline styles
    headlineLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.4,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.4,
    ),
    
    // Title styles
    titleLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    
    // Label styles
    labelLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.3,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.2,
    ),
    
    // Body styles
    bodyLarge: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.3,
    ),
  );

  // ========================================
  // COMPONENT THEMES
  // ========================================

  /// Elevated button theme
  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        elevation: 2,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        minimumSize: const Size(88, AppConstants.buttonHeight),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Outlined button theme
  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        minimumSize: const Size(88, AppConstants.buttonHeight),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Text button theme
  static TextButtonThemeData _textButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        minimumSize: const Size(64, 36),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Card theme
  static CardTheme _cardTheme(ColorScheme colorScheme) {
    return CardTheme(
      color: colorScheme.surface,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(8),
    );
  }

  /// Input decoration theme
  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      labelStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
      ),
    );
  }

  /// AppBar theme
  static AppBarTheme _appBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _baseTextTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      systemOverlayStyle: colorScheme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );
  }

  /// Bottom navigation bar theme
  static BottomNavigationBarThemeData _bottomNavigationBarTheme(ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedIconTheme: IconThemeData(
        color: colorScheme.primary,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelStyle: _baseTextTheme.labelSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _baseTextTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  /// Dialog theme
  static DialogTheme _dialogTheme(ColorScheme colorScheme) {
    return DialogTheme(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 24,
      shadowColor: colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.modalBorderRadius),
      ),
      titleTextStyle: _baseTextTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Snackbar theme
  static SnackBarThemeData _snackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      actionTextColor: colorScheme.primary,
      disabledActionTextColor: colorScheme.onInverseSurface.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    );
  }

  // ========================================
  // MAIN THEMES
  // ========================================

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      textTheme: _baseTextTheme,
      
      // Component themes
      elevatedButtonTheme: _elevatedButtonTheme(_lightColorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(_lightColorScheme),
      textButtonTheme: _textButtonTheme(_lightColorScheme),
      cardTheme: _cardTheme(_lightColorScheme),
      inputDecorationTheme: _inputDecorationTheme(_lightColorScheme),
      appBarTheme: _appBarTheme(_lightColorScheme),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(_lightColorScheme),
      dialogTheme: _dialogTheme(_lightColorScheme),
      snackBarTheme: _snackBarTheme(_lightColorScheme),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: _lightColorScheme.onSurface,
        size: AppConstants.normalIconSize,
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty .resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightColorScheme.primary;
          }
          return _lightColorScheme.outline;
        }),
        trackColor: WidgetStateProperty .resolveWith((states) {
          if (states.contains(WidgetState .selected)) {
            return _lightColorScheme.primary.withOpacity(0.5);
          }
          return _lightColorScheme.surfaceContainerHighest ;
        }),
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: _lightColorScheme.primary,
        inactiveTrackColor: _lightColorScheme.outline,
        thumbColor: _lightColorScheme.primary,
        overlayColor: _lightColorScheme.primary.withOpacity(0.12),
        valueIndicatorColor: _lightColorScheme.primary,
        valueIndicatorTextStyle: _baseTextTheme.bodySmall?.copyWith(
          color: _lightColorScheme.onPrimary,
        ),
      ),
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Platform brightness
      brightness: Brightness.light,
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      textTheme: _baseTextTheme,
      
      // Component themes
      elevatedButtonTheme: _elevatedButtonTheme(_darkColorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(_darkColorScheme),
      textButtonTheme: _textButtonTheme(_darkColorScheme),
      cardTheme: _cardTheme(_darkColorScheme),
      inputDecorationTheme: _inputDecorationTheme(_darkColorScheme),
      appBarTheme: _appBarTheme(_darkColorScheme),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(_darkColorScheme),
      dialogTheme: _dialogTheme(_darkColorScheme),
      snackBarTheme: _snackBarTheme(_darkColorScheme),
      
      // Icon theme
      iconTheme: IconThemeData(
        color: _darkColorScheme.onSurface,
        size: AppConstants.normalIconSize,
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: _darkColorScheme.outline,
        thickness: 1,
        space: 1,
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty .resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkColorScheme.primary;
          }
          return _darkColorScheme.outline;
        }),
        trackColor: WidgetStateProperty .resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkColorScheme.primary.withOpacity(0.5);
          }
          return _darkColorScheme.surfaceContainerHighest;
        }),
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: _darkColorScheme.primary,
        inactiveTrackColor: _darkColorScheme.outline,
        thumbColor: _darkColorScheme.primary,
        overlayColor: _darkColorScheme.primary.withOpacity(0.12),
        valueIndicatorColor: _darkColorScheme.primary,
        valueIndicatorTextStyle: _baseTextTheme.bodySmall?.copyWith(
          color: _darkColorScheme.onPrimary,
        ),
      ),
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Platform brightness
      brightness: Brightness.dark,
    );
  }

  // ========================================
  // THEME EXTENSIONS
  // ========================================

  /// Game-specific colors that extend the base theme
  static const gameColors = GameColors();

  /// Error color (accessible from anywhere)
  static Color get errorColor => AppColors.error;

  /// Success color (accessible from anywhere)
  static Color get successColor => AppColors.success;

  /// Warning color (accessible from anywhere)
  static Color get warningColor => AppColors.warning;

  /// Info color (accessible from anywhere)
  static Color get infoColor => AppColors.info;
}

/// Game-specific color extension
class GameColors {
  const GameColors();

  // Block colors for the game grid
  final Color block1 = const Color(0xFF4ECDC4); // Teal
  final Color block2 = const Color(0xFF45B7D1); // Blue
  final Color block3 = const Color(0xFF96CEB4); // Green
  final Color block4 = const Color(0xFFFCEAA7); // Yellow
  final Color block5 = const Color(0xFFFFAB91); // Orange
  final Color block6 = const Color(0xFFD1A3FF); // Purple
  final Color block7 = const Color(0xFFFF8A80); // Red
  final Color block8 = const Color(0xFFB39DDB); // Lavender

  // Grid colors
  final Color gridBackground = const Color(0xFF1A1A2E);
  final Color gridBorder = const Color(0xFF16213E);
  final Color cellEmpty = const Color(0xFF0F3460);
  final Color cellHighlight = const Color(0xFF533483);

  // Game UI colors
  final Color gameBackground = const Color(0xFF0F0E23);
  final Color hudBackground = const Color(0xFF16213E);
  final Color scoreText = const Color(0xFF4ECDC4);
  final Color levelText = const Color(0xFF45B7D1);
  final Color powerUpBackground = const Color(0xFF533483);

  /// Get block color by index
  Color getBlockColor(int index) {
    final colors = [
      block1, block2, block3, block4,
      block5, block6, block7, block8,
    ];
    return colors[index % colors.length];
  }
}