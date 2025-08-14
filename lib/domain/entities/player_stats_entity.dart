class PlayerStatsEntity {
  final int highScore;
  final int gamesPlayed;

  const PlayerStatsEntity({required this.highScore, required this.gamesPlayed});

  Map<String, dynamic> toJson() => {'highScore': highScore, 'gamesPlayed': gamesPlayed};
  factory PlayerStatsEntity.fromJson(Map<String, dynamic> json) =>
      PlayerStatsEntity(highScore: json['highScore'] as int, gamesPlayed: json['gamesPlayed'] as int);
}
