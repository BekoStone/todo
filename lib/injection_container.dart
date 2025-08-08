import 'package:get_it/get_it.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/audio_service.dart';
import 'core/services/storage_service.dart';
import 'data/datasources/local_storage_datasource.dart';
import 'data/repositories/game_repository_impl.dart';
import 'data/repositories/player_repository_impl.dart';
import 'domain/repositories/game_repository.dart';
import 'domain/repositories/player_repository.dart';
import 'domain/usecases/game_usecases.dart';
import 'domain/usecases/player_usecases.dart';


final sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Core services
  sl.registerLazySingleton<AudioService>(() => AudioService());
  sl.registerLazySingleton<StorageService>(
    () => StorageService(sl<SharedPreferences>()),
  );
  
  // Data sources
  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSource(sl<StorageService>()),
  );
  
  // Repositories
  sl.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(sl<LocalStorageDataSource>()),
  );
  sl.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(sl<LocalStorageDataSource>()),
  );
  
  // Use cases
  sl.registerLazySingleton(() => GameUseCases(sl<GameRepository>()));
  sl.registerLazySingleton(() => PlayerUseCases(sl<PlayerRepository>()));
  
  // Cubits
  sl.registerFactory(() => GameCubit(sl<GameUseCases>()));
  sl.registerFactory(() => PlayerCubit(sl<PlayerUseCases>()));
  sl.registerFactory(() => UICubit());
  
  // Initialize services
  await sl<AudioService>().initialize();
}