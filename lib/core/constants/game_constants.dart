import 'package:flutter/foundation.dart';

/// Game-specific constants and configuration values.
/// Centralized configuration for all game mechanics, UI, and performance settings.
/// Single source of truth to prevent API inconsistencies.
class GameConstants {
  // Prevent instantiation
  GameConstants._();

  // ========================================
  // CORE GAME MECHANICS
  // ========================================
  
  /// Game grid dimensions (8x8 for puzzle game)
  static const int gridSize = 8;
  static const int totalCells = gridSize * gridSize;
  
  /// Grid spacing and layout
  static const double gridSpacing = 2.0;
  static const double cellSpacing = 2.0; // Alias for consistency
  static const double cellBorderRadius = 4.0;
  static const double gridPadding = 16.0;
  
  /// Block configuration
  static const int maxActiveBlocks = 3;
  static const double blockSpacing = 3.0;
  static const double blockBorderRadius = 6.0;
  static const double dragScaleMultiplier = 1.05;
  
  /// Game timing
  static const Duration gameTickInterval = Duration(milliseconds: 16); // 60 FPS
  static const Duration autoSaveInterval = Duration(minutes: 1);
  static const Duration maxGameDuration = Duration(hours: 2);

  // ========================================
  // SCORING SYSTEM
  // ========================================
  
  /// Base scoring values
  static const Map<String, int> baseScores = {
    'blockPlace': 10,
    'singleLine': 100,
    'doubleLine': 250,
    'tripleLine': 400,
    'quadLine': 600,
    'perfectClear': 1000,
    'combo': 50,
    'streak': 25,
  };
  
  /// Combo multipliers (progressive)
  static const List<double> comboMultipliers = [
    1.0,  // No combo
    1.2,  // 2x combo
    1.5,  // 3x combo
    1.8,  // 4x combo
    2.2,  // 5x combo
    2.7,  // 6x combo
    3.3,  // 7x combo
    4.0,  // 8x combo
    5.0,  // 9x combo
    6.0,  // 10x combo
  ];
  
  /// Level progression
  static const int linesPerLevel = 10;
  static const double scoreMultiplierPerLevel = 1.1;
  static const int maxLevel = 50;
  
  /// Streak bonuses
  static const Map<int, int> streakBonuses = {
    5: 100,
    10: 300,
    15: 600,
    20: 1000,
    25: 1500,
  };

  // ========================================
  // POWER-UPS SYSTEM
  // ========================================
  
  /// Power-up limits
  static const int maxUndoCount = 3;
  static const int maxHints = 5;
  static const int maxShuffles = 2;
  
  /// Power-up costs (in coins)
  static const Map<String, int> powerUpCosts = {
    'undo': 50,
    'hint': 30,
    'shuffle': 100,
    'bomb': 150,
    'freeze': 200,
  };
  
  /// Power-up cooldowns (in seconds)
  static const Map<String, int> powerUpCooldowns = {
    'hint': 5,
    'shuffle': 10,
    'bomb': 15,
    'freeze': 20,
  };

  // ========================================
  // BLOCK SHAPES DEFINITION
  // ========================================
  
  /// All possible block shapes (Tetris-like pieces)
  static const List<List<List<int>>> blockShapes = [
    // I-piece (line)
    [
      [1, 1, 1, 1]
    ],
    
    // O-piece (square)
    [
      [1, 1],
      [1, 1]
    ],
    
    // T-piece
    [
      [0, 1, 0],
      [1, 1, 1]
    ],
    
    // L-piece
    [
      [1, 0],
      [1, 0],
      [1, 1]
    ],
    
    // J-piece
    [
      [0, 1],
      [0, 1],
      [1, 1]
    ],
    
    // S-piece
    [
      [0, 1, 1],
      [1, 1, 0]
    ],
    
    // Z-piece
    [
      [1, 1, 0],
      [0, 1, 1]
    ],
    
    // Single block
    [
      [1]
    ],
    
    // Double block (horizontal)
    [
      [1, 1]
    ],
    
    // Double block (vertical)
    [
      [1],
      [1]
    ],
    
    // Triple block (horizontal)
    [
      [1, 1, 1]
    ],
    
    // Triple block (vertical)
    [
      [1],
      [1],
      [1]
    ],
    
    // Plus shape
    [
      [0, 1, 0],
      [1, 1, 1],
      [0, 1, 0]
    ],
    
    // Small L
    [
      [1, 0],
      [1, 1]
    ],
    
    // Small reverse L
    [
      [0, 1],
      [1, 1]
    ],
  ];

  // ========================================
  // DIFFICULTY SETTINGS
  // ========================================
  
