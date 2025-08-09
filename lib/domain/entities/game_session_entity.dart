import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// GameSession entity represents a single game session.
/// Contains all data for a game instance including progress, settings, and state.
/// Immutable entity following Clean Architecture principles.
class GameSession extends Equatable {
  /// Unique session identifier
  final String sessionId;
  
  /// Session creation timestamp
  final DateTime createdAt;
  
  /// Session last updated timestamp
  final DateTime updatedAt;
  
  /// Game difficulty level
  final GameDifficulty difficulty;
  
  /// Current player score
  final int currentScore;
  
  /// Current game level
  final int currentLevel;
  
  /// Total lines cleared in this session
  final int linesCleared;
  
  /// Current combo count
  final int comboCount;
  
  /// Maximum combo achieved
  final int maxCombo;
  
  /// Total play time for this session
  final Duration playTime;
  
  /// Current game grid state (8x8 matrix)
  final List<List<int>> gridState;
  
  /// Currently active blocks
  final List<String> activeBlockIds;
  
  /// Remaining power-ups
  final Map<String, int> remainingPowerUps;
  
  /// Session statistics
  final SessionStatistics statistics;
  
  /// Whether this is the player's first game
  final bool isFirstGame;
  
  /// Whether the session is completed
  final bool isCompleted;
  
  /// Whether the session was paused
  final bool isPaused;
  
  /// Pause duration (for accurate play time calculation)
  final Duration pauseDuration;
  
  /// Session metadata
  final Map<String, dynamic> metadata;

  const GameSession({
    required this.sessionId,
    required this.createdAt,
    required this.updatedAt,
    required this.difficulty,
    this.currentScore = 0,
    this.currentLevel = 1,
    this.linesCleared = 0,
    this.comboCount = 0,
    this.maxCombo = 0,
    this.playTime = Duration.zero,
    required this.gridState,
    this.activeBlockIds = const [],
    this.remainingPowerUps = const {},
    required this.statistics,
    this.isFirstGame = false,
    this.isCompleted = false,
    this.isPaused = false,
    this.pauseDuration = Duration.zero,
    this.metadata = const {},
  });

  /// Create a new game session
  factory GameSession.create({
    String? sessionId,
    required GameDifficulty difficulty,
    bool isFirstGame = false,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final id = sessionId ?? _generateSessionId();
    
    return GameSession(
      sessionId: id,
      createdAt: now,
      updatedAt: now,
      difficulty: difficulty,
      gridState: _createEmptyGrid(),
      statistics: SessionStatistics.initial(),
      remainingPowerUps: _getInitialPowerUps(difficulty),
      isFirstGame: isFirstGame,
      metadata: metadata ?? {},
    );
  }

  /// Create a copy with updated values
  GameSession copyWith({
    String? sessionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    GameDifficulty? difficulty,
    int? currentScore,
    int? currentLevel,
    int? linesCleared,
    int? comboCount,
    int? maxCombo,
    Duration? playTime,
    List<List<int>>? gridState,
    List<String>? activeBlockIds,
    Map<String, int>? remainingPowerUps,
    SessionStatistics? statistics,
    bool? isFirstGame,
    bool? isCompleted,
    bool? isPaused,
    Duration? pauseDuration,
    Map<String, dynamic>? metadata,
  }) {
    return GameSession(
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      difficulty: difficulty ?? this.difficulty,
      currentScore: currentScore ?? this.currentScore,
      currentLevel: currentLevel ?? this.currentLevel,
      linesCleared: linesCleared ?? this.linesCleared,
      comboCount: comboCount ?? this.comboCount,
      maxCombo: maxCombo ?? this.maxCombo,
      playTime: playTime ?? this.playTime,
      gridState: gridState ?? this.gridState,
      activeBlockIds: activeBlockIds ?? this.activeBlockIds,
      remainingPowerUps: remainingPowerUps ?? this.remainingPowerUps,
      statistics: statistics ?? this.statistics,
      isFirstGame: isFirstGame ?? this.isFirstGame,
      isCompleted: isCompleted ?? this.isCompleted,
      isPaused: isPaused ?? this.isPaused,
      pauseDuration: pauseDuration ?? this.pauseDuration,
      metadata: metadata ?? this.metadata,
    );
  }

  // ========================================
  // SESSION PROPERTIES
  // ========================================

  /// Get actual play time (excluding pause duration)
  Duration get actualPlayTime {
    return playTime - pauseDuration;
  }

  /// Get session progress percentage (based on target score)
  double get progressPercentage {
    final targetScore = _getTargetScore();
    return targetScore > 0 ? (currentScore / targetScore).clamp(0.0, 1.0) : 0.0;
  }

  /// Get grid fill percentage
  double get gridFillPercentage {
    int filledCells = 0;
    for (final row in gridState) {
      filledCells += row.where((cell) => cell != 0).length;
    }
    final totalCells = AppConstants.gridSize * AppConstants.gridSize;
    return (filledCells / totalCells) * 100;
  }

  /// Check if the grid is nearly full
  bool get isGridNearlyFull {
    return gridFillPercentage >= 70.0;
  }

  /// Get difficulty multiplier for scoring
  double get difficultyMultiplier {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 0.8;
      case GameDifficulty.normal:
        return 1.0;
      case GameDifficulty.hard:
        return 1.3;
      case GameDifficulty.expert:
        return 1.6;
    }
  }

