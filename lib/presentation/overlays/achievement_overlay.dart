import 'package:flutter/material.dart';

class AchievementOverlay extends StatelessWidget {
  const AchievementOverlay({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Text(text),
        ),
      ),
    );
  }
}
