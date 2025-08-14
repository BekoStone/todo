// lib/data/datasources/local_storage_datasource.dart
import '../../core/constants/app_constants.dart';
import '../../services/storage_service.dart';

class LocalStorageDatasource {
  final StorageService storage;
  LocalStorageDatasource(this.storage);

  Future<Map<String, dynamic>?> loadPlayerStats() =>
      Future.value(storage.readJson(AppConstants.kPlayerStats));

  Future<void> savePlayerStats(Map<String, dynamic> json) =>
      storage.writeJson(AppConstants.kPlayerStats, json);

  Future<Map<String, dynamic>?> loadGameSession() =>
      Future.value(storage.readJson(AppConstants.kGameSession));

  Future<void> saveGameSession(Map<String, dynamic> json) =>
      storage.writeJson(AppConstants.kGameSession, json);
}

// Keep alias if you referenced Impl elsewhere
typedef LocalStorageDatasourceImpl = LocalStorageDatasource;
