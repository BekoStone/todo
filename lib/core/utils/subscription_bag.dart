import 'dart:async';

/// Holds stream subscriptions and cancels all on dispose().
class SubscriptionBag {
  final _subs = <StreamSubscription<dynamic>>[];

  void add(StreamSubscription<dynamic> s) => _subs.add(s);

  void cancelAll() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }
}