  /// Get next level threshold
  int get nextLevelThreshold {
    return currentLevel * AppConstants.linesPerLevel;
  }

  /// Get lines needed for next level
  int get linesToNextLevel {
    return nextLevelThreshold - linesCleared;
  }

  /// Get performance rating for this session
  SessionPerformance get performanceRating {
    final efficiency = statistics.blocksPlaced > 0 
        ? linesCleared / statistics.blocksPlaced 
        : 0.0;
    
    if (efficiency < 0.2) return SessionPerformance.poor;
    if (efficiency < 0.4) return SessionPerformance.average;
    if (efficiency < 0.6) return SessionPerformance.good;
    if (efficiency < 0.8) return SessionPerformance.excellent;
    return SessionPerformance.perfect;
  }

  /// Check if this is a perfect game (no wasted moves)
  bool get isPerfectGame {
    return statistics.blocksPlaced > 0 && 
           (linesCleared / statistics.blocksPlaced) >= 0.9;
  }

  /// Get session duration in formatted string
  String get formattedDuration {
    final duration = actualPlayTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // ========================================
  // SERIALIZATION
  // ========================================

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'difficulty': difficulty.name,
      'currentScore': currentScore,
      'currentLevel': currentLevel,
      'linesCleared': linesCleared,
      'comboCount': comboCount,
      'maxCombo': maxCombo,
      'playTime': playTime.inMilliseconds,
      'gridState': gridState,
      'activeBlockIds': activeBlockIds,
      'remainingPowerUps': remainingPowerUps,
      'statistics': statistics.toJson(),
      'isFirstGame': isFirstGame,
      'isCompleted': isCompleted,
      'isPaused': isPaused,
      'pauseDuration': pauseDuration.inMilliseconds,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      sessionId: json['sessionId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      difficulty: GameDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => GameDifficulty.normal,
      ),
      currentScore: json['currentScore'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      linesCleared: json['linesCleared'] as int? ?? 0,
      comboCount: json['comboCount'] as int? ?? 0,
      maxCombo: json['maxCombo'] as int? ?? 0,
      playTime: Duration(milliseconds: json['playTime'] as int? ?? 0),
      gridState: (json['gridState'] as List).map((row) =>
          (row as List).map((cell) => cell as int).toList()).toList(),
      activeBlockIds: (json['activeBlockIds'] as List?)?.cast<String>() ?? [],
      remainingPowerUps: Map<String, int>.from(json['remainingPowerUps'] ?? {}),
      statistics: SessionStatistics.fromJson(json['statistics']),
      isFirstGame: json['isFirstGame'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isPaused: json['isPaused'] as bool? ?? false,
      pauseDuration: Duration(milliseconds: json['pauseDuration'] as int? ?? 0),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // ========================================
  // PRIVATE HELPERS
  // ========================================

  /// Generate a unique session ID
  static String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'session_${timestamp}_${timestamp.hashCode.abs()}';
  }

  /// Create empty 8x8 grid
  static List<List<int>> _createEmptyGrid() {
    return List.generate(
      AppConstants.gridSize,
      (_) => List.filled(AppConstants.gridSize, 0),
    );
  }

  /// Get initial power-ups based on difficulty
  static Map<String, int> _getInitialPowerUps(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return {
          'undo': 5,
          'hint': 8,
          'shuffle': 3,
        };
      case GameDifficulty.normal:
        return {
          'undo': AppConstants.maxUndoCount,
          'hint': AppConstants.maxHints,
          'shuffle': 2,
        };
      case GameDifficulty.hard:
        return {
          'undo': 2,
          'hint': 3,
          'shuffle': 1,
        };
      case GameDifficulty.expert:
        return {
          'undo': 1,
          'hint': 1,
          'shuffle': 0,
        };
    }
  }

  /// Get target score for progress calculation
  int _getTargetScore() {
    return currentLevel * 1000; // 1000 points per level
  }

  @override
  List<Object?> get props => [
        sessionId,
        createdAt,
        updatedAt,
        difficulty,
        currentScore,
        currentLevel,
        linesCleared,
        comboCount,
        maxCombo,
        playTime,
        gridState,
        activeBlockIds,
        remainingPowerUps,
        statistics,
        isFirstGame,
        isCompleted,
        isPaused,
        pauseDuration,
        metadata,
      ];

  @override
  String toString() {
    return 'GameSession('
        'id: $sessionId, '
        'score: $currentScore, '
        'level: $currentLevel, '
        'duration: $formattedDuration'
        ')';
  }
}

/// Session statistics tracking
class SessionStatistics extends Equatable {
  final int blocksPlaced;
  final int linesCleared;
  final int powerUpsUsed;
  final int perfectClears;
  final DateTime? firstBlockTime;
  final DateTime? lastBlockTime;
  final List<int> scoreHistory;
  final Map<String, int> actionCounts;

