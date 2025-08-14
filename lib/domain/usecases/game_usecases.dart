import '../entities/game_session_entity.dart';
import '../repositories/game_repository.dart';
import '../repositories/asset_repository.dart';

class SaveGameSession {
  final GameRepository repo;
  SaveGameSession(this.repo);
  Future<void> call(GameSessionEntity s) => repo.save(s);
}

class LoadGameSession {
  final GameRepository repo;
  LoadGameSession(this.repo);
  Future<GameSessionEntity?> call() => repo.load();
}

class LoadAssets {
  final AssetRepository repo;
  LoadAssets(this.repo);
  Future<List<String>> call() => repo.listAll();
}
