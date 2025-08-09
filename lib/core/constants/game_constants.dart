import 'package:flutter/foundation.dart';

/// GameConstants defines all game-specific constants for Box Hooks.
/// Centralizes game mechanics, scoring, timing, and balance parameters.
/// Separated from AppConstants to maintain Clean Architecture boundaries.
class GameConstants {
  // Prevent instantiation
  GameConstants._();

  // ========================================
  // 🎮 CORE GAME MECHANICS
  // ========================================
  
  /// Grid configuration
  static const int defaultGridSize = 10;
  static const int minGridSize = 8;
  static const int maxGridSize = 12;
  static const double cellBorderWidth = 1.0;
  static const double gridPadding = 8.0;
  
  /// Block configuration
  static const int maxSimultaneousBlocks = 3;
  static const int blockVariants = 7;
  static const double blockAnimationDuration = 0.3;
  static const double blockPlacementDelay = 0.1;
  
  /// Movement timing (optimized for 60 FPS)
  static const double moveInputDelay = 0.05; // 50ms
  static const double rotateInputDelay = 0.1; // 100ms
  static const double fastDropMultiplier = 10.0;

  // ========================================
  // 🏆 SCORING SYSTEM
  // ========================================
  
  /// Base scoring values
  static const int pointsPerBlock = 10;
  static const int pointsPerLine = 100;
  static const int pointsPerPerfectClear = 500;
  static const int comboBaseMultiplier = 2;
  static const int maxComboMultiplier = 10;
  
  /// Level progression
  static const int pointsPerLevel = 1000;
  static const double levelSpeedIncrease = 0.1;
  static const int maxLevel = 99;
  
  /// Streak bonuses
  static const int streakThreshold = 3;
  static const double streakMultiplier = 1.5;
  static const int maxStreakMultiplier = 5;

  // ========================================
  // ⚡ POWER-UPS SYSTEM
  // ========================================
  
  /// Power-up availability
  static const int maxPowerUpsPerGame = 5;
  static const int powerUpCooldownSeconds = 30;
  static const double powerUpSpawnRate = 0.15; // 15% chance
  
  /// Power-up costs (coins)
  static const Map<String, int> powerUpCosts = {
    'clearLine': 50,
    'destroyBlock': 30,
    'extraTime': 40,
    'doubleScore': 60,
    'perfectClear': 100,
  };
  
  /// Power-up durations (seconds)
  static const Map<String, double> powerUpDurations = {
    'doubleScore': 30.0,
    'slowTime': 15.0,
    'extraTime': 60.0,
  };

  // ========================================
  // 🎯 DIFFICULTY SETTINGS
  // ========================================
  
  /// Difficulty multipliers for scoring
  static const Map<String, double> difficultyScoreMultipliers = {
    'easy': 0.8,
    'normal': 1.0,
    'hard': 1.3,
    'expert': 1.6,
  };
  
  /// Difficulty-based power-up availability
  static const Map<String, double> difficultyPowerUpRates = {
    'easy': 0.25,    // 25% spawn rate
    'normal': 0.15,  // 15% spawn rate
    'hard': 0.10,    // 10% spawn rate
    'expert': 0.05,  // 5% spawn rate
  };

  // ========================================
  // ⏱️ TIMING CONSTANTS
  // ========================================
  
  /// Game timing (optimized for 60 FPS)
  static const Duration targetFrameTime = Duration(milliseconds: 16); // ~60 FPS
  static const Duration gameUpdateInterval = Duration(milliseconds: 16);
  static const Duration uiUpdateInterval = Duration(milliseconds: 32); // 30 FPS for UI
  
  /// Animation durations
  static const Duration blockDropDuration = Duration(milliseconds: 500);
  static const Duration lineClearDuration = Duration(milliseconds: 300);
  static const Duration comboAnimationDuration = Duration(milliseconds: 400);
  static const Duration levelUpDuration = Duration(milliseconds: 800);
  
  /// Input timing
  static const Duration longPressThreshold = Duration(milliseconds: 500);
  static const Duration doubleTapWindow = Duration(milliseconds: 300);
  static const Duration dragStartDelay = Duration(milliseconds: 100);

  // ========================================
  // 🎨 VISUAL CONSTANTS
  // ========================================
  
  /// Animation curves and easing
  static const String defaultEasing = 'easeInOutCubic';
  static const double particleLifetime = 2.0; // seconds
  static const int maxParticles = 50;
  
