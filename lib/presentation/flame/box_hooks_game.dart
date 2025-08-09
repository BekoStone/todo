import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart' hide Vector2;
import 'package:flutter/material.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/presentation/flame/components/particle_component.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/audio_service.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/performance_utils.dart' hide Vector2;
import '../../injection_container.dart';
import 'components/game_world.dart';
import 'systems/input_system.dart';
import 'systems/scoring_system.dart';
import 'systems/power_up_system.dart';

/// Configuration class for responsive game design
class GameConfig {
  final int gridSize;
  final double cellSize;
  final double gridSpacing;
  final double totalGridSize;
  final double scale;
  final Size screenSize;

  const GameConfig({
    required this.gridSize,
    required this.cellSize,
    required this.gridSpacing,
    required this.totalGridSize,
    required this.scale,
    required this.screenSize,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameConfig &&
        other.gridSize == gridSize &&
        other.cellSize == cellSize &&
        other.gridSpacing == gridSpacing &&
        other.scale == scale;
  }

  @override
  int get hashCode {
    return gridSize.hashCode ^
        cellSize.hashCode ^
        gridSpacing.hashCode ^
        scale.hashCode;
  }
}

/// Main Flame game class following Clean Architecture principles.
/// Acts as the game engine coordinator and integrates with Flutter's state management.
/// Optimized for 60 FPS performance on mid-range devices with <3s cold start.
class BoxHooksGame extends FlameGame with HasCollisionDetection {
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

  // Game state tracking
  bool _isInitialized = false;
  bool _isPaused = false;
  bool _isDisposed = false;
  
  // Responsive design
  GameConfig? _currentConfig;
  
  // Performance monitoring
  final List<double> _frameTimes = [];
  DateTime? _lastFrameTime;
  int _frameCount = 0;
  
  // Stream subscriptions for cleanup
  final List<StreamSubscription> _subscriptions = [];
  
