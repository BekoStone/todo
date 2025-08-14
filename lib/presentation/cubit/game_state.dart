import 'package:equatable/equatable.dart';

class GameState extends Equatable {
  final int score;
  final int moves;
  final bool paused;

  const GameState({this.score = 0, this.moves = 0, this.paused = false});

  GameState copyWith({int? score, int? moves, bool? paused}) =>
      GameState(score: score ?? this.score, moves: moves ?? this.moves, paused: paused ?? this.paused);

  @override
  List<Object?> get props => [score, moves, paused];
}
