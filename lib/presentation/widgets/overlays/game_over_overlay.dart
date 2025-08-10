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
import '../../../core/theme/colors.dart';
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
  
  // Animation controllers - CRITICAL: Must be disposed properly
  late AnimationController _mainController;
  late AnimationController _achievementController;
  late AnimationController _statsController;
  late AnimationController _buttonController;
  late AnimationController _sparkleController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _achievementSlideAnimation;
  late Animation<double> _statsRevealAnimation;
  late Animation<double> _buttonStaggerAnimation;
  late Animation<double> _sparkleRotation;
  
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
    
    // CRITICAL: Dispose all animation controllers to prevent memory leaks
    _mainController.dispose();
    _achievementController.dispose();
    _statsController.dispose();
    _buttonController.dispose();
    _sparkleController.dispose();
    
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
    
    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Sparkle animation
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
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
      curve: Curves.bounceOut,
    ));

    _statsRevealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeInOutCubic,
    ));
    
    _buttonStaggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));
    
    _sparkleRotation = Tween<double>(
      begin: 0.0,
      end: 6.28318, // 2π
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.linear,
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
      
      // Start sparkle animation (infinite)
      _sparkleController.repeat();
      
      // Start main overlay animation
      await _mainController.forward();
      
      if (_isDisposed) return;
      
      // Start stats animation
      await _statsController.forward();
      
      if (_isDisposed) return;
      
      // Start button animation
      await _buttonController.forward();
      
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
      animation: Listenable.merge([
        _fadeAnimation,
        _scaleAnimation,
        _slideAnimation,
        _achievementSlideAnimation,
        _statsRevealAnimation,
        _buttonStaggerAnimation,
        _sparkleRotation,
      ]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: Colors.black.withValues(alpha:0.8),
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: Container(
                    width: ResponsiveUtils.wp(85),
                    constraints: BoxConstraints(
                      maxHeight: ResponsiveUtils.hp(75),
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.darkSurface,
                          AppColors.darkBackground,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha:0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header section
                        _buildHeader(),
                        
                        // Stats section
                        _buildStatsSection(),
                        
                        // Achievements section
                        if (widget.unlockedAchievements.isNotEmpty)
                          _buildAchievementsSection(),
                        
                        // Action buttons
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha:0.8),
            AppColors.secondary.withValues(alpha:0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Column(
        children: [
          // Sparkle decoration
          Transform.rotate(
            angle: _sparkleRotation.value,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha:0.8),
              size: 32,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Game Over title
          Text(
            'Game Over',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(6),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Subtitle based on performance
          Text(
            _getPerformanceMessage(),
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(3.5),
              color: Colors.white.withValues(alpha:0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Opacity(
      opacity: _statsRevealAnimation.value,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
        child: Column(
          children: [
            // Score display
            _buildScoreDisplay(),
            
            SizedBox(height: ResponsiveUtils.hp(2)),
            
            // Statistics grid
            if (widget.showDetailedStats)
              _buildStatisticsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Final Score',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(3),
              color: Colors.white.withValues(alpha:0.7),
            ),
          ),
          
          const SizedBox(height: 8),
          
          AnimatedCounter(
            count: widget.gameSession.currentScore,
            duration: const Duration(milliseconds: 1500),
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(8),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final stats = [
      {'label': 'Level', 'value': widget.gameSession.currentLevel.toString()},
      {'label': 'Lines', 'value': widget.gameSession.linesCleared.toString()},
      {'label': 'Time', 'value': _formatDuration(widget.gameSession.playTime)},
      {'label': 'Blocks', 'value': widget.gameSession.statistics.blocksPlaced.toString()},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat['value']!,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(4),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                stat['label']!,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(2.5),
                  color: Colors.white.withValues(alpha:0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection() {
    if (!_showingAchievements || widget.unlockedAchievements.isEmpty) {
      return const SizedBox();
    }

    final achievement = widget.unlockedAchievements[_currentAchievementIndex];

    return Transform.translate(
      offset: Offset(_achievementSlideAnimation.value * 300, 0),
      child: Container(
        margin: EdgeInsets.all(ResponsiveUtils.wp(4)),
        padding: EdgeInsets.all(ResponsiveUtils.wp(3)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withValues(alpha:0.3),
              AppColors.accent.withValues(alpha:0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha:0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Achievement Unlocked!',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(3.5),
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(3),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 4),
            
            Text(
              achievement.description,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(2.5),
                color: Colors.white.withValues(alpha:0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      child: Column(
        children: [
          // Primary actions row
          Row(
            children: [
              // Restart button
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, (1 - _buttonStaggerAnimation.value) * 50),
                  child: Opacity(
                    opacity: _buttonStaggerAnimation.value,
                    child: GradientButton(
                      text: 'Play Again',
                      onPressed: _handleRestart,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      height: ResponsiveUtils.hp(6),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: ResponsiveUtils.wp(2)),
              
              // Main menu button
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, (1 - _buttonStaggerAnimation.value) * 30),
                  child: Opacity(
                    opacity: _buttonStaggerAnimation.value * 0.8,
                    child: GradientButton(
                      text: 'Main Menu',
                      onPressed: _handleMainMenu,
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withValues(alpha:0.3),
                          Colors.grey.withValues(alpha:0.1),
                        ],
                      ),
                      height: ResponsiveUtils.hp(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.hp(1)),
          
          // Secondary actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Share button
              if (widget.onShare != null)
                Transform.translate(
                  offset: Offset((1 - _buttonStaggerAnimation.value) * -30, 0),
                  child: Opacity(
                    opacity: _buttonStaggerAnimation.value,
                    child: _buildIconButton(
                      icon: Icons.share,
                      label: 'Share',
                      onPressed: _handleShare,
                    ),
                  ),
                ),
              
              // Undo button (if available)
              if (widget.canUndo && widget.onUndo != null)
                Transform.translate(
                  offset: Offset(0, (1 - _buttonStaggerAnimation.value) * 20),
                  child: Opacity(
                    opacity: _buttonStaggerAnimation.value,
                    child: _buildIconButton(
                      icon: Icons.undo,
                      label: 'Undo',
                      onPressed: _handleUndo,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              
              // Watch ad button
              if (widget.onWatchAd != null)
                Transform.translate(
                  offset: Offset((1 - _buttonStaggerAnimation.value) * 30, 0),
                  child: Opacity(
                    opacity: _buttonStaggerAnimation.value,
                    child: _buildIconButton(
                      icon: Icons.play_arrow,
                      label: 'Bonus',
                      onPressed: _handleWatchAd,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (color ?? Colors.white).withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPerformanceMessage() {
    final score = widget.gameSession.currentScore;
    
    if (score > 10000) {
      return 'Incredible Performance!';
    } else if (score > 5000) {
      return 'Great Job!';
    } else if (score > 1000) {
      return 'Good Work!';
    } else {
      return 'Keep Practicing!';
    }
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
    if (!_isDisposed) {
      await _mainController.reverse();
      if (mounted) {
        context.read<UICubit>().hideGameOverOverlay();
      }
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