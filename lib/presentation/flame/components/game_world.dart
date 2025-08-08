import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';

import '../../../core/theme/colors.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/performance_utils.dart';
import 'grid_component.dart';
import 'block_component.dart';
import 'particle_component.dart';

/// The main game world component that manages the game grid, blocks, and core gameplay logic.
/// Follows Clean Architecture by separating concerns and using cubits for state management.
class GameWorld extends PositionComponent with HasGameRef {
  // Configuration
  final int gridSize;
  final double cellSize;
  
  // State management
  final GameCubit gameCubit;
  final PlayerCubit playerCubit;
  
  // Core components
  late final GridComponent _gridComponent;
  late final List<BlockComponent> _activeBlocks;
  late final List<List<BlockComponent?>> _placedBlocks;
  
  // Game state
  GameSession? _currentSession;
  PlayerStats? _currentPlayerStats;
  bool _isGameActive = false;
  
  // Performance tracking
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  // Animation and effects
  final List<ParticleComponent> _particles = [];
  late final ComponentSet<Component> _effects;

  GameWorld({
    required this.gridSize,
    required this.cellSize,
    required this.gameCubit,
    required this.playerCubit,
  }) {
    _activeBlocks = [];
    _placedBlocks = List.generate(
      gridSize,
      (i) => List.generate(gridSize, (j) => null),
    );
    _effects = ComponentSet<Component>();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    await _initializeComponents();
    await _setupGrid();
    
    debugPrint('🌍 GameWorld loaded - Grid: ${gridSize}x$gridSize, Cell: ${cellSize}px');
  }

  /// Initialize all child components
  Future<void> _initializeComponents() async {
    // Initialize grid component
    _gridComponent = GridComponent(
      gridSize: gridSize,
      cellSize: cellSize,
      onCellTapped: _handleCellTapped,
      onBlockDropped: _handleBlockDropped,
    );
    
    add(_gridComponent);
    
    // Add effects container
    add(_effects);
    
    debugPrint('🔧 GameWorld components initialized');
  }

  /// Setup the game grid layout and positioning
  Future<void> _setupGrid() async {
    // Center the grid in the available space
    final gameSize = gameRef.size;
    final gridWidth = gridSize * cellSize + (gridSize - 1) * GameConstants.gridSpacing;
    final gridHeight = gridWidth; // Square grid
    
    final offsetX = (gameSize.x - gridWidth) / 2;
    final offsetY = (gameSize.y - gridHeight) / 2;
    
    _gridComponent.position = Vector2(offsetX, offsetY);
    
    debugPrint('📐 Grid positioned at ($offsetX, $offsetY)');
  }

  /// Start a new game session
  void startGame(GameSession session) {
    _performanceMonitor.startTracking('game_session');
    
    _currentSession = session;
    _isGameActive = true;
    
    _resetGameState();
    _spawnInitialBlocks();
    
    debugPrint('🚀 Game started - Session ID: ${session.id}');
  }

  /// End the current game session
  void endGame() {
    _isGameActive = false;
    
    _clearActiveBlocks();
    _addGameOverEffect();
    
    _performanceMonitor.stopTracking('game_session');
    
    debugPrint('🏁 Game ended');
  }

