import '../entities/player_stats_entity.dart';
import '../entities/achievement_entity.dart';

abstract class PlayerRepository {
  Future<PlayerStatsEntity?> load();
  Future<void> save(PlayerStatsEntity stats);
  Future<void> unlock(AchievementEntity achievement);
}
