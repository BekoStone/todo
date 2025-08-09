// Import math for calculations
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';


/// PlayerState represents the current state of player data, achievements, and progression.
/// Includes statistics, coins, achievements, and UI state for notifications.
/// Uses Equatable for efficient state comparison and updates.
class PlayerState extends Equatable {
  /// Current status of player data loading
  final PlayerStateStatus status;
  
  /// Player statistics and progression data
  final PlayerStats? playerStats;
  
  /// List of unlocked achievements
  final List<Achievement> achievements;
  
  /// Whether this is a new player (first time)
  final bool isNewPlayer;
  
  /// Whether there are unseen achievements
  final bool hasUnseenAchievements;
  
  /// Recently unlocked achievements to display
  final List<Achievement> unlockedAchievements;
  
  /// Coins earned in the last action
  final int coinsEarned;
  
  /// Whether to show coins earned notification
  final bool showCoinsEarned;
  
  /// Daily bonus coins earned
  final int dailyBonusEarned;
  
  /// Whether to show daily bonus notification
  final bool showDailyBonus;
  
  /// Last time data was synced
  final DateTime? lastDataSync;
  
  /// Error message (if any)
  final String? errorMessage;

  const PlayerState({
    this.status = PlayerStateStatus.initial,
    this.playerStats,
    this.achievements = const [],
    this.isNewPlayer = false,
    this.hasUnseenAchievements = false,
    this.unlockedAchievements = const [],
    this.coinsEarned = 0,
    this.showCoinsEarned = false,
    this.dailyBonusEarned = 0,
    this.showDailyBonus = false,
    this.lastDataSync,
    this.errorMessage,
  });

