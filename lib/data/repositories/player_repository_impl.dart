import 'package:flutter/foundation.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/local_storage_datasource.dart';
import '../models/player_stats_model.dart';
import '../models/achievement_model.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final LocalStorageDataSource _dataSource;
  
  PlayerRepositoryImpl(this._dataSource);
  
  @override
  Future<PlayerStats?> loadPlayerStats() async {
    try {
      final playerStatsModel = _dataSource.loadPlayerStats();
      if (playerStatsModel == null) return null;
      
      return _mapPlayerStatsModelToEntity(playerStatsModel);
    } catch (e) {
      debugPrint('❌ Failed to load player stats: $e');
      return null;
    }
  }
  
  @override
  Future<bool> savePlayerStats(PlayerStats playerStats) async {
    try {
      final playerStatsModel = _mapPlayerStatsEntityToModel(playerStats);
      return await _dataSource.savePlayerStats(playerStatsModel);
    } catch (e) {
      debugPrint('❌ Failed to save player stats: $e');
      return false;
    }
  }
  
  @override
  Future<PlayerStats> createNewPlayer(String playerId) async {
    final playerStatsModel = PlayerStatsModel.newPlayer(playerId);
    await _dataSource.savePlayerStats(playerStatsModel);
    return _mapPlayerStatsModelToEntity(playerStatsModel);
  }
  
  @override
  Future<List<Achievement>> loadAchievements() async {
    try {
      final achievementModels = _dataSource.loadAchievements();
      return achievementModels.map(_mapAchievementModelToEntity).toList();
    } catch (e) {
      debugPrint('❌ Failed to load achievements: $e');
      return AchievementDefinitions.allAchievements;
    }
  }
  
  @override
  Future<bool> saveAchievements(List<Achievement> achievements) async {
    try {
      final achievementModels = achievements.map(_mapAchievementEntityToModel).toList();
      return await _dataSource.saveAchievements(achievementModels);
    } catch (e) {
      debugPrint('❌ Failed to save achievements: $e');
      return false;
    }
  }
  
  @override
  Future<bool> unlockAchievement(String achievementId) async {
    try {
      final achievements = await loadAchievements();
      final updatedAchievements = achievements.map((achievement) {
        if (achievement.id == achievementId && !achievement.isUnlocked) {
          return achievement.unlock();
        }
        return achievement;
      }).toList();
      
      return await saveAchievements(updatedAchievements);
    } catch (e) {
      debugPrint('❌ Failed to unlock achievement: $e');
      return false;
    }
  }
  
  @override
  Future<Map<PowerUpType, int>> loadPowerUpInventory() async {
    try {
      final playerStats = await loadPlayerStats();
      if (playerStats == null) return {};
      
      // Convert string keys to PowerUpType
      final inventory = <PowerUpType, int>{};
      for (final entry in playerStats.powerUpInventory.entries) {
        final powerUpType = _stringToPowerUpType(entry.key);
        if (powerUpType != null) {
          inventory[powerUpType] = entry.value;
        }
      }
      
      return inventory;
    } catch (e) {
      debugPrint('❌ Failed to load power-up inventory: $e');
      return {};
    }
  }
  
  @override
  Future<bool> savePowerUpInventory(Map<PowerUpType, int> inventory) async {
    try {
      final playerStats = await loadPlayerStats();
      if (playerStats == null) return false;
      
      // Convert PowerUpType keys to strings
      final stringInventory = <String, int>{};
      for (final entry in inventory.entries) {
        stringInventory[entry.key.name] = entry.value;
      }
      
      final updatedStats = playerStats.copyWith(powerUpInventory: stringInventory);
      return await savePlayerStats(updatedStats);
    } catch (e) {
      debugPrint('❌ Failed to save power-up inventory: $e');
      return false;
    }
  }
  
  @override
  Future<bool> usePowerUp(PowerUpType type) async {
    try {
      final playerStats = await loadPlayerStats();
      if (playerStats == null) return false;
      
      final updatedStats = playerStats.usePowerUp(type.name);
      return await savePlayerStats(updatedStats);
    } catch (e) {
      debugPrint('❌ Failed to use power-up: $e');
      return false;
    }
  }
  
  @override
  Future<bool> addPowerUp(PowerUpType type, int quantity) async {
    try {
      final playerStats = await loadPlayerStats();
      if (playerStats == null) return false;
      
      final updatedStats = playerStats.addPowerUp(type.name, quantity);
      return await savePlayerStats(updatedStats);
    } catch (e) {
      debugPrint('❌ Failed to add power-up: $e');
      return false;
    }
  }
  
  @override
  Future<int> getCoins() async {
    try {
      final playerStats = await loadPlayerStats();
      return playerStats?.currentCoins ?? 0;
    } catch (e) {
      debugPrint('❌ Failed to get coins: $e');
      return 0;
    }
  }
  
  @override
  Future<bool> spendCoins(int amount) async {
    try {
      final playerStats = await loadPlayerStats();
      if (playerStats == null) return false;
      
      final updatedStats = playerStats.spendCoins(amount);
      return await savePlayerStats(updatedStats);
    } catch (e) {
      debugPrint('❌ Failed to spend coins: $e');
      return false;
    }
  }
  
  @override
  Future<bool> addCoins(int amount) async {
    try {
      final playerStats = await loadPlayerStats();
      if (playerStats == null) return false;
      
      final updatedStats = playerStats.addCoins(amount);
      return await savePlayerStats(updatedStats);
    } catch (e) {
      debugPrint('❌ Failed to add coins: $e');
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>> getPlayerSettings() async {
    try {
      final playerStats = await loadPlayerStats();
      return playerStats?.settings ?? {};
    } catch (e) {
      debugPrint('❌ Failed to get player settings: $e');
      return {};
    }
  }
  
  @override
  Future<bool> savePlayerSettings(Map<String, dynamic> settings) async {
    try {
      final playerStats = await loadPlayerStats();
      if (playerStats == null) return false;
      
      final updatedStats = playerStats.copyWith(settings: settings);
      return await savePlayerStats(updatedStats);
    } catch (e) {
      debugPrint('❌ Failed to save player settings: $e');
      return false;
    }
  }
  
  @override
  Future<bool> updateSetting(String key, dynamic value) async {
    try {
      final playerStats = await loadPlayerStats();
      if (playerStats == null) return false;
      
      final updatedStats = playerStats.updateSetting(key, value);
      return await savePlayerStats(updatedStats);
    } catch (e) {
      debugPrint('❌ Failed to update setting: $e');
      return false;
    }
  }
  
  // Helper methods for mapping between entities and models
  PlayerStats _mapPlayerStatsModelToEntity(PlayerStatsModel model) {
    return PlayerStats(
      playerId: model.playerId,
      totalScore: model.totalScore,
      bestScore: model.bestScore,
      totalGamesPlayed: model.totalGamesPlayed,
      totalTimePlayed: Duration(seconds: model.totalTimePlayed),
      totalBlocksPlaced: model.totalBlocksPlaced,
      totalLinesCleared: model.totalLinesCleared,
      currentCoins: model.currentCoins,
      totalCoinsEarned: model.totalCoinsEarned,
      bestCombo: model.bestCombo,
      bestStreak: model.bestStreak,
      perfectClears: model.perfectClears,
      powerUpInventory: model.powerUpInventory,
      unlockedAchievements: model.achievements.keys.where((k) => model.achievements[k] == true).toSet(),
      recentScores: model.recentScores,
      firstPlayDate: model.firstPlayDate,
      lastPlayDate: model.lastPlayDate,
      settings: model.settings,
    );
  }
  
  PlayerStatsModel _mapPlayerStatsEntityToModel(PlayerStats entity) {
    final achievements = <String, bool>{};
    for (final achievementId in entity.unlockedAchievements) {
      achievements[achievementId] = true;
    }
    
    return PlayerStatsModel(
      playerId: entity.playerId,
      totalScore: entity.totalScore,
      bestScore: entity.bestScore,
      totalGamesPlayed: entity.totalGamesPlayed,
      totalTimePlayed: entity.totalTimePlayed.inSeconds,
      totalBlocksPlaced: entity.totalBlocksPlaced,
      totalLinesCleared: entity.totalLinesCleared,
      currentCoins: entity.currentCoins,
      totalCoinsEarned: entity.totalCoinsEarned,
      bestCombo: entity.bestCombo,
      bestStreak: entity.bestStreak,
      perfectClears: entity.perfectClears,
      powerUpInventory: entity.powerUpInventory,
      achievements: achievements,
      recentScores: entity.recentScores,
      firstPlayDate: entity.firstPlayDate,
      lastPlayDate: entity.lastPlayDate,
      settings: entity.settings,
    );
  }
  
  Achievement _mapAchievementModelToEntity(AchievementModel model) {
    return Achievement(
      id: model.id,
      name: model.name,
      description: model.description,
      icon: model.icon,
      category: AchievementCategory.values[model.category.index],
      rarity: AchievementRarity.values[model.rarity.index],
      targetValue: model.targetValue,
      coinReward: model.coinReward,
      powerUpRewards: model.powerUpRewards,
      isSecret: model.isSecret,
      isUnlocked: model.isUnlocked,
      currentProgress: model.currentProgress,
      unlockedAt: model.unlockedAt,
    );
  }
  
  AchievementModel _mapAchievementEntityToModel(Achievement entity) {
    return AchievementModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      icon: entity.icon,
      category: AchievementCategory.values[entity.category.index],
      rarity: AchievementRarity.values[entity.rarity.index],
      targetValue: entity.targetValue,
      coinReward: entity.coinReward,
      powerUpRewards: entity.powerUpRewards,
      isSecret: entity.isSecret,
      isUnlocked: entity.isUnlocked,
      currentProgress: entity.currentProgress,
      unlockedAt: entity.unlockedAt,
    );
  }
  
  PowerUpType? _stringToPowerUpType(String typeString) {
    for (final type in PowerUpType.values) {
      if (type.name == typeString) {
        return type;
      }
    }
    return null;
  }
}