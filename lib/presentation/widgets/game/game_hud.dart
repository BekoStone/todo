import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import '../common/animated_counter.dart';
import '../common/gradient_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';

/// GameHUD provides the heads-up display for the game interface.
/// Optimized for performance with minimal rebuilds and efficient layout.
/// Follows responsive design principles for multiple screen sizes.
class GameHUD extends StatefulWidget {
  /// Current score
  final int score;
  
  /// Current level
  final int level;
  
  /// Total lines cleared
  final int linesCleared;
  
  /// Queue of next blocks
  final List<BlockEntity> nextBlocks;
  
  /// Current combo count
  final int currentCombo;
  
  /// Available power-ups
  final List<PowerUp> powerUps;
  
  /// Whether undo is available
  final bool canUndo;
  
  /// Remaining undo moves
  final int remainingUndos;
  
  /// Callback when pause button is pressed
  final VoidCallback? onPausePressed;
  
  /// Callback when undo button is pressed
  final VoidCallback? onUndoPressed;
  
  /// Callback when power-up is used
  final Function(PowerUpType)? onPowerUpPressed;
  
  /// Whether to show detailed stats
  final bool showDetailedStats;
  
  /// Whether HUD should be compact
  final bool isCompact;

  const GameHUD({
    super.key,
    required this.score,
    required this.level,
    required this.linesCleared,
    this.nextBlocks = const [],
    this.currentCombo = 0,
    this.powerUps = const [],
    this.canUndo = false,
    this.remainingUndos = 0,
    this.onPausePressed,
    this.onUndoPressed,
    this.onPowerUpPressed,
    this.showDetailedStats = true,
    this.isCompact = false,
  });

  @override
  State<GameHUD> createState() => _GameHUDState();
}

class _GameHUDState extends State<GameHUD> with TickerProviderStateMixin {
  
  late AnimationController _comboAnimationController;
  late AnimationController _levelUpController;
  late Animation<double> _comboScaleAnimation;
  late Animation<double> _levelUpAnimation;
  
