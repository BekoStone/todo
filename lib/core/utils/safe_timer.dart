import 'dart:async';

/// A timer that always cancels itself safely.
/// Use instead of raw [Timer] to avoid leaks.
class SafeTimer {
  Timer? _timer;

  SafeTimer.periodic(Duration duration, void Function(Timer) callback) {
    _timer = Timer.periodic(duration, callback);
  }

  SafeTimer.once(Duration duration, void Function() callback) {
    _timer = Timer(duration, callback);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isActive => _timer?.isActive ?? false;
}