  /// Difficulty multipliers
  static const Map<String, Map<String, double>> difficultyMultipliers = {
    'easy': {
      'scoreMultiplier': 0.8,
      'timeMultiplier': 1.5,
      'powerUpMultiplier': 1.5,
    },
    'normal': {
      'scoreMultiplier': 1.0,
      'timeMultiplier': 1.0,
      'powerUpMultiplier': 1.0,
    },
    'hard': {
      'scoreMultiplier': 1.3,
      'timeMultiplier': 0.8,
      'powerUpMultiplier': 0.7,
    },
    'expert': {
      'scoreMultiplier': 1.6,
      'timeMultiplier': 0.6,
      'powerUpMultiplier': 0.5,
    },
  };

  // ========================================
  // PERFORMANCE THRESHOLDS
  // ========================================
  
  /// Target performance metrics
  static const double minTargetFPS = 50.0;
  static const double optimalFPS = 60.0;
  static const int maxColdStartMs = 3000;
  static const int maxMemoryUsageMB = 150;
  static const double maxCPUUsagePercent = 80.0;
  
  /// Frame time thresholds (in milliseconds)
  static const double criticalFrameTime = 20.0;
  static const double warningFrameTime = 18.0;
  static const double targetFrameTime = 16.67; // 60 FPS

  // ========================================
  // ANIMATION SETTINGS
  // ========================================
  
  /// Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  static const Duration extraLongAnimationDuration = Duration(milliseconds: 1000);
  
  /// Specific game animations
  static const Duration blockPlaceAnimationDuration = Duration(milliseconds: 200);
  static const Duration lineClearAnimationDuration = Duration(milliseconds: 500);
  static const Duration comboAnimationDuration = Duration(milliseconds: 300);
  static const Duration levelUpAnimationDuration = Duration(milliseconds: 800);
  
  /// Animation curves (referenced by name for consistency)
  static const String defaultAnimationCurve = 'easeInOut';
  static const String bounceAnimationCurve = 'elasticOut';
  static const String slideAnimationCurve = 'easeOutCubic';

  // ========================================
  // AUDIO SETTINGS
  // ========================================
  
  /// Default audio levels
  static const double defaultMusicVolume = 0.7;
  static const double defaultSfxVolume = 0.8;
  static const double maxAudioVolume = 1.0;
  static const double minAudioVolume = 0.0;
  
  /// Audio fade durations
  static const Duration musicFadeInDuration = Duration(milliseconds: 1500);
  static const Duration musicFadeOutDuration = Duration(milliseconds: 1000);
  static const Duration sfxFadeDuration = Duration(milliseconds: 200);
  
  /// SFX cooldowns to prevent audio spam
  static const Duration sfxCooldownDuration = Duration(milliseconds: 50);
  static const Duration uiSfxCooldownDuration = Duration(milliseconds: 100);

  // ========================================
  // UI/UX CONSTANTS
  // ========================================
  
  /// Touch and gesture settings
  static const double minTouchTargetSize = 44.0; // iOS/Android standard
  static const double dragThreshold = 10.0;
  static const Duration tapTimeout = Duration(milliseconds: 300);
  static const Duration longPressTimeout = Duration(milliseconds: 500);
  
  /// Visual feedback
  static const double selectionBorderWidth = 3.0;
  static const double disabledOpacity = 0.5;
  static const double hoveredOpacity = 0.8;
  static const double pressedOpacity = 0.6;
  
  /// Loading and transitions
  static const Duration splashMinDuration = Duration(seconds: 2);
  static const Duration loadingTimeout = Duration(seconds: 30);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  // ========================================
  // ECONOMY SYSTEM
  // ========================================
  
  /// Coin rewards
  static const int gameCompletionCoins = 10;
  static const int dailyBonusCoins = 50;
  static const int achievementBaseCoins = 25;
  static const int levelUpCoins = 20;
  static const int perfectClearCoins = 100;
  
  /// Shop prices
  static const Map<String, int> shopPrices = {
    'extraUndo': 100,
    'extraHint': 75,
    'extraShuffle': 150,
    'doubleCoins': 200,
    'removeAds': 500,
  };
  
  /// Daily rewards progression
  static const List<int> dailyRewards = [
    50,   // Day 1
    75,   // Day 2
    100,  // Day 3
    125,  // Day 4
    150,  // Day 5
    200,  // Day 6
    300,  // Day 7 (weekly bonus)
  ];

  // ========================================
  // ACHIEVEMENT THRESHOLDS
  // ========================================
  
  /// Score-based achievements
  static const Map<String, int> scoreAchievements = {
    'score_1K': 1000,
    'score_5K': 5000,
    'score_10K': 10000,
    'score_25K': 25000,
    'score_50K': 50000,
    'score_100K': 100000,
  };
  
