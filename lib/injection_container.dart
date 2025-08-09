// ignore_for_file: avoid_print

import 'package:get_it/get_it.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/presentation/flame/box_hooks_game.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'core/services/audio_service.dart';
import 'core/services/storage_service.dart';
import 'data/datasources/local_storage_datasource.dart';
import 'data/repositories/game_repository_impl.dart';
import 'data/repositories/player_repository_impl.dart';
import 'domain/repositories/game_repository.dart';
import 'domain/repositories/player_repository.dart';
import 'domain/usecases/game_usecases.dart';
import 'domain/usecases/player_usecases.dart';

final getIt = GetIt.instance;
final sl = getIt; // Backward compatibility alias

/// Initialize all dependencies with proper error handling and validation
Future<void> init() async {
  try {
    print('🚀 Initializing dependency injection...');
    
    // ========================================
    // EXTERNAL DEPENDENCIES
    // ========================================
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
    print('✅ SharedPreferences registered');
    
    // ========================================
    // CORE SERVICES
    // ========================================
    getIt.registerLazySingleton<AudioService>(() => AudioService());
    getIt.registerLazySingleton<StorageService>(
      () => StorageService(getIt<SharedPreferences>()),
    );
    print('✅ Core services registered');
    
    // ========================================
    // DATA SOURCES
    // ========================================
    getIt.registerLazySingleton<LocalStorageDataSource>(
      () => LocalStorageDataSource(getIt<StorageService>()),
    );
    print('✅ Data sources registered');
    
    // ========================================
    // REPOSITORIES
    // ========================================
    getIt.registerLazySingleton<GameRepository>(
      () => GameRepositoryImpl(getIt<LocalStorageDataSource>()),
    );
    getIt.registerLazySingleton<PlayerRepository>(
      () => PlayerRepositoryImpl(getIt<LocalStorageDataSource>()),
    );
    print('✅ Repositories registered');
    
    // ========================================
    // USE CASES
    // ========================================
    getIt.registerLazySingleton<GameUseCases>(
      () => GameUseCases(getIt<GameRepository>()),
    );
    getIt.registerLazySingleton<PlayerUseCases>(
      () => PlayerUseCases(getIt<PlayerRepository>()),
    );
    getIt.registerLazySingleton<AchievementUseCases>(
      () => AchievementUseCases(getIt<PlayerRepository>()),
    );
    print('✅ Use cases registered');
    
    // ========================================
    // STATE MANAGEMENT (CUBITS)
    // ========================================
    
    // Register as factories for proper state isolation
    getIt.registerFactory<GameCubit>(
      () => GameCubit(
        getIt<GameUseCases>(),
        getIt<AchievementUseCases>(),
      ),
    );
    
    getIt.registerFactory<PlayerCubit>(
      () => PlayerCubit(
        getIt<PlayerUseCases>(),
        getIt<AchievementUseCases>(),
      ),
    );
    
    getIt.registerFactory<UICubit>(
      () => UICubit(
        getIt<AudioService>(),
        getIt<StorageService>(),
      ),
    );
    print('✅ State management registered');
    
    // ========================================
    // INITIALIZE SERVICES
    // ========================================
    await _initializeServices();
    
    print('✅ Dependency injection initialized successfully');
    
  } catch (e, stackTrace) {
    print('❌ Failed to initialize dependency injection: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

/// Initialize core services that require async setup
Future<void> _initializeServices() async {
  try {
    // Initialize audio service
    await getIt<AudioService>().initialize();
    print('✅ Audio service initialized');
    
    // Initialize storage service
    await getIt<StorageService>().initialize();
    print('✅ Storage service initialized');
    
  } catch (e) {
    print('❌ Failed to initialize services: $e');
    rethrow;
  }
}

/// Clean up all registered dependencies
Future<void> dispose() async {
  try {
    print('🧹 Disposing dependencies...');
    
    // Dispose services that require cleanup
    if (getIt.isRegistered<AudioService>()) {
      await getIt<AudioService>().dispose();
    }
    
    if (getIt.isRegistered<StorageService>()) {
      await getIt<StorageService>().dispose();
    }
    
    // Reset GetIt instance
    await getIt.reset();
    
    print('✅ Dependencies disposed successfully');
  } catch (e) {
    print('❌ Failed to dispose dependencies: $e');
  }
}

/// Validate that all critical dependencies are properly registered
bool validateDependencies() {
  final criticalDependencies = <Type>[
    SharedPreferences,
    AudioService,
    StorageService,
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
    if (!getIt.isRegistered(instanceType: dependency)) {
      print('❌ Missing critical dependency: $dependency');
      return false;
    }
  }
  
  print('✅ All critical dependencies validated');
  return true;
}

/// Development helper to debug registered dependencies
void debugPrintDependencies() {
  if (!kDebugMode) return;
  
  print('📋 Registered Dependencies Status:');
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

/// Initialize state management system with proper error handling
Future<void> initializeStateManagement() async {
  try {
    print('🎮 Initializing state management...');
    
    // Create cubit instances to validate registration
    final gameCubit = getIt<GameCubit>();
    final playerCubit = getIt<PlayerCubit>();
    final uiCubit = getIt<UICubit>();
    
    // Initialize player data
    await playerCubit.initializePlayer();
    
    // Set up cross-cubit communication
    _setupCubitCommunication(gameCubit, playerCubit, uiCubit);
    
    print('✅ State management initialized');
  } catch (e) {
    print('❌ Failed to initialize state management: $e');
    rethrow;
  }
}

/// Setup communication between cubits for coordinated state management
void _setupCubitCommunication(
  GameCubit gameCubit,
  PlayerCubit playerCubit,
  UICubit uiCubit,
) {
  // Listen to game events and update player stats
  gameCubit.stream.listen((gameState) {
    if (gameState.status == GameStateStatus.gameOver && gameState.sessionData != null) {
      // Update player stats when game ends
      playerCubit.processGameCompletion(
        finalScore: gameState.score,
        level: gameState.level,
        linesCleared: gameState.linesCleared,
        blocksPlaced: gameState.sessionData!.blocksPlaced,
        gameDuration: gameState.sessionDuration ?? Duration.zero,
        usedPowerUps: gameState.sessionData!.powerUpsUsed,
      );
    }
  });
  
  // Listen to player achievements and trigger UI notifications
  playerCubit.stream.listen((playerState) {
    if (playerState.hasUnseenAchievements) {
      uiCubit.showAchievementNotification();
    }
    
    if (playerState.status == PlayerStateStatus.error) {
      uiCubit.showError(playerState.errorMessage ?? 'Player error occurred');
    }
  });
  
  // Listen to UI state for global app behavior
  uiCubit.stream.listen((uiState) {
    if (uiState.shouldPlaySound && uiState.soundEffect != null) {
      // Play UI sounds through audio service
      getIt<AudioService>().playSfx(uiState.soundEffect!);
    }
  });
}

/// Extension for easier dependency access
extension GetItExtension on GetIt {
  /// Safe get with fallback and error handling
  T safeGet<T extends Object>({T? fallback}) {
    try {
      return get<T>();
    } catch (e) {
      if (fallback != null) {
        print('⚠️ Using fallback for ${T.toString()}: $e');
        return fallback;
      }
      print('❌ Failed to get dependency ${T.toString()}: $e');
      rethrow;
    }
  }
}

