import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import '../widgets/common/animated_counter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _progressController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<Offset> _logoSlide;
  late Animation<double> _particleOpacity;
  late Animation<double> _progressValue;
  
  bool _assetsLoaded = false;
  double _loadingProgress = 0.0;
  String _loadingStatus = 'Initializing...';
  final List<String> _loadingSteps = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    ));

    _particleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeIn,
    ));

    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  void _startLoadingSequence() async {
    // Start logo animation
    _logoController.forward();
    
    // Start particle animation after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _particleController.forward();
      }
    });

    // Initialize app components
    await _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize dependency injection
      await _updateProgress(0.1, 'Setting up dependencies...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 2: Initialize storage
      await _updateProgress(0.3, 'Loading player data...');
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Step 3: Initialize audio
      await _updateProgress(0.5, 'Preparing audio system...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 4: Load game assets
      await _updateProgress(0.7, 'Loading game assets...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 5: Initialize game engine
      await _updateProgress(0.9, 'Starting game engine...');
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Step 6: Complete initialization
      await _updateProgress(1.0, 'Ready to play!');
      await Future.delayed(const Duration(milliseconds: 300));
      
      _assetsLoaded = true;
      
      // Navigate to main menu after successful loading
      if (mounted) {
        context.read<UICubit>().navigateToPage(AppPage.mainMenu);
      }
      
    } catch (e) {
      debugPrint('❌ Failed to initialize app: $e');
      await _updateProgress(0.0, 'Failed to load. Retrying...');
      
      // Retry after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _startLoadingSequence();
        }
      });
    }
  }

  Future<void> _updateProgress(double progress, String status) async {
    if (!mounted) return;
    
    setState(() {
      _loadingProgress = progress;
      _loadingStatus = status;
      _loadingSteps.add(status);
      
      // Keep only the last 3 steps
      if (_loadingSteps.length > 3) {
        _loadingSteps.removeAt(0);
      }
    });
    
    // Animate progress bar
    _progressController.reset();
    _progressController.forward();
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
                  AppColors.darkBackground,
                  AppColors.darkSurface,
                  AppColors.darkSurfaceVariant,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Background particles
                  _buildBackgroundParticles(),
                  
                  // Main content
                  Column(
                    children: [
                      // Logo section
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: _buildLogo(),
                        ),
                      ),
                      
                      // Loading section
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              // Loading progress
                              _buildLoadingProgress(),
                              
                              const SizedBox(height: 24),
                              
                              // Loading status
                              _buildLoadingStatus(),
                              
                              const SizedBox(height: 16),
                              
                              // Loading steps (debug info)
                              if (uiState.showDebugInfo) _buildLoadingSteps(),
                            ],
                          ),
                        ),
                      ),
                      
                      // Footer
                      const Spacer(flex: 1),
                      _buildFooter(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _particleOpacity,
      builder: (context, child) {
        return Opacity(
          opacity: _particleOpacity.value,
          child: Stack(
            children: List.generate(15, (index) {
              return _buildParticle(index);
            }),
          ),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    final screenSize = MediaQuery.of(context).size;
    final random = index * 97; // Pseudo-random based on index
    
    final x = ((random * 7) % 100) / 100 * screenSize.width;
    final y = ((random * 11) % 100) / 100 * screenSize.height;
    final size = 4.0 + ((random * 13) % 8);
    final color = AppColors.particleColors[index % AppColors.particleColors.length];
    
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.6),
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoScale, _logoSlide, _logoRotation]),
      builder: (context, child) {
        return SlideTransition(
          position: _logoSlide,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Transform.rotate(
              angle: _logoRotation.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App icon/logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
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
                      child: const Icon(
                        Icons.extension_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // App name
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline
                    Text(
                      'Puzzle Your Way to Victory',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 0.5,
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

  Widget _buildLoadingProgress() {
    return Column(
      children: [
        // Progress bar
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: AnimatedBuilder(
            animation: _progressValue,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _loadingProgress * _progressValue.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Progress percentage
        AnimatedCounter(
          value: (_loadingProgress * 100).round(),
          suffix: '%',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStatus() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _loadingStatus,
        key: ValueKey(_loadingStatus),
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingSteps() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loading Steps:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          ..._loadingSteps.map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Version ${AppConstants.appVersion}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '© ${DateTime.now().year} ${AppConstants.developerName}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}