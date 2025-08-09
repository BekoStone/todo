// File: lib/presentation/pages/game_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flame/game.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import '../widgets/game/game_hud.dart';
import '../widgets/game/game_board.dart';
import '../widgets/game/power_up_panel.dart';
import '../widgets/overlays/game_over_overlay.dart';
import '../widgets/overlays/pause_overlay.dart';
import '../flame/box_hooks_game.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/responsive_utils.dart';

class GamePage extends StatefulWidget {
  final GameDifficulty? difficulty;
  final String? sessionId;

  const GamePage({
    super.key,
    this.difficulty,
    this.sessionId,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  late BoxHooksGame _game;
  late AnimationController _transitionController;
  late Animation<double> _fadeAnimation;
  
  bool _isGameInitialized = false;
  bool _showDebugOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _initializeGame();
  }

  void _initializeAnimations() {
    _transitionController = AnimationController(
      duration: AppConstants.mediumAnimationDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));
    
    _transitionController.forward();
  }

  void _initializeGame() async {
    try {
      _game = BoxHooksGame();
      await _game.onLoad();
      
      setState(() {
        _isGameInitialized = true;
      });

      // Start game with specified difficulty or load existing session
      if (widget.sessionId != null) {
        context.read<GameCubit>().loadGame(widget.sessionId!);
      } else {
        context.read<GameCubit>().startNewGame(
          difficulty: widget.difficulty ?? GameDifficulty.normal,
        );
      }

    } catch (e) {
      _handleGameInitializationError(e);
    }
  }

