import 'package:flutter/widgets.dart';

class ResponsiveUtils {
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  static EdgeInsets pagePadding(BuildContext context) =>
      isTablet(context) ? const EdgeInsets.all(24) : const EdgeInsets.all(12);
}