  // Component pools for memory optimization
  final Map<Type, List<Component>> _componentPools = {};

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    try {
      developer.log('🎮 Initializing BoxHooksGame', name: 'BoxHooksGame');
      
      // Initialize performance monitoring
      PerformanceUtils.initialize();
      
      // Initialize dependencies
      await _initializeDependencies();
      
      // Setup responsive configuration
      await _setupResponsiveDesign();
      
      // Initialize game components
      await _initializeGameComponents();
      
      // Setup event listeners
      await _setupEventListeners();
      
      // Initialize object pools
      _initializeObjectPools();
      
      _isInitialized = true;
      
      // Mark cold start as complete
      PerformanceUtils.markColdStartComplete();
      
      developer.log('✅ BoxHooksGame initialized successfully', name: 'BoxHooksGame');
      
    } catch (e, stackTrace) {
      developer.log('❌ Failed to initialize BoxHooksGame: $e', 
          name: 'BoxHooksGame', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    
    if (_isDisposed) return;
    
    try {
      // Recalculate responsive configuration
      final newConfig = _calculateGameConfig(canvasSize.toSize());
      
      if (newConfig != _currentConfig) {
        _currentConfig = newConfig;
        _updateComponentsForNewSize(newConfig);
        developer.log('📱 Screen resized: ${canvasSize.x}x${canvasSize.y}', name: 'BoxHooksGame');
      }
    } catch (e) {
      developer.log('Failed to handle screen resize: $e', name: 'BoxHooksGame');
    }
  }

  @override
  void update(double dt) {
    if (_isDisposed || !_isInitialized) return;
    
    try {
      // Performance monitoring
      _monitorPerformance(dt);
      
      // Update game systems only when not paused
      if (!_isPaused) {
        _updateGameSystems(dt);
      }
      
      super.update(dt);
      
    } catch (e) {
      developer.log('Error in game update: $e', name: 'BoxHooksGame');
      // Don't rethrow to prevent game crash
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isDisposed || !_isInitialized) return;
    
    try {
      super.render(canvas);
      
      // Apply rendering optimizations
      _optimizeRendering(canvas);
      
    } catch (e) {
      developer.log('Error in game render: $e', name: 'BoxHooksGame');
    }
  }

  @override
  void onRemove() {
    _dispose();
    super.onRemove();
  }

  // ========================================
  // INITIALIZATION
  // ========================================

  /// Initialize all dependencies from the service locator
  Future<void> _initializeDependencies() async {
    try {
      _gameCubit = getIt<GameCubit>();
      _playerCubit = getIt<PlayerCubit>();
      _uiCubit = getIt<UICubit>();
      _audioService = getIt<AudioService>();
      
      developer.log('🔧 Dependencies initialized', name: 'BoxHooksGame');
    } catch (e) {
      developer.log('❌ Failed to initialize dependencies: $e', name: 'BoxHooksGame');
      rethrow;
    }
  }

  /// Setup responsive design configuration
  Future<void> _setupResponsiveDesign() async {
    final screenSize = size.toSize();
    _currentConfig = _calculateGameConfig(screenSize);
    
    developer.log('📱 Responsive config: ${_currentConfig!.gridSize}x${_currentConfig!.gridSize} grid, '
        '${_currentConfig!.cellSize.toStringAsFixed(1)} cell size', name: 'BoxHooksGame');
  }

  /// Calculate game configuration based on screen size
  GameConfig _calculateGameConfig(Size screenSize) {
    // Use responsive utils to calculate optimal configuration
    final isTablet = screenSize.shortestSide > AppConstants.tabletBreakpoint;
    final isMobile = screenSize.shortestSide <= AppConstants.mobileBreakpoint;
    
    // Grid size based on screen size
    final gridSize = isTablet ? 12 : (isMobile ? 8 : 10);
    
    // Calculate cell size to fit screen with padding
    final availableWidth = screenSize.width * 0.85; // 85% of screen width
    final availableHeight = screenSize.height * 0.6; // 60% of screen height
    final availableSize = math.min(availableWidth, availableHeight);
    
    const spacing = AppConstants.defaultPadding / 2;
    final totalSpacing = (gridSize - 1) * spacing;
    final cellSize = (availableSize - totalSpacing) / gridSize;
    
    final scale = screenSize.width / 375.0; // Base on iPhone width
    
    return GameConfig(
      gridSize: gridSize,
      cellSize: cellSize,
      gridSpacing: spacing,
      totalGridSize: cellSize * gridSize + totalSpacing,
      scale: scale.clamp(0.8, 2.0),
      screenSize: screenSize,
    );
  }

  /// Initialize and configure all game components
  Future<void> _initializeGameComponents() async {
    try {
      final config = _currentConfig!;
      
      // Initialize game world (main game logic container)
      _gameWorld = GameWorld(
        gridSize: config.gridSize,
        cellSize: config.cellSize,
        gameCubit: _gameCubit,
        playerCubit: _playerCubit,
      );
      
      // Initialize input system
      _inputSystem = InputSystem(
        gameWorld: _gameWorld,
        gameCubit: _gameCubit,
      );
      
      // Initialize scoring system
      _scoringSystem = ScoringSystem(
        gameWorld: _gameWorld,
        gameCubit: _gameCubit,
        playerCubit: _playerCubit,
      );
      
      // Initialize power-up system
      _powerUpSystem = PowerUpSystem(
        gameWorld: _gameWorld,
        gameCubit: _gameCubit,
        playerCubit: _playerCubit,
      );
      
      // Add components in dependency order
      await add(_gameWorld);
      await add(_inputSystem);
      await add(_scoringSystem);
      await add(_powerUpSystem);
      
      developer.log('🎮 Game components initialized', name: 'BoxHooksGame');
    } catch (e) {
      developer.log('❌ Failed to initialize game components: $e', name: 'BoxHooksGame');
      rethrow;
    }
  }

  /// Setup listeners for cubit state changes
  Future<void> _setupEventListeners() async {
    try {
      // Listen to game state changes
      final gameSubscription = _gameCubit.stream.listen(_handleGameStateChange);
      _subscriptions.add(gameSubscription);

      // Listen to player state changes  
      final playerSubscription = _playerCubit.stream.listen(_handlePlayerStateChange);
      _subscriptions.add(playerSubscription);

      // Listen to UI state changes
      final uiSubscription = _uiCubit.stream.listen(_handleUIStateChange);
      _subscriptions.add(uiSubscription);
      
      developer.log('👂 Event listeners setup', name: 'BoxHooksGame');
    } catch (e) {
      developer.log('❌ Failed to setup event listeners: $e', name: 'BoxHooksGame');
      rethrow;
    }
  }

  /// Initialize object pools for memory optimization
  void _initializeObjectPools() {
    // Initialize pools for frequently created/destroyed objects
    _componentPools[ParticleComponent] = [];
    _componentPools[EffectComponent] = [];
    
    developer.log('🏊 Object pools initialized', name: 'BoxHooksGame');
  }

  // ========================================
  // STATE CHANGE HANDLERS
  // ========================================

  /// Handle game state changes from the cubit
  void _handleGameStateChange(GameState gameState) {
    if (!_isInitialized || _isDisposed) return;

    try {
      switch (gameState.status) {
        case GameStateStatus.initial:
          _handleGameInitial();
          break;
        case GameStateStatus.loading:
          _handleGameLoading();
          break;
        case GameStateStatus.playing:
          _handleGamePlaying(gameState);
          break;
        case GameStateStatus.paused:
          _handleGamePaused();
          break;
        case GameStateStatus.gameOver:
          _handleGameOver(gameState);
          break;
        case GameStateStatus.error:
          _handleGameError(gameState.errorMessage ?? 'Unknown error');
          break;
      }
      
      // Update game world with new state
      _gameWorld.updateFromGameState(gameState);
      
    } catch (e) {
      developer.log('Error handling game state change: $e', name: 'BoxHooksGame');
    }
  }

  /// Handle player state changes from the cubit
  void _handlePlayerStateChange(PlayerState playerState) {
    if (!_isInitialized || _isDisposed) return;

    try {
      switch (playerState.status) {
        case PlayerStateStatus.loaded:
          _handlePlayerLoaded(playerState);
          break;
        case PlayerStateStatus.updating:
          _handlePlayerUpdating(playerState);
          break;
        case PlayerStateStatus.error:
          developer.log('Player error: ${playerState.errorMessage}', name: 'BoxHooksGame');
          break;
        default:
          break;
      }
      
      // Check for achievement unlocks
      if (playerState.recentUnlocks.isNotEmpty) {
        _handleAchievementUnlocks(playerState.recentUnlocks);
      }
      
      // Update game world with player stats
      _gameWorld.updatePlayerStats(playerState.playerStats);
      
    } catch (e) {
      developer.log('Error handling player state change: $e', name: 'BoxHooksGame');
    }
  }

  /// Handle UI state changes from the cubit
  void _handleUIStateChange(UIState uiState) {
    if (!_isInitialized || _isDisposed) return;

    try {
      // Apply performance settings
      _applyPerformanceSettings(uiState.performanceMode);
      
      // Apply visual settings
      _applyVisualSettings(uiState);
      
      // Handle audio settings
      if (uiState.musicEnabled) {
        _audioService.resumeMusic();
      } else {
        _audioService.pauseMusic();
      }
      
    } catch (e) {
      developer.log('Error handling UI state change: $e', name: 'BoxHooksGame');
    }
  }

  // ========================================
  // SPECIFIC STATE HANDLERS
  // ========================================

  void _handleGameInitial() {
    developer.log('🎮 Game state: Initial', name: 'BoxHooksGame');
  }

  void _handleGameLoading() {
    developer.log('🎮 Game state: Loading', name: 'BoxHooksGame');
  }

  void _handleGamePlaying(GameState gameState) {
    _isPaused = false;
    
    // Start background music if not playing
    if (!_audioService.isMusicPlaying) {
      _audioService.playMusic('game_background');
    }
    
    developer.log('🎮 Game state: Playing - Score: ${gameState.score}', name: 'BoxHooksGame');
  }

  void _handleGamePaused() {
    _isPaused = true;
    
    // Pause background music
    _audioService.pauseMusic();
    
    developer.log('🎮 Game state: Paused', name: 'BoxHooksGame');
  }

  void _handleGameOver(GameState gameState) {
    _isPaused = true;
    
    // Play game over sound
    _audioService.playSfx('game_over');
    
    // Stop background music
    _audioService.stopMusic();
    
    // Trigger game over effects
    _gameWorld.triggerGameOverEffect();
    
    developer.log('🎮 Game Over - Final Score: ${gameState.score}', name: 'BoxHooksGame');
  }

  void _handleGameError(String errorMessage) {
    _isPaused = true;
    
    developer.log('❌ Game Error: $errorMessage', name: 'BoxHooksGame');
    
    // Attempt to save current state
    try {
      if (_gameCubit.canSaveGame()) {
        _gameCubit.forceSaveGame();
      }
    } catch (e) {
      developer.log('Failed to save game after error: $e', name: 'BoxHooksGame');
    }
  }

  void _handlePlayerLoaded(PlayerState playerState) {
    developer.log('👤 Player loaded: ${playerState.playerStats?.currentCoins ?? 0} coins', 
        name: 'BoxHooksGame');
  }

  void _handlePlayerUpdating(PlayerState playerState) {
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

  /// Monitor frame performance for optimization
  void _monitorPerformance(double dt) {
    _frameCount++;
    final now = DateTime.now();
    
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      _frameTimes.add(frameTime);
      
      // Keep only recent frame times (last 60 frames)
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
      
      // Log performance warnings for frame drops
      if (frameTime > 20.0) { // More than 20ms (50 FPS)
        developer.log('⚠️ Frame drop: ${frameTime.toStringAsFixed(1)}ms', name: 'Performance');
      }
    }
    
    _lastFrameTime = now;
    
    // Log performance stats every 5 seconds
    if (_frameCount % 300 == 0) {
      _logPerformanceStats();
    }
  }

  /// Log performance statistics
  void _logPerformanceStats() {
    if (_frameTimes.isNotEmpty) {
      final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
      final avgFPS = 1000.0 / avgFrameTime;
      
      developer.log('📊 Performance: ${avgFPS.toStringAsFixed(1)} FPS avg, '
          '${avgFrameTime.toStringAsFixed(1)}ms frame time', name: 'Performance');
    }
  }

  /// Update all game systems
  void _updateGameSystems(double dt) {
    try {
      // Update systems in dependency order
      _inputSystem.update(dt);
      _scoringSystem.update(dt);
      _powerUpSystem.update(dt);
      
      // Game world updates last to incorporate all system changes
      _gameWorld.update(dt);
      
    } catch (e) {
      developer.log('Error updating game systems: $e', name: 'BoxHooksGame');
    }
  }

  /// Apply rendering optimizations
  void _optimizeRendering(Canvas canvas) {
    // Implement rendering optimizations:
    // - Culling off-screen objects
    // - Batching similar render calls
    // - Using object pools for particles/effects
    
    // Clear unused objects from pools periodically
    if (_frameCount % 600 == 0) { // Every 10 seconds at 60 FPS
      _cleanupObjectPools();
    }
  }

  /// Apply performance settings based on mode
  void _applyPerformanceSettings(PerformanceMode mode) {
    try {
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
    } catch (e) {
      developer.log('Error applying performance settings: $e', name: 'BoxHooksGame');
    }
  }

  void _setQualitySettings() {
    _gameWorld.setParticlesEnabled(true);
    _gameWorld.setAnimationsEnabled(true);
    _gameWorld.setShadowsEnabled(true);
  }

  void _setBalancedSettings() {
    _gameWorld.setParticlesEnabled(true);
    _gameWorld.setAnimationsEnabled(true);
    _gameWorld.setShadowsEnabled(false);
  }

  void _setPerformanceSettings() {
    _gameWorld.setParticlesEnabled(false);
    _gameWorld.setAnimationsEnabled(true);
    _gameWorld.setShadowsEnabled(false);
  }

  /// Apply visual settings from UI state
  void _applyVisualSettings(UIState uiState) {
    _gameWorld.setParticlesEnabled(uiState.particlesEnabled);
    _gameWorld.setAnimationsEnabled(uiState.animationsEnabled);
    _gameWorld.setShadowsEnabled(uiState.shadowsEnabled);
  }

  // ========================================
  // RESPONSIVE DESIGN
  // ========================================

  /// Update components for new screen size
  void _updateComponentsForNewSize(GameConfig config) {
    try {
      developer.log('📱 Updating components for new screen size', name: 'BoxHooksGame');
      
      // Update game world
      _gameWorld.updateSize(config);
      
      // Update input system for new touch areas
      _inputSystem.updateTouchAreas(config);
      
      // Update UI scaling
      _updateUIForNewSize(config);
      
    } catch (e) {
      developer.log('Error updating components for new size: $e', name: 'BoxHooksGame');
    }
  }

  void _updateUIForNewSize(GameConfig config) {
    // Update UI elements that depend on screen size
    // This would coordinate with Flutter UI overlays
  }

  // ========================================
  // VISUAL EFFECTS
  // ========================================

  /// Show coins earned effect
  void _showCoinsEarnedEffect(int coinsEarned) {
    try {
      _gameWorld.showCoinsEarned(coinsEarned);
      _audioService.playSfx('coins_earned');
    } catch (e) {
      developer.log('Error showing coins effect: $e', name: 'BoxHooksGame');
    }
  }

  /// Show achievement unlock effect
  void _showAchievementUnlockEffect(Achievement achievement) {
    try {
      _gameWorld.showAchievementUnlock(achievement);
      _audioService.playAchievementSound();
    } catch (e) {
      developer.log('Error showing achievement effect: $e', name: 'BoxHooksGame');
    }
  }

  // ========================================
  // MEMORY MANAGEMENT
  // ========================================

  /// Clean up object pools to prevent memory leaks
  void _cleanupObjectPools() {
    for (final pool in _componentPools.values) {
      // Keep only a reasonable number of pooled objects
      if (pool.length > 50) {
        pool.removeRange(25, pool.length);
      }
    }
  }

  /// Get object from pool or create new one
  T getPooledObject<T extends Component>(T Function() creator) {
    final pool = _componentPools[T];
    if (pool != null && pool.isNotEmpty) {
      return pool.removeLast() as T;
    }
    return creator();
  }

  /// Return object to pool for reuse
  void returnToPool<T extends Component>(T object) {
    final pool = _componentPools[T];
    if (pool != null && pool.length < 50) {
      // Reset object state before returning to pool
      object.removeFromParent();
      pool.add(object);
    }
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

  /// Force save the current game
  Future<bool> saveGame() async {
    if (_isInitialized && _gameCubit.canSaveGame()) {
      return await _gameCubit.forceSaveGame();
    }
    return false;
  }

  /// Check if game is initialized
  bool get isInitialized => _isInitialized;

  /// Check if game is paused
  bool get isPaused => _isPaused;

  /// Get current game configuration
  GameConfig? get currentConfig => _currentConfig;

  /// Get current performance metrics
  Map<String, dynamic> get performanceMetrics {
    return {
      'averageFrameTime': _frameTimes.isNotEmpty 
        ? _frameTimes.reduce((a, b) => a + b) / _frameTimes.length 
        : 0.0,
      'averageFPS': _frameTimes.isNotEmpty 
        ? 1000.0 / (_frameTimes.reduce((a, b) => a + b) / _frameTimes.length)
        : 0.0,
      'frameCount': _frameCount,
      'isInitialized': _isInitialized,
      'isPaused': _isPaused,
    };
  }

  // ========================================
  // CLEANUP
  // ========================================

  /// Dispose of all resources
  void _dispose() {
    if (_isDisposed) return;
    
    try {
      developer.log('🧹 Disposing BoxHooksGame', name: 'BoxHooksGame');
      
      _isDisposed = true;
      
      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();
      
      // Clean up components
      _gameWorld.cleanup();
      _inputSystem.cleanup();
      _scoringSystem.cleanup();
      _powerUpSystem.cleanup();
      
      // Clear object pools
      _componentPools.clear();
      
      // Clear frame time tracking
      _frameTimes.clear();
      
      developer.log('✅ BoxHooksGame disposed', name: 'BoxHooksGame');
      
    } catch (e) {
      developer.log('Error disposing BoxHooksGame: $e', name: 'BoxHooksGame');
    }
  }
}