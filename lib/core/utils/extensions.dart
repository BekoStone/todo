import 'package:flutter/material.dart';
import 'package:flame/components.dart';

extension ContextExtensions on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  
  // Size shortcuts
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  
  // Responsive helpers
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;
  bool get isLandscape => screenWidth > screenHeight;
  
  // Navigation shortcuts
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> push<T>(Widget page) => Navigator.of(this).push(
        MaterialPageRoute(builder: (_) => page),
      );
  Future<T?> pushReplacement<T>(Widget page) =>
      Navigator.of(this).pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );
  
  // Snackbar helper
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

extension ColorExtensions on Color {
  // Darken/Lighten colors
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
  
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
  
  // Get contrasting text color
  Color get textColor {
    return computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
  
  // Create material color from single color
  MaterialColor get materialColor {
    final swatch = <int, Color>{};
    final r = red, g = green, b = blue;
    
    for (final strength in [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]) {
      final double ds = 0.5 - strength / 1000;
      swatch[strength] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    
    return MaterialColor(value, swatch);
  }
}

extension ListExtensions<T> on List<T> {
  // Get random element
  T get random {
    if (isEmpty) throw StateError('Cannot get random element from empty list');
    return this[(DateTime.now().millisecondsSinceEpoch % length)];
  }
  
  // Get element safely
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
  
  // Add if not exists
  bool addIfNotExists(T item) {
    if (contains(item)) return false;
    add(item);
    return true;
  }
}

extension StringExtensions on String {
  // Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
  
  // Format as currency
  String get asCurrency => '\$${double.tryParse(this)?.toStringAsFixed(2) ?? this}';
  
  // Format score with commas
  String get asScore {
    final number = int.tryParse(this);
    if (number == null) return this;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

extension IntExtensions on int {
  // Format as score
  String get asScore => toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
  
  // Format as duration
  String get asDuration {
    final duration = Duration(seconds: this);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Clamp between min and max
// Clamp between min and max
int clampInt(int min, int max) => clamp(min, max).toInt();

  // Convert to double
  double toDoubleValue() => toDouble();
  
  // Convert to percentage string
  String get asPercentage => '${(this / 100).toStringAsFixed(1)}%';
  
  // Check if even
  bool get isEven => this % 2 == 0;
  
  // Check if odd
  bool get isOdd => !isEven;
}

extension DoubleExtensions on double {
  // Round to precision
  double roundToPrecision(int precision) {
    final factor = (10 * precision).toDouble();
    return (this * factor).roundToDouble() / factor;
  }
  
  // Convert to percentage string
  String get asPercentage => '${(this * 100).toStringAsFixed(1)}%';
}

extension Vector2Extensions on Vector2 {
  // Convert to Offset
  Offset get offset => Offset(x, y);
  
  // Distance to another vector
  double distanceTo(Vector2 other) => (this - other).length;
  
  // Angle to another vector
  double angleTo(Vector2 other) => (other - this).angleToSigned(Vector2(1, 0));
  
  // Clamp components
  Vector2 clampComponents(double min, double max) =>
      Vector2(x.clamp(min, max), y.clamp(min, max));
  
  // Round components
  Vector2 roundComponents() => Vector2(x.roundToDouble(), y.roundToDouble());
  
  // Check if approximately equal
  bool approximatelyEquals(Vector2 other, [double tolerance = 0.01]) =>
      (x - other.x).abs() < tolerance && (y - other.y).abs() < tolerance;
}

extension RectExtensions on Rect {
  // Check if contains point with tolerance
  bool containsWithTolerance(Offset point, double tolerance) {
    return left - tolerance <= point.dx &&
        point.dx <= right + tolerance &&
        top - tolerance <= point.dy &&
        point.dy <= bottom + tolerance;
  }
  
  // Get center as Vector2
  Vector2 get centerVector2 => Vector2(center.dx, center.dy);
  
  // Expand by amount
  Rect expandBy(double amount) => inflate(amount);
}