  /// Visual feedback
  static const double hapticFeedbackStrength = 0.5;
  static const double screenShakeIntensity = 2.0;
  static const Duration screenShakeDuration = Duration(milliseconds: 200);

  // ========================================
  // 💰 ECONOMY CONSTANTS
  // ========================================
  
  /// Coin rewards
  static const int coinsPerLine = 5;
  static const int coinsPerLevel = 25;
  static const int coinsPerAchievement = 50;
  static const int dailyBonusCoins = 100;
  static const int perfectGameBonus = 200;
  
  /// Purchase limits
  static const int maxCoinsPerPurchase = 10000;
  static const int maxPowerUpPurchases = 10;

  // ========================================
  // 🏅 ACHIEVEMENT THRESHOLDS
  // ========================================
  
  /// Score-based achievements
  static const Map<String, int> scoreAchievements = {
    'rookie': 1000,
    'skilled': 5000,
    'expert': 15000,
    'master': 50000,
    'legend': 100000,
  };
  
  /// Gameplay achievements
  static const Map<String, int> gameplayAchievements = {
    'firstWin': 1,
    'speedster': 10,      // Games completed under 5 min
    'marathon': 50,       // Games over 30 min
    'perfectionist': 5,   // Perfect clears
    'comboMaster': 25,    // Max combo achieved
  };

  // ========================================
  // 🔧 PERFORMANCE TUNING
  // ========================================
  
  /// Memory management
  static const int maxCachedBlocks = 20;
  static const int maxAudioInstances = 8;
  static const int maxParticleEffects = 30;
  static const Duration cacheCleanupInterval = Duration(minutes: 5);
  
  /// Performance thresholds
  static const double lowPerformanceThreshold = 45.0; // FPS
  static const double highPerformanceThreshold = 55.0; // FPS
  static const int memoryWarningThreshold = 100; // MB
  
  /// Auto-optimization settings
  static const bool enableAutoOptimization = true;
  static const bool enablePerformanceMonitoring = kDebugMode;
  static const bool enableMemoryOptimization = true;

  // ========================================
  // 📱 RESPONSIVE DESIGN
  // ========================================
  
  /// Screen size categories
  static const double smallScreenWidth = 360.0;
  static const double mediumScreenWidth = 768.0;
  static const double largeScreenWidth = 1024.0;
  
  /// Scaling factors for different screen sizes
  static const Map<String, double> uiScalingFactors = {
    'small': 0.8,
    'medium': 1.0,
    'large': 1.2,
    'xlarge': 1.4,
  };
  
  /// Grid scaling based on screen size
  static const Map<String, double> gridScalingFactors = {
    'small': 0.85,
    'medium': 1.0,
    'large': 1.15,
    'xlarge': 1.3,
  };

  // ========================================
  // 🎵 AUDIO CONSTANTS
  // ========================================
  
  /// Audio file names (consistent naming)
  static const Map<String, String> audioFiles = {
    'blockPlace': 'block_place.wav',
    'lineClear': 'line_clear.wav',
    'levelUp': 'level_up.wav',
    'gameOver': 'game_over.wav',
    'perfectClear': 'perfect_clear.wav',
    'powerUpActivate': 'powerup_activate.wav',
    'uiClick': 'ui_click.wav',
    'uiNavigate': 'ui_navigate.wav',
    'backgroundMusic': 'background_music.mp3',
  };
  
  /// Audio settings
  static const double defaultMusicVolume = 0.7;
  static const double defaultSfxVolume = 0.8;
  static const int maxConcurrentSounds = 6;

  // ========================================
  // 🚀 OPTIMIZATION FLAGS
  // ========================================
  
  /// Development and debugging
  static const bool enableDebugMode = kDebugMode;
  static const bool enablePerformanceLogs = kDebugMode;
  static const bool enableFrameRateDisplay = kDebugMode;
  static const bool enableMemoryDisplay = kDebugMode;
  
  /// Feature flags
  static const bool enableAdvancedAnimations = true;
  static const bool enableParticleEffects = true;
  static const bool enableHapticFeedback = true;
  static const bool enableScreenShake = true;
  
  /// Platform-specific optimizations
  static const bool enablePlatformOptimizations = true;
  static const bool useNativeRendering = true;
  static const bool enableTextureCompression = true;

  // ========================================
  // 🔒 VALIDATION CONSTANTS
  // ========================================
  
  /// Input validation
  static const int maxUsernameLength = 20;
  static const int minUsernameLength = 3;
  static const int maxHighScoreEntries = 10;
  
