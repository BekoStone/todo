
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';

abstract class PlayerRepository {
  // Player stats management
  Future<PlayerStats?> loadPlayerStats();
  Future<bool> savePlayerStats(PlayerStats playerStats);
  Future<PlayerStats> createNewPlayer(String playerId);
  Future<PlayerStats> getPlayerStats();
  Future<bool> updatePlayerStats(PlayerStats playerStats);
  Future<bool> resetPlayerStats();
  Future<bool> deletePlayerStats(String playerId);
  Future<bool> deleteAllPlayerStats();
  Future<bool> updatePlayerName(String playerId, String newName);
  Future<bool> updatePlayerAvatar(String playerId, String newAvatarUrl);
  // Achievement management
  Future<List<Achievement>> loadAchievements();
  Future<bool> saveAchievements(List<Achievement> achievements);
  Future<bool> unlockAchievement(String achievementId);
  Future<List<Achievement>> getAchievements();
  Future<void> updateAchievement(Achievement achievement);
  Future<Achievement?>achievementsUnlocked(String achievementId);

  
  // Power-up management
  Future<Map<PowerUpType, int>> loadPowerUpInventory();
  Future<bool> savePowerUpInventory(Map<PowerUpType, int> inventory);
  Future<bool> usePowerUp(PowerUpType type);
  Future<bool> addPowerUp(PowerUpType type, int quantity);
  
  // Coin management
  Future<int> getCoins();
  Future<bool> spendCoins(int amount);
  Future<bool> addCoins(int amount);
  
  
  // Settings management
  Future<Map<String, dynamic>> getPlayerSettings();
  Future<bool> savePlayerSettings(Map<String, dynamic> settings);
  Future<bool> updateSetting(String key, dynamic value);
}