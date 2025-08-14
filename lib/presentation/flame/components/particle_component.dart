// lib/presentation/flame/components/particle_component.dart
import 'package:flame/components.dart';
import '../../../core/constants/game_constants.dart';

class ParticlePool {
  final List<PositionComponent> _pool = <PositionComponent>[];
  int _index = 0;

  ParticlePool() {
    for (var i = 0; i < GameConstants.particlePoolSize; i++) {
      _pool.add(PositionComponent()..priority = 100); // render on top
    }
  }

  PositionComponent acquire() {
    final c = _pool[_index];
    _index = (_index + 1) % _pool.length;
    return c;
  }
}
