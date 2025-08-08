import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';

import '../../core/services/audio_service.dart';
import '../../core/utils/responsive_utils.dart';
import '../../injection_container.dart';
import 'components/game_world.dart';
import 'systems/input_system.dart';
import 'systems/scoring_system.dart';
import 'systems/power_up_system.dart';

/// Main Flame game class following Clean Architecture principles.
/// Acts as the game engine coordinator and integrates with Flutter's state management.
class BoxHooksGame extends FlameGame with HasCollisionDetection, HasGameRef {
  // Dependencies injected via service locator
  late final GameCubit _gameCubit;
  late final PlayerCubit _playerCubit;
  late final UICubit _uiCubit; // ✅ FIXED: Consistent naming
  late final AudioService _audioService;
  
  // Core game components
  late final GameWorld _gameWorld;
  late final InputSystem _inputSystem;
  late final ScoringSystem _scoringSystem;
  late final PowerUpSystem _powerUpSystem;

  // Game state
  bool _isInitialized = false;
  bool _isPaused = false;
  
  // Cache for responsive calculations
  GameConfig? _currentConfig;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    await _initializeDependencies();
    await _initializeGameComponents();
    await _setupEventListeners();
    
    _isInitialized = true;
    debugPrint('✅ BoxHooksGame initialized successfully');
  }

  /// Initialize all dependencies from the service locator
  Future<void> _initializeDependencies() async {
    try {
      _gameCubit = getIt<GameCubit>();
      _playerCubit = getIt<PlayerCubit>();
      _uiCubit = getIt<UICubit>(); // ✅ FIXED: Correct class name
      _audioService = getIt<AudioService>();
      
      debugPrint('🔧 Dependencies initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize dependencies: $e');
      rethrow;
    }
  }

  /// Initialize and configure all game components
  Future<void> _initializeGameComponents() async {
    try {
      // ✅ FIXED: Use ResponsiveUtils as static methods, not injected service
      final screenSize = size;
      final config = ResponsiveUtils.getGameConfig(screenSize);
      _currentConfig = config;
      
      // Initialize game world (main game logic container)
      _gameWorld = GameWorld(
        gridSize: config.gridSize,
        cellSize: config.cellSize,
        gameCubit: _gameCubit,
        playerCubit: _playerCubit,
      );
      
      // Initialize game systems
      _inputSystem = InputSystem(
        gameWorld: _gameWorld,
        gameCubit: _gameCubit,
      );
      
      _scoringSystem = ScoringSystem(
        gameWorld: _gameWorld,
        gameCubit: _gameCubit,
        playerCubit: _playerCubit,
      );
      
      _powerUpSystem = PowerUpSystem(
        gameWorld: _gameWorld,
        gameCubit: _gameCubit,
        playerCubit: _playerCubit,
      );
      
      // Add components in order
      add(_gameWorld);
      add(_inputSystem);
      add(_scoringSystem);
      add(_powerUpSystem);
      
      debugPrint('🎮 Game components initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize game components: $e');
      rethrow;
    }
  }

  /// Setup listeners for cubit state changes
  Future<void> _setupEventListeners() async {
    // Listen to game state changes
    _gameCubit.stream.listen((gameState) {
      _handleGameStateChange(gameState);
    });

    // Listen to player state changes  
    _playerCubit.stream.listen((playerState) {
      _handlePlayerStateChange(playerState);
    });

    // Listen to UI state changes
    _uiCubit.stream.listen((uiState) {
      _handleUIStateChange(uiState);
    });
  }

  /// Handle game state changes from the cubit
  void _handleGameStateChange(GameState gameState) {
    if (!_isInitialized) return;

    // ✅ FIXED: Proper state handling based on your GameState structure
    switch (gameState.status) {
      case GameStateStatus.initial:
        debugPrint('🎮 Game state: Initial');
        break;
      case GameStateStatus.loading:
        debugPrint('🎮 Game state: Loading');
        break;
      case GameStateStatus.playing:
        debugPrint('🎮 Game state: Playing');
        _handleGamePlaying(gameState);
        break;
      case GameStateStatus.paused:
        debugPrint('🎮 Game state: Paused');
        _handleGamePaused(gameState);
        break;
      case GameStateStatus.gameOver:
        debugPrint('🎮 Game state: Game Over');
        _handleGameOver(gameState);
        break;
      case GameStateStatus.error:
        debugPrint('❌ Game state error: ${gameState.errorMessage}');
        _handleGameError(gameState.errorMessage ?? 'Unknown error');
        break;
    }
  }

  /// Handle player state changes from the cubit
  void _handlePlayerStateChange(PlayerState playerState) {
    if (!_isInitialized) return;

    switch (playerState.status) {
      case PlayerStateStatus.initial:
        debugPrint('👤 Player state: Initial');
        break;
      case PlayerStateStatus.loading:
        debugPrint('👤 Player state: Loading');
        break;
      case PlayerStateStatus.loaded:
        debugPrint('👤 Player state: Loaded');
        _updatePlayerDisplay(playerState);
        break;
      case PlayerStateStatus.updating:
        debugPrint('👤 Player state: Updating');
        break;
      case PlayerStateStatus.error:
        debugPrint('❌ Player state error: ${playerState.errorMessage}');
        break;
    }
  }

  /// Handle UI state changes from the cubit
  void _handleUIStateChange(UIState uiState) {
    if (!_isInitialized) return;

    // Handle UI-specific state changes
    if (uiState.isLoading) {
      // Show loading overlay if needed
    }

    if (uiState.hasError) {
      debugPrint('🎨 UI Error: ${uiState.errorMessage}');
    }
  }

  /// Handle playing state
  void _handleGamePlaying(GameState gameState) {
    if (_isPaused) {
      _resumeGame();
    }
    
    // Update overlays
    overlays.clear();
    
    // Play background music if enabled
    if (_uiCubit.state.settings.musicEnabled) {
      _audioService.playMusic('game_theme');
    }
  }

  /// Handle paused state
  void _handleGamePaused(GameState gameState) {
    if (!_isPaused) {
      _pauseGame();
    }
    
    // Show pause overlay
    overlays.clear();
    overlays.add('PauseOverlay');
  }

  /// Handle game over state
  void _handleGameOver(GameState gameState) {
    _pauseGame();
    
    // Show game over overlay
    overlays.clear();
    overlays.add('GameOverOverlay');
    
    // Play game over sound
    _audioService.playSfx('game_over');
  }

  /// Handle game error
  void _handleGameError(String errorMessage) {
    debugPrint('🚨 Game Error: $errorMessage');
    
    // Show error overlay or return to menu
    overlays.clear();
    overlays.add('ErrorOverlay');
  }

  /// Update player display elements
  void _updatePlayerDisplay(PlayerState playerState) {
    // Update any player-specific UI elements in the game
    if (playerState.hasUnseenAchievements) {
      // Show achievement notification
      overlays.add('AchievementNotification');
    }
  }

  /// Public API for starting a new game
  void startNewGame() {
    if (!_isInitialized) {
      debugPrint('⚠️ Game not initialized, cannot start');
      return;
    }
    
    _gameCubit.startNewGame();
  }

  /// Public API for pausing the game
  void pauseGame() {
    if (!_isInitialized || _isPaused) return;
    
    _gameCubit.pauseGame();
  }

  /// Public API for resuming the game
  void resumeGame() {
    if (!_isInitialized || !_isPaused) return;
    
    _gameCubit.resumeGame();
  }

  /// Public API for ending the game
  void endGame() {
    if (!_isInitialized) return;
    
    _gameCubit.endGame();
  }

  /// Public API for placing a block
  void placeBlock(Block block, Vector2 position) {
    if (!_isInitialized || _isPaused) return;
    
    _gameWorld.placeBlock(block, position);
  }

  /// Public API for using a power-up
  void usePowerUp(String powerUpId) {
    if (!_isInitialized || _isPaused) return;
    
    _powerUpSystem.usePowerUp(powerUpId);
  }

  /// Internal pause handling
  void _pauseGame() {
    _isPaused = true;
    pauseEngine();
    _inputSystem.disable();
    
    // Pause audio
    _audioService.pauseMusic();
  }

  /// Internal resume handling
  void _resumeGame() {
    _isPaused = false;
    resumeEngine();
    _inputSystem.enable();
    
    // Resume audio if enabled
    if (_uiCubit.state.settings.musicEnabled) {
      _audioService.resumeMusic();
    }
  }

  /// Handle game resize for responsive layout
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    
    if (_isInitialized) {
      // ✅ FIXED: Use static method instead of injected service
      final config = ResponsiveUtils.getGameConfig(size);
      _currentConfig = config;
      _gameWorld.updateLayout(config);
    }
  }

  /// Clean up resources when game is removed
  @override
  void onRemove() {
    _audioService.stopAllSounds();
    super.onRemove();
  }

  // Getters for external access
  GameWorld get gameWorld => _gameWorld;
  InputSystem get inputSystem => _inputSystem;
  ScoringSystem get scoringSystem => _scoringSystem;
  PowerUpSystem get powerUpSystem => _powerUpSystem;
  bool get isInitialized => _isInitialized;
  bool get isPaused => _isPaused;
  GameConfig? get currentConfig => _currentConfig;
}

// ✅ FIXED: Add missing enums for state management
enum GameStateStatus {
  initial,
  loading,
  playing,
  paused,
  gameOver,
  error,
}

enum PlayerStateStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}