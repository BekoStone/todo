import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/core/constants/game_constants.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import '../../../core/utils/performance_utils.dart' hide Vector2;
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
      if (GameConstants.enablePerformanceMonitoring) {
        PerformanceUtils.markFrameStart();
      }
      
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
      
      if (GameConstants.enablePerformanceMonitoring) {
        PerformanceUtils.markFrameEnd();
      }
      return false;
      
    } catch (e) {
      _handleInputError('Drag start error', e);
      return false;
    }
  }

  /// Handle drag update event
  bool handleDragUpdate(Vector2 position, Vector2 delta) {
    try {
      if (GameConstants.enablePerformanceMonitoring) {
        PerformanceUtils.markFrameStart();
      }
      
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
      }
      
      if (GameConstants.enablePerformanceMonitoring) {
        PerformanceUtils.markFrameEnd();
      }
      return _isDragging;
      
    } catch (e) {
      _handleInputError('Drag update error', e);
      return false;
    }
  }

  /// Handle drag end event
  bool handleDragEnd(Vector2 position) {
    try {
      if (GameConstants.enablePerformanceMonitoring) {
        PerformanceUtils.markFrameStart();
      }
      
      _lastInputTime = DateTime.now();
      
      bool wasDragging = _isDragging;
      
      if (_isDragging && _selectedBlock != null) {
        _completeDrag(position);
      }
      
      _clearDragState();
      
      if (GameConstants.enablePerformanceMonitoring) {
        PerformanceUtils.markFrameEnd();
      }
      return wasDragging;
      
    } catch (e) {
      _handleInputError('Drag end error', e);
      return false;
    }
  }

  /// Handle tap event
  bool handleTap(Vector2 position) {
    try {
      if (GameConstants.enablePerformanceMonitoring) {
        PerformanceUtils.markFrameStart();
      }
      
      final now = DateTime.now();
      
      // Check for double tap
      if (_lastTapTime != null && _lastTapPosition != null) {
        final timeDifference = now.difference(_lastTapTime!);
        final positionDifference = position.distanceTo(_lastTapPosition!);
        
        if (timeDifference <= doubleTapWindow && positionDifference <= tapThreshold) {
          _tapCount++;
          return _handleMultiTap(position, _tapCount);
        }
      }
      
      _tapCount = 1;
      _lastTapTime = now;
      _lastTapPosition = position.clone();
      
      return _handleSingleTap(position);
      
    } catch (e) {
      _handleInputError('Tap error', e);
      return false;
    } finally {
      if (GameConstants.enablePerformanceMonitoring) {
        PerformanceUtils.markFrameEnd();
      }
    }
  }

  /// Handle single tap
  bool _handleSingleTap(Vector2 position) {
    final block = _getBlockAtPosition(position);
    
    if (block != null) {
      _selectBlock(block, position);
      gameCubit.selectBlock(block);
      return true;
    }
    
    // Check if tapping on valid placement area
    final gridPosition = _screenToGridPosition(position);
    if (_isValidGridPosition(gridPosition)) {
      _handleGridTap(gridPosition);
      return true;
    }
    
    return false;
  }

  /// Handle multi-tap (double tap, triple tap, etc.)
  bool _handleMultiTap(Vector2 position, int tapCount) {
    switch (tapCount) {
      case 2:
        return _handleDoubleTap(position);
      case 3:
        return _handleTripleTap(position);
      default:
        return false;
    }
  }

  /// Handle double tap
  bool _handleDoubleTap(Vector2 position) {
    final block = _getBlockAtPosition(position);
    
    if (block != null) {
      // Double tap to rotate block
      final rotatedBlock = block.rotateClockwise();
      gameCubit.updateBlockPosition(rotatedBlock, rotatedBlock.position.y, rotatedBlock.position.x);
      return true;
    }
    
    return false;
  }

  /// Handle triple tap
  bool _handleTripleTap(Vector2 position) {
    final block = _getBlockAtPosition(position);
    
    if (block != null) {
      // Triple tap for special action (e.g., remove block)
      _removeBlock(block);
      return true;
    }
    
    return false;
  }

  /// Handle grid tap (placing block or other grid actions)
  void _handleGridTap(Vector2 gridPosition) {
    if (_selectedBlock != null) {
      final row = gridPosition.y.round();
      final col = gridPosition.x.round();
      
      if (_canPlaceBlock(_selectedBlock!, row, col)) {
        gameCubit.placeBlock(_selectedBlock!, row, col);
        _selectedBlock = null;
      }
    }
  }

  /// Get block at screen position
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
    
    final gridPosition = _screenToGridPosition(adjustedPosition);
    
    if (_isValidGridPosition(gridPosition)) {
      final row = gridPosition.y.round();
      final col = gridPosition.x.round();
      
      gameCubit.updateBlockPosition(_selectedBlock!, row, col);
    }
  }

  /// Complete drag operation
  void _completeDrag(Vector2 endPosition) {
    if (_selectedBlock == null) return;
    
    final adjustedPosition = _selectedBlockOffset != null
        ? endPosition - _selectedBlockOffset!
        : endPosition;
    
    final gridPosition = _screenToGridPosition(adjustedPosition);
    
    if (_isValidGridPosition(gridPosition)) {
      final row = gridPosition.y.round();
      final col = gridPosition.x.round();
      
      if (_canPlaceBlock(_selectedBlock!, row, col)) {
        gameCubit.completeDrag(_selectedBlock!, row, col);
      }
    }
  }

  /// Check if block can be placed at position
  bool _canPlaceBlock(BlockEntity block, int row, int col) {
    // Use game cubit to validate placement
    return gameWorld.canPlaceBlockAt(block, row, col);
  }

  /// Remove block from game
  void _removeBlock(BlockEntity block) {
    // Implementation for removing block
    // This would depend on game rules
  }

  /// Clear all input state
  void _clearInputState() {
    _isDragging = false;
    _dragStartPosition = null;
    _currentDragPosition = null;
    _selectedBlock = null;
    _selectedBlockOffset = null;
    _lastTapTime = null;
    _lastTapPosition = null;
    _tapCount = 0;
    _inputHistory.clear();
  }

  /// Clear drag state specifically
  void _clearDragState() {
    _isDragging = false;
    _dragStartPosition = null;
    _currentDragPosition = null;
    _selectedBlock = null;
    _selectedBlockOffset = null;
  }

  /// Record input position for history tracking
  void _recordInputPosition(Vector2 position) {
    _inputHistory.add(position.clone());
    
    // Keep history size manageable
    if (_inputHistory.length > maxInputHistory) {
      _inputHistory.removeAt(0);
    }
  }

  /// Clean up old input history
  void _cleanupInputHistory() {
    // Remove history older than a certain threshold
    final cutoffTime = DateTime.now().subtract(const Duration(seconds: 1));
    
    // For simplicity, just maintain max size
    while (_inputHistory.length > maxInputHistory) {
      _inputHistory.removeAt(0);
    }
  }

  /// Update drag state over time
  void _updateDragState(double dt) {
    if (_isDragging && _currentDragPosition != null) {
      // Update drag visuals or state as needed
    }
  }

  /// Handle long press detection
  void _handleLongPressDetection() {
    if (_dragStartPosition != null && !_isDragging) {
      final elapsed = DateTime.now().difference(_lastInputTime ?? DateTime.now());
      
      if (elapsed >= longPressThreshold) {
        _handleLongPress(_dragStartPosition!);
        _clearDragState(); // Prevent drag from starting after long press
      }
    }
  }

  /// Handle long press event
  void _handleLongPress(Vector2 position) {
    final block = _getBlockAtPosition(position);
    
    if (block != null) {
      // Long press for context menu or special action
      _showBlockContextMenu(block, position);
    }
  }

  /// Show context menu for block
  void _showBlockContextMenu(BlockEntity block, Vector2 position) {
    // Implementation for showing context menu
    // This would integrate with UI system
  }

  /// Update input timing
  void _updateInputTiming() {
    final now = DateTime.now();
    
    // Reset tap count if too much time has passed
    if (_lastTapTime != null && now.difference(_lastTapTime!) > doubleTapWindow) {
      _tapCount = 0;
      _lastTapTime = null;
      _lastTapPosition = null;
    }
  }

  /// Handle input errors with graceful degradation
  void _handleInputError(String context, dynamic error) {
    print('Input system error in $context: $error');
    
    // Reset input state to prevent stuck states
    _clearInputState();
    
    // Log error for debugging
    if (GameConstants.enableDebugMode) {
      print('Input system stack trace: ${StackTrace.current}');
    }
  }

  /// Get input velocity for physics calculations
  Vector2 getInputVelocity() {
    if (_inputHistory.length < 2) return Vector2.zero();
    
    final recent = _inputHistory.last;
    final previous = _inputHistory[_inputHistory.length - 2];
    
    return recent - previous;
  }

  /// Get average input position
  Vector2 getAverageInputPosition() {
    if (_inputHistory.isEmpty) return Vector2.zero();
    
    var sum = Vector2.zero();
    for (final position in _inputHistory) {
      sum += position;
    }
    
    return sum / _inputHistory.length.toDouble();
  }

  /// Check if input is currently active
  bool get isInputActive => _isDragging || _selectedBlock != null;

  /// Get currently selected block
  BlockEntity? get selectedBlock => _selectedBlock;

  /// Check if currently dragging
  bool get isDragging => _isDragging;
}