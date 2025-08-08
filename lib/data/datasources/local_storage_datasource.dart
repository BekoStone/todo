import 'package:flutter/foundation.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/game_state_model.dart';
import '../models/player_stats_model.dart';
import '../models/achievement_model.dart';

class LocalStorageDataSource {
  final StorageService _storage;
  
  LocalStorageDataSource(this._storage);
  
  // Game State Operations
  Future<bool> saveGameState(GameStateModel gameState) async {
    try {
      final success = await _storage.setJson(
        AppConstants.gameDataKey,
        gameState.toJson(),
      );
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Game state saved: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save game state: $e');
      return false;
    }
  }
  
  GameStateModel? loadGameState() {
    try {
      final json = _storage.getJson(AppConstants.gameDataKey);
      
      if (json == null) {
        if (AppConstants.enableDebugLogging) {
          debugPrint('📂 No saved game state found');
        }
        return null;
      }
      
      final gameState = GameStateModel.fromJson(json);
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('📂 Game state loaded: Score ${gameState.score}');
      }
      
      return gameState;
    } catch (e) {
      debugPrint('❌ Failed to load game state: $e');
      return null;
    }
  }
  
  Future<bool> clearGameState() async {
    try {
      final success = await _storage.remove(AppConstants.gameDataKey);
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('🗑️ Game state cleared: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to clear game state: $e');
      return false;
    }
  }
  
  // Player Stats Operations
  Future<bool> savePlayerStats(PlayerStatsModel playerStats) async {
    try {
      final success = await _storage.setJson(
        AppConstants.playerStatsKey,
        playerStats.toJson(),
      );
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Player stats saved: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save player stats: $e');
      return false;
    }
  }
  
  PlayerStatsModel? loadPlayerStats() {
    try {
      final json = _storage.getJson(AppConstants.playerStatsKey);
      
      if (json == null) {
        if (AppConstants.enableDebugLogging) {
          debugPrint('📂 No saved player stats found, creating new player');
        }
        return _createNewPlayer();
      }
      
      final playerStats = PlayerStatsModel.fromJson(json);
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('📂 Player stats loaded: ${playerStats.playerId}');
      }
      
      return playerStats;
    } catch (e) {
      debugPrint('❌ Failed to load player stats: $e');
      return _createNewPlayer();
    }
  }
  
  PlayerStatsModel _createNewPlayer() {
    final playerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
    return PlayerStatsModel.newPlayer(playerId);
  }
  
  // Achievements Operations
  Future<bool> saveAchievements(List<AchievementModel> achievements) async {
    try {
      final achievementsJson = achievements.map((a) => a.toJson()).toList();
      final success = await _storage.setJson(
        AppConstants.achievementsKey,
        {'achievements': achievementsJson},
      );
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Achievements saved: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save achievements: $e');
      return false;
    }
  }
  
  List<AchievementModel> loadAchievements() {
    try {
      final json = _storage.getJson(AppConstants.achievementsKey);
      
      if (json == null || json['achievements'] == null) {
        if (AppConstants.enableDebugLogging) {
          debugPrint('📂 No saved achievements found, using defaults');
        }
        return AchievementDefinitions.allAchievements;
      }
      
      final achievementsJson = json['achievements'] as List;
      final achievements = achievementsJson
          .map((a) => AchievementModel.fromJson(a as Map<String, dynamic>))
          .toList();
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('📂 Achievements loaded: ${achievements.length} achievements');
      }
      
      return achievements;
    } catch (e) {
      debugPrint('❌ Failed to load achievements: $e');
      return AchievementDefinitions.allAchievements;
    }
  }
  
  // Settings Operations
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    try {
      final success = await _storage.setJson(AppConstants.settingsKey, settings);
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Settings saved: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save settings: $e');
      return false;
    }
  }
  
  Map<String, dynamic> loadSettings() {
    try {
      final settings = _storage.getJson(AppConstants.settingsKey);
      
      if (settings == null) {
        if (AppConstants.enableDebugLogging) {
          debugPrint('📂 No saved settings found, using defaults');
        }
        return _getDefaultSettings();
      }
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('📂 Settings loaded');
      }
      
      return settings;
    } catch (e) {
      debugPrint('❌ Failed to load settings: $e');
      return _getDefaultSettings();
    }
  }
  
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'musicEnabled': true,
      'sfxEnabled': true,
      'musicVolume': AppConstants.defaultMusicVolume,
      'sfxVolume': AppConstants.defaultSfxVolume,
      'showHints': true,
      'autoSave': true,
      'highPerformanceMode': false,
      'reduceAnimations': false,
      'theme': 'dark',
    };
  }
  
  // Daily Reward Operations
  Future<bool> saveLastClaimDate(DateTime date) async {
    try {
      final success = await _storage.setString(
        'last_daily_claim',
        date.toIso8601String(),
      );
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Last claim date saved: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save last claim date: $e');
      return false;
    }
  }
  
  DateTime? loadLastClaimDate() {
    try {
      final dateString = _storage.getString('last_daily_claim');
      
      if (dateString == null) return null;
      
      return DateTime.tryParse(dateString);
    } catch (e) {
      debugPrint('❌ Failed to load last claim date: $e');
      return null;
    }
  }
  
  bool canClaimDailyReward() {
    final lastClaim = loadLastClaimDate();
    if (lastClaim == null) return true;
    
    final now = DateTime.now();
    final daysSinceLastClaim = now.difference(lastClaim).inDays;
    
    return daysSinceLastClaim >= 1;
  }
  
  // High Scores Operations
  Future<bool> saveHighScores(List<int> scores) async {
    try {
      final scoresString = scores.map((s) => s.toString()).toList();
      final success = await _storage.setStringList('high_scores', scoresString);
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 High scores saved: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save high scores: $e');
      return false;
    }
  }
  
  List<int> loadHighScores() {
    try {
      final scoresString = _storage.getStringList('high_scores');
      
      if (scoresString.isEmpty) return [];
      
      final scores = scoresString
          .map((s) => int.tryParse(s) ?? 0)
          .where((s) => s > 0)
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Descending order
      
      return scores.take(10).toList(); // Top 10
    } catch (e) {
      debugPrint('❌ Failed to load high scores: $e');
      return [];
    }
  }
  
  Future<bool> addHighScore(int score) async {
    final currentScores = loadHighScores();
    currentScores.add(score);
    currentScores.sort((a, b) => b.compareTo(a));
    
    // Keep only top 10
    final topScores = currentScores.take(10).toList();
    
    return saveHighScores(topScores);
  }
  
  // Utility Operations
  Future<bool> exportAllData() async {
    try {
      final allData = _storage.exportAllData();
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('📤 Data export: ${allData.length} keys');
      }
      
      // In a real app, you might save this to a file or cloud
      return true;
    } catch (e) {
      debugPrint('❌ Failed to export data: $e');
      return false;
    }
  }
  
  Future<bool> importAllData(Map<String, dynamic> data) async {
    try {
      final success = await _storage.importData(data);
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('📥 Data import: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to import data: $e');
      return false;
    }
  }
  
  Future<bool> clearAllData() async {
    try {
      final success = await _storage.clear();
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('🗑️ All data cleared: ${success ? "success" : "failed"}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to clear all data: $e');
      return false;
    }
  }
  
  // Storage Statistics
  Map<String, dynamic> getStorageStats() {
    try {
      final stats = _storage.getStorageStats();
      
      if (AppConstants.enableDebugLogging) {
        debugPrint('📊 Storage stats: ${stats['totalKeys']} keys, ${stats['approximateSize']} bytes');
      }
      
      return stats;
    } catch (e) {
      debugPrint('❌ Failed to get storage stats: $e');
      return {
        'totalKeys': 0,
        'approximateSize': 0,
        'keysByType': {},
      };
    }
  }
}