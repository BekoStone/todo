import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'dart:math' as math;
import '../common/gradient_button.dart';
import '../common/animated_counter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/audio_service.dart';

class AchievementOverlay extends StatefulWidget {
  /// The achievement to display
  final Achievement achievement;
  
  /// Whether the achievement is newly unlocked
  final bool isNewlyUnlocked;
  
  /// Callback when the overlay is dismissed
  final VoidCallback? onDismiss;
  
  /// Callback when the reward is claimed
  final VoidCallback? onClaim;
  
  /// Whether to show detailed information
  final bool showDetails;

  const AchievementOverlay({
    super.key,
    required this.achievement,
    this.isNewlyUnlocked = false,
    this.onDismiss,
    this.onClaim,
    this.showDetails = true,
  });

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _showReward = false;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
    
    if (widget.isNewlyUnlocked) {
      AudioService.playSfx('achievement_unlocked');
      HapticFeedback.mediumImpact();
    }
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _particleAnimation = CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    await _mainController.forward();
    
    if (widget.isNewlyUnlocked) {
      _particleController.repeat();
      _pulseController.repeat(reverse: true);
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _showReward = true;
      });
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha:0.85),
      child: Stack(
        children: [
          // Particle background for newly unlocked achievements
          if (widget.isNewlyUnlocked)
            _buildParticleBackground(),
          
          // Main content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: EdgeInsets.all(ResponsiveUtils.wp(4)),
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.wp(90),
                  maxHeight: ResponsiveUtils.hp(80),
                ),
                decoration: _buildOverlayDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(ResponsiveUtils.wp(6)),
                        child: Column(
                          children: [
                            _buildAchievementIcon(),
                            SizedBox(height: ResponsiveUtils.hp(2)),
                            _buildAchievementInfo(),
                            if (widget.showDetails) ...[
                              SizedBox(height: ResponsiveUtils.hp(2)),
                              _buildProgressSection(),
                            ],
                            if (_showReward && widget.achievement.coinReward > 0) ...[
                              SizedBox(height: ResponsiveUtils.hp(2)),
                              _buildRewardSection(),
                            ],
                            SizedBox(height: ResponsiveUtils.hp(3)),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCloseButton(),
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
          painter: AchievementParticlePainter(
            _particleAnimation.value,
            widget.achievement.rarity.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  BoxDecoration _buildOverlayDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.surfaceColor,
          AppTheme.surfaceColor.withValues(alpha:0.95),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: widget.achievement.rarity.color.withValues(alpha:0.5),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: widget.achievement.rarity.color.withValues(alpha:0.2),
          blurRadius: 30,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.achievement.rarity.color.withValues(alpha:0.8),
            widget.achievement.rarity.color.withValues(alpha:0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.isNewlyUnlocked ? 'ACHIEVEMENT UNLOCKED!' : 'ACHIEVEMENT',
            style: AppTheme.headlineStyle.copyWith(
              fontSize: ResponsiveUtils.sp(16),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.wp(3),
              vertical: ResponsiveUtils.hp(0.5),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.achievement.rarity.displayName.toUpperCase(),
              style: AppTheme.bodyStyle.copyWith(
                fontSize: ResponsiveUtils.sp(12),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isNewlyUnlocked ? _pulseAnimation.value : 1.0,
          child: Container(
            width: ResponsiveUtils.wp(24),
            height: ResponsiveUtils.wp(24),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  widget.achievement.rarity.color,
                  widget.achievement.rarity.color.withValues(alpha:0.7),
                  widget.achievement.rarity.color.withValues(alpha:0.3),
                ],
                stops: const [0.3, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(ResponsiveUtils.wp(12)),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.achievement.rarity.color.withValues(alpha:0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.achievement.icon,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(48),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementInfo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            widget.achievement.title,
            style: AppTheme.headlineStyle.copyWith(
              fontSize: ResponsiveUtils.sp(20),
              fontWeight: FontWeight.bold,
              color: widget.achievement.rarity.color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveUtils.hp(1)),
          Text(
            widget.achievement.description,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: ResponsiveUtils.sp(14),
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.achievement.isUnlocked) ...[
            SizedBox(height: ResponsiveUtils.hp(1)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.wp(3),
                vertical: ResponsiveUtils.hp(0.5),
              ),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.successColor.withValues(alpha:0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successColor,
                    size: ResponsiveUtils.sp(16),
                  ),
                  SizedBox(width: ResponsiveUtils.wp(1)),
                  Text(
                    'Completed',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: ResponsiveUtils.sp(12),
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    if (!widget.showDetails) return const SizedBox.shrink();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha:0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    AnimatedCounter(
                      value: widget.achievement.currentProgress,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: ResponsiveUtils.sp(14),
                        fontWeight: FontWeight.bold,
                        color: widget.achievement.rarity.color,
                      ),
                    ),
                    Text(
                      ' / ${widget.achievement.maxProgress}',
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: ResponsiveUtils.sp(14),
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.hp(1)),
            LinearProgressIndicator(
              value: widget.achievement.progressPercentage,
              backgroundColor: Colors.white.withValues(alpha:0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.achievement.rarity.color,
              ),
              minHeight: 6,
            ),
            SizedBox(height: ResponsiveUtils.hp(0.5)),
            Text(
              '${(widget.achievement.progressPercentage * 100).toInt()}% Complete',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: ResponsiveUtils.sp(12),
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.secondaryColor.withValues(alpha:0.3),
              AppTheme.secondaryColor.withValues(alpha:0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha:0.5),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: AppTheme.secondaryColor,
                  size: ResponsiveUtils.sp(20),
                ),
                SizedBox(width: ResponsiveUtils.wp(2)),
                Text(
                  'REWARD',
                  style: AppTheme.titleStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(16),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.hp(1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  color: AppTheme.secondaryColor,
                  size: ResponsiveUtils.sp(24),
                ),
                SizedBox(width: ResponsiveUtils.wp(2)),
                CoinCounter(
                  coins: widget.achievement.coinReward,
                  fontSize: ResponsiveUtils.sp(20),
                  color: AppTheme.secondaryColor,
                  showIcon: false,
                ),
                SizedBox(width: ResponsiveUtils.wp(1)),
                Text(
                  'Coins',
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(16),
                    color: AppTheme.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
          // Claim button (if newly unlocked and has reward)
          if (widget.isNewlyUnlocked && 
              widget.achievement.coinReward > 0 && 
              !_claimed) ...[
            GradientButton(
              onPressed: _claimReward,
              gradient: LinearGradient(
                colors: [
                  AppTheme.successColor,
                  AppTheme.successColor.withValues(alpha:0.8),
                ],
              ),
              width: double.infinity,
              leadingIcon: Icons.redeem_rounded,
              child: Text(
                'CLAIM REWARD',
                style: AppTheme.buttonStyle.copyWith(
                  fontSize: ResponsiveUtils.sp(16),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.hp(1.5)),
          ],
          
          // Close button
          GradientButton.outlined(
            onPressed: _closeOverlay,
            width: double.infinity,
            child: Text(
              widget.isNewlyUnlocked ? 'AWESOME!' : 'CLOSE',
              style: AppTheme.buttonStyle.copyWith(
                fontSize: ResponsiveUtils.sp(16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        onPressed: _closeOverlay,
        icon: Icon(
          Icons.close_rounded,
          color: Colors.white,
          size: ResponsiveUtils.sp(20),
        ),
      ),
    );
  }

  void _claimReward() {
    setState(() {
      _claimed = true;
    });
    
    HapticFeedback.lightImpact();
    AudioService.playSfx('coin_collect');
    
    widget.onClaim?.call();
    
    // Show claim effect
    _showClaimEffect();
  }

  void _showClaimEffect() {
    // Create a brief animation effect
    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(controller);
    
    controller.forward().then((_) {
      controller.reverse();
      controller.dispose();
    });
  }

  void _closeOverlay() {
    AudioService.playSfx('button_click');
    widget.onDismiss?.call();
    Navigator.of(context).pop();
  }
}

/// Custom painter for achievement particles
class AchievementParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  
  AchievementParticlePainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final progress = (animationValue + i * 0.03) % 1.0;
      final angle = (i * 12.0) * (3.14159 / 180);
      final radius = size.width * 0.3 * progress;
      
      final x = size.width * 0.5 + radius * math.cos(angle);
      final y = size.height * 0.5 + radius * math.sin(angle);
      
      final alpha = (1.0 - progress) * 0.8;
      final particleSize = 3 + (progress * 5);
      
      paint.color = color.withValues(alpha:alpha);
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(AchievementParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

/// Compact achievement notification for in-game display
class AchievementNotification extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onTap;
  final Duration displayDuration;

  const AchievementNotification({
    super.key,
    required this.achievement,
    this.onTap,
    this.displayDuration = const Duration(seconds: 3),
  });

  @override
  State<AchievementNotification> createState() => _AchievementNotificationState();
}

class _AchievementNotificationState extends State<AchievementNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
    
    // Auto dismiss after duration
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              constraints: BoxConstraints(maxWidth: ResponsiveUtils.wp(80)),
              padding: EdgeInsets.all(ResponsiveUtils.wp(3)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.achievement.rarity.color.withValues(alpha:0.9),
                    widget.achievement.rarity.color.withValues(alpha:0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.achievement.icon,
                    style: TextStyle(fontSize: ResponsiveUtils.sp(20)),
                  ),
                  SizedBox(width: ResponsiveUtils.wp(2)),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Achievement Unlocked!',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: ResponsiveUtils.sp(10),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.achievement.title,
                          style: AppTheme.titleStyle.copyWith(
                            fontSize: ResponsiveUtils.sp(12),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}