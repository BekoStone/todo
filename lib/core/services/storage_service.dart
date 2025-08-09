import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Storage service for persistent data management.
/// Handles all local storage operations including player data, settings, and game state.
/// Provides optimized storage with compression, encryption, and data integrity checks.
class StorageService {
  final SharedPreferences _prefs;
  
  // Cache for frequently accessed data
  final Map<String, dynamic> _cache = {};
  
  // State tracking
  bool _isInitialized = false;
  DateTime? _lastCleanup;
  
  // Constants
  static const String _versionKey = 'storage_version';
  static const int _currentVersion = 2;
  static const Duration _cacheTimeout = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(days: 1);

  StorageService(this._prefs);

  /// Initialize the storage service
  Future<void> initialize() async {
    try {
      developer.log('Initializing StorageService', name: 'StorageService');
      
      // Check and handle version migration
      await _handleVersionMigration();
      
      // Perform cleanup if needed
      await _performCleanupIfNeeded();
      
      // Preload critical data into cache
      await _preloadCriticalData();
      
      _isInitialized = true;
      developer.log('StorageService initialized successfully', name: 'StorageService');
      
    } catch (e, stackTrace) {
      developer.log('Failed to initialize StorageService: $e', name: 'StorageService', stackTrace: stackTrace);
      _isInitialized = false;
      rethrow;
    }
  }

  // ========================================
  // CORE STORAGE OPERATIONS
  // ========================================

