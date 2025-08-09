import 'package:equatable/equatable.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import '../constants/game_constants.dart';

/// GameState represents the complete state of the game session.
/// Follows Clean Architecture with immutable state and clear data flow.
/// Optimized for performance with efficient equality checks and minimal rebuilds.
class GameState extends Equatable {
  /// Current game status
  final GameStateStatus status;
  
  /// Current score
  final int score;
  
  /// Current level
  final int level;
  
  /// Total lines cleared
  final int linesCleared;
  
  /// Current combo count
  final int comboCount;
  
  /// Maximum combo achieved in this session
  final int maxCombo;
  
  /// Current grid state (true = occupied, false = empty)
  final List<List<bool>> grid;
  
  /// Currently active blocks on the grid
  final List<BlockEntity> activeBlocks;
  
  /// Queue of next blocks to be placed
  final List<BlockEntity> nextBlocks;
  
  /// Available power-ups
  final List<PowerUp> availablePowerUps;
  
  /// Used power-ups in this session
  final List<PowerUpType> usedPowerUps;
  
  /// Whether undo is available
  final bool canUndo;
  
  /// Number of remaining undo moves
  final int remainingUndos;
  
  /// Game session data
  final GameSession? currentSession;
  
  /// Session duration
  final Duration? sessionDuration;
  
  /// Whether game is paused
  final bool isPaused;
  
  /// Whether game is loading
  final bool isLoading;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Last move timestamp for timing calculations
  final DateTime? lastMoveTime;
  
  /// Game difficulty
  final GameDifficulty difficulty;
  
  /// Game mode
  final GameMode mode;
  
  /// Performance tracking data
  final Map<String, dynamic> performanceData;

  const GameState({
    this.status = GameStateStatus.initial,
    this.score = 0,
    this.level = 1,
    this.linesCleared = 0,
    this.comboCount = 0,
    this.maxCombo = 0,
    this.grid = const [],
    this.activeBlocks = const [],
    this.nextBlocks = const [],
    this.availablePowerUps = const [],
    this.usedPowerUps = const [],
    this.canUndo = false,
    this.remainingUndos = 3,
    this.currentSession,
    this.sessionDuration,
    this.isPaused = false,
    this.isLoading = false,
    this.errorMessage,
    this.lastMoveTime,
    this.difficulty = GameDifficulty.normal,
    this.mode = GameMode.classic,
    this.performanceData = const {},
  });

  /// Create initial game state
  factory GameState.initial({
    GameDifficulty? difficulty,
    GameMode? mode,
    int? gridSize,
  }) {
    final size = gridSize ?? GameConstants.defaultGridSize;
    final emptyGrid = List.generate(
      size,
      (_) => List.filled(size, false),
    );

    return GameState(
      status: GameStateStatus.initial,
      grid: emptyGrid,
      difficulty: difficulty ?? GameDifficulty.normal,
      mode: mode ?? GameMode.classic,
      remainingUndos: GameConstants.maxUndoMoves,
      performanceData: {
        'gameStartTime': DateTime.now().millisecondsSinceEpoch,
        'moveCount': 0,
        'averageResponseTime': 0.0,
      },
    );
  }

  /// Create loading state
  GameState copyWithLoading({bool loading = true, String? message}) {
    return copyWith(
      status: loading ? GameStateStatus.loading : status,
      isLoading: loading,
      errorMessage: message,
    );
  }

  /// Create error state
  GameState copyWithError(String error) {
    return copyWith(
      status: GameStateStatus.error,
      isLoading: false,
      errorMessage: error,
    );
  }

  /// Create playing state
  GameState copyWithPlaying() {
    return copyWith(
      status: GameStateStatus.playing,
      isLoading: false,
      isPaused: false,
      errorMessage: null,
    );
  }

  /// Create paused state
  GameState copyWithPaused({required bool paused}) {
    return copyWith(
      status: paused ? GameStateStatus.paused : GameStateStatus.playing,
      isPaused: paused,
    );
  }

  /// Create game over state
  GameState copyWithGameOver({required GameSession session}) {
    return copyWith(
      status: GameStateStatus.gameOver,
      currentSession: session,
      isPaused: true,
      isLoading: false,
    );
  }

