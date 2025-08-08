import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/utils/performance_utils.dart';
import '../../../core/services/audio_service.dart';
import '../../../injection_container.dart';
import '../components/game_world.dart';
import '../components/block_component.dart';

/// Input system for handling user interactions in the game.
/// Manages touch events, gestures, keyboard input, and accessibility features.
/// Follows Clean Architecture by coordinating between presentation and domain layers.
class InputSystem extends Component with HasGameRef, TapCallbacks, DragCallbacks, HasKeyboardHandlerComponents {
  // Dependencies
  final GameWorld gameWorld;
  final GameCubit gameCubit;
  late final AudioService _audioService;
  
  // Input state
  bool _isEnabled = true;
  BlockComponent? _selectedBlock;
  BlockComponent? _draggedBlock;
  Vector2? _dragStartPosition;
  Vector2? _lastTouchPosition;
  
  // Multi-touch state
  final Map<int, Vector2> _activePointers = {};
  final Map<int, BlockComponent?> _pointerToBlock = {};
  
  // Gesture recognition
  DateTime? _lastTapTime;
  Vector2? _lastTapPosition;
  bool _isLongPressing = false;
  
  // Performance monitoring
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  // Accessibility
  bool _isAccessibilityEnabled = false;
  String? _accessibilityHint;

  InputSystem({
    required this.gameWorld,
    required this.gameCubit,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    _audioService = getIt<AudioService>();
    _setupAccessibility();
    
    debugPrint('🎮 InputSystem loaded and enabled');
  }

  /// Setup accessibility features
  void _setupAccessibility() {
    // Check if accessibility features are enabled
    _isAccessibilityEnabled = MediaQuery.of(gameRef.buildContext!).accessibleNavigation;
    
    if (_isAccessibilityEnabled) {
      debugPrint('♿ Accessibility mode enabled');
    }
  }

  /// Enable input handling
  void enable() {
    _isEnabled = true;
    debugPrint('🎮 Input system enabled');
  }

  /// Disable input handling
  void disable() {
    _isEnabled = false;
    _clearAllInputState();
    debugPrint('🎮 Input system disabled');
  }

  /// Clear all current input state
  void _clearAllInputState() {
    _selectedBlock = null;
    _draggedBlock = null;
    _dragStartPosition = null;
    _lastTouchPosition = null;
    _activePointers.clear();
    _pointerToBlock.clear();
    _isLongPressing = false;
  }

  /// Handle tap down events
  @override
  bool onTapDown(TapDownEvent event) {
    if (!_isEnabled) return false;
    
    _performanceMonitor.startTracking('tap_processing');
    
    final worldPosition = event.localPosition;
    _lastTouchPosition = worldPosition;
    
    // Check if tap is on an active block
    final tappedBlock = _getBlockAtPosition(worldPosition);
    
    if (tappedBlock != null) {
      _handleBlockTapDown(tappedBlock, worldPosition);
      _performanceMonitor.stopTracking('tap_processing');
      return true;
    }
    
    // Check if tap is on the grid
    if (_isPositionOnGrid(worldPosition)) {
      _handleGridTapDown(worldPosition);
      _performanceMonitor.stopTracking('tap_processing');
      return true;
    }
    
    _performanceMonitor.stopTracking('tap_processing');
    return false;
  }

  /// Handle tap up events
  @override
  bool onTapUp(TapUpEvent event) {
    if (!_isEnabled) return false;
    
    final worldPosition = event.localPosition;
    
    // Check for double tap
    if (_isDoubleTap(worldPosition)) {
      _handleDoubleTap(worldPosition);
      return true;
    }
    
    // Regular tap handling
    final tappedBlock = _getBlockAtPosition(worldPosition);
    
    if (tappedBlock != null) {
      _handleBlockTapUp(tappedBlock, worldPosition);
      return true;
    }
    
    if (_isPositionOnGrid(worldPosition)) {
      _handleGridTapUp(worldPosition);
      return true;
    }
    
    // Clear selection if tapping elsewhere
    _clearSelection();
    
    return false;
  }

  /// Handle long tap down (long press start)
  @override
  bool onLongTapDown(TapDownEvent event) {
    if (!_isEnabled) return false;
    
    final worldPosition = event.localPosition;
    final tappedBlock = _getBlockAtPosition(worldPosition);
    
    if (tappedBlock != null) {
      _handleBlockLongPress(tappedBlock, worldPosition);
      return true;
    }
    
    if (_isPositionOnGrid(worldPosition)) {
      _handleGridLongPress(worldPosition);
      return true;
    }
    
    return false;
  }

  /// Handle drag start events
  @override
  bool onDragStart(DragStartEvent event) {
    if (!_isEnabled) return false;
    
    _performanceMonitor.startTracking('drag_operation');
    
    final worldPosition = event.localPosition;
    _dragStartPosition = worldPosition;
    
    final draggedBlock = _getBlockAtPosition(worldPosition);
    
    if (draggedBlock != null && !draggedBlock.isPlaced) {
      _startBlockDrag(draggedBlock, worldPosition);
      return true;
    }
    
    return false;
  }

  /// Handle drag update events
  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (!_isEnabled || _draggedBlock == null) return false;
    
    _updateBlockDrag(event.localDelta);
    return true;
  }

