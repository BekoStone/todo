import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:puzzle_box/data/models/game_state_model.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import 'package:puzzle_box/domain/usecases/game_usecases.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';


/// GameCubit manages the core game state and logic coordination.
/// Handles game sessions, scoring, level progression, and game flow.
/// Follows Clean Architecture principles with proper error handling.
class GameCubit extends Cubit<GameStateModel> {
  final GameUseCases _gameUseCases;
  final AchievementUseCases _achievementUseCases;
  
  // Timers for game management
  Timer? _gameTimer;
  Timer? _autoSaveTimer;
  
  // Performance tracking
  DateTime? _lastFrameTime;
  List<Duration> _frameTimes = [];

  GameCubit(
    this._gameUseCases,
    this._achievementUseCases,
  ) : super( GameState()) {
    _initializeGameCubit();
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
  }) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));
      developer.log('Starting new game with difficulty: $difficulty', name: 'GameCubit');
      
      // Create new game session
      final session = await _gameUseCases.createGameSession(
        difficulty: difficulty,
        sessionId: sessionId,
      );
      
      // Initialize game state
      emit(state.copyWith(
        status: GameStateStatus.playing,
        currentSession: session,
        score: 0,
        level: 1,
        linesCleared: 0,
        comboCount: 0,
        sessionDuration: Duration.zero,
        remainingUndos: AppConstants.maxUndoCount,
        remainingHints: AppConstants.maxHints,
        gameGrid: _createEmptyGrid(),
        activeBlocks: [],
        sessionData: GameSessionData.initial(),
        lastActionTime: DateTime.now(),
        errorMessage: null,
      ));
      
      // Start game timer
      _startGameTimer();
      
      // Check for tutorial
      if (session.isFirstGame) {
        emit(state.copyWith(showTutorial: true));
      }
      
      developer.log('New game started successfully', name: 'GameCubit');
      
    } catch (e, stackTrace) {
      developer.log('Failed to start new game: $e', name: 'GameCubit', stackTrace: stackTrace);
      emit(state.copyWith(
        status: GameStateStatus.error,
        errorMessage: 'Failed to start game: ${e.toString()}',
      ));
    }
  }

  /// Pause the current game
  void pauseGame() {
    if (state.status != GameStateStatus.playing) return;
    
    developer.log('Game paused', name: 'GameCubit');
    _stopGameTimer();
    
    emit(state.copyWith(
      status: GameStateStatus.paused,
      lastActionTime: DateTime.now(),
    ));
  }

  /// Resume the paused game
  void resumeGame() {
    if (state.status != GameStateStatus.paused) return;
    
    developer.log('Game resumed', name: 'GameCubit');
    _startGameTimer();
    
    emit(state.copyWith(
      status: GameStateStatus.playing,
      lastActionTime: DateTime.now(),
    ));
  }

  /// End the current game
  void endGame({bool userInitiated = false}) {
    if (!state.isPlaying && !state.isPaused) return;
    
    developer.log('Game ended (user initiated: $userInitiated)', name: 'GameCubit');
    _stopGameTimer();
    _stopAutoSave();
    
    emit(state.copyWith(
      status: GameStateStatus.gameOver,
      lastActionTime: DateTime.now(),
      sessionData: state.sessionData?.copyWith(
        endTime: DateTime.now(),
        wasCompleted: !userInitiated,
      ),
    ));
    
    // Process final score and achievements
    _processFinalScore();
  }

  /// Load an existing game session
  Future<void> loadGame(String sessionId) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));
      developer.log('Loading game session: $sessionId', name: 'GameCubit');
      
      final session = await _gameUseCases.loadGameSession(sessionId);
      
      emit(state.copyWith(
        status: GameStateStatus.playing,
        currentSession: session,
        score: session.currentScore,
        level: session.currentLevel,
        linesCleared: session.linesCleared,
        sessionDuration: session.playTime,
        gameGrid: session.gridState,
        lastActionTime: DateTime.now(),
      ));
      
      _startGameTimer();
      developer.log('Game loaded successfully', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to load game: $e', name: 'GameCubit');
      emit(state.copyWith(
        status: GameStateStatus.error,
        errorMessage: 'Failed to load game: ${e.toString()}',
      ));
    }
  }

  // ========================================
  // GAME ACTIONS
  // ========================================

  /// Place a block on the game grid
  Future<void> placeBlock(Block block, int row, int col) async {
    if (!state.isPlaying) return;
    
    try {
      // Validate placement
      if (!_canPlaceBlock(block, row, col)) {
        developer.log('Invalid block placement at ($row, $col)', name: 'GameCubit');
        return;
      }
      
      // Create new grid with placed block
      final newGrid = _placeBlockOnGrid(state.gameGrid, block, row, col);
      
      // Check for completed lines
      final completedLines = _findCompletedLines(newGrid);
      final clearedGrid = _clearCompletedLines(newGrid, completedLines);
      
      // Calculate score
      final scoreData = _calculateScore(
        placedBlock: true,
        linesCleared: completedLines.length,
        currentCombo: completedLines.isNotEmpty ? state.comboCount + 1 : 0,
      );
      
      // Update game state
      final updatedSessionData = state.sessionData?.copyWith(
        blocksPlaced: (state.sessionData?.blocksPlaced ?? 0) + 1,
        linesCleared: (state.sessionData?.linesCleared ?? 0) + completedLines.length,
        lastPlacementTime: DateTime.now(),
      );
      
      emit(state.copyWith(
        gameGrid: clearedGrid,
        score: state.score + scoreData.totalScore,
        linesCleared: state.linesCleared + completedLines.length,
        comboCount: scoreData.comboCount,
        level: _calculateLevel(state.linesCleared + completedLines.length),
        sessionData: updatedSessionData,
        lastActionTime: DateTime.now(),
      ));
      
      // Check for level up
      if (_shouldLevelUp()) {
        _handleLevelUp();
      }
      
      // Check for game over
      if (_isGameOver(clearedGrid)) {
        endGame();
      }
      
      // Generate new blocks if needed
      _generateNewBlocks();
      
      developer.log('Block placed successfully at ($row, $col)', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Error placing block: $e', name: 'GameCubit');
      emit(state.copyWith(
        errorMessage: 'Failed to place block: ${e.toString()}',
      ));
    }
  }

  /// Use undo power-up
  Future<void> useUndo() async {
    if (!state.isPlaying || state.remainingUndos <= 0) return;
    
    try {
      // Get previous game state from history
      final previousState = await _gameUseCases.getPreviousGameState(
        state.currentSession?.sessionId ?? '',
      );
      
      if (previousState != null) {
        emit(state.copyWith(
          gameGrid: previousState.gridState,
          score: math.max(0, state.score - 50), // Penalty for undo
          remainingUndos: state.remainingUndos - 1,
          lastActionTime: DateTime.now(),
        ));
        
        developer.log('Undo used successfully', name: 'GameCubit');
      }
    } catch (e) {
      developer.log('Failed to use undo: $e', name: 'GameCubit');
    }
  }

  /// Use hint power-up
  Future<void> useHint() async {
    if (!state.isPlaying || state.remainingHints <= 0) return;
    
    try {
      final hintData = await _gameUseCases.generateHint(
        gridState: state.gameGrid,
        availableBlocks: state.activeBlocks,
      );
      
      emit(state.copyWith(
        currentHint: hintData,
        remainingHints: state.remainingHints - 1,
        lastActionTime: DateTime.now(),
      ));
      
      // Auto-hide hint after delay
      Timer(const Duration(seconds: 5), () {
        if (state.currentHint == hintData) {
          emit(state.copyWith(currentHint: null));
        }
      });
      
      developer.log('Hint generated successfully', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to generate hint: $e', name: 'GameCubit');
    }
  }

  // ========================================
  // PRIVATE GAME LOGIC
  // ========================================

  /// Create empty game grid
  List<List<int>> _createEmptyGrid() {
    return List.generate(
      AppConstants.gridSize,
      (row) => List.generate(AppConstants.gridSize, (col) => 0),
    );
  }

  /// Check if block can be placed at position
  bool _canPlaceBlock(Block block, int row, int col) {
    for (int i = 0; i < block.shape.length; i++) {
      for (int j = 0; j < block.shape[i].length; j++) {
        if (block.shape[i][j] == 1) {
          final newRow = row + i;
          final newCol = col + j;
          
          // Check bounds
          if (newRow < 0 || newRow >= AppConstants.gridSize ||
              newCol < 0 || newCol >= AppConstants.gridSize) {
            return false;
          }
          
          // Check if cell is occupied
          if (state.gameGrid[newRow][newCol] != 0) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Place block on grid
  List<List<int>> _placeBlockOnGrid(List<List<int>> grid, Block block, int row, int col) {
    final newGrid = grid.map((row) => row.toList()).toList();
    
    for (int i = 0; i < block.shape.length; i++) {
      for (int j = 0; j < block.shape[i].length; j++) {
        if (block.shape[i][j] == 1) {
          newGrid[row + i][col + j] = block.colorId;
        }
      }
    }
    
    return newGrid;
  }

  /// Find completed lines (rows and columns)
  List<LineCompletion> _findCompletedLines(List<List<int>> grid) {
    final completions = <LineCompletion>[];
    
    // Check rows
    for (int row = 0; row < AppConstants.gridSize; row++) {
      if (grid[row].every((cell) => cell != 0)) {
        completions.add(LineCompletion(type: LineType.row, index: row));
      }
    }
    
    // Check columns
    for (int col = 0; col < AppConstants.gridSize; col++) {
      if (grid.every((row) => row[col] != 0)) {
        completions.add(LineCompletion(type: LineType.column, index: col));
      }
    }
    
    return completions;
  }

  /// Clear completed lines from grid
  List<List<int>> _clearCompletedLines(List<List<int>> grid, List<LineCompletion> lines) {
    final newGrid = grid.map((row) => row.toList()).toList();
    
    for (final line in lines) {
      if (line.type == LineType.row) {
        for (int col = 0; col < AppConstants.gridSize; col++) {
          newGrid[line.index][col] = 0;
        }
      } else {
        for (int row = 0; row < AppConstants.gridSize; row++) {
          newGrid[row][line.index] = 0;
        }
      }
    }
    
    return newGrid;
  }

  /// Calculate score for current action
  ScoreCalculation _calculateScore({
    bool placedBlock = false,
    int linesCleared = 0,
    int currentCombo = 0,
  }) {
    int baseScore = 0;
    
    if (placedBlock) {
      baseScore += AppConstants.baseScores['blockPlace'] ?? 0;
    }
    
    if (linesCleared > 0) {
      final lineScoreKey = switch (linesCleared) {
        1 => 'singleLine',
        2 => 'doubleLine',
        3 => 'tripleLine',
        4 => 'quadLine',
        _ => 'quadLine', // 4+ lines use quad score
      };
      baseScore += AppConstants.baseScores[lineScoreKey] ?? 0;
    }
    
    // Apply combo multiplier
    final comboMultiplier = currentCombo < AppConstants.comboMultipliers.length
        ? AppConstants.comboMultipliers[currentCombo]
        : AppConstants.comboMultipliers.last;
    
    final totalScore = (baseScore * comboMultiplier).round();
    
    return ScoreCalculation(
      baseScore: baseScore,
      comboMultiplier: comboMultiplier,
      totalScore: totalScore,
      comboCount: currentCombo,
    );
  }

  /// Calculate current level based on lines cleared
  int _calculateLevel(int totalLinesCleared) {
    return (totalLinesCleared ~/ AppConstants.linesPerLevel) + 1;
  }

  /// Check if should level up
  bool _shouldLevelUp() {
    final newLevel = _calculateLevel(state.linesCleared);
    return newLevel > state.level;
  }

  /// Handle level up
  void _handleLevelUp() {
    final newLevel = _calculateLevel(state.linesCleared);
    emit(state.copyWith(level: newLevel));
    
    // Trigger level up achievements
    _achievementUseCases.checkLevelAchievements(newLevel);
    
    developer.log('Level up! New level: $newLevel', name: 'GameCubit');
  }

  /// Check if game is over
  bool _isGameOver(List<List<int>> grid) {
    // Count filled cells
    int filledCells = 0;
    for (final row in grid) {
      filledCells += row.where((cell) => cell != 0).length;
    }
    
    final fillPercentage = (filledCells / (AppConstants.gridSize * AppConstants.gridSize)) * 100;
    return fillPercentage >= AppConstants.gameOverThreshold;
  }

  /// Generate new blocks for the game
  void _generateNewBlocks() {
    // Implementation would generate new blocks based on game rules
    // This is a simplified version
    final newBlocks = <Block>[];
    
    // Generate blocks based on current level and difficulty
    for (int i = 0; i < AppConstants.maxActiveBlocks; i++) {
      newBlocks.add(_generateRandomBlock());
    }
    
    emit(state.copyWith(activeBlocks: newBlocks));
  }

  /// Generate a random block
  Block _generateRandomBlock() {
    // Simplified block generation - would be more sophisticated in real implementation
    return Block.createRandom(level: state.level);
  }

  // ========================================
  // TIMER MANAGEMENT
  // ========================================

  /// Start the game timer
  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPlaying) {
        emit(state.copyWith(
          sessionDuration: state.sessionDuration + const Duration(seconds: 1),
        ));
        
        // Check for maximum game duration
        if (state.sessionDuration >= AppConstants.maxGameDuration) {
          endGame(userInitiated: false);
        }
      }
    });
  }

  /// Stop the game timer
  void _stopGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  /// Setup auto-save functionality
  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(AppConstants.autoSaveInterval, (_) {
      _autoSave();
    });
  }

  /// Stop auto-save
  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Auto-save current game state
  void _autoSave() {
    if (state.isPlaying && state.currentSession != null) {
      try {
        _gameUseCases.saveGameState(
          sessionId: state.currentSession!.sessionId,
          gameState: state,
        );
        developer.log('Game auto-saved', name: 'GameCubit');
      } catch (e) {
        developer.log('Auto-save failed: $e', name: 'GameCubit');
      }
    }
  }

  /// Process final score and achievements
  void _processFinalScore() {
    if (state.currentSession == null) return;
    
    try {
      // Save final score
      _gameUseCases.saveFinalScore(
        sessionId: state.currentSession!.sessionId,
        finalScore: state.score,
        completionData: state.sessionData,
      );
      
      // Check achievements
      _achievementUseCases.checkGameCompletionAchievements(
        score: state.score,
        level: state.level,
        linesCleared: state.linesCleared,
        gameDuration: state.sessionDuration,
      );
      
      developer.log('Final score processed: ${state.score}', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to process final score: $e', name: 'GameCubit');
    }
  }

  // ========================================
  // CLEANUP
  // ========================================

  @override
  Future<void> close() {
    _stopGameTimer();
    _stopAutoSave();
    return super.close();
  }
}

