import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';

/// BlockEntity represents a single game block with position, shape, and state.
/// Follows Clean Architecture principles with immutable data and clear interfaces.
/// Optimized for performance with efficient equality checks and minimal memory usage.
class BlockEntity extends Equatable {
  /// Unique identifier for this block
  final String id;
  
  /// Block type (determines shape and color)
  final BlockType type;
  
  /// Current position in grid coordinates
  final Position position;
  
  /// Current rotation state (0-3)
  final int rotation;
  
  /// Block color
  final Color color;
  
  /// Whether this block is currently active (being controlled)
  final bool isActive;
  
  /// Whether this block is locked in place
  final bool isLocked;
  
  /// Block creation timestamp
  final DateTime createdAt;
  
  /// Block placement timestamp (null if not placed)
  final DateTime? placedAt;
  
  /// Animation state for visual effects
  final BlockAnimationState animationState;
  
  /// Custom properties for special blocks
  final Map<String, dynamic> properties;

  const BlockEntity({
    required this.id,
    required this.type,
    required this.position,
    this.rotation = 0,
    required this.color,
    this.isActive = false,
    this.isLocked = false,
    required this.createdAt,
    this.placedAt,
    this.animationState = BlockAnimationState.idle,
    this.properties = const {},
  });

  /// Create a new block with default values
  factory BlockEntity.create({
    required BlockType type,
    Position? position,
    Color? color,
    Map<String, dynamic>? properties,
  }) {
    return BlockEntity(
      id: _generateId(),
      type: type,
      position: position ?? const Position(0, 0),
      color: color ?? _getDefaultColorForType(type),
      createdAt: DateTime.now(),
      properties: properties ?? {},
    );
  }

