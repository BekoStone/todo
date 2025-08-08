import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import '../common/gradient_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/audio_service.dart';

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
  
  /// Whether the overlay can be dismissed by tapping outside
  final bool dismissible;

  const PauseOverlay({
    super.key,
    required this.gameSession,
    this.onResume,
    this.onRestart,
    this.onMainMenu,
    this.onSettings,
    this.dismissible = true,
  });

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _iconController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _iconAnimation;
  
  bool _showQuickStats = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
    AudioService.playSfx('pause');
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimationSequence() async {
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    
    setState(() {
      _showQuickStats = true;
    });
    
    _fadeController.forward();
    _iconController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.dismissible ? _resumeGame : null,
      child: Material(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.all(ResponsiveUtils.wp(6)),
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.wp(85),
                maxHeight: ResponsiveUtils.hp(70),
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
                          if (_showQuickStats) _buildQuickStats(),
                          SizedBox(height: ResponsiveUtils.hp(3)),
                          _buildActionButtons(),
                          SizedBox(height: ResponsiveUtils.hp(2)),
                          _buildSettingsToggle(),
                        ],
                      ),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.wp(4)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.primaryColor.withOpacity(0.6),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _iconAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_iconAnimation.value * 0.1),
                child: Icon(
                  Icons.pause_circle_filled_rounded,
                  color: Colors.white,
                  size: ResponsiveUtils.sp(32),
                ),
              );
            },
          ),
          SizedBox(width: ResponsiveUtils.wp(3)),
          Text(
            'GAME PAUSED',
            style: AppTheme.headlineStyle.copyWith(
              fontSize: ResponsiveUtils.sp(24),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
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
              'Current Progress',
              style: AppTheme.titleStyle.copyWith(
                fontSize: ResponsiveUtils.sp(16),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: ResponsiveUtils.hp(2)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Score',
                  _formatNumber(widget.gameSession.score),
                  Icons.emoji_events_rounded,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  'Level',
                  widget.gameSession.level.toString(),
                  Icons.trending_up_rounded,
                  AppTheme.accentColor,
                ),
                _buildStatCard(
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
                _buildStatCard(
                  'Lines',
                  widget.gameSession.linesCleared.toString(),
                  Icons.linear_scale_rounded,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  'Combo',
                  'x${widget.gameSession.currentCombo}',
                  Icons.local_fire_department_rounded,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Blocks',
                  widget.gameSession.blocksPlaced.toString(),
                  Icons.apps_rounded,
                  AppTheme.accentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(3),
        vertical: ResponsiveUtils.hp(1),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: ResponsiveUtils.sp(18),
          ),
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          Text(
            value,
            style: AppTheme.titleStyle.copyWith(
              fontSize: ResponsiveUtils.sp(14),
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
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Resume button
        GradientButton.primary(
          onPressed: _resumeGame,
          width: double.infinity,
          leadingIcon: Icons.play_arrow_rounded,
          child: Text(
            'RESUME GAME',
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
                  _showRestartConfirmation();
                },
                leadingIcon: Icons.refresh_rounded,
                child: Text(
                  'RESTART',
                  style: AppTheme.buttonStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.wp(3)),
            Expanded(
              child: GradientButton.outlined(
                onPressed: () {
                  AudioService.playSfx('button_click');
                  widget.onSettings?.call();
                },
                leadingIcon: Icons.settings_rounded,
                child: Text(
                  'SETTINGS',
                  style: AppTheme.buttonStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.hp(1)),
        
        // Menu button
        TextButton(
          onPressed: () {
            AudioService.playSfx('button_click');
            _showMenuConfirmation();
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

  Widget _buildSettingsToggle() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.all(ResponsiveUtils.wp(3)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Quick Settings',
                style: AppTheme.titleStyle.copyWith(
                  fontSize: ResponsiveUtils.sp(14),
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: ResponsiveUtils.hp(1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickToggle(
                    'Sound',
                    Icons.volume_up_rounded,
                    state.soundEnabled,
                    () => context.read<UICubit>().toggleSound(),
                  ),
                  _buildQuickToggle(
                    'Music',
                    Icons.music_note_rounded,
                    state.musicEnabled,
                    () => context.read<UICubit>().toggleMusic(),
                  ),
                  _buildQuickToggle(
                    'Vibration',
                    Icons.vibration_rounded,
                    state.vibrationEnabled,
                    () => context.read<UICubit>().toggleVibration(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickToggle(
    String label,
    IconData icon,
    bool value,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.wp(2)),
        decoration: BoxDecoration(
          color: value 
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value 
                ? AppTheme.primaryColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: value ? AppTheme.primaryColor : Colors.white54,
              size: ResponsiveUtils.sp(20),
            ),
            SizedBox(height: ResponsiveUtils.hp(0.5)),
            Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: ResponsiveUtils.sp(10),
                color: value ? AppTheme.primaryColor : Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resumeGame() {
    HapticFeedback.mediumImpact();
    AudioService.playSfx('resume');
    widget.onResume?.call();
  }

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Colors.orange,
              size: ResponsiveUtils.sp(24),
            ),
            SizedBox(width: ResponsiveUtils.wp(2)),
            Text(
              'Restart Game?',
              style: AppTheme.titleStyle.copyWith(
                fontSize: ResponsiveUtils.sp(18),
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: Text(
          'This will restart your current game and you\'ll lose all progress. Are you sure?',
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTheme.bodyStyle.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          GradientButton.danger(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRestart?.call();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showMenuConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.home_rounded,
              color: Colors.red,
              size: ResponsiveUtils.sp(24),
            ),
            SizedBox(width: ResponsiveUtils.wp(2)),
            Text(
              'Exit to Menu?',
              style: AppTheme.titleStyle.copyWith(
                fontSize: ResponsiveUtils.sp(18),
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'This will end your current game and return to the main menu. Your progress will be lost.',
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTheme.bodyStyle.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          GradientButton.danger(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onMainMenu?.call();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
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