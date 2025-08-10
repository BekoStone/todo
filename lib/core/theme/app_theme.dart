import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import 'colors.dart';

/// AppTheme provides consistent theming across the Box Hooks application.
/// Implements Material Design 3 with custom game branding and responsive design.
/// Optimized for performance with minimal theme rebuilds and efficient color schemes.
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // ========================================
  // COLOR SCHEMES
  // ========================================

  /// Light theme color scheme
  static final ColorScheme _lightColorScheme = ColorScheme.light(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryVariant,
    onPrimaryContainer: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryVariant,
    onSecondaryContainer: AppColors.onSecondary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.onAccent,
    tertiaryContainer: AppColors.accent,
    onTertiaryContainer: AppColors.onAccent,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.error,
    onErrorContainer: AppColors.onError,
    background: AppColors.lightBackground,
    onBackground: AppColors.lightOnBackground,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    outline: AppColors.lightOutline,
    outlineVariant: AppColors.lightOutline,
    shadow: AppColors.lightShadow,
    scrim: AppColors.lightScrim,
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkOnSurface,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  );

  /// Dark theme color scheme
  static final ColorScheme _darkColorScheme = ColorScheme.dark(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryVariant,
    onPrimaryContainer: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryVariant,
    onSecondaryContainer: AppColors.onSecondary,
    tertiary: AppColors.accent,
    onTertiary: AppColors.onAccent,
    tertiaryContainer: AppColors.accent,
    onTertiaryContainer: AppColors.onAccent,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.error,
    onErrorContainer: AppColors.onError,
    background: AppColors.darkBackground,
    onBackground: AppColors.darkOnBackground,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    outline: AppColors.darkOutline,
    outlineVariant: AppColors.darkOutline,
    shadow: AppColors.darkShadow,
    scrim: AppColors.darkScrim,
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightOnSurface,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.primary,
  );

  // ========================================
  // TEXT THEMES
  // ========================================

  /// Base text theme for consistent typography
  static const TextTheme _baseTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
  );

  // ========================================
  // THEME DEFINITIONS
  // ========================================

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      textTheme: _baseTextTheme.apply(
        bodyColor: _lightColorScheme.onSurface,
        displayColor: _lightColorScheme.onSurface,
      ),
      
      // Component themes
      elevatedButtonTheme: _elevatedButtonTheme(_lightColorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(_lightColorScheme),
      textButtonTheme: _textButtonTheme(_lightColorScheme),
      filledButtonTheme: _filledButtonTheme(_lightColorScheme),
      cardTheme: _cardTheme(_lightColorScheme),
      inputDecorationTheme: _inputDecorationTheme(_lightColorScheme),
      appBarTheme: _appBarTheme(_lightColorScheme),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(_lightColorScheme),
      navigationBarTheme: _navigationBarTheme(_lightColorScheme),
      dialogTheme: _dialogTheme(_lightColorScheme),
      snackBarTheme: _snackBarTheme(_lightColorScheme),
      chipTheme: _chipTheme(_lightColorScheme),
      floatingActionButtonTheme: _fabTheme(_lightColorScheme),
      
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
      switchTheme: _switchTheme(_lightColorScheme),
      
      // Slider theme
      sliderTheme: _sliderTheme(_lightColorScheme),
      
      // Progress indicator theme
      progressIndicatorTheme: _progressIndicatorTheme(_lightColorScheme),
      
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
      textTheme: _baseTextTheme.apply(
        bodyColor: _darkColorScheme.onSurface,
        displayColor: _darkColorScheme.onSurface,
      ),
      
      // Component themes
      elevatedButtonTheme: _elevatedButtonTheme(_darkColorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(_darkColorScheme),
      textButtonTheme: _textButtonTheme(_darkColorScheme),
      filledButtonTheme: _filledButtonTheme(_darkColorScheme),
      cardTheme: _cardTheme(_darkColorScheme),
      inputDecorationTheme: _inputDecorationTheme(_darkColorScheme),
      appBarTheme: _appBarTheme(_darkColorScheme),
      bottomNavigationBarTheme: _bottomNavigationBarTheme(_darkColorScheme),
      navigationBarTheme: _navigationBarTheme(_darkColorScheme),
      dialogTheme: _dialogTheme(_darkColorScheme),
      snackBarTheme: _snackBarTheme(_darkColorScheme),
      chipTheme: _chipTheme(_darkColorScheme),
      floatingActionButtonTheme: _fabTheme(_darkColorScheme),
      
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
      switchTheme: _switchTheme(_darkColorScheme),
      
      // Slider theme
      sliderTheme: _sliderTheme(_darkColorScheme),
      
      // Progress indicator theme
      progressIndicatorTheme: _progressIndicatorTheme(_darkColorScheme),
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Platform brightness
      brightness: Brightness.dark,
    );
  }

  // ========================================
  // COMPONENT THEME BUILDERS
  // ========================================

  /// Elevated button theme
  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        minimumSize: const Size(88, AppConstants.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
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
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        minimumSize: const Size(88, AppConstants.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        minimumSize: const Size(88, AppConstants.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Filled button theme
  static FilledButtonThemeData _filledButtonTheme(ColorScheme colorScheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        ),
        minimumSize: const Size(88, AppConstants.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
        textStyle: _baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Card theme
  static CardThemeData _cardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 1,
      shadowColor: colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(AppConstants.smallPadding),
    );
  }

  /// Input decoration theme
  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      labelStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: _baseTextTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha:0.6),
      ),
    );
  }

  /// App bar theme
  static AppBarTheme _appBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 0,
      scrolledUnderElevation: 3,
      shadowColor: colorScheme.shadow,
      centerTitle: true,
      titleTextStyle: _baseTextTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppConstants.normalIconSize,
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
        size: AppConstants.normalIconSize,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppConstants.normalIconSize,
      ),
      selectedLabelStyle: _baseTextTheme.labelSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: _baseTextTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 3,
    );
  }

  /// Navigation bar theme (Material 3)
  static NavigationBarThemeData _navigationBarTheme(ColorScheme colorScheme) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 3,
      shadowColor: colorScheme.shadow,
      height: 80,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _baseTextTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          );
        }
        return _baseTextTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: colorScheme.onSecondaryContainer,
            size: AppConstants.normalIconSize,
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: AppConstants.normalIconSize,
        );
      }),
    );
  }

  /// Dialog theme
  static DialogThemeData _dialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
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
      actionTextColor: colorScheme.inversePrimary,
      disabledActionTextColor: colorScheme.onInverseSurface.withValues(alpha:0.38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    );
  }

  /// Chip theme
  static ChipThemeData _chipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      selectedColor: colorScheme.secondaryContainer,
      deleteIconColor: colorScheme.onSurfaceVariant,
      disabledColor: colorScheme.onSurface.withValues(alpha:0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
      ),
      labelStyle: _baseTextTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.smallPadding),
      side: BorderSide.none,
    );
  }

  /// Floating Action Button theme
  static FloatingActionButtonThemeData _fabTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 6,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
    );
  }

  /// Switch theme
  static SwitchThemeData _switchTheme(ColorScheme colorScheme) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.onPrimary;
        }
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.surface;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        if (states.contains(WidgetState.disabled)) {
          return colorScheme.onSurface.withValues(alpha:0.12);
        }
        return colorScheme.surfaceVariant;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withValues(alpha:0.12);
        }
        return colorScheme.onSurface.withValues(alpha:0.12);
      }),
    );
  }

  /// Slider theme
  static SliderThemeData _sliderTheme(ColorScheme colorScheme) {
    return SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.surfaceVariant,
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha:0.12),
      valueIndicatorColor: colorScheme.primary,
      valueIndicatorTextStyle: _baseTextTheme.bodySmall?.copyWith(
        color: colorScheme.onPrimary,
      ),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    );
  }

  /// Progress indicator theme
  static ProgressIndicatorThemeData _progressIndicatorTheme(ColorScheme colorScheme) {
    return ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceVariant,
      circularTrackColor: colorScheme.surfaceVariant,
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

  /// Get color for block type
  Color getColorForBlockType(String blockType) {
    switch (blockType.toUpperCase()) {
      case 'I': return block1; // Cyan
      case 'O': return block4; // Yellow
      case 'T': return block6; // Purple
      case 'L': return block5; // Orange
      case 'J': return block2; // Blue
      case 'S': return block3; // Green
      case 'Z': return block7; // Red
      default: return block1;
    }
  }
}

/// Extension for accessing theme colors easily
extension AppThemeExtension on ThemeData {
  /// Get game colors
  GameColors get gameColors => AppTheme.gameColors;
  
  /// Get success color
  Color get successColor => AppTheme.successColor;
  
  /// Get warning color
  Color get warningColor => AppTheme.warningColor;
  
  /// Get info color
  Color get infoColor => AppTheme.infoColor;
}