import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';

import '../../../core/theme/colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/performance_utils.dart';
import '../box_hooks_game.dart';
import 'grid_component.dart';
import 'block_component.dart';
import 'particle_component.dart';

/// The main game world component that manages the game grid, blocks, and core gameplay logic.
/// Follows Clean Architecture by separating concerns and using cubits for state management.
class GameWorld extends PositionComponent with HasGameRef<BoxHooksGame> {
  // Configuration
  final int gridSize;
  final double cellSize;
  
  // State management
  final GameCubit gameCubit;
  final PlayerCubit playerCubit;
  
  // Core components
  late final GridComponent _gridComponent;
  final List<BlockComponent> _activeBlocks = [];
  late final List<List<BlockComponent?>> _placedBlocks;
  
  // Game state
  GameSession? _currentSession;
  PlayerStats? _currentPlayerStats;
  
  // Visual effects
  final List<ParticleComponent> _particles = [];
  final List<Component> _effectComponents = [];
  
  // Performance settings
  bool _particlesEnabled = true;
  bool _animationsEnabled = true;
  bool _shadowsEnabled = false;
  
  // Animation controllers
  final List<Effect> _activeEffects = [];

  GameWorld({
    required this.gridSize,
    required this.cellSize,
    required this.gameCubit,
    required this.playerCubit,
  }) : super() {
    _initializeGameWorld();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Initialize placed blocks grid
    _placedBlocks = List.generate(
      gridSize,
      (_) => List.filled(gridSize, null),
    );
    
    // Create and add grid component
    _gridComponent = GridComponent(
      gridSize: gridSize,
      cellSize: cellSize,
      onCellTapped: _handleCellTapped,
      onBlockDropped: _handleBlockDropped,
    );
    
    await add(_gridComponent);
    
    // Position the grid in the center of the world
    _positionGrid();
    
    debugPrint('🌍 GameWorld loaded');
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update particles
    _updateParticles(dt);
    
    // Update effects
    _updateEffects(dt);
    
    // Check for completed lines
    _checkForCompletedLines();
    
    // Update animations
    if (_animationsEnabled) {
      _updateAnimations(dt);
    }
  }

  /// Initialize the game world
  void _initializeGameWorld() {
    debugPrint('🌍 Initializing GameWorld');
  }

  /// Position the grid component in the center
  void _positionGrid() {
    final gameSize = gameRef.size;
    final gridTotalSize = gridSize * cellSize + (gridSize - 1) * AppConstants.cellSpacing;
    
    _gridComponent.position = Vector2(
      (gameSize.x - gridTotalSize) / 2,
      (gameSize.y - gridTotalSize) / 2,
    );
  }

  // ========================================
  // GAME STATE MANAGEMENT
  // ========================================

  /// Update from game state changes
  void updateFromGameState(GameState gameState) {
    _currentSession = gameState.currentSession;
    
    // Update grid state
    if (gameState.grid.isNotEmpty) {
      _updateGridFromState(gameState.grid);
    }
    
    // Update active blocks
    _updateActiveBlocks(gameState.activeBlocks);
    
    // Update visual elements based on game state
    _updateVisualElements(gameState);
  }

  /// Update player stats display
  void updatePlayerStats(PlayerStats? playerStats) {
    _currentPlayerStats = playerStats;
    // Update UI elements that display player stats
  }

