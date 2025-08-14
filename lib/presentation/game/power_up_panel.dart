import 'package:flutter/material.dart';
import '../../domain/entities/power_up_entity.dart';

class PowerUpPanel extends StatelessWidget {
  final void Function(PowerUpEntity) onUse;
  final Map<PowerUpType, int> counts;

  const PowerUpPanel({
    super.key,
    required this.onUse,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn(context, 'Bomb', PowerUpType.bomb),
          _btn(context, 'Line', PowerUpType.line),
          _btn(context, 'Color', PowerUpType.color), // ✅ restored
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, String label, PowerUpType t) {
    final left = counts[t] ?? 0;
    final text = left > 0 ? '$label ($left)' : '$label (Get)';
    return ElevatedButton(
      onPressed: () => onUse(PowerUpEntity(t)),
      child: Text(text),
    );
  }
}
