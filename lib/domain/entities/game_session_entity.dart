import 'package:equatable/equatable.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';

class GameSession extends Equatable {
  final String id;
  final int score;
  final int level;
  final int linesCleared;
  final int comboCount;
  final int streakCount;
  final List<List<bool>> grid;
  final List<Block> activeBlocks;
  final DateTime startTime;
  final DateTime lastPlayTime;
  final Duration totalPlayTime;
  final bool isGameOver;
  final Map<String, dynamic> metadata;
  
  const GameSession({
    required this.id,
    this.score = 0,
    this.level = 1,
    this.linesCleared = 0,
    this.comboCount = 0,
    this.streakCount = 0,
    required this.grid,
    this.activeBlocks = const [],
    required this.startTime,
    required this.lastPlayTime,
    this.totalPlayTime = Duration.zero,
    this.isGameOver = false,
    this.metadata = const {},
  });
  
  // Create new game session
  factory GameSession.newGame() {
    final now = DateTime.now();
    final sessionId = 'session_${now.millisecondsSinceEpoch}';
    
    return GameSession(
      id: sessionId,
      grid: List.generate(8, (_) => List.filled(8, false)),
      startTime: now,
      lastPlayTime: now,
    );
  }
  
  // Copy with modifications
  GameSession copyWith({
    String? id,
    int? score,
    int? level,
    int? linesCleared,
    int? comboCount,
    int? streakCount,
    List<List<bool>>? grid,
    List<Block>? activeBlocks,
    DateTime? startTime,
    DateTime? lastPlayTime,
    Duration? totalPlayTime,
    bool? isGameOver,
    Map<String, dynamic>? metadata,
  }) {
    return GameSession(
      id: id ?? this.id,
      score: score ?? this.score,
      level: level ?? this.level,
      linesCleared: linesCleared ?? this.linesCleared,
      comboCount: comboCount ?? this.comboCount,
      streakCount: streakCount ?? this.streakCount,
      grid: grid ?? this.grid,
      activeBlocks: activeBlocks ?? this.activeBlocks,
      startTime: startTime ?? this.startTime,
      lastPlayTime: lastPlayTime ?? this.lastPlayTime,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      isGameOver: isGameOver ?? this.isGameOver,
      metadata: metadata ?? this.metadata,
    );
  }
  
  // Game state analysis
  double get gridFillPercentage {
    int filledCells = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell) filledCells++;
      }
    }
    return (filledCells / 64) * 100;
  }
  
  bool get hasActiveBlocks => activeBlocks.isNotEmpty;
  
  Duration get currentSessionTime {
    return DateTime.now().difference(startTime);
  }
  
  // Scoring calculations
  int get pointsPerMinute {
    final minutes = totalPlayTime.inMinutes;
    return minutes > 0 ? (score / minutes).round() : 0;
  }
  
  double get efficiency {
    if (linesCleared == 0) return 0.0;
    return score / (linesCleared * 100);
  }
  
  // Level progression
  int get requiredLinesForNextLevel => level * 10;
  int get progressToNextLevel => linesCleared % 10;
  double get levelProgress => progressToNextLevel / 10.0;
  
  // Performance metrics
  String get performanceRating {
    final avgScore = totalPlayTime.inMinutes > 0 ? pointsPerMinute : 0;
    
    if (avgScore >= 200) return 'Master';
    if (avgScore >= 150) return 'Expert';
    if (avgScore >= 100) return 'Advanced';
    if (avgScore >= 50) return 'Intermediate';
    return 'Beginner';
  }
  
  // Game difficulty estimation
  String get difficulty {
    if (gridFillPercentage >= 80) return 'Extreme';
    if (gridFillPercentage >= 60) return 'Hard';
    if (gridFillPercentage >= 40) return 'Medium';
    if (gridFillPercentage >= 20) return 'Easy';
    return 'Very Easy';
  }
  
  // Check if this is a new high score
  bool isHigherScoreThan(int previousBest) => score > previousBest;
  
  // Check if this is a long session
  bool get isLongSession => currentSessionTime.inMinutes >= 10;
  
  // Check if this is a perfect game (no game over)
  bool get isPerfectGame => !isGameOver && score > 1000;
  
  // Streak analysis
  bool get hasActiveStreak => streakCount > 2;
  bool get hasActiveCombo => comboCount > 2;
  
  // Save data summary for persistence
  Map<String, dynamic> getSaveData() {
    return {
      'id': id,
      'score': score,
      'level': level,
      'linesCleared': linesCleared,
      'comboCount': comboCount,
      'streakCount': streakCount,
      'startTime': startTime.toIso8601String(),
      'totalPlayTime': totalPlayTime.inSeconds,
      'isGameOver': isGameOver,
      'gridFillPercentage': gridFillPercentage,
      'performance': performanceRating,
      'difficulty': difficulty,
    };
  }
  
  @override
  List<Object?> get props => [
    id,
    score,
    level,
    linesCleared,
    comboCount,
    streakCount,
    grid,
    activeBlocks,
    startTime,
    lastPlayTime,
    totalPlayTime,
    isGameOver,
    metadata,
  ];
}