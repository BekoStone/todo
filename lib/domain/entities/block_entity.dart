import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flame/components.dart';

class Block extends Equatable {
  final String id;
  final List<List<int>> shape;
  final Vector2 position;
  final Vector2 originalPosition;
  final bool isLocked;
  final bool isActive;
  final int colorIndex;
  final DateTime createdAt;
  
  const Block({
    required this.id,
    required this.shape,
    required this.position,
    required this.originalPosition,
    this.isLocked = false,
    this.isActive = true,
    this.colorIndex = 0,
    required this.createdAt,
  });
  
  // Factory constructor for creating blocks from shapes
  factory Block.fromShape(List<List<int>> shape, Vector2 position) {
    final id = 'block_${DateTime.now().millisecondsSinceEpoch}_${shape.hashCode}';
    
    return Block(
      id: id,
      shape: shape,
      position: position,
      originalPosition: position.clone(),
      colorIndex: shape.hashCode.abs() % 8, // 8 colors available
      createdAt: DateTime.now(),
    );
  }
  
  // Copy with modifications
  Block copyWith({
    String? id,
    List<List<int>>? shape,
    Vector2? position,
    Vector2? originalPosition,
    bool? isLocked,
    bool? isActive,
    int? colorIndex,
    DateTime? createdAt,
  }) {
    return Block(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      position: position ?? this.position,
      originalPosition: originalPosition ?? this.originalPosition,
      isLocked: isLocked ?? this.isLocked,
      isActive: isActive ?? this.isActive,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Block properties
  int get cellCount {
    int count = 0;
    for (final row in shape) {
      for (final cell in row) {
        if (cell == 1) count++;
      }
    }
    return count;
  }
  
  Vector2 get dimensions {
    return Vector2(shape[0].length.toDouble(), shape.length.toDouble());
  }
  
  double get width => shape[0].length.toDouble();
  double get height => shape.length.toDouble();
  
  // Get occupied cell positions relative to block
  List<Vector2> get occupiedCells {
    final cells = <Vector2>[];
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          cells.add(Vector2(col.toDouble(), row.toDouble()));
        }
      }
    }
    return cells;
  }
  
  // Get absolute positions on grid
  List<Vector2> getAbsolutePositions(Vector2 gridOffset) {
    return occupiedCells.map((cell) => gridOffset + cell).toList();
  }
  
  // Transformations
  Block rotate90() {
    final rows = shape.length;
    final cols = shape[0].length;
    final rotated = List.generate(cols, (_) => List.filled(rows, 0));
    
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        rotated[col][rows - 1 - row] = shape[row][col];
      }
    }
    
    return copyWith(shape: rotated);
  }
  
  Block flipHorizontal() {
    final flipped = shape.map((row) => row.reversed.toList()).toList();
    return copyWith(shape: flipped);
  }
  
  Block flipVertical() {
    final flipped = shape.reversed.toList();
    return copyWith(shape: flipped);
  }
  
  // Position updates
  Block moveTo(Vector2 newPosition) {
    return copyWith(position: newPosition);
  }
  
  Block resetToOriginalPosition() {
    return copyWith(position: originalPosition.clone());
  }
  
  Block updateOriginalPosition(Vector2 newPosition) {
    return copyWith(
      position: newPosition,
      originalPosition: newPosition.clone(),
    );
  }
  
  // State changes
  Block lock() => copyWith(isLocked: true);
  Block unlock() => copyWith(isLocked: false);
  Block activate() => copyWith(isActive: true);
  Block deactivate() => copyWith(isActive: false);
  
  // Collision detection helpers
  bool collidesWith(Block other, {double tolerance = 0.1}) {
    final myPositions = getAbsolutePositions(position);
    final otherPositions = other.getAbsolutePositions(other.position);
    
    for (final myPos in myPositions) {
      for (final otherPos in otherPositions) {
        if ((myPos - otherPos).length < tolerance) {
          return true;
        }
      }
    }
    return false;
  }
  
  bool canFitInGrid(Vector2 gridPosition, int gridSize) {
    final absolutePositions = getAbsolutePositions(gridPosition);
    
    for (final pos in absolutePositions) {
      if (pos.x < 0 || pos.x >= gridSize || pos.y < 0 || pos.y >= gridSize) {
        return false;
      }
    }
    return true;
  }
  
  // Block analysis
  double get density => cellCount / (width * height);
  
  double get complexity {
    // More complex shapes have lower density and irregular patterns
    final aspectRatio = width > height ? width / height : height / width;
    return (1 - density) + (aspectRatio - 1) * 0.5;
  }
  
  String get shapeType {
    if (width == 1 && height == 1) return 'single';
    if (width == 1 || height == 1) return 'line';
    if (width == height && density == 1.0) return 'square';
    if (cellCount == 3) return 'small';
    if (cellCount >= 5) return 'large';
    return 'medium';
  }
  
  // Bounding box
  Rect get boundingBox {
    if (occupiedCells.isEmpty) {
      return Rect.fromLTWH(position.x, position.y, width, height);
    }
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final cell in occupiedCells) {
      final absolutePos = position + cell;
      minX = minX < absolutePos.x ? minX : absolutePos.x;
      minY = minY < absolutePos.y ? minY : absolutePos.y;
      maxX = maxX > absolutePos.x ? maxX : absolutePos.x;
      maxY = maxY > absolutePos.y ? maxY : absolutePos.y;
    }
    
    return Rect.fromLTRB(minX, minY, maxX + 1, maxY + 1);
  }
  
  // Pattern matching
  bool matchesPattern(List<List<int>> pattern) {
    if (shape.length != pattern.length) return false;
    if (shape[0].length != pattern[0].length) return false;
    
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] != pattern[row][col]) return false;
      }
    }
    return true;
  }
  
  // Scoring helpers
  int getScoreValue() {
    // Base score depends on cell count and complexity
    return (cellCount * 10 * (1 + complexity)).round();
  }
  
  int getPlacementBonus(int level) {
    return (getScoreValue() * 0.1 * level).round();
  }
  
  @override
  List<Object?> get props => [
    id,
    shape,
    position,
    originalPosition,
    isLocked,
    isActive,
    colorIndex,
    createdAt,
  ];
  
  @override
  String toString() {
    return 'Block(id: $id, cells: $cellCount, pos: $position, locked: $isLocked)';
  }
}