  /// Create a copy with updated values
  GameState copyWith({
    GameStateStatus? status,
    int? score,
    int? level,
    int? linesCleared,
    int? comboCount,
    int? maxCombo,
    List<List<bool>>? grid,
    List<BlockEntity>? activeBlocks,
    List<BlockEntity>? nextBlocks,
    List<PowerUp>? availablePowerUps,
    List<PowerUpType>? usedPowerUps,
    bool? canUndo,
    int? remainingUndos,
    GameSession? currentSession,
    Duration? sessionDuration,
    bool? isPaused,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastMoveTime,
    GameDifficulty? difficulty,
    GameMode? mode,
    Map<String, dynamic>? performanceData,
  }) {
    return GameState(
      status: status ?? this.status,
      score: score ?? this.score,
      level: level ?? this.level,
      linesCleared: linesCleared ?? this.linesCleared,
      comboCount: comboCount ?? this.comboCount,
      maxCombo: maxCombo ?? this.maxCombo,
      grid: grid ?? this.grid,
      activeBlocks: activeBlocks ?? this.activeBlocks,
      nextBlocks: nextBlocks ?? this.nextBlocks,
      availablePowerUps: availablePowerUps ?? this.availablePowerUps,
      usedPowerUps: usedPowerUps ?? this.usedPowerUps,
      canUndo: canUndo ?? this.canUndo,
      remainingUndos: remainingUndos ?? this.remainingUndos,
      currentSession: currentSession ?? this.currentSession,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      isPaused: isPaused ?? this.isPaused,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastMoveTime: lastMoveTime ?? this.lastMoveTime,
      difficulty: difficulty ?? this.difficulty,
      mode: mode ?? this.mode,
      performanceData: performanceData ?? this.performanceData,
    );
  }

  /// Add score to current total
  GameState addScore(int points) {
    final newScore = score + points;
    final newLevel = _calculateLevel(newScore);
    
    return copyWith(
      score: newScore,
      level: newLevel,
      lastMoveTime: DateTime.now(),
    );
  }

  /// Add lines cleared
  GameState addLinesCleared(int lines) {
    final newLinesCleared = linesCleared + lines;
    final newLevel = _calculateLevelFromLines(newLinesCleared);
    
    return copyWith(
      linesCleared: newLinesCleared,
      level: newLevel,
      lastMoveTime: DateTime.now(),
    );
  }

  /// Update combo count
  GameState updateCombo(int combo) {
    return copyWith(
      comboCount: combo,
      maxCombo: combo > maxCombo ? combo : maxCombo,
    );
  }

  /// Reset combo
  GameState resetCombo() {
    return copyWith(comboCount: 0);
  }

  /// Place block on grid
  GameState placeBlock(BlockEntity block, int row, int col) {
    final newGrid = _copyGrid();
    final blockPositions = block.occupiedPositions;
    
    // Mark grid cells as occupied
    for (final pos in blockPositions) {
      final gridRow = row + pos.y;
      final gridCol = col + pos.x;
      
      if (gridRow >= 0 && gridRow < newGrid.length &&
          gridCol >= 0 && gridCol < newGrid[0].length) {
        newGrid[gridRow][gridCol] = true;
      }
    }
    
    // Update active blocks
    final newActiveBlocks = List<BlockEntity>.from(activeBlocks);
    newActiveBlocks.add(block.copyWith(
      position: Position(col, row),
      isLocked: true,
    ));
    
    return copyWith(
      grid: newGrid,
      activeBlocks: newActiveBlocks,
      canUndo: remainingUndos > 0,
      lastMoveTime: DateTime.now(),
    );
  }

