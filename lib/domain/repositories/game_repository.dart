import '../entities/game_session_entity.dart';

abstract class GameRepository {
  Future<void> save(GameSessionEntity session);
  Future<GameSessionEntity?> load();
}