  const SessionStatistics({
    this.blocksPlaced = 0,
    this.linesCleared = 0,
    this.powerUpsUsed = 0,
    this.perfectClears = 0,
    this.firstBlockTime,
    this.lastBlockTime,
    this.scoreHistory = const [],
    this.actionCounts = const {},
  });

  /// Create initial statistics
  factory SessionStatistics.initial() {
    return const SessionStatistics(
      actionCounts: {},
      scoreHistory: [],
    );
  }

  /// Create a copy with updated values
  SessionStatistics copyWith({
    int? blocksPlaced,
    int? linesCleared,
    int? powerUpsUsed,
    int? perfectClears,
    DateTime? firstBlockTime,
    DateTime? lastBlockTime,
    List<int>? scoreHistory,
    Map<String, int>? actionCounts,
  }) {
    return SessionStatistics(
      blocksPlaced: blocksPlaced ?? this.blocksPlaced,
      linesCleared: linesCleared ?? this.linesCleared,
      powerUpsUsed: powerUpsUsed ?? this.powerUpsUsed,
      perfectClears: perfectClears ?? this.perfectClears,
      firstBlockTime: firstBlockTime ?? this.firstBlockTime,
      lastBlockTime: lastBlockTime ?? this.lastBlockTime,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      actionCounts: actionCounts ?? this.actionCounts,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'blocksPlaced': blocksPlaced,
      'linesCleared': linesCleared,
      'powerUpsUsed': powerUpsUsed,
      'perfectClears': perfectClears,
      'firstBlockTime': firstBlockTime?.toIso8601String(),
      'lastBlockTime': lastBlockTime?.toIso8601String(),
      'scoreHistory': scoreHistory,
      'actionCounts': actionCounts,
    };
  }

  /// Create from JSON
  factory SessionStatistics.fromJson(Map<String, dynamic> json) {
    return SessionStatistics(
      blocksPlaced: json['blocksPlaced'] as int? ?? 0,
      linesCleared: json['linesCleared'] as int? ?? 0,
      powerUpsUsed: json['powerUpsUsed'] as int? ?? 0,
      perfectClears: json['perfectClears'] as int? ?? 0,
      firstBlockTime: json['firstBlockTime'] != null
          ? DateTime.parse(json['firstBlockTime'] as String)
          : null,
      lastBlockTime: json['lastBlockTime'] != null
          ? DateTime.parse(json['lastBlockTime'] as String)
          : null,
      scoreHistory: (json['scoreHistory'] as List?)?.cast<int>() ?? [],
      actionCounts: Map<String, int>.from(json['actionCounts'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        blocksPlaced,
        linesCleared,
        powerUpsUsed,
        perfectClears,
        firstBlockTime,
        lastBlockTime,
        scoreHistory,
        actionCounts,
      ];
}

/// Game difficulty enumeration
enum GameDifficulty {
  easy,
  normal,
  hard,
  expert;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.normal:
        return 'Normal';
      case GameDifficulty.hard:
        return 'Hard';
      case GameDifficulty.expert:
        return 'Expert';
    }
  }

  String get description {
    switch (this) {
      case GameDifficulty.easy:
        return 'More power-ups, relaxed gameplay';
      case GameDifficulty.normal:
        return 'Balanced experience for most players';
      case GameDifficulty.hard:
        return 'Fewer power-ups, increased challenge';
      case GameDifficulty.expert:
        return 'Minimal power-ups, maximum challenge';
    }
  }
}

/// Session performance rating
enum SessionPerformance {
  poor,
  average,
  good,
  excellent,
  perfect;

  String get displayName {
    switch (this) {
      case SessionPerformance.poor:
        return 'Needs Improvement';
      case SessionPerformance.average:
        return 'Average';
      case SessionPerformance.good:
        return 'Good';
      case SessionPerformance.excellent:
        return 'Excellent';
      case SessionPerformance.perfect:
        return 'Perfect';
    }
  }

  String get description {
    switch (this) {
      case SessionPerformance.poor:
        return 'Keep practicing to improve efficiency';
      case SessionPerformance.average:
        return 'Decent performance, room for improvement';
      case SessionPerformance.good:
        return 'Good block placement efficiency';
      case SessionPerformance.excellent:
        return 'Excellent strategic gameplay';
      case SessionPerformance.perfect:
        return 'Flawless execution!';
    }
  }
}