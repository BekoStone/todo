import 'package:flutter/material.dart';
import 'game_page.dart';
import 'achievements_page.dart';

class MainMenuPage extends StatelessWidget {
  static const route = '/menu';
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, GamePage.route), child: const Text('Play')),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, AchievementsPage.route), child: const Text('Achievements')),
          ],
        ),
      ),
    );
  }
}
