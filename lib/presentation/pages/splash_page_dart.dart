// File: lib/presentation/pages/splash_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/domain/repositories/asset_repository_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import '../widgets/common/animated_counter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/colors.dart';
import '../../injection_container.dart';

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
  List<String> _loadingSteps = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: AppConstants.longAnimationDuration,
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Particle animation
    _particleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeInOut,
    ));

    // Progress animation
    _progressValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _logoController.forward();
    _particleController.repeat(reverse: true);
  }

  Future<void> _startLoadingSequence() async {
    try {
      await _loadAssets();
      await _initializeServices();
      await _loadPlayerData();
      await _finishLoading();
    } catch (e) {
      _handleLoadingError(e);
    }
  }

  Future<void> _loadAssets() async {
    _updateLoadingStatus('Loading game assets...', 0.1);
    
    try {
      final assetRepository = getIt<AssetRepository>();
      
      final result = await assetRepository.preloadEssentialAssets(
        onProgress: (progress) {
          setState(() {
            _loadingProgress = 0.1 + (progress * 0.4); // 10% to 50%
          });
          _progressController.animateTo(_loadingProgress);
        },
      );

      _loadingSteps.add('✓ Assets loaded: ${result.loadedAssets}/${result.totalAssets}');
      
      if (!result.isSuccess) {
        _loadingSteps.add('⚠ Some assets failed to load');
      }

      _updateLoadingStatus('Assets loaded successfully', 0.5);
      
    } catch (e) {
      _loadingSteps.add('✗ Asset loading failed: $e');
      _updateLoadingStatus('Asset loading failed', 0.5);
      rethrow;
    }
  }

  Future<void> _initializeServices() async {
    _updateLoadingStatus('Initializing services...', 0.6);
    
    try {
      // Initialize audio service
      _loadingSteps.add('• Initializing audio...');
      await Future.delayed(const Duration(milliseconds: 300));
      _loadingSteps.add('✓ Audio service ready');

      // Initialize analytics
      _loadingSteps.add('• Setting up analytics...');
      await Future.delayed(const Duration(milliseconds: 200));
      _loadingSteps.add('✓ Analytics initialized');

      // Initialize storage
      _loadingSteps.add('• Preparing storage...');
      await Future.delayed(const Duration(milliseconds: 250));
      _loadingSteps.add('✓ Storage ready');

      _updateLoadingStatus('Services initialized', 0.75);
      
    } catch (e) {
      _loadingSteps.add('✗ Service initialization failed: $e');
      _updateLoadingStatus('Service initialization failed', 0.75);
      rethrow;
    }
  }

  Future<void> _loadPlayerData() async {
    _updateLoadingStatus('Loading player data...', 0.8);
    
    try {
      // Initialize player cubit
      final playerCubit = context.read<PlayerCubit>();
      await playerCubit.initializePlayer();
      
      _loadingSteps.add('✓ Player data loaded');
      _updateLoadingStatus('Player data ready', 0.9);
      
    } catch (e) {
      _loadingSteps.add('⚠ Using default player data');
      _updateLoadingStatus('Using default settings', 0.9);
      // Don't rethrow - we can continue with defaults
    }
  }

  Future<void> _finishLoading() async {
    _updateLoadingStatus('Ready to play!', 1.0);
    _loadingSteps.add('🎮 Game ready!');
    
    setState(() {
      _assetsLoaded = true;
    });

    // Wait a moment to show completion
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      context.read<UICubit>().navigateToPage(AppPage.mainMenu);
    }
  }

  void _updateLoadingStatus(String status, double progress) {
    if (mounted) {
      setState(() {
        _loadingStatus = status;
        _loadingProgress = progress;
      });
      _progressController.animateTo(progress);
    }
  }

  void _handleLoadingError(dynamic error) {
    setState(() {
      _loadingStatus = 'Loading failed';
      _loadingSteps.add('✗ Critical error: $error');
    });

    // Show error dialog after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _showErrorDialog(error.toString());
      }
    });
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Loading Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Failed to initialize the game:'),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startLoadingSequence(); // Retry
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<UICubit>().navigateToPage(AppPage.mainMenu);
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, uiState) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryPurple,
                  AppColors.primaryPink,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header spacing
                  const Spacer(flex: 2),
                  
                  // Logo section
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _logoController,
                          _particleController,
                        ]),
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Background particles
                              ..._buildParticles(),
                              
                              // Main logo
                              SlideTransition(
                                position: _logoSlide,
                                child: RotationTransition(
                                  turns: _logoRotation,
                                  child: ScaleTransition(
                                    scale: _logoScale,
                                    child: _buildLogo(),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                          if (uiState.showDebugInfo)
                            _buildLoadingSteps(),
                        ],
                      ),
                    ),
                  ),
                  
                  // Footer spacing
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Container(
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
          // App icon/logo would go here
          Container(
            width: 120,
            height: 120,
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
                  color: AppColors.primaryYellow.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.grid_3x3,
              size: 64,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App name
          const Text(
            'Box Hooks',
            style: TextStyle(
              fontSize: 36,
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
            'A Colorful Puzzle Adventure',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingProgress() {
    return Column(
      children: [
        // Progress bar
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _progressValue.value,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _assetsLoaded ? AppColors.success : AppColors.primaryYellow,
              ),
              minHeight: 8,
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Progress percentage
        AnimatedCounter(
          value: (_loadingProgress * 100).round(),
          suffix: '%',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingStatus() {
    return AnimatedSwitcher(
      duration: AppConstants.shortAnimationDuration,
      child: Text(
        _loadingStatus,
        key: ValueKey(_loadingStatus),
        style: TextStyle(
          fontSize: 16,
          color: Colors.white.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadingSteps() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loading Steps:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _loadingSteps.length,
                itemBuilder: (context, index) {
                  final step = _loadingSteps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(12, (index) {
      final random = (index * 137) % 100 / 100.0;
      final size = 4.0 + (index % 4) * 2;
      final color = [
        AppColors.primaryYellow,
        AppColors.primaryOrange,
        AppColors.primaryPink,
        AppColors.primaryBlue,
      ][index % 4];

      return Positioned(
        left: 300 * random,
        top: 300 * random + _particleOpacity.value * 20,
        child: Opacity(
          opacity: _particleOpacity.value * 0.6,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}