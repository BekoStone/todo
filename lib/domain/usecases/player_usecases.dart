import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import '../repositories/player_repository.dart';

/// Player-related business logic operations.
/// Manages player stats, achievements, inventory, and progression.
/// Follows Clean Architecture by containing all player-specific use cases.
class PlayerUseCases {
  final PlayerRepository _repository;
  
  PlayerUseCases(this._repository);

  // ========================================
  // PLAYER STATS MANAGEMENT
  // ========================================
  
  /// Load player statistics
  Future<PlayerStats?> loadPlayerStats() async {
    try {
      return await _repository.loadPlayerStats();
    } catch (e) {
      debugPrint('Failed to load player stats: $e');
      return null;
    }
  }
  
  /// Save player statistics
  Future<bool> savePlayerStats(PlayerStats playerStats) async {
    try {
      return await _repository.savePlayerStats(playerStats);
    } catch (e) {
      debugPrint('Failed to save player stats: $e');
      return false;
    }
  }
  
  /// Create a new player
  Future<PlayerStats> createNewPlayer(String playerId) async {
    try {
      return await _repository.createNewPlayer(playerId);
    } catch (e) {
      debugPrint('Failed to create new player: $e');
      // Return default player stats
      return PlayerStats.newPlayer(playerId);
    }
  }

  /// Get current player statistics with caching
  Future<PlayerStats?> getCurrentPlayerStats() async {
    try {
      return await _repository.getPlayerStats();
    } catch (e) {
      debugPrint('Failed to get current player stats: $e');
      return null;
    }
  }

  /// Update player display name
  Future<bool> updatePlayerName(String playerId, String newName) async {
    try {
      return await _repository.updatePlayerName(playerId, newName);
    } catch (e) {
      debugPrint('Failed to update player name: $e');
      return false;
    }
  }

  /// Update player avatar
  Future<bool> updatePlayerAvatar(String playerId, String avatarUrl) async {
    try {
      return await _repository.updatePlayerAvatar(playerId, avatarUrl);
    } catch (e) {
      debugPrint('Failed to update player avatar: $e');
      return false;
    }
  }

  // ========================================
  // GAME SESSION COMPLETION
  // ========================================
  
  /// Update player stats after completing a game session
  Future<PlayerStats?> updateStatsAfterGame({
    required GameSession gameSession,
    required PlayerStats currentStats,
    required int coinsEarned,
    bool hadPerfectClear = false,
    bool usedUndo = false,
  }) async {
    try {
      final sessionTime = gameSession.actualPlayTime;
      final blocksPlaced = _calculateBlocksPlaced(gameSession);
      
      final updatedStats = currentStats.afterGameSession(
        gameScore: gameSession.currentScore,
        blocksPlaced: blocksPlaced,
        linesCleared: gameSession.linesCleared,
        maxCombo: gameSession.maxCombo,
        maxStreak: gameSession.statistics.maxStreak,
        sessionTime: sessionTime,
        coinsEarned: coinsEarned,
        hadPerfectClear: hadPerfectClear,
      );
      
      final success = await savePlayerStats(updatedStats);
      return success ? updatedStats : null;
    } catch (e) {
      debugPrint('Failed to update stats after game: $e');
      return null;
    }
  }

  /// Process game completion and update all related stats
  Future<Map<String, dynamic>> processGameCompletion({
    required GameSession gameSession,
    required PlayerStats currentStats,
    bool hadPerfectClear = false,
    bool usedUndo = false,
    List<String> powerUpsUsed = const [],
  }) async {
    try {
      // Calculate coins earned
      final coinsEarned = _calculateCoinsEarned(
        gameSession,
        hadPerfectClear: hadPerfectClear,
        usedUndo: usedUndo,
      );

      // Update player stats
      final updatedStats = await updateStatsAfterGame(
        gameSession: gameSession,
        currentStats: currentStats,
        coinsEarned: coinsEarned,
        hadPerfectClear: hadPerfectClear,
        usedUndo: usedUndo,
      );

      if (updatedStats == null) {
        throw Exception('Failed to update player stats');
      }

      // Check for new achievements
      final achievementProgress = await _checkAchievementProgress(updatedStats, gameSession);

      // Update play streak
      final streakUpdated = await updatePlayStreak();

      return {
        'updatedStats': updatedStats,
        'coinsEarned': coinsEarned,
        'newAchievements': achievementProgress['newAchievements'] ?? [],
        'achievementProgress': achievementProgress['progress'] ?? [],
        'isNewBestScore': gameSession.currentScore > currentStats.highScore,
        'playStreakUpdated': streakUpdated,
        'levelUp': updatedStats.currentLevel > currentStats.currentLevel,
      };
    } catch (e) {
      debugPrint('Failed to process game completion: $e');
      return {
        'error': e.toString(),
        'coinsEarned': 0,
        'newAchievements': <Achievement>[],
        'achievementProgress': <Map<String, dynamic>>[],
        'isNewBestScore': false,
        'playStreakUpdated': false,
        'levelUp': false,
      };
    }
  }

