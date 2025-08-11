import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit.dart';
import '../common/gradient_button.dart';
import '../common/animated_counter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/services/audio_service.dart';

class PowerUpPanel extends StatefulWidget {
  /// Available power-ups
  final List<PowerUp> availablePowerUps;
  
  /// Callback when a power-up is used
  final Function(PowerUpType type)? onPowerUpUsed;
  
  /// Whether the panel is interactive
  final bool interactive;
  
  /// Whether to show power-up descriptions
  final bool showDescriptions;
  
  /// Panel orientation
  final Axis orientation;

  const PowerUpPanel({
    super.key,
    required this.availablePowerUps,
    this.onPowerUpUsed,
    this.interactive = true,
    this.showDescriptions = false,
    this.orientation = Axis.horizontal,
  });

  @override
  State<PowerUpPanel> createState() => _PowerUpPanelState();
}

class _PowerUpPanelState extends State<PowerUpPanel>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  final Map<PowerUpType, AnimationController> _buttonControllers = {};
  final Map<PowerUpType, Animation<double>> _buttonAnimations = {};
  
  PowerUpType? _selectedPowerUp;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeButtonAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.orientation == Axis.horizontal
          ? const Offset(0, 1)
          : const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _initializeButtonAnimations() {
    for (final powerUp in widget.availablePowerUps) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      );
      
      final animation = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
      
      _buttonControllers[powerUp.type] = controller;
      _buttonAnimations[powerUp.type] = animation;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    for (final controller in _buttonControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: EdgeInsets.all(ResponsiveUtils.wp(2)),
            decoration: _buildPanelDecoration(),
            child: widget.orientation == Axis.horizontal
                ? _buildHorizontalPanel(playerState)
                : _buildVerticalPanel(playerState),
          ),
        );
      },
    );
  }

  BoxDecoration _buildPanelDecoration() {
    return BoxDecoration(
      gradient: AppTheme.surfaceGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppTheme.primaryColor.withValues(alpha:0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha:0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildHorizontalPanel(PlayerState playerState) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.wp(3)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(),
          SizedBox(height: ResponsiveUtils.hp(1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: widget.availablePowerUps.map((powerUp) {
              return _buildPowerUpButton(powerUp, playerState);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalPanel(PlayerState playerState) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.wp(2)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPanelHeader(),
          SizedBox(height: ResponsiveUtils.hp(1)),
          ...widget.availablePowerUps.map((powerUp) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.hp(0.5)),
              child: _buildPowerUpButton(powerUp, playerState),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.primaryColor,
              size: ResponsiveUtils.sp(20),
            ),
            SizedBox(width: ResponsiveUtils.wp(2)),
            Text(
              'Power-Ups',
              style: AppTheme.titleStyle.copyWith(
                fontSize: ResponsiveUtils.sp(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (widget.showDescriptions)
          IconButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white70,
              size: ResponsiveUtils.sp(20),
            ),
          ),
      ],
    );
  }

  Widget _buildPowerUpButton(PowerUp powerUp, PlayerState playerState) {
    final isAvailable = _isPowerUpAvailable(powerUp, playerState);
    final count = _getPowerUpCount(powerUp.type, playerState);
    final isSelected = _selectedPowerUp == powerUp.type;
    
    return AnimatedBuilder(
      animation: _buttonAnimations[powerUp.type]!,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonAnimations[powerUp.type]!.value,
          child: GestureDetector(
            onTap: isAvailable && widget.interactive 
                ? () => _usePowerUp(powerUp)
                : null,
            child: Container(
              width: widget.orientation == Axis.horizontal 
                  ? ResponsiveUtils.wp(18) 
                  : null,
              height: ResponsiveUtils.hp(8),
              padding: EdgeInsets.all(ResponsiveUtils.wp(2)),
              decoration: _buildButtonDecoration(powerUp, isAvailable, isSelected),
              child: widget.orientation == Axis.horizontal
                  ? _buildHorizontalButtonContent(powerUp, count, isAvailable)
                  : _buildVerticalButtonContent(powerUp, count, isAvailable),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildButtonDecoration(PowerUp powerUp, bool isAvailable, bool isSelected) {
    Color baseColor = isAvailable ? powerUp.color : Colors.grey;
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          baseColor.withValues(alpha:isSelected ? 0.8 : 0.3),
          baseColor.withValues(alpha:isSelected ? 0.6 : 0.1),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected 
            ? baseColor
            : baseColor.withValues(alpha:0.5),
        width: isSelected ? 2 : 1,
      ),
      boxShadow: isAvailable && isSelected
          ? [
              BoxShadow(
                color: baseColor.withValues(alpha:0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  Widget _buildHorizontalButtonContent(PowerUp powerUp, int count, bool isAvailable) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          powerUp.icon,
          style: TextStyle(
            fontSize: ResponsiveUtils.sp(24),
            color: isAvailable ? Colors.white : Colors.grey,
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(0.5)),
        AnimatedCounter(
          value: count,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: ResponsiveUtils.sp(12),
            fontWeight: FontWeight.bold,
            color: isAvailable ? Colors.white : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalButtonContent(PowerUp powerUp, int count, bool isAvailable) {
    return Row(
      children: [
        Container(
          width: ResponsiveUtils.wp(12),
          height: ResponsiveUtils.wp(12),
          decoration: BoxDecoration(
            color: powerUp.color.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              powerUp.icon,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(20),
                color: isAvailable ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.wp(3)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                powerUp.name,
                style: AppTheme.titleStyle.copyWith(
                  fontSize: ResponsiveUtils.sp(14),
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? Colors.white : Colors.grey,
                ),
              ),
              if (widget.showDescriptions && _isExpanded)
                Text(
                  powerUp.description,
                  style: AppTheme.bodyStyle.copyWith(
                    fontSize: ResponsiveUtils.sp(10),
                    color: isAvailable ? Colors.white70 : Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedCounter(
              value: count,
              style: AppTheme.titleStyle.copyWith(
                fontSize: ResponsiveUtils.sp(16),
                fontWeight: FontWeight.bold,
                color: isAvailable ? powerUp.color : Colors.grey,
              ),
            ),
            Text(
              'uses',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: ResponsiveUtils.sp(10),
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isPowerUpAvailable(PowerUp powerUp, PlayerState playerState) {
    final count = _getPowerUpCount(powerUp.type, playerState);
    return count > 0;
  }

  int _getPowerUpCount(PowerUpType type, PlayerState playerState) {
    return playerState.powerUps[type] ?? 0;
  }

  void _usePowerUp(PowerUp powerUp) {
    if (!widget.interactive) return;
    
    setState(() {
      _selectedPowerUp = powerUp.type;
    });
    
    // Animate button
    _buttonControllers[powerUp.type]?.forward().then((_) {
      _buttonControllers[powerUp.type]?.reverse();
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Play sound
    AudioService.playSfx('power_up_use');
    
    // Trigger callback
    widget.onPowerUpUsed?.call(powerUp.type);
    
    // Show usage effect
    _showPowerUpUsageEffect(powerUp);
    
    // Clear selection after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _selectedPowerUp = null;
        });
      }
    });
  }

  void _showPowerUpUsageEffect(PowerUp powerUp) {
    // Create floating effect
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _PowerUpUsageEffect(
        powerUp: powerUp,
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );
    
    overlay.insert(overlayEntry);
  }
}

/// Visual effect shown when a power-up is used
class _PowerUpUsageEffect extends StatefulWidget {
  final PowerUp powerUp;
  final VoidCallback onComplete;

  const _PowerUpUsageEffect({
    required this.powerUp,
    required this.onComplete,
  });

  @override
  State<_PowerUpUsageEffect> createState() => _PowerUpUsageEffectState();
}

class _PowerUpUsageEffectState extends State<_PowerUpUsageEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -100),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: _positionAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.powerUp.color.withValues(alpha:0.8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.powerUp.color.withValues(alpha:0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.powerUp.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.powerUp.name} Activated!',
                          style: AppTheme.titleStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Compact power-up button for minimal UI
class CompactPowerUpButton extends StatelessWidget {
  final PowerUp powerUp;
  final int count;
  final VoidCallback? onPressed;
  final bool enabled;

  const CompactPowerUpButton({
    super.key,
    required this.powerUp,
    required this.count,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      onPressed: enabled && count > 0 ? onPressed : null,
      gradient: LinearGradient(
        colors: [
          powerUp.color,
          powerUp.color.withValues(alpha:0.7),
        ],
      ),
      width: ResponsiveUtils.wp(16),
      height: ResponsiveUtils.hp(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            powerUp.icon,
            style: TextStyle(fontSize: ResponsiveUtils.sp(16)),
          ),
          AnimatedCounter(
            value: count,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: ResponsiveUtils.sp(10),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}