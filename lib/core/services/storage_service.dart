import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// StorageService provides persistent data storage for the Box Hooks application.
/// Handles all local data persistence including player stats, game state, settings, and achievements.
/// Uses SharedPreferences with JSON serialization for complex data structures.
class StorageService {
  final SharedPreferences _prefs;
  
  // Cache for frequently accessed data
  final Map<String, dynamic> _cache = {};
  
  // Flag to track initialization
  bool _isInitialized = false;

  StorageService(this._prefs);

  /// Initialize the storage service
  Future<void> initialize() async {
    try {
      developer.log('Initializing StorageService', name: 'StorageService');
      
      // Perform any necessary migrations
      await _performMigrations();
      
      // Preload critical data into cache
      await _preloadCache();
      
      _isInitialized = true;
      developer.log('StorageService initialized successfully', name: 'StorageService');
      
    } catch (e, stackTrace) {
      developer.log('Failed to initialize StorageService: $e', name: 'StorageService', stackTrace: stackTrace);
      rethrow;
    }
  }

  // ========================================
  // GENERIC STORAGE METHODS
  // ========================================

  /// Store a string value
  Future<bool> setString(String key, String value) async {
    try {
      final success = await _prefs.setString(key, value);
      if (success) {
        _cache[key] = value;
        developer.log('Stored string: $key', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to store string $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Retrieve a string value
  String? getString(String key, {String? defaultValue}) {
    try {
      // Check cache first
      if (_cache.containsKey(key)) {
        return _cache[key] as String?;
      }
      
      final value = _prefs.getString(key) ?? defaultValue;
      if (value != null) {
        _cache[key] = value;
      }
      return value;
    } catch (e) {
      developer.log('Failed to retrieve string $key: $e', name: 'StorageService');
      return defaultValue;
    }
  }

  /// Store an integer value
  Future<bool> setInt(String key, int value) async {
    try {
      final success = await _prefs.setInt(key, value);
      if (success) {
        _cache[key] = value;
        developer.log('Stored int: $key = $value', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to store int $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Retrieve an integer value
  int? getInt(String key, {int? defaultValue}) {
    try {
      // Check cache first
      if (_cache.containsKey(key)) {
        return _cache[key] as int?;
      }
      
      final value = _prefs.getInt(key) ?? defaultValue;
      if (value != null) {
        _cache[key] = value;
      }
      return value;
    } catch (e) {
      developer.log('Failed to retrieve int $key: $e', name: 'StorageService');
      return defaultValue;
    }
  }

  /// Store a boolean value
  Future<bool> setBool(String key, bool value) async {
    try {
      final success = await _prefs.setBool(key, value);
      if (success) {
        _cache[key] = value;
        developer.log('Stored bool: $key = $value', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to store bool $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Retrieve a boolean value
  bool? getBool(String key, {bool? defaultValue}) {
    try {
      // Check cache first
      if (_cache.containsKey(key)) {
        return _cache[key] as bool?;
      }
      
      final value = _prefs.getBool(key) ?? defaultValue;
      if (value != null) {
        _cache[key] = value;
      }
      return value;
    } catch (e) {
      developer.log('Failed to retrieve bool $key: $e', name: 'StorageService');
      return defaultValue;
    }
  }

  /// Store a double value
  Future<bool> setDouble(String key, double value) async {
    try {
      final success = await _prefs.setDouble(key, value);
      if (success) {
        _cache[key] = value;
        developer.log('Stored double: $key = $value', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to store double $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Retrieve a double value
  double? getDouble(String key, {double? defaultValue}) {
    try {
      // Check cache first
      if (_cache.containsKey(key)) {
        return _cache[key] as double?;
      }
      
      final value = _prefs.getDouble(key) ?? defaultValue;
      if (value != null) {
        _cache[key] = value;
      }
      return value;
    } catch (e) {
      developer.log('Failed to retrieve double $key: $e', name: 'StorageService');
      return defaultValue;
    }
  }

  /// Store a list of strings
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      final success = await _prefs.setStringList(key, value);
      if (success) {
        _cache[key] = value;
        developer.log('Stored string list: $key (${value.length} items)', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to store string list $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Retrieve a list of strings
  List<String>? getStringList(String key, {List<String>? defaultValue}) {
    try {
      // Check cache first
      if (_cache.containsKey(key)) {
        return _cache[key] as List<String>?;
      }
      
      final value = _prefs.getStringList(key) ?? defaultValue;
      if (value != null) {
        _cache[key] = value;
      }
      return value;
    } catch (e) {
      developer.log('Failed to retrieve string list $key: $e', name: 'StorageService');
      return defaultValue;
    }
  }

  // ========================================
  // JSON STORAGE METHODS
  // ========================================

  /// Store a JSON-serializable object
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      final success = await setString(key, jsonString);
      if (success) {
        developer.log('Stored JSON: $key', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to store JSON $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Retrieve a JSON object
  Map<String, dynamic>? getJson(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      developer.log('Retrieved JSON: $key', name: 'StorageService');
      return decoded;
    } catch (e) {
      developer.log('Failed to retrieve JSON $key: $e', name: 'StorageService');
      return null;
    }
  }

  /// Store a list of JSON objects
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    try {
      final jsonString = jsonEncode(value);
      final success = await setString(key, jsonString);
      if (success) {
        developer.log('Stored JSON list: $key (${value.length} items)', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to store JSON list $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Retrieve a list of JSON objects
  List<Map<String, dynamic>>? getJsonList(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      
      final decoded = jsonDecode(jsonString) as List;
      final result = decoded.cast<Map<String, dynamic>>();
      developer.log('Retrieved JSON list: $key (${result.length} items)', name: 'StorageService');
      return result;
    } catch (e) {
      developer.log('Failed to retrieve JSON list $key: $e', name: 'StorageService');
      return null;
    }
  }

  // ========================================
  // GAME-SPECIFIC STORAGE METHODS
  // ========================================

  /// Save player statistics
  Future<bool> savePlayerStats(Map<String, dynamic> playerStats) async {
    return await setJson(AppConstants.playerStatsKeyV2, playerStats);
  }

  /// Load player statistics
  Future<Map<String, dynamic>?> loadPlayerStats() async {
    return getJson(AppConstants.playerStatsKeyV2);
  }

  /// Save achievements data
  Future<bool> saveAchievements(List<Map<String, dynamic>> achievements) async {
    return await setJsonList(AppConstants.achievementsKeyV2, achievements);
  }

  /// Load achievements data
  Future<List<Map<String, dynamic>>?> loadAchievements() async {
    return getJsonList(AppConstants.achievementsKeyV2);
  }

  /// Save game state
  Future<bool> saveGameState(Map<String, dynamic> gameState) async {
    return await setJson(AppConstants.gameStateKeyV2, gameState);
  }

  /// Load game state
  Future<Map<String, dynamic>?> loadGameState() async {
    return getJson(AppConstants.gameStateKeyV2);
  }

  /// Save app settings
  Future<bool> saveAppSettings(Map<String, dynamic> settings) async {
    return await setJson(AppConstants.settingsKeyV2, settings);
  }

  /// Load app settings
  Future<Map<String, dynamic>?> loadAppSettings() async {
    return getJson(AppConstants.settingsKeyV2);
  }

  /// Save user preferences
  Future<bool> saveUserPreferences(Map<String, dynamic> preferences) async {
    return await setJson(AppConstants.preferencesKeyV2, preferences);
  }

  /// Load user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    return getJson(AppConstants.preferencesKeyV2);
  }

  /// Save high scores
  Future<bool> saveHighScores(List<Map<String, dynamic>> highScores) async {
    return await setJsonList(AppConstants.highScoresKeyV2, highScores);
  }

  /// Load high scores
  Future<List<Map<String, dynamic>>?> loadHighScores() async {
    return getJsonList(AppConstants.highScoresKeyV2);
  }

  /// Save tutorial progress
  Future<bool> saveTutorialProgress(Map<String, dynamic> progress) async {
    return await setJson(AppConstants.tutorialKeyV2, progress);
  }

  /// Load tutorial progress
  Future<Map<String, dynamic>?> loadTutorialProgress() async {
    return getJson(AppConstants.tutorialKeyV2);
  }

  // ========================================
  // CACHE MANAGEMENT
  // ========================================

  /// Clear specific key from cache
  void clearCacheKey(String key) {
    _cache.remove(key);
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    developer.log('Cache cleared', name: 'StorageService');
  }

  /// Get cache size
  int get cacheSize => _cache.length;

  /// Preload frequently accessed data into cache
  Future<void> _preloadCache() async {
    try {
      // Preload user preferences
      final preferences = getJson(AppConstants.preferencesKeyV2);
      if (preferences != null) {
        _cache[AppConstants.preferencesKeyV2] = preferences;
      }
      
      // Preload app settings
      final settings = getJson(AppConstants.settingsKeyV2);
      if (settings != null) {
        _cache[AppConstants.settingsKeyV2] = settings;
      }
      
      developer.log('Cache preloaded with ${_cache.length} items', name: 'StorageService');
    } catch (e) {
      developer.log('Failed to preload cache: $e', name: 'StorageService');
    }
  }

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  /// Check if a key exists
  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }

  /// Remove a specific key
  Future<bool> remove(String key) async {
    try {
      final success = await _prefs.remove(key);
      if (success) {
        _cache.remove(key);
        developer.log('Removed key: $key', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to remove key $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Clear all stored data
  Future<bool> clearAll() async {
    try {
      final success = await _prefs.clear();
      if (success) {
        _cache.clear();
        developer.log('All data cleared', name: 'StorageService');
      }
      return success;
    } catch (e) {
      developer.log('Failed to clear all data: $e', name: 'StorageService');
      return false;
    }
  }

  /// Get all keys
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }

  /// Get storage size estimate (number of keys)
  int getStorageSize() {
    return _prefs.getKeys().length;
  }

  // ========================================
  // DATA MIGRATION
  // ========================================

  /// Perform data migrations between app versions
  Future<void> _performMigrations() async {
    try {
      final currentVersion = getString('storage_version', defaultValue: '1.0.0');
      
      if (currentVersion == '1.0.0') {
        await _migrateFromV1ToV2();
        await setString('storage_version', '2.0.0');
        developer.log('Migrated storage from v1.0.0 to v2.0.0', name: 'StorageService');
      }
      
    } catch (e) {
      developer.log('Migration failed: $e', name: 'StorageService');
    }
  }

  /// Migrate from version 1 to version 2 storage format
  Future<void> _migrateFromV1ToV2() async {
    try {
      // Migrate old keys to new prefixed keys
      final oldKeys = {
        'player_stats': AppConstants.playerStatsKeyV2,
        'achievements': AppConstants.achievementsKeyV2,
        'app_settings': AppConstants.settingsKeyV2,
        'game_state': AppConstants.gameStateKeyV2,
        'high_scores': AppConstants.highScoresKeyV2,
        'tutorial_progress': AppConstants.tutorialKeyV2,
        'user_preferences': AppConstants.preferencesKeyV2,
      };
      
      for (final entry in oldKeys.entries) {
        final oldKey = entry.key;
        final newKey = entry.value;
        
        if (hasKey(oldKey) && !hasKey(newKey)) {
          final value = getString(oldKey);
          if (value != null) {
            await setString(newKey, value);
            await remove(oldKey);
            developer.log('Migrated $oldKey -> $newKey', name: 'StorageService');
          }
        }
      }
      
    } catch (e) {
      developer.log('V1 to V2 migration failed: $e', name: 'StorageService');
    }
  }

  // ========================================
  // BACKUP AND RESTORE
  // ========================================

  /// Export all data for backup
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final allKeys = getAllKeys();
      final exportData = <String, dynamic>{};
      
      for (final key in allKeys) {
        // Only export game-related data, not system preferences
        if (key.startsWith(AppConstants.keyPrefix)) {
          final value = getString(key);
          if (value != null) {
            exportData[key] = value;
          }
        }
      }
      
      exportData['export_timestamp'] = DateTime.now().toIso8601String();
      exportData['app_version'] = AppConstants.appVersion;
      
      developer.log('Exported ${exportData.length} keys for backup', name: 'StorageService');
      return exportData;
      
    } catch (e) {
      developer.log('Failed to export data: $e', name: 'StorageService');
      rethrow;
    }
  }

  /// Import data from backup
  Future<bool> importAllData(Map<String, dynamic> backupData) async {
    try {
      int importedCount = 0;
      
      for (final entry in backupData.entries) {
        if (entry.key.startsWith(AppConstants.keyPrefix) && entry.value is String) {
          await setString(entry.key, entry.value as String);
          importedCount++;
        }
      }
      
      developer.log('Imported $importedCount keys from backup', name: 'StorageService');
      return true;
      
    } catch (e) {
      developer.log('Failed to import data: $e', name: 'StorageService');
      return false;
    }
  }

  // ========================================
  // CLEANUP AND MAINTENANCE
  // ========================================

  /// Clean up expired data
  Future<void> cleanupExpiredData() async {
    try {
      final now = DateTime.now();
      int cleanedCount = 0;
      
      // Clean up old game sessions (older than 90 days)
      final allKeys = getAllKeys();
      for (final key in allKeys) {
        if (key.startsWith('${AppConstants.keyPrefix}temp_') || 
            key.startsWith('${AppConstants.keyPrefix}session_')) {
          
          final data = getJson(key);
          if (data != null && data['createdAt'] != null) {
            try {
              final createdAt = DateTime.parse(data['createdAt'] as String);
              if (now.difference(createdAt).inDays > 90) {
                await remove(key);
                cleanedCount++;
              }
            } catch (e) {
              // Invalid date format, remove the key
              await remove(key);
              cleanedCount++;
            }
          }
        }
      }
      
      if (cleanedCount > 0) {
        developer.log('Cleaned up $cleanedCount expired entries', name: 'StorageService');
      }
      
    } catch (e) {
      developer.log('Cleanup failed: $e', name: 'StorageService');
    }
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    final allKeys = getAllKeys();
    final gameDataKeys = allKeys.where((k) => k.startsWith(AppConstants.keyPrefix)).length;
    
    return {
      'totalKeys': allKeys.length,
      'gameDataKeys': gameDataKeys,
      'cacheSize': _cache.length,
      'isInitialized': _isInitialized,
      'storageVersion': getString('storage_version', defaultValue: '1.0.0'),
    };
  }

  // ========================================
  // CLEANUP
  // ========================================

  /// Dispose of the storage service
  Future<void> dispose() async {
    try {
      developer.log('Disposing StorageService', name: 'StorageService');
      
      // Clear cache
      _cache.clear();
      
      // Perform final cleanup
      await cleanupExpiredData();
      
      _isInitialized = false;
      developer.log('StorageService disposed', name: 'StorageService');
      
    } catch (e) {
      developer.log('Error disposing StorageService: $e', name: 'StorageService');
    }
  }
}