import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// PlayerStats entity represents comprehensive player statistics and progression.
/// Contains all persistent data for a player's progress, achievements, and settings.
/// Immutable entity following Clean Architecture principles.
class PlayerStats extends Equatable {
  /// Unique player identifier
  final String playerId;
  
  /// Player creation date
  final DateTime createdAt;
  
  /// Last time player data was updated
  final DateTime lastUpdated;
  
  /// Last login date for daily bonus tracking
  final DateTime? lastLoginDate;
  
  /// Last game played date
  final DateTime? lastGameDate;

  // ========================================
  // CORE STATISTICS
  // ========================================
  
  /// Total games played
  final int totalGamesPlayed;
  
  /// Total games completed successfully
  final int totalGamesCompleted;
  
  /// Player's highest score
  final int highScore;
  
  /// Total cumulative score across all games
  final int totalScore;
  
  /// Average score per game
  final double averageScore;
  
  /// Total lines cleared across all games
  final int totalLinesCleared;
  
  /// Total blocks placed across all games
  final int totalBlocksPlaced;
  
  /// Total play time
  final Duration totalPlayTime;

  // ========================================
  // PROGRESSION
  // ========================================
  
  /// Current player level
  final int currentLevel;
  
  /// Experience points for level progression
  final int experiencePoints;
  
  /// Highest level reached
  final int highestLevel;
  
  /// Per-level statistics
  final Map<int, LevelStats> levelStats;

  // ========================================
  // ECONOMY
  // ========================================
  
  /// Current coin balance
  final int totalCoins;
  
  /// Total coins earned (lifetime)
  final int totalCoinsEarned;
  
  /// Total coins spent (lifetime)
  final int totalCoinsSpent;
  
  /// Premium currency balance
  final int premiumCurrency;

  // ========================================
  // ACHIEVEMENTS & STREAKS
  // ========================================
  
  /// Total achievements unlocked
  final int totalAchievementsUnlocked;
  
  /// Best combo streak achieved
  final int bestStreak;
  
  /// Best combo multiplier achieved
  final int bestCombo;
  
  /// Total perfect clears achieved
  final int totalPerfectClears;
  
  /// Consecutive login days
  final int consecutiveLoginDays;
  
  /// Total login days (lifetime)
  final int totalLoginDays;

  // ========================================
  // PREFERENCES & SETTINGS
  // ========================================
  
  /// Whether player has premium features
  final bool hasPremium;
  
  /// Player's preferred difficulty
  final String preferredDifficulty;
  
  /// Tutorial completion status
  final bool tutorialCompleted;
  
  /// Player preferences
  final Map<String, dynamic> preferences;

  // ========================================
  // SESSION TRACKING
  // ========================================
  
  /// Statistics for current session
  final SessionTracker sessionTracker;
  
  /// Recent performance data
  final List<GamePerformanceData> recentPerformance;

  const PlayerStats({
    required this.playerId,
    required this.createdAt,
    required this.lastUpdated,
    this.lastLoginDate,
    this.lastGameDate,
    
    // Core statistics
    this.totalGamesPlayed = 0,
    this.totalGamesCompleted = 0,
    this.highScore = 0,
    this.totalScore = 0,
    this.averageScore = 0.0,
    this.totalLinesCleared = 0,
    this.totalBlocksPlaced = 0,
    this.totalPlayTime = Duration.zero,
    
    // Progression
    this.currentLevel = 1,
    this.experiencePoints = 0,
    this.highestLevel = 1,
    this.levelStats = const {},
    
    // Economy
    this.totalCoins = AppConstants.startingCoins,
    this.totalCoinsEarned = 0,
    this.totalCoinsSpent = 0,
    this.premiumCurrency = 0,
    
    // Achievements & streaks
    this.totalAchievementsUnlocked = 0,
    this.bestStreak = 0,
    this.bestCombo = 0,
    this.totalPerfectClears = 0,
    this.consecutiveLoginDays = 0,
    this.totalLoginDays = 0,
    
    // Preferences
    this.hasPremium = false,
    this.preferredDifficulty = 'normal',
    this.tutorialCompleted = false,
    this.preferences = const {},
    
    // Session tracking
    required this.sessionTracker,
    this.recentPerformance = const [],
  });

