import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit.dart';
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
  
  // Animation controllers - CRITICAL: Must be disposed properly
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _progressController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  
  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<Offset> _logoSlide;
  late Animation<double> _particleOpacity;
  late Animation<double> _progressValue;
  late Animation<double> _textFade;
  late Animation<double> _backgroundGradient;
  
  // State tracking
  bool _assetsLoaded = false;
  bool _isDisposed = false;
  double _loadingProgress = 0.0;
  String _loadingStatus = 'Initializing...';
  final List<String> _loadingSteps = [];
  
  // Loading timer
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // CRITICAL: Dispose all animation controllers to prevent memory leaks
    _logoController.dispose();
    _particleController.dispose();
    _progressController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    
    // Cancel loading timer
    _loadingTimer?.cancel();
    
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
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
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
    
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));
    
    _backgroundGradient = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  void _startLoadingSequence() async {
    if (_isDisposed) return;
    
    try {
      // Start background animation
      _backgroundController.forward();
      
      // Start logo animation after brief delay
      await Future.delayed(const Duration(milliseconds: 300));
      if (!_isDisposed) {
        _logoController.forward();
        _particleController.forward();
      }
      
      // Start text animation
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isDisposed) {
        _textController.forward();
      }
      
      // Start loading process
      await _loadAssets();
      
      // Complete loading and navigate
      if (!_isDisposed) {
        await _completeLoading();
      }
    } catch (e) {
      _handleLoadingError(e);
    }
  }

  Future<void> _loadAssets() async {
    if (_isDisposed) return;
    
    final steps = [
      'Loading game engine...',
      'Initializing dependencies...',
      'Loading assets...',
      'Setting up state management...',
      'Preparing game world...',
      'Finalizing setup...',
    ];
    
    for (int i = 0; i < steps.length; i++) {
      if (_isDisposed) return;
      
      setState(() {
        _loadingStatus = steps[i];
        _loadingProgress = (i + 1) / steps.length;
      });
      
      // Animate progress bar
      _progressController.animateTo(_loadingProgress);
      
      // Simulate loading time with actual work
      switch (i) {
        case 0:
          // Initialize core systems
          await Future.delayed(const Duration(milliseconds: 300));
          break;
        case 1:
          // Initialize dependency injection
          await _initializeDependencies();
          break;
        case 2:
          // Load assets
          await _loadGameAssets();
          break;
        case 3:
          // Setup state management
          await _initializeStateManagement();
          break;
        case 4:
          // Prepare game world
          await Future.delayed(const Duration(milliseconds: 200));
          break;
        case 5:
          // Final setup
          await Future.delayed(const Duration(milliseconds: 200));
          break;
      }
    }
    
    setState(() {
      _assetsLoaded = true;
    });
  }

  Future<void> _initializeDependencies() async {
    try {
      if (!getIt.isRegistered<UICubit>()) {
        await initializeApp();
      }
    } catch (e) {
      print('Dependency initialization error: $e');
      // Continue with fallback
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> _loadGameAssets() async {
    // Simulate asset loading
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Preload critical UI components
    if (mounted) {
      precacheImage(const AssetImage('assets/images/logo.png'), context);
    }
  }

  Future<void> _initializeStateManagement() async {
    try {
      await initializeStateManagement();
    } catch (e) {
      print('State management initialization error: $e');
      // Continue with fallback
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> _completeLoading() async {
    if (_isDisposed) return;
    
    // Final animation sequence
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!_isDisposed && mounted) {
      // Navigate to main menu
      context.read<UICubit>().navigateToPage(AppPage.mainMenu);
    }
  }

  void _handleLoadingError(dynamic error) {
    if (_isDisposed) return;
    
    setState(() {
      _loadingStatus = 'Loading failed. Retrying...';
    });
    
    print('Splash loading error: $error');
    
    // Retry after delay
    _loadingTimer = Timer(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        _startLoadingSequence();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoScale,
          _logoRotation,
          _logoSlide,
          _particleOpacity,
          _progressValue,
          _textFade,
          _backgroundGradient,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBackground,
                  Color.lerp(AppColors.darkBackground, AppColors.primary.withValues(alpha:0.1), _backgroundGradient.value)!,
                  AppColors.darkSurface,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Particle effects background
                _buildParticleBackground(),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section
                      _buildLogo(),
                      
                      SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                      
                      // Loading section
                      _buildLoadingSection(),
                    ],
                  ),
                ),
                
                // Version info
                _buildVersionInfo(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticleBackground() {
    return Positioned.fill(
      child: Opacity(
        opacity: _particleOpacity.value * 0.3,
        child: CustomPaint(
          painter: ParticleBackgroundPainter(_particleController.value),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SlideTransition(
      position: _logoSlide,
      child: Transform.scale(
        scale: _logoScale.value,
        child: Transform.rotate(
          angle: _logoRotation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha:0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.apps,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        // App title
        FadeTransition(
          opacity: _textFade,
          child: const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        FadeTransition(
          opacity: _textFade,
          child: Text(
            'Puzzle Block Game',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha:0.7),
              letterSpacing: 1,
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Progress section
        _buildProgressSection(),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        children: [
          // Loading status text
          FadeTransition(
            opacity: _textFade,
            child: Text(
              _loadingStatus,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Progress bar
          FadeTransition(
            opacity: _textFade,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressValue.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Progress percentage
          FadeTransition(
            opacity: _textFade,
            child: AnimatedCounter(
              count: (_loadingProgress * 100).round(),
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha:0.8),
              ),
              suffix: '%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _textFade,
        child: Text(
          'Version ${AppConstants.appVersion}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha:0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Custom painter for animated particle background
class ParticleBackgroundPainter extends CustomPainter {
  final double animationValue;
  
  ParticleBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha:0.3)
      ..style = PaintingStyle.fill;

    // Create animated particles
    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20) * i + (animationValue * 50) % size.width;
      final y = (size.height / 4) * (i % 4) + (animationValue * 30) % (size.height / 2);
      final radius = 2 + (animationValue * 3) % 5;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = AppColors.primary.withValues(alpha:0.1 + (animationValue * 0.2)),
      );
    }
  }

  @override
  bool shouldRepaint(ParticleBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}