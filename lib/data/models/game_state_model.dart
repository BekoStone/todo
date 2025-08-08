import 'package:equatable/equatable.dart';
import 'block_model.dart';

class GameStateModel extends Equatable {
  final int score;
  final int level;
  final int linesCleared;
  final int combo;
  final int streak;
  final List<List<bool>> grid;
  final List<BlockModel> activeBlocks;
  final DateTime lastPlayed;
  final Duration timePlayed;
  final bool isGameOver;
  final Map<String, dynamic> metadata;
  
  const GameStateModel({
    required this.score,
    required this.level,
    required this.linesCleared,
    required this.combo,
    required this.streak,
    required this.grid,
    required this.activeBlocks,
    required this.lastPlayed,
    required this.timePlayed,
    this.isGameOver = false,
    this.metadata = const {},
  });
  
  // Create empty/initial game state
  factory GameStateModel.initial() {
    return GameStateModel(
      score: 0,
      level: 1,
      linesCleared: 0,
      combo: 0,
      streak: 0,
      grid: List.generate(8, (_) => List.filled(8, false)),
      activeBlocks: [],
      lastPlayed: DateTime.now(),
      timePlayed: Duration.zero,
      isGameOver: false,
      metadata: {},
    );
  }
  
  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'linesCleared': linesCleared,
      'combo': combo,
      'streak': streak,
      'grid': grid.map((row) => row.map((cell) => cell ? 1 : 0).toList()).toList(),
      'activeBlocks': activeBlocks.map((block) => block.toJson()).toList(),
      'lastPlayed': lastPlayed.toIso8601String(),
      'timePlayed': timePlayed.inSeconds,
      'isGameOver': isGameOver,
      'metadata': metadata,
    };
  }
  
  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    return GameStateModel(
      score: json['score'] ?? 0,
      level: json['level'] ?? 1,
      linesCleared: json['linesCleared'] ?? 0,
      combo: json['combo'] ?? 0,
      streak: json['streak'] ?? 0,
      grid: (json['grid'] as List?)?.map((row) => 
        (row as List).map((cell) => cell == 1).toList()
      ).toList() ?? List.generate(8, (_) => List.filled(8, false)),
      activeBlocks: (json['activeBlocks'] as List?)?.map((block) => 
        BlockModel.fromJson(block as Map<String, dynamic>)
      ).toList() ?? [],
      lastPlayed: DateTime.tryParse(json['lastPlayed'] ?? '') ?? DateTime.now(),
      timePlayed: Duration(seconds: json['timePlayed'] ?? 0),
      isGameOver: json['isGameOver'] ?? false,
      metadata: json['metadata'] ?? {},
    );
  }
  
  // Copy with modifications
  GameStateModel copyWith({
    int? score,
    int? level,
    int? linesCleared,
    int? combo,
    int? streak,
    List<List<bool>>? grid,
    List<BlockModel>? activeBlocks,
    DateTime? lastPlayed,
    Duration? timePlayed,
    bool? isGameOver,
    Map<String, dynamic>? metadata,
  }) {
    return GameStateModel(
      score: score ?? this.score,
      level: level ?? this.level,
      linesCleared: linesCleared ?? this.linesCleared,
      combo: combo ?? this.combo,
      streak: streak ?? this.streak,
      grid: grid ?? this.grid,
      activeBlocks: activeBlocks ?? this.activeBlocks,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      timePlayed: timePlayed ?? this.timePlayed,
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
  
  bool get isHighScore => score > (metadata['bestScore'] ?? 0);
  bool get isNewLevel => level > (metadata['lastLevel'] ?? 1);
  
  // Calculate efficiency metrics
  double get efficiency {
    if (linesCleared == 0) return 0;
    return score / (linesCleared * 100);
  }
  
  double get comboEfficiency {
    if (combo == 0) return 0;
    return score / (combo * 500);
  }
  
  @override
  List<Object?> get props => [
    score,
    level,
    linesCleared,
    combo,
    streak,
    grid,
    activeBlocks,
    lastPlayed,
    timePlayed,
    isGameOver,
    metadata,
  ];
}