  /// Create default player stats for new players
  factory PlayerStats.createDefault({String? playerId}) {
    final now = DateTime.now();
    final id = playerId ?? _generatePlayerId();
    
    return PlayerStats(
      playerId: id,
      createdAt: now,
      lastUpdated: now,
      sessionTracker: SessionTracker.initial(),
      preferences: {
        'soundEnabled': true,
        'musicEnabled': true,
        'hapticsEnabled': true,
        'theme': 'dark',
        'autoSave': true,
      },
    );
  }

  /// Create a copy with updated values
  PlayerStats copyWith({
    String? playerId,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? lastLoginDate,
    DateTime? lastGameDate,
    
    // Core statistics
    int? totalGamesPlayed,
    int? totalGamesCompleted,
    int? highScore,
    int? totalScore,
    double? averageScore,
    int? totalLinesCleared,
    int? totalBlocksPlaced,
    Duration? totalPlayTime,
    
    // Progression
    int? currentLevel,
    int? experiencePoints,
    int? highestLevel,
    Map<int, LevelStats>? levelStats,
    
    // Economy
    int? totalCoins,
    int? totalCoinsEarned,
    int? totalCoinsSpent,
    int? premiumCurrency,
    
    // Achievements
    int? totalAchievementsUnlocked,
    int? bestStreak,
    int? bestCombo,
    int? totalPerfectClears,
    int? consecutiveLoginDays,
    int? totalLoginDays,
    
    // Preferences
    bool? hasPremium,
    String? preferredDifficulty,
    bool? tutorialCompleted,
    Map<String, dynamic>? preferences,
    
    // Session tracking
    SessionTracker? sessionTracker,
    List<GamePerformanceData>? recentPerformance,
  }) {
    return PlayerStats(
      playerId: playerId ?? this.playerId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      lastGameDate: lastGameDate ?? this.lastGameDate,
      
      // Core statistics
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesCompleted: totalGamesCompleted ?? this.totalGamesCompleted,
      highScore: highScore ?? this.highScore,
      totalScore: totalScore ?? this.totalScore,
      averageScore: averageScore ?? this.averageScore,
      totalLinesCleared: totalLinesCleared ?? this.totalLinesCleared,
      totalBlocksPlaced: totalBlocksPlaced ?? this.totalBlocksPlaced,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      
      // Progression
      currentLevel: currentLevel ?? this.currentLevel,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      highestLevel: highestLevel ?? this.highestLevel,
      levelStats: levelStats ?? this.levelStats,
      
      // Economy
      totalCoins: totalCoins ?? this.totalCoins,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      totalCoinsSpent: totalCoinsSpent ?? this.totalCoinsSpent,
      premiumCurrency: premiumCurrency ?? this.premiumCurrency,
      
      // Achievements
      totalAchievementsUnlocked: totalAchievementsUnlocked ?? this.totalAchievementsUnlocked,
      bestStreak: bestStreak ?? this.bestStreak,
      bestCombo: bestCombo ?? this.bestCombo,
      totalPerfectClears: totalPerfectClears ?? this.totalPerfectClears,
      consecutiveLoginDays: consecutiveLoginDays ?? this.consecutiveLoginDays,
      totalLoginDays: totalLoginDays ?? this.totalLoginDays,
      
      // Preferences
      hasPremium: hasPremium ?? this.hasPremium,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      preferences: preferences ?? this.preferences,
      
      // Session tracking
      sessionTracker: sessionTracker ?? this.sessionTracker,
      recentPerformance: recentPerformance ?? this.recentPerformance,
    );
  }

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  /// Get win rate percentage
  double get winRate {
    return totalGamesPlayed > 0 
        ? (totalGamesCompleted / totalGamesPlayed) * 100 
        : 0.0;
  }

  /// Get average play time per game
  Duration get averagePlayTime {
    return totalGamesPlayed > 0 
        ? Duration(milliseconds: totalPlayTime.inMilliseconds ~/ totalGamesPlayed)
        : Duration.zero;
  }

  /// Get efficiency rating (lines per block)
  double get efficiency {
    return totalBlocksPlaced > 0 
        ? totalLinesCleared / totalBlocksPlaced 
        : 0.0;
  }