  // ========================================
  // COIN MANAGEMENT
  // ========================================

  /// Get current coin balance
  Future<int> getCoins() async {
    try {
      return await _repository.getCoins();
    } catch (e) {
      debugPrint('Failed to get coins: $e');
      return 0;
    }
  }

  /// Add coins to player balance
  Future<bool> addCoins(int amount) async {
    try {
      return await _repository.addCoins(amount);
    } catch (e) {
      debugPrint('Failed to add coins: $e');
      return false;
    }
  }

  /// Spend coins from player balance
  Future<bool> spendCoins(int amount) async {
    try {
      final hasEnough = await _repository.hasEnoughCoins(amount);
      if (!hasEnough) {
        debugPrint('Insufficient coins to spend $amount');
        return false;
      }
      return await _repository.spendCoins(amount);
    } catch (e) {
      debugPrint('Failed to spend coins: $e');
      return false;
    }
  }

  /// Check if player has enough coins
  Future<bool> hasEnoughCoins(int amount) async {
    try {
      return await _repository.hasEnoughCoins(amount);
    } catch (e) {
      debugPrint('Failed to check coin balance: $e');
      return false;
    }
  }

  /// Claim daily bonus coins
  Future<Map<String, dynamic>> claimDailyBonus() async {
    try {
      final canClaim = await _repository.canClaimDailyBonus();
      if (!canClaim) {
        return {
          'success': false,
          'reason': 'Daily bonus already claimed',
          'coinsEarned': 0,
        };
      }

      final bonusAmount = _calculateDailyBonus();
      final claimed = await _repository.claimDailyBonus();
      
      if (claimed) {
        await addCoins(bonusAmount);
        return {
          'success': true,
          'coinsEarned': bonusAmount,
          'message': 'Daily bonus claimed!',
        };
      }

      return {
        'success': false,
        'reason': 'Failed to claim bonus',
        'coinsEarned': 0,
      };
    } catch (e) {
      debugPrint('Failed to claim daily bonus: $e');
      return {
        'success': false,
        'reason': 'Error claiming bonus',
        'coinsEarned': 0,
      };
    }
  }

  // ========================================
  // POWER-UP MANAGEMENT
  // ========================================

  /// Get power-up inventory
  Future<Map<PowerUpType, int>> getPowerUpInventory() async {
    try {
      return await _repository.loadPowerUpInventory();
    } catch (e) {
      debugPrint('Failed to get power-up inventory: $e');
      return {};
    }
  }

  /// Use a power-up
  Future<bool> usePowerUp(PowerUpType type) async {
    try {
      final hasEnough = await _repository.hasPowerUp(type);
      if (!hasEnough) {
        debugPrint('No $type power-up available');
        return false;
      }
      return await _repository.usePowerUp(type);
    } catch (e) {
      debugPrint('Failed to use power-up: $e');
      return false;
    }
  }

  /// Add power-up to inventory
  Future<bool> addPowerUp(PowerUpType type, int quantity) async {
    try {
      return await _repository.addPowerUp(type, quantity);
    } catch (e) {
      debugPrint('Failed to add power-up: $e');
      return false;
    }
  }

