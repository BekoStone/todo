import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(const GameState());

  void addScore(int delta) => emit(state.copyWith(score: state.score + delta));
  void addMove() => emit(state.copyWith(moves: state.moves + 1));
  void pause() => emit(state.copyWith(paused: true));
  void resume() => emit(state.copyWith(paused: false));
  void reset() => emit(const GameState());
}
