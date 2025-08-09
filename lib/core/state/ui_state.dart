

import 'package:equatable/equatable.dart';

/// UIState represents the global UI state of the application.
/// Includes navigation, overlays, settings, notifications, and user preferences.
/// Uses Equatable for efficient state comparison and updates.
class UIState extends Equatable {
  // ========================================
  // NAVIGATION STATE
  // ========================================
  
  /// Current active page
  final AppPage currentPage;
  
  /// Navigation arguments for the current page
  final Map<String, dynamic>? navigationArguments;
  
  /// Last navigation timestamp
  final DateTime? lastNavigationTime;

  // ========================================
  // OVERLAY STATE
  // ========================================
  
  /// Whether pause overlay is visible
  final bool showPauseOverlay;
  
  /// Whether game over overlay is visible
  final bool showGameOverOverlay;
  
  /// Whether settings overlay is visible
  final bool showSettingsOverlay;
  
  /// Whether achievement notification is visible
  final bool showAchievementNotification;
  
  /// Whether loading overlay is visible
  final bool isLoading;
  
  /// Current overlay type
  final OverlayType? overlayType;
  
  /// Game over results data
  final Map<String, dynamic>? gameOverResults;
  
  /// Current achievement being shown
  final Achievement? currentAchievement;
  
  /// Loading message
  final String? loadingMessage;

  // ========================================
  // NOTIFICATION STATE
  // ========================================
  
  /// Whether there's an error to display
  final bool hasError;
  
  /// Error message
  final String? errorMessage;
  
  /// Error type
  final ErrorType? errorType;
  
  /// Whether there's a success message
  final bool hasSuccess;
  
  /// Success message
  final String? successMessage;
  
  /// Whether there's an info message
  final bool hasInfo;
  
  /// Info message
  final String? infoMessage;

  // ========================================
  // AUDIO SETTINGS
  // ========================================
  
  /// Whether music is enabled
  final bool musicEnabled;
  
  /// Whether sound effects are enabled
  final bool soundEnabled;
  
  /// Music volume (0.0 to 1.0)
  final double musicVolume;
  
  /// Sound effects volume (0.0 to 1.0)
  final double soundVolume;

  // ========================================
  // USER PREFERENCES
  // ========================================
  
  /// Whether haptic feedback is enabled
  final bool hapticsEnabled;
  
  /// Current app theme
  final AppTheme currentTheme;
  
  /// Current app language
  final AppLanguage currentLanguage;
  
  /// Performance mode setting
  final PerformanceMode performanceMode;

  // ========================================
  // TUTORIAL STATE
  // ========================================
  
  /// Whether tutorial is currently showing
  final bool showTutorial;
  
  /// Current tutorial step
  final int tutorialStep;
  
  /// Whether tutorial has been completed
  final bool tutorialCompleted;
  
  /// Whether tutorial was skipped
  final bool tutorialSkipped;

  // ========================================
  // VISUAL SETTINGS
  // ========================================
  
  /// Whether particles are enabled
  final bool particlesEnabled;
  
  /// Whether animations are enabled
  final bool animationsEnabled;
  
  /// Whether shadows are enabled
  final bool shadowsEnabled;

  // ========================================
  // SOUND EFFECTS
  // ========================================
  
  /// Whether a sound should be played
  final bool shouldPlaySound;
  
  /// Sound effect to play
  final String? soundEffect;

  const UIState({
    // Navigation
    this.currentPage = AppPage.splash,
    this.navigationArguments,
    this.lastNavigationTime,
    
    // Overlays
    this.showPauseOverlay = false,
    this.showGameOverOverlay = false,
    this.showSettingsOverlay = false,
    this.showAchievementNotification = false,
    this.isLoading = false,
    this.overlayType,
    this.gameOverResults,
    this.currentAchievement,
    this.loadingMessage,
    
    // Notifications
    this.hasError = false,
    this.errorMessage,
    this.errorType,
    this.hasSuccess = false,
    this.successMessage,
    this.hasInfo = false,
    this.infoMessage,
    
    // Audio
    this.musicEnabled = true,
    this.soundEnabled = true,
    this.musicVolume = 0.7,
    this.soundVolume = 0.8,
    
    // Preferences
    this.hapticsEnabled = true,
    this.currentTheme = AppTheme.dark,
    this.currentLanguage = AppLanguage.english,
    this.performanceMode = PerformanceMode.balanced,
    
    // Tutorial
    this.showTutorial = false,
    this.tutorialStep = 0,
    this.tutorialCompleted = false,
    this.tutorialSkipped = false,
    
    // Visual
    this.particlesEnabled = true,
    this.animationsEnabled = true,
    this.shadowsEnabled = true,
    
    // Sound effects
    this.shouldPlaySound = false,
    this.soundEffect,
  });

