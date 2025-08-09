import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import '../common/gradient_button.dart';
import '../common/animated_counter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/audio_service.dart';
import '../../../injection_container.dart';

/// GameOverOverlay displays game completion results with achievements and actions.
/// Optimized for performance with proper memory management and smooth animations.
/// Follows Clean Architecture with proper state management integration.
class GameOverOverlay extends StatefulWidget {
  /// The completed game session
  final GameSession gameSession;
  
  /// Newly unlocked achievements
  final List<Achievement> unlockedAchievements;
  
  /// Callback when restart is requested
  final VoidCallback? onRestart;
  
  /// Callback when main menu is requested
  final VoidCallback? onMainMenu;
  
  /// Callback when share is requested
  final VoidCallback? onShare;
  
  /// Callback when watching ad for coins
  final VoidCallback? onWatchAd;
  
  /// Whether undo is available
  final bool canUndo;
  
  /// Callback when undo is requested
  final VoidCallback? onUndo;
  
  /// Whether to show detailed statistics
  final bool showDetailedStats;

  const GameOverOverlay({
    super.key,
    required this.gameSession,
    this.unlockedAchievements = const [],
    this.onRestart,
    this.onMainMenu,
    this.onShare,
    this.onWatchAd,
    this.canUndo = false,
    this.onUndo,
    this.showDetailedStats = true,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _achievementController;
  late AnimationController _statsController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _achievementSlideAnimation;
  late Animation<double> _statsRevealAnimation;
  
  // Audio service
  late AudioService _audioService;
  
  // State tracking
  bool _isDisposed = false;
  bool _showingAchievements = false;
  bool _animationsCompleted = false;
  int _currentAchievementIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDependencies();
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mainController.dispose();
    _achievementController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    // Main overlay animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Achievement animation
    _achievementController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Stats animation
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Set up animation curves
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));