  /// Clear lines from grid
  GameState clearLines(List<int> linesToClear) {
    if (linesToClear.isEmpty) return this;
    
    final newGrid = _copyGrid();
    final sortedLines = List<int>.from(linesToClear)..sort((a, b) => b.compareTo(a));
    
    // Remove cleared lines (from bottom to top)
    for (final lineIndex in sortedLines) {
      newGrid.removeAt(lineIndex);
      // Add new empty line at top
      newGrid.insert(0, List.filled(newGrid.first.length, false));
    }
    
    // Calculate score bonus
    final lineBonus = _calculateLineBonus(linesToClear.length);
    final comboBonus = _calculateComboBonus(comboCount);
    final totalBonus = lineBonus + comboBonus;
    
    return copyWith(
      grid: newGrid,
      linesCleared: linesCleared + linesToClear.length,
      score: score + totalBonus,
      comboCount: comboCount + 1,
      maxCombo: (comboCount + 1) > maxCombo ? (comboCount + 1) : maxCombo,
      lastMoveTime: DateTime.now(),
    );
  }

  /// Use power-up
  GameState usePowerUp(PowerUpType powerUpType) {
    final newAvailablePowerUps = List<PowerUp>.from(availablePowerUps);
    final newUsedPowerUps = List<PowerUpType>.from(usedPowerUps);
    
    // Remove used power-up from available
    newAvailablePowerUps.removeWhere((p) => p.type == powerUpType);
    newUsedPowerUps.add(powerUpType);
    
    return copyWith(
      availablePowerUps: newAvailablePowerUps,
      usedPowerUps: newUsedPowerUps,
      lastMoveTime: DateTime.now(),
    );
  }

  /// Perform undo
  GameState performUndo() {
    if (!canUndo || remainingUndos <= 0) return this;
    
    return copyWith(
      remainingUndos: remainingUndos - 1,
      canUndo: remainingUndos > 1,
      lastMoveTime: DateTime.now(),
    );
  }

  /// Update performance data
  GameState updatePerformanceData(Map<String, dynamic> data) {
    final newData = Map<String, dynamic>.from(performanceData);
    newData.addAll(data);
    
    return copyWith(performanceData: newData);
  }

  /// Create deep copy of grid
  List<List<bool>> _copyGrid() {
    return grid.map((row) => List<bool>.from(row)).toList();
  }

  /// Calculate level from score
  int _calculateLevel(int currentScore) {
    return (currentScore / GameConstants.pointsPerLevel).floor() + 1;
  }

  /// Calculate level from lines cleared
  int _calculateLevelFromLines(int lines) {
    return (lines / 10).floor() + 1;
  }

  /// Calculate line clear bonus
  int _calculateLineBonus(int lineCount) {
    switch (lineCount) {
      case 1:
        return GameConstants.pointsPerLine;
      case 2:
        return GameConstants.pointsPerLine * 3;
      case 3:
        return GameConstants.pointsPerLine * 5;
      case 4:
        return GameConstants.pointsPerLine * 8;
      default:
        return GameConstants.pointsPerLine * lineCount;
    }
  }

  /// Calculate combo bonus
  int _calculateComboBonus(int combo) {
    if (combo < GameConstants.streakThreshold) return 0;
    
    final multiplier = (combo * GameConstants.streakMultiplier).clamp(
      1.0,
      GameConstants.maxStreakMultiplier.toDouble(),
    );
    
    return (GameConstants.pointsPerLine * multiplier).round();
  }

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  /// Check if game is in initial state
  bool get isInitial => status == GameStateStatus.initial;

  /// Check if game is loading
  bool get isGameLoading => status == GameStateStatus.loading || isLoading;

  /// Check if game is currently playing
  bool get isPlaying => status == GameStateStatus.playing && !isPaused;

  /// Check if game is paused
  bool get isGamePaused => status == GameStateStatus.paused || isPaused;

  /// Check if game is over
  bool get isGameOver => status == GameStateStatus.gameOver;

  /// Check if there's an error
  bool get hasError => status == GameStateStatus.error || errorMessage != null;

  /// Get grid size
  int get gridSize => grid.isNotEmpty ? grid.length : GameConstants.defaultGridSize;

  /// Check if grid is full (game over condition)
  bool get isGridFull {
    if (grid.isEmpty) return false;
    
    // Check if top row has any occupied cells
    return grid.first.any((cell) => cell);
  }