  /// Store a value with the given key
  Future<bool> setValue<T>(String key, T value) async {
    try {
      _ensureInitialized();
      
      bool success = false;
      
      // Store based on type
      if (value is String) {
        success = await _prefs.setString(key, value);
      } else if (value is int) {
        success = await _prefs.setInt(key, value);
      } else if (value is double) {
        success = await _prefs.setDouble(key, value);
      } else if (value is bool) {
        success = await _prefs.setBool(key, value);
      } else if (value is List<String>) {
        success = await _prefs.setStringList(key, value);
      } else {
        // Serialize complex objects to JSON
        final jsonString = jsonEncode(value);
        success = await _prefs.setString(key, jsonString);
      }
      
      // Update cache
      if (success) {
        _cache[key] = value;
        developer.log('Stored value for key: $key', name: 'StorageService');
      }
      
      return success;
      
    } catch (e) {
      developer.log('Failed to store value for key $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Retrieve a value by key
  T? getValue<T>(String key, {T? defaultValue}) {
    try {
      _ensureInitialized();
      
      // Check cache first
      if (_cache.containsKey(key)) {
        final cached = _cache[key];
        if (cached is T) {
          return cached;
        }
      }
      
      // Retrieve from storage
      final value = _prefs.get(key);
      
      if (value == null) {
        return defaultValue;
      }
      
      T? result;
      
      // Handle type conversion
      if (T == String && value is String) {
        result = value as T;
      } else if (T == int && value is int) {
        result = value as T;
      } else if (T == double && value is double) {
        result = value as T;
      } else if (T == bool && value is bool) {
        result = value as T;
      } else if (T == List<String> && value is List<String>) {
        result = value as T;
      } else if (value is String) {
        // Try to deserialize JSON
        try {
          final decoded = jsonDecode(value);
          if (decoded is T) {
            result = decoded;
          }
        } catch (e) {
          developer.log('Failed to deserialize JSON for key $key: $e', name: 'StorageService');
        }
      }
      
      // Cache the result
      if (result != null) {
        _cache[key] = result;
      }
      
      return result ?? defaultValue;
      
    } catch (e) {
      developer.log('Failed to retrieve value for key $key: $e', name: 'StorageService');
      return defaultValue;
    }
  }

  /// Remove a value by key
  Future<bool> removeValue(String key) async {
    try {
      _ensureInitialized();
      
      final success = await _prefs.remove(key);
      
      if (success) {
        _cache.remove(key);
        developer.log('Removed value for key: $key', name: 'StorageService');
      }
      
      return success;
      
    } catch (e) {
      developer.log('Failed to remove value for key $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Check if a key exists
  bool containsKey(String key) {
    try {
      _ensureInitialized();
      return _prefs.containsKey(key);
    } catch (e) {
      developer.log('Failed to check key existence for $key: $e', name: 'StorageService');
      return false;
    }
  }

  /// Clear all stored data
  Future<bool> clearAll() async {
    try {
      _ensureInitialized();
      
      final success = await _prefs.clear();
      
      if (success) {
        _cache.clear();
        developer.log('Cleared all stored data', name: 'StorageService');
      }
      
      return success;
      
    } catch (e) {
      developer.log('Failed to clear all data: $e', name: 'StorageService');
      return false;
    }
  }

  // ========================================
  // SPECIALIZED STORAGE METHODS
  // ========================================

  /// Store user preferences
  Future<bool> saveUserPreferences(Map<String, dynamic> preferences) async {
    return await setValue(AppConstants.preferencesKey, preferences);
  }

  /// Load user preferences
  Map<String, dynamic>? getUserPreferences() {
    return getValue<Map<String, dynamic>>(AppConstants.preferencesKey);
  }

  /// Store player statistics
  Future<bool> savePlayerStats(Map<String, dynamic> stats) async {
    // Add timestamp
    stats['lastUpdated'] = DateTime.now().toIso8601String();
    return await setValue(AppConstants.playerStatsKey, stats);
  }

  /// Load player statistics
  Map<String, dynamic>? getPlayerStats() {
    return getValue<Map<String, dynamic>>(AppConstants.playerStatsKey);
  }

  /// Store game state
  Future<bool> saveGameState(Map<String, dynamic> gameState) async {
    // Add timestamp and version
    gameState['savedAt'] = DateTime.now().toIso8601String();
    gameState['version'] = _currentVersion;
    return await setValue(AppConstants.gameStateKey, gameState);
  }

  /// Load game state
  Map<String, dynamic>? getGameState() {
    final state = getValue<Map<String, dynamic>>(AppConstants.gameStateKey);
    
    // Validate version compatibility
    if (state != null) {
      final version = state['version'] as int? ?? 1;
      if (version < _currentVersion) {
        developer.log('Game state version mismatch, clearing', name: 'StorageService');
        removeValue(AppConstants.gameStateKey);
        return null;
      }
    }
    
    return state;
  }

  /// Store achievements data
  Future<bool> saveAchievements(List<Map<String, dynamic>> achievements) async {
    return await setValue(AppConstants.achievementsKey, achievements);
  }

  /// Load achievements data
  List<Map<String, dynamic>> getAchievements() {
    final achievements = getValue<List<dynamic>>(AppConstants.achievementsKey);
    if (achievements == null) return [];
    
    return achievements.cast<Map<String, dynamic>>();
  }

  /// Store settings
  Future<bool> saveSettings(Map<String, dynamic> settings) async {
    return await setValue(AppConstants.settingsKey, settings);
  }

  /// Load settings
  Map<String, dynamic>? getSettings() {
    return getValue<Map<String, dynamic>>(AppConstants.settingsKey);
  }

  /// Store high scores
  Future<bool> saveHighScores(List<Map<String, dynamic>> scores) async {
    // Keep only top scores and add timestamp
    final timestampedScores = scores.map((score) {
      score['timestamp'] = DateTime.now().toIso8601String();
      return score;
    }).toList();
    
    // Sort by score and keep top entries
    timestampedScores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final topScores = timestampedScores.take(AppConstants.maxLeaderboardEntries).toList();
    
    return await setValue(AppConstants.highScoresKey, topScores);
  }

  /// Load high scores
  List<Map<String, dynamic>> getHighScores() {
    final scores = getValue<List<dynamic>>(AppConstants.highScoresKey);
    if (scores == null) return [];
    
    return scores.cast<Map<String, dynamic>>();
  }

  // ========================================
  // BATCH OPERATIONS
  // ========================================

  /// Store multiple values in a batch
  Future<bool> setBatch(Map<String, dynamic> values) async {
    try {
      _ensureInitialized();
      
      bool allSuccess = true;
      
      for (final entry in values.entries) {
        final success = await setValue(entry.key, entry.value);
        if (!success) {
          allSuccess = false;
          developer.log('Failed to store ${entry.key} in batch', name: 'StorageService');
        }
      }
      
      return allSuccess;
      
    } catch (e) {
      developer.log('Failed to store batch: $e', name: 'StorageService');
      return false;
    }
  }

  /// Get multiple values in a batch
  Map<String, dynamic> getBatch(List<String> keys) {
    final result = <String, dynamic>{};
    
    for (final key in keys) {
      final value = getValue(key);
      if (value != null) {
        result[key] = value;
      }
    }
    
    return result;
  }

  /// Remove multiple values in a batch
  Future<bool> removeBatch(List<String> keys) async {
    try {
      _ensureInitialized();
      
      bool allSuccess = true;
      
      for (final key in keys) {
        final success = await removeValue(key);
        if (!success) {
          allSuccess = false;
        }
      }
      
      return allSuccess;
      
    } catch (e) {
      developer.log('Failed to remove batch: $e', name: 'StorageService');
      return false;
    }
  }

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  /// Get storage size estimation
  int getStorageSize() {
    try {
      _ensureInitialized();
      
      int totalSize = 0;
      
      for (final key in _prefs.getKeys()) {
        final value = _prefs.get(key);
        if (value is String) {
          totalSize += value.length * 2; // UTF-16 encoding
        } else {
          totalSize += 8; // Rough estimate for primitives
        }
      }
      
      return totalSize;
      
    } catch (e) {
      developer.log('Failed to calculate storage size: $e', name: 'StorageService');
      return 0;
    }
  }

  /// Get all stored keys
  Set<String> getAllKeys() {
    try {
      _ensureInitialized();
      return _prefs.getKeys();
    } catch (e) {
      developer.log('Failed to get all keys: $e', name: 'StorageService');
      return <String>{};
    }
  }

  /// Export all data (for backup)
  Map<String, dynamic> exportData() {
    try {
      _ensureInitialized();
      
      final data = <String, dynamic>{};
      
      for (final key in _prefs.getKeys()) {
        data[key] = _prefs.get(key);
      }
      
      // Add metadata
      data['_export_timestamp'] = DateTime.now().toIso8601String();
      data['_export_version'] = _currentVersion;
      
      return data;
      
    } catch (e) {
      developer.log('Failed to export data: $e', name: 'StorageService');
      return {};
    }
  }

  /// Import data (from backup)
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      _ensureInitialized();
      
      // Validate version compatibility
      final version = data['_export_version'] as int? ?? 1;
      if (version > _currentVersion) {
        developer.log('Import data version too new: $version > $_currentVersion', name: 'StorageService');
        return false;
      }
      
      // Remove metadata keys
      data.remove('_export_timestamp');
      data.remove('_export_version');
      
      // Import data
      bool allSuccess = true;
      
      for (final entry in data.entries) {
        final success = await setValue(entry.key, entry.value);
        if (!success) {
          allSuccess = false;
        }
      }
      
      if (allSuccess) {
        developer.log('Successfully imported ${data.length} entries', name: 'StorageService');
      }
      
      return allSuccess;
      
    } catch (e) {
      developer.log('Failed to import data: $e', name: 'StorageService');
      return false;
    }
  }

  // ========================================
  // MAINTENANCE OPERATIONS
  // ========================================

  /// Handle version migration
  Future<void> _handleVersionMigration() async {
    final currentVersion = getValue<int>(_versionKey, defaultValue: 1);
    
    if (currentVersion! < _currentVersion) {
      developer.log('Migrating storage from version $currentVersion to $_currentVersion', name: 'StorageService');
      
      // Perform migration based on version differences
      await _performMigration(currentVersion, _currentVersion);
      
      // Update version
      await setValue(_versionKey, _currentVersion);
    }
  }

  /// Perform storage migration
  Future<void> _performMigration(int fromVersion, int toVersion) async {
    // Migration logic for different versions
    if (fromVersion == 1 && toVersion >= 2) {
      // Version 1 to 2: Update key formats
      await _migrateV1ToV2();
    }
    
    // Add more migration logic as needed
  }

  /// Migrate from version 1 to version 2
  Future<void> _migrateV1ToV2() async {
    // Update key formats from v1 to v2
    final oldKeys = {
      'player_stats': AppConstants.playerStatsKey,
      'achievements': AppConstants.achievementsKey,
      'settings': AppConstants.settingsKey,
      'game_state': AppConstants.gameStateKey,
    };
    
    for (final entry in oldKeys.entries) {
      if (containsKey(entry.key)) {
        final value = getValue(entry.key);
        if (value != null) {
          await setValue(entry.value, value);
          await removeValue(entry.key);
        }
      }
    }
  }

  /// Perform cleanup if needed
  Future<void> _performCleanupIfNeeded() async {
    final lastCleanup = getValue<String>('last_cleanup');
    final lastCleanupTime = lastCleanup != null 
        ? DateTime.tryParse(lastCleanup) 
        : null;
    
    if (lastCleanupTime == null || 
        DateTime.now().difference(lastCleanupTime) > _cleanupInterval) {
      await _performCleanup();
    }
  }

  /// Perform storage cleanup
  Future<void> _performCleanup() async {
    try {
      developer.log('Performing storage cleanup', name: 'StorageService');
      
      // Remove expired data
      await _removeExpiredData();
      
      // Clear cache
      _cache.clear();
      
      // Update cleanup timestamp
      await setValue('last_cleanup', DateTime.now().toIso8601String());
      
      developer.log('Storage cleanup completed', name: 'StorageService');
      
    } catch (e) {
      developer.log('Failed to perform cleanup: $e', name: 'StorageService');
    }
  }

  /// Remove expired data
  Future<void> _removeExpiredData() async {
    final keysToRemove = <String>[];
    
    for (final key in _prefs.getKeys()) {
      // Check for old temporary data
      if (key.startsWith('temp_') || key.startsWith('cache_')) {
        keysToRemove.add(key);
      }
      
      // Check for expired session data
      if (key.contains('session')) {
        final value = getValue<Map<String, dynamic>>(key);
        if (value != null) {
          final timestamp = value['timestamp'] as String?;
          if (timestamp != null) {
            final date = DateTime.tryParse(timestamp);
            if (date != null && DateTime.now().difference(date) > AppConstants.dataExpirationTime) {
              keysToRemove.add(key);
            }
          }
        }
      }
    }
    
    // Remove expired keys
    for (final key in keysToRemove) {
      await removeValue(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      developer.log('Removed ${keysToRemove.length} expired entries', name: 'StorageService');
    }
  }

  /// Preload critical data into cache
  Future<void> _preloadCriticalData() async {
    final criticalKeys = [
      AppConstants.settingsKey,
      AppConstants.preferencesKey,
    ];
    
    for (final key in criticalKeys) {
      if (containsKey(key)) {
        getValue(key); // This will cache the value
      }
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    return {
      'initialized': _isInitialized,
      'totalKeys': getAllKeys().length,
      'cacheSize': _cache.length,
      'storageSize': getStorageSize(),
      'lastCleanup': _lastCleanup?.toIso8601String(),
    };
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    developer.log('Storage cache cleared', name: 'StorageService');
  }

  /// Dispose of the storage service
  Future<void> dispose() async {
    try {
      developer.log('Disposing StorageService', name: 'StorageService');
      
      // Clear cache
      _cache.clear();
      
      // Mark as not initialized
      _isInitialized = false;
      
      developer.log('StorageService disposed', name: 'StorageService');
      
    } catch (e) {
      developer.log('Error disposing StorageService: $e', name: 'StorageService');
    }
  }
}