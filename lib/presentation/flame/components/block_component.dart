import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/performance_utils.dart';

/// A Flame component representing a game block.
/// Handles rendering, animation, and user interaction for blocks.
/// Follows Clean Architecture by being a pure presentation component.
class BlockComponent extends PositionComponent with DragCallbacks, TapCallbacks, HasGameRef {
  // Block data from domain layer
  final Block blockData;
  final double cellSize;
  final bool isPlaced;
  final bool isSelected;
  
  // Interaction callbacks
  final void Function(BlockComponent)? onDragStart;
  final void Function(BlockComponent, Vector2)? onDragEnd;
  final void Function(BlockComponent)? onTap;
  final void Function(BlockComponent)? onLongPress;
  
  // Visual components
  final List<RectangleComponent> _cells = [];
  late RectangleComponent _shadowComponent;
  late RectangleComponent _highlightComponent;
  
  // State
  bool _isDragging = false;
  bool _isHighlighted = false;
  Vector2? _originalPosition;
  double _originalScale = 1.0;
  
  // Animation controllers
  final List<Effect> _activeEffects = [];
  
  // Performance monitoring
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  BlockComponent({
    required this.blockData,
    required this.cellSize,
    this.isPlaced = false,
    this.isSelected = false,
    this.onDragStart,
    this.onDragEnd,
    this.onTap,
    this.onLongPress,
  }) {
    _calculateSize();
    _originalScale = scale.x;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    await _createVisualComponents();
    await _setupInitialState();
    
    debugPrint('🧱 BlockComponent loaded - ID: ${blockData.id}');
  }

  /// Calculate the component size based on block shape
  void _calculateSize() {
    final rows = blockData.shape.length;
    final cols = blockData.shape.isNotEmpty ? blockData.shape[0].length : 0;
    
    final width = cols * cellSize + (cols - 1) * GameConstants.blockCellSpacing;
    final height = rows * cellSize + (rows - 1) * GameConstants.blockCellSpacing;
    
    size = Vector2(width, height);
  }

  /// Create all visual components for the block
  Future<void> _createVisualComponents() async {
    _performanceMonitor.startTracking('create_visuals');
    
    // Create shadow component (rendered first)
    await _createShadowComponent();
    
    // Create highlight component
    await _createHighlightComponent();
    
    // Create individual cell components
    await _createCellComponents();
    
    _performanceMonitor.stopTracking('create_visuals');
  }