  /// Handle drag end events
  @override
  bool onDragEnd(DragEndEvent event) {
    if (!_isEnabled || _draggedBlock == null) return false;
    
    final endPosition = event.localPosition;
    _endBlockDrag(endPosition);
    
    _performanceMonitor.stopTracking('drag_operation');
    return true;
  }

  /// Handle drag cancel events
  @override
  bool onDragCancel(DragCancelEvent event) {
    if (!_isEnabled || _draggedBlock == null) return false;
    
    _cancelBlockDrag();
    
    _performanceMonitor.stopTracking('drag_operation');
    return true;
  }

  /// Handle block tap down
  void _handleBlockTapDown(BlockComponent block, Vector2 position) {
    if (block.isPlaced) return;
    
    // Provide haptic feedback
    HapticFeedback.selectionClick();
    
    // Audio feedback
    _audioService.playSound('block_select');
    
    // Select the block
    _selectBlock(block);
    
    if (_isAccessibilityEnabled) {
      _announceAccessibility('Block selected: ${block.blockData.id}');
    }
    
    debugPrint('🎯 Block tapped: ${block.blockData.id}');
  }

  /// Handle block tap up
  void _handleBlockTapUp(BlockComponent block, Vector2 position) {
    if (block.isPlaced) return;
    
    // If block is already selected, try to place it at a valid position
    if (_selectedBlock == block) {
      _attemptSmartPlacement(block);
    }
  }

  /// Handle block long press
  void _handleBlockLongPress(BlockComponent block, Vector2 position) {
    if (block.isPlaced) return;
    
    _isLongPressing = true;
    
    // Provide haptic feedback
    HapticFeedback.longPress();
    
    // Audio feedback
    _audioService.playSound('block_longpress');
    
    // Show block information or preview
    _showBlockPreview(block);
    
    if (_isAccessibilityEnabled) {
      _announceAccessibility(
        'Block details: ${_getBlockDescription(block.blockData)}'
      );
    }
    
    debugPrint('🔍 Block long pressed: ${block.blockData.id}');
  }

  /// Handle grid tap down
  void _handleGridTapDown(Vector2 position) {
    final gridPosition = _worldToGridPosition(position);
    
    // Audio feedback for grid interaction
    _audioService.playSound('grid_tap');
    
    if (_isAccessibilityEnabled) {
      _announceAccessibility('Grid cell at row ${gridPosition.y.toInt()}, column ${gridPosition.x.toInt()}');
    }
    
    debugPrint('🔳 Grid tapped at: $gridPosition');
  }

  /// Handle grid tap up
  void _handleGridTapUp(Vector2 position) {
    final gridPosition = _worldToGridPosition(position);
    
    // Try to place selected block at this position
    if (_selectedBlock != null) {
      _attemptBlockPlacement(_selectedBlock!, gridPosition);
    }
  }

  /// Handle grid long press
  void _handleGridLongPress(Vector2 position) {
    final gridPosition = _worldToGridPosition(position);
    
    // Provide haptic feedback
    HapticFeedback.longPress();
    
    // Show grid information
    _showGridInfo(gridPosition);
    
    if (_isAccessibilityEnabled) {
      final isOccupied = gameWorld.gridComponent.occupiedCells[gridPosition.y.toInt()][gridPosition.x.toInt()];
      _announceAccessibility(
        'Grid cell ${isOccupied ? "occupied" : "empty"} at row ${gridPosition.y.toInt()}, column ${gridPosition.x.toInt()}'
      );
    }
  }

