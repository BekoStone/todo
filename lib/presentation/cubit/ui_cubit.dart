import 'package:flutter_bloc/flutter_bloc.dart';
import 'ui_state.dart';

class UiCubit extends Cubit<UiState> {
  UiCubit() : super(const UiState());

  void showPauseOverlay(bool show) => emit(state.copyWith(showPause: show));
  void showHudOverlay(bool show) => emit(state.copyWith(showHud: show));
}
