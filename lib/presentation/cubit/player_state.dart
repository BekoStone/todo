import 'package:equatable/equatable.dart';

class PlayerState extends Equatable {
  final int highScore;
  final int gamesPlayed;

  const PlayerState({this.highScore = 0, this.gamesPlayed = 0});

  PlayerState copyWith({int? highScore, int? gamesPlayed}) =>
      PlayerState(highScore: highScore ?? this.highScore, gamesPlayed: gamesPlayed ?? this.gamesPlayed);

  @override
  List<Object?> get props => [highScore, gamesPlayed];
}
