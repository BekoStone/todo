import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'dart:math' as math;
import '../../flame/box_hooks_game.dart';
import '../../flame/components/block_component.dart' as flame_block;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/responsive_utils.dart';

class GameBoard extends StatefulWidget {
  /// The Flame game instance
  final BoxHooksGame game;
  
  /// Callback when a block is placed on the board
  final Function(Block block, int row, int col)? onBlockPlaced;
  
  /// Callback when a line is cleared
  final Function(List<int> rows, List<int> cols)? onLinesCleared;
  
  /// Whether the board is interactive
  final bool interactive;

  const GameBoard({
    super.key,
    required this.game,
    this.onBlockPlaced,
    this.onLinesCleared,
    this.interactive = true,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard>
    with TickerProviderStateMixin {
  late AnimationController _clearAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _clearAnimation;
  late Animation<double> _pulseAnimation;
  
  // Grid state
  late List<List<bool>> _occupiedCells;
  late List<List<Color?>> _cellColors;
  late List<List<BlockEntity?>> _cellBlocks;
  
  // Animation state
  final Set<int> _animatingRows = {};
  final Set<int> _animatingCols = {};
  final Map<String, AnimationController> _cellControllers = {};
  
  // Drag state
  flame_block.BlockComponent? _draggingBlock;
  Offset? _dragOffset;
  int? _dragTargetRow;
  int? _dragTargetCol;
  bool _isValidPlacement = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeGrid();
  }

  void _setupAnimations() {
    _clearAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _clearAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _clearAnimationController,
      curve: Curves.easeInBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _initializeGrid() {
    _occupiedCells = List.generate(
      GameConstants.gridSize,
      (row) => List.filled(GameConstants.gridSize, false),
    );
    
    _cellColors = List.generate(
      GameConstants.gridSize,
      (row) => List.filled(GameConstants.gridSize, null),
    );
    
    _cellBlocks = List.generate(
      GameConstants.gridSize,
      (row) => List.filled(GameConstants.gridSize, null),
    );
  }

  @override
  void dispose() {
    _clearAnimationController.dispose();
    _pulseController.dispose();
    for (final controller in _cellControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameStateLoaded) {
          _updateGridFromGameState(state);
        }
      },
      child: Container(
        margin: EdgeInsets.all(ResponsiveUtils.wp(2)),
        padding: EdgeInsets.all(ResponsiveUtils.wp(2)),
        decoration: _buildBoardDecoration(),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = _calculateCellSize(constraints);
              return _buildGrid(cellSize);
            },
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBoardDecoration() {
    return BoxDecoration(
      gradient: AppTheme.surfaceGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppTheme.primaryColor.withOpacity(0.3),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
        BoxShadow(
          color: AppTheme.primaryColor.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  double _calculateCellSize(BoxConstraints constraints) {
    final availableSize = math.min(constraints.maxWidth, constraints.maxHeight);
    final totalSpacing = GameConstants.cellSpacing * (GameConstants.gridSize - 1);
    return (availableSize - totalSpacing) / GameConstants.gridSize;
  }

  Widget _buildGrid(double cellSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(GameConstants.gridSize, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(GameConstants.gridSize, (col) {
            return Container(
              margin: EdgeInsets.all(GameConstants.cellSpacing / 2),
              child: _buildCell(row, col, cellSize),
            );
          }),
        );
      }),
    );
  }

  Widget _buildCell(int row, int col, double cellSize) {
    final isOccupied = _occupiedCells[row][col];
    final cellColor = _cellColors[row][col];
    final isHighlighted = _shouldHighlightCell(row, col);
    final isValidTarget = _isValidPlacementTarget(row, col);
    final isAnimating = _animatingRows.contains(row) || _animatingCols.contains(col);

    Widget cell = Container(
      width: cellSize,
      height: cellSize,
      decoration: _buildCellDecoration(
        isOccupied: isOccupied,
        cellColor: cellColor,
        isHighlighted: isHighlighted,
        isValidTarget: isValidTarget,
      ),
      child: _buildCellContent(row, col, isOccupied),
    );

    // Add animations if needed
    if (isAnimating) {
      cell = _buildAnimatedCell(cell, row, col);
    }

    // Add drag target functionality
    if (widget.interactive) {
      cell = _buildDragTarget(cell, row, col);
    }

    return cell;
  }

  BoxDecoration _buildCellDecoration({
    required bool isOccupied,
    required Color? cellColor,
    required bool isHighlighted,
    required bool isValidTarget,
  }) {
    Color backgroundColor;
    List<BoxShadow> shadows = [];
    Border? border;

    if (isOccupied && cellColor != null) {
      backgroundColor = cellColor;
      shadows = [
        BoxShadow(
          color: cellColor.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isValidTarget) {
      backgroundColor = AppTheme.successColor.withOpacity(0.3);
      border = Border.all(
        color: AppTheme.successColor,
        width: 2,
      );
    } else if (isHighlighted) {
      backgroundColor = AppTheme.primaryColor.withOpacity(0.2);
      border = Border.all(
        color: AppTheme.primaryColor.withOpacity(0.5),
        width: 1,
      );
    } else {
      backgroundColor = AppTheme.surfaceColor.withOpacity(0.1);
      border = Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      );
    }

    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(6),
      border: border,
      boxShadow: shadows,
    );
  }

  Widget _buildCellContent(int row, int col, bool isOccupied) {
    if (!isOccupied) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildAnimatedCell(Widget cell, int row, int col) {
    final cellKey = '$row-$col';
    
    if (!_cellControllers.containsKey(cellKey)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _cellControllers[cellKey] = controller;
    }

    final controller = _cellControllers[cellKey]!;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - (controller.value * 0.2),
          child: Opacity(
            opacity: 1.0 - controller.value,
            child: cell,
          ),
        );
      },
    );
  }

  Widget _buildDragTarget(Widget cell, int row, int col) {
    return DragTarget<flame_block.BlockComponent>(
      onWillAccept: (block) {
        return _canPlaceBlock(block, row, col);
      },
      onAccept: (block) {
        _placeBlock(block, row, col);
      },
      onMove: (details) {
        setState(() {
          _dragTargetRow = row;
          _dragTargetCol = col;
          _isValidPlacement = _canPlaceBlock(details.data, row, col);
        });
      },
      onLeave: (block) {
        setState(() {
          _dragTargetRow = null;
          _dragTargetCol = null;
          _isValidPlacement = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: widget.interactive ? () => _onCellTapped(row, col) : null,
          child: cell,
        );
      },
    );
  }

  bool _shouldHighlightCell(int row, int col) {
    // Highlight border cells for visual reference
    return row == 0 || row == GameConstants.gridSize - 1 ||
           col == 0 || col == GameConstants.gridSize - 1;
  }

  bool _isValidPlacementTarget(int row, int col) {
    if (_draggingBlock == null) return false;
    return _dragTargetRow == row && _dragTargetCol == col && _isValidPlacement;
  }

  bool _canPlaceBlock(flame_block.BlockComponent? block, int row, int col) {
    if (block == null) return false;

    // Check if block fits within grid bounds
    for (int blockRow = 0; blockRow < block.shape.length; blockRow++) {
      for (int blockCol = 0; blockCol < block.shape[blockRow].length; blockCol++) {
        if (block.shape[blockRow][blockCol] == 1) {
          final targetRow = row + blockRow;
          final targetCol = col + blockCol;
          
          // Check bounds
          if (targetRow >= GameConstants.gridSize || 
              targetCol >= GameConstants.gridSize ||
              targetRow < 0 || 
              targetCol < 0) {
            return false;
          }
          
          // Check if cell is already occupied
          if (_occupiedCells[targetRow][targetCol]) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  void _placeBlock(flame_block.BlockComponent block, int row, int col) {
    if (!_canPlaceBlock(block, row, col)) return;

    // Create BlockEntity from Flame component
    final blockEntity = BlockEntity(
      id: block.id,
      shape: block.shape,
      color: block.color,
      position: BlockPosition(row: row, col: col),
    );

    // Update grid state
    for (int blockRow = 0; blockRow < block.shape.length; blockRow++) {
      for (int blockCol = 0; blockCol < block.shape[blockRow].length; blockCol++) {
        if (block.shape[blockRow][blockCol] == 1) {
          final targetRow = row + blockRow;
          final targetCol = col + blockCol;
          
          _occupiedCells[targetRow][targetCol] = true;
          _cellColors[targetRow][targetCol] = block.color;
          _cellBlocks[targetRow][targetCol] = blockEntity;
        }
      }
    }

    // Trigger placement callback
    widget.onBlockPlaced?.call(blockEntity, row, col);

    // Check for line clears
    _checkForLineClear();

    setState(() {
      _draggingBlock = null;
      _dragTargetRow = null;
      _dragTargetCol = null;
      _isValidPlacement = false;
    });
  }

  void _checkForLineClear() {
    final clearedRows = <int>[];
    final clearedCols = <int>[];

    // Check rows
    for (int row = 0; row < GameConstants.gridSize; row++) {
      bool isRowComplete = true;
      for (int col = 0; col < GameConstants.gridSize; col++) {
        if (!_occupiedCells[row][col]) {
          isRowComplete = false;
          break;
        }
      }
      if (isRowComplete) {
        clearedRows.add(row);
      }
    }

    // Check columns
    for (int col = 0; col < GameConstants.gridSize; col++) {
      bool isColComplete = true;
      for (int row = 0; row < GameConstants.gridSize; row++) {
        if (!_occupiedCells[row][col]) {
          isColComplete = false;
          break;
        }
      }
      if (isColComplete) {
        clearedCols.add(col);
      }
    }

    if (clearedRows.isNotEmpty || clearedCols.isNotEmpty) {
      _animateLineClear(clearedRows, clearedCols);
    }
  }

  void _animateLineClear(List<int> rows, List<int> cols) {
    setState(() {
      _animatingRows.addAll(rows);
      _animatingCols.addAll(cols);
    });

    // Start animation for affected cells
    for (int row in rows) {
      for (int col = 0; col < GameConstants.gridSize; col++) {
        final cellKey = '$row-$col';
        _cellControllers[cellKey]?.forward();
      }
    }

    for (int col in cols) {
      for (int row = 0; row < GameConstants.gridSize; row++) {
        final cellKey = '$row-$col';
        _cellControllers[cellKey]?.forward();
      }
    }

    // Clear cells after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _clearLines(rows, cols);
    });
  }

  void _clearLines(List<int> rows, List<int> cols) {
    // Clear rows
    for (int row in rows) {
      for (int col = 0; col < GameConstants.gridSize; col++) {
        _occupiedCells[row][col] = false;
        _cellColors[row][col] = null;
        _cellBlocks[row][col] = null;
        
        final cellKey = '$row-$col';
        _cellControllers[cellKey]?.reset();
      }
    }

    // Clear columns
    for (int col in cols) {
      for (int row = 0; row < GameConstants.gridSize; row++) {
        _occupiedCells[row][col] = false;
        _cellColors[row][col] = null;
        _cellBlocks[row][col] = null;
        
        final cellKey = '$row-$col';
        _cellControllers[cellKey]?.reset();
      }
    }

    setState(() {
      _animatingRows.removeAll(rows);
      _animatingCols.removeAll(cols);
    });

    // Trigger callback
    widget.onLinesCleared?.call(rows, cols);
  }

  void _onCellTapped(int row, int col) {
    // Handle cell tap if needed
    // Could be used for power-ups or special actions
  }

  void _updateGridFromGameState(GameStateLoaded state) {
    // Update grid from game state if needed
    // This would be called when the game state changes
  }

  // Public methods for external control
  void clearCell(int row, int col) {
    if (row >= 0 && row < GameConstants.gridSize &&
        col >= 0 && col < GameConstants.gridSize) {
      setState(() {
        _occupiedCells[row][col] = false;
        _cellColors[row][col] = null;
        _cellBlocks[row][col] = null;
      });
    }
  }

  void resetBoard() {
    setState(() {
      _initializeGrid();
      _animatingRows.clear();
      _animatingCols.clear();
    });
    
    for (final controller in _cellControllers.values) {
      controller.reset();
    }
  }

  void highlightPossiblePlacements(flame_block.BlockComponent block) {
    // Could be used to show valid placement positions
    setState(() {
      _draggingBlock = block;
    });
  }

  void clearHighlights() {
    setState(() {
      _draggingBlock = null;
      _dragTargetRow = null;
      _dragTargetCol = null;
      _isValidPlacement = false;
    });
  }
}