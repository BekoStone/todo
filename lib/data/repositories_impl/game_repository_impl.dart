import '../../domain/entities/game_session_entity.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/local_storage_datasource.dart';

class GameRepositoryImpl implements GameRepository {
  final LocalStorageDatasource local;
  GameRepositoryImpl({required this.local});

  @override
  Future<GameSessionEntity?> load() async {
    final json = await local.loadGameSession();
    if (json == null) return null;
    return GameSessionEntity.fromJson(json);
  }

  @override
  Future<void> save(GameSessionEntity session) =>
      local.saveGameSession(session.toJson());
}
