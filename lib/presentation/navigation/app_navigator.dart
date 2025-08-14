import 'package:flutter/material.dart';
import '../pages/main_menu_page.dart';
import '../pages/game_page.dart';
import '../pages/achievements_page.dart';
import '../pages/splash_page.dart';

class AppNavigator {
  static const initialRoute = SplashPage.route;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashPage.route:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case MainMenuPage.route:
        return MaterialPageRoute(builder: (_) => const MainMenuPage());
      case GamePage.route:
        return MaterialPageRoute(builder: (_) => const GamePage());
      case AchievementsPage.route:
        return MaterialPageRoute(builder: (_) => const AchievementsPage());
      
      default:
        return MaterialPageRoute(builder: (_) => const MainMenuPage());
    }
  }
}