  /// Purchase power-up with coins
  Future<Map<String, dynamic>> purchasePowerUp(PowerUpType type, int quantity) async {
    try {
      final cost = _calculatePowerUpCost(type, quantity);
      final hasEnoughCoins = await hasEnoughCoins(cost);
      
      if (!hasEnoughCoins) {
        return {
          'success': false,
          'reason': 'Insufficient coins',
          'cost': cost,
        };
      }

      final coinsSpent = await spendCoins(cost);
      if (!coinsSpent) {
        return {
          'success': false,
          'reason': 'Failed to spend coins',
          'cost': cost,
        };
      }

      final powerUpAdded = await addPowerUp(type, quantity);
      if (!powerUpAdded) {
        // Refund coins if power-up addition failed
        await addCoins(cost);
        return {
          'success': false,
          'reason': 'Failed to add power-up',
          'cost': cost,
        };
      }

      return {
        'success': true,
        'powerUpType': type,
        'quantity': quantity,
        'cost': cost,
      };
    } catch (e) {
      debugPrint('Failed to purchase power-up: $e');
      return {
        'success': false,
        'reason': 'Purchase error',
        'cost': 0,
      };
    }
  }

  // ========================================
  // ACHIEVEMENT MANAGEMENT
  // ========================================

  /// Get all achievements
  Future<List<Achievement>> getAchievements() async {
    try {
      return await _repository.getAchievements();
    } catch (e) {
      debugPrint('Failed to get achievements: $e');
      return [];
    }
  }

  /// Get unlocked achievements
  Future<List<Achievement>> getUnlockedAchievements() async {
    try {
      return await _repository.getUnlockedAchievements();
    } catch (e) {
      debugPrint('Failed to get unlocked achievements: $e');
      return [];
    }
  }

  /// Get achievements by category
  Future<List<Achievement>> getAchievementsByCategory(AchievementCategory category) async {
    try {
      final allAchievements = await getAchievements();
      return allAchievements.where((a) => a.category == category).toList();
    } catch (e) {
      debugPrint('Failed to get achievements by category: $e');
      return [];
    }
  }

