import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit.dart';
import 'package:puzzle_box/presentation/flame/components/particle_component.dart';
/// Import equatable for GameConfig
import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/game_constants.dart';
import '../../core/services/audio_service.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/performance_utils.dart';
import '../../injection_container.dart';
import 'components/game_world.dart';
import 'systems/input_system.dart';
import 'systems/scoring_system.dart';

/// Configuration class for responsive game design
class GameConfig extends Equatable {
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

  /// Create configuration based on screen size
  factory GameConfig.fromScreenSize(Size screenSize) {
    final deviceType = ResponsiveUtils.getDeviceType();
    final optimalGridSize = ResponsiveUtils.getOptimalGridSize();
    final cellSize = ResponsiveUtils.getOptimalCellSize();
    final scale = ResponsiveUtils.getGameUIScale();
    
    return GameConfig(
      gridSize: optimalGridSize,
      cellSize: cellSize,
      gridSpacing: GameConstants.gridPadding,
      totalGridSize: cellSize * optimalGridSize + GameConstants.gridPadding * 2,
      scale: scale,
      screenSize: screenSize,
    );
  }

  @override
  List<Object> get props => [gridSize, cellSize, gridSpacing, scale, screenSize];
}

/// Main Flame game class following Clean Architecture principles.
/// Acts as the game engine coordinator and integrates with Flutter's state management.
/// Optimized for 60 FPS performance on mid-range devices with <3s cold start.
class BoxHooksGame extends FlameGame 
    with HasCollisionDetection, HasDragEvents, HasTapEvents {
  
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
  Timer? _performanceTimer;
  
  // Memory management
  final Set<Component> _managedComponents = {};
  Timer? _memoryCleanupTimer;
  
  // Input handling
  bool _isInputEnabled = true;
  DateTime? _lastInputTime;

  @override
  Future<void> onLoad() async {
    try {
      PerformanceUtils.markFrameStart();
      developer.log('Initializing BoxHooksGame', name: 'BoxHooksGame');
      
      // Initialize dependencies
      await _initializeDependencies();
      
      // Setup responsive configuration
      _setupResponsiveConfiguration();
      
      // Initialize core systems
      await _initializeSystems();
      
      // Setup performance monitoring
      _setupPerformanceMonitoring();
      
      // Setup memory management
      _setupMemoryManagement();
      
      // Mark as initialized
      _isInitialized = true;
      
      developer.log('BoxHooksGame initialized successfully', name: 'BoxHooksGame');
      PerformanceUtils.markFrameEnd();
      
    } catch (e, stackTrace) {
      developer.log('Failed to initialize BoxHooksGame: $e', 
          name: 'BoxHooksGame', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  void onRemove() {
    _dispose();
    super.onRemove();
  }

  /// Initialize dependency injection
  Future<void> _initializeDependencies() async {
    try {
      _gameCubit = getIt<GameCubit>();
      _playerCubit = getIt<PlayerCubit>();
      _uiCubit = getIt<UICubit>();
      _audioService = getIt<AudioService>();
      
      developer.log('Dependencies initialized', name: 'BoxHooksGame');
    } catch (e) {
      developer.log('Failed to initialize dependencies: $e', name: 'BoxHooksGame');
      rethrow;
    }
  }

  /// Setup responsive configuration based on screen size
  void _setupResponsiveConfiguration() {
    final screenSize = camera.visibleWorldRect.size;
    _currentConfig = GameConfig.fromScreenSize(Size(screenSize.x, screenSize.y));
    
    developer.log('Game config: ${_currentConfig!.gridSize}x${_currentConfig!.gridSize} '
        'cells @ ${_currentConfig!.cellSize.toStringAsFixed(1)}px each', 
        name: 'BoxHooksGame');
  }

  /// Initialize core game systems
  Future<void> _initializeSystems() async {
    if (_currentConfig == null) {
      throw StateError('Configuration must be set before initializing systems');
    }

    // Initialize game world
    _gameWorld = GameWorld(
      gridSize: _currentConfig!.gridSize,
      cellSize: _currentConfig!.cellSize,
      gameCubit: _gameCubit,
      playerCubit: _playerCubit,
    );
    await add(_gameWorld);
    _managedComponents.add(_gameWorld);

    // Initialize input system
    _inputSystem = InputSystem(
      gameWorld: _gameWorld,
      gameCubit: _gameCubit,
    );
    await add(_inputSystem);
    _managedComponents.add(_inputSystem);

    // Initialize scoring system
    _scoringSystem = ScoringSystem(
      gameWorld: _gameWorld,
      gameCubit: _gameCubit,
      playerCubit: _playerCubit,
    );
    await add(_scoringSystem);
    _managedComponents.add(_scoringSystem);

    // Initialize power-up system
    _powerUpSystem = PowerUpSystem(
      gameWorld: _gameWorld,
      gameCubit: _gameCubit,
      playerCubit: _playerCubit,
    );
    await add(_powerUpSystem);
    _managedComponents.add(_powerUpSystem);

    developer.log('Core systems initialized', name: 'BoxHooksGame');
  }

  /// Setup performance monitoring for 60 FPS optimization
  void _setupPerformanceMonitoring() {
    if (!GameConstants.enablePerformanceMonitoring) return;

    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePerformanceMetrics();
    });

    developer.log('Performance monitoring enabled', name: 'BoxHooksGame');
  }

  /// Setup memory management and cleanup
  void _setupMemoryManagement() {
    // Periodic memory cleanup every 30 seconds
    _memoryCleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _performMemoryCleanup();
    });

    developer.log('Memory management enabled', name: 'BoxHooksGame');
  }

  @override
  void update(double dt) {
    if (!_isInitialized || _isDisposed || _isPaused) return;

    try {
      // Record frame timing for performance monitoring
      _recordFrameTiming();
      
      // Limit frame rate for consistent performance
      if (_shouldSkipFrame(dt)) return;

      // Update core game logic
      super.update(dt);
      
      // Update custom systems
      _updateGameSystems(dt);
      
    } catch (e) {
      developer.log('Error in game update: $e', name: 'BoxHooksGame');
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_isInitialized || _isDisposed) return;

    try {
      super.render(canvas);
      
      // Render performance overlay in debug mode
      if (GameConstants.enableDebugMode) {
        _renderDebugOverlay(canvas);
      }
      
    } catch (e) {
      developer.log('Error in game render: $e', name: 'BoxHooksGame');
    }
  }

  /// Record frame timing for performance monitoring
  void _recordFrameTiming() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameTime = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      PerformanceUtils.recordFrameTime(frameTime);
      
      // Track frame times for local monitoring
      _frameTimes.add(frameTime);
      if (_frameTimes.length > 60) { // Keep last 60 frames (1 second at 60 FPS)
        _frameTimes.removeAt(0);
      }
    }
    _lastFrameTime = now;
    _frameCount++;
  }

  /// Check if frame should be skipped for performance
  bool _shouldSkipFrame(double dt) {
    // Skip frame if we're running too fast (over 60 FPS)
    if (dt < GameConstants.targetFrameTime.inMicroseconds / 1000000.0) {
      return true;
    }
    
    // Skip frame if performance is poor
    if (_frameTimes.isNotEmpty) {
      final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
      if (avgFrameTime > GameConstants.criticalFrameTime.inMilliseconds) {
        return _frameCount % 2 == 0; // Skip every other frame
      }
    }
    
    return false;
  }

  /// Update custom game systems
  void _updateGameSystems(double dt) {
    try {
      // Update systems in order of priority
      _inputSystem.updateSystem(dt);
      _gameWorld.updateSystem(dt);
      _scoringSystem.updateSystem(dt);
      _powerUpSystem.updateSystem(dt);
      
    } catch (e) {
      developer.log('Error updating game systems: $e', name: 'BoxHooksGame');
    }
  }

  /// Update performance metrics
  void _updatePerformanceMetrics() {
    if (_frameTimes.isEmpty) return;

    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final fps = 1000.0 / avgFrameTime;
    
    PerformanceUtils.recordFrameTime(avgFrameTime);
    
    // Log performance warnings
    if (fps < GameConstants.lowPerformanceThreshold) {
      developer.log('Performance warning: ${fps.toStringAsFixed(1)} FPS', 
          name: 'BoxHooksGame');
    }
  }

  /// Perform memory cleanup
  void _performMemoryCleanup() {
    try {
      // Remove inactive components
      final inactiveComponents = children.where((c) => 
          c.isMounted == false || c.isRemoved || 
          (c is ParticleComponent && c.isExpired)
      ).toList();
      
      for (final component in inactiveComponents) {
        remove(component);
      }
      
      // Clear cached resources
      PerformanceUtils.clearCache();
      
      developer.log('Memory cleanup completed. Removed ${inactiveComponents.length} components', 
          name: 'BoxHooksGame');
      
    } catch (e) {
      developer.log('Error during memory cleanup: $e', name: 'BoxHooksGame');
    }
  }

  /// Render debug overlay
  void _renderDebugOverlay(Canvas canvas) {
    if (_frameTimes.isEmpty) return;
    
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final fps = 1000.0 / avgFrameTime;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'FPS: ${fps.toStringAsFixed(1)}\n'
              'Frame: ${avgFrameTime.toStringAsFixed(1)}ms\n'
              'Components: ${children.length}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 50));
  }

  // ========================================
  // INPUT HANDLING
  // ========================================

  @override
  bool onDragStart(DragStartEvent event) {
    if (!_isInputEnabled || _isPaused) return false;
    
    _lastInputTime = DateTime.now();
    return _inputSystem.handleDragStart(event.localPosition);
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (!_isInputEnabled || _isPaused) return false;
    
    return _inputSystem.handleDragUpdate(event.localPosition, event.localDelta);
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    if (!_isInputEnabled || _isPaused) return false;
    
    return _inputSystem.handleDragEnd(event.localPosition);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!_isInputEnabled || _isPaused) return false;
    
    _lastInputTime = DateTime.now();
    return _inputSystem.handleTap(event.localPosition);
  }

  // ========================================
  // GAME CONTROL METHODS
  // ========================================

  /// Pause the game
  void pauseGame() {
    if (_isPaused) return;
    
    _isPaused = true;
    pauseEngine();
    _audioService.pauseMusic();
    
    developer.log('Game paused', name: 'BoxHooksGame');
  }

  /// Resume the game
  void resumeGame() {
    if (!_isPaused) return;
    
    _isPaused = false;
    resumeEngine();
    _audioService.resumeMusic();
    
    developer.log('Game resumed', name: 'BoxHooksGame');
  }

  /// Reset the game
  Future<void> resetGame() async {
    try {
      developer.log('Resetting game', name: 'BoxHooksGame');
      
      // Clear all dynamic components
      for (final component in _managedComponents) {
        component.removeFromParent();
      }
      _managedComponents.clear();
      
      // Reinitialize systems
      await _initializeSystems();
      
      // Reset state
      _frameCount = 0;
      _frameTimes.clear();
      
      developer.log('Game reset completed', name: 'BoxHooksGame');
      
    } catch (e) {
      developer.log('Error resetting game: $e', name: 'BoxHooksGame');
    }
  }

  /// Dispose of all resources
  void _dispose() {
    if (_isDisposed) return;
    
    developer.log('Disposing BoxHooksGame', name: 'BoxHooksGame');
    
    _isDisposed = true;
    _isInitialized = false;
    
    // Cancel timers
    _performanceTimer?.cancel();
    _memoryCleanupTimer?.cancel();
    
    // Dispose components
    for (final component in _managedComponents) {
      if (component.isMounted) {
        component.removeFromParent();
      }
    }
    _managedComponents.clear();
    
    // Clear performance data
    _frameTimes.clear();
    
    developer.log('BoxHooksGame disposed', name: 'BoxHooksGame');
  }

  // ========================================
  // GETTERS
  // ========================================

  /// Check if game is initialized
  bool get isInitialized => _isInitialized;

  /// Check if game is paused
  bool get isPaused => _isPaused;

  /// Get current game configuration
  GameConfig? get config => _currentConfig;

  /// Get current FPS
  double get currentFPS {
    if (_frameTimes.isEmpty) return 0.0;
    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    return 1000.0 / avgFrameTime;
  }

  /// Check if input is enabled
  bool get isInputEnabled => _isInputEnabled;

  /// Enable/disable input
  set inputEnabled(bool enabled) => _isInputEnabled = enabled;
}

