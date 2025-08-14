// lib/presentation/flame/game_world.dart
import 'dart:async' as dt;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import '../../core/utils/safe_timer.dart';
import '../../core/utils/subscription_bag.dart';

class GameWorld extends Component with HasGameRef<FlameGame> {
  final SubscriptionBag _subs = SubscriptionBag();
  SafeTimer? _tick;

  @override
  Future<void> onLoad() async {
    _tick = SafeTimer.periodic(const Duration(milliseconds: 250), _onTick);
  }

  void _onTick(dt.Timer _) {
    // periodic world logic
  }

  void listen<T>(Stream<T> stream, void Function(T) onData) {
    final sub = stream.listen(onData);
    _subs.add(sub);
  }

  @override
  void onRemove() {
    _tick?.cancel();
    _tick = null;
    _subs.cancelAll();
    super.onRemove();
  }
}
