import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/player_state.dart' hide PlayerState;
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

  @override
  void dispose() {
    _floatingController.dispose();
    _buttonsController.dispose();
    _backgroundController.dispose();
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
    _backgroundController.repeat();
    
    // Delay button animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _buttonsController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkBackground,
              AppColors.darkSurface,
              AppColors.darkSurfaceVariant,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            _buildAnimatedBackground(),
            
            // Main content
            SafeArea(
              child: ResponsiveUtils.isMobile(context)
                  ? _buildMobileLayout()
                  : ResponsiveUtils.isTablet(context)
                      ? _buildTabletLayout()
                      : _buildDesktopLayout(),
            ),
            
            // Settings button
            _buildSettingsButton(context),
            
            // Player stats overlay
            _buildPlayerStatsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Floating shapes
        ...List.generate(3, (index) => _buildFloatingShape(index)),
        
        // Rotating elements
        ...List.generate(3, (index) => _buildRotatingShape(index)),
        
        // Grid pattern overlay
        _buildGridOverlay(),
      ],
    );
  }

  Widget _buildGridOverlay() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.05,
        child: CustomPaint(
          painter: GridPainter(),
        ),
      ),
    );
  }

  Widget _buildFloatingShape(int index) {
    final positions = [
      const Offset(0.1, 0.1),
      const Offset(0.9, 0.15),
      const Offset(0.05, 0.7),
    ];
    
    final sizes = [40.0, 60.0, 50.0];
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
    ];
    
    final position = positions[index];
    final size = sizes[index];
    final color = colors[index];
    
    return Positioned(
      left: MediaQuery.of(context).size.width * position.dx,
      top: MediaQuery.of(context).size.height * position.dy,
      child: AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              _floatingAnimation.value * 20 - 10,
            ),
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
        },
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
      AppColors.warning,
      AppColors.info,
      AppColors.success,
    ];
    
    final position = positions[index];
    final color = colors[index];
    
    return Positioned(
      left: MediaQuery.of(context).size.width * position.dx,
      top: MediaQuery.of(context).size.height * position.dy,
      child: AnimatedBuilder(
        animation: _backgroundRotation,
        builder: (context, child) {
          return Transform.rotate(
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
          );
        },
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
              child: _buildLogoSection(),
            ),
            
            // Right side - Menu and stats
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlayerStatsCard(),
                  const SizedBox(height: 40),
                  _buildMenuButtons(),
                ],
              ),
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
          offset: Offset(0, _floatingAnimation.value * 10 - 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.extension_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // App name
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Tagline
              Text(
                'Puzzle Your Way to Victory',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.0,
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
          child: Opacity(
            opacity: _buttonsAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // New Game button
                  GradientButton(
                    text: 'New Game',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _startNewGame(),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Continue Game button
                  BlocBuilder<PlayerCubit, PlayerState>(
                    builder: (context, playerState) {
                      final hasSavedGame = playerState.playerStats?.hasSavedGame ?? false;
                      
                      return GradientButton(
                        text: 'Continue',
                        icon: Icons.refresh_rounded,
                        onPressed: hasSavedGame ? () => _continueGame() : null,
                        gradient: hasSavedGame
                            ? const LinearGradient(
                                colors: [AppColors.success, AppColors.info],
                              )
                            : null,
                        backgroundColor: hasSavedGame ? null : Colors.grey.withOpacity(0.3),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Achievements button
                  GradientButton(
                    text: 'Achievements',
                    icon: Icons.emoji_events_rounded,
                    onPressed: () => _showAchievements(),
                    gradient: const LinearGradient(
                      colors: [AppColors.warning, AppColors.error],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Leaderboard button
                  GradientButton(
                    text: 'Leaderboard',
                    icon: Icons.leaderboard_rounded,
                    onPressed: () => _showLeaderboard(),
                    gradient: const LinearGradient(
                      colors: [AppColors.info, AppColors.primary],
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

  Widget _buildPlayerStatsCard() {
    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, playerState) {
        if (!playerState.isDataLoaded || playerState.playerStats == null) {
          return const SizedBox();
        }

        final stats = playerState.playerStats!;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
              const Text(
                'Your Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    Icons.star_rounded,
                    stats.highScore,
                    'High Score',
                  ),
                  _buildStatItem(
                    Icons.monetization_on_rounded,
                    stats.totalCoins,
                    'Coins',
                  ),
                  _buildStatItem(
                    Icons.games_rounded,
                    stats.totalGamesPlayed,
                    'Games',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, int value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.warning,
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
        if (!playerState.isDataLoaded || playerState.playerStats == null) {
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
                  AppColors.warning.withOpacity(0.9),
                  AppColors.warning.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
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

  // Action handlers
  void _startNewGame() {
    context.read<UICubit>().navigateToPage(AppPage.game);
  }

  void _continueGame() {
    context.read<UICubit>().navigateToPage(AppPage.game, arguments: {'continue': true});
  }

  void _showAchievements() {
    context.read<UICubit>().navigateToPage(AppPage.achievements);
  }

  void _showLeaderboard() {
    context.read<UICubit>().navigateToPage(AppPage.leaderboard);
  }
}

/// Custom painter for grid overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 40.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}