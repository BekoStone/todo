// File: lib/presentation/cubit/game_cubit.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/core/errors/exceptions_dart.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import '../../domain/usecases/game_usecases.dart';
import '../../core/constants/game_constants.dart' hide GameConstants;

/// Game state enumeration
enum GameStateStatus {
  initial,
  loading,
  playing,
  paused,
  gameOver,
  restarting,
  error,
}

/// Game cubit state
class GameState extends Equatable {
  final GameStateStatus status;
  final GameSession? currentSession;
  final List<Block> activeBlocks;
  final List<List<bool>> gridState;
  final int score;
  final int level;
  final int linesCleared;
  final int comboCount;
  final int streakCount;
  final Map<PowerUpType, int> powerUpInventory;
  final bool canUndo;
  final int remainingUndos;
  final double gridFillPercentage;
  final String? errorMessage;
  final DateTime? lastActionTime;
  final Duration sessionDuration;
  final GameDifficulty difficulty;
  final bool isPowerUpActive;
  final PowerUpType? activePowerUp;

  const GameState({
    this.status = GameStateStatus.initial,
    this.currentSession,
    this.activeBlocks = const [],
    this.gridState = const [],
    this.score = 0,
    this.level = 1,
    this.linesCleared = 0,
    this.comboCount = 0,
    this.streakCount = 0,
    this.powerUpInventory = const {},
    this.canUndo = false,
    this.remainingUndos = 0,
    this.gridFillPercentage = 0.0,
    this.errorMessage,
    this.lastActionTime,
    this.sessionDuration = Duration.zero,
    this.difficulty = GameDifficulty.normal,
    this.isPowerUpActive = false,
    this.activePowerUp,
  });

  bool get isPlaying => status == GameStateStatus.playing;
  bool get isPaused => status == GameStateStatus.paused;
  bool get isGameOver => status == GameStateStatus.gameOver;
  bool get isLoading => status == GameStateStatus.loading;
  bool get hasError => status == GameStateStatus.error;
  bool get canPause => isPlaying && !isPowerUpActive;
  bool get isInDanger => gridFillPercentage > 70.0;
  bool get hasActiveBlocks => activeBlocks.isNotEmpty;

  GameState copyWith({
    GameStateStatus? status,
    GameSession? currentSession,
    List<Block>? activeBlocks,
    List<List<bool>>? gridState,
    int? score,
    int? level,
    int? linesCleared,
    int? comboCount,
    int? streakCount,
    Map<PowerUpType, int>? powerUpInventory,
    bool? canUndo,
    int? remainingUndos,
    double? gridFillPercentage,
    String? errorMessage,
    DateTime? lastActionTime,
    Duration? sessionDuration,
    GameDifficulty? difficulty,
    bool? isPowerUpActive,
    PowerUpType? activePowerUp,
  }) {
    return GameState(
      status: status ?? this.status,
      currentSession: currentSession ?? this.currentSession,
      activeBlocks: activeBlocks ?? this.activeBlocks,
      gridState: gridState ?? this.gridState,
      score: score ?? this.score,
      level: level ?? this.level,
      linesCleared: linesCleared ?? this.linesCleared,
      comboCount: comboCount ?? this.comboCount,
      streakCount: streakCount ?? this.streakCount,
      powerUpInventory: powerUpInventory ?? this.powerUpInventory,
      canUndo: canUndo ?? this.canUndo,
      remainingUndos: remainingUndos ?? this.remainingUndos,
      gridFillPercentage: gridFillPercentage ?? this.gridFillPercentage,
      errorMessage: errorMessage,
      lastActionTime: lastActionTime ?? this.lastActionTime,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      difficulty: difficulty ?? this.difficulty,
      isPowerUpActive: isPowerUpActive ?? this.isPowerUpActive,
      activePowerUp: activePowerUp,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentSession,
    activeBlocks,
    gridState,
    score,
    level,
    linesCleared,
    comboCount,
    streakCount,
    powerUpInventory,
    canUndo,
    remainingUndos,
    gridFillPercentage,
    errorMessage,
    lastActionTime,
    sessionDuration,
    difficulty,
    isPowerUpActive,
    activePowerUp,
  ];
}

/// Game cubit for managing game state
class GameCubit extends Cubit<GameState> {
  final GameUseCases _gameUseCases;
  final AchievementUseCases _achievementUseCases;

