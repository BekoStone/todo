import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import 'package:puzzle_box/core/constants/game_constants.dart';
import 'package:puzzle_box/core/state/game_state.dart';
import 'package:puzzle_box/core/theme/colors.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit.dart';
import 'package:puzzle_box/presentation/flame/box_hooks_game.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import '../widgets/overlays/pause_overlay.dart';
import '../widgets/overlays/game_over_overlay.dart';
import '../widgets/game/game_hud.dart';
import '../../injection_container.dart';

/// GamePage provides the main game interface with Flame integration.
/// Optimized for 60 FPS performance with proper memory management and lifecycle handling.
/// Follows Clean Architecture with proper state management and error handling.
class GamePage extends StatefulWidget {
  /// Optional arguments passed from navigation
  final Map<String, dynamic>? arguments;

  const GamePage({super.key, this.arguments});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  // Core game components
  late BoxHooksGame _game;
  
  // Animation controllers - CRITICAL: Must be disposed properly
  late AnimationController _hudAnimationController;
  late AnimationController _overlayAnimationController;
  late AnimationController _transitionController;
  
  // Animations
  late Animation<double> _hudFadeAnimation;
  late Animation<double> _overlayScaleAnimation;
  late Animation<Offset> _transitionSlideAnimation;
  
  // State tracking
  bool _isGameInitialized = false;
  bool _shouldContinueGame = false;
  bool _isGamePaused = false;
  bool _isDisposed = false;
  
  // Performance monitoring
  final Stopwatch _performanceTimer = Stopwatch();
  final List<double> _frameRates = [];
  
  // Error tracking
  String? _lastError;
  int _errorCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeGame();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    
    // CRITICAL: Dispose all animation controllers to prevent memory leaks
    _hudAnimationController.dispose();
    _overlayAnimationController.dispose();
    _transitionController.dispose();
    
    // Clean up game resources
    _game.pauseEngine();
    
