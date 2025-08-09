import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import 'package:puzzle_box/domain/usecases/game_usecases.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';

// Game state status enumeration
enum GameStateStatus {
  initial,
  loading,
  playing,
  paused,
  gameOver,
  error,
}

// Game state model
class GameState extends Equatable {
  final GameStateStatus status;
  final GameSession? currentSession;
  final int score;
  final int level;
  final int linesCleared;
  final int comboCount;
  final int maxCombo;
  final int streakCount;
  final int maxStreak;
  final List<Block> activeBlocks;
  final List<List<int>> grid;
  final Duration sessionDuration;
  final int remainingUndos;
  final int remainingHints;
  final String? errorMessage;
  final SessionStatistics? sessionData;
  final bool isFirstGame;
  final DateTime? lastMoveTime;
  final Map<String, int> powerUpCounts;

  const GameState({
    this.status = GameStateStatus.initial,
    this.currentSession,
    this.score = 0,
    this.level = 1,
    this.linesCleared = 0,
    this.comboCount = 0,
    this.maxCombo = 0,
    this.streakCount = 0,
    this.maxStreak = 0,
    this.activeBlocks = const [],
    this.grid = const [],
    this.sessionDuration = Duration.zero,
    this.remainingUndos = 3,
    this.remainingHints = 3,
    this.errorMessage,
    this.sessionData,
    this.isFirstGame = false,
    this.lastMoveTime,
    this.powerUpCounts = const {},
  });

  bool get isPlaying => status == GameStateStatus.playing;
  bool get isPaused => status == GameStateStatus.paused;
  bool get isGameOver => status == GameStateStatus.gameOver;
  bool get hasError => status == GameStateStatus.error;
  bool get isLoading => status == GameStateStatus.loading;

  GameState copyWith({
    GameStateStatus? status,
    GameSession? currentSession,
    int? score,
    int? level,
    int? linesCleared,
    int? comboCount,
    int? maxCombo,
    int? streakCount,
    int? maxStreak,
    List<Block>? activeBlocks,
    List<List<int>>? grid,
    Duration? sessionDuration,
    int? remainingUndos,
    int? remainingHints,
    String? errorMessage,
    SessionStatistics? sessionData,
    bool? isFirstGame,
    DateTime? lastMoveTime,
    Map<String, int>? powerUpCounts,
  }) {
    return GameState(
      status: status ?? this.status,
      currentSession: currentSession ?? this.currentSession,
      score: score ?? this.score,
      level: level ?? this.level,
      linesCleared: linesCleared ?? this.linesCleared,
      comboCount: comboCount ?? this.comboCount,
      maxCombo: maxCombo ?? this.maxCombo,
      streakCount: streakCount ?? this.streakCount,
      maxStreak: maxStreak ?? this.maxStreak,
      activeBlocks: activeBlocks ?? this.activeBlocks,
      grid: grid ?? this.grid,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      remainingUndos: remainingUndos ?? this.remainingUndos,
      remainingHints: remainingHints ?? this.remainingHints,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionData: sessionData ?? this.sessionData,
      isFirstGame: isFirstGame ?? this.isFirstGame,
      lastMoveTime: lastMoveTime ?? this.lastMoveTime,
      powerUpCounts: powerUpCounts ?? this.powerUpCounts,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentSession,
        score,
        level,
        linesCleared,
        comboCount,
        maxCombo,
        streakCount,
        maxStreak,
        activeBlocks,
        grid,
        sessionDuration,
        remainingUndos,
        remainingHints,
        errorMessage,
        sessionData,
        isFirstGame,
        lastMoveTime,
        powerUpCounts,
      ];
}

/// GameCubit manages the core game state and logic coordination.
/// Handles game sessions, scoring, level progression, and game flow.
/// Follows Clean Architecture principles with proper error handling.
class GameCubit extends Cubit<GameState> {
  final GameUseCases _gameUseCases;
  final AchievementUseCases _achievementUseCases;
  
  // Timers for game management
  Timer? _gameTimer;
  Timer? _autoSaveTimer;
  