  /// Gameplay achievements
  static const Map<String, int> gameplayAchievements = {
    'games_10': 10,
    'games_50': 50,
    'games_100': 100,
    'lines_100': 100,
    'lines_500': 500,
    'lines_1000': 1000,
    'combos_5': 5,
    'combos_10': 10,
    'perfect_clears_5': 5,
    'level_10': 10,
    'level_25': 25,
    'level_50': 50,
  };
  
  /// Time-based achievements
  static const Map<String, Duration> timeAchievements = {
    'playtime_1h': Duration(hours: 1),
    'playtime_10h': Duration(hours: 10),
    'playtime_50h': Duration(hours: 50),
    'daily_7': Duration(days: 7),
    'daily_30': Duration(days: 30),
  };

  // ========================================
  // GAME BALANCE
  // ========================================
  
  /// Game over conditions
  static const double gameOverThreshold = 85.0; // % of grid filled
  static const int maxConsecutiveFailures = 5;
  static const Duration maxIdleTime = Duration(minutes: 10);
  
  /// Block generation weights (probability distribution)
  static const Map<int, double> blockGenerationWeights = {
    0: 0.15,  // I-piece
    1: 0.10,  // O-piece
    2: 0.12,  // T-piece
    3: 0.08,  // L-piece
    4: 0.08,  // J-piece
    5: 0.06,  // S-piece
    6: 0.06,  // Z-piece
    7: 0.20,  // Single block
    8: 0.15,  // Other shapes
  };
  
  /// Special event triggers
  static const int comboThreshold = 3;
  static const int streakThreshold = 5;
  static const int perfectClearThreshold = 1;
  static const double cascadeMultiplier = 1.5;

  // ========================================
  // DEBUG AND DEVELOPMENT
  // ========================================
  
  /// Debug settings (only active in debug mode)
  static const bool enablePerformanceOverlay = kDebugMode;
  static const bool enableDebugPrint = kDebugMode;
  static const bool enableFrameRateDisplay = kDebugMode;
  static const bool enableMemoryDisplay = kDebugMode;
  
  /// Testing and validation
  static const Duration testTimeout = Duration(seconds: 5);
  static const int maxTestRetries = 3;
  static const bool enableAutomaticTesting = false;
  
  /// Logging levels
  static const int logLevel = kDebugMode ? 0 : 2; // 0=verbose, 1=info, 2=warning, 3=error

  // ========================================
  // UTILITY METHODS
  // ========================================
  
  /// Get block shape by index
  static List<List<int>> getBlockShape(int shapeIndex) {
    if (shapeIndex < 0 || shapeIndex >= blockShapes.length) {
      return blockShapes[7]; // Default to single block
    }
    return blockShapes[shapeIndex];
  }
  
  /// Get score for action
  static int getScore(String action, {int multiplier = 1}) {
    return (baseScores[action] ?? 0) * multiplier;
  }
  
  /// Get combo multiplier
  static double getComboMultiplier(int comboCount) {
    if (comboCount <= 0) return 1.0;
    final index = (comboCount - 1).clamp(0, comboMultipliers.length - 1);
    return comboMultipliers[index];
  }
  
  /// Calculate level from lines cleared
  static int calculateLevel(int linesCleared) {
    return (linesCleared / linesPerLevel).floor() + 1;
  }
  
  /// Calculate experience points
  static int calculateExperience(int score, int level, int linesCleared) {
    return ((score * 0.1) + (level * 10) + (linesCleared * 5)).round();
  }
  
  /// Get difficulty multiplier
  static double getDifficultyMultiplier(String difficulty, String type) {
    return difficultyMultipliers[difficulty]?[type] ?? 1.0;
  }
  
  /// Check if performance is within acceptable range
  static bool isPerformanceAcceptable(double fps, double memoryMB, int coldStartMs) {
    return fps >= minTargetFPS && 
           memoryMB <= maxMemoryUsageMB && 
           coldStartMs <= maxColdStartMs;
  }
  
  /// Get animation duration by name
  static Duration getAnimationDuration(String name) {
    switch (name) {
      case 'short':
        return shortAnimationDuration;
      case 'medium':
        return mediumAnimationDuration;
      case 'long':
        return longAnimationDuration;
      case 'extraLong':
        return extraLongAnimationDuration;
      case 'blockPlace':
        return blockPlaceAnimationDuration;
      case 'lineClear':
        return lineClearAnimationDuration;
      case 'combo':
        return comboAnimationDuration;
      case 'levelUp':
        return levelUpAnimationDuration;
      default:
        return mediumAnimationDuration;
    }
  }
}