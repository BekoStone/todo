import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import 'package:puzzle_box/domain/usecases/player_usecases.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';

// Player state status enumeration
enum PlayerStateStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

// Player state model
class PlayerState extends Equatable {
  final PlayerStateStatus status;
  final PlayerStats? playerStats;
  final List<Achievement> achievements;
  final List<Achievement> unlockedAchievements;
  final List<Achievement> recentUnlocks;
  final bool hasUnseenAchievements;
  final int coinsEarned;
  final int totalCoinsEarned;
  final String? errorMessage;
  final bool isNewPlayer;
  final DateTime? lastDailyBonusTime;
  final int dailyStreakCount;
  final Map<String, int> achievementProgress;

  const PlayerState({
    this.status = PlayerStateStatus.initial,
    this.playerStats,
    this.achievements = const [],
    this.unlockedAchievements = const [],
    this.recentUnlocks = const [],
    this.hasUnseenAchievements = false,
    this.coinsEarned = 0,
    this.totalCoinsEarned = 0,
    this.errorMessage,
    this.isNewPlayer = false,
    this.lastDailyBonusTime,
    this.dailyStreakCount = 0,
    this.achievementProgress = const {},
  });

  bool get isDataLoaded => status == PlayerStateStatus.loaded;
  bool get isUpdating => status == PlayerStateStatus.updating;
  bool get isLoading => status == PlayerStateStatus.loading;
  bool get hasError => status == PlayerStateStatus.error;

  PlayerState copyWith({
    PlayerStateStatus? status,
    PlayerStats? playerStats,
    List<Achievement>? achievements,
    List<Achievement>? unlockedAchievements,
    List<Achievement>? recentUnlocks,
    bool? hasUnseenAchievements,
    int? coinsEarned,
    int? totalCoinsEarned,
    String? errorMessage,
    bool? isNewPlayer,
    DateTime? lastDailyBonusTime,
    int? dailyStreakCount,
    Map<String, int>? achievementProgress,
  }) {
    return PlayerState(
      status: status ?? this.status,
      playerStats: playerStats ?? this.playerStats,
      achievements: achievements ?? this.achievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      recentUnlocks: recentUnlocks ?? this.recentUnlocks,
      hasUnseenAchievements: hasUnseenAchievements ?? this.hasUnseenAchievements,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      errorMessage: errorMessage ?? this.errorMessage,
      isNewPlayer: isNewPlayer ?? this.isNewPlayer,
      lastDailyBonusTime: lastDailyBonusTime ?? this.lastDailyBonusTime,
      dailyStreakCount: dailyStreakCount ?? this.dailyStreakCount,
      achievementProgress: achievementProgress ?? this.achievementProgress,
    );
  }

  @override
  List<Object?> get props => [
        status,
        playerStats,
        achievements,
        unlockedAchievements,
        recentUnlocks,
        hasUnseenAchievements,
        coinsEarned,
        totalCoinsEarned,
        errorMessage,
        isNewPlayer,
        lastDailyBonusTime,
        dailyStreakCount,
        achievementProgress,
      ];
}

/// PlayerCubit manages player data, statistics, achievements, and progression.
/// Handles player profile, coins, achievements, and cross-session data persistence.
/// Follows Clean Architecture with proper error handling and state management.
class PlayerCubit extends Cubit<PlayerState> {
  final PlayerUseCases _playerUseCases;
  final AchievementUseCases _achievementUseCases;
  
  // Timers for periodic operations
  Timer? _dailyBonusTimer;
  Timer? _achievementCheckTimer;
  
  // Achievement tracking
  final Set<String> _pendingAchievements = {};

  PlayerCubit(
    this._playerUseCases,
    this._achievementUseCases,
  ) : super(const PlayerState()) {
    _initializePlayerCubit();
  }

  @override
  Future<void> close() async {
    _dailyBonusTimer?.cancel();
    _achievementCheckTimer?.cancel();
    await super.close();
  }

  /// Initialize the player cubit
  void _initializePlayerCubit() {
    developer.log('PlayerCubit initialized', name: 'PlayerCubit');
    _setupDailyBonusTimer();
    _setupAchievementChecker();
  }

  // ========================================
  // PLAYER INITIALIZATION
  // ========================================

