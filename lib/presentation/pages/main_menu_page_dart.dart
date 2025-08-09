// File: lib/presentation/pages/main_menu_page.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  
  late AnimationController _floatingController;
  late AnimationController _buttonsController;
  late AnimationController _backgroundController;
  
  late Animation<double> _floatingAnimation;
  late Animation<double> _buttonsAnimation;
  late Animation<double> _backgroundRotation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Floating animation for logo and elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Button entrance animations
    _buttonsController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
    );
    
    // Background rotation animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
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
  }

  void _startAnimations() {
    _floatingController.repeat(reverse: true);
    _buttonsController.forward();
    _backgroundController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, uiState) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryPurple,
                  AppColors.primaryPink,
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background elements
                _buildAnimatedBackground(),
                
                // Main content
                SafeArea(
                  child: ResponsiveUtils.buildResponsiveWidget(
                    context: context,
                    mobile: _buildMobileLayout(),
                    tablet: _buildTabletLayout(),
                    desktop: _buildDesktopLayout(),
                  ),
                ),
                
                // Settings button
                _buildSettingsButton(context),
                
                // Player stats overlay
                _buildPlayerStatsOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating particles
            ...List.generate(15, (index) => _buildFloatingParticle(index)),
            
            // Rotating geometric shapes
            ...List.generate(3, (index) => _buildRotatingShape(index)),
          ],
        );
      },
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = (index * 1337) % 1000 / 1000.0;
    final size = 8.0 + (index % 6) * 4;
    final color = AppColors.blockColors[index % AppColors.blockColors.length];
    
    return Positioned(
      left: MediaQuery.of(context).size.width * random,
      top: MediaQuery.of(context).size.height * random + 
           _floatingAnimation.value * 30,
      child: Opacity(
        opacity: 0.3 + _floatingAnimation.value * 0.3,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size / 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRotatingShape(int index) {
    final positions = [
      const Offset(0.1, 0.2),
      const Offset(0.8, 0.3),
      const Offset(0.2, 0.8),
    ];
    
    final colors = [
      AppColors.primaryYellow,
      AppColors.primaryOrange,
      AppColors.primaryGreen,
    ];
    
    final position = positions[index];
    final color = colors[index];
    
    return Positioned(
      left: MediaQuery.of(context).size.width * position.dx,
      top: MediaQuery.of(context).size.height * position.dy,
      child: Transform.rotate(
        angle: _backgroundRotation.value + (index * math.pi / 3),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        const Spacer(flex: 1),
        
        // Logo section
        Expanded(
          flex: 3,
          child: _buildLogoSection(),
        ),
        
        // Menu buttons
        Expanded(
          flex: 4,
          child: _buildMenuButtons(),
        ),
        
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left side - Logo
        Expanded(
          flex: 2,
          child: Center(
            child: _buildLogoSection(),
          ),
        ),
        
        // Right side - Menu
        Expanded(
          flex: 2,
          child: _buildMenuButtons(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            // Left side - Logo and info
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogoSection(),
                  const SizedBox(height: 32),
                  _buildQuickStats(),
                ],
              ),
            ),
            
            // Right side - Menu
            Expanded(
              flex: 2,
              child: _buildMenuButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main logo container
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // App icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryYellow,
                            AppColors.primaryOrange,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryYellow.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.grid_3x3,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // App name
                    const Text(
                      'Box Hooks',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline
                    Text(
                      'Colorful Puzzle Adventure',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Version info
              Text(
                'Version ${AppConstants.appVersion}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuButtons() {
    return AnimatedBuilder(
      animation: _buttonsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonsAnimation.value,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play button
                  _buildAnimatedMenuButton(
                    text: 'PLAY',
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.primaryGreen,
                    onPressed: () => _navigateToGame(context),
                    delay: 0,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Achievements button
                  _buildAnimatedMenuButton(
                    text: 'ACHIEVEMENTS',
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.primaryYellow,
                    onPressed: () => _navigateToAchievements(context),
                    delay: 100,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Store button
                  _buildAnimatedMenuButton(
                    text: 'STORE',
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.primaryPink,
                    onPressed: () => _navigateToStore(context),
                    delay: 200,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Daily reward section
                  _buildDailyRewardSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedMenuButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 50),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              child: GradientButton(
                onPressed: onPressed,
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
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

  Widget _buildDailyRewardSection() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        // Check if daily reward is available (simplified logic)
        final canClaimDaily = true; // Would check last claim time
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryOrange.withOpacity(0.3),
                AppColors.primaryYellow.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryYellow.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Reward icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.primaryYellow,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Reward info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canClaimDaily ? 'Daily Reward Ready!' : 'Next Reward in 2h',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '+25 Coins',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Claim button
              if (canClaimDaily)
                GradientButton(
                  onPressed: () => _claimDailyReward(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryGreen, AppColors.primaryBlue],
                  ),
                  child: const Text(
                    'CLAIM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStats() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        if (!playerState.hasPlayerStats) {
          return const SizedBox();
        }
        
        final stats = playerState.playerStats!;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Title
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    label: 'High Score',
                    value: stats.highScore,
                    icon: Icons.emoji_events,
                  ),
                  _buildStatItem(
                    label: 'Games',
                    value: stats.gamesPlayed,
                    icon: Icons.games,
                  ),
                  _buildStatItem(
                    label: 'Achievements',
                    value: playerState.unlockedAchievements,
                    icon: Icons.star,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryYellow,
          size: 24,
        ),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 20,
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
    );
  }

  Widget _buildPlayerStatsOverlay() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        if (!playerState.hasPlayerStats) {
          return const SizedBox();
        }
        
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryYellow.withOpacity(0.9),
                  AppColors.primaryOrange.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryYellow.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
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
                  value: playerState.playerStats!.totalCoins,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Navigation methods
  void _navigateToGame(BuildContext context) {
    context.read<UICubit>().navigateToPage(AppPage.game);
  }

  void _navigateToAchievements(BuildContext context) {
    context.read<UICubit>().navigateToPage(AppPage.achievements);
  }

  void _navigateToStore(BuildContext context) {
    context.read<UICubit>().navigateToPage(AppPage.store);
  }

  void _claimDailyReward(BuildContext context) {
    // Would implement daily reward logic
    context.read<PlayerCubit>().addCoins(25, source: 'daily_reward');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.white),
            SizedBox(width: 8),
            Text('Daily reward claimed! +25 coins'),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _buttonsController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }
}