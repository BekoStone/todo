import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import 'package:puzzle_box/domain/usecases/player_usecases.dart';

/// PlayerCubit manages player data, statistics, achievements, and progression.
/// Handles player profile, coins, achievements, and cross-session data persistence.
/// Follows Clean Architecture with proper error handling and state management.
class PlayerCubit extends Cubit<PlayerState> {
  final PlayerUseCases _playerUseCases;
  final AchievementUseCases _achievementUseCases;
  
  // Timers for periodic operations
  Timer? _dailyBonusTimer;
  Timer? _achievementCheckTimer;
  Timer? _saveTimer;
  
  // Achievement tracking
  final Set<String> _pendingAchievements = {};
  final Map<String, double> _achievementProgress = {};

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
    _saveTimer?.cancel();
    await super.close();
  }

  /// Initialize the player cubit
  void _initializePlayerCubit() {
    developer.log('PlayerCubit initialized', name: 'PlayerCubit');
    _setupDailyBonusTimer();
    _setupAchievementChecker();
    _setupAutoSave();
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
      final achievements = await _playerUseCases.getAchievements();
      
      // Check if this is a new player
      final isNewPlayer = playerStats == null;
      
      // Create default stats for new players
      final stats = playerStats ?? PlayerStats.createDefault();
      
      // Load achievements
      final allAchievements = await _achievementUseCases.getAllAchievements();
      final unlockedIds = achievements.map((a) => a.id).toSet();
      final unlockedAchievements = allAchievements.where((a) => unlockedIds.contains(a.id)).toList();
      
      // Check for daily bonus
      await _checkDailyBonus(stats);
      
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: stats,
        achievements: unlockedAchievements,
        isNewPlayer: isNewPlayer,
        lastDataSync: DateTime.now(),
      ));
      
      // Show welcome message for new players
      if (isNewPlayer) {
        await _handleNewPlayer();
      }
      
      developer.log('Player data initialized successfully', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to initialize player: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to load player data: $e',
      ));
    }
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
    required bool usedUndo,
    required Map<String, int> usedPowerUps,
  }) async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.updating));
      developer.log('Processing game completion - Score: $finalScore', name: 'PlayerCubit');
      
      final currentStats = state.playerStats ?? PlayerStats.createDefault();
      
      // Calculate coins earned
      final coinsEarned = _calculateCoinsEarned(finalScore, level, linesCleared);
      
      // Update player statistics
      final updatedStats = currentStats.copyWith(
        totalGamesPlayed: currentStats.totalGamesPlayed + 1,
        highScore: math.max(currentStats.highScore, finalScore),
        totalScore: currentStats.totalScore + finalScore,
        totalCoins: currentStats.totalCoins + coinsEarned,
        totalLinesCleared: currentStats.totalLinesCleared + linesCleared,
        totalBlocksPlaced: currentStats.totalBlocksPlaced + blocksPlaced,
        totalPlayTime: currentStats.totalPlayTime + gameDuration,
        lastPlayedDate: DateTime.now(),
        averageScore: (currentStats.totalScore + finalScore) / (currentStats.totalGamesPlayed + 1),
        highestLevel: math.max(currentStats.highestLevel, level),
      );
      
      // Save updated stats
      await _playerUseCases.savePlayerStats(updatedStats);
      
      // Check for new achievements
      final newAchievements = await _checkCompletionAchievements(
        finalScore: finalScore,
        level: level,
        linesCleared: linesCleared,
        gameDuration: gameDuration,
        usedUndo: usedUndo,
        stats: updatedStats,
      );
      
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: updatedStats,
        coinsEarned: coinsEarned,
        showCoinsEarned: coinsEarned > 0,
        unlockedAchievements: newAchievements,
        hasUnseenAchievements: newAchievements.isNotEmpty,
        lastDataSync: DateTime.now(),
      ));
      
      // Auto-hide coins notification
      if (coinsEarned > 0) {
        Timer(const Duration(seconds: 5), () {
          if (!isClosed) {
            emit(state.copyWith(showCoinsEarned: false));
          }
        });
      }
      
      developer.log('Game completion processed - Coins earned: $coinsEarned', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to process game completion: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to update player data: $e',
      ));
    }
  }

  // ========================================
  // ACHIEVEMENTS MANAGEMENT
  // ========================================

  /// Unlock achievement manually
  Future<void> unlockAchievement(String achievementId) async {
    try {
      final achievement = await _achievementUseCases.unlockAchievement(achievementId);
      if (achievement != null) {
        final updatedAchievements = [...state.achievements, achievement];
        
        // Award achievement coins
        final currentStats = state.playerStats ?? PlayerStats.createDefault();
        final updatedStats = currentStats.copyWith(
          totalCoins: currentStats.totalCoins + achievement.coinReward,
        );
        
        emit(state.copyWith(
          achievements: updatedAchievements,
          playerStats: updatedStats,
          unlockedAchievements: [achievement],
          hasUnseenAchievements: true,
        ));
        
        developer.log('Achievement unlocked: ${achievement.title}', name: 'PlayerCubit');
      }
    } catch (e) {
      developer.log('Failed to unlock achievement: $e', name: 'PlayerCubit');
    }
  }

  /// Mark achievements as seen
  void markAchievementsSeen() {
    emit(state.copyWith(
      hasUnseenAchievements: false,
      unlockedAchievements: [],
    ));
  }

  // ========================================
  // COINS AND PURCHASES
  // ========================================

  /// Add coins to player account
  Future<void> addCoins(int amount, {String? reason}) async {
    try {
      final currentStats = state.playerStats ?? PlayerStats.createDefault();
      final updatedStats = currentStats.copyWith(
        totalCoins: currentStats.totalCoins + amount,
      );
      
      await _playerUseCases.savePlayerStats(updatedStats);
      
      emit(state.copyWith(
        playerStats: updatedStats,
        coinsEarned: amount,
        showCoinsEarned: true,
      ));
      
      // Auto-hide notification
      Timer(const Duration(seconds: 3), () {
        if (!isClosed) {
          emit(state.copyWith(showCoinsEarned: false));
        }
      });
      
      developer.log('Added $amount coins${reason != null ? ' - $reason' : ''}', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to add coins: $e', name: 'PlayerCubit');
    }
  }

  /// Spend coins for purchase
  Future<bool> spendCoins(int amount, {String? item}) async {
    try {
      final currentStats = state.playerStats ?? PlayerStats.createDefault();
      
      if (currentStats.totalCoins < amount) {
        developer.log('Insufficient coins for purchase', name: 'PlayerCubit');
        return false;
      }
      
      final updatedStats = currentStats.copyWith(
        totalCoins: currentStats.totalCoins - amount,
      );
      
      await _playerUseCases.savePlayerStats(updatedStats);
      
      emit(state.copyWith(playerStats: updatedStats));
      
      developer.log('Spent $amount coins${item != null ? ' on $item' : ''}', name: 'PlayerCubit');
      return true;
      
    } catch (e) {
      developer.log('Failed to spend coins: $e', name: 'PlayerCubit');
      return false;
    }
  }

  // ========================================
  // DAILY BONUS SYSTEM
  // ========================================

  /// Check and award daily bonus
  Future<void> _checkDailyBonus(PlayerStats stats) async {
    final now = DateTime.now();
    final lastBonus = stats.lastDailyBonusDate;
    
    if (lastBonus == null || !_isSameDay(lastBonus, now)) {
      final bonusAmount = 50; // Base daily bonus
      
      final updatedStats = stats.copyWith(
        totalCoins: stats.totalCoins + bonusAmount,
        lastDailyBonusDate: now,
        dailyBonusStreak: lastBonus != null && _isConsecutiveDay(lastBonus, now) 
          ? stats.dailyBonusStreak + 1 
          : 1,
      );
      
      await _playerUseCases.savePlayerStats(updatedStats);
      
      emit(state.copyWith(
        playerStats: updatedStats,
        dailyBonusEarned: bonusAmount,
        showDailyBonus: true,
      ));
      
      // Auto-hide daily bonus notification
      Timer(const Duration(seconds: 5), () {
        if (!isClosed) {
          emit(state.copyWith(showDailyBonus: false));
        }
      });
      
      developer.log('Daily bonus awarded: $bonusAmount coins', name: 'PlayerCubit');
    }
  }

  /// Claim daily bonus manually
  Future<void> claimDailyBonus() async {
    final stats = state.playerStats;
    if (stats != null) {
      await _checkDailyBonus(stats);
    }
  }

  // ========================================
  // STATISTICS AND PROGRESS
  // ========================================

  /// Get player statistics summary
  Map<String, dynamic> getPlayerStatistics() {
    final stats = state.playerStats;
    if (stats == null) return {};
    
    return {
      'totalGamesPlayed': stats.totalGamesPlayed,
      'highScore': stats.highScore,
      'totalScore': stats.totalScore,
      'averageScore': stats.averageScore,
      'totalCoins': stats.totalCoins,
      'totalLinesCleared': stats.totalLinesCleared,
      'totalBlocksPlaced': stats.totalBlocksPlaced,
      'totalTimePlayed': stats.totalPlayTime.inMinutes,
      'achievementsUnlocked': state.achievements.length,
      'dailyBonusStreak': stats.dailyBonusStreak,
      'lastPlayedDate': stats.lastLoginDate?.toIso8601String(),
    };
  }

  /// Get achievement progress
  Future<Map<String, double>> getAchievementProgress() async {
    try {
      final allAchievements = await _achievementUseCases.getAllAchievements();
      final progress = <String, double>{};
      
      for (final achievement in allAchievements) {
        progress[achievement.id] = await _achievementUseCases.getAchievementProgress(
          achievement.id,
          state.playerStats,
        );
      }
      
      return progress;
    } catch (e) {
      developer.log('Failed to get achievement progress: $e', name: 'PlayerCubit');
      return {};
    }
  }

  // ========================================
  // PRIVATE HELPER METHODS
  // ========================================

  /// Calculate coins earned based on game performance
  int _calculateCoinsEarned(int score, int level, int linesCleared) {
    final baseCoins = (score / 1000).floor();
    final levelBonus = level * 2;
    final lineBonus = linesCleared * 5;
    
    return math.max(1, baseCoins + levelBonus + lineBonus);
  }

  /// Check for achievements after game completion
  Future<List<Achievement>> _checkCompletionAchievements({
    required int finalScore,
    required int level,
    required int linesCleared,
    required Duration gameDuration,
    required bool usedUndo,
    required PlayerStats stats,
  }) async {
    try {
      return await _achievementUseCases.checkCompletionAchievements(
        finalScore: finalScore,
        level: level,
        linesCleared: linesCleared,
        gameDuration: gameDuration,
        usedUndo: usedUndo,
        stats: stats,
      );
    } catch (e) {
      developer.log('Failed to check completion achievements: $e', name: 'PlayerCubit');
      return [];
    }
  }

  /// Handle new player setup
  Future<void> _handleNewPlayer() async {
    // Award welcome bonus
    await addCoins(100, reason: 'Welcome bonus');
    
    // Check for beginner achievements
    await _achievementUseCases.checkBeginnerAchievements();
    
    developer.log('New player setup completed', name: 'PlayerCubit');
  }

  /// Setup daily bonus timer
  void _setupDailyBonusTimer() {
    _dailyBonusTimer?.cancel();
    _dailyBonusTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      final stats = state.playerStats;
      if (stats != null) {
        _checkDailyBonus(stats);
      }
    });
  }

  /// Setup achievement checker timer
  void _setupAchievementChecker() {
    _achievementCheckTimer?.cancel();
    _achievementCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkProgressAchievements();
    });
  }

  /// Setup auto-save timer
  void _setupAutoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _savePlayerData();
    });
  }

  /// Check for progress-based achievements
  Future<void> _checkProgressAchievements() async {
    try {
      if (state.playerStats != null) {
        await _achievementUseCases.checkProgressAchievements(state.playerStats!);
      }
    } catch (e) {
      developer.log('Failed to check progress achievements: $e', name: 'PlayerCubit');
    }
  }

  /// Auto-save player data
  Future<void> _savePlayerData() async {
    try {
      if (state.playerStats != null) {
        await _playerUseCases.savePlayerStats(state.playerStats!);
        emit(state.copyWith(lastDataSync: DateTime.now()));
      }
    } catch (e) {
      developer.log('Failed to auto-save player data: $e', name: 'PlayerCubit');
    }
  }

  /// Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Check if two dates are consecutive days
  bool _isConsecutiveDay(DateTime previousDate, DateTime currentDate) {
    final nextDay = DateTime(previousDate.year, previousDate.month, previousDate.day + 1);
    return _isSameDay(nextDay, currentDate);
  }

  // ========================================
  // PUBLIC UTILITY METHODS
  // ========================================

  /// Refresh player data from storage
  Future<void> refreshPlayerData() async {
    await initializePlayer();
  }

  /// Reset player data (for debugging/testing)
  Future<void> resetPlayerData() async {
    try {
      await _playerUseCases.resetPlayerData();
      emit(const PlayerState());
      await initializePlayer();
      developer.log('Player data reset completed', name: 'PlayerCubit');
    } catch (e) {
      developer.log('Failed to reset player data: $e', name: 'PlayerCubit');
    }
  }

  /// Get player level based on total score
  int getPlayerLevel() {
    final stats = state.playerStats;
    if (stats == null) return 1;
    
    return (stats.totalScore / 10000).floor() + 1;
  }

  /// Get experience progress to next level
  double getExperienceProgress() {
    final stats = state.playerStats;
    if (stats == null) return 0.0;
    
    final currentLevel = getPlayerLevel();
    final currentLevelScore = (currentLevel - 1) * 10000;
    final nextLevelScore = currentLevel * 10000;
    
    final progress = (stats.totalScore - currentLevelScore) / (nextLevelScore - currentLevelScore);
    return progress.clamp(0.0, 1.0);
  }
}