  /// Create a copy of the state with updated values
  UIState copyWith({
    // Navigation
    AppPage? currentPage,
    Map<String, dynamic>? navigationArguments,
    DateTime? lastNavigationTime,
    
    // Overlays
    bool? showPauseOverlay,
    bool? showGameOverOverlay,
    bool? showSettingsOverlay,
    bool? showAchievementNotification,
    bool? isLoading,
    OverlayType? overlayType,
    Map<String, dynamic>? gameOverResults,
    Achievement? currentAchievement,
    String? loadingMessage,
    
    // Notifications
    bool? hasError,
    String? errorMessage,
    ErrorType? errorType,
    bool? hasSuccess,
    String? successMessage,
    bool? hasInfo,
    String? infoMessage,
    
    // Audio
    bool? musicEnabled,
    bool? soundEnabled,
    double? musicVolume,
    double? soundVolume,
    
    // Preferences
    bool? hapticsEnabled,
    AppTheme? currentTheme,
    AppLanguage? currentLanguage,
    PerformanceMode? performanceMode,
    
    // Tutorial
    bool? showTutorial,
    int? tutorialStep,
    bool? tutorialCompleted,
    bool? tutorialSkipped,
    
    // Visual
    bool? particlesEnabled,
    bool? animationsEnabled,
    bool? shadowsEnabled,
    
    // Sound effects
    bool? shouldPlaySound,
    String? soundEffect,
  }) {
    return UIState(
      // Navigation
      currentPage: currentPage ?? this.currentPage,
      navigationArguments: navigationArguments ?? this.navigationArguments,
      lastNavigationTime: lastNavigationTime ?? this.lastNavigationTime,
      
      // Overlays
      showPauseOverlay: showPauseOverlay ?? this.showPauseOverlay,
      showGameOverOverlay: showGameOverOverlay ?? this.showGameOverOverlay,
      showSettingsOverlay: showSettingsOverlay ?? this.showSettingsOverlay,
      showAchievementNotification: showAchievementNotification ?? this.showAchievementNotification,
      isLoading: isLoading ?? this.isLoading,
      overlayType: overlayType ?? this.overlayType,
      gameOverResults: gameOverResults ?? this.gameOverResults,
      currentAchievement: currentAchievement ?? this.currentAchievement,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      
      // Notifications
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      hasSuccess: hasSuccess ?? this.hasSuccess,
      successMessage: successMessage ?? this.successMessage,
      hasInfo: hasInfo ?? this.hasInfo,
      infoMessage: infoMessage ?? this.infoMessage,
      
      // Audio
      musicEnabled: musicEnabled ?? this.musicEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicVolume: musicVolume ?? this.musicVolume,
      soundVolume: soundVolume ?? this.soundVolume,
      
      // Preferences
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      currentTheme: currentTheme ?? this.currentTheme,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      performanceMode: performanceMode ?? this.performanceMode,
      
      // Tutorial
      showTutorial: showTutorial ?? this.showTutorial,
      tutorialStep: tutorialStep ?? this.tutorialStep,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      tutorialSkipped: tutorialSkipped ?? this.tutorialSkipped,
      
      // Visual
      particlesEnabled: particlesEnabled ?? this.particlesEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      shadowsEnabled: shadowsEnabled ?? this.shadowsEnabled,
      
      // Sound effects
      shouldPlaySound: shouldPlaySound ?? this.shouldPlaySound,
      soundEffect: soundEffect ?? this.soundEffect,
    );
  }

  // ========================================
  // CONVENIENCE GETTERS
  // ========================================

  /// Check if any overlay is currently showing
  bool get hasActiveOverlay {
    return showPauseOverlay ||
           showGameOverOverlay ||
           showSettingsOverlay ||
           showAchievementNotification ||
           isLoading;
  }

  /// Check if any notification is active
  bool get hasActiveNotification {
    return hasError || hasSuccess || hasInfo;
  }

  /// Check if tutorial should be shown to new users
  bool get shouldShowTutorial {
    return !tutorialCompleted && !tutorialSkipped;
  }

  /// Get current overlay priority (higher = more important)
  int get overlayPriority {
    if (isLoading) return 100; // Loading has highest priority
    if (hasError) return 90; // Errors are important
    if (showGameOverOverlay) return 80;
    if (showPauseOverlay) return 70;
    if (showSettingsOverlay) return 60;
    if (showAchievementNotification) return 50;
    if (showTutorial) return 40;
    return 0; // No overlay
  }

  /// Check if game can be interacted with (no blocking overlays)
  bool get canInteractWithGame {
    return !isLoading &&
           !showSettingsOverlay &&
           !showGameOverOverlay &&
           !hasError;
  }

  /// Get formatted volume percentage for display
  String get musicVolumePercentage {
    return '${(musicVolume * 100).round()}%';
  }

  /// Get formatted volume percentage for display
  String get soundVolumePercentage {
    return '${(soundVolume * 100).round()}%';
  }

