import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/core/constants/game_constants.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import '../../../core/utils/performance_utils.dart';
import '../components/game_world.dart';

/// InputSystem handles all user input for the game including touch, drag, and tap gestures.
/// Optimized for 60 FPS performance with efficient input processing and gesture recognition.
/// Follows Clean Architecture by coordinating between presentation and domain layers.
class InputSystem extends Component {
  /// Reference to the game world
  final GameWorld gameWorld;
  
  /// Reference to the game cubit for state management
  final GameCubit gameCubit;
  
  // Input state tracking
  bool _isDragging = false;
  Vector2? _dragStartPosition;
  Vector2? _currentDragPosition;
  DateTime? _lastInputTime;
  
  // Selected block tracking
  BlockEntity? _selectedBlock;
  Vector2? _selectedBlockOffset;
  
  // Input timing for gesture recognition
  DateTime? _lastTapTime;
  Vector2? _lastTapPosition;
  int _tapCount = 0;
  
  // Performance optimization
  final List<Vector2> _inputHistory = [];
  static const int maxInputHistory = 10;
  
  // Input thresholds
  static const double dragThreshold = 10.0;
  static const double tapThreshold = 5.0;
  static const Duration doubleTapWindow = Duration(milliseconds: 300);
  static const Duration longPressThreshold = Duration(milliseconds: 500);

