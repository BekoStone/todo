import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
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

/// Configuration class for game responsiveness
class GameConfig {
  final int gridSize;
  final double cellSize;
  final double gridSpacing;
  final double totalGridSize;
  final double scale;

  const GameConfig({
    required this.gridSize,
    required this.cellSize,
    required this.gridSpacing,
    required this.totalGridSize,
    required this.scale,
  });
}

/// Main Flame game class following Clean Architecture principles.
/// Acts as the game engine coordinator and integrates with Flutter's state management.
class BoxHooksGame extends FlameGame with HasCollisionDetection, HasGameRef {
  // Dependencies injected via service locator
  late final GameCubit _gameCubit;
  late final PlayerCubit _playerCubit;
  late final UICubit _uiCubit;
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
    
    try {
      await _initializeDependencies();
      await _initializeGameComponents();
      await _setupEventListeners();
      
      _isInitialized = true;
      debugPrint('✅ BoxHooksGame initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize BoxHooksGame: $e');
      rethrow;
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    
    // Recalculate responsive configuration when screen size changes
    final newConfig = ResponsiveUtils.getGameConfig(canvasSize.toSize());
    if (newConfig != _currentConfig) {
      _currentConfig = newConfig;
      _updateComponentsForNewSize(newConfig);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Performance monitoring
    _monitorPerformance(dt);
    
    // Only update game components when not paused
    if (!_isPaused && _isInitialized) {
      _updateGameLogic(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Additional rendering optimizations could go here
    _optimizeRenderingPerformance(canvas);
  }

  /// Initialize all dependencies from the service locator
  Future<void> _initializeDependencies() async {
    try {
      _gameCubit = getIt<GameCubit>();
      _playerCubit = getIt<PlayerCubit>();
      _uiCubit = getIt<UICubit>();
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
      // Calculate responsive configuration
      final screenSize = size.toSize();
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
      
      // Add components in order of dependencies
      await add(_gameWorld);
      await add(_inputSystem);
      await add(_scoringSystem);
      await add(_powerUpSystem);
      
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
      case PlayerStateStatus.loaded:
        _handlePlayerLoaded(playerState);
        break;
      case PlayerStateStatus.updating:
        _handlePlayerUpdating(playerState);
        break;
      case PlayerStateStatus.error:
        debugPrint('❌ Player state error: ${playerState.errorMessage}');
        break;
      default:
        break;
    }

    // Handle achievement unlocks
    if (playerState.hasUnseenAchievements && playerState.recentUnlocks.isNotEmpty) {
      _handleAchievementUnlocks(playerState.recentUnlocks);
    }
  }

  /// Handle UI state changes from the cubit
  void _handleUIStateChange(UIState uiState) {
    if (!_isInitialized) return;

    // Handle audio settings changes
    if (uiState.musicEnabled) {
      _audioService.resumeMusic();
    } else {
      _audioService.pauseMusic();
    }

    // Handle performance mode changes
    _applyPerformanceSettings(uiState.performanceMode);
    
    // Handle visual settings
    _applyVisualSettings(uiState);
  }

  // ========================================
  // GAME STATE HANDLERS
  // ========================================

  void _handleGamePlaying(GameState gameState) {
    _isPaused = false;
    
    // Update game world with current state
    _gameWorld.updateFromGameState(gameState);
    
    // Resume background music
    _audioService.playMusic('game_background');
  }

  void _handleGamePaused(GameState gameState) {
    _isPaused = true;
    
    // Pause background music
    _audioService.pauseMusic();
    
    // Save game state
    _gameCubit.saveGame();
  }

  void _handleGameOver(GameState gameState) {
    _isPaused = true;
    
    // Play game over sound
    _audioService.playSfx('game_over');
    
    // Stop background music
    _audioService.stopMusic();
    
    // Trigger game over effects
    _gameWorld.triggerGameOverEffect();
  }

  void _handleGameError(String errorMessage) {
    _isPaused = true;
    
    // Show error overlay
    _uiCubit.showError('Game Error: $errorMessage');
    
    // Attempt to save current state
    try {
      _gameCubit.saveGame();
    } catch (e) {
      debugPrint('Failed to save game after error: $e');
    }
  }

  void _handlePlayerLoaded(PlayerState playerState) {
    // Update UI with player stats
    _updatePlayerDisplay(playerState);
  }

  void _handlePlayerUpdating(PlayerState playerState) {
    // Show loading indicator if needed
    if (playerState.coinsEarned > 0) {
      _showCoinsEarnedEffect(playerState.coinsEarned);
    }
  }

  void _handleAchievementUnlocks(List<Achievement> achievements) {
    for (final achievement in achievements) {
      _showAchievementUnlockEffect(achievement);
    }
  }

  // ========================================
  // PERFORMANCE OPTIMIZATION
  // ========================================

  void _monitorPerformance(double dt) {
    // Monitor frame time for performance issues
    if (dt > 0.020) { // More than 20ms per frame (50 FPS)
      debugPrint('⚠️ Performance warning: Frame time ${(dt * 1000).toStringAsFixed(1)}ms');
    }
  }

  void _updateGameLogic(double dt) {
    // Update game systems in order
    _inputSystem.update(dt);
    _scoringSystem.update(dt);
    _powerUpSystem.update(dt);
    
    // Update game world last
    _gameWorld.update(dt);
  }

  void _optimizeRenderingPerformance(Canvas canvas) {
    // Implement rendering optimizations
    // - Culling off-screen objects
    // - Batching similar render calls
    // - Using object pools for frequently created/destroyed objects
  }

  void _applyPerformanceSettings(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.quality:
        _setQualitySettings();
        break;
      case PerformanceMode.balanced:
        _setBalancedSettings();
        break;
      case PerformanceMode.performance:
        _setPerformanceSettings();
        break;
    }
  }

  void _setQualitySettings() {
    // Enable all visual effects
    _gameWorld.setParticlesEnabled(true);
    _gameWorld.setAnimationsEnabled(true);
    _gameWorld.setShadowsEnabled(true);
  }

  void _setBalancedSettings() {
    // Moderate visual effects
    _gameWorld.setParticlesEnabled(true);
    _gameWorld.setAnimationsEnabled(true);
    _gameWorld.setShadowsEnabled(false);
  }

  void _setPerformanceSettings() {
    // Minimal visual effects for best performance
    _gameWorld.setParticlesEnabled(false);
    _gameWorld.setAnimationsEnabled(true);
    _gameWorld.setShadowsEnabled(false);
  }

  void _applyVisualSettings(UIState uiState) {
    _gameWorld.setParticlesEnabled(uiState.particlesEnabled);
    _gameWorld.setAnimationsEnabled(uiState.animationsEnabled);
    _gameWorld.setShadowsEnabled(uiState.shadowsEnabled);
  }

  // ========================================
  // RESPONSIVE DESIGN
  // ========================================

  void _updateComponentsForNewSize(GameConfig config) {
    debugPrint('📱 Updating components for new screen size');
    
    // Update game world for new screen size
    _gameWorld.updateSize(config);
    
    // Update input system for new touch areas
    _inputSystem.updateTouchAreas(config);
    
    // Update UI elements
    _updateUIForNewSize(config);
  }

  void _updateUIForNewSize(GameConfig config) {
    // Update UI elements that depend on screen size
    // This would coordinate with Flutter UI overlays
  }

  // ========================================
  // VISUAL EFFECTS
  // ========================================

  void _updatePlayerDisplay(PlayerState playerState) {
    // Update player stats display in game world
    _gameWorld.updatePlayerStats(playerState.playerStats);
  }

  void _showCoinsEarnedEffect(int coinsEarned) {
    // Show floating coin animation
    _gameWorld.showCoinsEarned(coinsEarned);
    
    // Play coin sound
    _audioService.playSfx('coins_earned');
  }

  void _showAchievementUnlockEffect(Achievement achievement) {
    // Show achievement unlock animation
    _gameWorld.showAchievementUnlock(achievement);
    
    // Play achievement sound
    _audioService.playSfx('achievement_unlock');
  }

  // ========================================
  // PUBLIC API
  // ========================================

  /// Pause the game
  void pauseGame() {
    if (_isInitialized && !_isPaused) {
      _gameCubit.pauseGame();
    }
  }

  /// Resume the game
  void resumeGame() {
    if (_isInitialized && _isPaused) {
      _gameCubit.resumeGame();
    }
  }

  /// Check if game is initialized
  bool get isInitialized => _isInitialized;

  /// Check if game is paused
  bool get isPaused => _isPaused;

  /// Get current game configuration
  GameConfig? get currentConfig => _currentConfig;

  // ========================================
  // CLEANUP
  // ========================================

  @override
  void onRemove() {
    // Clean up resources
    _gameWorld.cleanup();
    _inputSystem.cleanup();
    _scoringSystem.cleanup();
    _powerUpSystem.cleanup();
    
    super.onRemove();
  }
}