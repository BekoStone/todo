import '../entities/player_stats_entity.dart';
import '../repositories/player_repository.dart';

class UpdatePlayerStats {
  final PlayerRepository repo;
  UpdatePlayerStats(this.repo);
  Future<void> call(PlayerStatsEntity stats) => repo.save(stats);
}

class LoadPlayerStats {
  final PlayerRepository repo;
  LoadPlayerStats(this.repo);
  Future<PlayerStatsEntity?> call() => repo.load();
}
