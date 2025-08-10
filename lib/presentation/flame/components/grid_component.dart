import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/performance_utils.dart' hide Vector2;
import 'block_component.dart';

/// A Flame component representing the game grid.
/// Handles grid rendering, cell highlighting, and placement validation.
/// Follows Clean Architecture by being a pure presentation component.
class GridComponent extends PositionComponent with TapCallbacks, HasGameRef {
  // Configuration
  final int gridSize;
  final double cellSize;
  final double spacing = GameConstants.gridSpacing;
  
  // Callbacks
  final void Function(Vector2)? onCellTapped;
  final void Function(BlockComponent, Vector2)? onBlockDropped;
  
  // Visual components
  final List<List<RectangleComponent>> _cells = [];
  final List<List<RectangleComponent>> _highlights = [];
  final List<List<bool>> _highlightedCells = [];
  
  // Grid state
  final List<List<bool>> _occupiedCells = [];
  
  // Visual effects
  late RectangleComponent _gridBorder;
  late RectangleComponent _gridBackground;
  final List<Effect> _activeEffects = [];
  
  // Performance monitoring
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  GridComponent({
    required this.gridSize,
    required this.cellSize,
    this.onCellTapped,
    this.onBlockDropped,
  }) {
    _initializeGridState();
    _calculateSize();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    await _createGridComponents();
    await _setupGridLayout();
    
    debugPrint('🔳 GridComponent loaded - Size: ${gridSize}x$gridSize, Cell: ${cellSize}px');
  }

  /// Initialize grid state arrays
  void _initializeGridState() {
    for (int i = 0; i < gridSize; i++) {
      _cells.add(<RectangleComponent>[]);
      _highlights.add(<RectangleComponent>[]);
      _highlightedCells.add(<bool>[]);
      _occupiedCells.add(<bool>[]);
      
      for (int j = 0; j < gridSize; j++) {
        _highlightedCells[i].add(false);
        _occupiedCells[i].add(false);
      }
    }
  }

  /// Calculate the total grid size
  void _calculateSize() {
    final totalWidth = gridSize * cellSize + (gridSize - 1) * spacing;
    final totalHeight = totalWidth; // Square grid
    
    size = Vector2(totalWidth, totalHeight);
  }

  /// Create all grid visual components
  Future<void> _createGridComponents() async {
    _performanceMonitor.startTracking('create_grid');
    
    await _createGridBackground();
    await _createGridBorder();
    await _createGridCells();
    await _createHighlightCells();
    
    _performanceMonitor.stopTracking('create_grid');
  }

  /// Create the grid background
  Future<void> _createGridBackground() async {
    _gridBackground = RectangleComponent(
      size: size + Vector2.all(GameConstants.gridBackgroundPadding * 2),
      position: Vector2.all(-GameConstants.gridBackgroundPadding),
      paint: Paint()
        ..shader = _createGridBackgroundGradient()
        ..style = PaintingStyle.fill,
    );
    
    _gridBackground.priority = -3;
    add(_gridBackground);
  }

