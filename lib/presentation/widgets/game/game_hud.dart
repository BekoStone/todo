import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import '../common/animated_counter.dart';
import '../common/gradient_button.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/audio_service.dart';

class GameHUD extends StatefulWidget {
  /// Whether the HUD is in compact mode
  final bool compact;
  
  /// Callback when pause button is pressed
  final VoidCallback? onPause;
  
  /// Callback when settings button is pressed
  final VoidCallback? onSettings;
  
  /// Callback when a power-up is used
  final Function(PowerUpType)? onPowerUpUsed;

  const GameHUD({
    super.key,
    this.compact = false,
    this.onPause,
    this.onSettings,
    this.onPowerUpUsed,
  });

  @override
  State<GameHUD> createState() => _GameHUDState();
}

class _GameHUDState extends State<GameHUD>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.wp(4),
          vertical: ResponsiveUtils.hp(1),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.darkSurface.withOpacity(0.9),
              AppColors.darkSurface.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: widget.compact 
            ? _buildCompactHUD()
            : _buildFullHUD(),
      ),
    );
  }

  Widget _buildCompactHUD() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, gameState) {
        return Row(
          children: [
            // Score
            _buildScoreDisplay(gameState, compact: true),
            
            const Spacer(),
            
            // Level and time
            _buildLevelAndTime(gameState, compact: true),
            
            const Spacer(),
            
            // Action buttons
            _buildActionButtons(compact: true),
          ],
        );
      },
    );
  }

  Widget _buildFullHUD() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, gameState) {
        return Column(
          children: [
            // Top row: Score, Level, Time
            Row(
              children: [
                Expanded(child: _buildScoreDisplay(gameState)),
                SizedBox(width: ResponsiveUtils.wp(2)),
                Expanded(child: _buildLevelDisplay(gameState)),
                SizedBox(width: ResponsiveUtils.wp(2)),
                Expanded(child: _buildTimeDisplay(gameState)),
              ],
            ),
            
            SizedBox(height: ResponsiveUtils.hp(1)),
            
            // Second row: Lines, Combo, Actions
            Row(
              children: [
                Expanded(child: _buildLinesDisplay(gameState)),
                SizedBox(width: ResponsiveUtils.wp(2)),
                Expanded(child: _buildComboDisplay(gameState)),
                SizedBox(width: ResponsiveUtils.wp(2)),
                _buildActionButtons(),
              ],
            ),
            
            SizedBox(height: ResponsiveUtils.hp(1)),
            
            // Third row: Power-ups
            _buildPowerUpsBar(gameState),
          ],
        );
      },
    );
  }

  Widget _buildScoreDisplay(GameState gameState, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(3),
        vertical: ResponsiveUtils.hp(1),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.warning, AppColors.info],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: ResponsiveUtils.sp(16),
            ),
            SizedBox(height: ResponsiveUtils.hp(0.5)),
          ],
          
          FancyAnimatedCounter(
            value: gameState.score,
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(compact ? 16 : 18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            highlightColor: AppColors.warning,
            showPlusAnimation: true,
          ),
          
          if (!compact)
            Text(
              'Score',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(10),
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelDisplay(GameState gameState) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(3),
        vertical: ResponsiveUtils.hp(1),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: Colors.white,
            size: ResponsiveUtils.sp(16),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          
          AnimatedCounter(
            value: gameState.level,
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(18),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          Text(
            'Level',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(10),
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(GameState gameState) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(3),
        vertical: ResponsiveUtils.hp(1),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.info],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            color: Colors.white,
            size: ResponsiveUtils.sp(16),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          
          Text(
            _formatDuration(gameState.sessionDuration),
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(14),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          Text(
            'Time',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(10),
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesDisplay(GameState gameState) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(3),
        vertical: ResponsiveUtils.hp(1),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.linear_scale_rounded,
            color: AppColors.primary,
            size: ResponsiveUtils.sp(14),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          
          AnimatedCounter(
            value: gameState.linesCleared,
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(16),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          Text(
            'Lines',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(10),
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboDisplay(GameState gameState) {
    final hasCombo = gameState.comboCount > 0;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: hasCombo ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.wp(3),
              vertical: ResponsiveUtils.hp(1),
            ),
            decoration: BoxDecoration(
              gradient: hasCombo
                  ? const LinearGradient(
                      colors: [AppColors.error, AppColors.warning],
                    )
                  : null,
              color: hasCombo ? null : AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: hasCombo
                  ? [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: hasCombo ? Colors.white : AppColors.error,
                  size: ResponsiveUtils.sp(14),
                ),
                
                SizedBox(height: ResponsiveUtils.hp(0.5)),
                
                AnimatedCounter(
                  value: gameState.comboCount,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  suffix: 'x',
                ),
                
                Text(
                  'Combo',
                  style: TextStyle(
                    fontSize: ResponsiveUtils.sp(10),
                    color: hasCombo 
                        ? Colors.white.withOpacity(0.8)
                        : AppColors.error.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelAndTime(GameState gameState, {bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.wp(2),
            vertical: ResponsiveUtils.hp(0.5),
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.success,
                size: ResponsiveUtils.sp(12),
              ),
              
              SizedBox(width: ResponsiveUtils.wp(1)),
              
              AnimatedCounter(
                value: gameState.level,
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(14),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(width: ResponsiveUtils.wp(2)),
        
        // Time
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.wp(2),
            vertical: ResponsiveUtils.hp(0.5),
          ),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_rounded,
                color: AppColors.secondary,
                size: ResponsiveUtils.sp(12),
              ),
              
              SizedBox(width: ResponsiveUtils.wp(1)),
              
              Text(
                _formatDuration(gameState.sessionDuration, compact: true),
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(12),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause button
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(compact ? 8 : 12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () {
              AudioService.playSfx('ui_click');
              widget.onPause?.call();
            },
            icon: Icon(
              Icons.pause_rounded,
              color: Colors.white,
              size: ResponsiveUtils.sp(compact ? 18 : 20),
            ),
            padding: EdgeInsets.all(compact ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: compact ? 32 : 40,
              minHeight: compact ? 32 : 40,
            ),
          ),
        ),
        
        if (!compact) ...[
          SizedBox(width: ResponsiveUtils.wp(2)),
          
          // Settings button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () {
                AudioService.playSfx('ui_click');
                widget.onSettings?.call();
              },
              icon: Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: ResponsiveUtils.sp(20),
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPowerUpsBar(GameState gameState) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(3),
        vertical: ResponsiveUtils.hp(1),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            'Power-ups:',
            style: TextStyle(
              fontSize: ResponsiveUtils.sp(12),
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          
          SizedBox(width: ResponsiveUtils.wp(3)),
          
          Expanded(
            child: Row(
              children: [
                _buildPowerUpButton(
                  PowerUpType.undo,
                  Icons.undo_rounded,
                  gameState.remainingUndos,
                ),
                
                SizedBox(width: ResponsiveUtils.wp(2)),
                
                _buildPowerUpButton(
                  PowerUpType.hint,
                  Icons.lightbulb_rounded,
                  gameState.remainingHints,
                ),
                
                SizedBox(width: ResponsiveUtils.wp(2)),
                
                _buildPowerUpButton(
                  PowerUpType.shuffle,
                  Icons.shuffle_rounded,
                  gameState.powerUpCounts['shuffle'] ?? 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpButton(PowerUpType powerUpType, IconData icon, int count) {
    final hasCharges = count > 0;
    
    return Expanded(
      child: GestureDetector(
        onTap: hasCharges 
            ? () {
                AudioService.playSfx('power_up_use');
                widget.onPowerUpUsed?.call(powerUpType);
              }
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.hp(1),
          ),
          decoration: BoxDecoration(
            gradient: hasCharges
                ? LinearGradient(
                    colors: [
                      _getPowerUpColor(powerUpType),
                      _getPowerUpColor(powerUpType).withOpacity(0.7),
                    ],
                  )
                : null,
            color: hasCharges ? null : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasCharges 
                  ? _getPowerUpColor(powerUpType).withOpacity(0.5)
                  : Colors.grey.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: hasCharges ? Colors.white : Colors.grey,
                size: ResponsiveUtils.sp(16),
              ),
              
              SizedBox(height: ResponsiveUtils.hp(0.5)),
              
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: ResponsiveUtils.sp(12),
                  fontWeight: FontWeight.bold,
                  color: hasCharges ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPowerUpColor(PowerUpType powerUpType) {
    switch (powerUpType) {
      case PowerUpType.undo:
        return AppColors.warning;
      case PowerUpType.hint:
        return AppColors.info;
      case PowerUpType.shuffle:
        return AppColors.secondary;
      case PowerUpType.bomb:
        return AppColors.error;
      case PowerUpType.freeze:
        return AppColors.primary;
    }
  }

  String _formatDuration(Duration duration, {bool compact = false}) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    
    if (compact) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      if (minutes > 0) {
        return '${minutes}m ${seconds}s';
      } else {
        return '${seconds}s';
      }
    }
  }
}