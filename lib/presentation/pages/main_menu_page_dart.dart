import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/core/state/state_extensions.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/animated_counter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive_utils.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with TickerProviderStateMixin {
  
  // Animation controllers - CRITICAL: Must be disposed properly
  late AnimationController _floatingController;
  late AnimationController _buttonsController;
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _particleController;
  
  // Animations
  late Animation<double> _floatingAnimation;
  late Animation<double> _buttonsAnimation;
  late Animation<double> _backgroundRotation;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _particleOpacity;
  
  // State tracking
  bool _isDisposed = false;
  bool _animationsStarted = false;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // CRITICAL: Dispose all animation controllers to prevent memory leaks
    _floatingController.dispose();
    _buttonsController.dispose();
    _backgroundController.dispose();
    _logoController.dispose();
    _particleController.dispose();
    
    super.dispose();
  }

  void _initializeAnimations() {
    // Floating animation for logo and elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Button entrance animations
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Background rotation animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Create animations
    _floatingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    _buttonsAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.elasticOut,
    ));
    
    _backgroundRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));
    
    _logoScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoRotation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));
    
    _particleOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeIn,
    ));
  }

  void _startAnimations() {
    if (_isDisposed || _animationsStarted) return;
    
    _animationsStarted = true;
    
    // Start background rotation (infinite)
    _backgroundController.repeat();
    
    // Start floating animation (infinite)
    _floatingController.repeat(reverse: true);
    
    // Start logo animation
    _logoController.forward();
    
    // Start particle animation
    _particleController.forward().then((_) {
      if (!_isDisposed) {
        _particleController.repeat(reverse: true);
      }
    });
    
    // Delayed button animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        _buttonsController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _floatingAnimation,
                _buttonsAnimation,
                _logoScale,
                _logoRotation,
                _particleOpacity,
              ]),
              builder: (context, child) {
                return Column(
                  children: [
                    // Top section with logo and stats
                    Expanded(
                      flex: 3,
                      child: _buildTopSection(),
                    ),
                    
                    // Middle section with main buttons
                    Expanded(
                      flex: 2,
                      child: _buildMainButtons(),
                    ),
                    
                    // Bottom section with secondary buttons
                    Expanded(
                      flex: 1,
                      child: _buildBottomSection(),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Settings button
          _buildSettingsButton(context),
          
          // Player stats overlay
          _buildPlayerStatsOverlay(),
          
          // Particle effects
          _buildParticleEffects(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundRotation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _backgroundRotation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                  AppColors.darkBackground,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.wp(5),
        vertical: ResponsiveUtils.hp(2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo/title
          Transform.scale(
            scale: _logoScale.value,
            child: Transform.rotate(
              angle: _logoRotation.value * math.sin(_floatingAnimation.value * 2 * math.pi),
              child: Container(
                width: ResponsiveUtils.wp(40),
                height: ResponsiveUtils.wp(40),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.apps,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(2)),
          
          // App title
          Opacity(
            opacity: _logoScale.value,
            child: Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(8),
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          
          SizedBox(height: ResponsiveUtils.hp(1)),
          
          // Subtitle
          Opacity(
            opacity: _logoScale.value * 0.8,
            child: Text(
              'Puzzle Block Game',
              style: TextStyle(
                fontSize: ResponsiveUtils.sp(4),
                color: Colors.white.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Play button
          Transform.translate(
            offset: Offset(0, (1 - _buttonsAnimation.value) * 50),
            child: Opacity(
              opacity: _buttonsAnimation.value,
              child: GradientButton(
                text: 'PLAY',
                onPressed: () => _navigateToGame(context),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                width: ResponsiveUtils.wp(60),
                height: ResponsiveUtils.hp(6),
              ),
            ),
          ),
          
          // Continue button (if game in progress)
          BlocBuilder<PlayerCubit, PlayerState>(
            builder: (context, playerState) {
              if (playerState.playerStats?.hasActiveGame == true) {
                return Transform.translate(
                  offset: Offset(0, (1 - _buttonsAnimation.value) * 30),
                  child: Opacity(
                    opacity: _buttonsAnimation.value * 0.8,
                    child: GradientButton(
                      text: 'CONTINUE',
                      onPressed: () => _continueGame(context),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent,
                          AppColors.accent.withOpacity(0.8),
                        ],
                      ),
                      width: ResponsiveUtils.wp(60),
                      height: ResponsiveUtils.hp(5),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Achievements button
          Transform.translate(
            offset: Offset((1 - _buttonsAnimation.value) * -50, 0),
            child: Opacity(
              opacity: _buttonsAnimation.value,
              child: _buildSecondaryButton(
                icon: Icons.emoji_events,
                label: 'Achievements',
                onPressed: () => _navigateToAchievements(context),
              ),
            ),
          ),
          
          // Leaderboard button
          Transform.translate(
            offset: Offset(0, (1 - _buttonsAnimation.value) * 30),
            child: Opacity(
              opacity: _buttonsAnimation.value,
              child: _buildSecondaryButton(
                icon: Icons.leaderboard,
                label: 'Leaderboard',
                onPressed: () => _navigateToLeaderboard(context),
              ),
            ),
          ),
          
          // Store button
          Transform.translate(
            offset: Offset((1 - _buttonsAnimation.value) * 50, 0),
            child: Opacity(
              opacity: _buttonsAnimation.value,
              child: _buildSecondaryButton(
                icon: Icons.store,
                label: 'Store',
                onPressed: () => _navigateToStore(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStatsOverlay() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        if (!playerState.isDataLoaded || playerState.playerStats == null) {
          return const SizedBox();
        }
        
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          child: Transform.translate(
            offset: Offset((1 - _buttonsAnimation.value) * -100, 0),
            child: Opacity(
              opacity: _buttonsAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withOpacity(0.9),
                      AppColors.warning.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    AnimatedCounter(
                      count: playerState.safeCoins,
                      duration: const Duration(milliseconds: 800),
                      style: const TextStyle(
                        color: Colors.white,
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
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 20,
      child: Transform.translate(
        offset: Offset((1 - _buttonsAnimation.value) * 100, 0),
        child: Opacity(
          opacity: _buttonsAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => context.read<UICubit>().navigateToPage(AppPage.settings),
              icon: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 28,
              ),
              tooltip: 'Settings',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticleEffects() {
    return AnimatedBuilder(
      animation: _particleOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _particleOpacity.value * 0.3,
          child: Stack(
            children: List.generate(10, (index) {
              final random = math.Random(index);
              return Positioned(
                left: random.nextDouble() * MediaQuery.of(context).size.width,
                top: random.nextDouble() * MediaQuery.of(context).size.height,
                child: Transform.scale(
                  scale: 0.5 + random.nextDouble() * 0.5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // Navigation methods
  void _navigateToGame(BuildContext context) {
    context.read<UICubit>().navigateToPage(
      AppPage.game,
      data: {'continueGame': false},
    );
  }

  void _continueGame(BuildContext context) {
    context.read<UICubit>().navigateToPage(
      AppPage.game,
      data: {'continueGame': true},
    );
  }

  void _navigateToAchievements(BuildContext context) {
    context.read<UICubit>().navigateToPage(AppPage.achievements);
  }

  void _navigateToLeaderboard(BuildContext context) {
    context.read<UICubit>().navigateToPage(AppPage.leaderboard);
  }

  void _navigateToStore(BuildContext context) {
    // Implementation for store navigation
    context.read<UICubit>().showError('Store coming soon!');
  }

  @override
  void didUpdateWidget(MainMenuPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Restart animations if widget is rebuilt
    if (!_animationsStarted) {
      _startAnimations();
    }
  }
}

