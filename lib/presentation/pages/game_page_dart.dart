import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/player_state.dart' hide PlayerState;
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/presentation/flame/box_hooks_game.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import '../widgets/overlays/pause_overlay.dart';
import '../widgets/overlays/game_over_overlay.dart';
import '../widgets/game/game_hud.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/performance_utils.dart';
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
  late AnimationController _hudAnimationController;
  late Animation<double> _hudFadeAnimation;
  
  // State tracking
  bool _isGameInitialized = false;
  bool _shouldContinueGame = false;
  bool _isGamePaused = false;
  bool _isDisposed = false;
  
  // Performance monitoring
  final Stopwatch _performanceTimer = Stopwatch();
  
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
    _hudAnimationController.dispose();
    _game.pauseEngine();
    super.dispose();
  }

  void _initializeAnimations() {
    _hudAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _hudFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hudAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeGame() async {
    try {
      _performanceTimer.start();
      
      // Check if we should continue a saved game
      _shouldContinueGame = widget.arguments?['continueGame'] ?? false;
      
      // Create new game instance
      _game = BoxHooksGame();
      
      // Initialize game
      await _game.onLoad();
      
      // Mark as initialized
      setState(() {
        _isGameInitialized = true;
      });
      
      // Start HUD animation
      _hudAnimationController.forward();
      
      // Start or continue game based on arguments
      if (_shouldContinueGame) {
        await _continueGame();
      } else {
        await _startNewGame();
      }
      
      _performanceTimer.stop();
      PerformanceUtils.recordPageBuildTime(
        'GamePage', 
        Duration(milliseconds: _performanceTimer.elapsedMilliseconds),
      );
      
    } catch (e, stackTrace) {
      _handleGameError('Failed to initialize game', e, stackTrace);
    }
  }

  Future<void> _startNewGame() async {
    try {
      final gameCubit = context.read<GameCubit>();
      await gameCubit.startNewGame();
      
      if (mounted) {
        _resumeGame();
      }
      
    } catch (e, stackTrace) {
      _handleGameError('Failed to start new game', e, stackTrace);
    }
  }

  Future<void> _continueGame() async {
    try {
      final gameCubit = context.read<GameCubit>();
      await gameCubit.loadSavedGame();
      
      if (mounted) {
        _resumeGame();
      }
      
    } catch (e, stackTrace) {
      _handleGameError('Failed to continue game', e, stackTrace);
    }
  }

  void _handleGameError(String message, dynamic error, StackTrace? stackTrace) {
    _errorCount++;
    _lastError = '$message: $error';
    
    if (mounted) {
      final uiCubit = context.read<UICubit>();
      uiCubit.showError(_lastError!);
      
      // If too many errors, navigate back to main menu
      if (_errorCount >= 3) {
        uiCubit.navigateToPage(AppPage.mainMenu);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (!_isGameInitialized || _isDisposed) return;

    switch (state) {
      case AppLifecycleState.paused:
        _pauseGame();
        break;
      case AppLifecycleState.resumed:
        // Don't auto-resume, let user choose
        break;
      case AppLifecycleState.detached:
        _saveGameState();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGameInitialized) {
      return _buildLoadingScreen();
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<GameCubit, GameState>(
          listener: _handleGameStateChange,
        ),
        BlocListener<UICubit, UIState>(
          listener: _handleUIStateChange,
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).gameColors.gameBackground,
        body: SafeArea(
          child: Stack(
            children: [
              // Main game view
              _buildGameView(),
              
              // Game HUD overlay
              _buildGameHUD(),
              
              // Pause overlay
              _buildPauseOverlay(),
              
              // Game over overlay
              _buildGameOverOverlay(),
              
              // Performance overlay (debug only)
              if (AppConstants.enablePerformanceMonitoring)
                _buildPerformanceOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).gameColors.gameBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: ResponsiveUtils.hp(2)),
            Text(
              'Loading Game...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            if (_lastError != null) ...[
              SizedBox(height: ResponsiveUtils.hp(2)),
              Container(
                margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.wp(10)),
                padding: EdgeInsets.all(ResponsiveUtils.getAdaptivePadding()),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    SizedBox(height: ResponsiveUtils.hp(1)),
                    Text(
                      'Error: $_lastError',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveUtils.hp(1)),
                    ElevatedButton(
                      onPressed: () => context.read<UICubit>().navigateToPage(AppPage.mainMenu),
                      child: const Text('Back to Menu'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameView() {
    return GameWidget<BoxHooksGame>.controlled(
      gameFactory: () => _game,
      overlayBuilderMap: {
        'pause': (context, game) => const SizedBox.shrink(),
        'gameOver': (context, game) => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildGameHUD() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, gameState) {
        return AnimatedBuilder(
          animation: _hudFadeAnimation,
          child: GameHUD(
            score: gameState.score,
            level: gameState.level,
            linesCleared: gameState.linesCleared,
            nextBlocks: gameState.nextBlocks,
            currentCombo: gameState.comboCount,
            powerUps: gameState.availablePowerUps,
            canUndo: gameState.canUndo,
            remainingUndos: gameState.remainingUndos,
            onPausePressed: _pauseGame,
            onUndoPressed: gameState.canUndo ? _undoMove : null,
            onPowerUpPressed: _usePowerUp,
          ),
          builder: (context, child) {
            return Opacity(
              opacity: _hudFadeAnimation.value,
              child: child,
            );
          },
        );
      },
    );
  }

  Widget _buildPauseOverlay() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, uiState) {
        if (!uiState.showPauseOverlay) return const SizedBox.shrink();
        
        return BlocBuilder<GameCubit, GameState>(
          builder: (context, gameState) {
            return PauseOverlay(
              onResume: _resumeGame,
              onRestart: _restartGame,
              onMainMenu: _exitToMainMenu,
              onSettings: _openSettings,
              gameStats: {
                'score': gameState.score,
                'level': gameState.level,
                'linesCleared': gameState.linesCleared,
                'combo': gameState.comboCount,
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGameOverOverlay() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, gameState) {
        if (!gameState.isGameOver || gameState.currentSession == null) {
          return const SizedBox.shrink();
        }
        
        return BlocBuilder<PlayerCubit, PlayerState>(
          builder: (context, playerState) {
            return GameOverOverlay(
              gameSession: gameState.currentSession!,
              unlockedAchievements: playerState.recentAchievements,
              onRestart: _restartGame,
              onMainMenu: _exitToMainMenu,
              onShare: _shareScore,
              onUndo: gameState.canUndo ? _undoMove : null,
              canUndo: gameState.canUndo,
            );
          },
        );
      },
    );
  }

  Widget _buildPerformanceOverlay() {
    if (!_isGameInitialized) return const SizedBox.shrink();
    
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FPS: ${_game.currentFPS.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            Text(
              'Memory: ${PerformanceUtils.getMetrics().currentMemoryMB.toStringAsFixed(1)}MB',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            if (_errorCount > 0)
              Text(
                'Errors: $_errorCount',
                style: const TextStyle(color: Colors.red, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // GAME CONTROL METHODS
  // ========================================

  void _pauseGame() {
    if (_isGamePaused || !_isGameInitialized) return;
    
    setState(() {
      _isGamePaused = true;
    });
    
    _game.pauseGame();
    context.read<UICubit>().showPauseOverlay();
    HapticFeedback.lightImpact();
  }

  void _resumeGame() {
    if (!_isGamePaused || !_isGameInitialized) return;
    
    setState(() {
      _isGamePaused = false;
    });
    
    _game.resumeGame();
    context.read<UICubit>().hidePauseOverlay();
    HapticFeedback.lightImpact();
  }

  Future<void> _restartGame() async {
    try {
      await _game.resetGame();
      await context.read<GameCubit>().startNewGame();
      _resumeGame();
    } catch (e, stackTrace) {
      _handleGameError('Failed to restart game', e, stackTrace);
    }
  }

  void _undoMove() {
    try {
      context.read<GameCubit>().undoLastMove();
      HapticFeedback.lightImpact();
    } catch (e, stackTrace) {
      _handleGameError('Failed to undo move', e, stackTrace);
    }
  }

  void _usePowerUp(PowerUpType powerUpType) {
    try {
      context.read<GameCubit>().usePowerUp(powerUpType);
      HapticFeedback.mediumImpact();
    } catch (e, stackTrace) {
      _handleGameError('Failed to use power-up', e, stackTrace);
    }
  }

  void _exitToMainMenu() {
    _saveGameState();
    context.read<UICubit>().navigateToPage(AppPage.mainMenu);
  }

  void _openSettings() {
    context.read<UICubit>().navigateToPage(AppPage.settings);
  }

  void _shareScore() {
    final gameState = context.read<GameCubit>().state;
    final scoreText = 'I just scored ${gameState.score} points in Box Hooks! Can you beat it?';
    
    // Implement share functionality
    // This would integrate with platform sharing APIs
    context.read<UICubit>().showNotification('Share feature coming soon!');
  }

  Future<void> _saveGameState() async {
    if (!_isGameInitialized) return;
    
    try {
      await context.read<GameCubit>().saveGame();
    } catch (e, stackTrace) {
      _handleGameError('Failed to save game', e, stackTrace);
    }
  }

  // ========================================
  // STATE CHANGE HANDLERS
  // ========================================

  void _handleGameStateChange(BuildContext context, GameState state) {
    // Handle game over
    if (state.isGameOver && state.currentSession != null) {
      _isGamePaused = true;
      _game.pauseGame();
      
      // Update player stats
      context.read<PlayerCubit>().processGameCompletion(
        finalScore: state.score,
        level: state.level,
        linesCleared: state.linesCleared,
        blocksPlaced: state.currentSession!.statistics.blocksPlaced,
        gameDuration: state.sessionDuration ?? Duration.zero,
        usedPowerUps: state.currentSession!.statistics.powerUpsUsed,
      );
    }
    
    // Handle errors
    if (state.hasError && state.errorMessage != null) {
      _handleGameError('Game error', state.errorMessage!, null);
    }
  }

  void _handleUIStateChange(BuildContext context, UIState state) {
    // Handle navigation away from game page
    if (state.currentPage != AppPage.game && mounted) {
      _saveGameState();
    }
    
    // Handle errors
    if (state.hasError && state.errorMessage != null) {
      _handleGameError('UI error', state.errorMessage!, null);
    }
  }
}