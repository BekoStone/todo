class AppConstants {
  AppConstants._();

  static const String appName = 'Puzzle Box';

  // Timings
  static const Duration shortAnim = Duration(milliseconds: 150);
  static const Duration mediumAnim = Duration(milliseconds: 250);
  static const Duration longAnim = Duration(milliseconds: 400);

  // Performance budgets
  static const int targetFps = 60;
  static const Duration frameBudget = Duration(milliseconds: 16);
  static const int maxMemoryMb = 150;
  static const Duration coldStartBudget = Duration(seconds: 3);

  // Storage keys
  static const String kPlayerStats = 'player_stats';
  static const String kGameSession = 'game_session';
  static const String kAchievements = 'achievements';
}
