import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/analytics_service.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

import 'data/datasources/asset_datasource.dart';
import 'data/datasources/local_storage_datasource.dart';

import 'data/repositories_impl/asset_repository_impl.dart';
import 'data/repositories_impl/game_repository_impl.dart';
import 'data/repositories_impl/player_repository_impl.dart';

import 'domain/repositories/asset_repository.dart';
import 'domain/repositories/game_repository.dart';
import 'domain/repositories/player_repository.dart';

import 'domain/usecases/achievement_usecases.dart';
import 'domain/usecases/game_usecases.dart';
import 'domain/usecases/player_usecases.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Services (all with dispose())
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsServiceImpl());
  sl.registerLazySingleton<AudioService>(() => AudioServiceImpl());
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(prefs));

  // Data sources
  sl.registerLazySingleton<AssetDatasource>(() => AssetDatasourceImpl());
  sl.registerLazySingleton<LocalStorageDatasource>(
    () => LocalStorageDatasourceImpl(sl<StorageService>()),
  );

  // Repositories
  sl.registerLazySingleton<AssetRepository>(() => AssetRepositoryImpl(sl<AssetDatasource>()));
  sl.registerLazySingleton<GameRepository>(() => GameRepositoryImpl(local: sl<LocalStorageDatasource>()));
  sl.registerLazySingleton<PlayerRepository>(() => PlayerRepositoryImpl(local: sl<LocalStorageDatasource>()));

  // Use cases
  sl.registerLazySingleton(() => LoadAssets(sl<AssetRepository>()));
  sl.registerLazySingleton(() => SaveGameSession(sl<GameRepository>()));
  sl.registerLazySingleton(() => LoadGameSession(sl<GameRepository>()));
  sl.registerLazySingleton(() => UpdatePlayerStats(sl<PlayerRepository>()));
  sl.registerLazySingleton(() => LoadPlayerStats(sl<PlayerRepository>()));
  sl.registerLazySingleton(() => UnlockAchievement(sl<PlayerRepository>()));
}