    super.dispose();
  }

  void _initializeAnimations() {
    // HUD fade animation
    _hudAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Overlay scale animation
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Page transition animation
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create animation tweens
    _hudFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hudAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _overlayScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _transitionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeGame() async {
    try {
      _performanceTimer.start();
      
      // Check if we should continue a saved game
      _shouldContinueGame = widget.arguments?['continueGame'] ?? false;
      
      // Initialize the Flame game
      _game = BoxHooksGame(
        gameCubit: getIt<GameCubit>(),
        playerCubit: getIt<PlayerCubit>(),
        uiCubit: getIt<UICubit>(),
      );
      
      // Load game assets and initialize systems
      await _game.onLoad();
      
      setState(() {
        _isGameInitialized = true;
      });
      
      // Start game session
      if (_shouldContinueGame) {
        await _loadSavedGame();
      } else {
        await _startNewGame();
      }
      
      // Start HUD animation
      _hudAnimationController.forward();
      _transitionController.forward();
      
      _performanceTimer.stop();
      
      if (GameConstants.enablePerformanceMonitoring) {
        print('Game initialization completed in ${_performanceTimer.elapsedMilliseconds}ms');
      }
      
    } catch (e) {
      _handleGameError('Failed to initialize game', e);
    }
  }

  Future<void> _startNewGame() async {
    try {
      final difficulty = widget.arguments?['difficulty'] ?? GameDifficulty.normal;
      final mode = widget.arguments?['mode'] ?? GameMode.classic;
      
      await context.read<GameCubit>().startNewGame(
        difficulty: difficulty,
        mode: mode,
      );
      
    } catch (e) {
      _handleGameError('Failed to start new game', e);
    }
  }

  Future<void> _loadSavedGame() async {
    try {
      final sessionId = widget.arguments?['sessionId'] as String?;
      if (sessionId != null) {
        await context.read<GameCubit>().loadGame(sessionId);
      } else {
        await _startNewGame();
      }
    } catch (e) {
      _handleGameError('Failed to load saved game', e);
      // Fallback to new game
      await _startNewGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Stack(
          children: [
            // Background
            _buildBackground(),
            
            // Game content
            if (_isGameInitialized) _buildGameContent(),
            
            // Loading overlay
            if (!_isGameInitialized) _buildLoadingOverlay(),
            
            // Game HUD
            if (_isGameInitialized) _buildGameHUD(),
            
            // Overlays
            _buildOverlays(),
            
            // Performance overlay (debug only)
            if (GameConstants.enablePerformanceMonitoring) _buildPerformanceOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.darkBackground,
            AppColors.darkSurface,
          ],
        ),
      ),
    );
  }

  Widget _buildGameContent() {
    return SlideTransition(
      position: _transitionSlideAnimation,
      child: SafeArea(
        child: GameWidget<BoxHooksGame>.controlled(
          gameFactory: () => _game,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.darkBackground,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 20),
            Text(
              'Loading game...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHUD() {
    return AnimatedBuilder(
      animation: _hudFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _hudFadeAnimation.value,
          child: const GameHUD(),
        );
      },
    );
  }

  Widget _buildOverlays() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, uiState) {
        return Stack(
          children: [
            // Pause overlay
            if (uiState.showPauseOverlay)
              AnimatedBuilder(
                animation: _overlayScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _overlayScaleAnimation.value,
                    child: const PauseOverlay(),
                  );
                },
              ),
            
            // Game over overlay
            if (uiState.showGameOverOverlay)
              BlocBuilder<GameCubit, GameState>(
                builder: (context, gameState) {
                  return AnimatedBuilder(
                    animation: _overlayScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _overlayScaleAnimation.value,
                        child: GameOverOverlay(
                          gameSession: gameState.currentSession!,
                          onRestart: _handleGameRestart,
                          onMainMenu: _handleBackToMainMenu,
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceOverlay() {
    return Positioned(
      top: 50,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FPS: ${_getCurrentFPS().toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Memory: ${_getMemoryUsage()}MB',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Errors: $_errorCount',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Event handlers
  Future<bool> _handleBackPress() async {
    if (_isGamePaused) {
      // Resume game
      context.read<GameCubit>().resumeGame();
      context.read<UICubit>().hidePauseOverlay();
      setState(() {
        _isGamePaused = false;
      });
      return false;
    } else {
      // Pause game and show confirmation
      _pauseGame();
      return false;
    }
  }

  void _pauseGame() {
    if (!_isGamePaused) {
      context.read<GameCubit>().pauseGame();
      context.read<UICubit>().showPauseOverlay();
      
      setState(() {
        _isGamePaused = true;
      });
      
      _overlayAnimationController.forward();
    }
  }

  void _resumeGame() {
    if (_isGamePaused) {
      context.read<GameCubit>().resumeGame();
      context.read<UICubit>().hidePauseOverlay();
      
      setState(() {
        _isGamePaused = false;
      });
      
      _overlayAnimationController.reverse();
    }
  }

  void _handleGameRestart() async {
    try {
      // Hide overlays
      context.read<UICubit>().hideGameOverOverlay();
      _overlayAnimationController.reverse();
      
      // Start transition animation
      _transitionController.reverse().then((_) async {
        // Start new game
        await _startNewGame();
        
        // Restart animations
        _transitionController.forward();
        _hudAnimationController.forward();
      });
      
    } catch (e) {
      _handleGameError('Failed to restart game', e);
    }
  }

  void _handleBackToMainMenu() {
    // Animate out
    _hudAnimationController.reverse();
    _transitionController.reverse().then((_) {
      // Navigate to main menu
      context.read<UICubit>().navigateToPage(AppPage.mainMenu);
    });
  }

  // Performance monitoring
  double _getCurrentFPS() {
    if (_frameRates.isEmpty) return 0.0;
    
    final sum = _frameRates.reduce((a, b) => a + b);
    return sum / _frameRates.length;
  }

  String _getMemoryUsage() {
    // This would need platform-specific implementation
    return '0';
  }

  void _updateFrameRate() {
    if (GameConstants.enablePerformanceMonitoring) {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Calculate FPS (simplified)
      _frameRates.add(60.0); // Placeholder
      
      // Keep only recent frame rates
      if (_frameRates.length > 60) {
        _frameRates.removeAt(0);
      }
    }
  }

  // Error handling
  void _handleGameError(String message, dynamic error) {
    _errorCount++;
    _lastError = message;
    
    print('Game error: $message - $error');
    
    if (!_isDisposed) {
      // Show error message to user
      context.read<UICubit>().showError(message);
    }
    
    // Log error for debugging
    if (GameConstants.enableDebugMode) {
      print('Game error stack trace: ${StackTrace.current}');
    }
  }

  // App lifecycle methods
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        if (!_isGamePaused) {
          _pauseGame();
        }
        break;
      case AppLifecycleState.resumed:
        // Game will be resumed manually by user
        break;
      case AppLifecycleState.inactive:
        if (!_isGamePaused) {
          _pauseGame();
        }
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  void didUpdateWidget(GamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle widget updates
    if (widget.arguments != oldWidget.arguments) {
      // Reinitialize if arguments changed
      _initializeGame();
    }
  }
}