  /// Handle double tap
  void _handleDoubleTap(Vector2 position) {
    final tappedBlock = _getBlockAtPosition(position);
    
    if (tappedBlock != null && !tappedBlock.isPlaced) {
      // Double tap on block - auto-place if possible
      _attemptSmartPlacement(tappedBlock);
    } else if (_isPositionOnGrid(position)) {
      // Double tap on grid - show placement suggestions
      _showPlacementSuggestions(_worldToGridPosition(position));
    }
    
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    debugPrint('👆👆 Double tap at: $position');
  }

  /// Start dragging a block
  void _startBlockDrag(BlockComponent block, Vector2 startPosition) {
    _draggedBlock = block;
    _dragStartPosition = startPosition;
    
    // Update block visual state
    block.priority = GameConstants.draggingBlockPriority;
    
    // Show valid placement areas
    gameWorld.gridComponent.highlightValidPlacements(block.blockData);
    
    // Audio feedback
    _audioService.playSound('block_pickup');
    
    // Haptic feedback
    HapticFeedback.selectionClick();
    
    if (_isAccessibilityEnabled) {
      _announceAccessibility('Started dragging block: ${block.blockData.id}');
    }
    
    debugPrint('🎯 Started dragging block: ${block.blockData.id}');
  }

  /// Update block drag position
  void _updateBlockDrag(Vector2 delta) {
    if (_draggedBlock == null) return;
    
    _draggedBlock!.position += delta;
    
    // Update placement preview if over grid
    final currentPosition = _draggedBlock!.position + _draggedBlock!.size / 2;
    if (_isPositionOnGrid(currentPosition)) {
      final gridPosition = _worldToGridPosition(currentPosition);
      _updatePlacementPreview(gridPosition);
    }
  }

  /// End block drag
  void _endBlockDrag(Vector2 endPosition) {
    if (_draggedBlock == null) return;
    
    final block = _draggedBlock!;
    final gridPosition = _worldToGridPosition(endPosition);
    
    // Clear highlights
    gameWorld.gridComponent.clearHighlights();
    
    // Try to place the block
    if (_isPositionOnGrid(endPosition) && gameWorld.gridComponent.occupiedCells.isNotEmpty) {
      if (_canPlaceBlockAt(block.blockData, gridPosition)) {
        _placeBlock(block, gridPosition);
      } else {
        _returnBlockToSlot(block);
        _audioService.playSound('placement_invalid');
      }
    } else {
      _returnBlockToSlot(block);
    }
    
    _draggedBlock = null;
    _dragStartPosition = null;
    
    if (_isAccessibilityEnabled) {
      _announceAccessibility('Finished dragging block');
    }
    
    debugPrint('🎯 Finished dragging block: ${block.blockData.id}');
  }

  /// Cancel block drag
  void _cancelBlockDrag() {
    if (_draggedBlock == null) return;
    
    _returnBlockToSlot(_draggedBlock!);
    gameWorld.gridComponent.clearHighlights();
    
    _draggedBlock = null;
    _dragStartPosition = null;
    
    _audioService.playSound('placement_cancel');
    
    debugPrint('🎯 Cancelled dragging block');
  }

  /// Select a block
  void _selectBlock(BlockComponent block) {
    // Clear previous selection
    _clearSelection();
    
    _selectedBlock = block;
    block.highlight();
    
    // Show valid placements for selected block
    gameWorld.gridComponent.highlightValidPlacements(block.blockData);
  }

  /// Clear current selection
  void _clearSelection() {
    if (_selectedBlock != null) {
      _selectedBlock!.removeHighlight();
      _selectedBlock = null;
      gameWorld.gridComponent.clearHighlights();
    }
  }

  /// Attempt smart placement of a block
  void _attemptSmartPlacement(BlockComponent block) {
    final bestPosition = _findBestPlacementPosition(block.blockData);
    
    if (bestPosition != null) {
      _placeBlock(block, bestPosition);
    } else {
      // No valid placement found
      _audioService.playSound('placement_invalid');
      
      if (_isAccessibilityEnabled) {
        _announceAccessibility('No valid placement found for this block');
      }
    }
  }

