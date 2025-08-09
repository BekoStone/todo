import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/state/game_state.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/usecases/game_usecases.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';

/// GameCubit manages the core game state and logic coordination.
/// Handles game sessions, scoring, level progression, and game flow.
/// Follows Clean Architecture principles with proper error handling.
class GameCubit extends Cubit<GameState> {
  final GameUseCases _gameUseCases;
  final AchievementUseCases _achievementUseCases;
  
  // Timers for game management
  Timer? _gameTimer;
  Timer? _autoSaveTimer;
  Timer? _comboTimer;
  
  // Performance tracking
  DateTime? _lastFrameTime;
  final List<Duration> _frameTimes = [];
  
  // Game state tracking
  DateTime? _gameStartTime;
  DateTime? _lastMoveTime;
  int _moveCount = 0;

  GameCubit(
    this._gameUseCases,
    this._achievementUseCases,
  ) : super(const GameState()) {
    _initializeGameCubit();
  }

  @override
  Future<void> close() async {
    _gameTimer?.cancel();
    _autoSaveTimer?.cancel();
    _comboTimer?.cancel();
    await super.close();
  }

  /// Initialize the game cubit with default settings
  void _initializeGameCubit() {
    developer.log('GameCubit initialized', name: 'GameCubit');
    _setupAutoSave();
  }

  // ========================================
  // GAME FLOW MANAGEMENT
  // ========================================

