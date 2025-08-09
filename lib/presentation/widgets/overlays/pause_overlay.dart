import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import '../common/gradient_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/audio_service.dart';
import '../../../injection_container.dart';

/// PauseOverlay provides game pause functionality with settings access.
/// Optimized for performance with proper memory management and efficient animations.
/// Follows Clean Architecture with proper state management integration.
class PauseOverlay extends StatefulWidget {
  /// Callback when resume is requested
  final VoidCallback? onResume;
  
  /// Callback when restart is requested
  final VoidCallback? onRestart;
  
  /// Callback when main menu is requested
  final VoidCallback? onMainMenu;
  
  /// Callback when settings are requested
  final VoidCallback? onSettings;
  
  /// Whether to show game statistics
  final bool showStatistics;
  
  /// Current game statistics data
  final Map<String, dynamic>? gameStats;

  const PauseOverlay({
    super.key,
    this.onResume,
    this.onRestart,
    this.onMainMenu,
    this.onSettings,
    this.showStatistics = true,
    this.gameStats,
  });

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with SingleTickerProviderStateMixin {
  
  // Animation controller for overlay entrance/exit
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Audio service for sound effects
  late AudioService _audioService;
  
  // State tracking
  bool _isDisposed = false;
  bool _showConfirmation = false;
  String _confirmationAction = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeDependencies();
    _startEntranceAnimation();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _initializeDependencies() {
    _audioService = getIt<AudioService>();
  }

  void _startEntranceAnimation() {
    if (!_isDisposed) {
      _animationController.forward();
    }
  }

  Future<void> _startExitAnimation() async {
    if (!_isDisposed) {
      await _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: Colors.black.withOpacity(0.7 * _fadeAnimation.value),
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: _showConfirmation 
                      ? _buildConfirmationDialog()
                      : _buildMainPauseMenu(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainPauseMenu() {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(10),
        vertical: ResponsiveUtils.hp(15),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            SizedBox(height: ResponsiveUtils.hp(3)),
            if (widget.showStatistics) ...[
              _buildGameStatistics(),
              SizedBox(height: ResponsiveUtils.hp(3)),
            ],
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.pause_circle_filled,
          size: ResponsiveUtils.sp(48),
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: ResponsiveUtils.hp(1)),
        Text(
          'Game Paused',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(0.5)),
        Text(
          'Take a break or resume when ready',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGameStatistics() {
    if (widget.gameStats == null) return const SizedBox.shrink();

    final stats = widget.gameStats!;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        children: [
          Text(
            'Current Session',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Score',
                '${stats['score'] ?? 0}',
                Icons.stars,
              ),
              _buildStatItem(
                'Level',
                '${stats['level'] ?? 1}',
                Icons.trending_up,
              ),
              _buildStatItem(
                'Lines',
                '${stats['linesCleared'] ?? 0}',
                Icons.horizontal_rule,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: ResponsiveUtils.sp(20),
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: ResponsiveUtils.hp(0.5)),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Resume button (primary action)
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Resume Game',
            icon: Icons.play_arrow_rounded,
            onPressed: _handleResume,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            height: ResponsiveUtils.getButtonSize(),
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.hp(1.5)),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Settings',
                icon: Icons.settings_rounded,
                onPressed: _handleSettings,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                height: ResponsiveUtils.getButtonSize() * 0.8,
              ),
            ),
            SizedBox(width: ResponsiveUtils.wp(2)),
            Expanded(
              child: GradientButton(
                text: 'Restart',
                icon: Icons.refresh_rounded,
                onPressed: () => _showConfirmationDialog('restart'),
                backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                textColor: Theme.of(context).colorScheme.tertiary,
                height: ResponsiveUtils.getButtonSize() * 0.8,
              ),
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveUtils.hp(1.5)),
        
        // Main menu button
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'Main Menu',
            icon: Icons.home_rounded,
            onPressed: () => _showConfirmationDialog('mainMenu'),
            backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.2),
            textColor: Theme.of(context).colorScheme.error,
            height: ResponsiveUtils.getButtonSize() * 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationDialog() {
    final actionData = _getConfirmationData(_confirmationAction);
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(15),
        vertical: ResponsiveUtils.hp(30),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              actionData['icon'] as IconData,
              size: ResponsiveUtils.sp(40),
              color: actionData['color'] as Color,
            ),
            SizedBox(height: ResponsiveUtils.hp(2)),
            Text(
              actionData['title'] as String,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.hp(1)),
            Text(
              actionData['message'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.hp(3)),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: 'Cancel',
                    onPressed: _hideConfirmationDialog,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: ResponsiveUtils.getButtonSize() * 0.8,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.wp(3)),
                Expanded(
                  child: GradientButton(
                    text: actionData['confirmText'] as String,
                    onPressed: () => _executeConfirmedAction(_confirmationAction),
                    backgroundColor: (actionData['color'] as Color).withOpacity(0.2),
                    textColor: actionData['color'] as Color,
                    height: ResponsiveUtils.getButtonSize() * 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getConfirmationData(String action) {
    switch (action) {
      case 'restart':
        return {
          'icon': Icons.refresh_rounded,
          'color': Theme.of(context).colorScheme.tertiary,
          'title': 'Restart Game',
          'message': 'Are you sure you want to restart?\nAll current progress will be lost.',
          'confirmText': 'Restart',
        };
      case 'mainMenu':
        return {
          'icon': Icons.home_rounded,
          'color': Theme.of(context).colorScheme.error,
          'title': 'Exit to Main Menu',
          'message': 'Your progress will be automatically saved.\nAre you sure you want to exit?',
          'confirmText': 'Exit',
        };
      default:
        return {
          'icon': Icons.help_outline,
          'color': Theme.of(context).colorScheme.primary,
          'title': 'Confirm Action',
          'message': 'Are you sure you want to proceed?',
          'confirmText': 'Confirm',
        };
    }
  }

  void _handleResume() {
    _playButtonSound();
    HapticFeedback.lightImpact();
    _closeOverlay();
    widget.onResume?.call();
  }

  void _handleSettings() {
    _playButtonSound();
    HapticFeedback.lightImpact();
    widget.onSettings?.call();
  }

  void _showConfirmationDialog(String action) {
    _playButtonSound();
    HapticFeedback.lightImpact();
    
    setState(() {
      _showConfirmation = true;
      _confirmationAction = action;
    });
  }

  void _hideConfirmationDialog() {
    _playButtonSound();
    HapticFeedback.lightImpact();
    
    setState(() {
      _showConfirmation = false;
      _confirmationAction = '';
    });
  }

  void _executeConfirmedAction(String action) {
    _playButtonSound();
    HapticFeedback.mediumImpact();
    
    switch (action) {
      case 'restart':
        _closeOverlay();
        widget.onRestart?.call();
        break;
      case 'mainMenu':
        _closeOverlay();
        widget.onMainMenu?.call();
        break;
    }
  }

  Future<void> _closeOverlay() async {
    await _startExitAnimation();
    if (!_isDisposed && mounted) {
      context.read<UICubit>().hidePauseOverlay();
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

/// Extension for easy access to pause overlay
extension PauseOverlayExtension on BuildContext {
  /// Show pause overlay
  void showPauseOverlay({
    VoidCallback? onResume,
    VoidCallback? onRestart,
    VoidCallback? onMainMenu,
    VoidCallback? onSettings,
    bool showStatistics = true,
    Map<String, dynamic>? gameStats,
  }) {
    final overlay = PauseOverlay(
      onResume: onResume,
      onRestart: onRestart,
      onMainMenu: onMainMenu,
      onSettings: onSettings,
      showStatistics: showStatistics,
      gameStats: gameStats,
    );

    showDialog(
      context: this,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => overlay,
    );
  }
}