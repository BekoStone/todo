class PerformanceUtils {
  static int? _coldStartMsStart;
  static int? _firstFrameMs;

  static void markColdStart() {
    _coldStartMsStart = DateTime.now().millisecondsSinceEpoch;
  }

  static void markFirstFrame() {
    final start = _coldStartMsStart;
    if (start == null) return;
    _firstFrameMs = DateTime.now().millisecondsSinceEpoch - start;
  }

  static int? get coldStartMs => _firstFrameMs;

  static void markFrameStart() {}
  static void markFrameEnd() {}
}
