import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/player_stats_entity.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/local_storage_datasource.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final LocalStorageDatasource local;
  PlayerRepositoryImpl({required this.local});

  @override
  Future<PlayerStatsEntity?> load() async {
    final json = await local.loadPlayerStats();
    return json == null ? null : PlayerStatsEntity.fromJson(json);
  }

  @override
  Future<void> save(PlayerStatsEntity stats) =>
      local.savePlayerStats(stats.toJson());

  @override
  Future<void> unlock(AchievementEntity achievement) async {
    // Persist unlocked achievement if needed (append to list or track flag)
  }
}
