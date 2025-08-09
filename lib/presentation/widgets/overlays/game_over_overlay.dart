import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/core/theme/colors.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import '../common/gradient_button.dart';
import '../common/animated_counter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/game_constants.dart';
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
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  
  bool _showStats = false;
  bool _showAchievements = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
    AudioService.playSfx('game_over');
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
  }

  void _startAnimationSequence() async {
    await _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      _showStats = true;
    });
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (widget.unlockedAchievements.isNotEmpty) {
      setState(() {
        _showAchievements = true;
      });
    }
    
    _particleController.repeat();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          // Background particles
          _buildParticleBackground(),
          
          // Main content
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: EdgeInsets.all(ResponsiveUtils.wp(4)),
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.wp(90),
                  maxHeight: ResponsiveUtils.hp(80),
                ),
                decoration: _buildOverlayDecoration(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(ResponsiveUtils.wp(6)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      SizedBox(height: ResponsiveUtils.hp(2)),
                      _buildScoreSection(),
                      if (_showStats) ...[
                        SizedBox(height: ResponsiveUtils.hp(2)),
                        _buildStatsSection(),
                      ],
                      if (_showAchievements && widget.unlockedAchievements.isNotEmpty) ...[
                        SizedBox(height: ResponsiveUtils.hp(2)),
                        _buildAchievementsSection(),
                      ],
                      SizedBox(height: ResponsiveUtils.hp(3)),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particleAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  BoxDecoration _buildOverlayDecoration() {
    return BoxDecoration(
      gradient: AppTheme.surfaceGradient,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppTheme.primaryColor.withOpacity(0.3),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppTheme.primaryColor.withOpacity(0.1),
          blurRadius: 30,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.wp(4),
            vertical: ResponsiveUtils.hp(1),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.8),
                Colors.orange.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '🎮 GAME OVER 🎮',
            style: AppTheme.headlineStyle.copyWith(
              fontSize: ResponsiveUtils.sp(24),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(1)),
        Text(
          _getGameOverMessage(),
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(14),
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScoreSection() {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.3),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'FINAL SCORE',
            style: AppTheme.titleStyle.copyWith(
              fontSize: ResponsiveUtils.sp(16),
              color: Colors.white70,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(1)),
          ScoreCounter(
            score: widget.gameSession.score,
            fontSize: ResponsiveUtils.sp(32),
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: ResponsiveUtils.hp(1)),
          _buildScoreComparison(),
        ],
      ),
    );
  }

  Widget _buildScoreComparison() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        final isNewBest = widget.gameSession.score > state.stats.bestScore;
        
        if (isNewBest) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.wp(3),
              vertical: ResponsiveUtils.hp(0.5),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successColor,
                  AppTheme.successColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'NEW BEST SCORE!',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Text(
            'Best: ${_formatNumber(state.stats.bestScore)}',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: ResponsiveUtils.sp(12),
              color: Colors.white60,
            ),
          );
        }
      },
    );
  }

  Widget _buildStatsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              'GAME STATISTICS',
              style: AppTheme.titleStyle.copyWith(
                fontSize: ResponsiveUtils.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.hp(2)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Level',
                  widget.gameSession.level.toString(),
                  Icons.trending_up_rounded,
                  AppTheme.accentColor,
                ),
                _buildStatItem(
                  'Lines',
                  widget.gameSession.linesCleared.toString(),
                  Icons.linear_scale_rounded,
                  AppTheme.primaryColor,
                ),
                _buildStatItem(
                  'Time',
                  _formatTime(widget.gameSession.playTime),
                  Icons.timer_rounded,
                  AppTheme.secondaryColor,
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
                  Colors.orange,
                ),
                _buildStatItem(
                  'Blocks',
                  widget.gameSession.blocksPlaced.toString(),
                  Icons.apps_rounded,
                  AppTheme.primaryColor,
                ),
                _buildStatItem(
                  'Coins',
                  '+${widget.gameSession.coinsEarned}',
                  Icons.monetization_on_rounded,
                  AppTheme.secondaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: ResponsiveUtils.sp(20),
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(0.5)),
        Text(
          value,
          style: AppTheme.titleStyle.copyWith(
            fontSize: ResponsiveUtils.sp(16),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(10),
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.successColor.withOpacity(0.3),
              AppTheme.successColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.successColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.successColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'ACHIEVEMENTS UNLOCKED!',
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(16),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.hp(1)),
            ...widget.unlockedAchievements.take(3).map((achievement) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: ResponsiveUtils.hp(0.5)),
                padding: EdgeInsets.all(ResponsiveUtils.wp(2)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      achievement.icon,
                      style: TextStyle(fontSize: ResponsiveUtils.sp(20)),
                    ),
                    SizedBox(width: ResponsiveUtils.wp(2)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: ResponsiveUtils.sp(12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            achievement.description,
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: ResponsiveUtils.sp(10),
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (achievement.coinReward > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.wp(2),
                          vertical: ResponsiveUtils.hp(0.5),
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              color: AppTheme.secondaryColor,
                              size: ResponsiveUtils.sp(12),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${achievement.coinReward}',
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: ResponsiveUtils.sp(10),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Undo button (if available)
        if (widget.canUndo && widget.onUndo != null) ...[
          GradientButton.secondary(
            onPressed: () {
              HapticFeedback.mediumImpact();
              AudioService.playSfx('button_click');
              widget.onUndo?.call();
            },
            width: double.infinity,
            leadingIcon: Icons.undo_rounded,
            child: Text(
              'UNDO LAST MOVE',
              style: AppTheme.buttonStyle.copyWith(
                fontSize: ResponsiveUtils.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(1.5)),
        ],
        
        // Primary action
        GradientButton.primary(
          onPressed: () {
            HapticFeedback.mediumImpact();
            AudioService.playSfx('button_click');
            widget.onRestart?.call();
          },
          width: double.infinity,
          leadingIcon: Icons.refresh_rounded,
          child: Text(
            'PLAY AGAIN',
            style: AppTheme.buttonStyle.copyWith(
              fontSize: ResponsiveUtils.sp(18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.hp(1.5)),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: GradientButton.outlined(
                onPressed: () {
                  AudioService.playSfx('button_click');
                  widget.onShare?.call();
                },
                leadingIcon: Icons.share_rounded,
                child: Text(
                  'SHARE',
                  style: AppTheme.buttonStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (widget.onWatchAd != null) ...[
              SizedBox(width: ResponsiveUtils.wp(2)),
              Expanded(
                child: GradientButton(
                  onPressed: () {
                    AudioService.playSfx('button_click');
                    widget.onWatchAd?.call();
                  },
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                  ),
                  leadingIcon: Icons.play_circle_outline_rounded,
                  child: Text(
                    'WATCH AD',
                    style: AppTheme.buttonStyle.copyWith(
                      fontSize: ResponsiveUtils.sp(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.hp(1)),
        
        // Menu button
        TextButton(
          onPressed: () {
            AudioService.playSfx('button_click');
            widget.onMainMenu?.call();
          },
          child: Text(
            'Back to Menu',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: ResponsiveUtils.sp(14),
              color: Colors.white60,
            ),
          ),
        ),
      ],
    );
  }

  String _getGameOverMessage() {
    final score = widget.gameSession.score;
    
    if (score > 10000) {
      return 'Incredible performance! You\'re a puzzle master! 🏆';
    } else if (score > 5000) {
      return 'Excellent game! You\'re getting really good at this! 🌟';
    } else if (score > 1000) {
      return 'Great job! Keep practicing to reach even higher scores! 💪';
    } else {
      return 'Good effort! Every game makes you better! 🎯';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for background particles
class ParticlePainter extends CustomPainter {
  final double animationValue;
  
  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    for (int i = 0; i < 50; i++) {
      final progress = (animationValue + i * 0.02) % 1.0;
      final x = (i * 137.5) % size.width;
      final y = size.height * progress;
      final alpha = (1.0 - progress * progress) * 0.7;
      
      paint.color = AppColors.blockColors[i % AppColors.blockColors.length]
          .withOpacity(alpha);
      
      canvas.drawCircle(
        Offset(x, y),
        2 + (progress * 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}