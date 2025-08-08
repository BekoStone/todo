// File: lib/core/constants/app_constants.dart

import 'package:flutter/foundation.dart';

/// Global application constants for the Box Hooks puzzle game.
/// Contains configuration values, settings, and magic numbers used throughout the app.
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
  
  /// Key for storing high scores
  static const String highScoresKey = 'high_scores';
  
  /// Key for storing last claim date for daily rewards
  static const String lastClaimDateKey = 'last_claim_date';
  
  /// Key for storing user preferences
  static const String userPreferencesKey = 'user_preferences';
  
  /// Key for storing tutorial completion status
  static const String tutorialCompletedKey = 'tutorial_completed';
  
  /// Key for storing first launch flag
  static const String firstLaunchKey = 'first_launch';

  // ========================================
  // 🎮 GAME CONFIGURATION
  // ========================================
  
  /// Default grid size (8x8)
  static const int defaultGridSize = 8;
  
  /// Minimum grid size
  static const int minGridSize = 6;
  
  /// Maximum grid size
  static const int maxGridSize = 12;
  
  /// Number of block slots
  static const int blockSlotCount = 3;
  
  /// Maximum blocks that can be active
  static const int maxActiveBlocks = 3;
  
  /// Base score for placing a block
  static const int baseBlockScore = 10;
  
  /// Score multiplier for line clears
  static const int lineClearMultiplier = 100;
  
  /// Score multiplier for combos
  static const int comboMultiplier = 50;
  
  /// Maximum combo streak
  static const int maxComboStreak = 10;
  
  /// Blocks needed for next level
  static const int blocksPerLevel = 50;
  
  /// Maximum undo actions per game
  static const int maxUndoActions = 3;

  // ========================================
  // 🏆 ACHIEVEMENTS & PROGRESSION
  // ========================================
  
  /// Number of top scores to track
  static const int maxHighScores = 10;
  
  /// Coins awarded for daily login
  static const int dailyLoginReward = 50;
  
  /// Base coins earned per line clear
  static const int baseCoinsPerLine = 5;
  
  /// Achievement coin rewards
  static const int achievementCoinReward = 100;
  
  /// Perfect clear coin bonus
  static const int perfectClearBonus = 500;
  
  /// Level up coin reward
  static const int levelUpCoinReward = 25;

  // ========================================
  // 🔧 UI/UX CONFIGURATION
  // ========================================
  
  /// Default button height
  static const double defaultButtonHeight = 48.0;
  
  /// Default border radius
  static const double defaultBorderRadius = 12.0;
  
  /// Default padding
  static const double defaultPadding = 16.0;
  
  /// Default margin
  static const double defaultMargin = 8.0;
  
  /// Minimum touch target size (accessibility)
  static const double minTouchTargetSize = 44.0;
  
  /// Maximum text scale factor
  static const double maxTextScaleFactor = 1.4;
  
  /// Minimum text scale factor
  static const double minTextScaleFactor = 0.8;
  
  /// Default elevation for cards
  static const double defaultElevation = 4.0;
  
  /// Grid spacing between cells
  static const double gridSpacing = 2.0;

  // ========================================
  // 📱 RESPONSIVE BREAKPOINTS
  // ========================================
  
  /// Mobile breakpoint (max width)
  static const double mobileBreakpoint = 768.0;
  
  /// Tablet breakpoint (max width)
  static const double tabletBreakpoint = 1200.0;
  
  /// Desktop breakpoint (min width)
  static const double desktopBreakpoint = 1200.0;
  
  /// Minimum safe area for UI elements
  static const double minSafeArea = 16.0;

  // ========================================
  // 🌐 NETWORK & API
  // ========================================
  
  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  /// Retry attempts for failed requests
  static const int maxRetryAttempts = 3;
  
  /// Retry delay between attempts
  static const Duration retryDelay = Duration(seconds: 2);

  // ========================================
  // 🔐 SECURITY & VALIDATION
  // ========================================
  
  /// Maximum player name length
  static const int maxPlayerNameLength = 20;
  
  /// Minimum player name length
  static const int minPlayerNameLength = 3;
  
  /// Session timeout duration
  static const Duration sessionTimeout = Duration(hours: 24);
  
  /// Maximum file size for uploads (bytes)
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  
  /// Allowed file extensions for uploads
  static const List<String> allowedFileExtensions = ['.jpg', '.jpeg', '.png'];

  // ========================================
  // 📊 ANALYTICS & TRACKING
  // ========================================
  
  /// Enable analytics tracking
  static const bool enableAnalytics = !kDebugMode;
  
  /// Analytics batch size
  static const int analyticsBatchSize = 20;
  
  /// Analytics flush interval
  static const Duration analyticsFlushInterval = Duration(minutes: 5);
  
  /// Maximum events to store offline
  static const int maxOfflineEvents = 1000;

  // ========================================
  // 🎲 GAME DIFFICULTY SETTINGS
  // ========================================
  
  /// Easy mode configuration
  static const Map<String, dynamic> easyModeConfig = {
    'gridSize': 8,
    'scoreMultiplier': 1.0,
    'timeLimit': null,
    'hintsAvailable': true,
  };
  
  /// Normal mode configuration
  static const Map<String, dynamic> normalModeConfig = {
    'gridSize': 8,
    'scoreMultiplier': 1.2,
    'timeLimit': null,
    'hintsAvailable': true,
  };
  
  /// Hard mode configuration
  static const Map<String, dynamic> hardModeConfig = {
    'gridSize': 8,
    'scoreMultiplier': 1.5,
    'timeLimit': null,
    'hintsAvailable': false,
  };
  
  /// Expert mode configuration
  static const Map<String, dynamic> expertModeConfig = {
    'gridSize': 10,
    'scoreMultiplier': 2.0,
    'timeLimit': 300, // 5 minutes
    'hintsAvailable': false,
  };

  // ========================================
  // 🎨 VISUAL EFFECTS
  // ========================================
  
  /// Particle effect duration
  static const Duration particleEffectDuration = Duration(milliseconds: 1200);
  
  /// Number of particles for block placement
  static const int blockPlacementParticles = 15;
  
  /// Number of particles for line clear
  static const int lineClearParticles = 25;
  
  /// Number of particles for combo effect
  static const int comboParticles = 30;
  
  /// Shake effect duration
  static const Duration shakeEffectDuration = Duration(milliseconds: 500);
  
  /// Flash effect duration
  static const Duration flashEffectDuration = Duration(milliseconds: 200);

  // ========================================
  // 📄 HELP & DOCUMENTATION
  // ========================================
  
  /// Tutorial steps count
  static const int tutorialStepsCount = 8;
  
  /// Help sections
  static const List<String> helpSections = [
    'Getting Started',
    'Game Rules',
    'Scoring System',
    'Power-ups',
    'Achievements',
    'Settings',
    'Troubleshooting',
    'Contact Support',
  ];

  // ========================================
  // 🌍 LOCALIZATION
  // ========================================
  
  /// Default locale
  static const String defaultLocale = 'en';
  
  /// Supported locales
  static const List<String> supportedLocales = [
    'en', // English
    'es', // Spanish
    'fr', // French
    'de', // German
    'ja', // Japanese
    'ko', // Korean
    'zh', // Chinese
  ];

  // ========================================
  // 💸 MONETIZATION (if applicable)
  // ========================================
  
  /// Ad display frequency (games between ads)
  static const int adFrequency = 5;
  
  /// Reward video coin amount
  static const int rewardVideoCoinAmount = 100;
  
  /// Daily reward streak multiplier
  static const double dailyStreakMultiplier = 1.2;
  
  /// Maximum daily streak days
  static const int maxDailyStreakDays = 7;

  // ========================================
  // 🛠️ DEVELOPMENT & TESTING
  // ========================================
  
  /// Enable dev tools in debug mode
  static const bool enableDevTools = kDebugMode;
  
  /// Enable test data
  static const bool enableTestData = kDebugMode;
  
  /// Test user ID
  static const String testUserId = 'test_user_123';
  
  /// Mock data delay for simulating network requests
  static const Duration mockDataDelay = Duration(milliseconds: 500);

  // ========================================
  // 📏 VALIDATION HELPERS
  // ========================================
  
  /// Email validation regex
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  
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