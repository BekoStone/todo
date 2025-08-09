import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/presentation/flame/box_hooks_game.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import '../widgets/overlays/pause_overlay.dart';
import '../widgets/overlays/game_over_overlay.dart';
import '../widgets/game/game_hud.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive_utils.dart';

class GamePage extends StatefulWidget {
  /// Optional arguments passed from navigation
  final Map<String, dynamic>? arguments;

  const GamePage({super.key, this.arguments});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late BoxHooksGame _game;
  bool _isGameInitialized = false;
  bool _shouldContinueGame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check if we should continue a saved game
    _shouldContinueGame = widget.arguments?['continue'] == true;
    
    _initializeGame();
    _setupGameStateListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _pauseGame();
        break;
      case AppLifecycleState.resumed:
        // Game will be resumed manually by user
        break;
      case AppLifecycleState.detached:
        _saveGame();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _initializeGame() {
    try {
      _game = BoxHooksGame();
      _isGameInitialized = true;
      
      // Start or continue game based on arguments
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_shouldContinueGame) {
          context.read<GameCubit>().loadSavedGame();
        } else {
          context.read<GameCubit>().startNewGame();
        }
      });
      
    } catch (e) {
      debugPrint('❌ Failed to initialize game: $e');
      _showErrorAndNavigateBack('Failed to initialize game');
    }
  }

  void _setupGameStateListeners() {
    // Listen to game state changes from the cubit
    // The actual game logic is handled in the Flame game and cubit
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: MultiBlocListener(
        listeners: [
          BlocListener<GameCubit, GameState>(
            listener: _handleGameStateChange,
          ),
          BlocListener<PlayerCubit, PlayerState>(
            listener: _handlePlayerStateChange,
          ),
          BlocListener<UICubit, UIState>(
            listener: _handleUIStateChange,
          ),
        ],
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
            
            // Loading overlay
            _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView() {
    if (!_isGameInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return GameWidget<BoxHooksGame>.controlled(
      gameFactory: () => _game,
      overlayBuilderMap: {
        'PauseOverlay': (context, game) => _buildPauseOverlay(),
        'GameOverOverlay': (context, game) => _buildGameOverOverlay(),
      },
    );
  }

  Widget _buildGameHUD() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, gameState) {
        if (!gameState.isPlaying && !gameState.isPaused) {
          return const SizedBox();
        }

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: GameHUD(
              compact: ResponsiveUtils.isMobile(context),
              onPause: _pauseGame,
              onSettings: _showSettings,
              onPowerUpUsed: _onPowerUpUsed,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPauseOverlay() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, uiState) {
        if (!uiState.showPauseOverlay) {
          return const SizedBox();
        }

        return BlocBuilder<GameCubit, GameState>(
          builder: (context, gameState) {
            return PauseOverlay(
              gameSession: gameState.currentSession!,
              onResume: _resumeGame,
              onRestart: _restartGame,
              onMainMenu: _exitToMainMenu,
              onSettings: _showSettings,
            );
          },
        );
      },
    );
  }

  Widget _buildGameOverOverlay() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, uiState) {
        if (!uiState.showGameOverOverlay) {
          return const SizedBox();
        }

        return BlocBuilder<GameCubit, GameState>(
          builder: (context, gameState) {
            return BlocBuilder<PlayerCubit, PlayerState>(
              builder: (context, playerState) {
                return GameOverOverlay(
                  gameSession: gameState.currentSession!,
                  unlockedAchievements: playerState.recentAchievements,
                  onRestart: _restartGame,
                  onMainMenu: _exitToMainMenu,
                  onShare: _shareScore,
                  onWatchAd: _watchAdForCoins,
                  canUndo: gameState.remainingUndos > 0,
                  onUndo: _undoLastMove,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return BlocBuilder<UICubit, UIState>(
      builder: (context, uiState) {
        if (!uiState.isLoading) {
          return const SizedBox();
        }

        return Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    uiState.loadingMessage ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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

  // ========================================
  // STATE CHANGE HANDLERS
  // ========================================

  void _handleGameStateChange(BuildContext context, GameState gameState) {
    switch (gameState.status) {
      case GameStateStatus.loading:
        context.read<UICubit>().showLoading(message: 'Starting game...');
        break;
        
      case GameStateStatus.playing:
        context.read<UICubit>().hideLoading();
        context.read<UICubit>().hidePauseOverlay();
        context.read<UICubit>().hideGameOverOverlay();
        break;
        
      case GameStateStatus.paused:
        context.read<UICubit>().showPauseOverlay();
        break;
        
      case GameStateStatus.gameOver:
        context.read<UICubit>().hideLoading();
        context.read<UICubit>().hidePauseOverlay();
        context.read<UICubit>().showGameOverOverlay(
          gameData: {
            'finalScore': gameState.score,
            'level': gameState.level,
            'linesCleared': gameState.linesCleared,
            'playTime': gameState.sessionDuration,
          },
        );
        _processGameCompletion(gameState);
        break;
        
      case GameStateStatus.error:
        context.read<UICubit>().hideLoading();
        _showErrorSnackBar(gameState.errorMessage ?? 'Game error occurred');
        break;
        
      case GameStateStatus.initial:
        // Initial state, nothing to do
        break;
    }
    
    // Handle achievements
    _checkForAchievements(gameState);
  }

  void _handlePlayerStateChange(BuildContext context, PlayerState playerState) {
    if (playerState.hasError) {
      _showErrorSnackBar(playerState.errorMessage ?? 'Player error occurred');
    }
    
    // Handle achievement unlocks
    if (playerState.hasUnseenAchievements && playerState.recentUnlocks.isNotEmpty) {
      for (final achievement in playerState.recentUnlocks) {
        _showAchievementUnlock(achievement);
      }
    }
    
    // Handle coins earned
    if (playerState.coinsEarned > 0) {
      _showCoinsEarned(playerState.coinsEarned);
    }
  }

  void _handleUIStateChange(BuildContext context, UIState uiState) {
    // Handle navigation changes
    if (uiState.currentPage != AppPage.game) {
      // Navigation away from game page will be handled by the app navigator
    }
    
    // Handle error messages
    if (uiState.hasError) {
      _showErrorSnackBar(uiState.errorMessage!);
    }
  }

  // ========================================
  // GAME ACTIONS
  // ========================================

  void _pauseGame() {
    HapticFeedback.lightImpact();
    context.read<GameCubit>().pauseGame();
  }

  void _resumeGame() {
    HapticFeedback.lightImpact();
    context.read<GameCubit>().resumeGame();
  }

  void _restartGame() {
    HapticFeedback.mediumImpact();
    context.read<GameCubit>().restartGame();
  }

  void _saveGame() {
    context.read<GameCubit>().saveGame();
  }

  void _undoLastMove() {
    HapticFeedback.lightImpact();
    // Implement undo logic through cubit
    _showInfoSnackBar('Undo functionality coming soon');
  }

  void _exitToMainMenu() {
    HapticFeedback.lightImpact();
    // Save game before exiting
    _saveGame();
    context.read<UICubit>().navigateToPage(AppPage.mainMenu);
  }

  void _showSettings() {
    context.read<UICubit>().showSettingsOverlay();
  }

  void _onPowerUpUsed(PowerUpType powerUpType) {
    HapticFeedback.mediumImpact();
    context.read<GameCubit>().usePowerUp(powerUpType);
  }

  void _shareScore() {
    final gameState = context.read<GameCubit>().state;
    final message = 'I just scored ${gameState.score} points in ${AppConstants.appName}! Can you beat my score?';
    
    // Implement share functionality
    _showInfoSnackBar('Share functionality coming soon');
  }

  void _watchAdForCoins() {
    // Implement ad watching for coins
    _showInfoSnackBar('Ad rewards coming soon');
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  void _processGameCompletion(GameState gameState) {
    final sessionData = gameState.sessionData;
    if (sessionData != null) {
      context.read<PlayerCubit>().processGameCompletion(
        finalScore: gameState.score,
        level: gameState.level,
        linesCleared: gameState.linesCleared,
        blocksPlaced: sessionData.blocksPlaced,
        gameDuration: gameState.sessionDuration,
        usedPowerUps: sessionData.powerUpsUsed,
        hadPerfectClear: sessionData.perfectClears > 0,
        usedUndo: gameState.remainingUndos < 3,
      );
    }
  }

  void _checkForAchievements(GameState gameState) {
    final playerCubit = context.read<PlayerCubit>();
    
    // Check for score-based achievements
    if (gameState.score >= 1000) {
      playerCubit.updateAchievementProgress('score_1000', 1);
    }
    
    // Check for combo achievements
    if (gameState.comboCount >= 3) {
      playerCubit.updateAchievementProgress('combo_3x', gameState.comboCount);
    }
    
    // Check for level achievements
    if (gameState.level >= 5) {
      playerCubit.updateAchievementProgress('level_5', 1);
    }
    
    // Check for lines cleared achievements
    if (gameState.linesCleared >= 10) {
      playerCubit.updateAchievementProgress('lines_10', gameState.linesCleared);
    }
  }

  void _showAchievementUnlock(Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.emoji_events_rounded,
              color: AppColors.warning,
              size: 32,
            ),
            SizedBox(width: 12),
            Text(
              'Achievement Unlocked!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            if (achievement.coinReward > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${achievement.coinReward} coins',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PlayerCubit>().markAchievementsSeen();
            },
            child: const Text(
              'Awesome!',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCoinsEarned(int coins) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.monetization_on_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Earned $coins coins!'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorAndNavigateBack(String error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showErrorSnackBar(error);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.read<UICubit>().navigateToPage(AppPage.mainMenu);
        }
      });
    });
  }
}