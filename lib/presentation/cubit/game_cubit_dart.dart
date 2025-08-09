import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/constants/game_constants.dart';
import 'package:puzzle_box/core/state/game_state.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import 'package:puzzle_box/domain/usecases/game_usecases.dart';

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
    GameMode mode = GameMode.classic,
  }) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));
      developer.log('Starting new game with difficulty: ${difficulty.name}', name: 'GameCubit');
      
      // Create new game session
      final session = await _gameUseCases.createGameSession(
        difficulty: difficulty,
        mode: mode,
        sessionId: sessionId,
      );
      
      // Initialize game state
      final newState = GameState.initial(
        difficulty: difficulty,
        mode: mode,
      ).copyWith(
        status: GameStateStatus.playing,
        currentSession: session,
      );
      
      emit(newState);
      
      // Start game timer and tracking
      _gameStartTime = DateTime.now();
      _moveCount = 0;
      _startGameTimer();
      _startAutoSave();
      
      // Clear performance data
      _frameTimes.clear();
      _lastFrameTime = DateTime.now();
      
      developer.log('New game started successfully', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to start new game: $e', name: 'GameCubit');
      emit(state.copyWithError('Failed to start new game: $e'));
    }
  }

  /// Load an existing game session
  Future<void> loadGame(String sessionId) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));
      developer.log('Loading game session: $sessionId', name: 'GameCubit');
      
      final session = await _gameUseCases.loadGameSession(sessionId);
      if (session == null) {
        throw Exception('Game session not found');
      }
      
      // Restore game state from session
      final loadedState = await _gameUseCases.loadGameState(sessionId);
      if (loadedState == null) {
        throw Exception('Game state not found');
      }
      
      emit(loadedState.copyWith(
        status: GameStateStatus.playing,
        currentSession: session,
      ));
      
      _gameStartTime = session.startTime;
      _startGameTimer();
      _startAutoSave();
      
      developer.log('Game loaded successfully', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to load game: $e', name: 'GameCubit');
      emit(state.copyWithError('Failed to load game: $e'));
    }
  }

  /// Pause the current game
  void pauseGame() {
    if (state.isPlaying) {
      emit(state.copyWithPaused(paused: true));
      _stopGameTimer();
      developer.log('Game paused', name: 'GameCubit');
    }
  }

  /// Resume the paused game
  void resumeGame() {
    if (state.isPaused) {
      emit(state.copyWithPlaying());
      _startGameTimer();
      developer.log('Game resumed', name: 'GameCubit');
    }
  }

  /// End the current game
  void endGame({String? reason}) async {
    if (state.isPlaying || state.isPaused) {
      try {
        final session = state.currentSession;
        if (session != null) {
          // Update session with final data
          final finalSession = session.copyWith(
            endTime: DateTime.now(),
            finalScore: state.score,
            isCompleted: true,
          );
          
          emit(state.copyWithGameOver(session: finalSession));
          
          // Save final game data
          await _gameUseCases.saveGameSession(finalSession);
          
          // Stop all timers
          _stopGameTimer();
          _stopAutoSave();
          _comboTimer?.cancel();
          
          developer.log('Game ended - Score: ${state.score}, Reason: $reason', name: 'GameCubit');
        }
      } catch (e) {
        developer.log('Error ending game: $e', name: 'GameCubit');
        emit(state.copyWithError('Failed to end game properly'));
      }
    }
  }

  // ========================================
  // GAME MECHANICS
  // ========================================

  /// Place a block on the game board
  Future<void> placeBlock(BlockEntity block, int row, int col) async {
    if (!state.isPlaying) return;
    
    try {
      _recordMove();
      
      // Validate placement
      if (!_canPlaceBlock(block, row, col)) {
        developer.log('Invalid block placement at ($row, $col)', name: 'GameCubit');
        return;
      }
      
      // Update grid with new block
      final updatedGrid = _updateGridWithBlock(state.grid, block, row, col);
      
      // Check for completed lines
      final completedLines = _findCompletedLines(updatedGrid);
      
      // Calculate score
      final scoreData = _calculateScore(block, completedLines);
      
      // Update state
      emit(state.copyWith(
        grid: updatedGrid,
        score: state.score + scoreData['score']!,
        linesCleared: state.linesCleared + completedLines.length,
        comboCount: scoreData['combo'] as int,
        maxCombo: math.max(state.maxCombo, scoreData['combo'] as int),
        lastMoveTime: DateTime.now(),
      ));
      
      // Check for level progression
      _checkLevelProgression();
      
      // Update achievements
      await _checkAchievements();
      
      developer.log('Block placed at ($row, $col), Score: +${scoreData['score']}', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Error placing block: $e', name: 'GameCubit');
    }
  }

  /// Use undo move
  void undoMove() {
    if (state.canUndo && state.remainingUndos > 0) {
      // Implementation would restore previous state
      emit(state.copyWith(
        remainingUndos: state.remainingUndos - 1,
        canUndo: state.remainingUndos > 1,
      ));
      
      developer.log('Undo used, remaining: ${state.remainingUndos - 1}', name: 'GameCubit');
    }
  }

  /// Select a block for interaction
  void selectBlock(BlockEntity block) {
    // Update active blocks
    final updatedBlocks = state.activeBlocks.map((b) => 
      b.id == block.id ? b.activate() : b.deactivate()
    ).toList();
    
    emit(state.copyWith(activeBlocks: updatedBlocks));
  }

  /// Start block drag operation
  void startBlockDrag(BlockEntity block) {
    selectBlock(block);
    developer.log('Started dragging block: ${block.id}', name: 'GameCubit');
  }

  /// Update block position during drag
  void updateBlockPosition(BlockEntity block, int row, int col) {
    // Real-time position update for visual feedback
    final updatedBlocks = state.activeBlocks.map((b) => 
      b.id == block.id ? b.copyWith(position: Position(col, row)) : b
    ).toList();
    
    emit(state.copyWith(activeBlocks: updatedBlocks));
  }

  /// Complete block drag operation
  void completeDrag(BlockEntity block, int row, int col) {
    placeBlock(block, row, col);
    developer.log('Completed dragging block: ${block.id}', name: 'GameCubit');
  }

  // ========================================
  // PRIVATE HELPER METHODS
  // ========================================

  /// Check if block can be placed at position
  bool _canPlaceBlock(BlockEntity block, int row, int col) {
    return block.canBePlacedAt(Position(col, row), state.grid);
  }

  /// Update grid with placed block
  List<List<bool>> _updateGridWithBlock(List<List<bool>> grid, BlockEntity block, int row, int col) {
    final newGrid = grid.map((row) => List<bool>.from(row)).toList();
    final blockPositions = block.copyWith(position: Position(col, row)).occupiedPositions;
    
    for (final pos in blockPositions) {
      if (pos.y >= 0 && pos.y < newGrid.length && pos.x >= 0 && pos.x < newGrid[0].length) {
        newGrid[pos.y][pos.x] = true;
      }
    }
    
    return newGrid;
  }

  /// Find completed lines in grid
  List<int> _findCompletedLines(List<List<bool>> grid) {
    final completedRows = <int>[];
    final completedCols = <int>[];
    
    // Check rows
    for (int row = 0; row < grid.length; row++) {
      if (grid[row].every((cell) => cell)) {
        completedRows.add(row);
      }
    }
    
    // Check columns
    for (int col = 0; col < grid[0].length; col++) {
      bool columnFull = true;
      for (int row = 0; row < grid.length; row++) {
        if (!grid[row][col]) {
          columnFull = false;
          break;
        }
      }
      if (columnFull) {
        completedCols.add(col);
      }
    }
    
    return [...completedRows, ...completedCols];
  }

  /// Calculate score for move
  Map<String, int> _calculateScore(BlockEntity block, List<int> completedLines) {
    final baseScore = block.shape.length * block.shape[0].length * 10;
    final lineBonus = completedLines.length * 100;
    final comboBonus = state.comboCount * 50;
    
    final totalScore = baseScore + lineBonus + comboBonus;
    final newCombo = completedLines.isNotEmpty ? state.comboCount + 1 : 0;
    
    return {
      'score': totalScore,
      'combo': newCombo,
    };
  }

  /// Check for level progression
  void _checkLevelProgression() {
    final newLevel = (state.linesCleared ~/ 10) + 1;
    if (newLevel > state.level) {
      emit(state.copyWith(level: newLevel));
      developer.log('Level up! New level: $newLevel', name: 'GameCubit');
    }
  }

  /// Check for achievements
  Future<void> _checkAchievements() async {
    try {
      await _achievementUseCases.checkGameAchievements(
        score: state.score,
        level: state.level,
        linesCleared: state.linesCleared,
        comboCount: state.comboCount,
      );
    } catch (e) {
      developer.log('Error checking achievements: $e', name: 'GameCubit');
    }
  }

  /// Record move for statistics
  void _recordMove() {
    _moveCount++;
    _lastMoveTime = DateTime.now();
    
    // Record frame time for performance tracking
    if (_lastFrameTime != null) {
      final frameTime = DateTime.now().difference(_lastFrameTime!);
      _frameTimes.add(frameTime);
      
      // Keep only recent frame times
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
    }
    _lastFrameTime = DateTime.now();
  }

  /// Start game timer
  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPlaying) {
        final duration = DateTime.now().difference(_gameStartTime ?? DateTime.now());
        emit(state.copyWith(sessionDuration: duration));
      }
    });
  }

  /// Stop game timer
  void _stopGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  /// Setup auto-save functionality
  void _setupAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _autoSaveGame();
    });
  }

  /// Start auto-save
  void _startAutoSave() {
    _setupAutoSave();
  }

  /// Stop auto-save
  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Auto-save current game
  Future<void> _autoSaveGame() async {
    if (state.isPlaying && state.currentSession != null) {
      try {
        await _gameUseCases.saveGameState(state);
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
      'sessionDuration': state.sessionDuration?.inSeconds ?? 0,
      'moveCount': _moveCount,
      'remainingUndos': state.remainingUndos,
      'difficulty': state.difficulty.name,
      'mode': state.mode.name,
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
        await _gameUseCases.saveGameState(state);
        return true;
      } catch (e) {
        developer.log('Failed to force save game: $e', name: 'GameCubit');
        return false;
      }
    }
    return false;
  }
}