import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/core/theme/colors.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'dart:math' as math;
import '../../../core/theme/app_theme.dart';
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
  
  /// Whether the slot is interactive
  final bool interactive;
  
  /// Whether to show animations
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
  
  // Animation controllers - CRITICAL: Must be disposed to prevent memory leaks
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  
  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  // State tracking
  bool _isHovered = false;
  bool _isDragging = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialAnimations();
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // CRITICAL: Dispose all animation controllers to prevent memory leaks
    _scaleController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    
    super.dispose();
  }

  void _setupAnimations() {
    // Scale animation for block placement/removal
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Shimmer animation for visual feedback
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Pulse animation for availability indication
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Rotation animation for block entrance
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create animation tweens
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startInitialAnimations() {
    if (widget.animate && mounted) {
      _scaleController.forward();
      
      // Start pulse animation for empty slots
      if (widget.block == null) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(BlockSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle block changes
    if (oldWidget.block != widget.block) {
      _handleBlockChange(oldWidget.block, widget.block);
    }
  }

  void _handleBlockChange(BlockEntity? oldBlock, BlockEntity? newBlock) {
    if (_isDisposed) return;
    
    if (oldBlock == null && newBlock != null) {
      // New block added
      _animateBlockEntrance();
    } else if (oldBlock != null && newBlock == null) {
      // Block removed
      _animateBlockExit();
    } else if (oldBlock != null && newBlock != null) {
      // Block changed
      _animateBlockChange();
    }
  }

  void _animateBlockEntrance() {
    if (!widget.animate || _isDisposed) return;
    
    _pulseController.stop();
    _pulseController.reset();
    
    _scaleController.reset();
    _rotationController.reset();
    
    _scaleController.forward();
    _rotationController.forward();
  }

  void _animateBlockExit() {
    if (!widget.animate || _isDisposed) return;
    
    _scaleController.reverse().then((_) {
      if (!_isDisposed && widget.block == null) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _animateBlockChange() {
    if (!widget.animate || _isDisposed) return;
    
    _scaleController.reverse().then((_) {
      if (!_isDisposed) {
        _scaleController.forward();
        _rotationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final slotSize = _calculateSlotSize();
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _shimmerAnimation,
        _pulseAnimation,
        _rotationAnimation,
      ]),
      builder: (context, child) {
        return _buildSlotContainer(slotSize);
      },
    );
  }

  Widget _buildSlotContainer(double slotSize) {
    return GestureDetector(
      onTap: widget.interactive ? _handleTap : null,
      onPanStart: widget.interactive ? _handlePanStart : null,
      onPanEnd: widget.interactive ? _handlePanEnd : null,
      child: MouseRegion(
        onEnter: widget.interactive ? _handleMouseEnter : null,
        onExit: widget.interactive ? _handleMouseExit : null,
        child: Transform.scale(
          scale: _isHovered ? 1.05 : 1.0,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: slotSize,
              height: slotSize,
              decoration: _buildSlotDecoration(),
              child: _buildSlotContent(slotSize),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildSlotDecoration() {
    final hasBlock = widget.block != null;
    
    return BoxDecoration(
      gradient: hasBlock 
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary.withValues(alpha:0.3),
              AppColors.secondary.withValues(alpha:0.1),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha:0.1),
              Colors.white.withValues(alpha:0.05),
            ],
          ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: hasBlock 
          ? AppColors.secondary.withValues(alpha:0.5)
          : Colors.white.withValues(alpha:0.2),
        width: 2,
      ),
      boxShadow: hasBlock ? [
        BoxShadow(
          color: AppColors.secondary.withValues(alpha:0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ] : [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildSlotContent(double slotSize) {
    if (widget.block == null) {
      return _buildEmptySlot(slotSize);
    }
    
    return Transform.scale(
      scale: _scaleAnimation.value,
      child: Transform.rotate(
        angle: _rotationAnimation.value * 0.1,
        child: _buildBlockDisplay(slotSize),
      ),
    );
  }

  Widget _buildEmptySlot(double slotSize) {
    return Center(
      child: Container(
        width: slotSize * 0.3,
        height: slotSize * 0.3,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add,
          color: Colors.white.withValues(alpha:0.6),
          size: slotSize * 0.15,
        ),
      ),
    );
  }

  Widget _buildBlockDisplay(double slotSize) {
    final block = widget.block!;
    final blockSize = _calculateBlockSize(block, slotSize);
    
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmer effect background
          if (widget.animate)
            _buildShimmerEffect(blockSize),
          
          // Block shape
          _buildBlockShape(block, blockSize),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect(double blockSize) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: blockSize * 1.2,
          height: blockSize * 1.2,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha:0.3 * _shimmerAnimation.value),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  Widget _buildBlockShape(BlockEntity block, double blockSize) {
    final cellSize = blockSize / math.max(block.shape.length, block.shape[0].length);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: block.shape.asMap().entries.map((rowEntry) {
        final row = rowEntry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: row.asMap().entries.map((colEntry) {
            final cell = colEntry.value;
            return Container(
              width: cellSize,
              height: cellSize,
              margin: const EdgeInsets.all(1),
              decoration: cell ? BoxDecoration(
                color: block.color,
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    block.color,
                    block.color.withValues(alpha:0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: block.color.withValues(alpha:0.3),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ) : null,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  double _calculateSlotSize() {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseSize = screenWidth * 0.2;
    return baseSize.clamp(60.0, 120.0);
  }

  double _calculateBlockSize(BlockEntity block, double slotSize) {
    final maxDimension = math.max(block.shape.length, block.shape[0].length);
    return (slotSize * 0.7).clamp(20.0, slotSize - 20);
  }

  // Event handlers
  void _handleTap() {
    if (widget.block != null && widget.onBlockDragStarted != null) {
      widget.onBlockDragStarted!(widget.block!);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    if (widget.block != null) {
      setState(() {
        _isDragging = true;
      });
      
      if (widget.onBlockDragStarted != null) {
        widget.onBlockDragStarted!(widget.block!);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });
      
      widget.onBlockDragCompleted?.call();
    }
  }

  void _handleMouseEnter(PointerEnterEvent event) {
    if (widget.interactive) {
      setState(() {
        _isHovered = true;
      });
    }
  }

  void _handleMouseExit(PointerExitEvent event) {
    if (widget.interactive) {
      setState(() {
        _isHovered = false;
      });
    }
  }

  // Public methods for external control
  void animateNewBlock() {
    if (widget.animate && !_isDisposed) {
      _shimmerController.forward().then((_) {
        if (!_isDisposed) {
          _shimmerController.reset();
        }
      });
    }
  }

  void animateBlockRemoval() {
    if (!_isDisposed) {
      _scaleController.reverse();
    }
  }

  void resetAnimations() {
    if (!_isDisposed) {
      _scaleController.reset();
      _shimmerController.reset();
      _rotationController.reset();
      
      // Restart pulse for empty slots
      if (widget.block == null) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
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
          color: Colors.white.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          final block = index < blocks.length ? blocks[index] : null;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
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

/// A widget that conditionally shows block slot content
class ConditionalBlockSlot extends StatelessWidget {
  final BlockEntity? block;
  final bool showWhenEmpty;
  final Widget? emptyWidget;
  final Function(BlockEntity)? onBlockSelected;

  const ConditionalBlockSlot({
    super.key,
    this.block,
    this.showWhenEmpty = true,
    this.emptyWidget,
    this.onBlockSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (block == null && !showWhenEmpty) {
      return emptyWidget ?? const SizedBox();
    }

    return BlockSlot(
      index: 0,
      block: block,
      onBlockDragStarted: onBlockSelected,
    );
  }
}