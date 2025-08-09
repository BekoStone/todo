import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/game_state.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'dart:math' as math;
import '../../flame/box_hooks_game.dart';
import '../../flame/components/block_component.dart' as flame_block;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/performance_utils.dart';

class GameBoard extends StatefulWidget {
  /// The Flame game instance
  final BoxHooksGame game;
  
  /// Callback when a block is placed on the board
  final Function(BlockEntity block, int row, int col)? onBlockPlaced;
  
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
  
  // Animation controllers - CRITICAL: These must be disposed properly
  late AnimationController _clearAnimationController;
  late AnimationController _pulseController;
  late AnimationController _placementController;
  late AnimationController _hoverController;
  
  // Animations
  late Animation<double> _clearAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _placementAnimation;
  late Animation<double> _hoverAnimation;
  
  // Grid state - optimized for differential updates
  late List<List<bool>> _occupiedCells;
  late List<List<Color?>> _cellColors;
  late List<List<BlockEntity?>> _cellBlocks;
  
  // Animation state tracking
  final Set<int> _animatingRows = {};
  final Set<int> _animatingCols = {};
  final Map<String, AnimationController> _cellControllers = {};
  
  // Drag state
  flame_block.BlockComponent? _draggingBlock;
  Offset? _dragOffset;
  int? _dragTargetRow;
  int? _dragTargetCol;
  bool _isValidPlacement = false;
  
