// File: lib/core/constants/app_constants.dart

import 'package:flutter/foundation.dart';

/// Global application constants for the Box Hooks puzzle game.
/// Contains configuration values, settings, and magic numbers used throughout the app.
/// CONSOLIDATED: Includes all GameConstants for single source of truth.
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ========================================
  // 📱 APPLICATION INFORMATION
  // ========================================
  
  /// Application name
  static const String appName = 'Box Hooks';
  
  /// Current application version
  static const String appVersion = '1.0.0';
  
  /// Build number for internal tracking
  static const int buildNumber = 1;
  
  /// Application package name
  static const String packageName = 'com.yourcompany.boxhooksgame';
  
  /// Developer name
  static const String developerName = 'Your Company';
  
  /// Support email
  static const String supportEmail = 'support@yourcompany.com';
  
  /// Privacy policy URL
  static const String privacyPolicyUrl = 'https://yourcompany.com/privacy';
  
  /// Terms of service URL
  static const String termsOfServiceUrl = 'https://yourcompany.com/terms';

  // ========================================
  // 🎮 GAME CONFIGURATION (CONSOLIDATED FROM GameConstants)
  // ========================================
  
  /// Game grid size (8x8) - MAIN PROPERTY USED THROUGHOUT APP
  static const int gridSize = 8;
  
  /// Cell spacing between grid cells
  static const double cellSpacing = 2.0;
  static const double gridSpacing = 2.0; // Alias for compatibility
  
  /// Cell border radius
  static const double cellBorderRadius = 4.0;
  
  /// Grid padding
  static const double gridPadding = 16.0;
  
  /// Maximum number of active blocks at once
  static const int maxActiveBlocks = 3;
  
  /// Block spacing
  static const double blockSpacing = 3.0;
  
  /// Block border radius
  static const double blockBorderRadius = 6.0;
  
  /// Drag scale multiplier for visual feedback
  static const double dragScaleMultiplier = 1.05;

  // ========================================
  // 🏆 SCORING SYSTEM
  // ========================================
  
  /// Base scores for different actions
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
    1.0, 1.2, 1.5, 1.8, 2.2, 2.7, 3.3, 4.0,
  ];
  
  /// Streak bonuses for consecutive successes
  static const Map<int, int> streakBonuses = {
    3: 50,
    5: 120,
    7: 200,
    10: 300,
    15: 500,
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
  };
  
  /// Maximum undo count per game
  static const int maxUndoCount = 3;
  
  /// Maximum hints per game
  static const int maxHints = 5;

  // ========================================
  // 🪙 COIN SYSTEM
  // ========================================
  
  /// Starting coins for new players
  static const int startingCoins = 100;
  
  /// Daily bonus coins
  static const int dailyBonusCoins = 50;
  
  /// Coins earned from watching ads
  static const int adRewardCoins = 25;
  
  /// Bonus coins for achievements
  static const int achievementBonusCoins = 100;

  // ========================================
  // ⚖️ GAME BALANCE
  // ========================================
  
  /// Lines required per level
  static const int linesPerLevel = 10;
  
  /// Difficulty increase per level
  static const double difficultyIncrease = 0.1;
  
  /// Maximum difficulty multiplier
  static const double maxDifficulty = 2.0;
  
  /// Game over threshold (grid fill percentage)
  static const int gameOverThreshold = 80;

  // ========================================
  // 🔧 PHYSICS & COLLISION
  // ========================================
  
  /// Snap threshold for block placement
  static const double snapThreshold = 30.0;
  
  /// Collision detection tolerance
  static const double collisionTolerance = 2.0;
  
  /// Drag dead zone to prevent accidental drags
  static const double dragDeadZone = 5.0;

  // ========================================
  // ✨ VISUAL EFFECTS
  // ========================================
  
  /// Default particle count for effects
  static const int particleCount = 15;
  
  /// Particle lifetime in seconds
  static const double particleLifetime = 2.0;
  
  /// Maximum simultaneous glow effects
  static const int maxGlowEffects = 3;

  // ========================================
  // 🏅 ACHIEVEMENT THRESHOLDS
  // ========================================
  
  /// Achievement target values
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

  // ========================================
  // 🎬 ANIMATION & TIMING
  // ========================================
  
  /// Short animation duration for quick UI transitions
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  
  /// Medium animation duration for standard animations
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  
  /// Long animation duration for complex animations
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  /// Extra long animation duration for special effects
  static const Duration extraLongAnimationDuration = Duration(milliseconds: 1200);
  
  /// Splash screen minimum display duration
  static const Duration splashMinDuration = Duration(milliseconds: 2000);
  
  /// Auto-save interval for game state
  static const Duration autoSaveInterval = Duration(seconds: 30);
  
  /// Debounce duration for user input
  static const Duration inputDebounceDelay = Duration(milliseconds: 300);
  
  /// Animation delay between sequential elements
  static const Duration animationStaggerDelay = Duration(milliseconds: 100);

  // ========================================
  // ⚡ PERFORMANCE & DEBUG
  // ========================================
  
  /// Enable debug logging throughout the application
  static const bool enableDebugLogging = kDebugMode;
  
  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = kDebugMode;
  
  /// Frame time threshold for performance warnings (in seconds)
  static const double frameTimeThreshold = 1.0 / 45.0; // ~22ms for 45 FPS warning
  
  /// Target frame rate for the game
  static const double targetFrameRate = 60.0;
  
  /// Maximum object pool size to prevent memory bloat
  static const int objectPoolSize = 100;
  
  /// Maximum cached assets
  static const int maxCachedAssets = 200;
  
  /// Memory warning threshold (MB)
  static const int memoryWarningThreshold = 100;
  
  /// Performance monitoring sample size
  static const int performanceSampleSize = 60;

  // ========================================
  // 🔊 AUDIO SETTINGS
  // ========================================
  
  /// Default music volume (0.0 - 1.0)
  static const double defaultMusicVolume = 0.7;
  
  /// Default sound effects volume (0.0 - 1.0)
  static const double defaultSfxVolume = 0.8;
  
  /// Minimum volume level
  static const double minVolume = 0.0;
  
  /// Maximum volume level
  static const double maxVolume = 1.0;
  
  /// Audio fade duration
  static const Duration audioFadeDuration = Duration(milliseconds: 500);
  
  /// Sound debounce interval (prevent rapid repeated sounds)
  static const Duration soundDebounceInterval = Duration(milliseconds: 100);

  // ========================================
  // 💾 STORAGE KEYS
  // ========================================
  
  /// Key for storing player statistics
  static const String playerStatsKey = 'player_stats';
  
  /// Key for storing game achievements
  static const String achievementsKey = 'achievements';
  
  /// Key for storing app settings
  static const String settingsKey = 'app_settings';
  
  /// Key for storing game state
  static const String gameStateKey = 'game_state';
  static const String gameDataKey = 'game_state'; // Alias for compatibility
  
  /// Key for storing high scores
  static const String highScoresKey = 'high_scores';
  
  /// Key for storing tutorial progress
  static const String tutorialKey = 'tutorial_progress';
  
  /// Key for storing user preferences
  static const String preferencesKey = 'user_preferences';

  // ========================================
  // 🌐 NETWORK & API
  // ========================================
  
  /// API base URL (if using remote services)
  static const String apiBaseUrl = 'https://api.yourcompany.com/v1';
  
  /// API timeout duration
  static const Duration apiTimeout = Duration(seconds: 30);
  
  /// Maximum retry attempts for network requests
  static const int maxRetryAttempts = 3;
  
  /// Retry delay
  static const Duration retryDelay = Duration(seconds: 2);

  // ========================================
  // 📋 VALIDATION
  // ========================================
  
  /// Email validation regex
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  /// Username validation regex (alphanumeric + underscore)
  static const String usernameRegex = r'^[a-zA-Z0-9_]{3,20}$';
  
  /// Profanity filter (basic words to block)
  static const List<String> profanityFilter = [
    // Add appropriate words for your app
  ];

  // ========================================
  // 🎯 FEATURE FLAGS
  // ========================================
  
  /// Enable new tutorial system
  static const bool enableNewTutorial = true;
  
  /// Enable cloud save
  static const bool enableCloudSave = false;
  
  /// Enable social features
  static const bool enableSocialFeatures = false;
  
  /// Enable analytics
  static const bool enableCrashlytics = !kDebugMode;
  
  /// Enable push notifications
  static const bool enablePushNotifications = false;

  // ========================================
  // 🔍 DEBUG FLAGS
  // ========================================
  
  /// Show performance overlay
  static const bool showPerformanceOverlay = kDebugMode;
  
  /// Show debug grid
  static const bool showDebugGrid = false;
  
  /// Enable verbose logging
  static const bool enableVerboseLogging = kDebugMode;
  
  /// Skip splash screen in debug
  static const bool skipSplashInDebug = kDebugMode;
  
  /// Enable dev menu
  static const bool enableDevMenu = kDebugMode;

  // ========================================
  // 📦 ASSET CONSTANTS
  // ========================================
  
  /// Asset loading timeout
  static const Duration assetLoadTimeout = Duration(seconds: 30);
  
  /// Maximum concurrent asset loads
  static const int maxConcurrentAssetLoads = 5;
  
  /// Asset retry attempts
  static const int assetRetryAttempts = 3;
  
  /// Asset cache duration
  static const Duration assetCacheDuration = Duration(days: 7);

  // ========================================
  // 🔄 STATE MANAGEMENT
  // ========================================
  
  /// State persistence interval
  static const Duration statePersistenceInterval = Duration(seconds: 10);
  
  /// Maximum state history size
  static const int maxStateHistorySize = 50;
  
  /// Bloc event timeout
  static const Duration blocEventTimeout = Duration(seconds: 30);

  // ========================================
  // 📱 PLATFORM SPECIFIC
  // ========================================
  
  /// iOS App Store ID
  static const String iosAppStoreId = '123456789';
  
  /// Android package name
  static const String androidPackageName = packageName;
  
  /// Minimum Android SDK version
  static const int minAndroidSdk = 21;
  
  /// Minimum iOS version
  static const String minIosVersion = '12.0';
}

