import 'package:flame/components.dart' show Vector2;
import '../../../domain/entities/power_up_entity.dart';
import '../components/grid_component.dart';

class PowerUpSystem {
  PowerUpType? _active;

  // Start with 2 of each
  final Map<PowerUpType, int> _counts = {
    PowerUpType.bomb: 2,
    PowerUpType.line: 2,
    PowerUpType.color: 2,
  };

  Map<PowerUpType, int> get counts => Map.unmodifiable(_counts);
  bool get isActive => _active != null;
  PowerUpType? get active => _active;

  bool canActivate(PowerUpType t) => (_counts[t] ?? 0) > 0;

  bool activate(PowerUpEntity p) {
    final t = p.type;
    if (!canActivate(t)) return false;
    _active = t;
    return true;
  }

  void cancel() {
    _active = null;
  }

  /// Apply the active power-up at a world position on the grid.
  /// Returns cleared cells count.
  int apply(GridComponent grid, Vector2 worldPos) {
    final type = _active;
    if (type == null) return 0;

    final cell = grid.pointToCell(worldPos);
    if (cell == null) return 0;

    int cleared = 0;
    switch (type) {
      case PowerUpType.bomb:
        cleared = grid.clearArea(centerR: cell.r, centerC: cell.c, radius: 1); // 3x3
        break;
      case PowerUpType.line:
        cleared = grid.clearRow(cell.r);
        break;
      case PowerUpType.color:
        final tappedColor = grid.cellColorAt(cell.r, cell.c);
        if (tappedColor != null) {
          cleared = grid.clearAllOfColor(tappedColor);
        }
        break;
    }

    if (cleared > 0) {
      _counts[type] = (_counts[type] ?? 0) - 1;
    }

    _active = null; // consume
    return cleared;
  }

  void grant(PowerUpType t, int amount) {
    _counts[t] = (_counts[t] ?? 0) + amount;
  }
}
