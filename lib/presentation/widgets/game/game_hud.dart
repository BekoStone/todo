import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import '../common/animated_counter.dart';
import '../common/gradient_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/game_constants.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/audio_service.dart';

class GameHUD extends StatefulWidget {
  /// Whether the HUD is in compact mode
  final bool compact;
  
  /// Callback when pause button is pressed
  final VoidCallback? onPause;
  
  /// Callback when settings button is pressed
  final VoidCallback? onSettings;
  
  /// Whether to show progress indicators
  final bool showProgress;
  
  /// Whether to show level information
  final bool showLevel;

  const GameHUD({
    super.key,
    this.compact = false,
    this.onPause,
    this.onSettings,
    this.showProgress = true,
    this.showLevel = true,
  });

  @override
  State<GameHUD> createState() => _GameHUDState();
}

class _GameHUDState extends State<GameHUD>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _comboController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _comboAnimation;
  
  bool _showComboIndicator = false;
  int _lastComboCount = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _comboController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _comboAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _comboController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _comboController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listener: (context, state) {
        if (state is GameStateLoaded) {
          _handleGameStateChange(state);
        }
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.compact ? _buildCompactHUD() : _buildFullHUD(),
      ),
    );
  }

  Widget _buildFullHUD() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(4),
        vertical: ResponsiveUtils.hp(1),
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.surfaceGradient,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopRow(),
            if (widget.showProgress) ...[
              SizedBox(height: ResponsiveUtils.hp(1)),
              _buildProgressRow(),
            ],
            if (_showComboIndicator) ...[
              SizedBox(height: ResponsiveUtils.hp(1)),
              _buildComboIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHUD() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(2),
        vertical: ResponsiveUtils.hp(0.5),
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.surfaceGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCompactScoreDisplay(),
          _buildCompactLevelDisplay(),
          _buildCompactCoinsDisplay(),
          _buildCompactActions(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        _buildScoreSection(),
        const Spacer(),
        _buildLevelSection(),
        const Spacer(),
        _buildCoinsSection(),
        const Spacer(),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildScoreSection() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final score = state is GameStateLoaded ? state.session.score : 0;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.wp(3),
            vertical: ResponsiveUtils.hp(1),
          ),
          decoration: _buildSectionDecoration(AppTheme.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: AppTheme.primaryColor,
                    size: ResponsiveUtils.sp(16),
                  ),
                  SizedBox(width: ResponsiveUtils.wp(1)),
                  Text(
                    'SCORE',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: ResponsiveUtils.sp(10),
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              ScoreCounter(
                score: score,
                fontSize: ResponsiveUtils.sp(18),
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelSection() {
    if (!widget.showLevel) return const SizedBox.shrink();
    
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final level = state is GameStateLoaded ? state.session.level : 1;
        final progress = state is GameStateLoaded ? state.session.levelProgress : 0.0;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.wp(3),
            vertical: ResponsiveUtils.hp(1),
          ),
          decoration: _buildSectionDecoration(AppTheme.accentColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.accentColor,
                    size: ResponsiveUtils.sp(16),
                  ),
                  SizedBox(width: ResponsiveUtils.wp(1)),
                  Text(
                    'LEVEL',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: ResponsiveUtils.sp(10),
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              AnimatedCounter(
                value: level,
                style: AppTheme.titleStyle.copyWith(
                  fontSize: ResponsiveUtils.sp(18),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              if (widget.showProgress)
                Container(
                  width: ResponsiveUtils.wp(15),
                  height: 4,
                  margin: EdgeInsets.only(top: ResponsiveUtils.hp(0.5)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinsSection() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.wp(3),
            vertical: ResponsiveUtils.hp(1),
          ),
          decoration: _buildSectionDecoration(AppTheme.secondaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    color: AppTheme.secondaryColor,
                    size: ResponsiveUtils.sp(16),
                  ),
                  SizedBox(width: ResponsiveUtils.wp(1)),
                  Text(
                    'COINS',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: ResponsiveUtils.sp(10),
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              CoinCounter(
                coins: state.stats.coins,
                fontSize: ResponsiveUtils.sp(18),
                showIcon: false,
                color: AppTheme.secondaryColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onPause != null)
          _buildActionButton(
            icon: Icons.pause_rounded,
            onPressed: widget.onPause!,
            color: Colors.orange,
          ),
        if (widget.onSettings != null) ...[
          SizedBox(width: ResponsiveUtils.wp(2)),
          _buildActionButton(
            icon: Icons.settings_rounded,
            onPressed: widget.onSettings!,
            color: Colors.grey,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: ResponsiveUtils.wp(10),
      height: ResponsiveUtils.wp(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AudioService.playSfx('button_click');
            onPressed();
          },
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            color: Colors.white,
            size: ResponsiveUtils.sp(16),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRow() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        if (state is! GameStateLoaded) return const SizedBox.shrink();
        
        return Row(
          children: [
            Expanded(child: _buildLinesProgress(state)),
            SizedBox(width: ResponsiveUtils.wp(4)),
            Expanded(child: _buildTimeProgress(state)),
          ],
        );
      },
    );
  }

  Widget _buildLinesProgress(GameStateLoaded state) {
    final lines = state.session.linesCleared;
    final targetLines = (state.session.level * 10); // 10 lines per level
    final progress = (lines % 10) / 10.0;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(2)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lines Cleared',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: ResponsiveUtils.sp(10),
                  color: Colors.white70,
                ),
              ),
              Text(
                '${lines % 10}/10',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: ResponsiveUtils.sp(10),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeProgress(GameStateLoaded state) {
    final elapsedSeconds = state.session.playTime;
    
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(2)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Time Played',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: ResponsiveUtils.sp(10),
              color: Colors.white70,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(0.5)),
          TimerCounter(
            totalSeconds: elapsedSeconds,
            fontSize: ResponsiveUtils.sp(14),
            color: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildComboIndicator() {
    return AnimatedBuilder(
      animation: _comboAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _comboAnimation.value,
          child: Opacity(
            opacity: _comboAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.wp(4),
                vertical: ResponsiveUtils.hp(1),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange,
                    Colors.red,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'COMBO x$_lastComboCount',
                    style: AppTheme.titleStyle.copyWith(
                      fontSize: ResponsiveUtils.sp(14),
                      fontWeight: FontWeight.bold,
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

  // Compact versions
  Widget _buildCompactScoreDisplay() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final score = state is GameStateLoaded ? state.session.score : 0;
        return ScoreCounter(
          score: score,
          fontSize: ResponsiveUtils.sp(14),
          fontWeight: FontWeight.bold,
        );
      },
    );
  }

  Widget _buildCompactLevelDisplay() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        final level = state is GameStateLoaded ? state.session.level : 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: AppTheme.accentColor,
              size: ResponsiveUtils.sp(14),
            ),
            const SizedBox(width: 4),
            AnimatedCounter(
              value: level,
              style: AppTheme.titleStyle.copyWith(
                fontSize: ResponsiveUtils.sp(14),
                color: AppTheme.accentColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactCoinsDisplay() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        return CoinCounter(
          coins: state.stats.coins,
          fontSize: ResponsiveUtils.sp(12),
          color: AppTheme.secondaryColor,
        );
      },
    );
  }

  Widget _buildCompactActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onPause != null)
          IconButton(
            onPressed: widget.onPause,
            icon: Icon(
              Icons.pause_rounded,
              color: Colors.white70,
              size: ResponsiveUtils.sp(16),
            ),
          ),
      ],
    );
  }

  BoxDecoration _buildSectionDecoration(Color color) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  void _handleGameStateChange(GameStateLoaded state) {
    // Handle score changes
    if (state.session.lastScoreIncrease > 0) {
      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });
    }
    
    // Handle combo changes
    if (state.session.currentCombo > 1 && state.session.currentCombo != _lastComboCount) {
      setState(() {
        _showComboIndicator = true;
        _lastComboCount = state.session.currentCombo;
      });
      
      _comboController.forward();
      
      // Hide combo indicator after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showComboIndicator = false;
          });
          _comboController.reverse();
        }
      });
    }
  }
}