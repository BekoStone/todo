import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import 'package:puzzle_box/domain/usecases/player_usecases.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/presentation/flame/box_hooks_game.dart';


/// PlayerCubit manages player data, statistics, achievements, and progression.
/// Handles player profile, coins, achievements, and cross-session data persistence.
/// Follows Clean Architecture with proper error handling and state management.
class PlayerCubit extends Cubit<PlayerStateStatus> {
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
      final playerStats = await _playerUseCases.getPlayerStats();
      final achievements = await _achievementUseCases.getPlayerAchievements();
      
      // Check if this is a new player
      final isNewPlayer = playerStats == null;
      
      // Create default stats for new players
      final stats = playerStats ?? PlayerStats.createDefault();
      
      // Process daily login bonus
      final updatedStats = await _processDailyLogin(stats);
      
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: updatedStats,
        achievements: achievements,
        isNewPlayer: isNewPlayer,
        lastDataSync: DateTime.now(),
      ));
      
      // Save updated stats if they changed
      if (updatedStats != stats) {
        await _playerUseCases.savePlayerStats(updatedStats);
      }
      
      // Check for pending achievements
      await _checkPendingAchievements();
      
      developer.log('Player initialized successfully', name: 'PlayerCubit');
      
    } catch (e, stackTrace) {
      developer.log('Failed to initialize player: $e', name: 'PlayerCubit', stackTrace: stackTrace);
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to load player data: ${e.toString()}',
      ));
    }
  }

  /// Process daily login bonus
  Future<PlayerStats> _processDailyLogin(PlayerStats stats) async {
    final now = DateTime.now();
    final lastLogin = stats.lastLoginDate;
    
    // Check if eligible for daily bonus
    if (lastLogin == null || _isDifferentDay(lastLogin, now)) {
      final consecutiveDays = _calculateConsecutiveDays(lastLogin, now);
      final bonusCoins = _calculateDailyBonus(consecutiveDays);
      
      final updatedStats = stats.copyWith(
        lastLoginDate: now,
        consecutiveLoginDays: consecutiveDays,
        totalCoins: stats.totalCoins + bonusCoins,
        totalLoginDays: stats.totalLoginDays + 1,
      );
      
      // Emit daily bonus event
      emit(state.copyWith(
        dailyBonusEarned: bonusCoins,
        showDailyBonus: bonusCoins > 0,
      ));
      
      developer.log('Daily bonus earned: $bonusCoins coins', name: 'PlayerCubit');
      return updatedStats;
    }
    
    return stats;
  }

  // ========================================
  // GAME COMPLETION PROCESSING
  // ========================================

  /// Process game completion and update player statistics
  Future<void> processGameCompletion({
    required int finalScore,
    required int level,
    required int linesCleared,
    required int blocksPlaced,
    required Duration gameDuration,
    required Map<String, int> usedPowerUps, required usedUndo,
  }) async {
    if (state.playerStats == null) return;
    
    try {
      developer.log('Processing game completion: Score=$finalScore, Level=$level', name: 'PlayerCubit');
      
      final currentStats = state.playerStats!;
      
      // Calculate coins earned from this game
      final coinsEarned = _calculateGameCoins(finalScore, level, linesCleared);
      
      // Update player statistics
      final updatedStats = currentStats.copyWith(
        totalGamesPlayed: currentStats.totalGamesPlayed + 1,
        totalScore: currentStats.totalScore + finalScore,
        highScore: math.max(currentStats.highScore, finalScore),
        totalLinesCleared: currentStats.totalLinesCleared + linesCleared,
        totalBlocksPlaced: currentStats.totalBlocksPlaced + blocksPlaced,
        totalPlayTime: currentStats.totalPlayTime + gameDuration,
        totalCoins: currentStats.totalCoins + coinsEarned,
        averageScore: _calculateAverageScore(
          currentStats.totalScore + finalScore,
          currentStats.totalGamesPlayed + 1,
        ),
        lastGameDate: DateTime.now(),
      );
      
      // Update level progression
      final levelStats = _updateLevelStats(currentStats.levelStats, level);
      final finalUpdatedStats = updatedStats.copyWith(levelStats: levelStats);
      
      emit(state.copyWith(
        playerStats: finalUpdatedStats,
        coinsEarned: coinsEarned,
        showCoinsEarned: coinsEarned > 0,
      ));
      
      // Save updated statistics
      await _playerUseCases.savePlayerStats(finalUpdatedStats);
      
      // Check for achievements
      await _checkGameCompletionAchievements(
        score: finalScore,
        level: level,
        linesCleared: linesCleared,
        gameDuration: gameDuration,
      );
      
      developer.log('Game completion processed successfully', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to process game completion: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        errorMessage: 'Failed to save game progress: ${e.toString()}',
      ));
    }
  }

  // ========================================
  // COIN MANAGEMENT
  // ========================================

  /// Add coins to player account
  Future<void> addCoins(int amount, {String source = 'unknown'}) async {
    if (state.playerStats == null || amount <= 0) return;
    
    try {
      final currentStats = state.playerStats!;
      final newTotal = currentStats.totalCoins + amount;
      
      final updatedStats = currentStats.copyWith(
        totalCoins: newTotal,
        totalCoinsEarned: currentStats.totalCoinsEarned + amount,
      );
      
      emit(state.copyWith(
        playerStats: updatedStats,
        coinsEarned: amount,
        showCoinsEarned: true,
      ));
      
      await _playerUseCases.savePlayerStats(updatedStats);
      
      developer.log('Added $amount coins from $source. Total: $newTotal', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to add coins: $e', name: 'PlayerCubit');
    }
  }

  /// Spend coins for purchases
  Future<bool> spendCoins(int amount, {String purpose = 'unknown'}) async {
    if (state.playerStats == null || amount <= 0) return false;
    
    final currentStats = state.playerStats!;
    if (currentStats.totalCoins < amount) {
      emit(state.copyWith(
        errorMessage: 'Insufficient coins. Need $amount, have ${currentStats.totalCoins}.',
      ));
      return false;
    }
    
    try {
      final updatedStats = currentStats.copyWith(
        totalCoins: currentStats.totalCoins - amount,
        totalCoinsSpent: currentStats.totalCoinsSpent + amount,
      );
      
      emit(state.copyWith(playerStats: updatedStats));
      await _playerUseCases.savePlayerStats(updatedStats);
      
      developer.log('Spent $amount coins for $purpose. Remaining: ${updatedStats.totalCoins}', name: 'PlayerCubit');
      return true;
      
    } catch (e) {
      developer.log('Failed to spend coins: $e', name: 'PlayerCubit');
      return false;
    }
  }

  // ========================================
  // ACHIEVEMENT MANAGEMENT
  // ========================================

  /// Check and unlock achievements based on game completion
  Future<void> _checkGameCompletionAchievements({
    required int score,
    required int level,
    required int linesCleared,
    required Duration gameDuration,
  }) async {
    try {
      final newAchievements = await _achievementUseCases.checkGameCompletionAchievements(
        score: score,
        level: level,
        linesCleared: linesCleared,
        gameDuration: gameDuration,
        playerStats: state.playerStats!,
      );
      
      if (newAchievements.isNotEmpty) {
        await _processNewAchievements(newAchievements);
      }
      
    } catch (e) {
      developer.log('Failed to check achievements: $e', name: 'PlayerCubit');
    }
  }

  /// Process newly unlocked achievements
  Future<void> _processNewAchievements(List<Achievement> newAchievements) async {
    try {
      // Add to current achievements list
      final currentAchievements = List<Achievement>.from(state.achievements);
      currentAchievements.addAll(newAchievements);
      
      // Calculate total coins earned from achievements
      final achievementCoins = newAchievements.fold<int>(
        0,
        (sum, achievement) => sum + achievement.coinReward,
      );
      
      // Update player stats with achievement coins
      if (achievementCoins > 0 && state.playerStats != null) {
        final updatedStats = state.playerStats!.copyWith(
          totalCoins: state.playerStats!.totalCoins + achievementCoins,
          totalAchievementsUnlocked: currentAchievements.length,
        );
        
        emit(state.copyWith(
          playerStats: updatedStats,
          achievements: currentAchievements,
          hasUnseenAchievements: true,
          unlockedAchievements: newAchievements,
          coinsEarned: achievementCoins,
        ));
        
        await _playerUseCases.savePlayerStats(updatedStats);
      } else {
        emit(state.copyWith(
          achievements: currentAchievements,
          hasUnseenAchievements: true,
          unlockedAchievements: newAchievements,
        ));
      }
      
      // Save achievements
      await _achievementUseCases.savePlayerAchievements(currentAchievements);
      
      developer.log('Processed ${newAchievements.length} new achievements', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to process new achievements: $e', name: 'PlayerCubit');
    }
  }

  /// Mark achievements as seen
  void markAchievementsSeen() {
    emit(state.copyWith(
      hasUnseenAchievements: false,
      unlockedAchievements: [],
    ));
  }

  /// Check for pending achievements (called periodically)
  Future<void> _checkPendingAchievements() async {
    if (state.playerStats == null) return;
    
    try {
      final pendingAchievements = await _achievementUseCases.checkAllAchievements(
        playerStats: state.playerStats!,
      );
      
      if (pendingAchievements.isNotEmpty) {
        await _processNewAchievements(pendingAchievements);
      }
      
    } catch (e) {
      developer.log('Failed to check pending achievements: $e', name: 'PlayerCubit');
    }
  }

  // ========================================
  // STATISTICS AND CALCULATIONS
  // ========================================

  /// Calculate coins earned from game completion
  int _calculateGameCoins(int score, int level, int linesCleared) {
    int baseCoins = AppConstants.gameCompletionCoins;
    
    // Score bonus (1 coin per 100 points)
    final scoreBonus = (score / 100).floor();
    
    // Level bonus
    final levelBonus = level * 2;
    
    // Lines bonus
    final linesBonus = linesCleared;
    
    return baseCoins + scoreBonus + levelBonus + linesBonus;
  }

  /// Calculate average score
  double _calculateAverageScore(int totalScore, int gamesPlayed) {
    return gamesPlayed > 0 ? totalScore / gamesPlayed : 0.0;
  }

  /// Update level statistics
  Map<int, LevelStats> _updateLevelStats(
    Map<int, LevelStats> currentLevelStats,
    int completedLevel,
  ) {
    final updatedStats = Map<int, LevelStats>.from(currentLevelStats);
    
    // Update or create level stats
    final currentStats = updatedStats[completedLevel] ?? LevelStats.initial(completedLevel);
    final newStats = currentStats.copyWith(
      timesCompleted: currentStats.timesCompleted + 1,
      lastCompletedDate: DateTime.now(),
    );
    
    updatedStats[completedLevel] = newStats;
    return updatedStats;
  }

  /// Calculate daily bonus amount
  int _calculateDailyBonus(int consecutiveDays) {
    // Base daily bonus
    int bonus = AppConstants.dailyBonusCoins;
    
    // Consecutive day bonuses
    if (consecutiveDays >= 7) bonus += 25; // Weekly bonus
    if (consecutiveDays >= 30) bonus += 50; // Monthly bonus
    
    // Cap at reasonable maximum
    return math.min(bonus, 200);
  }

  /// Calculate consecutive login days
  int _calculateConsecutiveDays(DateTime? lastLogin, DateTime current) {
    if (lastLogin == null) return 1;
    
    final daysDifference = current.difference(lastLogin).inDays;
    
    // Reset streak if more than 1 day gap
    if (daysDifference > 1) return 1;
    
    // Continue streak if exactly 1 day
    if (daysDifference == 1) {
      return (state.playerStats?.consecutiveLoginDays ?? 0) + 1;
    }
    
    // Same day login
    return state.playerStats?.consecutiveLoginDays ?? 1;
  }

  /// Check if two dates are different days
  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year ||
           date1.month != date2.month ||
           date1.day != date2.day;
  }

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  /// Export player data for backup or transfer
  Future<Map<String, dynamic>> exportPlayerData() async {
    try {
      if (state.playerStats == null) {
        throw Exception('No player data to export');
      }
      
      final exportData = {
        'playerStats': state.playerStats!.toJson(),
        'achievements': state.achievements.map((a) => a.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': AppConstants.appVersion,
      };
      
      developer.log('Player data exported successfully', name: 'PlayerCubit');
      return exportData;
      
    } catch (e) {
      developer.log('Failed to export player data: $e', name: 'PlayerCubit');
      rethrow;
    }
  }

  /// Import player data from backup
  Future<void> importPlayerData(Map<String, dynamic> data) async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.loading));
      
      // Validate data structure
      if (!data.containsKey('playerStats') || !data.containsKey('achievements')) {
        throw Exception('Invalid backup data format');
      }
      
      // Parse player stats
      final playerStats = PlayerStats.fromJson(data['playerStats']);
      
      // Parse achievements
      final achievementsList = (data['achievements'] as List)
          .map((a) => Achievement.fromJson(a))
          .toList();
      
      // Update state
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: playerStats,
        achievements: achievementsList,
        lastDataSync: DateTime.now(),
      ));
      
      // Save imported data
      await _playerUseCases.savePlayerStats(playerStats);
      await _achievementUseCases.savePlayerAchievements(achievementsList);
      
      developer.log('Player data imported successfully', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to import player data: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to import data: ${e.toString()}',
      ));
    }
  }

  /// Reset player data (with confirmation)
  Future<void> resetPlayerData({bool confirmed = false}) async {
    if (!confirmed) {
      emit(state.copyWith(
        errorMessage: 'Player data reset requires confirmation',
      ));
      return;
    }
    
    try {
      developer.log('Resetting player data', name: 'PlayerCubit');
      
      // Create fresh player stats
      final newStats = PlayerStats.createDefault();
      
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: newStats,
        achievements: [],
        isNewPlayer: true,
        hasUnseenAchievements: false,
        unlockedAchievements: [],
        lastDataSync: DateTime.now(),
      ));
      
      // Clear saved data
      await _playerUseCases.clearPlayerData();
      await _achievementUseCases.clearAchievements();
      
      developer.log('Player data reset successfully', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to reset player data: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to reset data: ${e.toString()}',
      ));
    }
  }

  // ========================================
  // TIMERS AND PERIODIC TASKS
  // ========================================

  /// Setup daily bonus timer
  void _setupDailyBonusTimer() {
    _dailyBonusTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkDailyBonus(),
    );
  }

  /// Setup achievement checker
  void _setupAchievementChecker() {
    _achievementCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkPendingAchievements(),
    );
  }

  /// Check for daily bonus availability
  void _checkDailyBonus() {
    if (state.playerStats != null) {
      final now = DateTime.now();
      final lastLogin = state.playerStats!.lastLoginDate;
      
      if (lastLogin == null || _isDifferentDay(lastLogin, now)) {
        emit(state.copyWith(showDailyBonus: true));
      }
    }
  }

  // ========================================
  // UI HELPERS
  // ========================================

  /// Dismiss daily bonus UI
  void dismissDailyBonus() {
    emit(state.copyWith(showDailyBonus: false, dailyBonusEarned: 0));
  }

  /// Dismiss coins earned UI
  void dismissCoinsEarned() {
    emit(state.copyWith(showCoinsEarned: false, coinsEarned: 0));
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  // ========================================
  // CLEANUP
  // ========================================

  @override
  Future<void> close() {
    _dailyBonusTimer?.cancel();
    _achievementCheckTimer?.cancel();
    return super.close();
  }
}