// Block factory for creating common shapes
class BlockFactory {
  static const List<List<List<int>>> commonShapes = [
    // Single block
    [[1]],
    
    // 2-block shapes
    [[1, 1]],
    [[1], [1]],
    
    // 3-block shapes
    [[1, 1, 1]],
    [[1], [1], [1]],
    [[1, 1], [1, 0]],
    [[1, 1], [0, 1]],
    
    // 4-block shapes (Tetris-like)
    [[1, 1], [1, 1]], // Square
    [[1, 1, 1, 1]], // I-piece horizontal
    [[1], [1], [1], [1]], // I-piece vertical
    [[1, 1, 1], [0, 1, 0]], // T-piece
    [[1, 0, 0], [1, 1, 1]], // L-piece
    [[0, 0, 1], [1, 1, 1]], // J-piece
    [[1, 1, 0], [0, 1, 1]], // S-piece
    [[0, 1, 1], [1, 1, 0]], // Z-piece
    
    // 5-block shapes
    [[1, 1, 1, 1, 1]], // Long line
    [[0, 1, 0], [1, 1, 1], [0, 1, 0]], // Plus
    [[1, 0, 1], [1, 1, 1]], // U-shape
    
    // Complex shapes
    [[1, 1, 1], [1, 0, 0], [1, 0, 0]], // Corner
    [[1, 1, 1], [1, 1, 1], [1, 1, 1]], // 3x3 square
  ];
  
  static Block createRandomBlock(Vector2 position) {
    final shape = (commonShapes..shuffle()).first;
    return Block.fromShape(shape, position);
  }
  
  static Block createBlockByType(String type, Vector2 position) {
    List<List<int>> shape;
    
    switch (type) {
      case 'single':
        shape = [[1]];
        break;
      case 'line2':
        shape = [[1, 1]];
        break;
      case 'line3':
        shape = [[1, 1, 1]];
        break;
      case 'square':
        shape = [[1, 1], [1, 1]];
        break;
      case 'tpiece':
        shape = [[1, 1, 1], [0, 1, 0]];
        break;
      case 'lpiece':
        shape = [[1, 0, 0], [1, 1, 1]];
        break;
      default:
        shape = [[1]];
    }
    
    return Block.fromShape(shape, position);
  }
  
  static List<Block> createBlockSet(Vector2 basePosition, {int count = 3}) {
    final blocks = <Block>[];
    final usedShapes = <List<List<int>>>[];
    
    for (int i = 0; i < count; i++) {
      List<List<int>> shape;
      
      // Ensure variety in shapes
      do {
        shape = (commonShapes..shuffle()).first;
      } while (usedShapes.any((used) => _shapesEqual(used, shape)) && usedShapes.length < commonShapes.length);
      
      usedShapes.add(shape);
      
      final blockPosition = Vector2(
        basePosition.x + (i * 100), // Spread blocks horizontally
        basePosition.y,
      );
      
      blocks.add(Block.fromShape(shape, blockPosition));
    }
    
    return blocks;
  }
  
  static bool _shapesEqual(List<List<int>> shape1, List<List<int>> shape2) {
    if (shape1.length != shape2.length) return false;
    
    for (int row = 0; row < shape1.length; row++) {
      if (shape1[row].length != shape2[row].length) return false;
      for (int col = 0; col < shape1[row].length; col++) {
        if (shape1[row][col] != shape2[row][col]) return false;
      }
    }
    
    return true;
  }
}