import 'package:flutter/foundation.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import '../repositories/player_repository.dart';

class PlayerUseCases {
  final PlayerRepository _repository;
  
  PlayerUseCases(this._repository);
  
  // Player stats management
  Future<PlayerStats?> loadPlayerStats() async {
    try {
      return await _repository.loadPlayerStats();
    } catch (e) {
      debugPrint('Failed to load player stats: $e');
      return null;
    }
  }
  
  Future<bool> savePlayerStats(PlayerStats playerStats) async {
    try {
      return await _repository.savePlayerStats(playerStats);
    } catch (e) {
      debugPrint('Failed to save player stats: $e');
      return false;
    }
  }
  
  Future<PlayerStats> createNewPlayer(String playerId) async {
    return await _repository.createNewPlayer(playerId);
  }
  
  // Game session completion
  Future<PlayerStats?> updateStatsAfterGame({
    required GameSession gameSession,
    required PlayerStats currentStats,
    required int coinsEarned,
    bool hadPerfectClear = false,
    bool usedUndo = false,
  }) async {
    try {
      final sessionTime = gameSession.currentSessionTime;
      final updatedStats = currentStats.afterGameSession(
        gameScore: gameSession.score,
        blocksPlaced: _calculateBlocksPlaced(gameSession),
        linesCleared: gameSession.linesCleared,
        maxCombo: gameSession.comboCount,
        maxStreak: gameSession.streakCount,
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
  
  // Achievement management
  Future<List<Achievement>> loadAchievements() async {
    return await _repository.loadAchievements();
  }
  
  Future<List<Achievement>> checkAndUpdateAchievements({
    required GameSession gameSession,
    required PlayerStats playerStats,
    required List<Achievement> currentAchievements,
    bool hadPerfectClear = false,
    bool usedUndo = false,
  }) async {
    try {
      final gameData = _buildGameDataForAchievements(
        gameSession,
        playerStats,
        hadPerfectClear: hadPerfectClear,
        usedUndo: usedUndo,
      );
      
      final updatedAchievements = <Achievement>[];
      bool hasNewUnlocks = false;
      
      for (final achievement in currentAchievements) {
        if (achievement.isUnlocked) {
          updatedAchievements.add(achievement);
          continue;
        }
        
        // Calculate new progress
        final newProgress = AchievementChecker.calculateProgress(achievement, gameData);
        final updatedAchievement = achievement.updateProgress(newProgress);
        
        // Check if achievement should be unlocked
        if (!achievement.isUnlocked && 
            AchievementChecker.checkCondition(updatedAchievement, gameData)) {
          final unlockedAchievement = updatedAchievement.unlock();
          updatedAchievements.add(unlockedAchievement);
          hasNewUnlocks = true;
          
          // Grant achievement rewards
          await _grantAchievementRewards(unlockedAchievement);
          
          debugPrint('🏆 Achievement unlocked: ${unlockedAchievement.name}');
        } else {
          updatedAchievements.add(updatedAchievement);
        }
      }
      
      if (hasNewUnlocks) {
        await _repository.saveAchievements(updatedAchievements);
      }
      
      return updatedAchievements;
    } catch (e) {
      debugPrint('Failed to check achievements: $e');
      return currentAchievements;
    }
  }
  
  Future<bool> unlockAchievement(String achievementId) async {
    return await _repository.unlockAchievement(achievementId);
  }
  
  // Power-up management
  Future<Map<PowerUpType, int>> loadPowerUpInventory() async {
    return await _repository.loadPowerUpInventory();
  }
  
  Future<bool> usePowerUp(PowerUpType type) async {
    return await _repository.usePowerUp(type);
  }
  
  Future<bool> addPowerUp(PowerUpType type, int quantity) async {
    return await _repository.addPowerUp(type, quantity);
  }
  
  Future<bool> canUsePowerUp(PowerUpType type, GameSession gameSession) async {
    final inventory = await loadPowerUpInventory();
    final quantity = inventory[type] ?? 0;
    
    if (quantity <= 0) return false;
    
    // Check power-up specific conditions
    final powerUp = PowerUp.definitions[type];
    if (powerUp == null) return false;
    
    final gameState = _buildGameStateForPowerUp(gameSession);
    return powerUp.canBeUsed(gameState);
  }
  
  // Coin management
  Future<int> getCoins() async {
    return await _repository.getCoins();
  }
  
  Future<bool> spendCoins(int amount) async {
    final currentCoins = await getCoins();
    if (currentCoins < amount) return false;
    
    return await _repository.spendCoins(amount);
  }
  
  Future<bool> addCoins(int amount) async {
    return await _repository.addCoins(amount);
  }
  
  Future<bool> purchasePowerUp(PowerUpType type) async {
    final powerUp = PowerUp.definitions[type];
    if (powerUp == null) return false;
    
    final canAfford = await spendCoins(powerUp.cost);
    if (!canAfford) return false;
    
    return await addPowerUp(type, 1);
  }
  
  int calculateCoinsEarned(GameSession gameSession, PlayerStats playerStats) {
    int coins = 0;
    
    // Base coins for playing
    coins += 5;
    
    // Score-based coins
    coins += (gameSession.score / 100).floor();
    
    // Line clear bonus
    coins += gameSession.linesCleared * 2;
    
    // Combo bonus
    if (gameSession.comboCount > 2) {
      coins += gameSession.comboCount * 5;
    }
    
    // Perfect clear bonus
    if (gameSession.gridFillPercentage == 0) {
      coins += 50;
    }
    
    // New high score bonus
    if (gameSession.score > playerStats.bestScore) {
      coins += 25;
    }
    
    return coins;
  }
  
  // Settings management
  Future<Map<String, dynamic>> getPlayerSettings() async {
    return await _repository.getPlayerSettings();
  }
  
  Future<bool> savePlayerSettings(Map<String, dynamic> settings) async {
    return await _repository.savePlayerSettings(settings);
  }
  
  Future<bool> updateSetting(String key, dynamic value) async {
    return await _repository.updateSetting(key, value);
  }
  
  // Statistics and analytics
  Map<String, dynamic> calculateGameStats(GameSession gameSession, PlayerStats playerStats) {
    return {
      'sessionTime': gameSession.currentSessionTime.inSeconds,
      'efficiency': gameSession.efficiency,
      'gridFillPercentage': gameSession.gridFillPercentage,
      'performanceRating': gameSession.performanceRating,
      'isNewHighScore': gameSession.score > playerStats.bestScore,
      'isLongSession': gameSession.isLongSession,
      'isPerfectGame': gameSession.isPerfectGame,
      'levelProgress': gameSession.levelProgress,
      'pointsPerMinute': gameSession.pointsPerMinute,
    };
  }
  
  List<Achievement> getUnlockedAchievements(List<Achievement> achievements) {
    return achievements.where((a) => a.isUnlocked).toList();
  }
  
  List<Achievement> getRecentlyUnlockedAchievements(List<Achievement> achievements) {
    return achievements.where((a) => a.isRecentlyUnlocked).toList();
  }
  
  double calculateOverallProgress(PlayerStats playerStats, List<Achievement> achievements) {
    final totalAchievements = achievements.length;
    final unlockedAchievements = achievements.where((a) => a.isUnlocked).length;
    
    if (totalAchievements == 0) return 0.0;
    
    final achievementProgress = unlockedAchievements / totalAchievements;
    final levelProgress = playerStats.experienceProgress;
    
    // Weight achievements more heavily
    return (achievementProgress * 0.7) + (levelProgress * 0.3);
  }
  
  // Private helper methods
  Map<String, dynamic> _buildGameDataForAchievements(
    GameSession gameSession,
    PlayerStats playerStats, {
    bool hadPerfectClear = false,
    bool usedUndo = false,
  }) {
    return {
      // Current game data
      'currentScore': gameSession.score,
      'level': gameSession.level,
      'linesCleared': gameSession.linesCleared,
      'maxCombo': gameSession.comboCount,
      'maxStreak': gameSession.streakCount,
      'sessionTime': gameSession.currentSessionTime.inSeconds,
      'hadPerfectClear': hadPerfectClear,
      'usedUndo': usedUndo,
      'blocksPlaced': _calculateBlocksPlaced(gameSession),
      
      // Player stats
      'gamesPlayed': playerStats.totalGamesPlayed + 1,
      'totalBlocksPlaced': playerStats.totalBlocksPlaced,
      'totalLinesCleared': playerStats.totalLinesCleared,
      'bestScore': playerStats.bestScore > gameSession.score 
          ? playerStats.bestScore 
          : gameSession.score,
      'bestCombo': playerStats.bestCombo > gameSession.comboCount 
          ? playerStats.bestCombo 
          : gameSession.comboCount,
      'bestLevel': playerStats.experienceLevel > gameSession.level 
          ? playerStats.experienceLevel 
          : gameSession.level,
      'longestSession': playerStats.totalTimePlayed.inSeconds > gameSession.currentSessionTime.inSeconds
          ? playerStats.totalTimePlayed.inSeconds
          : gameSession.currentSessionTime.inSeconds,
      'perfectClears': playerStats.perfectClears + (hadPerfectClear ? 1 : 0),
      
      // Special conditions
      'secretPatternFound': _checkForSecretPattern(gameSession),
    };
  }
  
  Map<String, dynamic> _buildGameStateForPowerUp(GameSession gameSession) {
    return {
      'hasActiveBlocks': gameSession.activeBlocks.isNotEmpty,
      'hasPlacedBlocks': gameSession.gridFillPercentage > 0,
      'hasValidMoves': _hasValidMoves(gameSession),
      'canUndo': false, // Would need undo manager state
      'isTimerRunning': !gameSession.isGameOver,
    };
  }
  
  int _calculateBlocksPlaced(GameSession gameSession) {
    // This would need to be tracked during the game
    // For now, estimate based on grid fill
    return (gameSession.gridFillPercentage / 100 * 64).round();
  }
  
  bool _hasValidMoves(GameSession gameSession) {
    for (final block in gameSession.activeBlocks) {
      for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
          if (_canPlaceBlockAt(gameSession, block, row, col)) {
            return true;
          }
        }
      }
    }
    return false;
  }
  
  bool _canPlaceBlockAt(GameSession gameSession, Block block, int row, int col) {
    final occupiedCells = block.occupiedCells;
    
    for (final cell in occupiedCells) {
      final gridR = row + cell.y.toInt();
      final gridC = col + cell.x.toInt();
      
      if (gridR < 0 || gridR >= 8 || gridC < 0 || gridC >= 8) {
        return false;
      }
      
      if (gameSession.grid[gridR][gridC]) {
        return false;
      }
    }
    
    return true;
  }
  
  bool _checkForSecretPattern(GameSession gameSession) {
    // Check for specific patterns in the grid
    // This could be any special arrangement
    return gameSession.score == 777 || // Lucky number
           gameSession.comboCount >= 10 || // High combo
           gameSession.gridFillPercentage == 0; // Perfect clear
  }
  
  Future<void> _grantAchievementRewards(Achievement achievement) async {
    // Grant coin rewards
    if (achievement.coinReward > 0) {
      await addCoins(achievement.coinReward);
    }
    
    // Grant power-up rewards
    for (final entry in achievement.powerUpRewards.entries) {
      final powerUpTypeString = entry.key;
      final quantity = entry.value;
      
      // Convert string to PowerUpType
      PowerUpType? powerUpType;
      for (final type in PowerUpType.values) {
        if (type.name == powerUpTypeString) {
          powerUpType = type;
          break;
        }
      }
      
      if (powerUpType != null) {
        await addPowerUp(powerUpType, quantity);
      }
    }
  }
}