import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../flame/components/block_component.dart' as flame_block;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/responsive_utils.dart';

class BlockSlot extends StatefulWidget {
  /// The slot index (0, 1, or 2)
  final int index;
  
  /// The block entity to display
  final BlockEntity? block;
  
  /// Callback when block is dragged from this slot
  final Function(BlockEntity block)? onBlockDragStarted;
  
  /// Callback when block drag is completed
  final VoidCallback? onBlockDragCompleted;
  
  /// Whether this slot is interactive
  final bool interactive;
  
  /// Whether to show slot animations
  final bool animate;

  const BlockSlot({
    super.key,
    required this.index,
    this.block,
    this.onBlockDragStarted,
    this.onBlockDragCompleted,
    this.interactive = true,
    this.animate = true,
  });

  @override
  State<BlockSlot> createState() => _BlockSlotState();
}

class _BlockSlotState extends State<BlockSlot>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  
  bool _isDragging = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BlockSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.block != widget.block) {
      if (widget.block != null && oldWidget.block == null) {
        // Block appeared - trigger shimmer
        _shimmerController.forward().then((_) {
          _shimmerController.reset();
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _scaleAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * 
                 (widget.animate ? _pulseAnimation.value : 1.0),
          child: _buildSlotContainer(),
        );
      },
    );
  }

  Widget _buildSlotContainer() {
    final slotSize = ResponsiveUtils.wp(20);
    
    return Container(
      width: slotSize,
      height: slotSize,
      margin: EdgeInsets.all(ResponsiveUtils.wp(1)),
      child: Stack(
        children: [
          // Slot background
          _buildSlotBackground(slotSize),
          
          // Shimmer effect
          if (widget.animate)
            _buildShimmerEffect(slotSize),
          
          // Block content
          if (widget.block != null)
            _buildBlockContent(slotSize)
          else
            _buildEmptySlotContent(slotSize),
          
          // Slot number indicator
          _buildSlotIndicator(),
        ],
      ),
    );
  }

  Widget _buildSlotBackground(double slotSize) {
    final slotColors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.secondaryColor,
    ];
    
    final slotColor = slotColors[widget.index % slotColors.length];
    
    return Container(
      width: slotSize,
      height: slotSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.block != null
              ? [
                  slotColor.withOpacity(0.3),
                  slotColor.withOpacity(0.1),
                ]
              : [
                  Colors.grey.withOpacity(0.2),
                  Colors.grey.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.block != null
              ? slotColor.withOpacity(0.6)
              : Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: widget.block != null
            ? [
                BoxShadow(
                  color: slotColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildShimmerEffect(double slotSize) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment(_shimmerAnimation.value - 1, 0),
                  end: Alignment(_shimmerAnimation.value, 0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockContent(double slotSize) {
    final block = widget.block!;
    
    return Positioned.fill(
      child: widget.interactive
          ? _buildDraggableBlock(block, slotSize)
          : _buildStaticBlock(block, slotSize),
    );
  }

  Widget _buildDraggableBlock(BlockEntity block, double slotSize) {
    return Draggable<flame_block.BlockComponent>(
      data: _createFlameBlock(block),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.1,
          child: _buildBlockPreview(block, slotSize),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildBlockPreview(block, slotSize),
      ),
      onDragStarted: () {
        setState(() {
          _isDragging = true;
        });
        _scaleController.forward();
        widget.onBlockDragStarted?.call(block);
      },
      onDragEnd: (details) {
        setState(() {
          _isDragging = false;
        });
        _scaleController.reverse();
        widget.onBlockDragCompleted?.call();
      },
      child: _buildBlockPreview(block, slotSize),
    );
  }

  Widget _buildStaticBlock(BlockEntity block, double slotSize) {
    return _buildBlockPreview(block, slotSize);
  }

  Widget _buildBlockPreview(BlockEntity block, double slotSize) {
    final blockSize = _calculateBlockSize(block, slotSize);
    final cellSize = blockSize / math.max(block.shape.length, block.shape[0].length);
    
    return Center(
      child: Container(
        width: blockSize,
        height: blockSize,
        child: _buildBlockGrid(block, cellSize),
      ),
    );
  }

  Widget _buildBlockGrid(BlockEntity block, double cellSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(block.shape.length, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(block.shape[row].length, (col) {
            final isActive = block.shape[row][col] == 1;
            return Container(
              width: cellSize,
              height: cellSize,
              margin: const EdgeInsets.all(1),
              decoration: isActive
                  ? _buildBlockCellDecoration(block.color)
                  : null,
            );
          }),
        );
      }),
    );
  }

  BoxDecoration _buildBlockCellDecoration(Color color) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          color.withOpacity(0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Widget _buildEmptySlotContent(double slotSize) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_rounded,
            size: ResponsiveUtils.sp(16),
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          Text(
            'Slot ${widget.index + 1}',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: ResponsiveUtils.sp(10),
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotIndicator() {
    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: _getSlotIndicatorColor(),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '${widget.index + 1}',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.sp(8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getSlotIndicatorColor() {
    if (widget.block != null) {
      return AppTheme.successColor.withOpacity(0.8);
    } else {
      return Colors.grey.withOpacity(0.5);
    }
  }

  double _calculateBlockSize(BlockEntity block, double slotSize) {
    final maxDimension = math.max(block.shape.length, block.shape[0].length);
    return (slotSize * 0.7).clamp(20.0, slotSize - 20);
  }

  flame_block.BlockComponent _createFlameBlock(BlockEntity block) {
    // Convert BlockEntity to Flame BlockComponent
    return flame_block.BlockComponent(
      id: block.id,
      shape: block.shape,
      color: block.color,
    );
  }

  // Public methods for external control
  void animateNewBlock() {
    if (widget.animate) {
      _shimmerController.forward().then((_) {
        _shimmerController.reset();
      });
    }
  }

  void animateBlockRemoval() {
    _scaleController.forward();
  }

  void resetAnimations() {
    _scaleController.reset();
    _shimmerController.reset();
  }
}

/// A specialized widget for displaying block slots in a row
class BlockSlotRow extends StatelessWidget {
  /// List of blocks to display in slots
  final List<BlockEntity?> blocks;
  
  /// Callback when a block is dragged from a slot
  final Function(BlockEntity block, int slotIndex)? onBlockDragStarted;
  
  /// Callback when block drag is completed
  final Function(int slotIndex)? onBlockDragCompleted;
  
  /// Whether slots are interactive
  final bool interactive;
  
  /// Whether to show animations
  final bool animate;
  
  /// Spacing between slots
  final double spacing;

  const BlockSlotRow({
    super.key,
    required this.blocks,
    this.onBlockDragStarted,
    this.onBlockDragCompleted,
    this.interactive = true,
    this.animate = true,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(2),
        vertical: ResponsiveUtils.hp(1),
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.surfaceGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          final block = index < blocks.length ? blocks[index] : null;
          
          return Expanded(
            child: Center(
              child: BlockSlot(
                index: index,
                block: block,
                interactive: interactive,
                animate: animate,
                onBlockDragStarted: (block) {
                  onBlockDragStarted?.call(block, index);
                },
                onBlockDragCompleted: () {
                  onBlockDragCompleted?.call(index);
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A preview widget for showing how a block would look when placed
class BlockPreview extends StatelessWidget {
  /// The block to preview
  final BlockEntity block;
  
  /// Size of the preview
  final double size;
  
  /// Whether to show with transparency
  final bool transparent;

  const BlockPreview({
    super.key,
    required this.block,
    this.size = 60.0,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = size / math.max(block.shape.length, block.shape[0].length);
    
    return Opacity(
      opacity: transparent ? 0.6 : 1.0,
      child: Container(
        width: size,
        height: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(block.shape.length, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(block.shape[row].length, (col) {
                final isActive = block.shape[row][col] == 1;
                return Container(
                  width: cellSize,
                  height: cellSize,
                  margin: const EdgeInsets.all(0.5),
                  decoration: isActive
                      ? BoxDecoration(
                          color: block.color,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 0.5,
                          ),
                        )
                      : null,
                );
              }),
            );
          }),
        ),
      ),
    );
  }
}