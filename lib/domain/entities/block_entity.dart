import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:puzzle_box/core/theme/colors.dart';

/// Block entity represents a game piece that can be placed on the grid.
/// Contains shape data, color information, and placement logic.
/// Immutable entity following Clean Architecture principles.
class Block extends Equatable {
  /// Unique identifier for this block instance
  final String id;
  
  /// Shape matrix (1 = filled, 0 = empty)
  final List<List<int>> shape;
  
  /// Color ID (corresponds to AppColors.blockColors index)
  final int colorId;
  
  /// Block type identifier
  final BlockType type;
  
  /// Rotation state (0, 1, 2, 3 for 0°, 90°, 180°, 270°)
  final int rotation;
  
  /// Whether this block can be rotated
  final bool canRotate;
  
  /// Block rarity (affects spawning probability)
  final BlockRarity rarity;
  
  /// Creation timestamp
  final DateTime createdAt;

  const Block({
    required this.id,
    required this.shape,
    required this.colorId,
    required this.type,
    this.rotation = 0,
    this.canRotate = true,
    this.rarity = BlockRarity.common,
    required this.createdAt,
  });

  /// Create a basic single-cell block
  factory Block.single({
    String? id,
    int? colorId,
  }) {
    return Block(
      id: id ?? _generateId(),
      shape: const [[1]],
      colorId: colorId ?? _randomColorId(),
      type: BlockType.single,
      canRotate: false,
      rarity: BlockRarity.common,
      createdAt: DateTime.now(),
    );
  }

  /// Create a line block (I-piece)
  factory Block.line({
    String? id,
    int? colorId,
    int length = 4,
  }) {
    final shape = [List.filled(length, 1)];
    return Block(
      id: id ?? _generateId(),
      shape: shape,
      colorId: colorId ?? _randomColorId(),
      type: BlockType.line,
      canRotate: true,
      rarity: BlockRarity.common,
      createdAt: DateTime.now(),
    );
  }

  /// Create a square block (O-piece)
  factory Block.square({
    String? id,
    int? colorId,
    int size = 2,
  }) {
    final shape = List.generate(size, (_) => List.filled(size, 1));
    return Block(
      id: id ?? _generateId(),
      shape: shape,
      colorId: colorId ?? _randomColorId(),
      type: BlockType.square,
      canRotate: false, // Square doesn't need rotation
      rarity: BlockRarity.common,
      createdAt: DateTime.now(),
    );
  }

  /// Create an L-shaped block
  factory Block.lShape({
    String? id,
    int? colorId,
    bool reversed = false,
  }) {
    final shape = reversed
        ? [[0, 1], [0, 1], [1, 1]] // J-piece
        : [[1, 0], [1, 0], [1, 1]]; // L-piece
    
    return Block(
      id: id ?? _generateId(),
      shape: shape,
      colorId: colorId ?? _randomColorId(),
      type: reversed ? BlockType.jShape : BlockType.lShape,
      canRotate: true,
      rarity: BlockRarity.uncommon,
      createdAt: DateTime.now(),
    );
  }

  /// Create a T-shaped block
  factory Block.tShape({
    String? id,
    int? colorId,
  }) {
    const shape = [
      [0, 1, 0],
      [1, 1, 1],
    ];
    
    return Block(
      id: id ?? _generateId(),
      shape: shape,
      colorId: colorId ?? _randomColorId(),
      type: BlockType.tShape,
      canRotate: true,
      rarity: BlockRarity.uncommon,
      createdAt: DateTime.now(),
    );
  }

  /// Create an S or Z shaped block
  factory Block.sShape({
    String? id,
    int? colorId,
    bool zShape = false,
  }) {
    final shape = zShape
        ? [[1, 1, 0], [0, 1, 1]] // Z-piece
        : [[0, 1, 1], [1, 1, 0]]; // S-piece
    
    return Block(
      id: id ?? _generateId(),
      shape: shape,
      colorId: colorId ?? _randomColorId(),
      type: zShape ? BlockType.zShape : BlockType.sShape,
      canRotate: true,
      rarity: BlockRarity.rare,
      createdAt: DateTime.now(),
    );
  }

