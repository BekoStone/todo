import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flame/components.dart';

class BlockModel extends Equatable {
  final String id;
  final List<List<int>> shape;
  final Vector2 position;
  final Vector2 originalPosition;
  final bool isLocked;
  final bool isActive;
  final int colorIndex;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  
  const BlockModel({
    required this.id,
    required this.shape,
    required this.position,
    required this.originalPosition,
    this.isLocked = false,
    this.isActive = true,
    this.colorIndex = 0,
    required this.createdAt,
    this.metadata = const {},
  });
  
  // Create new block with generated ID
  factory BlockModel.create({
    required List<List<int>> shape,
    required Vector2 position,
    int colorIndex = 0,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}_${shape.hashCode}';
    
    return BlockModel(
      id: id,
      shape: shape,
      position: position,
      originalPosition: position.clone(),
      colorIndex: colorIndex,
      createdAt: now,
      metadata: metadata ?? {},
    );
  }
  
  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shape': shape,
      'position': {'x': position.x, 'y': position.y},
      'originalPosition': {'x': originalPosition.x, 'y': originalPosition.y},
      'isLocked': isLocked,
      'isActive': isActive,
      'colorIndex': colorIndex,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  factory BlockModel.fromJson(Map<String, dynamic> json) {
    final positionJson = json['position'] as Map<String, dynamic>?;
    final originalPositionJson = json['originalPosition'] as Map<String, dynamic>?;
    
    return BlockModel(
      id: json['id'] ?? '',
      shape: (json['shape'] as List?)?.map((row) => 
        (row as List).map((cell) => cell as int).toList()
      ).toList() ?? [],
      position: positionJson != null 
        ? Vector2(positionJson['x']?.toDouble() ?? 0, positionJson['y']?.toDouble() ?? 0)
        : Vector2.zero(),
      originalPosition: originalPositionJson != null 
        ? Vector2(originalPositionJson['x']?.toDouble() ?? 0, originalPositionJson['y']?.toDouble() ?? 0)
        : Vector2.zero(),
      isLocked: json['isLocked'] ?? false,
      isActive: json['isActive'] ?? true,
      colorIndex: json['colorIndex'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'] ?? {},
    );
  }
  
  // Copy with modifications
  BlockModel copyWith({
    String? id,
    List<List<int>>? shape,
    Vector2? position,
    Vector2? originalPosition,
    bool? isLocked,
    bool? isActive,
    int? colorIndex,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return BlockModel(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      position: position ?? this.position,
      originalPosition: originalPosition ?? this.originalPosition,
      isLocked: isLocked ?? this.isLocked,
      isActive: isActive ?? this.isActive,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
  
  // Block analysis
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
  
  // Get all occupied cell positions relative to block position
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
  
  // Get absolute positions of occupied cells
  List<Vector2> get absoluteOccupiedCells {
    return occupiedCells.map((cell) => position + cell).toList();
  }
  
  // Check if block contains a specific shape pattern
  bool hasPattern(List<List<int>> pattern) {
    if (shape.length != pattern.length) return false;
    if (shape[0].length != pattern[0].length) return false;
    
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] != pattern[row][col]) return false;
      }
    }
    return true;
  }
  
  // Rotate block shape (clockwise)
  BlockModel rotateClockwise() {
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
  
  // Flip block shape horizontally
  BlockModel flipHorizontally() {
    final flipped = shape.map((row) => row.reversed.toList()).toList();
    return copyWith(shape: flipped);
  }
  
  // Check if block can fit at position (basic check)
  bool canFitAt(Vector2 newPosition, int gridSize) {
    final absoluteCells = occupiedCells.map((cell) => newPosition + cell);
    
    for (final cell in absoluteCells) {
      if (cell.x < 0 || cell.x >= gridSize || cell.y < 0 || cell.y >= gridSize) {
        return false;
      }
    }
    return true;
  }
  
  // Get bounding box of the shape
  Rect get boundingBox {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final cell in occupiedCells) {
      minX = minX < cell.x ? minX : cell.x;
      minY = minY < cell.y ? minY : cell.y;
      maxX = maxX > cell.x ? maxX : cell.x;
      maxY = maxY > cell.y ? maxY : cell.y;
    }
    
    return Rect.fromLTRB(minX, minY, maxX + 1, maxY + 1);
  }
  
  // Calculate block complexity (for difficulty scaling)
  double get complexity {
    final area = dimensions.x * dimensions.y;
    final fillRatio = cellCount / area;
    final aspectRatio = dimensions.x / dimensions.y;
    
    // More complex shapes have lower fill ratios and extreme aspect ratios
    return (1 - fillRatio) + (aspectRatio > 1 ? aspectRatio : 1 / aspectRatio) - 1;
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
    metadata,
  ];
}