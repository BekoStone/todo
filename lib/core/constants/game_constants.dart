class GameConstants {
  // Grid Configuration
  static const int gridSize = 8;
  static const double cellSpacing = 2.0;
  static const double cellBorderRadius = 4.0;
  static const double gridPadding = 16.0;
  
  // Block Configuration
  static const int maxActiveBlocks = 3;
  static const double blockSpacing = 3.0;
  static const double blockBorderRadius = 6.0;
  static const double dragScaleMultiplier = 1.05;
  
  // Scoring System
  static const Map<String, int> baseScores = {
    'blockPlace': 10,
    'singleLine': 100,
    'doubleLine': 250,
    'tripleLine': 400,
    'quadLine': 600,
    'perfectClear': 1000,
  };
  
  static const List<double> comboMultipliers = [
    1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 4.0,
  ];
  
  static const Map<int, int> streakBonuses = {
    3: 50,
    5: 120,
    7: 200,
    10: 300,
    15: 500,
  };
  
  // Power-ups
  static const Map<String, int> powerUpCosts = {
    'shuffle': 75,
    'undo': 50,
    'hint': 25,
    'bomb': 100,
  };
  
  static const int maxUndoCount = 3;
  static const int maxHints = 5;
  
  // Coin System
  static const int startingCoins = 100;
  static const int dailyBonusCoins = 50;
  static const int adRewardCoins = 25;
  static const int achievementBonusCoins = 100;
  
  // Game Balance
  static const int linesPerLevel = 10;
  static const double difficultyIncrease = 0.1;
  static const double maxDifficulty = 2.0;
  static const int gameOverThreshold = 80; // Grid fill percentage
  
  // Physics & Collision
  static const double snapThreshold = 30.0;
  static const double collisionTolerance = 2.0;
  static const double dragDeadZone = 5.0;
  
  // Visual Effects
  static const int particleCount = 15;
  static const double particleLifetime = 2.0;
  static const int maxGlowEffects = 3;
  
  // Achievement Thresholds
  static const Map<String, int> achievementTargets = {
    'firstBlock': 1,
    'firstLine': 1,
    'score1K': 1000,
    'score5K': 5000,
    'score10K': 10000,
    'combo5x': 5,
    'combo10x': 10,
    'perfectClear': 1,
    'gamesPlayed': 10,
    'totalBlocks': 100,
    'totalLines': 50,
  };
}