  /// Create a copy with updated values
  BlockEntity copyWith({
    String? id,
    BlockType? type,
    Position? position,
    int? rotation,
    Color? color,
    bool? isActive,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? placedAt,
    BlockAnimationState? animationState,
    Map<String, dynamic>? properties,
  }) {
    return BlockEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      placedAt: placedAt ?? this.placedAt,
      animationState: animationState ?? this.animationState,
      properties: properties ?? Map.from(this.properties),
    );
  }

  /// Get the current shape matrix based on type and rotation
  List<List<int>> get currentShape {
    List<List<int>> baseShape = List.from(type.shape.map((row) => List<int>.from(row)));
    
    // Apply rotation
    for (int i = 0; i < rotation; i++) {
      baseShape = _rotateMatrix(baseShape);
    }
    
    return baseShape;
  }

  /// Get all cell positions occupied by this block
  List<Position> get occupiedPositions {
    final shape = currentShape;
    final positions = <Position>[];
    
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          positions.add(Position(
            position.x + col,
            position.y + row,
          ));
        }
      }
    }
    
    return positions;
  }

  /// Get bounding box of the block
  Rectangle get boundingBox {
    final positions = occupiedPositions;
    if (positions.isEmpty) {
      return Rectangle(position.x, position.y, 0, 0);
    }
    
    int minX = positions.first.x;
    int maxX = positions.first.x;
    int minY = positions.first.y;
    int maxY = positions.first.y;
    
    for (final pos in positions) {
      minX = math.min(minX, pos.x);
      maxX = math.max(maxX, pos.x);
      minY = math.min(minY, pos.y);
      maxY = math.max(maxY, pos.y);
    }
    
    return Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  /// Move block by offset
  BlockEntity move(int deltaX, int deltaY) {
    return copyWith(
      position: Position(position.x + deltaX, position.y + deltaY),
    );
  }

  /// Rotate block clockwise
  BlockEntity rotateClockwise() {
    return copyWith(rotation: (rotation + 1) % 4);
  }

  /// Rotate block counterclockwise
  BlockEntity rotateCounterclockwise() {
    return copyWith(rotation: (rotation - 1) % 4);
  }

  /// Lock block in place
  BlockEntity lock() {
    return copyWith(
      isLocked: true,
      isActive: false,
      placedAt: DateTime.now(),
      animationState: BlockAnimationState.placed,
    );
  }

  /// Activate block for player control
  BlockEntity activate() {
    return copyWith(
      isActive: true,
      animationState: BlockAnimationState.active,
    );
  }

  /// Deactivate block
  BlockEntity deactivate() {
    return copyWith(
      isActive: false,
      animationState: BlockAnimationState.idle,
    );
  }

  /// Check if block can be placed at given position in grid
  bool canBePlacedAt(Position newPosition, List<List<bool>> grid) {
    final testBlock = copyWith(position: newPosition);
    final positions = testBlock.occupiedPositions;
    
    for (final pos in positions) {
      // Check bounds
      if (pos.x < 0 || pos.x >= grid[0].length || pos.y < 0 || pos.y >= grid.length) {
        return false;
      }
      
      // Check collision
      if (grid[pos.y][pos.x]) {
        return false;
      }
    }
    
    return true;
  }

  /// Check if block can be rotated in current position
  bool canRotateAt(Position position, List<List<bool>> grid, bool clockwise) {
    final testBlock = clockwise ? rotateClockwise() : rotateCounterclockwise();
    return testBlock.copyWith(position: position).canBePlacedAt(position, grid);
  }

  /// Get preview of block at different position/rotation
  BlockEntity getPreview({Position? newPosition, int? newRotation}) {
    return copyWith(
      position: newPosition ?? position,
      rotation: newRotation ?? rotation,
      animationState: BlockAnimationState.preview,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'position': position.toJson(),
      'rotation': rotation,
      'color': color.value,
      'isActive': isActive,
      'isLocked': isLocked,
      'createdAt': createdAt.toIso8601String(),
      'placedAt': placedAt?.toIso8601String(),
      'animationState': animationState.name,
      'properties': properties,
    };
  }

  /// Create from JSON
  factory BlockEntity.fromJson(Map<String, dynamic> json) {
    return BlockEntity(
      id: json['id'] as String,
      type: BlockType.values.firstWhere((t) => t.name == json['type']),
      position: Position.fromJson(json['position']),
      rotation: json['rotation'] as int? ?? 0,
      color: Color(json['color'] as int),
      isActive: json['isActive'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      placedAt: json['placedAt'] != null ? DateTime.parse(json['placedAt'] as String) : null,
      animationState: BlockAnimationState.values.firstWhere(
        (s) => s.name == json['animationState'], 
        orElse: () => BlockAnimationState.idle,
      ),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }

  /// Generate unique ID for block
  static String _generateId() {
    return 'block_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  /// Get default color for block type
  static Color _getDefaultColorForType(BlockType type) {
    const colors = [
      Color(0xFF00FFFF), // Cyan - I
      Color(0xFFFFFF00), // Yellow - O
      Color(0xFF800080), // Purple - T
      Color(0xFFFF8000), // Orange - L
      Color(0xFF0000FF), // Blue - J
      Color(0xFF00FF00), // Green - S
      Color(0xFFFF0000), // Red - Z
    ];
    return colors[type.index % colors.length];
  }

  /// Rotate matrix 90 degrees clockwise
  static List<List<int>> _rotateMatrix(List<List<int>> matrix) {
    final rows = matrix.length;
    final cols = matrix[0].length;
    final rotated = List.generate(cols, (_) => List.filled(rows, 0));
    
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        rotated[j][rows - 1 - i] = matrix[i][j];
      }
    }
    
    return rotated;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        position,
        rotation,
        color,
        isActive,
        isLocked,
        createdAt,
        placedAt,
        animationState,
        properties,
      ];
}

/// Position represents a 2D coordinate in the game grid
class Position extends Equatable {
  final int x;
  final int y;

  const Position(this.x, this.y);

  /// Create from JSON
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      json['x'] as int,
      json['y'] as int,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y};
  }

  /// Add offset to position
  Position operator +(Position other) {
    return Position(x + other.x, y + other.y);
  }

  /// Subtract offset from position
  Position operator -(Position other) {
    return Position(x - other.x, y - other.y);
  }

  /// Calculate distance to another position
  double distanceTo(Position other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => 'Position($x, $y)';

  @override
  List<Object> get props => [x, y];
}

/// Rectangle represents a rectangular area
class Rectangle extends Equatable {
  final int x;
  final int y;
  final int width;
  final int height;

  const Rectangle(this.x, this.y, this.width, this.height);

  /// Get right edge
  int get right => x + width;

  /// Get bottom edge
  int get bottom => y + height;

  /// Check if point is inside rectangle
  bool contains(Position point) {
    return point.x >= x && point.x < right && point.y >= y && point.y < bottom;
  }

  /// Check if rectangles intersect
  bool intersects(Rectangle other) {
    return x < other.right && right > other.x && y < other.bottom && bottom > other.y;
  }

  @override
  List<Object> get props => [x, y, width, height];
}

/// Block animation state enumeration
enum BlockAnimationState {
  idle,
  active,
  moving,
  rotating,
  falling,
  placing,
  placed,
  clearing,
  preview,
  highlight;

  String get name => toString().split('.').last;
}

/// Legacy alias for backward compatibility
typedef Block = BlockEntity;