  /// Get current session statistics
  SessionStatistics get sessionStatistics {
    return SessionStatistics(
      blocksPlaced: activeBlocks.length,
      linesCleared: linesCleared,
      powerUpsUsed: usedPowerUps.length,
      perfectClears: 0, // Would be calculated based on grid analysis
      firstBlockTime: performanceData['gameStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(performanceData['gameStartTime'])
          : null,
      lastBlockTime: lastMoveTime,
      scoreHistory: [score], // Simplified for now
      actionCounts: {
        'blocksPlaced': activeBlocks.length,
        'linesCleared': linesCleared,
        'powerUpsUsed': usedPowerUps.length,
        'undosUsed': GameConstants.maxUndoMoves - remainingUndos,
      },
    );
  }

  /// Get difficulty multiplier
  double get difficultyMultiplier {
    return GameConstants.difficultyScoreMultipliers[difficulty.name] ?? 1.0;
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'score': score,
      'level': level,
      'linesCleared': linesCleared,
      'comboCount': comboCount,
      'maxCombo': maxCombo,
      'grid': grid,
      'activeBlocks': activeBlocks.map((b) => b.toJson()).toList(),
      'nextBlocks': nextBlocks.map((b) => b.toJson()).toList(),
      'availablePowerUps': availablePowerUps.map((p) => p.toJson()).toList(),
      'usedPowerUps': usedPowerUps.map((p) => p.name).toList(),
      'canUndo': canUndo,
      'remainingUndos': remainingUndos,
      'currentSession': currentSession?.toJson(),
      'sessionDuration': sessionDuration?.inMilliseconds,
      'isPaused': isPaused,
      'difficulty': difficulty.name,
      'mode': mode.name,
      'performanceData': performanceData,
      'lastMoveTime': lastMoveTime?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      status: GameStateStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GameStateStatus.initial,
      ),
      score: json['score'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      linesCleared: json['linesCleared'] as int? ?? 0,
      comboCount: json['comboCount'] as int? ?? 0,
      maxCombo: json['maxCombo'] as int? ?? 0,
      grid: (json['grid'] as List?)?.map((row) => 
        (row as List).map((cell) => cell as bool).toList()
      ).toList() ?? [],
      activeBlocks: (json['activeBlocks'] as List?)?.map((b) => 
        BlockEntity.fromJson(b as Map<String, dynamic>)
      ).toList() ?? [],
      nextBlocks: (json['nextBlocks'] as List?)?.map((b) => 
        BlockEntity.fromJson(b as Map<String, dynamic>)
      ).toList() ?? [],
      availablePowerUps: (json['availablePowerUps'] as List?)?.map((p) => 
        PowerUp.fromJson(p as Map<String, dynamic>)
      ).toList() ?? [],
      usedPowerUps: (json['usedPowerUps'] as List?)?.map((p) => 
        PowerUpType.values.firstWhere((t) => t.name == p)
      ).toList() ?? [],
      canUndo: json['canUndo'] as bool? ?? false,
      remainingUndos: json['remainingUndos'] as int? ?? 3,
      currentSession: json['currentSession'] != null 
          ? GameSession.fromJson(json['currentSession'])
          : null,
      sessionDuration: json['sessionDuration'] != null 
          ? Duration(milliseconds: json['sessionDuration'])
          : null,
      isPaused: json['isPaused'] as bool? ?? false,
      difficulty: GameDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => GameDifficulty.normal,
      ),
      mode: GameMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => GameMode.classic,
      ),
      performanceData: Map<String, dynamic>.from(json['performanceData'] ?? {}),
      lastMoveTime: json['lastMoveTime'] != null 
          ? DateTime.parse(json['lastMoveTime'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        status,
        score,
        level,
        linesCleared,
        comboCount,
        maxCombo,
        grid,
        activeBlocks,
        nextBlocks,
        availablePowerUps,
        usedPowerUps,
        canUndo,
        remainingUndos,
        currentSession,
        sessionDuration,
        isPaused,
        isLoading,
        errorMessage,
        lastMoveTime,
        difficulty,
        mode,
        performanceData,
      ];
}

/// Game state status enumeration
enum GameStateStatus {
  initial,
  loading,
  playing,
  paused,
  gameOver,
  error;

  String get name => toString().split('.').last;
}