  /// Game state validation
  static const int maxUndoMoves = 3;
  static const Duration maxGameDuration = Duration(hours: 2);
  static const Duration minGameDuration = Duration(seconds: 30);
  
  /// Data validation
  static const int maxSaveDataSize = 1024 * 1024; // 1MB
  static const Duration dataValidityPeriod = Duration(days: 30);

  // ========================================
  // 🎮 BLOCK SHAPE DEFINITIONS
  // ========================================
  
  /// Standard Tetris-like block shapes
  static const List<List<List<int>>> blockShapes = [
    // I-piece (line) - 4 blocks in a row
    [
      [1, 1, 1, 1]
    ],
    
    // O-piece (square) - 2x2 square
    [
      [1, 1],
      [1, 1]
    ],
    
    // T-piece - T shape
    [
      [0, 1, 0],
      [1, 1, 1]
    ],
    
    // L-piece - L shape
    [
      [1, 0],
      [1, 0],
      [1, 1]
    ],
    
    // J-piece (reverse L) - reverse L shape
    [
      [0, 1],
      [0, 1],
      [1, 1]
    ],
    
    // S-piece - S/Z shape
    [
      [0, 1, 1],
      [1, 1, 0]
    ],
    
    // Z-piece - Z shape
    [
      [1, 1, 0],
      [0, 1, 1]
    ],
  ];
  
  /// Block colors (indices match blockShapes)
  static const List<String> blockColorNames = [
    'cyan',    // I-piece
    'yellow',  // O-piece
    'purple',  // T-piece
    'orange',  // L-piece
    'blue',    // J-piece
    'green',   // S-piece
    'red',     // Z-piece
  ];

  // ========================================
  // 💾 SAVE/LOAD CONSTANTS
  // ========================================
  
  /// Save game settings
  static const int maxSaveSlots = 3;
  static const Duration autoSaveInterval = Duration(minutes: 2);
  static const bool enableAutoSave = true;
  static const bool enableCloudSave = false; // Future feature
  
  /// Data compression
  static const bool enableDataCompression = true;
  static const int compressionLevel = 6; // 1-9, higher = better compression
}

/// Block type enumeration for type safety
enum BlockType {
  i, o, t, l, j, s, z;
  
  String get name => toString().split('.').last.toUpperCase();
  
  List<List<int>> get shape => GameConstants.blockShapes[index];
  
  String get colorName => GameConstants.blockColorNames[index];
  
  int get shapeIndex => index;
}

/// Game mode enumeration
enum GameMode {
  classic,
  timed,
  endless,
  puzzle;
  
  String get name => toString().split('.').last;
  
  String get displayName {
    switch (this) {
      case GameMode.classic:
        return 'Classic';
      case GameMode.timed:
        return 'Time Attack';
      case GameMode.endless:
        return 'Endless';
      case GameMode.puzzle:
        return 'Puzzle';
    }
  }
  
  String get description {
    switch (this) {
      case GameMode.classic:
        return 'Traditional block-stacking gameplay';
      case GameMode.timed:
        return 'Race against the clock';
      case GameMode.endless:
        return 'Play until the grid fills up';
      case GameMode.puzzle:
        return 'Solve predetermined challenges';
    }
  }
}

/// Performance preset enumeration
enum PerformancePreset {
  low,
  medium,
  high,
  ultra;
  
  String get name => toString().split('.').last;
  
  String get displayName {
    switch (this) {
      case PerformancePreset.low:
        return 'Low';
      case PerformancePreset.medium:
        return 'Medium';
      case PerformancePreset.high:
        return 'High';
      case PerformancePreset.ultra:
        return 'Ultra';
    }
  }
  
  Map<String, dynamic> get settings {
    switch (this) {
      case PerformancePreset.low:
        return {
          'enableParticles': false,
          'enableAnimations': false,
          'enableShaders': false,
          'maxParticles': 10,
          'targetFPS': 30,
        };
      case PerformancePreset.medium:
        return {
          'enableParticles': true,
          'enableAnimations': true,
          'enableShaders': false,
          'maxParticles': 25,
          'targetFPS': 45,
        };
      case PerformancePreset.high:
        return {
          'enableParticles': true,
          'enableAnimations': true,
          'enableShaders': true,
          'maxParticles': 50,
          'targetFPS': 60,
        };
      case PerformancePreset.ultra:
        return {
          'enableParticles': true,
          'enableAnimations': true,
          'enableShaders': true,
          'maxParticles': 100,
          'targetFPS': 60,
        };
    }
  }
}