import 'package:flutter/material.dart';

class GameHud extends StatelessWidget {
  final VoidCallback onPause;
  final VoidCallback onRestart;

  const GameHud({super.key, required this.onPause, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      right: 20,
      child: Row(
        children: [
          IconButton(onPressed: onPause, icon: const Icon(Icons.pause)),
          IconButton(onPressed: onRestart, icon: const Icon(Icons.refresh)),
        ],
      ),
    );
  }
}