  /// Update grid from game state
  void _updateGridFromState(List<List<int>> gridState) {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final cellValue = gridState[row][col];
        
        if (cellValue != 0) {
          // Cell is occupied
          if (_placedBlocks[row][col] == null) {
            // Create new block component
            final blockComponent = BlockComponent(
              colorIndex: cellValue - 1,
              position: Vector2(col.toDouble(), row.toDouble()),
            );
            _placedBlocks[row][col] = blockComponent;
            _gridComponent.add(blockComponent);
          }
        } else {
          // Cell is empty
          if (_placedBlocks[row][col] != null) {
            // Remove existing block
            _placedBlocks[row][col]?.removeFromParent();
            _placedBlocks[row][col] = null;
          }
        }
      }
    }
  }

  /// Update active blocks
  void _updateActiveBlocks(List<Block> blocks) {
    // Clear existing active blocks
    for (final block in _activeBlocks) {
      block.removeFromParent();
    }
    _activeBlocks.clear();
    
    // Add new active blocks
    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      final blockComponent = BlockComponent.fromBlock(
        block: block,
        position: Vector2(i * (cellSize + 10), -cellSize * 2),
      );
      
      _activeBlocks.add(blockComponent);
      add(blockComponent);
    }
  }

  /// Update visual elements based on game state
  void _updateVisualElements(GameState gameState) {
    // Update score display, level display, etc.
    // This would typically update HUD components
  }

  // ========================================
  // INTERACTION HANDLING
  // ========================================

  /// Handle cell tap
  void _handleCellTapped(Vector2 cellPosition) {
    final row = cellPosition.y.toInt();
    final col = cellPosition.x.toInt();
    
    debugPrint('Cell tapped: ($row, $col)');
    
    // Handle cell interaction based on current game mode
    // This might place a block, select a cell, etc.
  }

  /// Handle block drop
  void _handleBlockDropped(BlockComponent block, Vector2 cellPosition) {
    final row = cellPosition.y.toInt();
    final col = cellPosition.x.toInt();
    
    debugPrint('Block dropped at: ($row, $col)');
    
    // Validate placement and update game state through cubit
    if (_canPlaceBlock(block, row, col)) {
      // Convert to domain entity and place through cubit
      final blockEntity = block.toBlockEntity();
      gameCubit.placeBlock(blockEntity, row, col);
      
      // Show placement effect
      _showBlockPlacementEffect(Vector2(col.toDouble(), row.toDouble()));
    } else {
      // Show invalid placement effect
      _showInvalidPlacementEffect(Vector2(col.toDouble(), row.toDouble()));
    }
  }

  /// Check if block can be placed at position
  bool _canPlaceBlock(BlockComponent block, int row, int col) {
    // Implement placement validation logic
    final blockShape = block.getShape();
    
    for (int r = 0; r < blockShape.length; r++) {
      for (int c = 0; c < blockShape[r].length; c++) {
        if (blockShape[r][c] == 1) {
          final targetRow = row + r;
          final targetCol = col + c;
          
          // Check bounds
          if (targetRow < 0 || targetRow >= gridSize ||
              targetCol < 0 || targetCol >= gridSize) {
            return false;
          }
          
          // Check if cell is already occupied
          if (_placedBlocks[targetRow][targetCol] != null) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  // ========================================
  // LINE CLEARING
  // ========================================

  /// Check for completed lines
  void _checkForCompletedLines() {
    final completedRows = <int>[];
    final completedCols = <int>[];
    
    // Check rows
    for (int row = 0; row < gridSize; row++) {
      if (_isRowComplete(row)) {
        completedRows.add(row);
      }
    }
    
    // Check columns
    for (int col = 0; col < gridSize; col++) {
      if (_isColumnComplete(col)) {
        completedCols.add(col);
      }
    }
    
    // Clear completed lines
    if (completedRows.isNotEmpty || completedCols.isNotEmpty) {
      _clearLines(completedRows, completedCols);
    }
  }

  /// Check if row is complete
  bool _isRowComplete(int row) {
    for (int col = 0; col < gridSize; col++) {
      if (_placedBlocks[row][col] == null) {
        return false;
      }
    }
    return true;
  }

  /// Check if column is complete
  bool _isColumnComplete(int col) {
    for (int row = 0; row < gridSize; row++) {
      if (_placedBlocks[row][col] == null) {
        return false;
      }
    }
    return true;
  }

  /// Clear completed lines
  void _clearLines(List<int> rows, List<int> cols) {
    // Show line clear effects
    for (final row in rows) {
      _showLineClearEffect(row, isRow: true);
    }
    
    for (final col in cols) {
      _showLineClearEffect(col, isRow: false);
    }
    
    // Remove blocks from cleared lines
    for (final row in rows) {
      for (int col = 0; col < gridSize; col++) {
        _placedBlocks[row][col]?.removeFromParent();
        _placedBlocks[row][col] = null;
      }
    }
    
    for (final col in cols) {
      for (int row = 0; row < gridSize; row++) {
        _placedBlocks[row][col]?.removeFromParent();
        _placedBlocks[row][col] = null;
      }
    }
  }

  // ========================================
  // VISUAL EFFECTS
  // ========================================

  /// Show block placement effect
  void _showBlockPlacementEffect(Vector2 position) {
    if (!_particlesEnabled) return;
    
    final particle = ParticleComponent(
      position: position * cellSize + Vector2(cellSize / 2, cellSize / 2),
      color: AppColors.success,
      type: ParticleType.burst,
    );
    
    _particles.add(particle);
    add(particle);
  }

  /// Show invalid placement effect
  void _showInvalidPlacementEffect(Vector2 position) {
    if (!_particlesEnabled) return;
    
    final particle = ParticleComponent(
      position: position * cellSize + Vector2(cellSize / 2, cellSize / 2),
      color: AppColors.error,
      type: ParticleType.shake,
    );
    
    _particles.add(particle);
    add(particle);
  }

  /// Show line clear effect
  void _showLineClearEffect(int lineIndex, {required bool isRow}) {
    if (!_animationsEnabled) return;
    
    // Create line clear animation
    final effect = ScaleEffect.to(
      Vector2.zero(),
      EffectController(duration: 0.3),
    );
    
    // Apply to all blocks in the line
    if (isRow) {
      for (int col = 0; col < gridSize; col++) {
        _placedBlocks[lineIndex][col]?.add(effect);
      }
    } else {
      for (int row = 0; row < gridSize; row++) {
        _placedBlocks[row][lineIndex]?.add(effect);
      }
    }
  }

  /// Show coins earned effect
  void showCoinsEarned(int coinsEarned) {
    if (!_particlesEnabled) return;
    
    // Create floating text effect
    final textComponent = TextComponent(
      text: '+$coinsEarned',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: AppColors.warning,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    
    textComponent.position = Vector2(size.x / 2, size.y / 4);
    
    // Add floating animation
    final moveEffect = MoveEffect.to(
      textComponent.position + Vector2(0, -50),
      EffectController(duration: 2.0),
    );
    
    final fadeEffect = OpacityEffect.to(
      0.0,
      EffectController(duration: 2.0),
    );
    
    textComponent.add(moveEffect);
    textComponent.add(fadeEffect);
    
    add(textComponent);
    
    // Remove after animation
    Future.delayed(const Duration(seconds: 2), () {
      textComponent.removeFromParent();
    });
  }

  /// Show achievement unlock effect
  void showAchievementUnlock(Achievement achievement) {
    if (!_animationsEnabled) return;
    
    // Create achievement banner
    final bannerComponent = RectangleComponent(
      size: Vector2(size.x * 0.8, 60),
      paint: Paint()..color = AppColors.primary.withOpacity(0.9),
    );
    
    bannerComponent.position = Vector2(size.x * 0.1, -60);
    
    final textComponent = TextComponent(
      text: 'Achievement Unlocked: ${achievement.title}',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    
    textComponent.position = Vector2(10, 20);
    bannerComponent.add(textComponent);
    
    // Add slide-in animation
    final slideIn = MoveEffect.to(
      Vector2(size.x * 0.1, 50),
      EffectController(duration: 0.5, curve: Curves.easeOut),
    );
    
    bannerComponent.add(slideIn);
    add(bannerComponent);
    
    // Remove after delay
    Future.delayed(const Duration(seconds: 3), () {
      final slideOut = MoveEffect.to(
        Vector2(size.x * 0.1, -60),
        EffectController(duration: 0.5, curve: Curves.easeIn),
      );
      
      bannerComponent.add(slideOut);
      
      Future.delayed(const Duration(milliseconds: 500), () {
        bannerComponent.removeFromParent();
      });
    });
  }

  /// Show game over effect
  void triggerGameOverEffect() {
    if (!_animationsEnabled) return;
    
    // Add screen shake effect
    final shakeEffect = MoveEffect.by(
      Vector2(5, 0),
      EffectController(
        duration: 0.1,
        alternate: true,
        repeatCount: 10,
      ),
    );
    
    add(shakeEffect);
    
    // Dim all blocks
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final block = _placedBlocks[row][col];
        if (block != null) {
          final dimEffect = OpacityEffect.to(
            0.3,
            EffectController(duration: 1.0),
          );
          block.add(dimEffect);
        }
      }
    }
  }

  // ========================================
  // PERFORMANCE SETTINGS
  // ========================================

  /// Set particles enabled/disabled
  void setParticlesEnabled(bool enabled) {
    _particlesEnabled = enabled;
    
    if (!enabled) {
      // Remove all existing particles
      for (final particle in _particles) {
        particle.removeFromParent();
      }
      _particles.clear();
    }
  }

  /// Set animations enabled/disabled
  void setAnimationsEnabled(bool enabled) {
    _animationsEnabled = enabled;
    
    if (!enabled) {
      // Remove all active effects
      for (final effect in _activeEffects) {
        effect.removeFromParent();
      }
      _activeEffects.clear();
    }
  }

  /// Set shadows enabled/disabled
  void setShadowsEnabled(bool enabled) {
    _shadowsEnabled = enabled;
    
    // Update shadow rendering for all components
    _gridComponent.setShadowsEnabled(enabled);
    
    for (final block in _activeBlocks) {
      block.setShadowsEnabled(enabled);
    }
  }

  /// Update size for responsive design
  void updateSize(GameConfig config) {
    // Update component sizes based on new configuration
    size = Vector2(config.totalGridSize, config.totalGridSize);
    
    // Reposition grid
    _positionGrid();
    
    // Update component scales
    final scale = config.scale;
    this.scale = Vector2.all(scale);
  }

  // ========================================
  // UPDATE METHODS
  // ========================================

  /// Update particles
  void _updateParticles(double dt) {
    _particles.removeWhere((particle) {
      if (particle.isFinished) {
        particle.removeFromParent();
        return true;
      }
      return false;
    });
  }

  /// Update effects
  void _updateEffects(double dt) {
    _activeEffects.removeWhere((effect) {
      if (effect.parent == null) {
        return true;
      }
      return false;
    });
  }

  /// Update animations
  void _updateAnimations(double dt) {
    // Update any custom animations here
  }

  // ========================================
  // CLEANUP
  // ========================================

  /// Cleanup resources
  void cleanup() {
    // Remove all particles
    for (final particle in _particles) {
      particle.removeFromParent();
    }
    _particles.clear();
    
    // Remove all effects
    for (final effect in _activeEffects) {
      effect.removeFromParent();
    }
    _activeEffects.clear();
    
    // Clear placed blocks
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        _placedBlocks[row][col]?.removeFromParent();
        _placedBlocks[row][col] = null;
      }
    }
    
    // Remove active blocks
    for (final block in _activeBlocks) {
      block.removeFromParent();
    }
    _activeBlocks.clear();
  }
}