  Timer? _sessionTimer;
  Timer? _autoSaveTimer;
  DateTime? _gameStartTime;

  GameCubit(this._gameUseCases, this._achievementUseCases)
    : super(const GameState()) {
    void initialize() {
      developer.log('GameCubit initialized.', name: 'GameCubit');
      _initializeAutoSave();
      // ممكن هنا تضيف أي مهام تهيئة تانية محتاجها
      // مثلاً: تحميل آخر حالة لعبة
      // loadLastSavedGame();
    }
  }

  /// Initialize a new game session
  Future<void> startNewGame({
    GameDifficulty difficulty = GameDifficulty.normal,
  }) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));

      // Create new game session
      final session = await _gameUseCases.createNewGame(difficulty: difficulty);

      // Initialize grid
      final gridState = List.generate(
        GameConstants.gridSize,
        (_) => List.filled(GameConstants.gridSize, false),
      );

      // Generate initial blocks
      final activeBlocks = await _gameUseCases.generateNewBlocks();

      // Initialize power-up inventory
      final powerUpInventory = <PowerUpType, int>{
        PowerUpType.shuffle: 2,
        PowerUpType.undo: 3,
      };

      _gameStartTime = DateTime.now();
      _startSessionTimer();

      emit(
        state.copyWith(
          status: GameStateStatus.playing,
          currentSession: session,
          activeBlocks: activeBlocks,
          gridState: gridState,
          score: 0,
          level: 1,
          linesCleared: 0,
          comboCount: 0,
          streakCount: 0,
          powerUpInventory: powerUpInventory,
          canUndo: false,
          remainingUndos: GameConstants.maxUndoCount,
          gridFillPercentage: 0.0,
          lastActionTime: DateTime.now(),
          sessionDuration: Duration.zero,
          difficulty: difficulty,
          isPowerUpActive: false,
          activePowerUp: null,
        ),
      );

      developer.log(
        'New game started with difficulty: ${difficulty.name}',
        name: 'GameCubit',
      );
    } catch (e) {
      developer.log('Failed to start new game: $e', name: 'GameCubit');
      emit(
        state.copyWith(
          status: GameStateStatus.error,
          errorMessage: 'Failed to start new game: $e',
        ),
      );
    }
  }

  /// Place a block on the grid
  Future<void> placeBlock(Block block, int row, int col) async {
    if (!state.isPlaying ||
        state.isPowerUpActive ||
        state.currentSession == null) {
      return;
    }

    try {
      // Validate placement
      // ✅ هنا يتم تمرير المتغيرات بالشكل الصحيح
      final canPlace = await _gameUseCases.canPlaceBlock(
        state.currentSession!,
        block,
        row,
        col,
      );

      if (!canPlace) {
        developer.log(
          'Cannot place block at position ($row, $col)',
          name: 'GameCubit',
        );
        return;
      }

      // Place block and update grid
      final placementResult = _gameUseCases.placeBlock(
        state.currentSession!,
        block,
        row,
        col,
      );

      // Remove placed block from active blocks
      final updatedActiveBlocks = state.activeBlocks
          .where((b) => b.id != block.id)
          .toList();

      // Check for line clears
      final clearResult = _gameUseCases.clearCompletedLines(placementResult);

      // Calculate new score
      final scoreData = await _gameUseCases.calculateScore(
        blocksPlaced: 1,
        linesCleared: clearResult.linesCleared - state.linesCleared,
        currentScore: state.score,
        comboCount: clearResult.linesCleared > state.linesCleared
            ? state.comboCount + 1
            : 0,
      );

      // Update grid fill percentage
      final fillPercentage = _calculateGridFillPercentage(clearResult.grid);

      // Generate new blocks if needed
      List<Block> newActiveBlocks = clearResult.activeBlocks;
      if (newActiveBlocks.isEmpty) {
        newActiveBlocks = await _gameUseCases
            .generateNewBlocks(clearResult)
            .activeBlocks;
      }

      // Check for game over
      final gameOverResult = _gameUseCases.isGameOver(clearResult);

      if (gameOverResult) {
        await _handleGameOver();
        return;
      }

      emit(
        state.copyWith(
          currentSession: clearResult,
          gridState: clearResult.grid,
          activeBlocks: newActiveBlocks,
          score: scoreData.totalScore,
          level: scoreData.level,
          linesCleared: clearResult.linesCleared,
          comboCount: clearResult.comboCount,
          streakCount: clearResult.streakCount,
          canUndo: true,
          gridFillPercentage: fillPercentage,
          lastActionTime: DateTime.now(),
        ),
      );

      // Process achievements
      await _processBlockPlacementAchievements(
        clearResult.linesCleared - state.linesCleared,
      );

      developer.log(
        'Block placed: Score ${scoreData.totalScore}, Lines ${clearResult.linesCleared - state.linesCleared}',
        name: 'GameCubit',
      );
    } catch (e) {
      developer.log('Failed to place block: $e', name: 'GameCubit');
      emit(
        state.copyWith(
          status: GameStateStatus.error,
          errorMessage: 'Failed to place block: $e',
        ),
      );
    }
  }

  /// Use a power-up
  Future<void> usePowerUp(PowerUpType powerUpType) async {
    if (!state.isPlaying) return;

    try {
      final currentCount = state.powerUpInventory[powerUpType] ?? 0;
      if (currentCount <= 0) {
        developer.log(
          'No ${powerUpType.name} power-ups available',
          name: 'GameCubit',
        );
        return;
      }

      switch (powerUpType) {
        case PowerUpType.shuffle:
          await _useShuffle();
          break;
        case PowerUpType.undo:
          await _useUndo();
          break;
      }

      // Update inventory
      final updatedInventory = Map<PowerUpType, int>.from(
        state.powerUpInventory,
      );
      updatedInventory[powerUpType] = currentCount - 1;

      emit(
        state.copyWith(
          powerUpInventory: updatedInventory,
          lastActionTime: DateTime.now(),
        ),
      );

      developer.log('Used power-up: ${powerUpType.name}', name: 'GameCubit');
    } catch (e) {
      developer.log('Failed to use power-up: $e', name: 'GameCubit');
    }
  }

  /// Pause the game
  void pauseGame() {
    if (state.isPlaying && !state.isPowerUpActive) {
      _sessionTimer?.cancel();
      emit(state.copyWith(status: GameStateStatus.paused));
      developer.log('Game paused', name: 'GameCubit');
    }
  }

  /// Resume the game
  void resumeGame() {
    if (state.isPaused) {
      _startSessionTimer();
      emit(state.copyWith(status: GameStateStatus.playing));
      developer.log('Game resumed', name: 'GameCubit');
    }
  }

  /// Restart the current game
  Future<void> restartGame() async {
    emit(state.copyWith(status: GameStateStatus.restarting));
    await startNewGame(difficulty: state.difficulty);
  }

  /// Save game state
  Future<void> saveGame() async {
    if (state.currentSession == null) return;

    try {
      await _gameUseCases.saveGame(state.currentSession!);
      developer.log('Game saved successfully', name: 'GameCubit');
    } catch (e) {
      developer.log('Failed to save game: $e', name: 'GameCubit');
    }
  }

  /// Load game state
  Future<void> loadGame(String sessionId) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));

      final session = await _gameUseCases.loadSavedGame();
      if (session == null) {
        throw NotFoundException('Game session not found: $sessionId');
      }

      // Reconstruct game state from session
      emit(
        state.copyWith(
          status: GameStateStatus.playing,
          currentSession: session,
          score: session.currentScore,
          level: session.level,
          linesCleared: session.linesCleared,
          // Add other state reconstruction...
        ),
      );

      _startSessionTimer();
      developer.log('Game loaded successfully: $sessionId', name: 'GameCubit');
    } catch (e) {
      developer.log('Failed to load game: $e', name: 'GameCubit');
      emit(
        state.copyWith(
          status: GameStateStatus.error,
          errorMessage: 'Failed to load game: $e',
        ),
      );
    }
  }

  /// Handle shuffle power-up
  Future<void> _useShuffle() async {
    final newBlocks = await _gameUseCases.generateInitialBlocks();
    emit(state.copyWith(activeBlocks: newBlocks));
  }

  /// Handle undo power-up
  Future<void> _useUndo() async {
    if (!state.canUndo || state.remainingUndos <= 0) return;

    // Implementation would restore previous game state
    // This is a simplified version
    emit(
      state.copyWith(
        remainingUndos: state.remainingUndos - 1,
        canUndo: state.remainingUndos > 1,
      ),
    );
  }

  /// Handle game over
  Future<void> _handleGameOver() async {
    _sessionTimer?.cancel();

    // Calculate final session data
    final sessionDuration = _gameStartTime != null
        ? DateTime.now().difference(_gameStartTime!)
        : Duration.zero;

    // Process end-game achievements
    await _achievementUseCases.processGameSessionAchievements(
      finalScore: state.score,
      level: state.level,
      linesCleared: state.linesCleared,
      blocksPlaced: 0, // Would track this during gameplay
      comboCount: state.comboCount,
      perfectClear: false, // Would determine this
      usedUndo: state.remainingUndos < GameConstants.maxUndoCount,
      sessionDuration: sessionDuration,
    );

    emit(
      state.copyWith(
        status: GameStateStatus.gameOver,
        sessionDuration: sessionDuration,
      ),
    );

    developer.log(
      'Game over: Score ${state.score}, Duration ${sessionDuration.inSeconds}s',
      name: 'GameCubit',
    );
  }

  /// Process achievements for block placement
  Future<void> _processBlockPlacementAchievements(int linesCleared) async {
    try {
      // Process first block achievement
      if (state.score == 0) {
        await _achievementUseCases.processGameActionAchievements(
          action: 'first_block',
          actionData: {},
        );
      }

      // Process line clear achievements
      if (linesCleared > 0) {
        await _achievementUseCases.processGameActionAchievements(
          action: 'line_cleared',
          actionData: {'line_count': linesCleared},
        );

        if (state.linesCleared == 0) {
          await _achievementUseCases.processGameActionAchievements(
            action: 'first_line',
            actionData: {},
          );
        }
      }
    } catch (e) {
      developer.log('Failed to process achievements: $e', name: 'GameCubit');
    }
  }

  /// Calculate grid fill percentage
  double _calculateGridFillPercentage(List<List<bool>> gridState) {
    int occupiedCells = 0;
    int totalCells = GameConstants.gridSize * GameConstants.gridSize;

    for (final row in gridState) {
      for (final cell in row) {
        if (cell) occupiedCells++;
      }
    }

    return (occupiedCells / totalCells) * 100.0;
  }

  /// Start session timer
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isPlaying) {
        final newDuration = _gameStartTime != null
            ? DateTime.now().difference(_gameStartTime!)
            : state.sessionDuration + const Duration(seconds: 1);

        emit(state.copyWith(sessionDuration: newDuration));
      }
    });
  }

  /// Initialize auto-save functionality
  void _initializeAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (state.isPlaying) {
        saveGame();
      }
    });
  }

  @override
  Future<void> close() {
    _sessionTimer?.cancel();
    _autoSaveTimer?.cancel();
    return super.close();
  }
}
