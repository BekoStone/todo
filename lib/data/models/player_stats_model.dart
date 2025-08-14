import '../../domain/entities/player_stats_entity.dart';

class PlayerStatsModel {
  final int highScore;
  final int gamesPlayed;

  const PlayerStatsModel({required this.highScore, required this.gamesPlayed});

  PlayerStatsEntity toEntity() => PlayerStatsEntity(highScore: highScore, gamesPlayed: gamesPlayed);

  Map<String, dynamic> toJson() => {'highScore': highScore, 'gamesPlayed': gamesPlayed};
  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) =>
      PlayerStatsModel(highScore: json['highScore'] as int, gamesPlayed: json['gamesPlayed'] as int);
}