  /// Create a copy of the state with updated values
  PlayerState copyWith({
    PlayerStateStatus? status,
    PlayerStats? playerStats,
    List<Achievement>? achievements,
    bool? isNewPlayer,
    bool? hasUnseenAchievements,
    List<Achievement>? unlockedAchievements,
    int? coinsEarned,
    bool? showCoinsEarned,
    int? dailyBonusEarned,
    bool? showDailyBonus,
    DateTime? lastDataSync,
    String? errorMessage,
  }) {
    return PlayerState(
      status: status ?? this.status,
      playerStats: playerStats ?? this.playerStats,
      achievements: achievements ?? this.achievements,
      isNewPlayer: isNewPlayer ?? this.isNewPlayer,
      hasUnseenAchievements: hasUnseenAchievements ?? this.hasUnseenAchievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      showCoinsEarned: showCoinsEarned ?? this.showCoinsEarned,
      dailyBonusEarned: dailyBonusEarned ?? this.dailyBonusEarned,
      showDailyBonus: showDailyBonus ?? this.showDailyBonus,
      lastDataSync: lastDataSync ?? this.lastDataSync,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // ========================================
  // CONVENIENCE GETTERS
  // ========================================

  /// Check if player data is loading
  bool get isLoading => status == PlayerStateStatus.loading;

  /// Check if player data is loaded
  bool get isLoaded => status == PlayerStateStatus.loaded;


  /// Check if there's an error
  bool get hasError => status == PlayerStateStatus.error;
  /// Check if player data is updating
  bool get isUpdating => status == PlayerStateStatus.updating;

  /// Check if player is initialized
  bool get isInitialized => status != PlayerStateStatus.initial;

  /// Get current coin count safely
  int get currentCoins => playerStats?.totalCoinsEarned ?? 0;

  /// Get current level safely
  int get currentLevel => playerStats?.currentLevel ?? 1;

  /// Get total games played
  int get totalGamesPlayed => playerStats?.totalGamesPlayed ?? 0;

  /// Get high score safely
  int get highScore => playerStats?.highScore ?? 0;

  /// Get formatted high score
  String get formattedHighScore {
    return highScore.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Get total play time formatted
  String get formattedPlayTime {
    if (playerStats == null) return '0:00';
    
    final totalMinutes = playerStats!.totalPlayTime.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get player rank based on total score
  PlayerRank get playerRank {
    final totalScore = playerStats?.totalScore ?? 0;
    
    if (totalScore < 10000) return PlayerRank.bronze;
    if (totalScore < 50000) return PlayerRank.silver;
    if (totalScore < 150000) return PlayerRank.gold;
    if (totalScore < 500000) return PlayerRank.platinum;
    return PlayerRank.diamond;
  }

  /// Get achievement completion percentage
  double get achievementProgress {
    // This would need the total number of available achievements
    const totalAchievements = 30; // Example total
    return (achievements.length / totalAchievements).clamp(0.0, 1.0);
  }

  /// Get consecutive login days
  int get consecutiveLoginDays => playerStats?.consecutiveLoginDays ?? 0;

  /// Check if eligible for daily bonus
  bool get eligibleForDailyBonus {
    if (playerStats?.lastGameDate == null) return true;
    
    final now = DateTime.now();
    final lastLogin = playerStats!.lastGameDate!;
    
    return now.difference(lastLogin).inDays >= 1;
  }

  /// Get next level progress (0.0 to 1.0)
  double get nextLevelProgress {
    if (playerStats == null) return 0.0;
    
    final currentXP = playerStats!.totalScore;
    final currentLevelXP = _getXPForLevel(currentLevel);
    final nextLevelXP = _getXPForLevel(currentLevel + 1);
    
    if (nextLevelXP <= currentLevelXP) return 1.0;
    
    return ((currentXP - currentLevelXP) / (nextLevelXP - currentLevelXP))
        .clamp(0.0, 1.0);
  }

  /// Get XP needed for next level
  int get xpToNextLevel {
    if (playerStats == null) return 0;
    
    final currentXP = playerStats!.totalScore;
    final nextLevelXP = _getXPForLevel(currentLevel + 1);
    
    return math.max(0, nextLevelXP - currentXP);
  }

  /// Check if player has premium features
  bool get hasPremium => playerStats?.hasPremium ?? false;

  /// Get statistics summary for display
  Map<String, dynamic> get statisticsSummary {
    if (playerStats == null) {
      return {
        'gamesPlayed': 0,
        'totalScore': 0,
        'averageScore': 0.0,
        'bestStreak': 0,
        'totalPlayTime': '0m',
        'achievementsUnlocked': 0,
      };
    }
    
    return {
      'gamesPlayed': playerStats!.totalGamesPlayed,
      'totalScore': playerStats!.totalScore,
      'averageScore': playerStats!.averageScore,
      'bestStreak': playerStats!.bestStreak,
      'totalPlayTime': formattedPlayTime,
      'achievementsUnlocked': achievements.length,
    };
  }

  /// Get recent achievements (last 5)
  List<Achievement> get recentAchievements {
    return achievements
        .where((a) => a.unlockedDate != null)
        .toList()
      ..sort((a, b) => b.unlockedDate!.compareTo(a.unlockedDate!))
      ..take(5);
  }

  /// Check if should show any notifications
  bool get hasNotifications {
    return showDailyBonus || showCoinsEarned || hasUnseenAchievements;
  }

  // ========================================
  // PRIVATE HELPERS
  // ========================================

  /// Calculate XP requirement for a given level
  int _getXPForLevel(int level) {
    // Exponential growth: level^2 * 1000
    return level * level * 1000;
  }

  @override
  List<Object?> get props => [
        status,
        playerStats,
        achievements,
        isNewPlayer,
        hasUnseenAchievements,
        unlockedAchievements,
        coinsEarned,
        showCoinsEarned,
        dailyBonusEarned,
        showDailyBonus,
        lastDataSync,
        errorMessage,
      ];

  @override
  String toString() {
    return 'PlayerState('
        'status: $status, '
        'coins: $currentCoins, '
        'level: $currentLevel, '
        'achievements: ${achievements.length}, '
        'hasNotifications: $hasNotifications'
        ')';
  }
}

/// Player state status enumeration
enum PlayerStateStatus {
  initial,
  loading,
  loaded,
  error,
  updating,
}

/// Player rank enumeration based on total score
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

  String get description {
    switch (this) {
      case PlayerRank.bronze:
        return 'Novice Player';
      case PlayerRank.silver:
        return 'Skilled Player';
      case PlayerRank.gold:
        return 'Expert Player';
      case PlayerRank.platinum:
        return 'Master Player';
      case PlayerRank.diamond:
        return 'Legendary Player';
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

/// Level statistics for tracking performance per level
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

  /// Create initial level stats
  factory LevelStats.initial(int level) {
    return LevelStats(
      level: level,
      firstCompletedDate: DateTime.now(),
    );
  }

  /// Create a copy with updated values
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

  /// Convert to JSON for persistence
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

  /// Create from JSON
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