  /// Attempt to place a block at a specific grid position
  void _attemptBlockPlacement(BlockComponent block, Vector2 gridPosition) {
    if (_canPlaceBlockAt(block.blockData, gridPosition)) {
      _placeBlock(block, gridPosition);
    } else {
      _audioService.playSound('placement_invalid');
      
      if (_isAccessibilityEnabled) {
        _announceAccessibility('Cannot place block at this position');
      }
    }
  }

  /// Place a block at the specified grid position
  void _placeBlock(BlockComponent block, Vector2 gridPosition) {
    // Notify game world to handle placement
    gameWorld.placeBlock(block.blockData, gridPosition);
    
    // Audio feedback
    _audioService.playSound('block_place');
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Clear selection
    _clearSelection();
    
    // Notify game cubit
    gameCubit.onBlockPlaced(block.blockData, gridPosition);
    
    if (_isAccessibilityEnabled) {
      _announceAccessibility('Block placed successfully');
    }
    
    debugPrint('✅ Block placed at: $gridPosition');
  }

  /// Return a block to its original slot
  void _returnBlockToSlot(BlockComponent block) {
    block.returnToOriginalPosition();
    block.priority = GameConstants.activeBlockPriority;
  }

  /// Find the best placement position for a block
  Vector2? _findBestPlacementPosition(Block blockData) {
    final gridSize = gameWorld.gridComponent.gridSize;
    
    // Strategy: Try positions from top-left, prioritizing corners and edges
    final positions = <Vector2>[];
    
    // Add corner positions first
    positions.addAll([
      Vector2(0, 0), // Top-left
      Vector2(gridSize - 1, 0), // Top-right
      Vector2(0, gridSize - 1), // Bottom-left
      Vector2(gridSize - 1, gridSize - 1), // Bottom-right
    ]);
    
    // Add edge positions
    for (int i = 1; i < gridSize - 1; i++) {
      positions.addAll([
        Vector2(i, 0), // Top edge
        Vector2(i, gridSize - 1), // Bottom edge
        Vector2(0, i), // Left edge
        Vector2(gridSize - 1, i), // Right edge
      ]);
    }
    
    // Add center positions
    for (int row = 1; row < gridSize - 1; row++) {
      for (int col = 1; col < gridSize - 1; col++) {
        positions.add(Vector2(col.toDouble(), row.toDouble()));
      }
    }
    
    // Find first valid position
    for (final position in positions) {
      if (_canPlaceBlockAt(blockData, position)) {
        return position;
      }
    }
    
    return null; // No valid position found
  }