  /// Create the shadow component for depth effect
  Future<void> _createShadowComponent() async {
    _shadowComponent = RectangleComponent(
      size: size + Vector2.all(GameConstants.blockShadowOffset),
      position: Vector2.all(GameConstants.blockShadowOffset / 2),
      paint: Paint()
        ..color = AppColors.shadow.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    
    // Shadow should be behind everything
    _shadowComponent.priority = -2;
    add(_shadowComponent);
  }

  /// Create the highlight component for selection feedback
  Future<void> _createHighlightComponent() async {
    _highlightComponent = RectangleComponent(
      size: size + Vector2.all(GameConstants.blockHighlightWidth * 2),
      position: Vector2.all(-GameConstants.blockHighlightWidth),
      paint: Paint()
        ..color = AppColors.accent.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameConstants.blockHighlightWidth,
    );
    
    _highlightComponent.priority = -1;
    _highlightComponent.opacity = 0.0; // Hidden by default
    add(_highlightComponent);
  }

  /// Create individual cell components based on block shape
  Future<void> _createCellComponents() async {
    final shape = blockData.shape;
    
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          await _createSingleCell(row, col);
        }
      }
    }
  }

  /// Create a single cell component
  Future<void> _createSingleCell(int row, int col) async {
    final cellPosition = Vector2(
      col * (cellSize + GameConstants.blockCellSpacing),
      row * (cellSize + GameConstants.blockCellSpacing),
    );
    
    // Main cell background
    final cellBackground = RectangleComponent(
      position: cellPosition,
      size: Vector2.all(cellSize),
      paint: Paint()
        ..shader = _createCellGradient(blockData.color)
        ..style = PaintingStyle.fill,
    );
    
    // Cell border
    final cellBorder = RectangleComponent(
      position: cellPosition,
      size: Vector2.all(cellSize),
      paint: Paint()
        ..color = _getCellBorderColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameConstants.blockBorderWidth,
    );
    
    // Inner highlight for 3D effect
    final innerHighlight = RectangleComponent(
      position: cellPosition + Vector2.all(GameConstants.blockBorderWidth),
      size: Vector2.all(cellSize - GameConstants.blockBorderWidth * 2),
      paint: Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    
    // Add corner rounding if enabled
    if (GameConstants.enableRoundedBlocks) {
      cellBackground.decorator.addLast(PaintDecorator.blur(0.5));
    }
    
    _cells.addAll([cellBackground, cellBorder, innerHighlight]);
    
    add(cellBackground);
    add(cellBorder);
    add(innerHighlight);
  }

  /// Create gradient for cell background
  Shader _createCellGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.9),
        baseColor,
        baseColor.withOpacity(0.7),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, cellSize, cellSize));
  }

  /// Get border color based on block state
  Color _getCellBorderColor() {
    if (isSelected) {
      return AppColors.accent;
    } else if (_isHighlighted) {
      return AppColors.accent.withOpacity(0.8);
    } else if (isPlaced) {
      return Colors.white.withOpacity(0.3);
    } else {
      return Colors.white.withOpacity(0.6);
    }
  }

  /// Setup initial component state
  Future<void> _setupInitialState() async {
    // Set initial priority
    priority = isPlaced ? GameConstants.placedBlockPriority : GameConstants.activeBlockPriority;
    
    // Store original position for drag operations
    _originalPosition = position.clone();
    
    // Apply initial scale for placed blocks
    if (isPlaced) {
      scale = Vector2.all(0.0);
      add(ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(
          duration: 0.3,
          curve: Curves.elasticOut,
        ),
      ));
    }
  }

  /// Handle drag start
  @override
  bool onDragStart(DragStartEvent event) {
    if (isPlaced || _isDragging) return false;
    
    _performanceMonitor.startTracking('drag_operation');
    
    _isDragging = true;
    _originalPosition = position.clone();
    
    // Visual feedback
    _startDragVisualFeedback();
    
    // Notify parent
    onDragStart?.call(this);
    
    debugPrint('🎯 Block drag started - ID: ${blockData.id}');
    return true;
  }

  /// Handle drag update
  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) return false;
    
    position += event.localDelta;
    return true;
  }

  /// Handle drag end
  @override
  bool onDragEnd(DragEndEvent event) {
    if (!_isDragging) return false;
    
    _isDragging = false;
    
    // Stop visual feedback
    _stopDragVisualFeedback();
    
    // Notify parent with final position
    onDragEnd?.call(this, position);
    
    _performanceMonitor.stopTracking('drag_operation');
    
    debugPrint('🎯 Block drag ended - ID: ${blockData.id}');
    return true;
  }

  /// Handle drag cancel
  @override
  bool onDragCancel(DragCancelEvent event) {
    if (!_isDragging) return false;
    
    _isDragging = false;
    
    // Return to original position
    returnToOriginalPosition();
    
    // Stop visual feedback
    _stopDragVisualFeedback();
    
    _performanceMonitor.stopTracking('drag_operation');
    
    debugPrint('🎯 Block drag cancelled - ID: ${blockData.id}');
    return true;
  }

  /// Handle tap
  @override
  bool onTapUp(TapUpEvent event) {
    if (isPlaced || _isDragging) return false;
    
    onTap?.call(this);
    
    // Add tap feedback
    _addTapFeedback();
    
    debugPrint('👆 Block tapped - ID: ${blockData.id}');
    return true;
  }

  /// Handle long press
  @override
  bool onLongTapDown(TapDownEvent event) {
    if (isPlaced || _isDragging) return false;
    
    onLongPress?.call(this);
    
    // Add long press feedback
    _addLongPressFeedback();
    
    debugPrint('🖱️ Block long pressed - ID: ${blockData.id}');
    return true;
  }

  /// Start visual feedback for drag operation
  void _startDragVisualFeedback() {
    // Increase scale
    final scaleEffect = ScaleEffect.to(
      Vector2.all(_originalScale * 1.1),
      EffectController(duration: 0.1),
    );
    
    // Add glow effect
    final glowEffect = OpacityEffect.to(
      0.8,
      EffectController(duration: 0.1),
      target: _highlightComponent,
    );
    
    // Increase priority to render on top
    priority = GameConstants.draggingBlockPriority;
    
    _activeEffects.addAll([scaleEffect, glowEffect]);
    add(scaleEffect);
    add(glowEffect);
  }

  /// Stop visual feedback for drag operation
  void _stopDragVisualFeedback() {
    // Return to original scale
    final scaleEffect = ScaleEffect.to(
      Vector2.all(_originalScale),
      EffectController(duration: 0.2),
    );
    
    // Hide glow effect
    final glowEffect = OpacityEffect.to(
      0.0,
      EffectController(duration: 0.2),
      target: _highlightComponent,
    );
    
    // Reset priority
    priority = isPlaced ? GameConstants.placedBlockPriority : GameConstants.activeBlockPriority;
    
    _activeEffects.addAll([scaleEffect, glowEffect]);
    add(scaleEffect);
    add(glowEffect);
  }

  /// Add tap feedback animation
  void _addTapFeedback() {
    final effect = ScaleEffect.by(
      Vector2.all(0.1),
      EffectController(
        duration: 0.1,
        alternate: true,
        repeatCount: 1,
      ),
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Add long press feedback animation
  void _addLongPressFeedback() {
    final effect = OpacityEffect.to(
      0.7,
      EffectController(
        duration: 0.2,
        alternate: true,
        repeatCount: 1,
      ),
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Highlight the block (for valid placement indication)
  void highlight() {
    if (_isHighlighted) return;
    
    _isHighlighted = true;
    
    final effect = OpacityEffect.to(
      1.0,
      EffectController(duration: 0.2),
      target: _highlightComponent,
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Remove highlight from the block
  void removeHighlight() {
    if (!_isHighlighted) return;
    
    _isHighlighted = false;
    
    final effect = OpacityEffect.to(
      0.0,
      EffectController(duration: 0.2),
      target: _highlightComponent,
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Return block to its original position with animation
  void returnToOriginalPosition() {
    if (_originalPosition == null) return;
    
    final effect = MoveEffect.to(
      _originalPosition!,
      EffectController(
        duration: 0.3,
        curve: Curves.easeOut,
      ),
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Update the block's position (for slot repositioning)
  void updatePosition(Vector2 newPosition, {bool animate = true}) {
    _originalPosition = newPosition.clone();
    
    if (animate) {
      final effect = MoveEffect.to(
        newPosition,
        EffectController(
          duration: 0.3,
          curve: Curves.easeOut,
        ),
      );
      
      _activeEffects.add(effect);
      add(effect);
    } else {
      position = newPosition;
    }
  }

  /// Play destruction animation for line clearing
  void playDestructionAnimation() {
    // Scale down effect
    final scaleEffect = ScaleEffect.to(
      Vector2.zero(),
      EffectController(
        duration: 0.3,
        curve: Curves.easeIn,
      ),
    );
    
    // Fade out effect
    final fadeEffect = OpacityEffect.to(
      0.0,
      EffectController(
        duration: 0.3,
        curve: Curves.easeIn,
      ),
    );
    
    // Rotation effect for dramatic flair
    final rotateEffect = RotateEffect.by(
      3.14159, // 180 degrees
      EffectController(
        duration: 0.3,
        curve: Curves.easeIn,
      ),
    );
    
    _activeEffects.addAll([scaleEffect, fadeEffect, rotateEffect]);
    
    add(scaleEffect);
    add(fadeEffect);
    add(rotateEffect);
    
    // Remove component after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      removeFromParent();
    });
  }

  /// Update cell colors (for power-up effects)
  void updateCellColors(Color newColor) {
    final newShader = _createCellGradient(newColor);
    
    for (final cell in _cells) {
      if (cell.paint.style == PaintingStyle.fill) {
        cell.paint.shader = newShader;
      }
    }
  }

  /// Add pulsing animation (for power-up blocks)
  void addPulsingAnimation() {
    final effect = ScaleEffect.by(
      Vector2.all(0.1),
      EffectController(
        duration: 1.0,
        infinite: true,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Stop all animations
  void stopAllAnimations() {
    for (final effect in _activeEffects) {
      effect.removeFromParent();
    }
    _activeEffects.clear();
  }

  /// Check if this block can fit at a specific grid position
  bool canFitAtPosition(Vector2 gridPosition, List<List<bool>> occupiedCells) {
    final startRow = gridPosition.y.toInt();
    final startCol = gridPosition.x.toInt();
    
    for (int row = 0; row < blockData.shape.length; row++) {
      for (int col = 0; col < blockData.shape[row].length; col++) {
        if (blockData.shape[row][col] == 1) {
          final checkRow = startRow + row;
          final checkCol = startCol + col;
          
          // Check bounds
          if (checkRow < 0 || checkRow >= occupiedCells.length ||
              checkCol < 0 || checkCol >= occupiedCells[0].length) {
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

  /// Get all grid positions occupied by this block
  List<Vector2> getOccupiedPositions(Vector2 gridPosition) {
    final positions = <Vector2>[];
    final startRow = gridPosition.y.toInt();
    final startCol = gridPosition.x.toInt();
    
    for (int row = 0; row < blockData.shape.length; row++) {
      for (int col = 0; col < blockData.shape[row].length; col++) {
        if (blockData.shape[row][col] == 1) {
          positions.add(Vector2(
            (startCol + col).toDouble(),
            (startRow + row).toDouble(),
          ));
        }
      }
    }
    
    return positions;
  }

  @override
  void onRemove() {
    // Clean up performance monitoring
    _performanceMonitor.dispose();
    
    // Stop all animations
    stopAllAnimations();
    
    super.onRemove();
  }

  // Getters
  bool get isDragging => _isDragging;
  bool get isHighlighted => _isHighlighted;
  Vector2? get originalPosition => _originalPosition;
  List<RectangleComponent> get cells => List.unmodifiable(_cells);
}