  /// Create a random block based on level and difficulty
  factory Block.createRandom({
    int level = 1,
    String? id,
  }) {
    final random = math.Random();
    
    // Determine block type based on level and probability
    final blockType = _getRandomBlockType(level, random);
    final colorId = random.nextInt(AppColors.blockColors.length);
    
    switch (blockType) {
      case BlockType.single:
        return Block.single(id: id, colorId: colorId);
      case BlockType.line:
        final length = _getRandomLineLength(level, random);
        return Block.line(id: id, colorId: colorId, length: length);
      case BlockType.square:
        final size = level > 5 ? (random.nextBool() ? 2 : 3) : 2;
        return Block.square(id: id, colorId: colorId, size: size);
      case BlockType.lShape:
        return Block.lShape(id: id, colorId: colorId);
      case BlockType.jShape:
        return Block.lShape(id: id, colorId: colorId, reversed: true);
      case BlockType.tShape:
        return Block.tShape(id: id, colorId: colorId);
      case BlockType.sShape:
        return Block.sShape(id: id, colorId: colorId);
      case BlockType.zShape:
        return Block.sShape(id: id, colorId: colorId, zShape: true);
      case BlockType.custom:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// Create a block from predefined shape
  factory Block.fromShape({
    required List<List<int>> shape,
    String? id,
    int? colorId,
    BlockType? type,
  }) {
    return Block(
      id: id ?? _generateId(),
      shape: shape,
      colorId: colorId ?? _randomColorId(),
      type: type ?? _detectBlockType(shape),
      canRotate: true,
      rarity: BlockRarity.common,
      createdAt: DateTime.now(),
    );
  }

  // ========================================
  // BLOCK OPERATIONS
  // ========================================

  /// Rotate the block 90 degrees clockwise
  Block rotate() {
    if (!canRotate) return this;
    
    final rotatedShape = _rotateShapeClockwise(shape);
    final newRotation = (rotation + 1) % 4;
    
    return copyWith(
      shape: rotatedShape,
      rotation: newRotation,
    );
  }

  /// Get the block rotated to a specific rotation state
  Block rotateTo(int targetRotation) {
    if (!canRotate) return this;
    
    final rotationDiff = (targetRotation - rotation) % 4;
    Block rotatedBlock = this;
    
    for (int i = 0; i < rotationDiff; i++) {
      rotatedBlock = rotatedBlock.rotate();
    }
    
    return rotatedBlock;
  }

  /// Create a copy of this block with updated properties
  Block copyWith({
    String? id,
    List<List<int>>? shape,
    int? colorId,
    BlockType? type,
    int? rotation,
    bool? canRotate,
    BlockRarity? rarity,
    DateTime? createdAt,
  }) {
    return Block(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      colorId: colorId ?? this.colorId,
      type: type ?? this.type,
      rotation: rotation ?? this.rotation,
      canRotate: canRotate ?? this.canRotate,
      rarity: rarity ?? this.rarity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ========================================
  // BLOCK PROPERTIES
  // ========================================

  /// Get the width of the block (number of columns)
  int get width {
    if (shape.isEmpty) return 0;
    return shape.first.length;
  }

  /// Get the height of the block (number of rows)
  int get height {
    return shape.length;
  }

  /// Get the number of filled cells in the block
  int get cellCount {
    int count = 0;
    for (final row in shape) {
      for (final cell in row) {
        if (cell == 1) count++;
      }
    }
    return count;
  }

  /// Get the bounding box of the block (minimal rectangle containing all cells)
  ({int minRow, int maxRow, int minCol, int maxCol}) get boundingBox {
    int minRow = height;
    int maxRow = -1;
    int minCol = width;
    int maxCol = -1;
    
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        if (shape[row][col] == 1) {
          minRow = math.min(minRow, row);
          maxRow = math.max(maxRow, row);
          minCol = math.min(minCol, col);
          maxCol = math.max(maxCol, col);
        }
      }
    }
    
    return (
      minRow: minRow == height ? 0 : minRow,
      maxRow: maxRow == -1 ? 0 : maxRow,
      minCol: minCol == width ? 0 : minCol,
      maxCol: maxCol == -1 ? 0 : maxCol,
    );
  }

  /// Check if the block is symmetric (same after 180-degree rotation)
  bool get isSymmetric {
    final rotated = rotate().rotate();
    return _shapesEqual(shape, rotated.shape);
  }

  /// Get the block's center of mass
  ({double row, double col}) get centerOfMass {
    double totalRow = 0;
    double totalCol = 0;
    int count = 0;
    
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        if (shape[row][col] == 1) {
          totalRow += row;
          totalCol += col;
          count++;
        }
      }
    }
    
    return count > 0
        ? (row: totalRow / count, col: totalCol / count)
        : (row: 0.0, col: 0.0);
  }

  // ========================================
  // VALIDATION METHODS
  // ========================================

