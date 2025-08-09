import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import '../common/gradient_button.dart';
import '../common/animated_counter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/responsive_utils.dart';

class PauseOverlay extends StatefulWidget {
  /// The current game session
  final GameSession gameSession;
  
  /// Callback when resume is requested
  final VoidCallback? onResume;
  
  /// Callback when restart is requested
  final VoidCallback? onRestart;
  
  /// Callback when main menu is requested
  final VoidCallback? onMainMenu;
  
  /// Callback when settings is requested
  final VoidCallback? onSettings;

  const PauseOverlay({
    super.key,
    required this.gameSession,
    this.onResume,
    this.onRestart,
    this.onMainMenu,
    this.onSettings,
  });

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _slideController.forward();
      }
    });
    
    // Start pulse animation for resume button
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred background
          _buildBlurredBackground(),
          
          // Main overlay content
          _buildOverlayContent(),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value * 0.8,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
          ),
        );
      },
    );
  }

  Widget _buildOverlayContent() {
    return SafeArea(
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.wp(5),
            ),
            padding: EdgeInsets.all(ResponsiveUtils.wp(6)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.darkSurface.withOpacity(0.95),
                  AppColors.darkSurfaceVariant.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pause icon and title
                _buildHeader(),
                
                SizedBox(height: ResponsiveUtils.hp(3)),
                
                // Game stats
                _buildGameStats(),
                
                SizedBox(height: ResponsiveUtils.hp(4)),
                
                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Pause icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.pause_rounded,
            color: Colors.white,
            size: ResponsiveUtils.sp(32),
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.hp(2)),
        
        // Title
        Text(
          'Game Paused',
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(24),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.hp(1)),
        
        // Subtitle
        Text(
          'Take a break and come back when ready',
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(14),
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGameStats() {
    return Container(
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
            'Current Progress',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(16),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(2)),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Score',
                widget.gameSession.currentScore,
                Icons.star_rounded,
                AppColors.warning,
              ),
              _buildStatItem(
                'Level',
                widget.gameSession.currentLevel,
                Icons.trending_up_rounded,
                AppColors.success,
              ),
              _buildStatItem(
                'Lines',
                widget.gameSession.linesCleared,
                Icons.horizontal_rule_rounded,
                AppColors.info,
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveUtils.hp(2)),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Combo',
                widget.gameSession.comboCount,
                Icons.local_fire_department_rounded,
                AppColors.error,
              ),
              _buildStatItem(
                'Time',
                _formatDuration(widget.gameSession.actualPlayTime),
                Icons.timer_rounded,
                AppColors.primary,
              ),
              _buildStatItem(
                'Blocks',
                widget.gameSession.statistics.blocksPlaced,
                Icons.apps_rounded,
                AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, dynamic value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveUtils.sp(20),
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.hp(0.5)),
        
        value is int 
            ? AnimatedCounter(
                value: value,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : Text(
                value.toString(),
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
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Resume button (primary action)
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GradientButton.primary(
                text: 'Resume Game',
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onResume?.call();
                },
                width: double.infinity,
                height: ResponsiveUtils.hp(6),
              ),
            );
          },
        ),
        
        SizedBox(height: ResponsiveUtils.hp(2)),
        
        // Secondary actions
        Row(
          children: [
            // Settings button
            Expanded(
              child: GradientButton(
                text: 'Settings',
                icon: Icons.settings_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onSettings?.call();
                },
                backgroundColor: Colors.white.withOpacity(0.1),
                textColor: Colors.white,
                height: ResponsiveUtils.hp(5),
              ),
            ),
            
            SizedBox(width: ResponsiveUtils.wp(3)),
            
            // Restart button
            Expanded(
              child: GradientButton(
                text: 'Restart',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showRestartConfirmation();
                },
                backgroundColor: AppColors.warning.withOpacity(0.2),
                textColor: AppColors.warning,
                height: ResponsiveUtils.hp(5),
              ),
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.hp(1.5)),
        
        // Main menu button
        GradientButton(
          text: 'Main Menu',
          icon: Icons.home_rounded,
          onPressed: () {
            HapticFeedback.lightImpact();
            _showMainMenuConfirmation();
          },
          backgroundColor: AppColors.error.withOpacity(0.2),
          textColor: AppColors.error,
          width: double.infinity,
          height: ResponsiveUtils.hp(5),
        ),
      ],
    );
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Restart Game',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to restart? All current progress will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRestart?.call();
            },
            child: const Text(
              'Restart',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  void _showMainMenuConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Exit to Main Menu',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your progress will be automatically saved. Are you sure you want to exit?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onMainMenu?.call();
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}