  // Performance tracking
  DateTime? _lastFrameTime;
  final List<Duration> _frameTimes = [];

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
  }) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));
      
      // Create new game session
      final gameSession = await _gameUseCases.createNewGame(difficulty: difficulty);
      
      // Initialize game state
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
        grid: _createEmptyGrid(),
        activeBlocks: _generateInitialBlocks(),
        sessionDuration: Duration.zero,
        remainingUndos: AppConstants.maxUndoCount,
        remainingHints: AppConstants.maxHints,
        errorMessage: null,
        sessionData: SessionStatistics.initial(),
        isFirstGame: sessionId == null,
        lastMoveTime: DateTime.now(),
        powerUpCounts: _getInitialPowerUps(difficulty),
      ));
      
      _startGameTimer();
      developer.log('New game started with difficulty: ${difficulty.name}', name: 'GameCubit');
      
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
      
      final savedGame = await _gameUseCases.loadSavedGame();
      if (savedGame != null) {
        emit(state.copyWith(
          status: GameStateStatus.playing,
          currentSession: savedGame,
          score: savedGame.currentScore,
          level: savedGame.currentLevel,
          linesCleared: savedGame.linesCleared,
          comboCount: savedGame.comboCount,
          maxCombo: savedGame.maxCombo,
          grid: savedGame.gridState,
          sessionDuration: savedGame.playTime,
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
      final (clearedLines, newScore) = _checkForLineClears(updatedSession.gridState);
      
      // Update combo and streak
      final newCombo = clearedLines.isNotEmpty ? state.comboCount + 1 : 0;
      final newStreak = clearedLines.isNotEmpty ? state.streakCount + 1 : 0;
      
      // Generate new blocks if needed
      final newActiveBlocks = _updateActiveBlocks(block);
      
      // Calculate level progression
      final newLevel = _calculateLevel(state.linesCleared + clearedLines.length);

      emit(state.copyWith(
        currentSession: updatedSession,
        score: state.score + newScore,
        level: newLevel,
        linesCleared: state.linesCleared + clearedLines.length,
        comboCount: newCombo,
        maxCombo: newCombo > state.maxCombo ? newCombo : state.maxCombo,
        streakCount: newStreak,
        maxStreak: newStreak > state.maxStreak ? newStreak : state.maxStreak,
        grid: updatedSession.gridState,
        activeBlocks: newActiveBlocks,
        lastMoveTime: DateTime.now(),
        sessionData: state.sessionData?.copyWith(
          blocksPlaced: (state.sessionData?.blocksPlaced ?? 0) + 1,
          linesCleared: (state.sessionData?.linesCleared ?? 0) + clearedLines.length,
          lastBlockTime: DateTime.now(),
        ),
      ));

      // Check for game over
      if (_isGameOver(updatedSession.gridState)) {
        await endGame(userInitiated: false);
      }

      developer.log('Block placed at ($gridRow, $gridCol) - Score: ${state.score}', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to place block: $e', name: 'GameCubit');
      emit(state.copyWith(
        status: GameStateStatus.error,
        errorMessage: 'Failed to place block: $e',
      ));
    }
  }

  /// Use a power-up
  Future<void> usePowerUp(PowerUpType powerUpType) async {
    if (!state.isPlaying) return;

    try {
      final currentCount = state.powerUpCounts[powerUpType.name] ?? 0;
      if (currentCount <= 0) {
        throw Exception('No ${powerUpType.name} power-ups remaining');
      }

      // Apply power-up effect based on type
      switch (powerUpType) {
        case PowerUpType.undo:
          _handleUndoPowerUp();
          break;
        case PowerUpType.hint:
          _handleHintPowerUp();
          break;
        case PowerUpType.shuffle:
          _handleShufflePowerUp();
          break;
        case PowerUpType.bomb:
          _handleBombPowerUp();
          break;
        case PowerUpType.freeze:
          _handleFreezePowerUp();
          break;
      }

      // Update power-up count
      final updatedCounts = Map<String, int>.from(state.powerUpCounts);
      updatedCounts[powerUpType.name] = currentCount - 1;

      emit(state.copyWith(
        powerUpCounts: updatedCounts,
        sessionData: state.sessionData?.copyWith(
          powerUpsUsed: (state.sessionData?.powerUpsUsed ?? 0) + 1,
        ),
      ));

      developer.log('Power-up used: ${powerUpType.name}', name: 'GameCubit');
      
    } catch (e) {
      developer.log('Failed to use power-up: $e', name: 'GameCubit');
      emit(state.copyWith(
        status: GameStateStatus.error,
        errorMessage: 'Failed to use power-up: $e',
      ));
    }
  }

  /// Save current game state
  Future<void> saveGame() async {
    if (state.currentSession != null) {
      try {
        final success = await _gameUseCases.saveGame(state.currentSession!);
        if (!success) {
          throw Exception('Failed to save game');
        }
        developer.log('Game saved successfully', name: 'GameCubit');
      } catch (e) {
        developer.log('Failed to save game: $e', name: 'GameCubit');
        emit(state.copyWith(
          status: GameStateStatus.error,
          errorMessage: 'Failed to save game: $e',
        ));
      }
    }
  }

  // ========================================
  // PRIVATE HELPER METHODS
  // ========================================

  /// Create empty 8x8 grid
  List<List<int>> _createEmptyGrid() {
    return List.generate(
      AppConstants.gridSize,
      (_) => List.filled(AppConstants.gridSize, 0),
    );
  }

  /// Generate initial blocks for the game
  List<Block> _generateInitialBlocks() {
    final blocks = <Block>[];
    for (int i = 0; i < AppConstants.maxActiveBlocks; i++) {
      blocks.add(_generateRandomBlock());
    }
    return blocks;
  }

  /// Generate a random block based on current level
  Block _generateRandomBlock() {
    // Use block shapes from constants
    final shapeIndex = DateTime.now().millisecondsSinceEpoch % AppConstants.blockShapes.length;
    final shape = AppConstants.blockShapes[shapeIndex];
    
    return Block.fromShape(
      shape: shape,
      colorId: shapeIndex,
      level: state.level,
    );
  }

  /// Update active blocks after placing one
  List<Block> _updateActiveBlocks(Block placedBlock) {
    final updatedBlocks = List<Block>.from(state.activeBlocks);
    updatedBlocks.removeWhere((block) => block.id == placedBlock.id);
    
    // Add new block if needed
    if (updatedBlocks.length < AppConstants.maxActiveBlocks) {
      updatedBlocks.add(_generateRandomBlock());
    }
    
    return updatedBlocks;
  }

  /// Check for completed lines and return cleared lines with score
  (List<int>, int) _checkForLineClears(List<List<int>> grid) {
    final clearedLines = <int>[];
    int totalScore = 0;

    // Check rows
    for (int row = 0; row < AppConstants.gridSize; row++) {
      if (grid[row].every((cell) => cell != 0)) {
        clearedLines.add(row);
      }
    }

    // Check columns
    for (int col = 0; col < AppConstants.gridSize; col++) {
      if (grid.every((row) => row[col] != 0)) {
        clearedLines.add(AppConstants.gridSize + col); // Offset for columns
      }
    }

    // Calculate score based on cleared lines
    if (clearedLines.isNotEmpty) {
      final baseScore = AppConstants.baseScores['singleLine'] ?? 100;
      final multiplier = AppConstants.comboMultipliers[
        (state.comboCount < AppConstants.comboMultipliers.length 
            ? state.comboCount 
            : AppConstants.comboMultipliers.length - 1)
      ];
      
      totalScore = (baseScore * clearedLines.length * multiplier).round();
    }

    return (clearedLines, totalScore);
  }

  /// Calculate level based on lines cleared
  int _calculateLevel(int totalLinesCleared) {
    return (totalLinesCleared / AppConstants.linesPerLevel).floor() + 1;
  }

  /// Check if game is over
  bool _isGameOver(List<List<int>> grid) {
    // Simple game over check - could be more sophisticated
    int filledCells = 0;
    for (final row in grid) {
      filledCells += row.where((cell) => cell != 0).length;
    }
    
    final totalCells = AppConstants.gridSize * AppConstants.gridSize;
    final fillPercentage = (filledCells / totalCells) * 100;
    
    return fillPercentage >= 80.0; // Game over at 80% fill
  }

  /// Get initial power-ups based on difficulty
  Map<String, int> _getInitialPowerUps(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return {'undo': 5, 'hint': 8, 'shuffle': 3};
      case GameDifficulty.normal:
        return {'undo': 3, 'hint': 5, 'shuffle': 2};
      case GameDifficulty.hard:
        return {'undo': 2, 'hint': 3, 'shuffle': 1};
      case GameDifficulty.expert:
        return {'undo': 1, 'hint': 1, 'shuffle': 0};
    }
  }

  // Power-up handlers
  void _handleUndoPowerUp() {
    // Implement undo logic
    developer.log('Undo power-up used', name: 'GameCubit');
  }

  void _handleHintPowerUp() {
    // Implement hint logic
    developer.log('Hint power-up used', name: 'GameCubit');
  }

  void _handleShufflePowerUp() {
    // Shuffle active blocks
    final shuffledBlocks = <Block>[];
    for (int i = 0; i < AppConstants.maxActiveBlocks; i++) {
      shuffledBlocks.add(_generateRandomBlock());
    }
    emit(state.copyWith(activeBlocks: shuffledBlocks));
    developer.log('Shuffle power-up used', name: 'GameCubit');
  }

  void _handleBombPowerUp() {
    // Implement bomb logic
    developer.log('Bomb power-up used', name: 'GameCubit');
  }

  void _handleFreezePowerUp() {
    // Implement freeze logic
    developer.log('Freeze power-up used', name: 'GameCubit');
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
        if (state.sessionDuration >= const Duration(hours: 2)) {
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
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
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
        _gameUseCases.saveGame(state.currentSession!);
        developer.log('Auto-save completed', name: 'GameCubit');
      } catch (e) {
        developer.log('Auto-save failed: $e', name: 'GameCubit');
      }
    }
  }
}