  /// Check achievement progress
  Future<double> getAchievementProgress(String achievementId) async {
    try {
      return await _repository.getAchievementProgress(achievementId);
    } catch (e) {
      debugPrint('Failed to get achievement progress: $e');
      return 0.0;
    }
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================

  /// Get recent game scores
  Future<List<int>> getRecentScores({int limit = 10}) async {
    try {
      return await _repository.getRecentScores(limit: limit);
    } catch (e) {
      debugPrint('Failed to get recent scores: $e');
      return [];
    }
  }

  /// Add score to history
  Future<bool> addScore(int score) async {
    try {
      return await _repository.addScore(score);
    } catch (e) {
      debugPrint('Failed to add score: $e');
      return false;
    }
  }

  /// Get play streak
  Future<int> getPlayStreak() async {
    try {
      return await _repository.getPlayStreak();
    } catch (e) {
      debugPrint('Failed to get play streak: $e');
      return 0;
    }
  }

  /// Update play streak
  Future<bool> updatePlayStreak() async {
    try {
      return await _repository.updatePlayStreak();
    } catch (e) {
      debugPrint('Failed to update play streak: $e');
      return false;
    }
  }

  /// Get comprehensive player analytics
  Future<Map<String, dynamic>> getPlayerAnalytics() async {
    try {
      final stats = await getCurrentPlayerStats();
      if (stats == null) return {};

      final recentScores = await getRecentScores(limit: 10);
      final playStreak = await getPlayStreak();
      final achievements = await getUnlockedAchievements();
      final powerUps = await getPowerUpInventory();

      return {
        'totalScore': stats.totalScore,
        'bestScore': stats.bestScore,
        'averageScore': recentScores.isNotEmpty 
          ? recentScores.reduce((a, b) => a + b) / recentScores.length 
          : 0.0,
        'gamesPlayed': stats.totalGamesPlayed,
        'totalPlayTime': stats.totalPlayTime.inMinutes,
        'linesCleared': stats.totalLinesCleared,
        'blocksPlaced': stats.totalBlocksPlaced,
        'currentCoins': stats.currentCoins,
        'totalCoinsEarned': stats.totalCoinsEarned,
        'playStreak': playStreak,
        'achievementsUnlocked': achievements.length,
        'powerUpsOwned': powerUps.values.fold<int>(0, (sum, count) => sum + count),
        'perfectClears': stats.perfectClears,
        'bestCombo': stats.bestCombo,
        'bestStreak': stats.bestStreak,
        'currentLevel': stats.currentLevel,
      };
    } catch (e) {
      debugPrint('Failed to get player analytics: $e');
      return {};
    }
  }

  // ========================================
  // SETTINGS MANAGEMENT
  // ========================================

  /// Get player settings
  Future<Map<String, dynamic>> getPlayerSettings() async {
    try {
      return await _repository.getPlayerSettings();
    } catch (e) {
      debugPrint('Failed to get player settings: $e');
      return {};
    }
  }

  /// Update player setting
  Future<bool> updatePlayerSetting(String key, dynamic value) async {
    try {
      return await _repository.updateSetting(key, value);
    } catch (e) {
      debugPrint('Failed to update player setting: $e');
      return false;
    }
  }

  /// Get specific setting value
  Future<T?> getPlayerSetting<T>(String key, {T? defaultValue}) async {
    try {
      return await _repository.getSetting<T>(key, defaultValue: defaultValue);
    } catch (e) {
      debugPrint('Failed to get player setting: $e');
      return defaultValue;
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Calculate blocks placed from game session
  int _calculateBlocksPlaced(GameSession gameSession) {
    return gameSession.statistics.blocksPlaced;
  }

  /// Calculate coins earned from game session
  int _calculateCoinsEarned(
    GameSession gameSession, {
    bool hadPerfectClear = false,
    bool usedUndo = false,
  }) {
    int baseCoins = (gameSession.currentScore / 100).floor();
    
    // Bonus for perfect clear
    if (hadPerfectClear) {
      baseCoins += 50;
    }
    
    // Penalty for using undo
    if (usedUndo) {
      baseCoins = (baseCoins * 0.8).floor();
    }
    
    // Level multiplier
    baseCoins *= gameSession.currentLevel;
    
    return math.max(1, baseCoins);
  }

  /// Calculate daily bonus amount
  int _calculateDailyBonus() {
    // Base daily bonus, could be enhanced with streak multipliers
    return 50;
  }

  /// Calculate power-up cost
  int _calculatePowerUpCost(PowerUpType type, int quantity) {
    const baseCosts = {
      PowerUpType.hammer: 100,
      PowerUpType.bomb: 200,
      PowerUpType.lineClear: 150,
      PowerUpType.shuffle: 75,
      PowerUpType.hint: 50,
    };
    
    final baseCost = baseCosts[type] ?? 100;
    return baseCost * quantity;
  }

  /// Check for achievement progress updates
  Future<Map<String, dynamic>> _checkAchievementProgress(
    PlayerStats updatedStats,
    GameSession gameSession,
  ) async {
    try {
      final achievements = await getAchievements();
      final newlyUnlocked = <Achievement>[];
      final progressUpdates = <Map<String, dynamic>>[];

      for (final achievement in achievements) {
        if (achievement.isUnlocked) continue;

        final previousProgress = achievement.currentProgress;
        var newProgress = previousProgress;

        // Check achievement conditions based on type
        switch (achievement.id) {
          case 'first_game':
            newProgress = updatedStats.totalGamesPlayed >= 1 ? 1 : 0;
            break;
          case 'score_1000':
            newProgress = gameSession.currentScore >= 1000 ? 1 : 0;
            break;
          case 'games_10':
            newProgress = updatedStats.totalGamesPlayed;
            break;
          case 'lines_100':
            newProgress = updatedStats.totalLinesCleared;
            break;
          // Add more achievement checks here
        }

        if (newProgress != previousProgress) {
          progressUpdates.add({
            'achievementId': achievement.id,
            'previousProgress': previousProgress,
            'newProgress': newProgress,
            'targetValue': achievement.targetValue,
          });

          if (newProgress >= achievement.targetValue && !achievement.isUnlocked) {
            final unlockedAchievement = achievement.unlock();
            newlyUnlocked.add(unlockedAchievement);
            await _repository.updateAchievement(unlockedAchievement);
          }
        }
      }

      return {
        'newAchievements': newlyUnlocked,
        'progress': progressUpdates,
      };
    } catch (e) {
      debugPrint('Failed to check achievement progress: $e');
      return {
        'newAchievements': <Achievement>[],
        'progress': <Map<String, dynamic>>[],
      };
    }
  }
}