import 'package:flutter/foundation.dart';

/// Global application constants for the Box Hooks puzzle game.
/// Contains configuration values, settings, and magic numbers used throughout the app.
/// Single source of truth for all constants to prevent inconsistencies.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ========================================
  // 📱 APPLICATION INFORMATION
  // ========================================
  
  static const String appName = 'Box Hooks';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;
  static const String packageName = 'com.yourcompany.boxhooksgame';
  static const String developerName = 'Your Company';
  static const String supportEmail = 'support@yourcompany.com';
  static const String privacyPolicyUrl = 'https://yourcompany.com/privacy';
  static const String termsOfServiceUrl = 'https://yourcompany.com/terms';

  // ========================================
  // 🎮 GAME CONFIGURATION
  // ========================================
  
  /// Game grid size (8x8) - Core game dimension
  static const int gridSize = 8;
  
  /// Spacing and layout constants
  static const double cellSpacing = 2.0;
  static const double gridSpacing = 2.0; // Alias for compatibility
  static const double cellBorderRadius = 4.0;
  static const double gridPadding = 16.0;
  
  /// Block configuration
  static const int maxActiveBlocks = 3;
  static const double blockSpacing = 3.0;
  static const double blockBorderRadius = 6.0;
  static const double dragScaleMultiplier = 1.05;

  // ========================================
  // 🏆 SCORING SYSTEM
  // ========================================
  
  /// Base scores for different game actions
  static const Map<String, int> baseScores = {
    'blockPlace': 10,
    'singleLine': 100,
    'doubleLine': 250,
    'tripleLine': 400,
    'quadLine': 600,
    'perfectClear': 1000,
  };
  
  /// Combo multipliers for consecutive actions
  static const List<double> comboMultipliers = [
    1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 4.0, 5.0, 6.0,
  ];
  
  /// Streak bonuses for consecutive successes
  static const Map<int, int> streakBonuses = {
    3: 50,
    5: 120,
    7: 200,
    10: 300,
    15: 500,
    20: 800,
    25: 1200,
  };

  // ========================================
  // ⚡ POWER-UPS SYSTEM
  // ========================================
  
  /// Power-up costs in coins
  static const Map<String, int> powerUpCosts = {
    'shuffle': 75,
    'undo': 50,
    'hint': 25,
    'bomb': 100,
    'freeze': 150,
  };
  
  /// Power-up limits per game
  static const int maxUndoCount = 3;
  static const int maxHints = 5;
  static const int maxBombs = 2;

  // ========================================
  // 🪙 ECONOMY SYSTEM
  // ========================================
  
  /// Coin system configuration
  static const int startingCoins = 100;
  static const int dailyBonusCoins = 50;
  static const int adRewardCoins = 25;
  static const int achievementBonusCoins = 100;
  static const int gameCompletionCoins = 10;
  
  /// Premium currency
  static const int premiumCurrencyStarting = 5;
  static const Map<String, int> premiumCosts = {
    'extraUndo': 1,
    'skipLevel': 2,
    'doubleCoins': 3,
  };

  // ========================================
  // ⚖️ GAME BALANCE
  // ========================================
  
  /// Level progression
  static const int linesPerLevel = 10;
  static const double difficultyIncrease = 0.1;
  static const double maxDifficulty = 2.0;
  static const int gameOverThreshold = 80; // Grid fill percentage
  
  /// Game session limits
  static const Duration maxGameDuration = Duration(minutes: 30);
  static const Duration autoSaveInterval = Duration(seconds: 30);

  // ========================================
  // 🔧 TECHNICAL CONFIGURATION
  // ========================================
  
  /// Physics and collision detection
  static const double snapThreshold = 30.0;
  static const double collisionTolerance = 2.0;
  static const double dragDeadZone = 5.0;
  static const double tapTolerance = 10.0;
  
  /// Performance settings
  static const int maxParticleCount = 50;
  static const double particleLifetime = 2.0;
  static const int maxGlowEffects = 3;
  static const int maxSimultaneousAnimations = 5;
  
  /// Frame rate targets
  static const int targetFPS = 60;
  static const double maxFrameTime = 16.67; // milliseconds (60 FPS)

  // ========================================
  // 🎨 ANIMATION TIMINGS
  // ========================================
  
  /// Animation durations
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration normalAnimationDuration = Duration(milliseconds: 250);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  static const Duration extraLongAnimationDuration = Duration(milliseconds: 800);
  static const Duration shortAnimationDuration = Duration(milliseconds: 100);
  
  /// Transition durations
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration overlayTransitionDuration = Duration(milliseconds: 200);

  // ========================================
  // 🔊 AUDIO CONFIGURATION
  // ========================================
  
  /// Audio settings
  static const double defaultMusicVolume = 0.7;
  static const double defaultSfxVolume = 0.8;
  static const double maxVolume = 1.0;
  static const double minVolume = 0.0;
  
  /// Audio behavior
  static const Duration audioFadeDuration = Duration(milliseconds: 500);
  static const Duration soundDebounceInterval = Duration(milliseconds: 100);
  static const int maxSimultaneousSounds = 8;

  // ========================================
  // 💾 STORAGE CONFIGURATION
  // ========================================
  
  /// Storage keys for persistent data
  static const String playerStatsKey = 'player_stats_v2';
  static const String achievementsKey = 'achievements_v2';
  static const String settingsKey = 'app_settings_v2';
  static const String gameStateKey = 'game_state_v2';
  static const String highScoresKey = 'high_scores_v2';
  static const String tutorialKey = 'tutorial_progress_v2';
  static const String preferencesKey = 'user_preferences_v2';
  
  /// Storage behavior
  static const int maxSavedGames = 5;
  static const Duration dataExpirationTime = Duration(days: 90);

  // ========================================
  // 🌐 NETWORK CONFIGURATION
  // ========================================
  
  /// API configuration (if using remote services)
  static const String apiBaseUrl = 'https://api.yourcompany.com/v1';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ========================================
  // 📏 RESPONSIVE DESIGN
  // ========================================
  
  /// Breakpoints for responsive design
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  /// Responsive scaling factors
  static const Map<String, double> scalingFactors = {
    'mobile': 1.0,
    'tablet': 1.2,
    'desktop': 1.4,
  };

  // ========================================
  // 🎯 ACHIEVEMENT TARGETS
  // ========================================
  
  /// Achievement unlock conditions
  static const Map<String, int> achievementTargets = {
    'firstBlock': 1,
    'firstLine': 1,
    'score1K': 1000,
    'score5K': 5000,
    'score10K': 10000,
    'score25K': 25000,
    'score50K': 50000,
    'score100K': 100000,
    'combo5x': 5,
    'combo10x': 10,
    'combo15x': 15,
    'perfectClear': 1,
    'perfectClear5': 5,
    'gamesPlayed': 10,
    'gamesPlayed50': 50,
    'gamesPlayed100': 100,
    'totalBlocks': 100,
    'totalBlocks1K': 1000,
    'totalLines': 50,
    'totalLines500': 500,
    'dailyPlayer': 7, // Play 7 consecutive days
    'speedster': 1, // Complete level in under 60 seconds
    'efficient': 1, // Complete level with minimal moves
  };

  // ========================================
  // 📊 ANALYTICS EVENTS
  // ========================================
  
  /// Analytics event names
  static const Map<String, String> analyticsEvents = {
    'gameStart': 'game_started',
    'gameEnd': 'game_completed',
    'levelUp': 'level_achieved',
    'powerUpUsed': 'power_up_activated',
    'achievementUnlocked': 'achievement_earned',
    'coinsPurchased': 'coins_purchased',
    'adWatched': 'advertisement_viewed',
  };

  // ========================================
  // 🎲 GAME DIFFICULTY SETTINGS
  // ========================================
  
  /// Difficulty modifiers
  static const Map<String, Map<String, double>> difficultySettings = {
    'easy': {
      'scoreMultiplier': 0.8,
      'timeMultiplier': 1.5,
      'hintCost': 0.5,
    },
    'normal': {
      'scoreMultiplier': 1.0,
      'timeMultiplier': 1.0,
      'hintCost': 1.0,
    },
    'hard': {
      'scoreMultiplier': 1.3,
      'timeMultiplier': 0.8,
      'hintCost': 1.5,
    },
    'expert': {
      'scoreMultiplier': 1.6,
      'timeMultiplier': 0.6,
      'hintCost': 2.0,
    },
  };

  // ========================================
  // 🔒 VALIDATION CONSTANTS
  // ========================================
  
  /// Validation patterns and limits
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int maxScoreDigits = 10;
  static const int maxLeaderboardEntries = 100;

  // ========================================
  // 🚀 PERFORMANCE THRESHOLDS
  // ========================================
  
  /// Performance monitoring thresholds
  static const Duration criticalFrameTime = Duration(milliseconds: 20);
  static const Duration warningFrameTime = Duration(milliseconds: 18);
  static const int maxMemoryUsageMB = 150;
  static const double maxCPUUsagePercent = 80.0;

  // ========================================
  // 🎨 UI CONSTANTS
  // ========================================
  
  /// UI element sizes and spacing
  static const double buttonHeight = 48.0;
  static const double buttonBorderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double modalBorderRadius = 20.0;
  
  /// Padding and margins
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  /// Icon sizes
  static const double smallIconSize = 16.0;
  static const double normalIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;

  // ========================================
  // 🏁 GAME CONSTANTS (CONSOLIDATED)
  // ========================================
  
  /// Consolidated game constants to avoid API mismatches
  /// All game-related constants are now in one place
  
  // Block system constants
  static const List<List<List<int>>> blockShapes = [
    // I-piece (line)
    [[1, 1, 1, 1]],
    
    // O-piece (square)
    [[1, 1], [1, 1]],
    
    // T-piece
    [[0, 1, 0], [1, 1, 1]],
    
    // L-piece
    [[1, 0], [1, 0], [1, 1]],
    
    // J-piece (reverse L)
    [[0, 1], [0, 1], [1, 1]],
    
    // S-piece
    [[0, 1, 1], [1, 1, 0]],
    
    // Z-piece
    [[1, 1, 0], [0, 1, 1]],
  ];
  
  // Game state status strings (for consistency)
  static const String gameStatusIdle = 'idle';
  static const String gameStatusLoading = 'loading';
  static const String gameStatusPlaying = 'playing';
  static const String gameStatusPaused = 'paused';
  static const String gameStatusGameOver = 'gameOver';
  static const String gameStatusError = 'error';

  // ========================================
  // 🔍 DEBUG AND DEVELOPMENT
  // ========================================
  
  /// Debug mode settings (only active in debug builds)
  static bool get enableDebugOverlays => kDebugMode;
  static bool get enablePerformanceMonitoring => kDebugMode;
  static bool get enableVerboseLogging => kDebugMode;
  static bool get enableStateDumping => kDebugMode;
  
  /// Development shortcuts
  static const Map<String, dynamic> devShortcuts = {
    'skipTutorial': kDebugMode,
    'unlockAllLevels': kDebugMode,
    'infiniteCoins': kDebugMode,
    'godMode': kDebugMode,
  };

  // ========================================
  // 📝 API CONSISTENCY HELPERS
  // ========================================
  
  /// Consistent naming for all file extensions
  static const String audioFileExtension = '.wav';
  static const String musicFileExtension = '.mp3';
  static const String imageFileExtension = '.png';
  static const String animationFileExtension = '.json';
  
  /// Consistent asset paths
  static const String assetsPath = 'assets/';
  static const String audioPath = '${assetsPath}audio/';
  static const String imagesPath = '${assetsPath}images/';
  static const String animationsPath = '${assetsPath}animations/';
  static const String fontsPath = '${assetsPath}fonts/';
  
  /// Consistent naming for storage keys (version 2 for migration)
  static const String keyPrefix = 'box_hooks_v2_';
  static const String playerStatsKeyV2 = '${keyPrefix}player_stats';
  static const String achievementsKeyV2 = '${keyPrefix}achievements';
  static const String settingsKeyV2 = '${keyPrefix}app_settings';
  static const String gameStateKeyV2 = '${keyPrefix}game_state';
  static const String highScoresKeyV2 = '${keyPrefix}high_scores';
  static const String tutorialKeyV2 = '${keyPrefix}tutorial_progress';
  static const String preferencesKeyV2 = '${keyPrefix}user_preferences';

  // ========================================
  // 🎯 FEATURE FLAGS
  // ========================================
  
  /// Feature flags for gradual rollout of features
  static const bool enableAchievements = true;
  static const bool enableLeaderboards = true;
  static const bool enableDailyRewards = true;
  static const bool enablePowerUps = true;
  static const bool enableTutorial = true;
  static const bool enableAnalytics = false; // Disabled for privacy
  static const bool enableCloudSave = false; // Future feature
  static const bool enableMultiplayer = false; // Future feature
  
  /// Feature flag for A/B testing
  static const String abTestGroup = 'groupA'; // Can be 'groupA'
  static const String abTestVariant = 'variant1'; // Can be 'variant1' or 'variant2'
}