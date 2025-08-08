import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Vibrant and energetic)
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryPink = Color(0xFFFF6B9D);
  static const Color primaryYellow = Color(0xFFFFC947);
  static const Color primaryGreen = Color(0xFF00E676);
  static const Color primaryOrange = Color(0xFFFF9500);
  
  // Secondary Palette
  static const Color secondaryBlue = Color(0xFF5CB3F5);
  static const Color secondaryPurple = Color(0xFF9C88FF);
  static const Color secondaryPink = Color(0xFFFF8FAD);
  static const Color secondaryYellow = Color(0xFFFFD568);
  static const Color secondaryGreen = Color(0xFF33EF8A);
  static const Color secondaryOrange = Color(0xFFFFAB33);
  
  // Block Colors (High contrast and accessible)
  static const List<Color> blockColors = [
    Color(0xFF6C63FF), // Purple
    Color(0xFF4A90E2), // Blue
    Color(0xFFFF6B9D), // Pink
    Color(0xFFFFC947), // Yellow
    Color(0xFF00E676), // Green
    Color(0xFFFF9500), // Orange
    Color(0xFF9C27B0), // Deep Purple
    Color(0xFF2196F3), // Material Blue
    Color(0xFFE91E63), // Pink
    Color(0xFF4CAF50), // Material Green
  ];
  
  // Background Colors
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardDark = Color(0xFF2A2A2A);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  // Surface Colors
  static const Color surfaceDark = Color(0xFF2D2D2D);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceVariantDark = Color(0xFF3A3A3A);
  static const Color surfaceVariantLight = Color(0xFFE8E8E8);
  
  // Text Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textSecondaryLight = Color(0xFF666666);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Special Effects
  static const Color glow = Color(0x44FFFFFF);
  static const Color shadow = Color(0x44000000);
  static const Color highlight = Color(0x33FFFFFF);
  static const Color overlay = Color(0x80000000);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryPurple],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPink, primaryOrange],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF667eea),
      Color(0xFF764ba2),
      Color(0xFF8e44ad),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const RadialGradient buttonGradient = RadialGradient(
    colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 1.0],
  );
  
  // Color Schemes
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryBlue,
    onPrimary: textPrimaryLight,
    secondary: primaryPink,
    onSecondary: textPrimaryLight,
    error: error,
    onError: textPrimaryLight,
    background: backgroundLight,
    onBackground: textPrimaryLight,
    surface: surfaceLight,
    onSurface: textPrimaryLight,
  );
  
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryBlue,
    onPrimary: textPrimaryDark,
    secondary: primaryPink,
    onSecondary: textPrimaryDark,
    error: error,
    onError: textPrimaryDark,
    background: backgroundDark,
    onBackground: textPrimaryDark,
    surface: surfaceDark,
    onSurface: textPrimaryDark,
  );
}