  /// Reset all game state for a new game
  void _resetGameState() {
    // Clear the grid
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final existingBlock = _placedBlocks[i][j];
        if (existingBlock != null) {
          existingBlock.removeFromParent();
          _placedBlocks[i][j] = null;
        }
      }
    }
    
    // Clear active blocks
    _clearActiveBlocks();
    
    // Reset grid state
    _gridComponent.resetGrid();
    
    // Clear effects
    _clearAllEffects();
    
    debugPrint('🔄 Game state reset');
  }

  /// Spawn the initial set of blocks for the game
  void _spawnInitialBlocks() {
    if (_currentSession == null) return;
    
    final blocksToSpawn = _currentSession!.nextBlocks;
    
    for (int i = 0; i < blocksToSpawn.length && i < 3; i++) {
      _spawnBlock(blocksToSpawn[i], i);
    }
    
    debugPrint('📦 Spawned ${blocksToSpawn.length} initial blocks');
  }

  /// Spawn a single block at the specified slot
  void _spawnBlock(Block blockData, int slotIndex) {
    final blockComponent = BlockComponent(
      blockData: blockData,
      cellSize: cellSize,
      onDragStart: _handleBlockDragStart,
      onDragEnd: _handleBlockDragEnd,
    );
    
    // Position block in the appropriate slot
    final slotPosition = _getBlockSlotPosition(slotIndex);
    blockComponent.position = slotPosition;
    
    _activeBlocks.add(blockComponent);
    add(blockComponent);
    
    // Add spawn animation
    blockComponent.add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.3,
          curve: Curves.elasticOut,
        ),
      ),
    );
  }

  /// Get the position for a block slot
  Vector2 _getBlockSlotPosition(int slotIndex) {
    final screenWidth = gameRef.size.x;
    final slotWidth = cellSize * 3; // Assume max 3x3 blocks
    final spacing = 20.0;
    final totalWidth = 3 * slotWidth + 2 * spacing;
    final startX = (screenWidth - totalWidth) / 2;
    
    final x = startX + slotIndex * (slotWidth + spacing);
    final y = gameRef.size.y - 150; // Position at bottom
    
    return Vector2(x, y);
  }

  /// Handle when a block starts being dragged
  void _handleBlockDragStart(BlockComponent block) {
    if (!_isGameActive) return;
    
    // Highlight valid placement areas
    _gridComponent.highlightValidPlacements(block.blockData);
    
    // Add visual feedback
    block.scale = Vector2.all(1.1);
    block.add(ColorEffect(
      AppColors.accent.withOpacity(0.8),
      EffectController(duration: 0.1),
    ));
  }

  /// Handle when a block finishes being dragged
  void _handleBlockDragEnd(BlockComponent block, Vector2 worldPosition) {
    if (!_isGameActive) return;
    
    // Clear grid highlights
    _gridComponent.clearHighlights();
    
    // Reset block visual state
    block.scale = Vector2.all(1.0);
    
    // Check if block can be placed at this position
    final gridPosition = _worldToGridPosition(worldPosition);
    
    if (_canPlaceBlock(block.blockData, gridPosition)) {
      _placeBlockOnGrid(block, gridPosition);
    } else {
      _returnBlockToSlot(block);
    }
  }

  /// Handle cell tapped on the grid
  void _handleCellTapped(Vector2 gridPosition) {
    if (!_isGameActive) return;
    
    // If there's a selected block, try to place it
    final selectedBlock = _getSelectedBlock();
    if (selectedBlock != null && _canPlaceBlock(selectedBlock.blockData, gridPosition)) {
      _placeBlockOnGrid(selectedBlock, gridPosition);
    }
  }

  /// Handle block dropped on the grid
  void _handleBlockDropped(BlockComponent block, Vector2 gridPosition) {
    if (!_isGameActive) return;
    
    if (_canPlaceBlock(block.blockData, gridPosition)) {
      _placeBlockOnGrid(block, gridPosition);
    }
  }

  /// Check if a block can be placed at the given grid position
  bool _canPlaceBlock(Block blockData, Vector2 gridPosition) {
    final startRow = gridPosition.y.toInt();
    final startCol = gridPosition.x.toInt();
    
    // Check each cell of the block
    for (int row = 0; row < blockData.shape.length; row++) {
      for (int col = 0; col < blockData.shape[row].length; col++) {
        if (blockData.shape[row][col] == 1) {
          final gridRow = startRow + row;
          final gridCol = startCol + col;
          
          // Check bounds
          if (gridRow < 0 || gridRow >= gridSize || 
              gridCol < 0 || gridCol >= gridSize) {
            return false;
          }
          
          // Check if cell is already occupied
          if (_placedBlocks[gridRow][gridCol] != null) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  /// Place a block on the grid
  void _placeBlockOnGrid(BlockComponent block, Vector2 gridPosition) {
    _performanceMonitor.startTracking('place_block');
    
    final startRow = gridPosition.y.toInt();
    final startCol = gridPosition.x.toInt();
    
    // Create new block components for each cell
    final placedComponents = <BlockComponent>[];
    
    for (int row = 0; row < block.blockData.shape.length; row++) {
      for (int col = 0; col < block.blockData.shape[row].length; col++) {
        if (block.blockData.shape[row][col] == 1) {
          final gridRow = startRow + row;
          final gridCol = startCol + col;
          
          final cellBlock = BlockComponent(
            blockData: Block(
              id: '${block.blockData.id}_cell_${gridRow}_$gridCol',
              shape: [[1]], // Single cell
              color: block.blockData.color,
              powerUpType: block.blockData.powerUpType,
            ),
            cellSize: cellSize,
            isPlaced: true,
          );
          
          final worldPos = _gridToWorldPosition(Vector2(gridCol.toDouble(), gridRow.toDouble()));
          cellBlock.position = worldPos;
          
          _placedBlocks[gridRow][gridCol] = cellBlock;
          placedComponents.add(cellBlock);
          add(cellBlock);
        }
      }
    }
    
    // Remove the dragged block
    _activeBlocks.remove(block);
    block.removeFromParent();
    
    // Add placement effect
    _addBlockPlacementEffect(gridPosition, block.blockData);
    
    // Check for completed lines
    _checkForCompletedLines();
    
    // Check if we need more blocks
    _checkAndSpawnNewBlocks();
    
    // Check for game over
    _checkGameOver();
    
    // Update game state
    gameCubit.onBlockPlaced(block.blockData, gridPosition);
    
    _performanceMonitor.stopTracking('place_block');
    
    debugPrint('📍 Block placed at ($startCol, $startRow)');
  }

  /// Return a block to its original slot
  void _returnBlockToSlot(BlockComponent block) {
    final slotIndex = _activeBlocks.indexOf(block);
    if (slotIndex >= 0) {
      final slotPosition = _getBlockSlotPosition(slotIndex);
      
      block.add(MoveEffect.to(
        slotPosition,
        EffectController(duration: 0.3, curve: Curves.easeOut),
      ));
    }
  }

  /// Check for completed lines and clear them
  void _checkForCompletedLines() {
    final completedRows = <int>[];
    final completedCols = <int>[];
    
    // Check rows
    for (int row = 0; row < gridSize; row++) {
      bool isComplete = true;
      for (int col = 0; col < gridSize; col++) {
        if (_placedBlocks[row][col] == null) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        completedRows.add(row);
      }
    }
    
    // Check columns
    for (int col = 0; col < gridSize; col++) {
      bool isComplete = true;
      for (int row = 0; row < gridSize; row++) {
        if (_placedBlocks[row][col] == null) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        completedCols.add(col);
      }
    }
    
    if (completedRows.isNotEmpty || completedCols.isNotEmpty) {
      _clearCompletedLines(completedRows, completedCols);
    }
  }

  /// Clear completed lines with animation
  void _clearCompletedLines(List<int> rows, List<int> cols) {
    _performanceMonitor.startTracking('clear_lines');
    
    final cellsToRemove = <Vector2>[];
    
    // Collect cells to remove
    for (final row in rows) {
      for (int col = 0; col < gridSize; col++) {
        cellsToRemove.add(Vector2(col.toDouble(), row.toDouble()));
      }
    }
    
    for (final col in cols) {
      for (int row = 0; row < gridSize; row++) {
        cellsToRemove.add(Vector2(col.toDouble(), row.toDouble()));
      }
    }
    
    // Remove duplicates
    final uniqueCells = cellsToRemove.toSet().toList();
    
    // Add clear effects
    for (final cell in uniqueCells) {
      _addLineClearEffect(cell);
    }
    
    // Remove blocks after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      for (final cell in uniqueCells) {
        final row = cell.y.toInt();
        final col = cell.x.toInt();
        
        final block = _placedBlocks[row][col];
        if (block != null) {
          block.removeFromParent();
          _placedBlocks[row][col] = null;
        }
      }
      
      // Update game state
      gameCubit.onLinesCleared(rows.length + cols.length, uniqueCells.length);
      
      _performanceMonitor.stopTracking('clear_lines');
    });
    
    debugPrint('💥 Cleared ${rows.length} rows and ${cols.length} columns');
  }

  /// Check if new blocks need to be spawned
  void _checkAndSpawnNewBlocks() {
    if (_activeBlocks.isEmpty && _currentSession != null) {
      // Request new blocks from the game cubit
      gameCubit.requestNewBlocks();
    }
  }

  /// Check for game over conditions
  void _checkGameOver() {
    if (!_hasValidMoves()) {
      gameCubit.triggerGameOver();
    }
  }

  /// Check if there are any valid moves available
  bool _hasValidMoves() {
    for (final block in _activeBlocks) {
      if (_hasValidPlacement(block.blockData)) {
        return true;
      }
    }
    return false;
  }

  /// Check if a block has any valid placement on the grid
  bool _hasValidPlacement(Block blockData) {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (_canPlaceBlock(blockData, Vector2(col.toDouble(), row.toDouble()))) {
          return true;
        }
      }
    }
    return false;
  }

  /// Convert world position to grid position
  Vector2 _worldToGridPosition(Vector2 worldPosition) {
    final localPosition = worldPosition - _gridComponent.position;
    final gridX = (localPosition.x / (cellSize + GameConstants.gridSpacing)).floor();
    final gridY = (localPosition.y / (cellSize + GameConstants.gridSpacing)).floor();
    
    return Vector2(
      gridX.toDouble().clamp(0, gridSize - 1),
      gridY.toDouble().clamp(0, gridSize - 1),
    );
  }

  /// Convert grid position to world position
  Vector2 _gridToWorldPosition(Vector2 gridPosition) {
    final x = _gridComponent.position.x + gridPosition.x * (cellSize + GameConstants.gridSpacing);
    final y = _gridComponent.position.y + gridPosition.y * (cellSize + GameConstants.gridSpacing);
    
    return Vector2(x, y);
  }

  /// Get the currently selected block (if any)
  BlockComponent? _getSelectedBlock() {
    for (final block in _activeBlocks) {
      if (block.isSelected) {
        return block;
      }
    }
    return null;
  }

  /// Clear all active blocks
  void _clearActiveBlocks() {
    for (final block in _activeBlocks) {
      block.removeFromParent();
    }
    _activeBlocks.clear();
  }

  /// Add block placement effect
  void _addBlockPlacementEffect(Vector2 gridPosition, Block blockData) {
    final worldPos = _gridToWorldPosition(gridPosition);
    final particle = ParticleComponent.blockPlacement(
      position: worldPos,
      color: blockData.color,
    );
    
    _particles.add(particle);
    add(particle);
    
    // Remove particle after animation
    Future.delayed(const Duration(seconds: 2), () {
      particle.removeFromParent();
      _particles.remove(particle);
    });
  }

  /// Add line clear effect
  void _addLineClearEffect(Vector2 gridPosition) {
    final worldPos = _gridToWorldPosition(gridPosition);
    final particle = ParticleComponent.lineClear(
      position: worldPos,
      cellSize: cellSize,
    );
    
    _particles.add(particle);
    add(particle);
    
    // Remove particle after animation
    Future.delayed(const Duration(seconds: 1), () {
      particle.removeFromParent();
      _particles.remove(particle);
    });
  }

  /// Add game over effect
  void _addGameOverEffect() {
    final centerPosition = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    final particle = ParticleComponent.gameOver(
      position: centerPosition,
    );
    
    _particles.add(particle);
    add(particle);
  }

  /// Clear all effects
  void _clearAllEffects() {
    for (final particle in _particles) {
      particle.removeFromParent();
    }
    _particles.clear();
    _effects.clear();
  }

  /// Update player stats display
  void updatePlayerStats(PlayerStats stats) {
    _currentPlayerStats = stats;
    // Update any UI components that show player stats
  }

  /// Update layout for responsive design
  void updateLayout(dynamic config) {
    // Update positions and sizes based on new configuration
    _setupGrid();
    
    // Reposition active blocks
    for (int i = 0; i < _activeBlocks.length; i++) {
      final newPosition = _getBlockSlotPosition(i);
      _activeBlocks[i].position = newPosition;
    }
  }

  /// Place a block programmatically (for power-ups, etc.)
  void placeBlock(Block block, Vector2 position) {
    if (!_isGameActive) return;
    
    final gridPosition = _worldToGridPosition(position);
    if (_canPlaceBlock(block, gridPosition)) {
      // Create a temporary block component
      final blockComponent = BlockComponent(
        blockData: block,
        cellSize: cellSize,
      );
      
      _placeBlockOnGrid(blockComponent, gridPosition);
    }
  }

  // Getters for external access
  List<BlockComponent> get activeBlocks => List.unmodifiable(_activeBlocks);
  List<List<BlockComponent?>> get placedBlocks => _placedBlocks;
  GridComponent get gridComponent => _gridComponent;
  bool get isGameActive => _isGameActive;
  GameSession? get currentSession => _currentSession;
}