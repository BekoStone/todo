import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/utils/performance_utils.dart' hide Vector2;
import '../../../core/services/audio_service.dart';
import '../../../injection_container.dart';
import '../components/game_world.dart';
import '../components/block_component.dart';
import '../components/particle_component.dart';

/// Power-up system for managing power-up activation, effects, and cooldowns.
/// Handles power-up logic, visual effects, and integration with game mechanics.
/// Follows Clean Architecture by coordinating between presentation and domain layers.
class PowerUpSystem extends Component with HasGameRef {
  // Dependencies
  final GameWorld gameWorld;
  final GameCubit gameCubit;
  final PlayerCubit playerCubit;
  late final AudioService _audioService;
  
  // Power-up state
  final Map<String, PowerUp> _availablePowerUps = {};
  final Map<String, int> _powerUpCounts = {};
  final Map<String, DateTime> _cooldowns = {};
  PowerUp? _activePowerUp;
  bool _isWaitingForTarget = false;
  
  // Active effects
  final List<PowerUpEffect> _activeEffects = {};
  final Map<String, Timer> _effectTimers = {};
  
  // Visual indicators
  final Map<String, Component> _powerUpIndicators = {};
  
  // Performance tracking
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  PowerUpSystem({
    required this.gameWorld,
    required this.gameCubit,
    required this.playerCubit,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    _audioService = getIt<AudioService>();
    await _initializePowerUps();
    
    debugPrint('⚡ PowerUpSystem loaded');
  }

  /// Initialize available power-ups
  Future<void> _initializePowerUps() async {
    // Register all available power-ups
    _registerPowerUp(const PowerUp(
      id: 'hammer',
      name: 'Hammer',
      description: 'Destroy a single block on the grid',
      icon: 'hammer',
      rarity: PowerUpRarity.common,
      cooldown: Duration(seconds: 30),
      uses: 1,
    ));
    
    _registerPowerUp(const PowerUp(
      id: 'bomb',
      name: 'Bomb',
      description: 'Clear a 3x3 area around target',
      icon: 'bomb',
      rarity: PowerUpRarity.rare,
      cooldown: Duration(seconds: 60),
      uses: 1,
    ));
    
    _registerPowerUp(const PowerUp(
      id: 'line_clear',
      name: 'Line Clear',
      description: 'Clear a complete row or column',
      icon: 'line_clear',
      rarity: PowerUpRarity.common,
      cooldown: Duration(seconds: 45),
      uses: 1,
    ));
    
    _registerPowerUp(const PowerUp(
      id: 'shuffle',
      name: 'Shuffle',
      description: 'Replace current blocks with new ones',
      icon: 'shuffle',
      rarity: PowerUpRarity.common,
      cooldown: Duration(seconds: 90),
      uses: 1,
    ));
    
    _registerPowerUp(const PowerUp(
      id: 'time_freeze',
      name: 'Time Freeze',
      description: 'Pause the timer for 30 seconds',
      icon: 'time_freeze',
      rarity: PowerUpRarity.epic,
      cooldown: Duration(seconds: 120),
      uses: 1,
    ));
    
    _registerPowerUp(const PowerUp(
      id: 'multiplier',
      name: 'Score Multiplier',
      description: '2x score for 60 seconds',
      icon: 'multiplier',
      rarity: PowerUpRarity.rare,
      cooldown: Duration(seconds: 180),
      uses: 1,
    ));
    
    _registerPowerUp(const PowerUp(
      id: 'ghost_block',
      name: 'Ghost Block',
      description: 'Next block can overlap existing blocks',
      icon: 'ghost',
      rarity: PowerUpRarity.epic,
      cooldown: Duration(seconds: 150),
      uses: 1,
    ));
    
    _registerPowerUp(const PowerUp(
      id: 'magnet',
      name: 'Magnet',
      description: 'Automatically place blocks optimally',
      icon: 'magnet',
      rarity: PowerUpRarity.legendary,
      cooldown: Duration(seconds: 300),
      uses: 1,
    ));
    
    // Initialize counts (would be loaded from player data)
    _initializePowerUpCounts();
    
    debugPrint('⚡ Initialized ${_availablePowerUps.length} power-ups');
  }

  /// Register a power-up in the system
  void _registerPowerUp(PowerUp powerUp) {
    _availablePowerUps[powerUp.id] = powerUp;
    _powerUpCounts[powerUp.id] = 0;
  }

  /// Initialize power-up counts (from player data)
  void _initializePowerUpCounts() {
    // This would load from player save data
    _powerUpCounts['hammer'] = 3;
    _powerUpCounts['bomb'] = 1;
    _powerUpCounts['line_clear'] = 2;
    _powerUpCounts['shuffle'] = 2;
    _powerUpCounts['time_freeze'] = 1;
    _powerUpCounts['multiplier'] = 1;
    _powerUpCounts['ghost_block'] = 1;
    _powerUpCounts['magnet'] = 0;
  }

  /// Activate a power-up
  bool activatePowerUp(PowerUp powerUp) {
    if (!canActivatePowerUp(powerUp.id)) {
      debugPrint('❌ Cannot activate power-up: ${powerUp.name}');
      return false;
    }
    
    _performanceMonitor.startTracking('power_up_activation');
    
    // Check if power-up requires target selection
    if (_requiresTargetSelection(powerUp)) {
      _startTargetSelection(powerUp);
    } else {
      _executePowerUp(powerUp, null);
    }
    
    _performanceMonitor.stopTracking('power_up_activation');
    
    debugPrint('⚡ Activated power-up: ${powerUp.name}');
    return true;
  }

  /// Use a power-up by ID
  bool usePowerUp(String powerUpId) {
    final powerUp = _availablePowerUps[powerUpId];
    if (powerUp == null) {
      debugPrint('❌ Power-up not found: $powerUpId');
      return false;
    }
    
    return activatePowerUp(powerUp);
  }

  /// Check if a power-up can be activated
  bool canActivatePowerUp(String powerUpId) {
    final powerUp = _availablePowerUps[powerUpId];
    if (powerUp == null) return false;
    
    // Check if player has this power-up
    if ((_powerUpCounts[powerUpId] ?? 0) <= 0) return false;
    
    // Check cooldown
    if (isOnCooldown(powerUpId)) return false;
    
    // Check if another power-up is active
    if (_activePowerUp != null && _activePowerUp!.id != powerUpId) return false;
    
    return true;
  }

  /// Check if a power-up is on cooldown
  bool isOnCooldown(String powerUpId) {
    final cooldownEnd = _cooldowns[powerUpId];
    if (cooldownEnd == null) return false;
    
    return DateTime.now().isBefore(cooldownEnd);
  }

  /// Get remaining cooldown time
  Duration getRemainingCooldown(String powerUpId) {
    final cooldownEnd = _cooldowns[powerUpId];
    if (cooldownEnd == null) return Duration.zero;
    
    final remaining = cooldownEnd.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Start target selection for power-ups that require it
  void _startTargetSelection(PowerUp powerUp) {
    _activePowerUp = powerUp;
    _isWaitingForTarget = true;
    
    // Visual feedback for target selection
    _showTargetSelectionUI(powerUp);
    
    // Audio feedback
    _audioService.playSound('power_up_select');
    
    debugPrint('🎯 Started target selection for: ${powerUp.name}');
  }

  /// Handle target selection (called from input system)
  void handleTargetSelection(Vector2 worldPosition) {
    if (!_isWaitingForTarget || _activePowerUp == null) return;
    
    final gridPosition = _worldToGridPosition(worldPosition);
    
    if (_isValidTarget(gridPosition, _activePowerUp!)) {
      _executePowerUp(_activePowerUp!, gridPosition);
      _endTargetSelection();
    } else {
      // Invalid target - show feedback
      _showInvalidTargetFeedback(worldPosition);
    }
  }

  /// Cancel target selection
  void cancelTargetSelection() {
    if (!_isWaitingForTarget) return;
    
    _endTargetSelection();
    _audioService.playSound('power_up_cancel');
    
    debugPrint('❌ Cancelled target selection');
  }

  /// End target selection mode
  void _endTargetSelection() {
    _isWaitingForTarget = false;
    _activePowerUp = null;
    _hideTargetSelectionUI();
  }

  /// Execute a power-up effect
  void _executePowerUp(PowerUp powerUp, Vector2? targetPosition) {
    _performanceMonitor.startTracking('power_up_execution');
    
    // Consume the power-up
    _consumePowerUp(powerUp.id);
    
    // Start cooldown
    _startCooldown(powerUp);
    
    // Execute specific power-up logic
    switch (powerUp.id) {
      case 'hammer':
        _executeHammer(targetPosition);
        break;
      case 'bomb':
        _executeBomb(targetPosition);
        break;
      case 'line_clear':
        _executeLineClear(targetPosition);
        break;
      case 'shuffle':
        _executeShuffle();
        break;
      case 'time_freeze':
        _executeTimeFreeze();
        break;
      case 'multiplier':
        _executeMultiplier();
        break;
      case 'ghost_block':
        _executeGhostBlock();
        break;
      case 'magnet':
        _executeMagnet();
        break;
    }
    
    // Visual and audio feedback
    _createPowerUpEffect(powerUp, targetPosition);
    _audioService.playSound('power_up_use');
    
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    _performanceMonitor.stopTracking('power_up_execution');
    
    debugPrint('✅ Executed power-up: ${powerUp.name}');
  }

  /// Execute hammer power-up (destroy single block)
  void _executeHammer(Vector2? targetPosition) {
    if (targetPosition == null) return;
    
    final row = targetPosition.y.toInt();
    final col = targetPosition.x.toInt();
    
    if (_isValidGridPosition(row, col) && 
        gameWorld.gridComponent.occupiedCells[row][col]) {
      
      // Clear the cell
      gameWorld.gridComponent.setCellOccupied(row, col, false);
      
      // Award points for clearing
      gameWorld.scoringSystem.awardPowerUpUsage('hammer', 1);
      
      debugPrint('🔨 Hammer destroyed block at ($col, $row)');
    }
  }

  /// Execute bomb power-up (clear 3x3 area)
  void _executeBomb(Vector2? targetPosition) {
    if (targetPosition == null) return;
    
    final centerRow = targetPosition.y.toInt();
    final centerCol = targetPosition.x.toInt();
    int cellsCleared = 0;
    
    // Clear 3x3 area around target
    for (int row = centerRow - 1; row <= centerRow + 1; row++) {
      for (int col = centerCol - 1; col <= centerCol + 1; col++) {
        if (_isValidGridPosition(row, col) && 
            gameWorld.gridComponent.occupiedCells[row][col]) {
          
          gameWorld.gridComponent.setCellOccupied(row, col, false);
          cellsCleared++;
        }
      }
    }
    
    // Award points based on effectiveness
    gameWorld.scoringSystem.awardPowerUpUsage('bomb', cellsCleared);
    
    debugPrint('💣 Bomb cleared $cellsCleared cells around ($centerCol, $centerRow)');
  }

  /// Execute line clear power-up
  void _executeLineClear(Vector2? targetPosition) {
    if (targetPosition == null) return;
    
    final row = targetPosition.y.toInt();
    final col = targetPosition.x.toInt();
    
    // Clear entire row or column (whichever has more blocks)
    int rowBlocks = 0;
    int colBlocks = 0;
    
    // Count blocks in row
    for (int c = 0; c < gameWorld.gridComponent.gridSize; c++) {
      if (gameWorld.gridComponent.occupiedCells[row][c]) rowBlocks++;
    }
    
    // Count blocks in column
    for (int r = 0; r < gameWorld.gridComponent.gridSize; r++) {
      if (gameWorld.gridComponent.occupiedCells[r][col]) colBlocks++;
    }
    
    if (rowBlocks >= colBlocks) {
      // Clear row
      for (int c = 0; c < gameWorld.gridComponent.gridSize; c++) {
        if (gameWorld.gridComponent.occupiedCells[row][c]) {
          gameWorld.gridComponent.setCellOccupied(row, c, false);
        }
      }
      gameWorld.scoringSystem.awardPowerUpUsage('line_clear', rowBlocks);
      debugPrint('📏 Line clear removed row $row ($rowBlocks blocks)');
    } else {
      // Clear column
      for (int r = 0; r < gameWorld.gridComponent.gridSize; r++) {
        if (gameWorld.gridComponent.occupiedCells[r][col]) {
          gameWorld.gridComponent.setCellOccupied(r, col, false);
        }
      }
      gameWorld.scoringSystem.awardPowerUpUsage('line_clear', colBlocks);
      debugPrint('📏 Line clear removed column $col ($colBlocks blocks)');
    }
  }

  /// Execute shuffle power-up (replace current blocks)
  void _executeShuffle() {
    // Clear current active blocks
    for (final block in gameWorld.activeBlocks.toList()) {
      block.removeFromParent();
    }
    gameWorld.activeBlocks.clear();
    
    // Request new blocks from game cubit
    gameCubit.requestNewBlocks();
    
    gameWorld.scoringSystem.awardPowerUpUsage('shuffle', 3);
    
    debugPrint('🔄 Shuffle replaced all active blocks');
  }

  /// Execute time freeze power-up
  void _executeTimeFreeze() {
    final effect = PowerUpEffect(
      id: 'time_freeze',
      duration: const Duration(seconds: 30),
      onStart: () {
        // Pause timer (would be handled by game logic)
        debugPrint('⏰ Time frozen');
      },
      onEnd: () {
        debugPrint('⏰ Time resumed');
      },
    );
    
    _addActiveEffect(effect);
    gameWorld.scoringSystem.awardPowerUpUsage('time_freeze', 1);
  }

  /// Execute score multiplier power-up
  void _executeMultiplier() {
    final effect = PowerUpEffect(
      id: 'multiplier',
      duration: const Duration(seconds: 60),
      onStart: () {
        // Increase score multiplier (would be handled by scoring system)
        debugPrint('✨ Score multiplier active (2x)');
      },
      onEnd: () {
        debugPrint('✨ Score multiplier ended');
      },
    );
    
    _addActiveEffect(effect);
    gameWorld.scoringSystem.awardPowerUpUsage('multiplier', 1);
  }

  /// Execute ghost block power-up
  void _executeGhostBlock() {
    final effect = PowerUpEffect(
      id: 'ghost_block',
      duration: const Duration(seconds: 45),
      onStart: () {
        // Enable ghost mode for next block
        debugPrint('👻 Ghost block mode enabled');
      },
      onEnd: () {
        debugPrint('👻 Ghost block mode ended');
      },
    );
    
    _addActiveEffect(effect);
    gameWorld.scoringSystem.awardPowerUpUsage('ghost_block', 1);
  }

  /// Execute magnet power-up (auto-place blocks)
  void _executeMagnet() {
    final effect = PowerUpEffect(
      id: 'magnet',
      duration: const Duration(seconds: 30),
      onStart: () {
        // Enable auto-placement for blocks
        debugPrint('🧲 Magnet mode enabled');
      },
      onEnd: () {
        debugPrint('🧲 Magnet mode ended');
      },
    );
    
    _addActiveEffect(effect);
    gameWorld.scoringSystem.awardPowerUpUsage('magnet', 1);
  }

  /// Add an active effect
  void _addActiveEffect(PowerUpEffect effect) {
    _activeEffects.add(effect);
    effect.onStart?.call();
    
    // Set up timer to end effect
    _effectTimers[effect.id] = Timer(effect.duration, () {
      _removeActiveEffect(effect.id);
    });
    
    // Create visual indicator
    _createEffectIndicator(effect);
  }

  /// Remove an active effect
  void _removeActiveEffect(String effectId) {
    final effect = _activeEffects.where((e) => e.id == effectId).firstOrNull;
    if (effect != null) {
      effect.onEnd?.call();
      _activeEffects.remove(effect);
    }
    
    _effectTimers[effectId]?.cancel();
    _effectTimers.remove(effectId);
    
    _removeEffectIndicator(effectId);
  }

  /// Consume a power-up (decrease count)
  void _consumePowerUp(String powerUpId) {
    final currentCount = _powerUpCounts[powerUpId] ?? 0;
    if (currentCount > 0) {
      _powerUpCounts[powerUpId] = currentCount - 1;
    }
  }

  /// Start cooldown for a power-up
  void _startCooldown(PowerUp powerUp) {
    _cooldowns[powerUp.id] = DateTime.now().add(powerUp.cooldownDuration);
  }

  /// Check if power-up requires target selection
  bool _requiresTargetSelection(PowerUp powerUp) {
    return ['hammer', 'bomb', 'line_clear'].contains(powerUp.id);
  }

  /// Check if target is valid for power-up
  bool _isValidTarget(Vector2 gridPosition, PowerUp powerUp) {
    final row = gridPosition.y.toInt();
    final col = gridPosition.x.toInt();
    
    if (!_isValidGridPosition(row, col)) return false;
    
    switch (powerUp.id) {
      case 'hammer':
      case 'bomb':
        return gameWorld.gridComponent.occupiedCells[row][col];
      case 'line_clear':
        return true; // Can target any cell
      default:
        return true;
    }
  }

  /// Check if grid position is valid
  bool _isValidGridPosition(int row, int col) {
    final gridSize = gameWorld.gridComponent.gridSize;
    return row >= 0 && row < gridSize && col >= 0 && col < gridSize;
  }

  /// Convert world position to grid position
  Vector2 _worldToGridPosition(Vector2 worldPosition) {
    final localPosition = worldPosition - gameWorld.gridComponent.position;
    final cellSize = gameWorld.cellSize;
    final spacing = GameConstants.gridSpacing;
    
    final col = (localPosition.x / (cellSize + spacing)).floor();
    final row = (localPosition.y / (cellSize + spacing)).floor();
    
    return Vector2(col.toDouble(), row.toDouble());
  }

  /// Show target selection UI
  void _showTargetSelectionUI(PowerUp powerUp) {
    // This would show UI overlay for target selection
    gameCubit.showTargetSelection(powerUp);
  }

  /// Hide target selection UI
  void _hideTargetSelectionUI() {
    gameCubit.hideTargetSelection();
  }

  /// Show invalid target feedback
  void _showInvalidTargetFeedback(Vector2 position) {
    _audioService.playSound('invalid_target');
    HapticFeedback.lightImpact();
  }

  /// Create visual effect for power-up activation
  void _createPowerUpEffect(PowerUp powerUp, Vector2? targetPosition) {
    Vector2 effectPosition;
    
    if (targetPosition != null) {
      effectPosition = gameWorld.gridComponent.position + 
                      Vector2(targetPosition.x * gameWorld.cellSize, 
                             targetPosition.y * gameWorld.cellSize);
    } else {
      effectPosition = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    }
    
    final particle = ParticleComponent.powerUpActivation(
      position: effectPosition,
      powerUpColor: _getPowerUpColor(powerUp),
    );
    
    gameWorld.add(particle);
  }

  /// Create visual indicator for active effect
  void _createEffectIndicator(PowerUpEffect effect) {
    // This would create a UI indicator showing the active effect
    final indicator = RectangleComponent(
      size: Vector2(40, 40),
      position: Vector2(10, 100 + _activeEffects.length * 50),
      paint: Paint()..color = _getPowerUpColor(_availablePowerUps[effect.id]!),
    );
    
    _powerUpIndicators[effect.id] = indicator;
    add(indicator);
  }

  /// Remove visual indicator for effect
  void _removeEffectIndicator(String effectId) {
    final indicator = _powerUpIndicators[effectId];
    if (indicator != null) {
      indicator.removeFromParent();
      _powerUpIndicators.remove(effectId);
    }
  }

  /// Get color for power-up based on rarity
  Color _getPowerUpColor(PowerUp powerUp) {
    switch (powerUp.rarity) {
      case PowerUpRarity.common:
        return Colors.grey;
      case PowerUpRarity.rare:
        return Colors.blue;
      case PowerUpRarity.epic:
        return Colors.purple;
      case PowerUpRarity.legendary:
        return Colors.orange;
    }
  }

  /// Add power-up to inventory
  void addPowerUp(String powerUpId, int count) {
    _powerUpCounts[powerUpId] = (_powerUpCounts[powerUpId] ?? 0) + count;
    debugPrint('➕ Added $count ${_availablePowerUps[powerUpId]?.name} power-ups');
  }

  /// Get power-up inventory
  Map<String, int> getPowerUpInventory() {
    return Map.unmodifiable(_powerUpCounts);
  }

  /// Get available power-ups
  Map<String, PowerUp> getAvailablePowerUps() {
    return Map.unmodifiable(_availablePowerUps);
  }

  /// Get active effects
  List<PowerUpEffect> getActiveEffects() {
    return List.unmodifiable(_activeEffects);
  }

  /// Check if any effect is active
  bool hasActiveEffect(String effectId) {
    return _activeEffects.any((effect) => effect.id == effectId);
  }

  @override
  void onRemove() {
    // Cancel all timers
    for (final timer in _effectTimers.values) {
      timer.cancel();
    }
    _effectTimers.clear();
    
    // Clean up performance monitoring
    _performanceMonitor.dispose();
    
    super.onRemove();
  }

  // Getters for external access
  PowerUp? get activePowerUp => _activePowerUp;
  bool get isWaitingForTarget => _isWaitingForTarget;
  int get activeEffectCount => _activeEffects.length;
}

/// Represents an active power-up effect
class PowerUpEffect {
  final String id;
  final Duration duration;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final DateTime startTime;

  PowerUpEffect({
    required this.id,
    required this.duration,
    this.onStart,
    this.onEnd,
  }) : startTime = DateTime.now();

  /// Get remaining duration
  Duration get remainingDuration {
    final elapsed = DateTime.now().difference(startTime);
    final remaining = duration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if effect has expired
  bool get hasExpired => remainingDuration == Duration.zero;

  /// Get progress (0.0 to 1.0)
  double get progress {
    final elapsed = DateTime.now().difference(startTime);
    return (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}

/// Timer component for managing timed events
class Timer {
  final Duration duration;
  final VoidCallback callback;
  final DateTime startTime;
  bool _isCancelled = false;

  Timer(this.duration, this.callback) : startTime = DateTime.now() {
    Future.delayed(duration, () {
      if (!_isCancelled) {
        callback();
      }
    });
  }

  void cancel() {
    _isCancelled = true;
  }

  bool get isCancelled => _isCancelled;
}