  void _handleGameInitializationError(dynamic error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Game Error'),
          ],
        ),
        content: Text('Failed to initialize game: $error'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<UICubit>().navigateToPage(AppPage.mainMenu);
            },
            child: const Text('Back to Menu'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeGame();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listener: (context, gameState) {
        _handleGameStateChanges(gameState);
      },
      child: Scaffold(
        backgroundColor: AppColors.gameBackground,
        body: SafeArea(
          child: _isGameInitialized
              ? _buildGameInterface()
              : _buildLoadingScreen(),
        ),
      ),
    );
  }

  Widget _buildGameInterface() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, gameState) {
        return ResponsiveUtils.buildResponsiveWidget(
          context: context,
          mobile: _buildMobileGameLayout(gameState),
          tablet: _buildTabletGameLayout(gameState),
          desktop: _buildDesktopGameLayout(gameState),
        );
      },
    );
  }

  Widget _buildMobileGameLayout(GameState gameState) {
    return Stack(
      children: [
        // Game background
        _buildGameBackground(),
        
        // Main game content
        Column(
          children: [
            // Game HUD
            GameHUD(
              score: gameState.score,
              level: gameState.level,
              combo: gameState.comboCount,
              coins: context.read<PlayerCubit>().state.playerStats?.totalCoins ?? 0,
              onPause: _pauseGame,
              onSettings: _showSettings,
            ),
            
            // Game board
            Expanded(
              flex: 3,
              child: Center(
                child: GameBoard(
                  gridState: gameState.gridState,
                  activeBlocks: gameState.activeBlocks,
                  onBlockPlaced: _onBlockPlaced,
                  gridFillPercentage: gameState.gridFillPercentage,
                ),
              ),
            ),
            
            // Power-up panel
            PowerUpPanel(
              inventory: gameState.powerUpInventory,
              onPowerUpUsed: _onPowerUpUsed,
              isActive: gameState.isPowerUpActive,
              activePowerUp: gameState.activePowerUp,
            ),
            
            const SizedBox(height: 16),
          ],
        ),
        
        // Overlays
        _buildGameOverlays(gameState),
        
        // Debug overlay
        if (_showDebugOverlay) _buildDebugOverlay(gameState),
      ],
    );
  }

  Widget _buildTabletGameLayout(GameState gameState) {
    return Stack(
      children: [
        _buildGameBackground(),
        
        Row(
          children: [
            // Left panel - HUD and Power-ups
            SizedBox(
              width: 280,
              child: Column(
                children: [
                  GameHUD(
                    score: gameState.score,
                    level: gameState.level,
                    combo: gameState.comboCount,
                    coins: context.read<PlayerCubit>().state.playerStats?.totalCoins ?? 0,
                    onPause: _pauseGame,
                    onSettings: _showSettings,
                    isCompact: true,
                  ),
                  
                  const Spacer(),
                  
                  PowerUpPanel(
                    inventory: gameState.powerUpInventory,
                    onPowerUpUsed: _onPowerUpUsed,
                    isActive: gameState.isPowerUpActive,
                    activePowerUp: gameState.activePowerUp,
                    isVertical: true,
                  ),
                ],
              ),
            ),
            
            // Center - Game board
            Expanded(
              child: Center(
                child: GameBoard(
                  gridState: gameState.gridState,
                  activeBlocks: gameState.activeBlocks,
                  onBlockPlaced: _onBlockPlaced,
                  gridFillPercentage: gameState.gridFillPercentage,
                ),
              ),
            ),
            
            // Right panel - Stats and info
            SizedBox(
              width: 200,
              child: _buildSidePanel(gameState),
            ),
          ],
        ),
        
        _buildGameOverlays(gameState),
        if (_showDebugOverlay) _buildDebugOverlay(gameState),
      ],
    );
  }

  Widget _buildDesktopGameLayout(GameState gameState) {
    return Stack(
      children: [
        _buildGameBackground(),
        
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Row(
              children: [
                // Left panel
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      GameHUD(
                        score: gameState.score,
                        level: gameState.level,
                        combo: gameState.comboCount,
                        coins: context.read<PlayerCubit>().state.playerStats?.totalCoins ?? 0,
                        onPause: _pauseGame,
                        onSettings: _showSettings,
                        isCompact: false,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildGameStats(gameState),
                      
                      const Spacer(),
                      
                      PowerUpPanel(
                        inventory: gameState.powerUpInventory,
                        onPowerUpUsed: _onPowerUpUsed,
                        isActive: gameState.isPowerUpActive,
                        activePowerUp: gameState.activePowerUp,
                        isVertical: true,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 40),
                
                // Center - Game board
                Expanded(
                  child: Center(
                    child: GameBoard(
                      gridState: gameState.gridState,
                      activeBlocks: gameState.activeBlocks,
                      onBlockPlaced: _onBlockPlaced,
                      gridFillPercentage: gameState.gridFillPercentage,
                    ),
                  ),
                ),
                
                const SizedBox(width: 40),
                
                // Right panel
                SizedBox(
                  width: 250,
                  child: _buildSidePanel(gameState),
                ),
              ],
            ),
          ),
        ),
        
        _buildGameOverlays(gameState),
        if (_showDebugOverlay) _buildDebugOverlay(gameState),
      ],
    );
  }

  Widget _buildGameBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gameBackground,
            AppColors.primaryBlue,
            AppColors.primaryPurple,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildSidePanel(GameState gameState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNextBlocksPreview(gameState),
          const SizedBox(height: 20),
          _buildGameProgress(gameState),
          const Spacer(),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildGameStats(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Game Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow('Lines Cleared', gameState.linesCleared.toString()),
          _buildStatRow('Combo', '${gameState.comboCount}x'),
          _buildStatRow('Streak', '${gameState.streakCount}x'),
          _buildStatRow('Grid Fill', '${gameState.gridFillPercentage.toStringAsFixed(1)}%'),
          _buildStatRow('Time', _formatDuration(gameState.sessionDuration)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextBlocksPreview(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Blocks',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // Would show preview of upcoming blocks
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                'Preview',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameProgress(GameState gameState) {
    final progressToNextLevel = (gameState.linesCleared % 10) / 10.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Level Progress',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressToNextLevel,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text(
            '${(progressToNextLevel * 100).round()}% to Level ${gameState.level + 1}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _saveGame,
          icon: const Icon(Icons.save, size: 16),
          label: const Text('Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _restartGame,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Restart'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverlays(GameState gameState) {
    return Stack(
      children: [
        // Pause overlay
        if (gameState.isPaused)
          PauseOverlay(
            onResume: _resumeGame,
            onRestart: _restartGame,
            onMainMenu: _exitToMainMenu,
            onSettings: _showSettings,
          ),
        
        // Game over overlay
        if (gameState.isGameOver)
          GameOverOverlay(
            finalScore: gameState.score,
            level: gameState.level,
            linesCleared: gameState.linesCleared,
            sessionDuration: gameState.sessionDuration,
            canUndo: gameState.canUndo,
            onRestart: _restartGame,
            onMainMenu: _exitToMainMenu,
            onUndo: gameState.canUndo ? _undoLastMove : null,
          ),
        
        // Loading overlay
        if (gameState.isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDebugOverlay(GameState gameState) {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FPS: 60', style: _debugTextStyle),
            Text('State: ${gameState.status.name}', style: _debugTextStyle),
            Text('Blocks: ${gameState.activeBlocks.length}', style: _debugTextStyle),
            Text('Fill: ${gameState.gridFillPercentage.toStringAsFixed(1)}%', style: _debugTextStyle),
            Text('Memory: 45MB', style: _debugTextStyle),
          ],
        ),
      ),
    );
  }

  TextStyle get _debugTextStyle => const TextStyle(
    fontSize: 10,
    color: Colors.white,
    fontFamily: 'monospace',
  );

  Widget _buildLoadingScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.primaryPurple],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'Loading Game...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Game state change handler
  void _handleGameStateChanges(GameState gameState) {
    // Handle game over
    if (gameState.isGameOver && gameState.currentSession != null) {
      _processGameCompletion(gameState);
    }
    
    // Handle errors
    if (gameState.hasError) {
      _showErrorSnackBar(gameState.errorMessage!);
    }
    
    // Handle achievements
    _checkForAchievements(gameState);
  }

  void _processGameCompletion(GameState gameState) {
    context.read<PlayerCubit>().processGameCompletion(
      finalScore: gameState.score,
      level: gameState.level,
      linesCleared: gameState.linesCleared,
      blocksPlaced: 0, // Would track this during gameplay
      gameDuration: gameState.sessionDuration,
      usedUndo: gameState.remainingUndos < 3,
    );
  }

  void _checkForAchievements(GameState gameState) {
    // Check for score-based achievements
    if (gameState.score >= 1000) {
      context.read<PlayerCubit>().updateAchievementProgress(
        achievementId: 'score_1000',
        progress: 1,
      );
    }
    
    // Check for combo achievements
    if (gameState.comboCount >= 3) {
      context.read<PlayerCubit>().updateAchievementProgress(
        achievementId: 'combo_3x',
        progress: gameState.comboCount,
      );
    }
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

  // Game action handlers
  void _onBlockPlaced(int blockId, int row, int col) {
    final gameState = context.read<GameCubit>().state;
    final block = gameState.activeBlocks.firstWhere((b) => b.id == blockId);
    context.read<GameCubit>().placeBlock(block, row, col);
  }

  void _onPowerUpUsed(PowerUpType powerUpType) {
    context.read<GameCubit>().usePowerUp(powerUpType);
  }

  void _pauseGame() {
    context.read<GameCubit>().pauseGame();
  }

  void _resumeGame() {
    context.read<GameCubit>().resumeGame();
  }

  void _restartGame() {
    context.read<GameCubit>().restartGame();
  }

  void _saveGame() {
    context.read<GameCubit>().saveGame();
    _showSuccessSnackBar('Game saved successfully');
  }

  void _undoLastMove() {
    // Implement undo logic
    _showInfoSnackBar('Undo functionality coming soon');
  }

  void _exitToMainMenu() {
    context.read<UICubit>().navigateToPage(AppPage.mainMenu);
  }

  void _showSettings() {
    context.read<UICubit>().navigateToPage(AppPage.settings);
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
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        if (context.read<GameCubit>().state.isPlaying) {
          _pauseGame();
        }
        break;
      case AppLifecycleState.resumed:
        // Game will remain paused until user manually resumes
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transitionController.dispose();
    _game.onRemove();
    super.dispose();
  }
}