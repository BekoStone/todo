abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object?> parameters = const {}});
  Future<void> dispose();
}

class AnalyticsServiceImpl implements AnalyticsService {
  bool _disposed = false;

  @override
  Future<void> logEvent(String name, {Map<String, Object?> parameters = const {}}) async {
    if (_disposed) return;
    // Wire to a real analytics SDK here.
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }
}