  /// Check if this block can fit at the given position on a grid
  bool canFitAt(List<List<int>> grid, int row, int col) {
    for (int r = 0; r < height; r++) {
      for (int c = 0; c < width; c++) {
        if (shape[r][c] == 1) {
          final gridRow = row + r;
          final gridCol = col + c;
          
          // Check bounds
          if (gridRow < 0 || gridRow >= grid.length ||
              gridCol < 0 || gridCol >= grid[0].length) {
            return false;
          }
          
          // Check if cell is occupied
          if (grid[gridRow][gridCol] != 0) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Get all valid positions where this block can be placed on a grid
  List<({int row, int col})> getValidPositions(List<List<int>> grid) {
    final validPositions = <({int row, int col})>[];
    
    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[0].length; col++) {
        if (canFitAt(grid, row, col)) {
          validPositions.add((row: row, col: col));
        }
      }
    }
    
    return validPositions;
  }

  // ========================================
  // SERIALIZATION
  // ========================================

  /// Convert block to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shape': shape,
      'colorId': colorId,
      'type': type.name,
      'rotation': rotation,
      'canRotate': canRotate,
      'rarity': rarity.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create block from JSON
  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as String,
      shape: (json['shape'] as List).map((row) => 
          (row as List).map((cell) => cell as int).toList()).toList(),
      colorId: json['colorId'] as int,
      type: BlockType.values.firstWhere((t) => t.name == json['type']),
      rotation: json['rotation'] as int? ?? 0,
      canRotate: json['canRotate'] as bool? ?? true,
      rarity: BlockRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => BlockRarity.common,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // ========================================
  // PRIVATE HELPER METHODS
  // ========================================

  /// Generate a unique ID for the block
  static String _generateId() {
    return 'block_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(1000)}';
  }

  /// Get a random color ID
  static int _randomColorId() {
    return math.Random().nextInt(AppColors.blockColors.length);
  }

  /// Rotate a shape matrix 90 degrees clockwise
  static List<List<int>> _rotateShapeClockwise(List<List<int>> shape) {
    final rows = shape.length;
    final cols = shape.first.length;
    
    final rotated = List.generate(cols, (_) => List.filled(rows, 0));
    
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        rotated[c][rows - 1 - r] = shape[r][c];
      }
    }
    
    return rotated;
  }

  /// Check if two shapes are equal
  static bool _shapesEqual(List<List<int>> shape1, List<List<int>> shape2) {
    if (shape1.length != shape2.length) return false;
    
    for (int r = 0; r < shape1.length; r++) {
      if (shape1[r].length != shape2[r].length) return false;
      for (int c = 0; c < shape1[r].length; c++) {
        if (shape1[r][c] != shape2[r][c]) return false;
      }
    }
    
    return true;
  }

  /// Detect block type from shape
  static BlockType _detectBlockType(List<List<int>> shape) {
    final height = shape.length;
    final width = shape.first.length;
    
    // Count filled cells
    int cellCount = 0;
    for (final row in shape) {
      for (final cell in row) {
        if (cell == 1) cellCount++;
      }
    }
    
    // Simple detection logic
    if (cellCount == 1) return BlockType.single;
    if (height == 1 || width == 1) return BlockType.line;
    if (height == width && cellCount == height * width) return BlockType.square;
    
    // Default to custom for complex shapes
    return BlockType.custom;
  }

  /// Get random block type based on level
  static BlockType _getRandomBlockType(int level, math.Random random) {
    // Probability weights based on level
    final weights = <BlockType, double>{
      BlockType.single: math.max(0.4 - (level * 0.02), 0.1),
      BlockType.line: 0.3,
      BlockType.square: 0.2,
      BlockType.lShape: math.min(0.1 + (level * 0.01), 0.2),
      BlockType.tShape: math.min(0.05 + (level * 0.01), 0.15),
      BlockType.sShape: math.min(0.02 + (level * 0.005), 0.1),
    };
    
    final totalWeight = weights.values.reduce((a, b) => a + b);
    final randomValue = random.nextDouble() * totalWeight;
    
    double currentWeight = 0;
    for (final entry in weights.entries) {
      currentWeight += entry.value;
      if (randomValue <= currentWeight) {
        return entry.key;
      }
    }
    
    return BlockType.single; // Fallback
  }

  /// Get random line length based on level
  static int _getRandomLineLength(int level, math.Random random) {
    if (level < 3) return random.nextBool() ? 2 : 3;
    if (level < 6) return 2 + random.nextInt(3); // 2, 3, or 4
    return 2 + random.nextInt(4); // 2, 3, 4, or 5
  }

  @override
  List<Object?> get props => [
        id,
        shape,
        colorId,
        type,
        rotation,
        canRotate,
        rarity,
        createdAt,
      ];

  @override
  String toString() {
    return 'Block(id: $id, type: $type, color: $colorId, size: ${width}x$height)';
  }
}

/// Block type enumeration
enum BlockType {
  single,
  line,
  square,
  lShape,
  jShape,
  tShape,
  sShape,
  zShape,
  custom;
  
  String get name => toString().split('.').last;
  
  String get displayName {
    switch (this) {
      case BlockType.single:
        return 'Single';
      case BlockType.line:
        return 'Line';
      case BlockType.square:
        return 'Square';
      case BlockType.lShape:
        return 'L-Shape';
      case BlockType.jShape:
        return 'J-Shape';
      case BlockType.tShape:
        return 'T-Shape';
      case BlockType.sShape:
        return 'S-Shape';
      case BlockType.zShape:
        return 'Z-Shape';
      case BlockType.custom:
        return 'Custom';
    }
  }
}

/// Block rarity enumeration (affects spawning probability)
enum BlockRarity {
  common,
  uncommon,
  rare,
  epic;
  
  String get name => toString().split('.').last;
  
  double get spawnProbability {
    switch (this) {
      case BlockRarity.common:
        return 0.6;
      case BlockRarity.uncommon:
        return 0.3;
      case BlockRarity.rare:
        return 0.08;
      case BlockRarity.epic:
        return 0.02;
    }
  }
}