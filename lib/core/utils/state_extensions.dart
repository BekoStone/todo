// lib/core/utils/state_extensions.dart
typedef Emitter<S> = void Function(S);

extension EmitIfChanged<S> on Emitter<S> {
  /// Call the emitter only if [current] differs from [next].
  void emitIfChanged(S current, S next) {
    if (current != next) {
      this(next); // call the function directly
    }
  }
}
