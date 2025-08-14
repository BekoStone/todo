import 'package:flutter_bloc/flutter_bloc.dart';

extension SafeEmit<S> on Cubit<S> {
  void emitIf(bool condition, S state) {
    if (condition) emit(state);
  }
}
