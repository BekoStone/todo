import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';

/// Repository contract for player-related data operations.
/// Defines all player data management methods including stats, achievements, and inventory.
/// Follows Repository pattern to abstract data layer implementation details.
abstract class PlayerRepository {
  // ========================================
  // PLAYER STATS MANAGEMENT
  // ========================================
  
  /// Load player statistics from storage
  Future<PlayerStats?> loadPlayerStats();
  
  /// Save player statistics to storage
  Future<bool> savePlayerStats(PlayerStats playerStats);
  
  /// Create a new player with default stats
  Future<PlayerStats> createNewPlayer(String playerId);
  
  /// Get current player statistics (with caching)
  Future<PlayerStats?> getPlayerStats();
  
  /// Update existing player statistics
  Future<bool> updatePlayerStats(PlayerStats playerStats);
  
  /// Reset all player statistics to defaults
  Future<bool> resetPlayerStats();
  
  /// Delete player statistics by ID
  Future<bool> deletePlayerStats(String playerId);
  
  /// Delete all player statistics (for debugging/testing)
  Future<bool> deleteAllPlayerStats();
  
  /// Update player display name
  Future<bool> updatePlayerName(String playerId, String newName);
  
  /// Update player avatar URL
  Future<bool> updatePlayerAvatar(String playerId, String newAvatarUrl);

  // ========================================
  // ACHIEVEMENT MANAGEMENT
  // ========================================
  
  /// Load all achievements from storage
  Future<List<Achievement>> loadAchievements();
  
  /// Save achievements to storage
  Future<bool> saveAchievements(List<Achievement> achievements);
  
  /// Unlock a specific achievement
  Future<bool> unlockAchievement(String achievementId);
  
  /// Get all achievements (with default fallback)
  Future<List<Achievement>> getAchievements();
  
  /// Update a single achievement
  Future<void> updateAchievement(Achievement achievement);
  
  /// Check if an achievement is unlocked
  Future<Achievement?> getAchievementById(String achievementId);
  
  /// Get progress for a specific achievement
  Future<double> getAchievementProgress(String achievementId);
  
  /// Get all unlocked achievements
  Future<List<Achievement>> getUnlockedAchievements();
  
  /// Get all locked achievements
  Future<List<Achievement>> getLockedAchievements();

  // ========================================
  // POWER-UP MANAGEMENT
  // ========================================
  
  /// Load power-up inventory from storage
  Future<Map<PowerUpType, int>> loadPowerUpInventory();
  
  /// Save power-up inventory to storage
  Future<bool> savePowerUpInventory(Map<PowerUpType, int> inventory);
  
  /// Use a power-up (decrements count)
  Future<bool> usePowerUp(PowerUpType type);
  
  /// Add power-ups to inventory
  Future<bool> addPowerUp(PowerUpType type, int quantity);
  
  /// Get count of specific power-up
  Future<int> getPowerUpCount(PowerUpType type);
  
  /// Check if player has enough of a power-up
  Future<bool> hasPowerUp(PowerUpType type, {int count = 1});
  
  /// Get all power-ups with counts > 0
  Future<Map<PowerUpType, int>> getAvailablePowerUps();

  // ========================================
  // COIN MANAGEMENT
  // ========================================
  
  /// Get current coin balance
  Future<int> getCoins();
  
  /// Spend coins (decrements balance)
  Future<bool> spendCoins(int amount);
  
  /// Add coins to balance
  Future<bool> addCoins(int amount);
  
  /// Check if player has enough coins
  Future<bool> hasEnoughCoins(int amount);
  
  /// Get total coins earned throughout gameplay
  Future<int> getTotalCoinsEarned();
  
  /// Get daily coin bonus status
  Future<bool> canClaimDailyBonus();
  
  /// Claim daily coin bonus
  Future<bool> claimDailyBonus();

  // ========================================
  // SETTINGS MANAGEMENT
  // ========================================
  
  /// Get all player settings
  Future<Map<String, dynamic>> getPlayerSettings();
  
  /// Save player settings
  Future<bool> savePlayerSettings(Map<String, dynamic> settings);
  
  /// Update a specific setting
  Future<bool> updateSetting(String key, dynamic value);
  
  /// Get a specific setting value
  Future<T?> getSetting<T>(String key, {T? defaultValue});
  
  /// Reset settings to defaults
  Future<bool> resetSettings();

  // ========================================
  // GAME HISTORY & STATISTICS
  // ========================================
  
  /// Get recent game scores
  Future<List<int>> getRecentScores({int limit = 10});
  
  /// Add a new score to history
  Future<bool> addScore(int score);
  
  /// Get best score
  Future<int> getBestScore();
  
  /// Get average score
  Future<double> getAverageScore();
  
  /// Get total games played
  Future<int> getTotalGamesPlayed();
  
  /// Get total play time
  Future<Duration> getTotalPlayTime();
  
  /// Get play streak (consecutive days)
  Future<int> getPlayStreak();
  
  /// Update play streak
  Future<bool> updatePlayStreak();

  // ========================================
  // DATA MANAGEMENT
  // ========================================
  
  /// Export all player data for backup
  Future<Map<String, dynamic>> exportPlayerData();
  
  /// Import player data from backup
  Future<bool> importPlayerData(Map<String, dynamic> data);
  
  /// Clear all player data
  Future<bool> clearAllPlayerData();
  
  /// Validate player data integrity
  Future<bool> validatePlayerData();
  
  /// Migrate player data to new version
  Future<bool> migratePlayerData(int fromVersion, int toVersion);
}