  InputSystem({
    required this.gameWorld,
    required this.gameCubit,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _initializeInputSystem();
  }

  void _initializeInputSystem() {
    // Initialize input system state
    _clearInputState();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateInputSystem(dt);
  }

  /// Update input system logic
  void _updateInputSystem(double dt) {
    // Clean up old input history
    _cleanupInputHistory();
    
    // Update drag state
    _updateDragState(dt);
    
    // Handle long press detection
    _handleLongPressDetection();
    
    // Update input timing
    _updateInputTiming();
  }

  /// Handle drag start event
  bool handleDragStart(Vector2 position) {
    try {
      PerformanceUtils.markFrameStart();
      
      _lastInputTime = DateTime.now();
      _dragStartPosition = position.clone();
      _currentDragPosition = position.clone();
      
      // Record input history
      _recordInputPosition(position);
      
      // Check if we're selecting a block
      final selectedBlock = _getBlockAtPosition(position);
      if (selectedBlock != null) {
        _selectBlock(selectedBlock, position);
        return true;
      }
      
      PerformanceUtils.markFrameEnd();
      return false;
      
    } catch (e) {
      _handleInputError('Drag start error', e);
      return false;
    }
  }

  /// Handle drag update event
  bool handleDragUpdate(Vector2 position, Vector2 delta) {
    try {
      PerformanceUtils.markFrameStart();
      
      _lastInputTime = DateTime.now();
      _currentDragPosition = position.clone();
      
      // Record input history
      _recordInputPosition(position);
      
      if (!_isDragging && _dragStartPosition != null) {
        final distance = position.distanceTo(_dragStartPosition!);
        if (distance > dragThreshold) {
          _startDrag();
        }
      }
      
      if (_isDragging && _selectedBlock != null) {
        _updateBlockPosition(position);
        return true;
      }
      
      PerformanceUtils.markFrameEnd();
      return false;
      
    } catch (e) {
      _handleInputError('Drag update error', e);
      return false;
    }
  }

  /// Handle drag end event
  bool handleDragEnd(Vector2 position) {
    try {
      PerformanceUtils.markFrameStart();
      
      _lastInputTime = DateTime.now();
      
      bool handled = false;
      
      if (_isDragging && _selectedBlock != null) {
        handled = _finalizeDrag(position);
      } else if (_selectedBlock != null) {
        // Handle tap/click without drag
        handled = _handleBlockTap();
      }
      
      _clearInputState();
      
      PerformanceUtils.markFrameEnd();
      return handled;
      
    } catch (e) {
      _handleInputError('Drag end error', e);
      _clearInputState();
      return false;
    }
  }

  /// Handle tap event
  bool handleTap(Vector2 position) {
    try {
      PerformanceUtils.markFrameStart();
      
      _lastInputTime = DateTime.now();
      
      // Record input history
      _recordInputPosition(position);
      
      // Handle multi-tap detection
      final isMultiTap = _detectMultiTap(position);
      
      if (isMultiTap) {
        return _handleMultiTap(position);
      } else {
        return _handleSingleTap(position);
      }
      
    } catch (e) {
      _handleInputError('Tap error', e);
      return false;
    } finally {
      PerformanceUtils.markFrameEnd();
    }
  }

  /// Get block at the given position
  BlockEntity? _getBlockAtPosition(Vector2 position) {
    final gridPosition = _screenToGridPosition(position);
    
    // Check if position is within grid bounds
    if (!_isValidGridPosition(gridPosition)) {
      return null;
    }
    
    // Get block from game world at this position
    return gameWorld.getBlockAtPosition(gridPosition.x.round(), gridPosition.y.round());
  }

  /// Convert screen position to grid coordinates
  Vector2 _screenToGridPosition(Vector2 screenPosition) {
    final gridBounds = gameWorld.gridBounds;
    final cellSize = gameWorld.cellSize;
    
    final relativeX = screenPosition.x - gridBounds.left;
    final relativeY = screenPosition.y - gridBounds.top;
    
    final gridX = relativeX / cellSize;
    final gridY = relativeY / cellSize;
    
    return Vector2(gridX, gridY);
  }

  /// Check if grid position is valid
  bool _isValidGridPosition(Vector2 gridPosition) {
    final gridSize = gameWorld.gridSize;
    return gridPosition.x >= 0 && 
           gridPosition.x < gridSize && 
           gridPosition.y >= 0 && 
           gridPosition.y < gridSize;
  }

  /// Select a block for manipulation
  void _selectBlock(BlockEntity block, Vector2 position) {
    _selectedBlock = block;
    
    // Calculate offset from block center
    final blockCenter = _getBlockCenterPosition(block);
    _selectedBlockOffset = position - blockCenter;
    
    // Notify game cubit of block selection
    gameCubit.selectBlock(block);
  }

  /// Get block center position in screen coordinates
  Vector2 _getBlockCenterPosition(BlockEntity block) {
    final gridBounds = gameWorld.gridBounds;
    final cellSize = gameWorld.cellSize;
    
    final centerX = gridBounds.left + (block.position.x + 0.5) * cellSize;
    final centerY = gridBounds.top + (block.position.y + 0.5) * cellSize;
    
    return Vector2(centerX, centerY);
  }

  /// Start dragging operation
  void _startDrag() {
    _isDragging = true;
    
    if (_selectedBlock != null) {
      gameCubit.startBlockDrag(_selectedBlock!);
    }
  }

  /// Update block position during drag
  void _updateBlockPosition(Vector2 dragPosition) {
    if (_selectedBlock == null) return;
    
    // Calculate new position accounting for offset
    final adjustedPosition = _selectedBlockOffset != null
        ? dragPosition - _selectedBlockOffset!
        : dragPosition;
    
    final newGridPosition = _screenToGridPosition(adjustedPosition);
    
    // Validate and update block position
    if (_isValidBlockPosition(newGridPosition)) {
      final newPosition = Position(
        newGridPosition.x.round(),
        newGridPosition.y.round(),
      );
      
      gameCubit.updateBlockPosition(_selectedBlock!, newPosition);
    }
  }

  /// Check if block can be placed at position
  bool _isValidBlockPosition(Vector2 gridPosition) {
    if (_selectedBlock == null) return false;
    
    final position = Position(
      gridPosition.x.round(),
      gridPosition.y.round(),
    );
    
    return gameWorld.canPlaceBlockAt(_selectedBlock!, position);
  }

  /// Finalize drag operation
  bool _finalizeDrag(Vector2 finalPosition) {
    if (_selectedBlock == null) return false;
    
    final gridPosition = _screenToGridPosition(finalPosition);
    
    if (_isValidBlockPosition(gridPosition)) {
      final finalGridPosition = Position(
        gridPosition.x.round(),
        gridPosition.y.round(),
      );
      
      gameCubit.placeBlock(_selectedBlock!, finalGridPosition);
      return true;
    } else {
      // Invalid position - return block to original position
      gameCubit.cancelBlockDrag(_selectedBlock!);
      return false;
    }
  }

  /// Handle block tap without drag
  bool _handleBlockTap() {
    if (_selectedBlock == null) return false;
    
    // Rotate block on tap
    gameCubit.rotateBlock(_selectedBlock!);
    return true;
  }

  /// Detect multi-tap gesture
  bool _detectMultiTap(Vector2 position) {
    final now = DateTime.now();
    
    if (_lastTapTime != null && _lastTapPosition != null) {
      final timeDiff = now.difference(_lastTapTime!);
      final positionDiff = position.distanceTo(_lastTapPosition!);
      
      if (timeDiff < doubleTapWindow && positionDiff < tapThreshold) {
        _tapCount++;
        _lastTapTime = now;
        _lastTapPosition = position.clone();
        return _tapCount >= 2;
      }
    }
    
    _tapCount = 1;
    _lastTapTime = now;
    _lastTapPosition = position.clone();
    return false;
  }

  /// Handle multi-tap gesture
  bool _handleMultiTap(Vector2 position) {
    // Double tap to instantly place block at best position
    final block = _getBlockAtPosition(position);
    if (block != null) {
      final bestPosition = _findBestPositionForBlock(block);
      if (bestPosition != null) {
        gameCubit.placeBlock(block, bestPosition);
        return true;
      }
    }
    
    return false;
  }

  /// Handle single tap gesture
  bool _handleSingleTap(Vector2 position) {
    final block = _getBlockAtPosition(position);
    if (block != null) {
      return _handleBlockTap();
    }
    
    // Tap on empty area - could trigger special actions
    return _handleEmptyAreaTap(position);
  }

  /// Handle tap on empty area
  bool _handleEmptyAreaTap(Vector2 position) {
    // Could be used for special actions like power-ups
    // For now, just clear selection
    gameCubit.clearSelection();
    return false;
  }

  /// Find best position for block placement
  Position? _findBestPositionForBlock(BlockEntity block) {
    final gridSize = gameWorld.gridSize;
    
    // Start from bottom and work up
    for (int row = gridSize - 1; row >= 0; row--) {
      for (int col = 0; col < gridSize; col++) {
        final position = Position(col, row);
        if (gameWorld.canPlaceBlockAt(block, position)) {
          return position;
        }
      }
    }
    
    return null;
  }

  /// Handle long press detection
  void _handleLongPressDetection() {
    if (_dragStartPosition == null || _lastInputTime == null) return;
    
    final elapsed = DateTime.now().difference(_lastInputTime!);
    if (elapsed > longPressThreshold && !_isDragging && _selectedBlock != null) {
      _handleLongPress();
    }
  }

  /// Handle long press gesture
  void _handleLongPress() {
    if (_selectedBlock != null) {
      // Long press could trigger special actions
      gameCubit.showBlockOptions(_selectedBlock!);
    }
  }

  /// Record input position for gesture analysis
  void _recordInputPosition(Vector2 position) {
    _inputHistory.add(position.clone());
    
    if (_inputHistory.length > maxInputHistory) {
      _inputHistory.removeAt(0);
    }
  }

  /// Clean up old input history
  void _cleanupInputHistory() {
    // Remove positions older than 1 second
    final cutoff = DateTime.now().subtract(const Duration(seconds: 1));
    // Note: In a real implementation, you'd need to store timestamps with positions
  }

  /// Update drag state
  void _updateDragState(double dt) {
    if (_isDragging && _currentDragPosition != null) {
      // Update visual feedback for dragging
      gameWorld.updateDragPreview(_selectedBlock, _currentDragPosition!);
    }
  }

  /// Update input timing
  void _updateInputTiming() {
    // Clean up old tap tracking
    if (_lastTapTime != null) {
      final elapsed = DateTime.now().difference(_lastTapTime!);
      if (elapsed > doubleTapWindow) {
        _tapCount = 0;
      }
    }
  }

  /// Clear input state
  void _clearInputState() {
    _isDragging = false;
    _dragStartPosition = null;
    _currentDragPosition = null;
    _selectedBlock = null;
    _selectedBlockOffset = null;
  }

  /// Handle input errors gracefully
  void _handleInputError(String context, dynamic error) {
    // Log error but don't crash the game
    print('Input system error in $context: $error');
    
    // Clear state to prevent cascading errors
    _clearInputState();
  }

  /// System update method for external use
  void updateSystem(double dt) {
    update(dt);
  }

  /// Get input velocity for physics calculations
  Vector2 getInputVelocity() {
    if (_inputHistory.length < 2) return Vector2.zero();
    
    final recent = _inputHistory.last;
    final previous = _inputHistory[_inputHistory.length - 2];
    
    return recent - previous;
  }

  /// Check if input is currently active
  bool get isInputActive => _isDragging || _selectedBlock != null;

  /// Get currently selected block
  BlockEntity? get selectedBlock => _selectedBlock;
}