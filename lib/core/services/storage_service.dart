import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class StorageService {
  final SharedPreferences _prefs;
  
  StorageService(this._prefs);
  
  // String operations
  Future<bool> setString(String key, String value) async {
    try {
      final success = await _prefs.setString(key, value);
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Saved string: $key');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save string $key: $e');
      return false;
    }
  }
  
  String? getString(String key, [String? defaultValue]) {
    try {
      return _prefs.getString(key) ?? defaultValue;
    } catch (e) {
      debugPrint('❌ Failed to get string $key: $e');
      return defaultValue;
    }
  }
  
  // Integer operations
  Future<bool> setInt(String key, int value) async {
    try {
      final success = await _prefs.setInt(key, value);
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Saved int: $key = $value');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save int $key: $e');
      return false;
    }
  }
  
  int getInt(String key, [int defaultValue = 0]) {
    try {
      return _prefs.getInt(key) ?? defaultValue;
    } catch (e) {
      debugPrint('❌ Failed to get int $key: $e');
      return defaultValue;
    }
  }
  
  // Double operations
  Future<bool> setDouble(String key, double value) async {
    try {
      final success = await _prefs.setDouble(key, value);
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Saved double: $key = $value');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save double $key: $e');
      return false;
    }
  }
  
  double getDouble(String key, [double defaultValue = 0.0]) {
    try {
      return _prefs.getDouble(key) ?? defaultValue;
    } catch (e) {
      debugPrint('❌ Failed to get double $key: $e');
      return defaultValue;
    }
  }
  
  // Boolean operations
  Future<bool> setBool(String key, bool value) async {
    try {
      final success = await _prefs.setBool(key, value);
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Saved bool: $key = $value');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save bool $key: $e');
      return false;
    }
  }
  
  bool getBool(String key, [bool defaultValue = false]) {
    try {
      return _prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      debugPrint('❌ Failed to get bool $key: $e');
      return defaultValue;
    }
  }
  
  // List operations
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      final success = await _prefs.setStringList(key, value);
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Saved string list: $key (${value.length} items)');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save string list $key: $e');
      return false;
    }
  }
  
  List<String> getStringList(String key, [List<String>? defaultValue]) {
    try {
      return _prefs.getStringList(key) ?? defaultValue ?? [];
    } catch (e) {
      debugPrint('❌ Failed to get string list $key: $e');
      return defaultValue ?? [];
    }
  }
  
  // JSON operations for complex objects
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      final jsonString = jsonEncode(value);
      final success = await setString(key, jsonString);
      if (AppConstants.enableDebugLogging) {
        debugPrint('💾 Saved JSON: $key');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Failed to save JSON $key: $e');
      return false;
    }
  }
  
  Map<String, dynamic>? getJson(String key, [Map<String, dynamic>? defaultValue]) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return defaultValue;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Failed to get JSON $key: $e');
      return defaultValue;
    }
  }
  
  // Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  // Remove operations
  Future<bool> remove(String key) async {
    try {
      final success = await _prefs.remove(key);
      if (AppConstants.enableDebugLogging) {
        debugPrint('🗑️ Removed: $key');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Failed to remove $key: $e');
      return false;
    }
  }
  
  // Clear all data
  Future<bool> clear() async {
    try {
      final success = await _prefs.clear();
      if (AppConstants.enableDebugLogging) {
        debugPrint('🗑️ Cleared all storage');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Failed to clear storage: $e');
      return false;
    }
  }
  
  // Get all keys
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }
  
  // Batch operations for better performance
  Future<bool> setBatch(Map<String, dynamic> data) async {
    bool allSuccessful = true;
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      bool success = false;
      
      if (value is String) {
        success = await setString(key, value);
      } else if (value is int) {
        success = await setInt(key, value);
      } else if (value is double) {
        success = await setDouble(key, value);
      } else if (value is bool) {
        success = await setBool(key, value);
      } else if (value is List<String>) {
        success = await setStringList(key, value);
      } else if (value is Map<String, dynamic>) {
        success = await setJson(key, value);
      } else {
        debugPrint('⚠️ Unsupported type for key $key: ${value.runtimeType}');
        success = false;
      }
      
      if (!success) allSuccessful = false;
    }
    
    if (AppConstants.enableDebugLogging) {
      debugPrint('💾 Batch operation: ${allSuccessful ? "success" : "partial failure"}');
    }
    
    return allSuccessful;
  }
  
  // Get storage size (approximate)
  int getApproximateSize() {
    int totalSize = 0;
    for (final key in _prefs.getKeys()) {
      final value = _prefs.get(key);
      if (value is String) {
        totalSize += value.length * 2; // Approximate UTF-16 encoding
      } else {
        totalSize += 8; // Approximate size for numbers/booleans
      }
    }
    return totalSize;
  }
  
  // Export all data (useful for backup/debugging)
  Map<String, dynamic> exportAllData() {
    final data = <String, dynamic>{};
    
    for (final key in _prefs.getKeys()) {
      data[key] = _prefs.get(key);
    }
    
    return data;
  }
  
  // Import data (useful for restore)
  Future<bool> importData(Map<String, dynamic> data) async {
    return await setBatch(data);
  }
  
  // Get storage statistics
  // Get storage statistics
Map<String, dynamic> getStorageStats() {
  final keys = _prefs.getKeys();
  final stats = <String, dynamic>{
    'totalKeys': keys.length,
    'approximateSize': getApproximateSize(),
    'keysByType': <String, int>{},
  };

  // Cast the 'keysByType' value to the correct type for safe access
  final keysByType = stats['keysByType'] as Map<String, int>;

  for (final key in keys) {
    final value = _prefs.get(key);
    final type = value.runtimeType.toString();
    keysByType[type] = (keysByType[type] ?? 0) + 1;
  }

  return stats;
}
}