  /// Initialize player data - loads existing or creates new player
  Future<void> initializePlayer() async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.loading));
      developer.log('Initializing player data', name: 'PlayerCubit');
      
      // Load existing player data
      final playerStats = await _playerUseCases.loadPlayerStats();
      final achievements = await _achievementUseCases.getPlayerAchievements();
      
      // Check if this is a new player
      final isNewPlayer = playerStats == null;
      
      // Create default stats for new players
      final stats = playerStats ?? await _createNewPlayerStats();
      
      // Load achievement progress
      final achievementProgress = await _achievementUseCases.getAchievementProgress();
      
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: stats,
        achievements: achievements,
        isNewPlayer: isNewPlayer,
        achievementProgress: achievementProgress,
      ));
      
      // Check for daily bonus eligibility
      _checkDailyBonus();
      
      // Check for pending achievements
      await _checkPendingAchievements();
      
      developer.log('Player initialized - New: $isNewPlayer, Coins: ${stats.totalCoins}', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to initialize player: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to initialize player: $e',
      ));
    }
  }

  /// Create new player stats with default values
  Future<PlayerStats> _createNewPlayerStats() async {
    final newStats = PlayerStats.initial();
    await _playerUseCases.savePlayerStats(newStats);
    return newStats;
  }

  // ========================================
  // GAME COMPLETION PROCESSING
  // ========================================

  /// Process game completion and update player stats
  Future<void> processGameCompletion({
    required int finalScore,
    required int level,
    required int linesCleared,
    required int blocksPlaced,
    required Duration gameDuration,
    required int usedPowerUps,
    bool hadPerfectClear = false,
    bool usedUndo = false,
  }) async {
    if (state.playerStats == null) return;

    try {
      emit(state.copyWith(status: PlayerStateStatus.updating));
      
      // Calculate coins earned from this game
      final coinsEarned = _calculateGameCoins(finalScore, level, linesCleared);
      
      // Update player stats
      final currentStats = state.playerStats!;
      final updatedStats = currentStats.afterGameSession(
        gameScore: finalScore,
        blocksPlaced: blocksPlaced,
        linesCleared: linesCleared,
        maxCombo: 0, // Would be passed from game state
        maxStreak: 0, // Would be passed from game state
        sessionTime: gameDuration,
        coinsEarned: coinsEarned,
        hadPerfectClear: hadPerfectClear,
      );

      // Save updated stats
      await _playerUseCases.savePlayerStats(updatedStats);
      
      // Update state
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: updatedStats,
        coinsEarned: coinsEarned,
        totalCoinsEarned: state.totalCoinsEarned + coinsEarned,
      ));

      // Check for achievements
      await _checkGameCompletionAchievements(
        finalScore: finalScore,
        level: level,
        linesCleared: linesCleared,
        blocksPlaced: blocksPlaced,
        hadPerfectClear: hadPerfectClear,
        usedUndo: usedUndo,
      );

      developer.log('Game completion processed - Score: $finalScore, Coins: $coinsEarned', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to process game completion: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to process game completion: $e',
      ));
    }
  }

  // ========================================
  // ACHIEVEMENT MANAGEMENT
  // ========================================

  /// Update achievement progress for a specific achievement
  Future<void> updateAchievementProgress(String achievementId, int progress) async {
    try {
      final currentProgress = state.achievementProgress[achievementId] ?? 0;
      final newProgress = currentProgress + progress;
      
      // Update progress map
      final updatedProgress = Map<String, int>.from(state.achievementProgress);
      updatedProgress[achievementId] = newProgress;
      
      emit(state.copyWith(achievementProgress: updatedProgress));
      
      // Check if achievement is now unlocked
      final achievement = await _achievementUseCases.getAchievementById(achievementId);
      if (achievement != null && newProgress >= achievement.targetValue) {
        await _unlockAchievement(achievement);
      }
      
      // Save progress
      await _achievementUseCases.saveAchievementProgress(updatedProgress);
      
    } catch (e) {
      developer.log('Failed to update achievement progress: $e', name: 'PlayerCubit');
    }
  }

  /// Unlock a specific achievement
  Future<void> _unlockAchievement(Achievement achievement) async {
    try {
      // Check if already unlocked
      if (state.achievements.any((a) => a.id == achievement.id)) {
        return;
      }

      // Add to unlocked achievements
      final updatedAchievements = List<Achievement>.from(state.achievements);
      updatedAchievements.add(achievement);
      
      // Add coins reward
      final coinsReward = achievement.coinReward;
      PlayerStats? updatedStats;
      
      if (state.playerStats != null && coinsReward > 0) {
        updatedStats = state.playerStats!.copyWith(
          totalCoins: state.playerStats!.totalCoins + coinsReward,
          totalAchievementsUnlocked: updatedAchievements.length,
        );
        await _playerUseCases.savePlayerStats(updatedStats);
      }

      // Update state
      emit(state.copyWith(
        playerStats: updatedStats ?? state.playerStats,
        achievements: updatedAchievements,
        recentUnlocks: [achievement],
        hasUnseenAchievements: true,
        coinsEarned: coinsReward,
        totalCoinsEarned: state.totalCoinsEarned + coinsReward,
      ));

      // Save achievements
      await _achievementUseCases.savePlayerAchievements(updatedAchievements);

      developer.log('Achievement unlocked: ${achievement.title} (+$coinsReward coins)', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to unlock achievement: $e', name: 'PlayerCubit');
    }
  }

  /// Check for achievements after game completion
  Future<void> _checkGameCompletionAchievements({
    required int finalScore,
    required int level,
    required int linesCleared,
    required int blocksPlaced,
    required bool hadPerfectClear,
    required bool usedUndo,
  }) async {
    try {
      // Score-based achievements
      await updateAchievementProgress('score_1000', finalScore >= 1000 ? 1 : 0);
      await updateAchievementProgress('score_5000', finalScore >= 5000 ? 1 : 0);
      await updateAchievementProgress('score_10000', finalScore >= 10000 ? 1 : 0);
      
      // Level achievements
      await updateAchievementProgress('level_5', level >= 5 ? 1 : 0);
      await updateAchievementProgress('level_10', level >= 10 ? 1 : 0);
      
      // Lines cleared achievements
      await updateAchievementProgress('lines_100', linesCleared);
      await updateAchievementProgress('lines_500', linesCleared);
      
      // Perfect clear achievements
      if (hadPerfectClear) {
        await updateAchievementProgress('perfect_clear', 1);
        await updateAchievementProgress('perfect_clear_5', 1);
      }
      
      // Efficiency achievements
      if (!usedUndo) {
        await updateAchievementProgress('no_undo_game', 1);
      }
      
      // Games played achievements
      await updateAchievementProgress('games_10', 1);
      await updateAchievementProgress('games_50', 1);
      await updateAchievementProgress('games_100', 1);
      
    } catch (e) {
      developer.log('Failed to check game completion achievements: $e', name: 'PlayerCubit');
    }
  }

  /// Mark achievements as seen
  void markAchievementsSeen() {
    emit(state.copyWith(
      hasUnseenAchievements: false,
      recentUnlocks: [],
    ));
  }

  /// Check for pending achievements (called periodically)
  Future<void> _checkPendingAchievements() async {
    if (state.playerStats == null) return;
    
    try {
      final pendingAchievements = await _achievementUseCases.checkAllAchievements(
        playerStats: state.playerStats!,
      );
      
      for (final achievement in pendingAchievements) {
        await _unlockAchievement(achievement);
      }
      
    } catch (e) {
      developer.log('Failed to check pending achievements: $e', name: 'PlayerCubit');
    }
  }

  // ========================================
  // COIN MANAGEMENT
  // ========================================

  /// Add coins to player account
  Future<void> addCoins(int amount, {String source = 'unknown'}) async {
    if (amount <= 0 || state.playerStats == null) return;

    try {
      final updatedStats = state.playerStats!.copyWith(
        totalCoins: state.playerStats!.totalCoins + amount,
      );

      await _playerUseCases.savePlayerStats(updatedStats);

      emit(state.copyWith(
        playerStats: updatedStats,
        coinsEarned: amount,
        totalCoinsEarned: state.totalCoinsEarned + amount,
      ));

      developer.log('Added $amount coins from $source', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to add coins: $e', name: 'PlayerCubit');
    }
  }

  /// Spend coins from player account
  Future<bool> spendCoins(int amount, {String purpose = 'unknown'}) async {
    if (amount <= 0 || state.playerStats == null) return false;

    try {
      final currentCoins = state.playerStats!.totalCoins;
      if (currentCoins < amount) {
        developer.log('Insufficient coins: $currentCoins < $amount', name: 'PlayerCubit');
        return false;
      }

      final updatedStats = state.playerStats!.copyWith(
        totalCoins: currentCoins - amount,
      );

      await _playerUseCases.savePlayerStats(updatedStats);

      emit(state.copyWith(playerStats: updatedStats));

      developer.log('Spent $amount coins for $purpose', name: 'PlayerCubit');
      return true;
      
    } catch (e) {
      developer.log('Failed to spend coins: $e', name: 'PlayerCubit');
      return false;
    }
  }

  // ========================================
  // DAILY BONUS SYSTEM
  // ========================================

  /// Check and grant daily bonus if eligible
  void _checkDailyBonus() {
    final now = DateTime.now();
    final lastBonus = state.lastDailyBonusTime;
    
    if (lastBonus == null || _isDifferentDay(lastBonus, now)) {
      _grantDailyBonus();
    }
  }

  /// Grant daily bonus to player
  Future<void> _grantDailyBonus() async {
    try {
      final dailyBonus = AppConstants.dailyBonusCoins;
      final streakBonus = _calculateStreakBonus();
      final totalBonus = dailyBonus + streakBonus;
      
      await addCoins(totalBonus, source: 'daily_bonus');
      
      emit(state.copyWith(
        lastDailyBonusTime: DateTime.now(),
        dailyStreakCount: state.dailyStreakCount + 1,
      ));
      
      developer.log('Daily bonus granted: $totalBonus coins (streak: ${state.dailyStreakCount})', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to grant daily bonus: $e', name: 'PlayerCubit');
    }
  }

  /// Calculate streak bonus
  int _calculateStreakBonus() {
    final streak = state.dailyStreakCount;
    if (streak >= 7) return 50; // Weekly bonus
    if (streak >= 3) return 20; // 3-day bonus
    return 0;
  }

  /// Check if two dates are different days
  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year ||
           date1.month != date2.month ||
           date1.day != date2.day;
  }

  // ========================================
  // STATISTICS AND CALCULATIONS
  // ========================================

  /// Calculate coins earned from game completion
  int _calculateGameCoins(int score, int level, int linesCleared) {
    const baseCoins = 10;
    
    // Score bonus (1 coin per 100 points)
    final scoreBonus = (score / 100).floor();
    
    // Level bonus
    final levelBonus = level * 2;
    
    // Lines bonus
    final linesBonus = linesCleared;
    
    return baseCoins + scoreBonus + levelBonus + linesBonus;
  }

  // ========================================
  // POWER-UP MANAGEMENT
  // ========================================

  /// Purchase a power-up with coins
  Future<bool> purchasePowerUp(PowerUpType powerUpType, int quantity) async {
    try {
      final cost = _getPowerUpCost(powerUpType) * quantity;
      
      if (await spendCoins(cost, purpose: 'power_up_${powerUpType.name}')) {
        // Power-ups would be managed by the game cubit
        developer.log('Purchased $quantity ${powerUpType.name} power-ups for $cost coins', name: 'PlayerCubit');
        return true;
      }
      
      return false;
    } catch (e) {
      developer.log('Failed to purchase power-up: $e', name: 'PlayerCubit');
      return false;
    }
  }

  /// Get cost of a power-up
  int _getPowerUpCost(PowerUpType powerUpType) {
    switch (powerUpType) {
      case PowerUpType.undo:
        return 50;
      case PowerUpType.hint:
        return 30;
      case PowerUpType.shuffle:
        return 100;
      case PowerUpType.bomb:
        return 150;
      case PowerUpType.freeze:
        return 200;
    }
  }

  // ========================================
  // TIMER MANAGEMENT
  // ========================================

  /// Setup daily bonus timer
  void _setupDailyBonusTimer() {
    _dailyBonusTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkDailyBonus();
    });
  }

  /// Setup achievement checker
  void _setupAchievementChecker() {
    _achievementCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkPendingAchievements();
    });
  }

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  /// Reset all player data
  Future<void> resetPlayerData() async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.loading));
      
      // Clear stored data
      await _playerUseCases.clearPlayerData();
      await _achievementUseCases.clearAchievements();
      
      // Create new player
      final newStats = await _createNewPlayerStats();
      
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: newStats,
        achievements: [],
        unlockedAchievements: [],
        recentUnlocks: [],
        hasUnseenAchievements: false,
        coinsEarned: 0,
        totalCoinsEarned: 0,
        isNewPlayer: true,
        achievementProgress: {},
      ));
      
      developer.log('Player data reset successfully', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to reset player data: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to reset player data: $e',
      ));
    }
  }

  /// Export player data for backup
  Map<String, dynamic> exportPlayerData() {
    return {
      'playerStats': state.playerStats?.toJson(),
      'achievements': state.achievements.map((a) => a.toJson()).toList(),
      'achievementProgress': state.achievementProgress,
      'lastDailyBonusTime': state.lastDailyBonusTime?.toIso8601String(),
      'dailyStreakCount': state.dailyStreakCount,
    };
  }
}