  /// Get current player rank based on total score
  PlayerRank get playerRank {
    if (totalScore < 10000) return PlayerRank.bronze;
    if (totalScore < 50000) return PlayerRank.silver;
    if (totalScore < 150000) return PlayerRank.gold;
    if (totalScore < 500000) return PlayerRank.platinum;
    return PlayerRank.diamond;
  }

  /// Get experience points needed for next level
  int get experienceToNextLevel {
    final nextLevelXP = _getXPRequiredForLevel(currentLevel + 1);
    return nextLevelXP - experiencePoints;
  }

  /// Get progress to next level (0.0 to 1.0)
  double get levelProgress {
    final currentLevelXP = _getXPRequiredForLevel(currentLevel);
    final nextLevelXP = _getXPRequiredForLevel(currentLevel + 1);
    final totalXPForLevel = nextLevelXP - currentLevelXP;
    final currentProgress = experiencePoints - currentLevelXP;
    
    return totalXPForLevel > 0 
        ? (currentProgress / totalXPForLevel).clamp(0.0, 1.0)
        : 0.0;
  }

  /// Get net coin balance (earned - spent)
  int get netCoinBalance {
    return totalCoinsEarned - totalCoinsSpent;
  }

  /// Get days since account creation
  int get daysSinceCreation {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Get days since last game
  int get daysSinceLastGame {
    return lastGameDate != null 
        ? DateTime.now().difference(lastGameDate!).inDays
        : daysSinceCreation;
  }

  /// Check if player is active (played recently)
  bool get isActivePlayer {
    return daysSinceLastGame <= 7; // Active if played within a week
  }

  /// Get formatted total play time
  String get formattedPlayTime {
    final hours = totalPlayTime.inHours;
    final minutes = totalPlayTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get completion rate for achievements
  double get achievementCompletionRate {
    const totalAchievements = 50; // Would come from achievement system
    return (totalAchievementsUnlocked / totalAchievements) * 100;
  }

  // ========================================
  // SERIALIZATION
  // ========================================

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'lastGameDate': lastGameDate?.toIso8601String(),
      
      // Core statistics
      'totalGamesPlayed': totalGamesPlayed,
      'totalGamesCompleted': totalGamesCompleted,
      'highScore': highScore,
      'totalScore': totalScore,
      'averageScore': averageScore,
      'totalLinesCleared': totalLinesCleared,
      'totalBlocksPlaced': totalBlocksPlaced,
      'totalPlayTime': totalPlayTime.inMilliseconds,
      
      // Progression
      'currentLevel': currentLevel,
      'experiencePoints': experiencePoints,
      'highestLevel': highestLevel,
      'levelStats': levelStats.map((k, v) => MapEntry(k.toString(), v.toJson())),
      
      // Economy
      'totalCoins': totalCoins,
      'totalCoinsEarned': totalCoinsEarned,
      'totalCoinsSpent': totalCoinsSpent,
      'premiumCurrency': premiumCurrency,
      
      // Achievements
      'totalAchievementsUnlocked': totalAchievementsUnlocked,
      'bestStreak': bestStreak,
      'bestCombo': bestCombo,
      'totalPerfectClears': totalPerfectClears,
      'consecutiveLoginDays': consecutiveLoginDays,
      'totalLoginDays': totalLoginDays,
      
      // Preferences
      'hasPremium': hasPremium,
      'preferredDifficulty': preferredDifficulty,
      'tutorialCompleted': tutorialCompleted,
      'preferences': preferences,
      
      // Session tracking
      'sessionTracker': sessionTracker.toJson(),
      'recentPerformance': recentPerformance.map((p) => p.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerId: json['playerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'] as String)
          : null,
      lastGameDate: json['lastGameDate'] != null
          ? DateTime.parse(json['lastGameDate'] as String)
          : null,
      
      // Core statistics
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalGamesCompleted: json['totalGamesCompleted'] as int? ?? 0,
      highScore: json['highScore'] as int? ?? 0,
      totalScore: json['totalScore'] as int? ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      totalLinesCleared: json['totalLinesCleared'] as int? ?? 0,
      totalBlocksPlaced: json['totalBlocksPlaced'] as int? ?? 0,
      totalPlayTime: Duration(milliseconds: json['totalPlayTime'] as int? ?? 0),
      
      // Progression
      currentLevel: json['currentLevel'] as int? ?? 1,
      experiencePoints: json['experiencePoints'] as int? ?? 0,
      highestLevel: json['highestLevel'] as int? ?? 1,
      levelStats: (json['levelStats'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(int.parse(k), LevelStats.fromJson(v)),
      ) ?? {},
      
      // Economy
      totalCoins: json['totalCoins'] as int? ?? AppConstants.startingCoins,
      totalCoinsEarned: json['totalCoinsEarned'] as int? ?? 0,
      totalCoinsSpent: json['totalCoinsSpent'] as int? ?? 0,
      premiumCurrency: json['premiumCurrency'] as int? ?? 0,
      
      // Achievements
      totalAchievementsUnlocked: json['totalAchievementsUnlocked'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      bestCombo: json['bestCombo'] as int? ?? 0,
      totalPerfectClears: json['totalPerfectClears'] as int? ?? 0,
      consecutiveLoginDays: json['consecutiveLoginDays'] as int? ?? 0,
      totalLoginDays: json['totalLoginDays'] as int? ?? 0,
      
      // Preferences
      hasPremium: json['hasPremium'] as bool? ?? false,
      preferredDifficulty: json['preferredDifficulty'] as String? ?? 'normal',
      tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      
      // Session tracking
      sessionTracker: SessionTracker.fromJson(json['sessionTracker']),
      recentPerformance: (json['recentPerformance'] as List?)
          ?.map((p) => GamePerformanceData.fromJson(p))
          .toList() ?? [],
    );
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Calculate XP required for a given level
  int _getXPRequiredForLevel(int level) {
    // Exponential growth: level^2 * 100
    return level * level * 100;
  }

  /// Generate a unique player ID
  static String _generatePlayerId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'player_${timestamp}_${timestamp.hashCode.abs()}';
  }

  @override
  List<Object?> get props => [
        playerId,
        createdAt,
        lastUpdated,
        lastLoginDate,
        lastGameDate,
        totalGamesPlayed,
        totalGamesCompleted,
        highScore,
        totalScore,
        averageScore,
        totalLinesCleared,
        totalBlocksPlaced,
        totalPlayTime,
        currentLevel,
        experiencePoints,
        highestLevel,
        levelStats,
        totalCoins,
        totalCoinsEarned,
        totalCoinsSpent,
        premiumCurrency,
        totalAchievementsUnlocked,
        bestStreak,
        bestCombo,
        totalPerfectClears,
        consecutiveLoginDays,
        totalLoginDays,
        hasPremium,
        preferredDifficulty,
        tutorialCompleted,
        preferences,
        sessionTracker,
        recentPerformance,
      ];

  @override
  String toString() {
    return 'PlayerStats('
        'id: $playerId, '
        'level: $currentLevel, '
        'score: $totalScore, '
        'games: $totalGamesPlayed'
        ')';
  }
}

/// Session tracker for current session data
class SessionTracker extends Equatable {
  final DateTime sessionStart;
  final int gamesThisSession;
  final int scoreThisSession;
  final Duration playTimeThisSession;

  const SessionTracker({
    required this.sessionStart,
    this.gamesThisSession = 0,
    this.scoreThisSession = 0,
    this.playTimeThisSession = Duration.zero,
  });

  factory SessionTracker.initial() {
    return SessionTracker(sessionStart: DateTime.now());
  }

  SessionTracker copyWith({
    DateTime? sessionStart,
    int? gamesThisSession,
    int? scoreThisSession,
    Duration? playTimeThisSession,
  }) {
    return SessionTracker(
      sessionStart: sessionStart ?? this.sessionStart,
      gamesThisSession: gamesThisSession ?? this.gamesThisSession,
      scoreThisSession: scoreThisSession ?? this.scoreThisSession,
      playTimeThisSession: playTimeThisSession ?? this.playTimeThisSession,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionStart': sessionStart.toIso8601String(),
      'gamesThisSession': gamesThisSession,
      'scoreThisSession': scoreThisSession,
      'playTimeThisSession': playTimeThisSession.inMilliseconds,
    };
  }

  factory SessionTracker.fromJson(Map<String, dynamic> json) {
    return SessionTracker(
      sessionStart: DateTime.parse(json['sessionStart'] as String),
      gamesThisSession: json['gamesThisSession'] as int? ?? 0,
      scoreThisSession: json['scoreThisSession'] as int? ?? 0,
      playTimeThisSession: Duration(
        milliseconds: json['playTimeThisSession'] as int? ?? 0,
      ),
    );
  }

  @override
  List<Object> get props => [
        sessionStart,
        gamesThisSession,
        scoreThisSession,
        playTimeThisSession,
      ];
}

/// Game performance data for tracking recent games
class GamePerformanceData extends Equatable {
  final DateTime gameDate;
  final int score;
  final int level;
  final int linesCleared;
  final Duration playTime;
  final double efficiency;

  const GamePerformanceData({
    required this.gameDate,
    required this.score,
    required this.level,
    required this.linesCleared,
    required this.playTime,
    required this.efficiency,
  });

  Map<String, dynamic> toJson() {
    return {
      'gameDate': gameDate.toIso8601String(),
      'score': score,
      'level': level,
      'linesCleared': linesCleared,
      'playTime': playTime.inMilliseconds,
      'efficiency': efficiency,
    };
  }

  factory GamePerformanceData.fromJson(Map<String, dynamic> json) {
    return GamePerformanceData(
      gameDate: DateTime.parse(json['gameDate'] as String),
      score: json['score'] as int,
      level: json['level'] as int,
      linesCleared: json['linesCleared'] as int,
      playTime: Duration(milliseconds: json['playTime'] as int),
      efficiency: (json['efficiency'] as num).toDouble(),
    );
  }

  @override
  List<Object> get props => [
        gameDate,
        score,
        level,
        linesCleared,
        playTime,
        efficiency,
      ];
}

/// Player rank enumeration
enum PlayerRank {
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  String get displayName {
    switch (this) {
      case PlayerRank.bronze:
        return 'Bronze';
      case PlayerRank.silver:
        return 'Silver';
      case PlayerRank.gold:
        return 'Gold';
      case PlayerRank.platinum:
        return 'Platinum';
      case PlayerRank.diamond:
        return 'Diamond';
    }
  }

  int get minScore {
    switch (this) {
      case PlayerRank.bronze:
        return 0;
      case PlayerRank.silver:
        return 10000;
      case PlayerRank.gold:
        return 50000;
      case PlayerRank.platinum:
        return 150000;
      case PlayerRank.diamond:
        return 500000;
    }
  }
}

/// Level statistics (reused from player_state.dart for consistency)
class LevelStats extends Equatable {
  final int level;
  final int timesCompleted;
  final int bestScore;
  final Duration bestTime;
  final DateTime? lastCompletedDate;
  final DateTime firstCompletedDate;

  const LevelStats({
    required this.level,
    this.timesCompleted = 0,
    this.bestScore = 0,
    this.bestTime = Duration.zero,
    this.lastCompletedDate,
    required this.firstCompletedDate,
  });

  factory LevelStats.initial(int level) {
    return LevelStats(
      level: level,
      firstCompletedDate: DateTime.now(),
    );
  }

  LevelStats copyWith({
    int? level,
    int? timesCompleted,
    int? bestScore,
    Duration? bestTime,
    DateTime? lastCompletedDate,
    DateTime? firstCompletedDate,
  }) {
    return LevelStats(
      level: level ?? this.level,
      timesCompleted: timesCompleted ?? this.timesCompleted,
      bestScore: bestScore ?? this.bestScore,
      bestTime: bestTime ?? this.bestTime,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      firstCompletedDate: firstCompletedDate ?? this.firstCompletedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'timesCompleted': timesCompleted,
      'bestScore': bestScore,
      'bestTime': bestTime.inMilliseconds,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'firstCompletedDate': firstCompletedDate.toIso8601String(),
    };
  }

  factory LevelStats.fromJson(Map<String, dynamic> json) {
    return LevelStats(
      level: json['level'] as int,
      timesCompleted: json['timesCompleted'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
      bestTime: Duration(milliseconds: json['bestTime'] as int? ?? 0),
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.parse(json['lastCompletedDate'] as String)
          : null,
      firstCompletedDate: DateTime.parse(json['firstCompletedDate'] as String),
    );
  }

  @override
  List<Object?> get props => [
        level,
        timesCompleted,
        bestScore,
        bestTime,
        lastCompletedDate,
        firstCompletedDate,
      ];
}