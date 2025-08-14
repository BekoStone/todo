import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/player_usecases.dart';
import '../../domain/entities/player_stats_entity.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final LoadPlayerStats load;
  final UpdatePlayerStats save;

  PlayerCubit({required this.load, required this.save}) : super(const PlayerState());

  Future<void> hydrate() async {
    final stats = await load();
    if (stats != null) {
      emit(PlayerState(highScore: stats.highScore, gamesPlayed: stats.gamesPlayed));
    }
  }

  Future<void> recordGame(int score) async {
    final high = score > state.highScore ? score : state.highScore;
    final next = PlayerState(highScore: high, gamesPlayed: state.gamesPlayed + 1);
    emit(next);
    await save(PlayerStatsEntity(highScore: next.highScore, gamesPlayed: next.gamesPlayed));
  }
}
