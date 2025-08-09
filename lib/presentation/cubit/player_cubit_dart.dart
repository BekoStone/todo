import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/domain/usecases/player_usecases.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';

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
      final stats = playerStats ?? await _createNewPlayerStats();
      
      // Load achievement progress
      final achievementProgress = <String, double>{};
      for (final achievement in achievements) {
        achievementProgress[achievement.id] = achievement.currentProgress.toDouble();
      }
      
      // Get unlocked achievements
      final unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
      
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: stats,
        achievements: achievements,
        unlockedAchievements: unlockedAchievements,
        hasUnseenAchievements: unlockedAchievements.any((a) => !a.hasBeenSeen),
        isNewPlayer: isNewPlayer,
        achievementProgress: achievementProgress,
        totalCoinsEarned: stats.totalCoinsEarned,
        dailyStreakCount: await _playerUseCases.getPlayStreak(),
      ));
      
      // Check for daily bonus eligibility
      await _checkDailyBonus();
      
      // Check for pending achievements
      await _checkPendingAchievements();
      
      developer.log('Player initialized - New: $isNewPlayer, Coins: ${stats.currentCoins}', name: 'PlayerCubit');
      
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
    const playerId = 'player_001'; // Could be generated or from auth system
    final newStats = await _playerUseCases.createNewPlayer(playerId);
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
    required Map<String, int> usedPowerUps,
    bool hadPerfectClear = false,
    bool usedUndo = false,
  }) async {
    if (state.playerStats == null) return;

    try {
      emit(state.copyWith(status: PlayerStateStatus.updating));
      
      // Calculate coins earned from this game
      final coinsEarned = _calculateGameCoins(finalScore, level, linesCleared, hadPerfectClear);
      
      // Update player stats
      final currentStats = state.playerStats!;
      final updatedStats = currentStats.copyWith(
        totalScore: currentStats.totalScore + finalScore,
        bestScore: math.max(currentStats.bestScore, finalScore),
        totalGamesPlayed: currentStats.totalGamesPlayed + 1,
        totalTimePlayed: currentStats.totalTimePlayed + gameDuration,
        totalBlocksPlaced: currentStats.totalBlocksPlaced + blocksPlaced,
        totalLinesCleared: currentStats.totalLinesCleared + linesCleared,
        currentCoins: currentStats.currentCoins + coinsEarned,
        totalCoinsEarned: currentStats.totalCoinsEarned + coinsEarned,
        lastPlayDate: DateTime.now(),
      );

      // Save updated stats
      await _playerUseCases.savePlayerStats(updatedStats);
      
      // Add score to recent scores
      await _playerUseCases.addScore(finalScore);
      
      // Check for new achievements
      final newAchievements = await _checkGameAchievements(
        finalScore: finalScore,
        level: level,
        linesCleared: linesCleared,
        blocksPlaced: blocksPlaced,
        hadPerfectClear: hadPerfectClear,
        usedUndo: usedUndo,
        updatedStats: updatedStats,
      );
      
      // Update play streak
      await _playerUseCases.updatePlayStreak();
      final newStreak = await _playerUseCases.getPlayStreak();
      
      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: updatedStats,
        coinsEarned: coinsEarned,
        totalCoinsEarned: updatedStats.totalCoinsEarned,
        recentUnlocks: newAchievements,
        hasUnseenAchievements: newAchievements.isNotEmpty || state.hasUnseenAchievements,
        dailyStreakCount: newStreak,
      ));
      
      developer.log('Game completion processed - Score: $finalScore, Coins: +$coinsEarned', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to process game completion: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to process game completion: $e',
      ));
    }
  }

  /// Calculate coins earned from game performance
  int _calculateGameCoins(int score, int level, int linesCleared, bool hadPerfectClear) {
    int baseCoins = (score / 100).floor();
    
    // Level bonus
    baseCoins += level * 5;
    
    // Lines cleared bonus
    baseCoins += linesCleared * 2;
    
    // Perfect clear bonus
    if (hadPerfectClear) {
      baseCoins += 50;
    }
    
    return math.max(1, baseCoins);
  }

  // ========================================
  // ACHIEVEMENT MANAGEMENT
  // ========================================

  /// Check for achievements based on game completion
  Future<List<Achievement>> _checkGameAchievements({
    required int finalScore,
    required int level,
    required int linesCleared,
    required int blocksPlaced,
    required bool hadPerfectClear,
    required bool usedUndo,
    required PlayerStats updatedStats,
  }) async {
    final newlyUnlocked = <Achievement>[];
    
    try {
      // Score-based achievements
      if (finalScore >= 1000 && !_hasAchievement('score_1000')) {
        newlyUnlocked.add(await _unlockAchievement('score_1000'));
      }
      if (finalScore >= 5000 && !_hasAchievement('score_5000')) {
        newlyUnlocked.add(await _unlockAchievement('score_5000'));
      }
      if (finalScore >= 10000 && !_hasAchievement('score_10000')) {
        newlyUnlocked.add(await _unlockAchievement('score_10000'));
      }
      
      // Game count achievements
      if (updatedStats.totalGamesPlayed >= 10 && !_hasAchievement('games_10')) {
        newlyUnlocked.add(await _unlockAchievement('games_10'));
      }
      if (updatedStats.totalGamesPlayed >= 50 && !_hasAchievement('games_50')) {
        newlyUnlocked.add(await _unlockAchievement('games_50'));
      }
      if (updatedStats.totalGamesPlayed >= 100 && !_hasAchievement('games_100')) {
        newlyUnlocked.add(await _unlockAchievement('games_100'));
      }
      
      // Lines cleared achievements
      if (updatedStats.totalLinesCleared >= 100 && !_hasAchievement('lines_100')) {
        newlyUnlocked.add(await _unlockAchievement('lines_100'));
      }
      if (updatedStats.totalLinesCleared >= 500 && !_hasAchievement('lines_500')) {
        newlyUnlocked.add(await _unlockAchievement('lines_500'));
      }
      
      // Perfect clear achievement
      if (hadPerfectClear && !_hasAchievement('perfect_clear')) {
        newlyUnlocked.add(await _unlockAchievement('perfect_clear'));
      }
      
      // First game achievement
      if (updatedStats.totalGamesPlayed == 1 && !_hasAchievement('first_game')) {
        newlyUnlocked.add(await _unlockAchievement('first_game'));
      }
      
      // Update achievement progress for incremental ones
      await _updateAchievementProgress(updatedStats);
      
    } catch (e) {
      developer.log('Failed to check game achievements: $e', name: 'PlayerCubit');
    }
    
    return newlyUnlocked;
  }

  /// Update progress for incremental achievements
  Future<void> _updateAchievementProgress(PlayerStats stats) async {
    final progressUpdates = <String, double>{
      'score_master': stats.bestScore / 100000.0, // Target: 100K points
      'time_player': stats.totalTimePlayed.inHours / 100.0, // Target: 100 hours
      'block_master': stats.totalBlocksPlaced / 10000.0, // Target: 10K blocks
      'line_master': stats.totalLinesCleared / 1000.0, // Target: 1K lines
    };
    
    for (final entry in progressUpdates.entries) {
      _achievementProgress[entry.key] = math.min(1.0, entry.value);
    }
    
    emit(state.copyWith(achievementProgress: Map.from(_achievementProgress)));
  }

  /// Check if player has a specific achievement
  bool _hasAchievement(String achievementId) {
    return state.unlockedAchievements.any((a) => a.id == achievementId);
  }

  /// Unlock a specific achievement
  Future<Achievement> _unlockAchievement(String achievementId) async {
    await _playerUseCases.unlockAchievement(achievementId);
    final achievement = state.achievements.firstWhere((a) => a.id == achievementId);
    return achievement.unlock();
  }

  /// Mark achievements as seen
  void markAchievementsAsSeen() {
    emit(state.copyWith(
      hasUnseenAchievements: false,
      recentUnlocks: [],
    ));
  }

  // ========================================
  // COIN MANAGEMENT
  // ========================================

  /// Add coins to player balance
  Future<void> addCoins(int amount) async {
    if (state.playerStats == null || amount <= 0) return;
    
    try {
      final success = await _playerUseCases.addCoins(amount);
      if (success) {
        final updatedStats = state.playerStats!.copyWith(
          currentCoins: state.playerStats!.currentCoins + amount,
          totalCoinsEarned: state.playerStats!.totalCoinsEarned + amount,
        );
        
        await _playerUseCases.savePlayerStats(updatedStats);
        
        emit(state.copyWith(
          playerStats: updatedStats,
          coinsEarned: state.coinsEarned + amount,
          totalCoinsEarned: updatedStats.totalCoinsEarned,
        ));
        
        developer.log('Added $amount coins, total: ${updatedStats.currentCoins}', name: 'PlayerCubit');
      }
    } catch (e) {
      developer.log('Failed to add coins: $e', name: 'PlayerCubit');
    }
  }

  /// Spend coins from player balance
  Future<bool> spendCoins(int amount) async {
    if (state.playerStats == null || amount <= 0) return false;
    
    try {
      final hasEnough = await _playerUseCases.hasEnoughCoins(amount);
      if (!hasEnough) {
        emit(state.copyWith(errorMessage: 'Insufficient coins'));
        return false;
      }
      
      final success = await _playerUseCases.spendCoins(amount);
      if (success) {
        final updatedStats = state.playerStats!.copyWith(
          currentCoins: state.playerStats!.currentCoins - amount,
        );
        
        await _playerUseCases.savePlayerStats(updatedStats);
        
        emit(state.copyWith(
          playerStats: updatedStats,
          errorMessage: null,
        ));
        
        developer.log('Spent $amount coins, remaining: ${updatedStats.currentCoins}', name: 'PlayerCubit');
        return true;
      }
    } catch (e) {
      developer.log('Failed to spend coins: $e', name: 'PlayerCubit');
      emit(state.copyWith(errorMessage: 'Failed to spend coins'));
    }
    
    return false;
  }

  /// Check daily bonus eligibility and claim if available
  Future<void> _checkDailyBonus() async {
    try {
      final canClaim = await _playerUseCases.canClaimDailyBonus();
      if (canClaim) {
        final result = await _playerUseCases.claimDailyBonus();
        if (result['success'] == true) {
          final bonusAmount = result['coinsEarned'] as int;
          await addCoins(bonusAmount);
          
          emit(state.copyWith(
            lastDailyBonusTime: DateTime.now(),
          ));
          
          developer.log('Daily bonus claimed: $bonusAmount coins', name: 'PlayerCubit');
        }
      }
    } catch (e) {
      developer.log('Failed to check daily bonus: $e', name: 'PlayerCubit');
    }
  }

  // ========================================
  // POWER-UP MANAGEMENT
  // ========================================

  /// Purchase power-up with coins
  Future<bool> purchasePowerUp(PowerUpType type, int quantity) async {
    try {
      final result = await _playerUseCases.purchasePowerUp(type, quantity);
      
      if (result['success'] == true) {
        final cost = result['cost'] as int;
        developer.log('Power-up purchased: $type x$quantity for $cost coins', name: 'PlayerCubit');
        return true;
      } else {
        emit(state.copyWith(errorMessage: result['reason'] as String));
        return false;
      }
    } catch (e) {
      developer.log('Failed to purchase power-up: $e', name: 'PlayerCubit');
      emit(state.copyWith(errorMessage: 'Failed to purchase power-up'));
      return false;
    }
  }

  /// Use a power-up
  Future<bool> usePowerUp(PowerUpType type) async {
    try {
      final success = await _playerUseCases.usePowerUp(type);
      if (success) {
        developer.log('Power-up used: $type', name: 'PlayerCubit');
      }
      return success;
    } catch (e) {
      developer.log('Failed to use power-up: $e', name: 'PlayerCubit');
      return false;
    }
  }

  /// Get power-up inventory
  Future<Map<PowerUpType, int>> getPowerUpInventory() async {
    try {
      return await _playerUseCases.getPowerUpInventory();
    } catch (e) {
      developer.log('Failed to get power-up inventory: $e', name: 'PlayerCubit');
      return {};
    }
  }

  // ========================================
  // PLAYER SETTINGS
  // ========================================

  /// Update player setting
  Future<void> updatePlayerSetting(String key, dynamic value) async {
    try {
      await _playerUseCases.updatePlayerSetting(key, value);
      developer.log('Player setting updated: $key = $value', name: 'PlayerCubit');
    } catch (e) {
      developer.log('Failed to update player setting: $e', name: 'PlayerCubit');
    }
  }

  /// Get player setting
  Future<T?> getPlayerSetting<T>(String key, {T? defaultValue}) async {
    try {
      return await _playerUseCases.getPlayerSetting<T>(key, defaultValue: defaultValue);
    } catch (e) {
      developer.log('Failed to get player setting: $e', name: 'PlayerCubit');
      return defaultValue;
    }
  }

  // ========================================
  // ANALYTICS & STATISTICS
  // ========================================

  /// Get comprehensive player analytics
  Future<Map<String, dynamic>> getPlayerAnalytics() async {
    try {
      return await _playerUseCases.getPlayerAnalytics();
    } catch (e) {
      developer.log('Failed to get player analytics: $e', name: 'PlayerCubit');
      return {};
    }
  }

  /// Get recent scores
  Future<List<int>> getRecentScores({int limit = 10}) async {
    try {
      return await _playerUseCases.getRecentScores(limit: limit);
    } catch (e) {
      developer.log('Failed to get recent scores: $e', name: 'PlayerCubit');
      return [];
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

  /// Setup auto-save for player data
  void _setupAutoSave() {
    _saveTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _autoSavePlayerData();
    });
  }

  /// Check pending achievements
  Future<void> _checkPendingAchievements() async {
    if (_pendingAchievements.isEmpty) return;
    
    try {
      for (final achievementId in List.from(_pendingAchievements)) {
        // Check if achievement should be unlocked
        final shouldUnlock = await _checkAchievementCondition(achievementId);
        if (shouldUnlock) {
          await _unlockAchievement(achievementId);
          _pendingAchievements.remove(achievementId);
        }
      }
    } catch (e) {
      developer.log('Failed to check pending achievements: $e', name: 'PlayerCubit');
    }
  }

  /// Check if achievement condition is met
  Future<bool> _checkAchievementCondition(String achievementId) async {
    // Implementation would check specific conditions for each achievement
    // This is a simplified version
    return false;
  }

  /// Auto-save player data
  Future<void> _autoSavePlayerData() async {
    if (state.playerStats != null) {
      try {
        await _playerUseCases.savePlayerStats(state.playerStats!);
        developer.log('Player data auto-saved', name: 'PlayerCubit');
      } catch (e) {
        developer.log('Auto-save failed: $e', name: 'PlayerCubit');
      }
    }
  }

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  /// Reset all player data
  Future<void> resetPlayerData() async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.loading));
      
      // Create new player stats
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
        dailyStreakCount: 0,
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
      'isNewPlayer': state.isNewPlayer,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import player data from backup
  Future<void> importPlayerData(Map<String, dynamic> data) async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.loading));
      
      // Parse and validate data
      final playerStatsData = data['playerStats'] as Map<String, dynamic>?;
      if (playerStatsData != null) {
        final playerStats = PlayerStats.fromJson(playerStatsData);
        await _playerUseCases.savePlayerStats(playerStats);
      }
      
      // Reinitialize with imported data
      await initializePlayer();
      
      developer.log('Player data imported successfully', name: 'PlayerCubit');
      
    } catch (e) {
      developer.log('Failed to import player data: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to import player data: $e',
      ));
    }
  }

  /// Clear any error state
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Get current player status summary
  Map<String, dynamic> getPlayerStatus() {
    return {
      'isLoaded': state.status == PlayerStateStatus.loaded,
      'isNewPlayer': state.isNewPlayer,
      'currentCoins': state.playerStats?.currentCoins ?? 0,
      'totalGamesPlayed': state.playerStats?.totalGamesPlayed ?? 0,
      'bestScore': state.playerStats?.bestScore ?? 0,
      'achievementsUnlocked': state.unlockedAchievements.length,
      'totalAchievements': state.achievements.length,
      'hasUnseenAchievements': state.hasUnseenAchievements,
      'dailyStreak': state.dailyStreakCount,
    };
  }
}