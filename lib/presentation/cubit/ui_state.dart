import 'package:equatable/equatable.dart';

class UiState extends Equatable {
  final bool showHud;
  final bool showPause;

  const UiState({this.showHud = true, this.showPause = false});

  UiState copyWith({bool? showHud, bool? showPause}) =>
      UiState(showHud: showHud ?? this.showHud, showPause: showPause ?? this.showPause);

  @override
  List<Object?> get props => [showHud, showPause];
}