    _achievementSlideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _achievementController,
      curve: Curves.easeOutBounce,
    ));

    _statsRevealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeInOutCubic,
    ));
  }

  void _initializeDependencies() {
    _audioService = getIt<AudioService>();
  }

  Future<void> _startAnimationSequence() async {
    if (_isDisposed) return;

    try {
      // Play game over sound
      _audioService.playSfx('game_over');
      
      // Start main overlay animation
      await _mainController.forward();
      
      if (_isDisposed) return;
      
      // Start stats animation
      await _statsController.forward();
      
      if (_isDisposed) return;
      
      // Show achievements if any
      if (widget.unlockedAchievements.isNotEmpty) {
        await _showAchievements();
      }
      
      _animationsCompleted = true;
      
    } catch (e) {
      // Handle animation errors gracefully
      _animationsCompleted = true;
    }
  }

  Future<void> _showAchievements() async {
    if (_isDisposed || widget.unlockedAchievements.isEmpty) return;

    setState(() {
      _showingAchievements = true;
    });

    // Show each achievement with a delay
    for (int i = 0; i < widget.unlockedAchievements.length; i++) {
      if (_isDisposed) break;
      
      setState(() {
        _currentAchievementIndex = i;
      });
      
      _achievementController.reset();
      await _achievementController.forward();
      
      // Play achievement sound
      _audioService.playSfx('achievement_unlock');
      
      // Wait before showing next achievement
      if (i < widget.unlockedAchievements.length - 1) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _achievementController, _statsController]),
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.8 * _fadeAnimation.value),
          child: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildMainContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(8),
        vertical: ResponsiveUtils.hp(10),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            SizedBox(height: ResponsiveUtils.hp(2)),
            _buildScore(),
            SizedBox(height: ResponsiveUtils.hp(2)),
            if (widget.showDetailedStats) ...[
              _buildDetailedStats(),
              SizedBox(height: ResponsiveUtils.hp(2)),
            ],
            if (_showingAchievements && widget.unlockedAchievements.isNotEmpty) ...[
              _buildAchievementDisplay(),
              SizedBox(height: ResponsiveUtils.hp(2)),
            ],
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isHighScore = widget.gameSession.isPersonalBest;
    
    return Column(
      children: [
        Icon(
          isHighScore ? Icons.emoji_events : Icons.flag,
          size: ResponsiveUtils.sp(48),
          color: isHighScore 
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: ResponsiveUtils.hp(1)),
        Text(
          isHighScore ? 'New High Score!' : 'Game Over',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighScore 
                ? Theme.of(context).colorScheme.tertiary
                : null,
          ),
        ),
        if (isHighScore) ...[
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          Text(
            '🎉 Congratulations! 🎉',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScore() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        children: [
          Text(
            'Final Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          AnimatedCounter(
            count: widget.gameSession.finalScore,
            duration: const Duration(milliseconds: 1500),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (widget.gameSession.isPersonalBest) ...[
            SizedBox(height: ResponsiveUtils.hp(0.5)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'PERSONAL BEST',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return AnimatedBuilder(
      animation: _statsRevealAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _statsRevealAnimation.value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * _statsRevealAnimation.value),
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              ),
              child: Column(
                children: [
                  Text(
                    'Game Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.hp(1.5)),
                  _buildStatsGrid(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    final stats = widget.gameSession.statistics;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: ResponsiveUtils.isMobile() ? 2 : 3,
      childAspectRatio: 2.5,
      mainAxisSpacing: ResponsiveUtils.hp(1),
      crossAxisSpacing: ResponsiveUtils.wp(2),
      children: [
        _buildStatItem('Level', '${widget.gameSession.level}', Icons.trending_up),
        _buildStatItem('Lines', '${stats.linesCleared}', Icons.horizontal_rule),
        _buildStatItem('Blocks', '${stats.blocksPlaced}', Icons.apps),
        _buildStatItem('Time', _formatDuration(widget.gameSession.duration), Icons.access_time),
        if (stats.perfectClears > 0)
          _buildStatItem('Perfect', '${stats.perfectClears}', Icons.star),
        if (stats.powerUpsUsed > 0)
          _buildStatItem('Power-ups', '${stats.powerUpsUsed}', Icons.flash_on),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: ResponsiveUtils.sp(16),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementDisplay() {
    if (widget.unlockedAchievements.isEmpty) return const SizedBox.shrink();
    
    final achievement = widget.unlockedAchievements[_currentAchievementIndex];
    
    return AnimatedBuilder(
      animation: _achievementSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            ResponsiveUtils.width() * _achievementSlideAnimation.value,
            0,
          ),
          child: Container(
            padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
              border: Border.all(
                color: Theme.of(context).colorScheme.tertiary,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: ResponsiveUtils.sp(24),
                    ),
                    SizedBox(width: ResponsiveUtils.wp(2)),
                    Text(
                      'Achievement Unlocked!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.hp(1)),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.hp(0.5)),
                          Text(
                            achievement.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (achievement.coinReward > 0) ...[
                      SizedBox(width: ResponsiveUtils.wp(2)),
                      Column(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: ResponsiveUtils.sp(20),
                          ),
                          Text(
                            '+${achievement.coinReward}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary actions row
        Row(
          children: [
            if (widget.canUndo) ...[
              Expanded(
                child: GradientButton(
                  text: 'Undo',
                  icon: Icons.undo_rounded,
                  onPressed: _handleUndo,
                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  textColor: Theme.of(context).colorScheme.secondary,
                  height: ResponsiveUtils.getButtonSize(),
                ),
              ),
              SizedBox(width: ResponsiveUtils.wp(2)),
            ],
            Expanded(
              child: GradientButton(
                text: 'Play Again',
                icon: Icons.refresh_rounded,
                onPressed: _handleRestart,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                height: ResponsiveUtils.getButtonSize(),
              ),
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.hp(1.5)),
        
        // Secondary actions row
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Share',
                icon: Icons.share_rounded,
                onPressed: _handleShare,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                height: ResponsiveUtils.getButtonSize() * 0.8,
              ),
            ),
            SizedBox(width: ResponsiveUtils.wp(2)),
            if (widget.onWatchAd != null) ...[
              Expanded(
                child: GradientButton(
                  text: 'Watch Ad',
                  icon: Icons.play_circle_outline,
                  onPressed: _handleWatchAd,
                  backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                  textColor: Theme.of(context).colorScheme.tertiary,
                  height: ResponsiveUtils.getButtonSize() * 0.8,
                ),
              ),
              SizedBox(width: ResponsiveUtils.wp(2)),
            ],
            Expanded(
              child: GradientButton(
                text: 'Main Menu',
                icon: Icons.home_rounded,
                onPressed: _handleMainMenu,
                backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.2),
                textColor: Theme.of(context).colorScheme.error,
                height: ResponsiveUtils.getButtonSize() * 0.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleRestart() {
    _playButtonSound();
    HapticFeedback.lightImpact();
    _closeOverlay();
    widget.onRestart?.call();
  }

  void _handleMainMenu() {
    _playButtonSound();
    HapticFeedback.lightImpact();
    _closeOverlay();
    widget.onMainMenu?.call();
  }

  void _handleShare() {
    _playButtonSound();
    HapticFeedback.lightImpact();
    widget.onShare?.call();
  }

  void _handleWatchAd() {
    _playButtonSound();
    HapticFeedback.lightImpact();
    widget.onWatchAd?.call();
  }

  void _handleUndo() {
    _playButtonSound();
    HapticFeedback.lightImpact();
    _closeOverlay();
    widget.onUndo?.call();
  }

  Future<void> _closeOverlay() async {
    await _mainController.reverse();
    if (!_isDisposed && mounted) {
      context.read<UICubit>().hideGameOverOverlay();
    }
  }

  void _playButtonSound() {
    try {
      _audioService.playSfx('ui_click');
    } catch (e) {
      // Silently handle audio errors
    }
  }
}