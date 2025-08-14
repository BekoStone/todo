import 'package:flutter/material.dart';
import '../widgets/animated_counter.dart';

class GameBoard extends StatelessWidget {
  final int score;
  final int moves;

  const GameBoard({super.key, required this.score, required this.moves});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Placeholder board background (grid rendered by Flame underlay)
        Positioned.fill(
          child: Container(decoration: const BoxDecoration(color: Colors.transparent)),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Row(
            children: [
              const Text('Score: '),
              AnimatedCounter(value: score),
              const SizedBox(width: 16),
              const Text('Moves: '),
              AnimatedCounter(value: moves),
            ],
          ),
        ),
      ],
    );
  }
}