/// App page enumeration for navigation
enum AppPage {
  splash,
  mainMenu,
  game,
  settings,
  achievements,
  tutorial,
  help,
  about,
}

/// Game difficulty levels
enum GameDifficulty {
  easy,
  normal,
  hard,
  expert,
}

/// Animation states
enum AnimationState {
  idle,
  animating,
  paused,
}

/// App theme modes
enum AppThemeMode {
  light,
  dark,
  system,
}

// ========================================
// DEPRECATED - FOR MIGRATION ONLY
// ========================================

/// @deprecated Use AppConstants instead
/// This class exists only for migration compatibility
/// All imports should be changed to use AppConstants
class GameConstants {
  // Redirect all GameConstants to AppConstants
  static int get gridSize => AppConstants.gridSize;
  static double get cellSpacing => AppConstants.cellSpacing;
  static double get gridSpacing => AppConstants.gridSpacing;
  static double get cellBorderRadius => AppConstants.cellBorderRadius;
  static double get gridPadding => AppConstants.gridPadding;
  static int get maxActiveBlocks => AppConstants.maxActiveBlocks;
  static double get blockSpacing => AppConstants.blockSpacing;
  static double get blockBorderRadius => AppConstants.blockBorderRadius;
  static double get dragScaleMultiplier => AppConstants.dragScaleMultiplier;
  static Map<String, int> get baseScores => AppConstants.baseScores;
  static List<double> get comboMultipliers => AppConstants.comboMultipliers;
  static Map<int, int> get streakBonuses => AppConstants.streakBonuses;
  static Map<String, int> get powerUpCosts => AppConstants.powerUpCosts;
  static int get maxUndoCount => AppConstants.maxUndoCount;
  static int get maxHints => AppConstants.maxHints;
  static int get startingCoins => AppConstants.startingCoins;
  static int get dailyBonusCoins => AppConstants.dailyBonusCoins;
  static int get adRewardCoins => AppConstants.adRewardCoins;
  static int get achievementBonusCoins => AppConstants.achievementBonusCoins;
  static int get linesPerLevel => AppConstants.linesPerLevel;
  static double get difficultyIncrease => AppConstants.difficultyIncrease;
  static double get maxDifficulty => AppConstants.maxDifficulty;
  static int get gameOverThreshold => AppConstants.gameOverThreshold;
  static double get snapThreshold => AppConstants.snapThreshold;
  static double get collisionTolerance => AppConstants.collisionTolerance;
  static double get dragDeadZone => AppConstants.dragDeadZone;
  static int get particleCount => AppConstants.particleCount;
  static double get particleLifetime => AppConstants.particleLifetime;
  static int get maxGlowEffects => AppConstants.maxGlowEffects;
  static Map<String, int> get achievementTargets => AppConstants.achievementTargets;
}