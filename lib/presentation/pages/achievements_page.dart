import 'package:flutter/material.dart';
import '../misc/achievements_manager.dart';

class AchievementsPage extends StatelessWidget {
  static const route = '/achievements';
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mgr = AchievementsManager.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        // automaticallyImplyLeading: true by default → shows back arrow
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: mgr.version,
        builder: (context, _, __) {
          final list = mgr.list;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final a = list[i];
              return ListTile(
                leading: Icon(
                  a.unlocked ? Icons.verified : Icons.lock_outline,
                  color: a.unlocked ? Colors.green : Colors.grey,
                ),
                title: Text(a.title),
                subtitle: Text(a.description),
                trailing: a.unlocked && a.unlockedAt != null
                    ? Text(
                        '${a.unlockedAt!.hour.toString().padLeft(2, '0')}:${a.unlockedAt!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white54),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
