import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
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
  late final UICubit _uiCubit;
  late final AudioService _audioService;
  late final ResponsiveUtils _responsiveUtils;

  // Core game components
  late final GameWorld _gameWorld;
  late final InputSystem _inputSystem;
  late final ScoringSystem _scoringSystem;
  late final PowerUpSystem _powerUpSystem;

  // Game state
  bool _isInitialized = false;
  bool _isPaused = false;

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
      _uiCubit = getIt<UiCubit>();
      _audioService = getIt<AudioService>();
      _responsiveUtils = getIt<ResponsiveUtils>();
      
      debugPrint('🔧 Dependencies initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize dependencies: $e');
      rethrow;
    }
  }

  /// Initialize and configure all game components
  Future<void> _initializeGameComponents() async {
    try {
      // Calculate responsive layout
      final screenSize = size;
      final config = _responsiveUtils.getGameConfig(screenSize);
      
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

    gameState.when(
      initial: () {
        debugPrint('🎮 Game state: Initial');
      },
      loading: () {
        debugPrint('🎮 Game state: Loading');
      },
      playing: (session) {
        debugPrint('🎮 Game state: Playing');
        _handleGamePlaying(session);
      },
      paused: (session) {
        debugPrint('🎮 Game state: Paused');
        _handleGamePaused(session);
      },
      gameOver: (session) {
        debugPrint('🎮 Game state: Game Over');
        _handleGameOver(session);
      },
      error: (message) {
        debugPrint('❌ Game state error: $message');
        _handleGameError(message);
      },
    );
  }

  /// Handle player state changes from the cubit
  void _handlePlayerStateChange(PlayerState playerState) {
    if (!_isInitialized) return;

    playerState.when(
      initial: () {
        debugPrint('👤 Player state: Initial');
      },
      loading: () {
        debugPrint('👤 Player state: Loading');
      },
      loaded: (stats) {
        debugPrint('👤 Player state: Loaded - Score: ${stats.currentScore}');
        _gameWorld.updatePlayerStats(stats);
      },
      error: (message) {
        debugPrint('❌ Player state error: $message');
      },
    );
  }

  /// Handle UI state changes from the cubit
  void _handleUIStateChange(UiState uiState) {
    if (!_isInitialized) return;

    uiState.when(
      idle: () {
        // Normal state
      },
      showingPowerUp: (powerUp) {
        _powerUpSystem.activatePowerUp(powerUp);
      },
      showingOverlay: (overlayType) {
        _handleOverlayDisplay(overlayType);
      },
      error: (message) {
        debugPrint('❌ UI state error: $message');
      },
    );
  }

  /// Handle when game enters playing state
  void _handleGamePlaying(GameSession session) {
    if (_isPaused) {
      _resumeGame();
    }
    
    _gameWorld.startGame(session);
    _audioService.playBackgroundMusic('game_music');
  }

  /// Handle when game is paused
  void _handleGamePaused(GameSession session) {
    _pauseGame();
    _audioService.pauseBackgroundMusic();
  }

  /// Handle when game is over
  void _handleGameOver(GameSession session) {
    _gameWorld.endGame();
    _audioService.stopBackgroundMusic();
    _audioService.playSound('game_over');
    
    // Trigger haptic feedback
    _uiCubit.triggerHapticFeedback();
  }

  /// Handle game errors
  void _handleGameError(String message) {
    _audioService.playSound('error');
    debugPrint('🚨 Game error: $message');
  }

  /// Handle overlay display
  void _handleOverlayDisplay(String overlayType) {
    switch (overlayType) {
      case 'pause':
        overlays.add('PauseOverlay');
        break;
      case 'gameOver':
        overlays.add('GameOverOverlay');
        break;
      case 'achievements':
        overlays.add('AchievementOverlay');
        break;
      case 'powerUp':
        overlays.add('PowerUpOverlay');
        break;
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
  }

  /// Internal resume handling
  void _resumeGame() {
    _isPaused = false;
    resumeEngine();
    _inputSystem.enable();
  }

  /// Handle game resize for responsive layout
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    
    if (_isInitialized) {
      final config = _responsiveUtils.getGameConfig(size);
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
}