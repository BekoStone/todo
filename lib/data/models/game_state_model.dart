import '../../domain/entities/game_session_entity.dart';

class GameStateModel {
  final int score;
  final int moves;

  const GameStateModel({required this.score, required this.moves});

  GameSessionEntity toEntity() => GameSessionEntity(score: score, moves: moves);

  Map<String, dynamic> toJson() => {'score': score, 'moves': moves};
  factory GameStateModel.fromJson(Map<String, dynamic> json) =>
      GameStateModel(score: json['score'] as int, moves: json['moves'] as int);
}