  /// Start a new game with optional difficulty setting
  Future<void> startNewGame({
    GameDifficulty difficulty = GameDifficulty.normal,
    String? sessionId,
    bool continueFromSave = false,
  }) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));
      developer.log('Starting new game with difficulty: ${difficulty.name}', name: 'GameCubit');
      
      // Create new game session
      final gameSession = await _gameUseCases.createNewGame(difficulty: difficulty);
      
      // Generate initial blocks
      final initialBlocks = _gameUseCases.generateNextBlocks(gameSession);
      
      // Initialize game state
      _gameStartTime = DateTime.now();
      _lastMoveTime = DateTime.now();
      _moveCount = 0;
      
      emit(state.copyWith(
        status: GameStateStatus.playing,
        currentSession: gameSession,
        score: 0,
        level: 1,
        linesCleared: 0,
        comboCount: 0,
        maxCombo: 0,
        streakCount: 0,
        maxStreak: 0,
        activeBlocks: initialBlocks,
        grid: List.generate(
          AppConstants.defaultGridSize,
          (_) => List.filled(AppConstants.defaultGridSize, 0),
        ),
        sessionDuration: Duration.zero,
        remainingUndos: AppConstants.maxUndoCount,
        remainingHints: AppConstants.maxHintCount,
        errorMessage: null,
        sessionData: gameSession.statistics,
        isFirstGame: gameSession.isFirstGame,
        lastMoveTime: _lastMoveTime,
        powerUpCounts: gameSession.remainingPowerUps,
      ));
      
      _startGameTimer();
      developer.log('New game started successfully', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to start new game: $e', name: 'GameCubit');
      emit(state.copyWith(
        status: GameStateStatus.error,
        errorMessage: 'Failed to start new game: $e',
      ));
    }
  }

  /// Load a saved game session
  Future<void> loadSavedGame() async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));
      developer.log('Loading saved game', name: 'GameCubit');
      
      final savedGame = await _gameUseCases.loadSavedGame();
      
      if (savedGame != null) {
        _gameStartTime = savedGame.createdAt;
        _lastMoveTime = savedGame.updatedAt;
        
        emit(state.copyWith(
          status: GameStateStatus.playing,
          currentSession: savedGame,
          score: savedGame.currentScore,
          level: savedGame.currentLevel,
          linesCleared: savedGame.linesCleared,
          comboCount: savedGame.comboCount,
          maxCombo: savedGame.maxCombo,
          grid: savedGame.gridState,
          sessionDuration: savedGame.actualPlayTime,
          remainingUndos: savedGame.remainingPowerUps['undo'] ?? 0,
          remainingHints: savedGame.remainingPowerUps['hint'] ?? 0,
          sessionData: savedGame.statistics,
          lastMoveTime: savedGame.updatedAt,
          powerUpCounts: savedGame.remainingPowerUps,
        ));
        
        _startGameTimer();
        developer.log('Saved game loaded successfully', name: 'GameCubit');
      } else {
        // No saved game found, start new game
        await startNewGame();
      }
    } catch (e) {
      developer.log('Failed to load saved game: $e', name: 'GameCubit');
      emit(state.copyWith(
        status: GameStateStatus.error,
        errorMessage: 'Failed to load saved game: $e',
      ));
    }
  }

  /// Pause the current game
  void pauseGame() {
    if (state.isPlaying) {
      _stopGameTimer();
      emit(state.copyWith(status: GameStateStatus.paused));
      developer.log('Game paused', name: 'GameCubit');
    }
  }

  /// Resume the paused game
  void resumeGame() {
    if (state.isPaused) {
      _startGameTimer();
      emit(state.copyWith(status: GameStateStatus.playing));
      developer.log('Game resumed', name: 'GameCubit');
    }
  }

  /// End the current game
  Future<void> endGame({bool userInitiated = true}) async {
    if (state.isPlaying || state.isPaused) {
      _stopGameTimer();
      _stopAutoSave();
      
      // Update session with final data
      final updatedSession = state.currentSession?.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
        currentScore: state.score,
        currentLevel: state.level,
        linesCleared: state.linesCleared,
        maxCombo: state.maxCombo,
        playTime: state.sessionDuration,
      );
      
      emit(state.copyWith(
        status: GameStateStatus.gameOver,
        currentSession: updatedSession,
      ));
      
      // Save final session
      if (updatedSession != null) {
        await _gameUseCases.saveGame(updatedSession);
        await _gameUseCases.saveFinalScore(
          updatedSession.sessionId,
          state.score,
          {
            'level': state.level,
            'linesCleared': state.linesCleared,
            'maxCombo': state.maxCombo,
            'sessionDuration': state.sessionDuration.inSeconds,
            'moveCount': _moveCount,
            'userInitiated': userInitiated,
          },
        );
      }
      
      developer.log('Game ended - Score: ${state.score}, Level: ${state.level}', name: 'GameCubit');
    }
  }

  /// Restart the current game
  Future<void> restartGame() async {
    final difficulty = state.currentSession?.difficulty ?? GameDifficulty.normal;
    await startNewGame(difficulty: difficulty);
  }

  // ========================================
  // GAME ACTIONS
  // ========================================

  /// Place a block on the grid
  Future<void> placeBlock(Block block, int gridRow, int gridCol) async {
    if (!state.isPlaying) return;

    try {
      // Validate placement using use cases
      final updatedSession = _gameUseCases.placeBlock(
        state.currentSession!,
        block,
        gridRow,
        gridCol,
      );

      // Check for line clears
      final (clearedRows, clearedCols, lineScore) = _gameUseCases.checkAndClearLines(updatedSession);
      
      // Update game state
      var newSession = updatedSession;
      var newScore = state.score + _calculatePlacementScore(block);
      var newCombo = state.comboCount;
      var newStreak = state.streakCount;
      
      // Handle line clears
      if (clearedRows.isNotEmpty || clearedCols.isNotEmpty) {
        newSession = _gameUseCases.clearLines(newSession, clearedRows, clearedCols, lineScore);
        newScore += lineScore;
        newCombo += 1;
        newStreak += 1;
        
        // Reset combo timer
        _resetComboTimer();
      } else {
        // Reset combo if no lines cleared
        newCombo = 0;
      }
      
      // Update move tracking
      _moveCount++;
      _lastMoveTime = DateTime.now();
      
      // Calculate new level
      final newLevel = _calculateLevel(state.linesCleared + clearedRows.length + clearedCols.length);
      
      // Remove placed block from active blocks
      final remainingBlocks = List<Block>.from(state.activeBlocks)..remove(block);
      
      // Generate new blocks if needed
      if (remainingBlocks.length < 2) {
        final newBlocks = _gameUseCases.generateNextBlocks(newSession);
        remainingBlocks.addAll(newBlocks);
      }
      
      // Check for game over
      final isGameOver = _gameUseCases.isGameOver(newSession, remainingBlocks);
      
      emit(state.copyWith(
        currentSession: newSession,
        score: newScore,
        level: newLevel,
        linesCleared: state.linesCleared + clearedRows.length + clearedCols.length,
        comboCount: newCombo,
        maxCombo: math.max(state.maxCombo, newCombo),
        streakCount: newStreak,
        maxStreak: math.max(state.maxStreak, newStreak),
        activeBlocks: remainingBlocks,
        grid: newSession.gridState,
        lastMoveTime: _lastMoveTime,
        status: isGameOver ? GameStateStatus.gameOver : GameStateStatus.playing,
      ));
      
      // Auto-save after significant progress
      if (_moveCount % 5 == 0) {
        await _autoSaveGame();
      }
      
      // End game if no moves available
      if (isGameOver) {
        await endGame(userInitiated: false);
      }
      
      developer.log('Block placed: +$newScore points', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to place block: $e', name: 'GameCubit');
      emit(state.copyWith(
        errorMessage: 'Failed to place block: $e',
      ));
    }
  }

  /// Use undo functionality
  Future<void> useUndo() async {
    if (!state.isPlaying || state.remainingUndos <= 0) return;
    
    try {
      // Implement undo logic here
      // For now, just decrement undo count
      emit(state.copyWith(
        remainingUndos: state.remainingUndos - 1,
      ));
      
      developer.log('Undo used, remaining: ${state.remainingUndos}', name: 'GameCubit');
    } catch (e) {
      developer.log('Failed to use undo: $e', name: 'GameCubit');
    }
  }

  /// Use hint functionality
  Future<void> useHint() async {
    if (!state.isPlaying || state.remainingHints <= 0) return;
    
    try {
      final hint = _gameUseCases.getGameHint(state.currentSession!, state.activeBlocks);
      
      if (hint != null) {
        emit(state.copyWith(
          remainingHints: state.remainingHints - 1,
        ));
        
        // Emit hint data through state or separate mechanism
        developer.log('Hint provided: ${hint['reason']}', name: 'GameCubit');
      }
    } catch (e) {
      developer.log('Failed to use hint: $e', name: 'GameCubit');
    }
  }

  /// Use power-up
  Future<void> usePowerUp(String powerUpType) async {
    if (!state.isPlaying) return;
    
    final count = state.powerUpCounts[powerUpType] ?? 0;
    if (count <= 0) return;
    
    try {
      // Decrement power-up count
      final updatedCounts = Map<String, int>.from(state.powerUpCounts);
      updatedCounts[powerUpType] = count - 1;
      
      emit(state.copyWith(powerUpCounts: updatedCounts));
      
      developer.log('Power-up used: $powerUpType', name: 'GameCubit');
    } catch (e) {
      developer.log('Failed to use power-up: $e', name: 'GameCubit');
    }
  }

  // ========================================
  // SCORING & PROGRESSION
  // ========================================

  /// Calculate score for placing a block
  int _calculatePlacementScore(Block block) {
    final blockSize = block.shape.expand((row) => row).where((cell) => cell == 1).length;
    return blockSize * 10 * state.level;
  }

  /// Calculate level based on lines cleared
  int _calculateLevel(int totalLinesCleared) {
    return math.max(1, (totalLinesCleared ~/ 10) + 1);
  }

  /// Reset combo timer
  void _resetComboTimer() {
    _comboTimer?.cancel();
    _comboTimer = Timer(const Duration(seconds: 3), () {
      if (state.isPlaying) {
        emit(state.copyWith(comboCount: 0));
      }
    });
  }

  // ========================================
  // TIMER MANAGEMENT
  // ========================================

  /// Start the game timer
  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPlaying && _gameStartTime != null) {
        final elapsed = DateTime.now().difference(_gameStartTime!);
        emit(state.copyWith(sessionDuration: elapsed));
      }
    });
  }

  /// Stop the game timer
  void _stopGameTimer() {
    _gameTimer?.cancel();
  }

  /// Setup auto-save functionality
  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (state.isPlaying) {
        _autoSaveGame();
      }
    });
  }

  /// Stop auto-save
  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
  }

  /// Auto-save current game state
  Future<void> _autoSaveGame() async {
    if (state.currentSession != null) {
      try {
        await _gameUseCases.autoSaveGame(state.currentSession!);
        developer.log('Game auto-saved', name: 'GameCubit');
      } catch (e) {
        developer.log('Auto-save failed: $e', name: 'GameCubit');
      }
    }
  }

  // ========================================
  // GAME DATA & STATISTICS
  // ========================================

  /// Get current game statistics
  Map<String, dynamic> getGameStatistics() {
    return {
      'score': state.score,
      'level': state.level,
      'linesCleared': state.linesCleared,
      'maxCombo': state.maxCombo,
      'maxStreak': state.maxStreak,
      'sessionDuration': state.sessionDuration.inSeconds,
      'moveCount': _moveCount,
      'remainingUndos': state.remainingUndos,
      'remainingHints': state.remainingHints,
      'isFirstGame': state.isFirstGame,
      'difficulty': state.currentSession?.difficulty.name,
    };
  }

  /// Check if current score is a high score
  Future<bool> isHighScore() async {
    try {
      return await _gameUseCases.isHighScore(state.score);
    } catch (e) {
      developer.log('Failed to check high score: $e', name: 'GameCubit');
      return false;
    }
  }

  /// Get game performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'averageFrameTime': _frameTimes.isNotEmpty 
        ? _frameTimes.map((d) => d.inMicroseconds).reduce((a, b) => a + b) / _frameTimes.length / 1000
        : 0.0,
      'frameCount': _frameTimes.length,
      'lastFrameTime': _lastFrameTime?.millisecondsSinceEpoch,
      'gameUptime': _gameStartTime != null 
        ? DateTime.now().difference(_gameStartTime!).inSeconds 
        : 0,
    };
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Clear any error state
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Reset game state to initial
  void resetToInitial() {
    _stopGameTimer();
    _stopAutoSave();
    _comboTimer?.cancel();
    
    emit(const GameState());
    developer.log('Game state reset to initial', name: 'GameCubit');
  }

  /// Get current game session ID
  String? getCurrentSessionId() {
    return state.currentSession?.sessionId;
  }

  /// Check if game can be saved
  bool canSaveGame() {
    return state.isPlaying && state.currentSession != null;
  }

  /// Force save current game
  Future<bool> forceSaveGame() async {
    if (canSaveGame()) {
      try {
        await _gameUseCases.saveGame(state.currentSession!);
        return true;
      } catch (e) {
        developer.log('Failed to force save game: $e', name: 'GameCubit');
        return false;
      }
    }
    return false;
  }
}