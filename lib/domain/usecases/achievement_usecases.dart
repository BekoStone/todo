import '../entities/achievement_entity.dart';
import '../repositories/player_repository.dart';

class UnlockAchievement {
  final PlayerRepository repo;
  UnlockAchievement(this.repo);
  Future<void> call(AchievementEntity ach) => repo.unlock(ach);
}