  int _previousLevel = 1;
  int _previousCombo = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _previousLevel = widget.level;
    _previousCombo = widget.currentCombo;
  }

  @override
  void didUpdateWidget(GameHUD oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger level up animation
    if (widget.level > _previousLevel) {
      _triggerLevelUpAnimation();
      _previousLevel = widget.level;
    }
    
    // Trigger combo animation
    if (widget.currentCombo > _previousCombo && widget.currentCombo > 1) {
      _triggerComboAnimation();
    }
    _previousCombo = widget.currentCombo;
  }

  @override
  void dispose() {
    _comboAnimationController.dispose();
    _levelUpController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _comboAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _levelUpController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _comboScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _comboAnimationController,
      curve: Curves.elasticOut,
    ));

    _levelUpAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelUpController,
      curve: Curves.bounceOut,
    ));
  }

  void _triggerComboAnimation() {
    _comboAnimationController.forward().then((_) {
      _comboAnimationController.reverse();
    });
  }

  void _triggerLevelUpAnimation() {
    _levelUpController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _levelUpController.reverse();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isLandscape()) {
      return _buildLandscapeLayout();
    } else {
      return _buildPortraitLayout();
    }
  }

  Widget _buildPortraitLayout() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                _buildLeftPanel(),
                Expanded(child: Container()), // Game area
                _buildRightPanel(),
              ],
            ),
          ),
          if (!widget.isCompact) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return SafeArea(
      child: Row(
        children: [
          _buildLeftPanel(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: Container()), // Game area
                if (!widget.isCompact) _buildBottomBar(),
              ],
            ),
          ),
          _buildRightPanel(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: ResponsiveUtils.getHUDElementSize(),
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getAdaptivePadding()),
      child: Row(
        children: [
          _buildPauseButton(),
          const Spacer(),
          _buildScoreDisplay(),
          const Spacer(),
          _buildLevelDisplay(),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    final panelWidth = ResponsiveUtils.isMobile() 
        ? ResponsiveUtils.wp(20) 
        : ResponsiveUtils.wp(15);
    
    return Container(
      width: panelWidth,
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
      child: Column(
        children: [
          if (widget.showDetailedStats) ...[
            _buildStatsPanel(),
            SizedBox(height: ResponsiveUtils.hp(2)),
          ],
          if (widget.nextBlocks.isNotEmpty) ...[
            _buildNextBlocksPanel(),
            SizedBox(height: ResponsiveUtils.hp(2)),
          ],
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    final panelWidth = ResponsiveUtils.isMobile() 
        ? ResponsiveUtils.wp(20) 
        : ResponsiveUtils.wp(15);
    
    return Container(
      width: panelWidth,
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
      child: Column(
        children: [
          if (widget.currentCombo > 1) ...[
            _buildComboDisplay(),
            SizedBox(height: ResponsiveUtils.hp(2)),
          ],
          if (widget.powerUps.isNotEmpty) ...[
            _buildPowerUpsPanel(),
            SizedBox(height: ResponsiveUtils.hp(2)),
          ],
          const Spacer(),
          _buildLevelUpIndicator(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: ResponsiveUtils.getHUDElementSize() * 0.8,
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getAdaptivePadding()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickStat('Lines', widget.linesCleared),
          _buildQuickStat('Combo', widget.currentCombo),
          if (widget.powerUps.isNotEmpty)
            _buildQuickStat('Power-ups', widget.powerUps.length),
        ],
      ),
    );
  }

  Widget _buildPauseButton() {
    return GradientButton.compact(
      text: '',
      icon: Icons.pause_rounded,
      onPressed: () {
        HapticFeedback.lightImpact();
        widget.onPausePressed?.call();
      },
      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha:0.8),
      textColor: Theme.of(context).colorScheme.onSurface,
      width: ResponsiveUtils.getHUDElementSize(),
    );
  }

  Widget _buildScoreDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SCORE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).gameColors.scoreText,
            fontWeight: FontWeight.bold,
          ),
        ),
        AnimatedScoreCounter(
          score: widget.score,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).gameColors.scoreText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'LEVEL',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).gameColors.levelText,
            fontWeight: FontWeight.bold,
          ),
        ),
        AnimatedLevelCounter(
          level: widget.level,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).gameColors.levelText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).gameColors.hudBackground.withValues(alpha:0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'STATS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildStatRow('Lines', widget.linesCleared),
          _buildStatRow('Level', widget.level),
          if (widget.currentCombo > 1)
            _buildStatRow('Combo', widget.currentCombo),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextBlocksPanel() {
    if (widget.nextBlocks.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).gameColors.hudBackground.withValues(alpha:0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'NEXT',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...widget.nextBlocks.take(3).map((block) => _buildMiniBlock(block)),
        ],
      ),
    );
  }

  Widget _buildMiniBlock(BlockEntity block) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: block.color.withValues(alpha:0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        block.type.name,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildComboDisplay() {
    return AnimatedBuilder(
      animation: _comboScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _comboScaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'COMBO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.currentCombo}x',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPowerUpsPanel() {
    return Column(
      children: [
        Text(
          'POWER-UPS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...widget.powerUps.map((powerUp) => _buildPowerUpButton(powerUp)),
      ],
    );
  }

  Widget _buildPowerUpButton(PowerUp powerUp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: GradientButton.compact(
        text: powerUp.type.name.toUpperCase(),
        onPressed: () {
          HapticFeedback.mediumImpact();
          widget.onPowerUpPressed?.call(powerUp.type);
        },
        backgroundColor: Theme.of(context).gameColors.powerUpBackground,
        textColor: Colors.white,
        width: double.infinity,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.canUndo && widget.remainingUndos > 0) ...[
          GradientButton.compact(
            text: 'UNDO',
            icon: Icons.undo_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onUndoPressed?.call();
            },
            backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha:0.8),
            textColor: Colors.white,
            width: double.infinity,
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.remainingUndos} left',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLevelUpIndicator() {
    return AnimatedBuilder(
      animation: _levelUpAnimation,
      builder: (context, child) {
        if (_levelUpAnimation.value == 0) {
          return const SizedBox.shrink();
        }
        
        return Opacity(
          opacity: _levelUpAnimation.value,
          child: Transform.scale(
            scale: _levelUpAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.tertiary,
                    Theme.of(context).colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha:0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: ResponsiveUtils.sp(24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LEVEL UP!',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level ${widget.level}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(String label, int value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}