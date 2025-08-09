import 'dart:async';
import 'dart:developer' as developer;
import '../../core/services/storage_service.dart';
import '../../domain/entities/player_stats_entity.dart';
import '../../domain/entities/game_session_entity.dart';
import '../../domain/entities/achievement_entity.dart';


/// LocalStorageDataSource provides data access layer for local storage operations.
/// Acts as an interface between the domain layer and the storage service.
/// Handles serialization/deserialization and error management for persistent data.
class LocalStorageDataSource {
  final StorageService _storageService;

  LocalStorageDataSource(this._storageService);

  // ========================================
  // PLAYER STATISTICS
  // ========================================

  /// Save player statistics to local storage
  Future<bool> savePlayerStats(PlayerStats playerStats) async {
    try {
      developer.log('Saving player stats: ${playerStats.playerId}', name: 'LocalStorageDataSource');
      
      final json = playerStats.toJson();
      final success = await _storageService.savePlayerStats(json);
      
      if (success) {
        developer.log('Player stats saved successfully', name: 'LocalStorageDataSource');
      } else {
        developer.log('Failed to save player stats', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e, stackTrace) {
      developer.log('Error saving player stats: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      return false;
    }
  }

  /// Load player statistics from local storage
  Future<PlayerStats?> loadPlayerStats() async {
    try {
      developer.log('Loading player stats', name: 'LocalStorageDataSource');
      
      final json = await _storageService.loadPlayerStats();
      if (json == null) {
        developer.log('No player stats found', name: 'LocalStorageDataSource');
        return null;
      }
      
      final playerStats = PlayerStats.fromJson(json);
      developer.log('Player stats loaded: ${playerStats.playerId}', name: 'LocalStorageDataSource');
      
      return playerStats;
    } catch (e, stackTrace) {
      developer.log('Error loading player stats: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      return null;
    }
  }

  /// Check if player statistics exist
  Future<bool> hasPlayerStats() async {
    try {
      final stats = await loadPlayerStats();
      return stats != null;
    } catch (e) {
      developer.log('Error checking player stats existence: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Delete player statistics
  Future<bool> deletePlayerStats() async {
    try {
      developer.log('Deleting player stats', name: 'LocalStorageDataSource');
      
      final success = await _storageService.remove(_storageService.playerStatsKeyV2);
      
      if (success) {
        developer.log('Player stats deleted successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error deleting player stats: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  // ========================================
  // GAME SESSIONS
  // ========================================

  /// Save game session to local storage
  Future<bool> saveGameSession(GameSession gameSession) async {
    try {
      developer.log('Saving game session: ${gameSession.sessionId}', name: 'LocalStorageDataSource');
      
      final json = gameSession.toJson();
      final key = 'game_session_${gameSession.sessionId}';
      final success = await _storageService.setJson(key, json);
      
      if (success) {
        developer.log('Game session saved successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e, stackTrace) {
      developer.log('Error saving game session: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      return false;
    }
  }

  /// Load game session from local storage
  Future<GameSession?> loadGameSession(String sessionId) async {
    try {
      developer.log('Loading game session: $sessionId', name: 'LocalStorageDataSource');
      
      final key = 'game_session_$sessionId';
      final json = _storageService.getJson(key);
      
      if (json == null) {
        developer.log('Game session not found: $sessionId', name: 'LocalStorageDataSource');
        return null;
      }
      
      final gameSession = GameSession.fromJson(json);
      developer.log('Game session loaded: ${gameSession.sessionId}', name: 'LocalStorageDataSource');
      
      return gameSession;
    } catch (e, stackTrace) {
      developer.log('Error loading game session: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      return null;
    }
  }

  /// Load all game sessions
  Future<List<GameSession>> loadAllGameSessions() async {
    try {
      developer.log('Loading all game sessions', name: 'LocalStorageDataSource');
      
      final allKeys = _storageService.getAllKeys();
      final sessionKeys = allKeys.where((key) => key.startsWith('game_session_')).toList();
      
      final sessions = <GameSession>[];
      
      for (final key in sessionKeys) {
        try {
          final json = _storageService.getJson(key);
          if (json != null) {
            final session = GameSession.fromJson(json);
            sessions.add(session);
          }
        } catch (e) {
          developer.log('Error parsing session from key $key: $e', name: 'LocalStorageDataSource');
          // Continue with other sessions
        }
      }
      
      developer.log('Loaded ${sessions.length} game sessions', name: 'LocalStorageDataSource');
      return sessions;
    } catch (e, stackTrace) {
      developer.log('Error loading all game sessions: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      return [];
    }
  }

  /// Delete game session
  Future<bool> deleteGameSession(String sessionId) async {
    try {
      developer.log('Deleting game session: $sessionId', name: 'LocalStorageDataSource');
      
      final key = 'game_session_$sessionId';
      final success = await _storageService.remove(key);
      
      if (success) {
        developer.log('Game session deleted successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error deleting game session: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Save current game state (for auto-save)
  Future<bool> saveCurrentGameState(Map<String, dynamic> gameState) async {
    try {
      developer.log('Saving current game state', name: 'LocalStorageDataSource');
      
      // Add timestamp for auto-save tracking
      gameState['autoSaveTimestamp'] = DateTime.now().toIso8601String();
      
      final success = await _storageService.saveGameState(gameState);
      
      if (success) {
        developer.log('Current game state saved', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error saving current game state: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Load current game state (for resume)
  Future<Map<String, dynamic>?> loadCurrentGameState() async {
    try {
      developer.log('Loading current game state', name: 'LocalStorageDataSource');
      
      final gameState = await _storageService.loadGameState();
      
      if (gameState != null) {
        developer.log('Current game state loaded', name: 'LocalStorageDataSource');
      } else {
        developer.log('No current game state found', name: 'LocalStorageDataSource');
      }
      
      return gameState;
    } catch (e) {
      developer.log('Error loading current game state: $e', name: 'LocalStorageDataSource');
      return null;
    }
  }

  // ========================================
  // ACHIEVEMENTS
  // ========================================

  /// Save achievements to local storage
  Future<bool> saveAchievements(List<Achievement> achievements) async {
    try {
      developer.log('Saving ${achievements.length} achievements', name: 'LocalStorageDataSource');
      
      final jsonList = achievements.map((achievement) => achievement.toJson()).toList();
      final success = await _storageService.saveAchievements(jsonList);
      
      if (success) {
        developer.log('Achievements saved successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e, stackTrace) {
      developer.log('Error saving achievements: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      return false;
    }
  }

  /// Load achievements from local storage
  Future<List<Achievement>> loadAchievements() async {
    try {
      developer.log('Loading achievements', name: 'LocalStorageDataSource');
      
      final jsonList = await _storageService.loadAchievements();
      
      if (jsonList == null || jsonList.isEmpty) {
        developer.log('No achievements found', name: 'LocalStorageDataSource');
        return [];
      }
      
      final achievements = jsonList.map((json) => Achievement.fromJson(json)).toList();
      developer.log('Loaded ${achievements.length} achievements', name: 'LocalStorageDataSource');
      
      return achievements;
    } catch (e, stackTrace) {
      developer.log('Error loading achievements: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      return [];
    }
  }

  /// Add a new achievement
  Future<bool> addAchievement(Achievement achievement) async {
    try {
      developer.log('Adding achievement: ${achievement.id}', name: 'LocalStorageDataSource');
      
      final existingAchievements = await loadAchievements();
      
      // Check if achievement already exists
      final exists = existingAchievements.any((a) => a.id == achievement.id);
      if (exists) {
        developer.log('Achievement already exists: ${achievement.id}', name: 'LocalStorageDataSource');
        return true; // Not an error, just already exists
      }
      
      existingAchievements.add(achievement);
      return await saveAchievements(existingAchievements);
    } catch (e) {
      developer.log('Error adding achievement: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Delete all achievements
  Future<bool> deleteAllAchievements() async {
    try {
      developer.log('Deleting all achievements', name: 'LocalStorageDataSource');
      
      final success = await _storageService.remove(_storageService.achievementsKeyV2);
      
      if (success) {
        developer.log('All achievements deleted', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error deleting achievements: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  // ========================================
  // HIGH SCORES
  // ========================================

  /// Save high scores
  Future<bool> saveHighScores(List<Map<String, dynamic>> highScores) async {
    try {
      developer.log('Saving ${highScores.length} high scores', name: 'LocalStorageDataSource');
      
      final success = await _storageService.saveHighScores(highScores);
      
      if (success) {
        developer.log('High scores saved successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error saving high scores: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Load high scores
  Future<List<Map<String, dynamic>>> loadHighScores() async {
    try {
      developer.log('Loading high scores', name: 'LocalStorageDataSource');
      
      final highScores = await _storageService.loadHighScores();
      
      if (highScores == null) {
        developer.log('No high scores found', name: 'LocalStorageDataSource');
        return [];
      }
      
      developer.log('Loaded ${highScores.length} high scores', name: 'LocalStorageDataSource');
      return highScores;
    } catch (e) {
      developer.log('Error loading high scores: $e', name: 'LocalStorageDataSource');
      return [];
    }
  }

  /// Add a new high score
  Future<bool> addHighScore(Map<String, dynamic> scoreData) async {
    try {
      developer.log('Adding high score: ${scoreData['score']}', name: 'LocalStorageDataSource');
      
      final existingScores = await loadHighScores();
      existingScores.add(scoreData);
      
      // Sort by score (descending) and keep top scores only
      existingScores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      
      // Keep only top 100 scores
      const maxScores = 100;
      if (existingScores.length > maxScores) {
        existingScores.removeRange(maxScores, existingScores.length);
      }
      
      return await saveHighScores(existingScores);
    } catch (e) {
      developer.log('Error adding high score: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  // ========================================
  // SETTINGS AND PREFERENCES
  // ========================================

  /// Save app settings
  Future<bool> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      developer.log('Saving app settings', name: 'LocalStorageDataSource');
      
      final success = await _storageService.saveAppSettings(settings);
      
      if (success) {
        developer.log('App settings saved successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error saving app settings: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Load app settings
  Future<Map<String, dynamic>?> loadAppSettings() async {
    try {
      developer.log('Loading app settings', name: 'LocalStorageDataSource');
      
      final settings = await _storageService.loadAppSettings();
      
      if (settings != null) {
        developer.log('App settings loaded', name: 'LocalStorageDataSource');
      } else {
        developer.log('No app settings found', name: 'LocalStorageDataSource');
      }
      
      return settings;
    } catch (e) {
      developer.log('Error loading app settings: $e', name: 'LocalStorageDataSource');
      return null;
    }
  }

  /// Save user preferences
  Future<bool> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      developer.log('Saving user preferences', name: 'LocalStorageDataSource');
      
      final success = await _storageService.saveUserPreferences(preferences);
      
      if (success) {
        developer.log('User preferences saved successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error saving user preferences: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Load user preferences
  Future<Map<String, dynamic>?> loadUserPreferences() async {
    try {
      developer.log('Loading user preferences', name: 'LocalStorageDataSource');
      
      final preferences = await _storageService.getUserPreferences();
      
      if (preferences != null) {
        developer.log('User preferences loaded', name: 'LocalStorageDataSource');
      } else {
        developer.log('No user preferences found', name: 'LocalStorageDataSource');
      }
      
      return preferences;
    } catch (e) {
      developer.log('Error loading user preferences: $e', name: 'LocalStorageDataSource');
      return null;
    }
  }

  /// Save tutorial progress
  Future<bool> saveTutorialProgress(Map<String, dynamic> progress) async {
    try {
      developer.log('Saving tutorial progress', name: 'LocalStorageDataSource');
      
      final success = await _storageService.saveTutorialProgress(progress);
      
      if (success) {
        developer.log('Tutorial progress saved successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error saving tutorial progress: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Load tutorial progress
  Future<Map<String, dynamic>?> loadTutorialProgress() async {
    try {
      developer.log('Loading tutorial progress', name: 'LocalStorageDataSource');
      
      final progress = await _storageService.loadTutorialProgress();
      
      if (progress != null) {
        developer.log('Tutorial progress loaded', name: 'LocalStorageDataSource');
      } else {
        developer.log('No tutorial progress found', name: 'LocalStorageDataSource');
      }
      
      return progress;
    } catch (e) {
      developer.log('Error loading tutorial progress: $e', name: 'LocalStorageDataSource');
      return null;
    }
  }

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  /// Clear all game data
  Future<bool> clearAllGameData() async {
    try {
      developer.log('Clearing all game data', name: 'LocalStorageDataSource');
      
      final success = await _storageService.clearAll();
      
      if (success) {
        developer.log('All game data cleared successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e) {
      developer.log('Error clearing all game data: $e', name: 'LocalStorageDataSource');
      return false;
    }
  }

  /// Export all data for backup
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      developer.log('Exporting all data for backup', name: 'LocalStorageDataSource');
      
      final exportData = await _storageService.exportAllData();
      
      developer.log('Data export completed with ${exportData.length} entries', name: 'LocalStorageDataSource');
      return exportData;
    } catch (e, stackTrace) {
      developer.log('Error exporting data: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Import data from backup
  Future<bool> importAllData(Map<String, dynamic> backupData) async {
    try {
      developer.log('Importing data from backup', name: 'LocalStorageDataSource');
      
      final success = await _storageService.importAllData(backupData);
      
      if (success) {
        developer.log('Data import completed successfully', name: 'LocalStorageDataSource');
      }
      
      return success;
    } catch (e, stackTrace) {
      developer.log('Error importing data: $e', name: 'LocalStorageDataSource', stackTrace: stackTrace);
      return false;
    }
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStatistics() {
    try {
      final stats = _storageService.getStorageStats();
      developer.log('Retrieved storage statistics', name: 'LocalStorageDataSource');
      return stats;
    } catch (e) {
      developer.log('Error getting storage statistics: $e', name: 'LocalStorageDataSource');
      return {};
    }
  }

  /// Perform storage cleanup
  Future<void> performCleanup() async {
    try {
      developer.log('Performing storage cleanup', name: 'LocalStorageDataSource');
      
      await _storageService.cleanupExpiredData();
      
      developer.log('Storage cleanup completed', name: 'LocalStorageDataSource');
    } catch (e) {
      developer.log('Error during storage cleanup: $e', name: 'LocalStorageDataSource');
    }
  }
}