  /// Get performance mode display text
  String get performanceModeText {
    switch (performanceMode) {
      case PerformanceMode.quality:
        return 'High Quality';
      case PerformanceMode.balanced:
        return 'Balanced';
      case PerformanceMode.performance:
        return 'High Performance';
    }
  }

  /// Get theme display name
  String get themeDisplayName {
    switch (currentTheme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.auto:
        return 'Auto';
    }
  }

  /// Get language display name
  String get languageDisplayName {
    switch (currentLanguage) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.spanish:
        return 'Español';
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.german:
        return 'Deutsch';
      case AppLanguage.japanese:
        return '日本語';
    }
  }

  /// Check if high performance mode is active
  bool get isHighPerformanceMode {
    return performanceMode == PerformanceMode.performance;
  }

  /// Check if should reduce visual effects
  bool get shouldReduceEffects {
    return !particlesEnabled || !animationsEnabled;
  }

  @override
  List<Object?> get props => [
        // Navigation
        currentPage,
        navigationArguments,
        lastNavigationTime,
        
        // Overlays
        showPauseOverlay,
        showGameOverOverlay,
        showSettingsOverlay,
        showAchievementNotification,
        isLoading,
        overlayType,
        gameOverResults,
        currentAchievement,
        loadingMessage,
        
        // Notifications
        hasError,
        errorMessage,
        errorType,
        hasSuccess,
        successMessage,
        hasInfo,
        infoMessage,
        
        // Audio
        musicEnabled,
        soundEnabled,
        musicVolume,
        soundVolume,
        
        // Preferences
        hapticsEnabled,
        currentTheme,
        currentLanguage,
        performanceMode,
        
        // Tutorial
        showTutorial,
        tutorialStep,
        tutorialCompleted,
        tutorialSkipped,
        
        // Visual
        particlesEnabled,
        animationsEnabled,
        shadowsEnabled,
        
        // Sound effects
        shouldPlaySound,
        soundEffect,
      ];

  @override
  String toString() {
    return 'UIState('
        'currentPage: $currentPage, '
        'hasOverlay: $hasActiveOverlay, '
        'hasNotification: $hasActiveNotification, '
        'musicEnabled: $musicEnabled, '
        'soundEnabled: $soundEnabled'
        ')';
  }
}

/// App page enumeration
enum AppPage {
  splash,
  mainMenu,
  game,
  settings,
  achievements,
  leaderboard,
   store;
  
  String get name => toString().split('.').last;
}

/// Overlay type enumeration
enum OverlayType {
  pause,
  gameOver,
  settings,
  achievement,
  loading,
  tutorial;
  
  String get name => toString().split('.').last;
}

/// Error type enumeration
enum ErrorType {
  general,
  network,
  storage,
  audio,
  game;
  
  String get name => toString().split('.').last;
}

/// App theme enumeration
enum AppTheme {
  light,
  dark,
  auto;
  
  String get name => toString().split('.').last;
}

/// App language enumeration
enum AppLanguage {
  english,
  spanish,
  french,
  german,
  japanese;
  
  String get name => toString().split('.').last;
  
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.german:
        return 'de';
      case AppLanguage.japanese:
        return 'ja';
    }
  }
}

/// Performance mode enumeration
enum PerformanceMode {
  quality,
  balanced,
  performance;
  
  String get name => toString().split('.').last;
  
  String get description {
    switch (this) {
      case PerformanceMode.quality:
        return 'Best visual quality with all effects enabled';
      case PerformanceMode.balanced:
        return 'Good balance between quality and performance';
      case PerformanceMode.performance:
        return 'Best performance with reduced visual effects';
    }
  }
}

/// Achievement data for notifications
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final int coinReward;
  final DateTime? unlockedDate;
  final String iconPath;
  final AchievementRarity rarity;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.coinReward = 0,
    this.unlockedDate,
    required this.iconPath,
    this.rarity = AchievementRarity.common,
  });

  /// Create a copy with updated values
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    int? coinReward,
    DateTime? unlockedDate,
    String? iconPath,
    AchievementRarity? rarity,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coinReward: coinReward ?? this.coinReward,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      iconPath: iconPath ?? this.iconPath,
      rarity: rarity ?? this.rarity,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coinReward': coinReward,
      'unlockedDate': unlockedDate?.toIso8601String(),
      'iconPath': iconPath,
      'rarity': rarity.name,
    };
  }

  /// Create from JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      coinReward: json['coinReward'] as int? ?? 0,
      unlockedDate: json['unlockedDate'] != null
          ? DateTime.parse(json['unlockedDate'] as String)
          : null,
      iconPath: json['iconPath'] as String,
      rarity: AchievementRarity.values.firstWhere(
        (r) => r.name == (json['rarity'] as String?),
        orElse: () => AchievementRarity.common,
      ),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        coinReward,
        unlockedDate,
        iconPath,
        rarity,
      ];
}

/// Achievement rarity enumeration
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary;
  
  String get name => toString().split('.').last;
  
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }
}