class GameSessionEntity {
  final int score;
  final int moves;
  const GameSessionEntity({required this.score, required this.moves});

  Map<String, dynamic> toJson() => {'score': score, 'moves': moves};
  factory GameSessionEntity.fromJson(Map<String, dynamic> json) =>
      GameSessionEntity(score: json['score'] as int, moves: json['moves'] as int);
}