  /// Check if a block can be placed at a specific grid position
  bool _canPlaceBlockAt(Block blockData, Vector2 gridPosition) {
    final startRow = gridPosition.y.toInt();
    final startCol = gridPosition.x.toInt();
    final gridSize = gameWorld.gridComponent.gridSize;
    final occupiedCells = gameWorld.gridComponent.occupiedCells;
    
    for (int row = 0; row < blockData.shape.length; row++) {
      for (int col = 0; col < blockData.shape[row].length; col++) {
        if (blockData.shape[row][col] == 1) {
          final checkRow = startRow + row;
          final checkCol = startCol + col;
          
          // Check bounds
          if (checkRow < 0 || checkRow >= gridSize ||
              checkCol < 0 || checkCol >= gridSize) {
            return false;
          }
          
          // Check if cell is occupied
          if (occupiedCells[checkRow][checkCol]) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  /// Get block component at a specific world position
  BlockComponent? _getBlockAtPosition(Vector2 worldPosition) {
    for (final block in gameWorld.activeBlocks) {
      if (_isPositionInBlock(worldPosition, block)) {
        return block;
      }
    }
    return null;
  }

  /// Check if a position is within a block's bounds
  bool _isPositionInBlock(Vector2 position, BlockComponent block) {
    final blockRect = Rect.fromLTWH(
      block.position.x,
      block.position.y,
      block.size.x,
      block.size.y,
    );
    
    return blockRect.contains(position.toOffset());
  }

  /// Check if a position is on the game grid
  bool _isPositionOnGrid(Vector2 position) {
    final gridRect = Rect.fromLTWH(
      gameWorld.gridComponent.position.x,
      gameWorld.gridComponent.position.y,
      gameWorld.gridComponent.size.x,
      gameWorld.gridComponent.size.y,
    );
    
    return gridRect.contains(position.toOffset());
  }

  /// Convert world position to grid coordinates
  Vector2 _worldToGridPosition(Vector2 worldPosition) {
    final localPosition = worldPosition - gameWorld.gridComponent.position;
    final cellSize = gameWorld.cellSize;
    final spacing = GameConstants.gridSpacing;
    
    final col = (localPosition.x / (cellSize + spacing)).floor();
    final row = (localPosition.y / (cellSize + spacing)).floor();
    
    return Vector2(col.toDouble(), row.toDouble());
  }

  /// Check if current tap is a double tap
  bool _isDoubleTap(Vector2 position) {
    final now = DateTime.now();
    
    if (_lastTapTime != null && _lastTapPosition != null) {
      final timeDiff = now.difference(_lastTapTime!);
      final distanceDiff = (position - _lastTapPosition!).length;
      
      if (timeDiff.inMilliseconds < GameConstants.doubleTapMaxDelay &&
          distanceDiff < GameConstants.doubleTapMaxDistance) {
        _lastTapTime = null; // Reset to prevent triple tap
        _lastTapPosition = null;
        return true;
      }
    }
    
    _lastTapTime = now;
    _lastTapPosition = position;
    return false;
  }

  /// Show block preview information
  void _showBlockPreview(BlockComponent block) {
    // This would trigger a UI overlay showing block details
    gameCubit.showBlockPreview(block.blockData);
  }

  /// Show grid information at a position
  void _showGridInfo(Vector2 gridPosition) {
    // This would show grid cell information
    gameCubit.showGridInfo(gridPosition);
  }

  /// Show placement suggestions for a grid position
  void _showPlacementSuggestions(Vector2 gridPosition) {
    // This would highlight possible block placements at this position
    gameCubit.showPlacementSuggestions(gridPosition);
  }

  /// Update placement preview while dragging
  void _updatePlacementPreview(Vector2 gridPosition) {
    if (_draggedBlock == null) return;
    
    final canPlace = _canPlaceBlockAt(_draggedBlock!.blockData, gridPosition);
    
    // Update visual feedback based on placement validity
    if (canPlace) {
      _draggedBlock!.removeHighlight();
    } else {
      _draggedBlock!.highlight();
    }
  }

  /// Get description of a block for accessibility
  String _getBlockDescription(Block block) {
    final cellCount = block.shape.expand((row) => row).where((cell) => cell == 1).length;
    return 'Block with $cellCount cells, color ${block.color.toString()}';
  }

  /// Announce text for accessibility
  void _announceAccessibility(String text) {
    if (!_isAccessibilityEnabled) return;
    
    // This would use the platform's accessibility announcements
    debugPrint('♿ Accessibility: $text');
  }

  /// Handle keyboard input for accessibility
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!_isEnabled || !_isAccessibilityEnabled) return false;
    
    if (event is KeyDownEvent) {
      // Handle arrow keys for block selection/movement
      if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
        _handleKeyboardNavigation(Vector2(0, -1));
        return true;
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
        _handleKeyboardNavigation(Vector2(0, 1));
        return true;
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
        _handleKeyboardNavigation(Vector2(-1, 0));
        return true;
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
        _handleKeyboardNavigation(Vector2(1, 0));
        return true;
      } else if (keysPressed.contains(LogicalKeyboardKey.enter) || 
                 keysPressed.contains(LogicalKeyboardKey.space)) {
        _handleKeyboardSelection();
        return true;
      } else if (keysPressed.contains(LogicalKeyboardKey.escape)) {
        _clearSelection();
        return true;
      }
    }
    
    return false;
  }

  /// Handle keyboard navigation
  void _handleKeyboardNavigation(Vector2 direction) {
    // Navigate between blocks or grid cells using keyboard
    debugPrint('⌨️ Keyboard navigation: $direction');
  }

  /// Handle keyboard selection
  void _handleKeyboardSelection() {
    if (_selectedBlock != null) {
      _attemptSmartPlacement(_selectedBlock!);
    }
  }

  @override
  void onRemove() {
    _performanceMonitor.dispose();
    super.onRemove();
  }

  // Getters for external access
  bool get isEnabled => _isEnabled;
  BlockComponent? get selectedBlock => _selectedBlock;
  BlockComponent? get draggedBlock => _draggedBlock;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
}