  /// Create the grid border
  Future<void> _createGridBorder() async {
    _gridBorder = RectangleComponent(
      size: size + Vector2.all(GameConstants.gridBorderWidth),
      position: Vector2.all(-GameConstants.gridBorderWidth / 2),
      paint: Paint()
        ..color = AppColors.primary.withValues(alpha:0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameConstants.gridBorderWidth,
    );
    
    _gridBorder.priority = -1;
    add(_gridBorder);
  }

  /// Create individual grid cells
  Future<void> _createGridCells() async {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        await _createSingleCell(row, col);
      }
    }
  }

  /// Create a single grid cell
  Future<void> _createSingleCell(int row, int col) async {
    final cellPosition = Vector2(
      col * (cellSize + spacing),
      row * (cellSize + spacing),
    );
    
    // Cell background
    final cell = RectangleComponent(
      position: cellPosition,
      size: Vector2.all(cellSize),
      paint: Paint()
        ..color = _getCellBackgroundColor(row, col)
        ..style = PaintingStyle.fill,
    );
    
    // Cell border
    final cellBorder = RectangleComponent(
      position: cellPosition,
      size: Vector2.all(cellSize),
      paint: Paint()
        ..color = _getCellBorderColor(row, col)
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameConstants.gridCellBorderWidth,
    );
    
    cell.priority = -2;
    cellBorder.priority = -1;
    
    _cells[row].add(cell);
    add(cell);
    add(cellBorder);
  }

  /// Create highlight overlays for each cell
  Future<void> _createHighlightCells() async {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        await _createSingleHighlight(row, col);
      }
    }
  }

  /// Create a single highlight overlay
  Future<void> _createSingleHighlight(int row, int col) async {
    final cellPosition = Vector2(
      col * (cellSize + spacing),
      row * (cellSize + spacing),
    );
    
    final highlight = RectangleComponent(
      position: cellPosition,
      size: Vector2.all(cellSize),
      paint: Paint()
        ..color = AppColors.accent.withValues(alpha:0.4)
        ..style = PaintingStyle.fill,
    );
    
    highlight.priority = 1;
    highlight.opacity = 0.0; // Hidden by default
    
    _highlights[row].add(highlight);
    add(highlight);
  }

  /// Setup grid layout and positioning
  Future<void> _setupGridLayout() async {
    // Add subtle grid animation on load
    scale = Vector2.all(0.8);
    opacity = 0.0;
    
    final scaleEffect = ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(
        duration: 0.5,
        curve: Curves.elasticOut,
      ),
    );
    
    final fadeEffect = OpacityEffect.to(
      1.0,
      EffectController(
        duration: 0.3,
        curve: Curves.easeOut,
      ),
    );
    
    _activeEffects.addAll([scaleEffect, fadeEffect]);
    add(scaleEffect);
    add(fadeEffect);
  }

  /// Create gradient for grid background
  Shader _createGridBackgroundGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.surface.withValues(alpha:0.8),
        AppColors.surface.withValues(alpha:0.6),
        AppColors.surface.withValues(alpha:0.4),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(
      -GameConstants.gridBackgroundPadding,
      -GameConstants.gridBackgroundPadding,
      size.x + GameConstants.gridBackgroundPadding * 2,
      size.y + GameConstants.gridBackgroundPadding * 2,
    ));
  }

  /// Get background color for a specific cell
  Color _getCellBackgroundColor(int row, int col) {
    // Checkerboard pattern for better visual clarity
    final isEvenCell = (row + col) % 2 == 0;
    
    if (_occupiedCells[row][col]) {
      return AppColors.secondary.withValues(alpha:0.8);
    } else if (isEvenCell) {
      return AppColors.surface.withValues(alpha:0.3);
    } else {
      return AppColors.surface.withValues(alpha:0.2);
    }
  }

  /// Get border color for a specific cell
  Color _getCellBorderColor(int row, int col) {
    if (_occupiedCells[row][col]) {
      return AppColors.accent.withValues(alpha:0.6);
    } else {
      return AppColors.onSurface.withValues(alpha:0.1);
    }
  }

  /// Handle tap on grid
  @override
  bool onTapUp(TapUpEvent event) {
    final localPosition = event.localPosition;
    final gridPosition = _worldToGridPosition(localPosition);
    
    if (_isValidGridPosition(gridPosition)) {
      onCellTapped?.call(gridPosition);
      _addTapFeedback(gridPosition);
      
      debugPrint('👆 Grid tapped at ($gridPosition)');
      return true;
    }
    
    return false;
  }

  /// Convert world position to grid coordinates
  Vector2 _worldToGridPosition(Vector2 worldPosition) {
    final col = (worldPosition.x / (cellSize + spacing)).floor();
    final row = (worldPosition.y / (cellSize + spacing)).floor();
    
    return Vector2(col.toDouble(), row.toDouble());
  }

  /// Convert grid coordinates to world position
  Vector2 _gridToWorldPosition(Vector2 gridPosition) {
    final x = gridPosition.x * (cellSize + spacing);
    final y = gridPosition.y * (cellSize + spacing);
    
    return Vector2(x, y);
  }

  /// Check if grid position is valid
  bool _isValidGridPosition(Vector2 gridPosition) {
    final row = gridPosition.y.toInt();
    final col = gridPosition.x.toInt();
    
    return row >= 0 && row < gridSize && col >= 0 && col < gridSize;
  }

  /// Highlight valid placement positions for a block
  void highlightValidPlacements(Block block) {
    _performanceMonitor.startTracking('highlight_placements');
    
    clearHighlights();
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final gridPos = Vector2(col.toDouble(), row.toDouble());
        
        if (_canPlaceBlockAt(block, gridPos)) {
          _highlightBlockPlacement(block, gridPos);
        }
      }
    }
    
    _performanceMonitor.stopTracking('highlight_placements');
  }

  /// Check if a block can be placed at a specific position
  bool _canPlaceBlockAt(Block block, Vector2 gridPosition) {
    final startRow = gridPosition.y.toInt();
    final startCol = gridPosition.x.toInt();
    
    for (int row = 0; row < block.shape.length; row++) {
      for (int col = 0; col < block.shape[row].length; col++) {
        if (block.shape[row][col] == 1) {
          final checkRow = startRow + row;
          final checkCol = startCol + col;
          
          // Check bounds
          if (checkRow < 0 || checkRow >= gridSize ||
              checkCol < 0 || checkCol >= gridSize) {
            return false;
          }
          
          // Check if cell is occupied
          if (_occupiedCells[checkRow][checkCol]) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  /// Highlight the placement area for a specific block
  void _highlightBlockPlacement(Block block, Vector2 gridPosition) {
    final startRow = gridPosition.y.toInt();
    final startCol = gridPosition.x.toInt();
    
    for (int row = 0; row < block.shape.length; row++) {
      for (int col = 0; col < block.shape[row].length; col++) {
        if (block.shape[row][col] == 1) {
          final highlightRow = startRow + row;
          final highlightCol = startCol + col;
          
          if (_isValidGridPosition(Vector2(highlightCol.toDouble(), highlightRow.toDouble()))) {
            _showCellHighlight(highlightRow, highlightCol);
          }
        }
      }
    }
  }

  /// Show highlight for a specific cell
  void _showCellHighlight(int row, int col) {
    if (_highlightedCells[row][col]) return;
    
    _highlightedCells[row][col] = true;
    
    final highlight = _highlights[row][col];
    final effect = OpacityEffect.to(
      1.0,
      EffectController(duration: 0.2),
      target: highlight,
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Clear all highlights
  void clearHighlights() {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (_highlightedCells[row][col]) {
          _hideCellHighlight(row, col);
        }
      }
    }
  }

  /// Hide highlight for a specific cell
  void _hideCellHighlight(int row, int col) {
    if (!_highlightedCells[row][col]) return;
    
    _highlightedCells[row][col] = false;
    
    final highlight = _highlights[row][col];
    final effect = OpacityEffect.to(
      0.0,
      EffectController(duration: 0.2),
      target: highlight,
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Mark a cell as occupied
  void setCellOccupied(int row, int col, bool occupied) {
    if (!_isValidGridPosition(Vector2(col.toDouble(), row.toDouble()))) return;
    
    _occupiedCells[row][col] = occupied;
    
    // Update visual appearance
    final cell = _cells[row][col];
    cell.paint.color = _getCellBackgroundColor(row, col);
    
    if (occupied) {
      _addCellOccupiedEffect(row, col);
    }
  }

  /// Add visual effect when a cell becomes occupied
  void _addCellOccupiedEffect(int row, int col) {
    final cell = _cells[row][col];
    
    final scaleEffect = ScaleEffect.by(
      Vector2.all(0.1),
      EffectController(
        duration: 0.1,
        alternate: true,
        repeatCount: 1,
      ),
      target: cell,
    );
    
    _activeEffects.add(scaleEffect);
    add(scaleEffect);
  }

  /// Add tap feedback animation
  void _addTapFeedback(Vector2 gridPosition) {
    final row = gridPosition.y.toInt();
    final col = gridPosition.x.toInt();
    
    if (!_isValidGridPosition(gridPosition)) return;
    
    final cell = _cells[row][col];
    
    final effect = ScaleEffect.by(
      Vector2.all(0.1),
      EffectController(
        duration: 0.1,
        alternate: true,
        repeatCount: 1,
      ),
      target: cell,
    );
    
    _activeEffects.add(effect);
    add(effect);
  }

  /// Animate line clearing
  void animateLineClear(List<int> rows, List<int> cols) {
    _performanceMonitor.startTracking('line_clear_animation');
    
    final cellsToAnimate = <Vector2>[];
    
    // Collect cells to animate
    for (final row in rows) {
      for (int col = 0; col < gridSize; col++) {
        cellsToAnimate.add(Vector2(col.toDouble(), row.toDouble()));
      }
    }
    
    for (final col in cols) {
      for (int row = 0; row < gridSize; row++) {
        cellsToAnimate.add(Vector2(col.toDouble(), row.toDouble()));
      }
    }
    
    // Remove duplicates
    final uniqueCells = cellsToAnimate.toSet().toList();
    
    // Animate each cell
    for (final cellPos in uniqueCells) {
      _animateCellClear(cellPos.x.toInt(), cellPos.y.toInt());
    }
    
    // Update occupancy after animation
    Future.delayed(const Duration(milliseconds: 400), () {
      for (final cellPos in uniqueCells) {
        setCellOccupied(cellPos.y.toInt(), cellPos.x.toInt(), false);
      }
      
      _performanceMonitor.stopTracking('line_clear_animation');
    });
  }

  /// Animate a single cell clearing
  void _animateCellClear(int col, int row) {
    final cell = _cells[row][col];
    
    // Flash effect
    final flashEffect = ColorEffect(
      Colors.white,
      EffectController(
        duration: 0.1,
        alternate: true,
        repeatCount: 2,
      ),
      target: cell,
    );
    
    // Scale effect
    final scaleEffect = ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(
        duration: 0.2,
        curve: Curves.easeOut,
      ),
      target: cell,
    );
    
    // Fade effect
    final fadeEffect = OpacityEffect.to(
      0.3,
      EffectController(
        duration: 0.3,
        curve: Curves.easeOut,
      ),
      target: cell,
    );
    
    _activeEffects.addAll([flashEffect, scaleEffect, fadeEffect]);
    
    add(flashEffect);
    add(scaleEffect);
    add(fadeEffect);
    
    // Reset after animation
    Future.delayed(const Duration(milliseconds: 400), () {
      cell.scale = Vector2.all(1.0);
      cell.opacity = 1.0;
      cell.paint.color = _getCellBackgroundColor(row, col);
    });
  }

  /// Reset the entire grid
  void resetGrid() {
    // Clear occupancy
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        _occupiedCells[row][col] = false;
      }
    }
    
    // Clear highlights
    clearHighlights();
    
    // Reset visual state
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final cell = _cells[row][col];
        cell.paint.color = _getCellBackgroundColor(row, col);
        cell.scale = Vector2.all(1.0);
        cell.opacity = 1.0;
      }
    }
    
    debugPrint('🔄 Grid reset');
  }

  /// Get grid state for external access
  List<List<bool>> getOccupiedCells() {
    return _occupiedCells.map((row) => List<bool>.from(row)).toList();
  }

  /// Update grid theme colors
  void updateThemeColors() {
    // Update background
    _gridBackground.paint.shader = _createGridBackgroundGradient();
    
    // Update border
    _gridBorder.paint.color = AppColors.primary.withValues(alpha:0.8);
    
    // Update cell colors
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final cell = _cells[row][col];
        cell.paint.color = _getCellBackgroundColor(row, col);
      }
    }
  }

  @override
  void onRemove() {
    // Clean up performance monitoring
    _performanceMonitor.dispose();
    
    // Stop all active effects
    for (final effect in _activeEffects) {
      effect.removeFromParent();
    }
    _activeEffects.clear();
    
    super.onRemove();
  }

  // Getters
  List<List<bool>> get occupiedCells => _occupiedCells;
  Vector2 get gridWorldSize => size;
}