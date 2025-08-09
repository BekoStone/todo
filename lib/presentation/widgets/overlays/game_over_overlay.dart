import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/core/theme/colors.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import '../common/gradient_button.dart';
import '../common/animated_counter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/audio_service.dart';

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
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _scoreController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _scoreAnimation;
  
  bool _showStats = false;
  bool _showAchievements = false;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    );

    _scoreAnimation = CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    );
  }

  void _startAnimationSequence() async {
    // Play game over sound
    AudioService.playSfx('game_over');
    
    // Start main slide animation
    await _slideController.forward();
    
    // Show stats with delay
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _showStats = true;
    });
    _fadeController.forward();
    _scoreController.forward();
    
    // Show achievements if any
    if (widget.unlockedAchievements.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _showAchievements = true;
      });
    }
    
    // Show action buttons
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _showActions = true;
    });
    
    // Start particle animation
    _particleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background overlay
          _buildBackground(),
          
          // Floating particles
          _buildParticles(),
          
          // Main content
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3 * _fadeAnimation.value),
                Colors.black.withOpacity(0.8 * _fadeAnimation.value),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: ParticlesPainter(_particleAnimation.value),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ResponsiveUtils.wp(5)),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              SizedBox(height: ResponsiveUtils.hp(3)),
              
              // Game stats
              if (_showStats) _buildGameStats(),
              
              SizedBox(height: ResponsiveUtils.hp(3)),
              
              // Achievements
              if (_showAchievements) _buildAchievements(),
              
              SizedBox(height: ResponsiveUtils.hp(3)),
              
              // Action buttons
              if (_showActions) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(6)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkSurface.withOpacity(0.9),
            AppColors.darkSurfaceVariant.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Game Over icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.error, AppColors.warning],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.flag_rounded,
              color: Colors.white,
              size: ResponsiveUtils.sp(40),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(2)),
          
          // Game Over title
          Text(
            'Game Over',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(28),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(1)),
          
          // Performance message
          Text(
            _getPerformanceMessage(),
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(16),
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.wp(5)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Final Statistics',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(20),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            SizedBox(height: ResponsiveUtils.hp(2)),
            
            // Score (prominent)
            _buildScoreDisplay(),
            
            SizedBox(height: ResponsiveUtils.hp(3)),
            
            // Other stats grid
            _buildStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.warning, AppColors.info],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_rounded,
            color: Colors.white,
            size: ResponsiveUtils.sp(24),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(1)),
          
          Text(
            'Final Score',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(14),
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return FancyAnimatedCounter(
                value: (widget.gameSession.currentScore * _scoreAnimation.value).round(),
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(32),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                highlightColor: AppColors.warning,
                showPlusAnimation: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Level',
              widget.gameSession.currentLevel.toString(),
              Icons.trending_up_rounded,
              AppColors.success,
            ),
            _buildStatItem(
              'Lines',
              widget.gameSession.linesCleared.toString(),
              Icons.linear_scale_rounded,
              AppColors.primary,
            ),
            _buildStatItem(
              'Time',
              _formatTime(widget.gameSession.actualPlayTime),
              Icons.timer_rounded,
              AppColors.secondary,
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.hp(2)),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Max Combo',
              widget.gameSession.maxCombo.toString(),
              Icons.local_fire_department_rounded,
              AppColors.error,
            ),
            _buildStatItem(
              'Blocks',
              widget.gameSession.statistics.blocksPlaced.toString(),
              Icons.apps_rounded,
              AppColors.info,
            ),
            _buildStatItem(
              'Coins',
              '+${_calculateCoinsEarned()}',
              Icons.monetization_on_rounded,
              AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveUtils.sp(24),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(1)),
          
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(16),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(12),
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withOpacity(0.2),
              AppColors.info.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.warning,
                  size: ResponsiveUtils.sp(24),
                ),
                
                SizedBox(width: ResponsiveUtils.wp(2)),
                
                Text(
                  'Achievements Unlocked!',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: ResponsiveUtils.hp(2)),
            
            ...widget.unlockedAchievements.map((achievement) {
              return Container(
                margin: EdgeInsets.only(bottom: ResponsiveUtils.hp(1)),
                padding: EdgeInsets.all(ResponsiveUtils.wp(3)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                        size: ResponsiveUtils.sp(16),
                      ),
                    ),
                    
                    SizedBox(width: ResponsiveUtils.wp(3)),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.sp(14),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.sp(12),
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (achievement.coinReward > 0)
                      Text(
                        '+${achievement.coinReward}',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.sp(14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Undo button (if available)
          if (widget.canUndo && widget.onUndo != null) ...[
            GradientButton.secondary(
              text: 'Undo Last Move',
              icon: Icons.undo_rounded,
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onUndo?.call();
              },
              width: double.infinity,
              height: ResponsiveUtils.hp(6),
            ),
            
            SizedBox(height: ResponsiveUtils.hp(2)),
          ],
          
          // Play Again button
          GradientButton.primary(
            text: 'Play Again',
            icon: Icons.refresh_rounded,
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onRestart?.call();
            },
            width: double.infinity,
            height: ResponsiveUtils.hp(6),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(2)),
          
          // Secondary actions
          Row(
            children: [
              // Share button
              Expanded(
                child: GradientButton(
                  text: 'Share',
                  icon: Icons.share_rounded,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onShare?.call();
                  },
                  backgroundColor: AppColors.info.withOpacity(0.2),
                  textColor: AppColors.info,
                  height: ResponsiveUtils.hp(5),
                ),
              ),
              
              SizedBox(width: ResponsiveUtils.wp(3)),
              
              // Main menu button
              Expanded(
                child: GradientButton(
                  text: 'Menu',
                  icon: Icons.home_rounded,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onMainMenu?.call();
                  },
                  backgroundColor: Colors.white.withOpacity(0.1),
                  textColor: Colors.white,
                  height: ResponsiveUtils.hp(5),
                ),
              ),
            ],
          ),
          
          // Watch ad button (if available)
          if (widget.onWatchAd != null) ...[
            SizedBox(height: ResponsiveUtils.hp(1.5)),
            
            GradientButton.warning(
              text: 'Watch Ad for Extra Coins',
              icon: Icons.play_circle_filled_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onWatchAd?.call();
              },
              width: double.infinity,
              height: ResponsiveUtils.hp(5),
            ),
          ],
        ],
      ),
    );
  }

  String _getPerformanceMessage() {
    final score = widget.gameSession.currentScore;
    
    if (score >= 50000) {
      return 'Legendary Performance! 🏆';
    } else if (score >= 25000) {
      return 'Outstanding Game! ⭐';
    } else if (score >= 10000) {
      return 'Great Job! 🎉';
    } else if (score >= 5000) {
      return 'Good Effort! 👍';
    } else {
      return 'Keep Practicing! 💪';
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }

  int _calculateCoinsEarned() {
    // Simple coin calculation based on score and achievements
    final baseCoins = (widget.gameSession.currentScore / 100).floor();
    final achievementCoins = widget.unlockedAchievements
        .fold<int>(0, (sum, achievement) => sum + achievement.coinReward);
    
    return baseCoins + achievementCoins;
  }
}

/// Custom painter for floating particles effect
class ParticlesPainter extends CustomPainter {
  final double progress;

  ParticlesPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final x = (i * 47 % size.width.toInt()).toDouble();
      final y = size.height * (1 - progress) + (i * 23 % 100);
      final opacity = (1 - progress * 0.5) * (0.3 + (i % 3) * 0.2);
      
      paint.color = AppColors.particleColors[i % AppColors.particleColors.length]
          .withOpacity(opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        2 + (i % 3).toDouble(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}