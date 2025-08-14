import 'package:flutter/material.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      color: Colors.black54,
      child: Center(child: Text('Paused')),
    );
  }
}
