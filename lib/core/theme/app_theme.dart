import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(AppColors.lightColorScheme);
  static ThemeData get darkTheme => _buildTheme(AppColors.darkColorScheme);
  
  // MISSING PROPERTIES - ADD THESE FOR COMPILATION
  /// Primary color - maps to AppColors.primaryBlue
  static Color get primaryColor => AppColors.primaryBlue;
  
  /// Accent color - maps to AppColors.primaryPink  
  static Color get accentColor => AppColors.primaryPink;
  
  /// Surface color - maps to AppColors.surfaceDark
  static Color get surfaceColor => AppColors.surfaceDark;
  
  /// Background color - maps to AppColors.backgroundDark
  static Color get backgroundColor => AppColors.backgroundDark;
  
  /// Error color - maps to AppColors.error
  static Color get errorColor => AppColors.error;
  
  /// Success color - maps to AppColors.success  
  static Color get successColor => AppColors.success;
  
  /// Warning color - maps to AppColors.warning
  static Color get warningColor => AppColors.warning;
  
  /// Info color - maps to AppColors.info
  static Color get infoColor => AppColors.info;
  
  // GRADIENT PROPERTIES
  /// Primary gradient
  static LinearGradient get primaryGradient => AppColors.primaryGradient;
  
  /// Secondary gradient
  static LinearGradient get secondaryGradient => AppColors.secondaryGradient;
  
  /// Background gradient
  static LinearGradient get backgroundGradient => AppColors.backgroundGradient;
  
  /// Surface gradient for overlays
  static LinearGradient get surfaceGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.surfaceDark,
      AppColors.surfaceDark.withOpacity(0.95),
      AppColors.cardDark,
    ],
  );
  
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.fredoka().fontFamily,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: _titleTextStyle(colorScheme),
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.fredoka(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      
      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(48, 48),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        elevation: 8,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: _titleTextStyle(colorScheme),
        contentTextStyle: _bodyTextStyle(colorScheme),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      
      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        contentTextStyle: GoogleFonts.fredoka(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.fredoka(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.black12,
        thickness: 1,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: _titleTextStyle(colorScheme),
        subtitleTextStyle: _bodyTextStyle(colorScheme),
      ),
    );
  }
  
  // Custom Text Styles
  static TextStyle _titleTextStyle(ColorScheme colorScheme) {
    return GoogleFonts.fredoka(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: colorScheme.onBackground,
      shadows: [
        Shadow(
          offset: const Offset(1, 1),
          blurRadius: 2,
          color: Colors.black.withOpacity(0.2),
        ),
      ],
    );
  }
  
  static TextStyle _bodyTextStyle(ColorScheme colorScheme) {
    return GoogleFonts.fredoka(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: colorScheme.onSurface,
    );
  }
  
  // MISSING TEXT STYLES - ADD THESE FOR COMPILATION
  /// Headline text style
  static TextStyle get headlineStyle => GoogleFonts.fredoka(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      const Shadow(
        offset: Offset(2, 2),
        blurRadius: 4,
        color: Colors.black38,
      ),
    ],
  );
  
  /// Title text style  
  static TextStyle get titleStyle => GoogleFonts.fredoka(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    shadows: [
      const Shadow(
        offset: Offset(1, 1),
        blurRadius: 2,
        color: Colors.black26,
      ),
    ],
  );
  
  /// Body text style
  static TextStyle get bodyStyle => GoogleFonts.fredoka(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );
  
  /// Button text style
  static TextStyle get buttonStyle => GoogleFonts.fredoka(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // Game-specific styles
  static TextStyle get scoreStyle => GoogleFonts.fredoka(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      const Shadow(
        offset: Offset(2, 2),
        blurRadius: 4,
        color: Colors.black38,
      ),
    ],
  );
  
  static TextStyle get levelStyle => GoogleFonts.fredoka(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    shadows: [
      const Shadow(
        offset: Offset(1, 1),
        blurRadius: 2,
        color: Colors.black26,
      ),
    ],
  );
  
  static TextStyle get comboStyle => GoogleFonts.fredoka(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryYellow,
    shadows: [
      Shadow(
        offset: const Offset(1, 1),
        blurRadius: 3,
        color: AppColors.primaryOrange.withOpacity(0.5),
      ),
    ],
  );
  
  // Button Decorations
  static BoxDecoration gameButtonDecoration({
    required Color color,
    bool isPressed = false,
    bool isDisabled = false,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDisabled
            ? [Colors.grey.shade400, Colors.grey.shade600]
            : isPressed
                ? [color.withOpacity(0.7), color.withOpacity(0.9)]
                : [color, color.withOpacity(0.8)],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDisabled 
            ? Colors.grey.shade500
            : color.withOpacity(0.8),
        width: 2,
      ),
      boxShadow: isDisabled
          ? null
          : [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: isPressed ? 4 : 8,
                offset: Offset(0, isPressed ? 2 : 4),
              ),
            ],
    );
  }
  
  // Game background decoration
  static BoxDecoration get gameBackgroundDecoration => const BoxDecoration(
    gradient: AppColors.backgroundGradient,
  );
  
  // Overlay decorations
  static BoxDecoration overlayDecoration({
    Color? color,
    double opacity = 0.9,
  }) {
    return BoxDecoration(
      color: (color ?? AppColors.backgroundDark).withOpacity(opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.primaryBlue.withOpacity(0.3),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}