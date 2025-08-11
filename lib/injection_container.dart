// ignore_for_file: avoid_print

import 'package:get_it/get_it.dart';
import 'package:puzzle_box/core/state/game_state.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit.dart';
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
import 'core/state/player_state.dart';

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
    // STATE MANAGEMENT - REGISTER AS SINGLETONS
    // ========================================
    getIt.registerLazySingleton<GameCubit>(
      () => GameCubit(
        getIt<GameUseCases>(),
        getIt<AchievementUseCases>(),
      ),
    );
    
    getIt.registerLazySingleton<PlayerCubit>(
      () => PlayerCubit(
        getIt<PlayerUseCases>(),
        getIt<AchievementUseCases>(),
      ),
    );
    
    getIt.registerLazySingleton<UICubit>(
      () => UICubit(
        getIt<AudioService>(),
        getIt<StorageService>(),
      ),
    );
    print('✅ State management (Cubits) registered as singletons');
    
    print('✅ Dependency injection completed successfully!');
    
    // Validate registration
    _validateRegistration();
    
  } catch (e) {
    print('❌ Failed to initialize dependencies: $e');
    rethrow;
  }
}

/// Validate that all critical dependencies are registered
void _validateRegistration() {
  print('🔍 Validating dependency registration...');
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
    if (gameState.status == GameStateStatus.gameOver && gameState.currentSession != null) {
      // Update player stats when game ends
      playerCubit.processGameCompletion(
        finalScore: gameState.score,
        level: gameState.level,
        linesCleared: gameState.linesCleared,
        blocksPlaced: 0, // Would need to track this in game state
        gameDuration: gameState.sessionDuration ?? Duration.zero,
        usedUndo: gameState.remainingUndos < 3,
        usedPowerUps: {},
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
        print('⚠️ Failed to get ${T.toString()}, using fallback: $e');
        return fallback;
      }
      print('❌ Failed to get ${T.toString()}: $e');
      rethrow;
    }
  }
  
  /// Check if a dependency is registered and ready
  bool isReady<T extends Object>() {
    try {
      get<T>();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Clean up all dependencies (for testing and app shutdown)
Future<void> cleanUp() async {
  try {
    print('🧹 Cleaning up dependencies...');
    
    // Close all cubits
    if (getIt.isRegistered<GameCubit>()) {
      await getIt<GameCubit>().close();
    }
    if (getIt.isRegistered<PlayerCubit>()) {
      await getIt<PlayerCubit>().close();
    }
    if (getIt.isRegistered<UICubit>()) {
      await getIt<UICubit>().close();
    }
    
    // Dispose audio service
    if (getIt.isRegistered<AudioService>()) {
      await getIt<AudioService>().dispose();
    }
    
    // Reset GetIt
    await getIt.reset();
    
    print('✅ Dependencies cleaned up');
  } catch (e) {
    print('❌ Error during cleanup: $e');
  }
}

/// Initialize app with proper error handling and recovery
Future<void> initializeApp() async {
  try {
    print('🎯 Starting Box Hooks application initialization...');
    
    // Initialize dependency injection
    await init();
    
    // Initialize state management
    await initializeStateManagement();
    
    // Additional app-specific initialization
    await _initializeAppSpecificFeatures();
    
    print('🎉 Application initialized successfully!');
    
  } catch (e) {
    print('💥 Critical error during app initialization: $e');
    
    // Attempt graceful degradation
    try {
      await _handleInitializationFailure(e);
    } catch (recoveryError) {
      print('💀 Recovery failed: $recoveryError');
      rethrow;
    }
  }
}

/// Initialize app-specific features
Future<void> _initializeAppSpecificFeatures() async {
  try {
    // Initialize audio system
    final audioService = getIt<AudioService>();
    await audioService.initialize();
    
    // Pre-load critical assets if needed
    // await _preloadCriticalAssets();
    
    print('✅ App-specific features initialized');
  } catch (e) {
    print('⚠️ Warning: Some app features failed to initialize: $e');
    // Continue anyway - these are not critical for basic functionality
  }
}

/// Handle initialization failure with graceful degradation
Future<void> _handleInitializationFailure(dynamic error) async {
  print('🔄 Attempting recovery from initialization failure...');
  
  try {
    // Clean up partial state
    await cleanUp();
    
    // Try minimal initialization
    await _initializeMinimal();
    
    print('✅ Minimal initialization successful');
  } catch (e) {
    print('❌ Minimal initialization failed: $e');
    rethrow;
  }
}

/// Minimal initialization for emergency fallback
Future<void> _initializeMinimal() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  
  getIt.registerLazySingleton<StorageService>(
    () => StorageService(getIt<SharedPreferences>()),
  );
  
  getIt.registerLazySingleton<AudioService>(() => AudioService());
  
  print('⚠️ Running in minimal mode');
}