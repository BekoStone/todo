// ignore_for_file: avoid_print

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
import 'domain/usecases/achievement_usecases_dart.dart';

// Use 'getIt' instead of 'sl' to match usage in BoxHooksGame
final getIt = GetIt.instance;
final sl = getIt; // Keep for backward compatibility

Future<void> init() async {
  try {
    // ========================================
    // EXTERNAL DEPENDENCIES
    // ========================================
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerLazySingleton(() => sharedPreferences);
    
    // ========================================
    // CORE SERVICES  
    // ========================================
    getIt.registerLazySingleton<AudioService>(() => AudioService());
    getIt.registerLazySingleton<StorageService>(
      () => StorageService(getIt<SharedPreferences>()),
    );
    
    // ✅ REMOVED: ResponsiveUtils - now used as static utility class
    // ResponsiveUtils doesn't need dependency injection since it's all static methods
    
    // ========================================
    // DATA SOURCES
    // ========================================
    getIt.registerLazySingleton<LocalStorageDataSource>(
      () => LocalStorageDataSource(getIt<StorageService>()),
    );
    
    // ========================================
    // REPOSITORIES
    // ========================================
    getIt.registerLazySingleton<GameRepository>(
      () => GameRepositoryImpl(getIt<LocalStorageDataSource>()),
    );
    getIt.registerLazySingleton<PlayerRepository>(
      () => PlayerRepositoryImpl(getIt<LocalStorageDataSource>()),
    );
    
    // ========================================
    // USE CASES
    // ========================================
    getIt.registerLazySingleton(() => GameUseCases(getIt<GameRepository>()));
    getIt.registerLazySingleton(() => PlayerUseCases(getIt<PlayerRepository>()));
    
    // Achievement use cases
    getIt.registerLazySingleton(() => AchievementUseCases(getIt<PlayerRepository>()));
    
    // ========================================
    // CUBITS/BLOCS - PROPER STATE MANAGEMENT
    // ========================================
    
    // GameCubit - with both required parameters
    getIt.registerFactory(() => GameCubit(
      getIt<GameUseCases>(),
      getIt<AchievementUseCases>(),
    ));
    
    // PlayerCubit - with both required parameters  
    getIt.registerFactory(() => PlayerCubit(
      getIt<PlayerUseCases>(),
      getIt<AchievementUseCases>(),
    ));
    
    // UICubit - CRITICAL FIX: Add required constructor parameters
    getIt.registerFactory(() => UICubit(
      getIt<AudioService>(),
      getIt<StorageService>(),
    ));
    
    // ========================================
    // INITIALIZE SERVICES
    // ========================================
    await getIt<AudioService>().initialize();
    
    print('✅ Dependency injection initialized successfully');
    
  } catch (e) {
    print('❌ Failed to initialize dependency injection: $e');
    rethrow;
  }
}

/// Clean up all registered dependencies
Future<void> dispose() async {
  try {
    // Dispose audio service
    if (getIt.isRegistered<AudioService>()) {
      // await getIt<AudioService>().dispose();
    }
    
    // Reset GetIt instance
    await getIt.reset();
    
    print('✅ Dependencies disposed successfully');
  } catch (e) {
    print('❌ Failed to dispose dependencies: $e');
  }
}

/// Check if all critical dependencies are registered
bool validateDependencies() {
  final criticalDependencies = [
    SharedPreferences,
    AudioService,
    StorageService,
    // ✅ REMOVED: ResponsiveUtils (now static utility)
    LocalStorageDataSource,
    GameRepository,
    PlayerRepository,
    GameUseCases,
    PlayerUseCases,
    AchievementUseCases,
    GameCubit,
    PlayerCubit,
    UICubit,
  ];
  
  for (final dependency in criticalDependencies) {
    if (!getIt.isRegistered(instance: dependency)) {
      print('❌ Missing dependency: $dependency');
      return false;
    }
  }
  
  print('✅ All critical dependencies registered');
  return true;
}

/// Development helper to list all registered dependencies
void debugPrintDependencies() {
  print('📋 Registered Dependencies:');
  print('- SharedPreferences: ${getIt.isRegistered<SharedPreferences>()}');
  print('- AudioService: ${getIt.isRegistered<AudioService>()}');
  print('- StorageService: ${getIt.isRegistered<StorageService>()}');
  print('- LocalStorageDataSource: ${getIt.isRegistered<LocalStorageDataSource>()}');
  print('- GameRepository: ${getIt.isRegistered<GameRepository>()}');
  print('- PlayerRepository: ${getIt.isRegistered<PlayerRepository>()}');
  print('- GameUseCases: ${getIt.isRegistered<GameUseCases>()}');
  print('- PlayerUseCases: ${getIt.isRegistered<PlayerUseCases>()}');
  print('- AchievementUseCases: ${getIt.isRegistered<AchievementUseCases>()}');
  print('- GameCubit: ${getIt.isRegistered<GameCubit>()}');
  print('- PlayerCubit: ${getIt.isRegistered<PlayerCubit>()}');
  print('- UICubit: ${getIt.isRegistered<UICubit>()}');
}

/// Initialize state management system
Future<void> initializeStateManagement() async {
  try {
    // Initialize all cubits with proper state
    final gameCubit = getIt<GameCubit>();
    final playerCubit = getIt<PlayerCubit>();
    final uiCubit = getIt<UICubit>();
    
    // Initialize player data first
    await playerCubit.initializePlayer();
    
    // Set up cross-cubit communication if needed
    _setupCubitCommunication(gameCubit, playerCubit, uiCubit);
    
    print('✅ State management initialized');
  } catch (e) {
    print('❌ Failed to initialize state management: $e');
    rethrow;
  }
}

/// Setup communication between cubits
void _setupCubitCommunication(GameCubit gameCubit, PlayerCubit playerCubit, UICubit uiCubit) {
  // Example: Listen to game events and update player stats
  gameCubit.stream.listen((gameState) {
    if (gameState.status == GameStateStatus.gameOver) {
      // Update player stats when game ends
      playerCubit.processGameCompletion(
        finalScore: gameState.score,
        level: gameState.level,
        linesCleared: gameState.linesCleared,
        blocksPlaced: 0, // Would get this from game state
        gameDuration: gameState.sessionDuration ?? Duration.zero,
        usedUndo: gameState.remainingUndos < 3,
      );
    }
  });
  
  // Example: Update UI based on player achievements
  playerCubit.stream.listen((playerState) {
    if (playerState.hasUnseenAchievements) {
      // Could trigger UI notifications
    }
  });
}