  // Performance optimization
  bool _needsGridUpdate = true;
  final List<List<Widget>> _cachedCells = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeGrid();
    _startPerformanceMonitoring();
  }

  @override
  void dispose() {
    // CRITICAL: Dispose all animation controllers to prevent memory leaks
    _clearAnimationController.dispose();
    _pulseController.dispose();
    _placementController.dispose();
    _hoverController.dispose();
    
    // Dispose all dynamic cell controllers
    for (final controller in _cellControllers.values) {
      controller.dispose();
    }
    _cellControllers.clear();
    
    super.dispose();
  }

  void _setupAnimations() {
    // Line clear animation
    _clearAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Pulse animation for interactive feedback
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Block placement animation
    _placementController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Hover feedback animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Create animation tweens
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
    
    _placementAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _placementController,
      curve: Curves.elasticOut,
    ));
    
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    // Start continuous pulse animation
    _pulseController.repeat(reverse: true);
  }

  void _initializeGrid() {
    final gridSize = GameConstants.defaultGridSize;
    
    _occupiedCells = List.generate(
      gridSize,
      (row) => List.filled(gridSize, false),
    );
    
    _cellColors = List.generate(
      gridSize,
      (row) => List.filled(gridSize, null),
    );
    
    _cellBlocks = List.generate(
      gridSize,
      (row) => List.filled(gridSize, null),
    );
    
    // Initialize cached cells
    _cachedCells.clear();
    for (int i = 0; i < gridSize; i++) {
      _cachedCells.add(List.filled(gridSize, const SizedBox()));
    }
  }

  void _startPerformanceMonitoring() {
    if (GameConstants.enablePerformanceMonitoring) {
      PerformanceUtils.markFrameStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listener: (context, state) {
        _handleGameStateChange(state);
      },
      child: BlocBuilder<GameCubit, GameState>(
        buildWhen: (previous, current) {
          // Only rebuild when grid actually changes
          return previous.grid != current.grid ||
                 previous.activeBlocks != current.activeBlocks ||
                 previous.status != current.status;
        },
        builder: (context, state) {
          return _buildGameBoard(context, state);
        },
      ),
    );
  }

  Widget _buildGameBoard(BuildContext context, GameState state) {
    final screenSize = MediaQuery.of(context).size;
    final boardSize = _calculateBoardSize(screenSize);
    final cellSize = boardSize / GameConstants.defaultGridSize;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _clearAnimation,
          _pulseAnimation,
          _placementAnimation,
          _hoverAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: _buildGrid(state, cellSize),
          );
        },
      ),
    );
  }

  Widget _buildGrid(GameState state, double cellSize) {
    // Only rebuild grid if necessary for performance
    if (_needsGridUpdate) {
      _updateCachedGrid(state, cellSize);
      _needsGridUpdate = false;
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: GameConstants.defaultGridSize * GameConstants.defaultGridSize,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: GameConstants.defaultGridSize,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final row = index ~/ GameConstants.defaultGridSize;
        final col = index % GameConstants.defaultGridSize;
        return _cachedCells[row][col];
      },
    );
  }

  void _updateCachedGrid(GameState state, double cellSize) {
    for (int row = 0; row < GameConstants.defaultGridSize; row++) {
      for (int col = 0; col < GameConstants.defaultGridSize; col++) {
        _cachedCells[row][col] = _buildCell(state, row, col, cellSize);
      }
    }
  }

  Widget _buildCell(GameState state, int row, int col, double cellSize) {
    final isOccupied = row < state.grid.length && 
                      col < state.grid[row].length && 
                      state.grid[row][col];
    
    final cellBlock = _getCellBlock(state, row, col);
    final isAnimating = _animatingRows.contains(row) || _animatingCols.contains(col);
    
    return GestureDetector(
      onTap: widget.interactive ? () => _handleCellTap(row, col) : null,
      onPanStart: widget.interactive ? (details) => _handlePanStart(details, row, col) : null,
      onPanUpdate: widget.interactive ? (details) => _handlePanUpdate(details, row, col) : null,
      onPanEnd: widget.interactive ? (details) => _handlePanEnd(details, row, col) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _getCellColor(isOccupied, cellBlock, isAnimating),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _getBorderColor(row, col),
            width: 1,
          ),
          boxShadow: isOccupied ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: _buildCellContent(cellBlock, isAnimating, cellSize),
      ),
    );
  }

  Widget _buildCellContent(BlockEntity? block, bool isAnimating, double cellSize) {
    if (block == null) return const SizedBox();

    Widget content = Container(
      width: cellSize * 0.8,
      height: cellSize * 0.8,
      decoration: BoxDecoration(
        color: block.color,
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            block.color,
            block.color.withOpacity(0.7),
          ],
        ),
      ),
    );

    if (isAnimating) {
      return AnimatedBuilder(
        animation: _clearAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _clearAnimation.value,
            child: Transform.rotate(
              angle: (1 - _clearAnimation.value) * math.pi * 2,
              child: content,
            ),
          );
        },
      );
    }

    return content;
  }

  Color _getCellColor(bool isOccupied, BlockEntity? block, bool isAnimating) {
    if (isAnimating) {
      return Colors.white.withOpacity(0.8);
    }
    
    if (isOccupied && block != null) {
      return block.color.withOpacity(0.1);
    }
    
    return Colors.white.withOpacity(0.05);
  }

  Color _getBorderColor(int row, int col) {
    if (_dragTargetRow == row && _dragTargetCol == col) {
      return _isValidPlacement ? Colors.green : Colors.red;
    }
    
    return Colors.white.withOpacity(0.1);
  }

  BlockEntity? _getCellBlock(GameState state, int row, int col) {
    // Get block from active blocks that occupies this position
    for (final block in state.activeBlocks) {
      final positions = block.occupiedPositions;
      if (positions.any((pos) => pos.x == col && pos.y == row)) {
        return block;
      }
    }
    return null;
  }

  double _calculateBoardSize(Size screenSize) {
    final minDimension = math.min(screenSize.width, screenSize.height);
    return (minDimension * 0.8).clamp(200.0, 400.0);
  }

  void _handleGameStateChange(GameState state) {
    // Mark grid for update when state changes
    _needsGridUpdate = true;
    
    // Handle animations for line clears
    if (state.linesCleared > 0) {
      _animateLineClear();
    }
    
    // Update grid references
    if (state.grid != _occupiedCells) {
      _updateGridState(state);
    }
  }

  void _updateGridState(GameState state) {
    // Update grid state efficiently
    for (int row = 0; row < state.grid.length && row < _occupiedCells.length; row++) {
      for (int col = 0; col < state.grid[row].length && col < _occupiedCells[row].length; col++) {
        _occupiedCells[row][col] = state.grid[row][col];
      }
    }
  }

  void _animateLineClear() {
    _clearAnimationController.reset();
    _clearAnimationController.forward().then((_) {
      _clearAnimationController.reset();
      _animatingRows.clear();
      _animatingCols.clear();
      setState(() {
        _needsGridUpdate = true;
      });
    });
  }

  // Input handling methods
  void _handleCellTap(int row, int col) {
    if (!widget.interactive) return;
    
    // Trigger haptic feedback
    HapticFeedback.lightImpact();
    
    // Handle cell selection logic
    widget.onBlockPlaced?.call(_createDummyBlock(), row, col);
  }

  void _handlePanStart(DragStartDetails details, int row, int col) {
    if (!widget.interactive) return;
    
    _dragOffset = details.localPosition;
    _dragTargetRow = row;
    _dragTargetCol = col;
    
    // Start hover animation
    _hoverController.forward();
  }

  void _handlePanUpdate(DragUpdateDetails details, int row, int col) {
    if (!widget.interactive) return;
    
    // Update drag target position
    setState(() {
      _dragTargetRow = row;
      _dragTargetCol = col;
      _isValidPlacement = _validatePlacement(row, col);
    });
  }

  void _handlePanEnd(DragEndDetails details, int row, int col) {
    if (!widget.interactive) return;
    
    // Reset hover animation
    _hoverController.reverse();
    
    if (_isValidPlacement) {
      // Trigger placement animation
      _placementController.forward().then((_) {
        _placementController.reset();
      });
      
      widget.onBlockPlaced?.call(_createDummyBlock(), row, col);
    }
    
    // Reset drag state
    setState(() {
      _dragTargetRow = null;
      _dragTargetCol = null;
      _isValidPlacement = false;
      _dragOffset = null;
    });
  }

  bool _validatePlacement(int row, int col) {
    // Validate if block can be placed at this position
    return row >= 0 && 
           row < GameConstants.defaultGridSize && 
           col >= 0 && 
           col < GameConstants.defaultGridSize &&
           !_occupiedCells[row][col];
  }

  BlockEntity _createDummyBlock() {
    // Create a dummy block for testing
    return BlockEntity.create(
      type: BlockType.square,
      position: Position(0, 0),
    );
  }

  // Performance optimization methods
  void _createCellController(String key) {
    if (!_cellControllers.containsKey(key)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _cellControllers[key] = controller;
    }
  }

  void _disposeCellController(String key) {
    final controller = _cellControllers.remove(key);
    controller?.dispose();
  }

  void _optimizeMemoryUsage() {
    // Clean up unused cell controllers periodically
    final activeKeys = <String>{};
    
    // Add logic to determine which controllers are still needed
    for (int row = 0; row < GameConstants.defaultGridSize; row++) {
      for (int col = 0; col < GameConstants.defaultGridSize; col++) {
        if (_occupiedCells[row][col]) {
          activeKeys.add('$row-$col');
        }
      }
    }
    
    // Dispose unused controllers
    final keysToRemove = _cellControllers.keys.where((key) => !activeKeys.contains(key)).toList();
    for (final key in keysToRemove) {
      _disposeCellController(key);
    }
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Optimize memory when widget updates
    _optimizeMemoryUsage();
    
    // Mark for update if game instance changed
    if (oldWidget.game != widget.game) {
      _needsGridUpdate = true;
    }
  }
}