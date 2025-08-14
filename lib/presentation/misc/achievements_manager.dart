import 'package:flutter/foundation.dart';
import '../../domain/entities/power_up_entity.dart';

enum AchievementId { firstPlacement, firstLine, score500, useBomb, useColor }

class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  bool unlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });
}

class AchievementsManager {
  AchievementsManager._();
  static final AchievementsManager instance = AchievementsManager._();

  final List<Achievement> _list = [
    Achievement(
      id: AchievementId.firstPlacement,
      title: 'First Move',
      description: 'Place your first piece.',
    ),
    Achievement(
      id: AchievementId.firstLine,
      title: 'Line Breaker',
      description: 'Clear a full row or column.',
    ),
    Achievement(
      id: AchievementId.score500,
      title: '500 Club',
      description: 'Reach a score of 500.',
    ),
    Achievement(
      id: AchievementId.useBomb,
      title: 'Bomb Squad',
      description: 'Use the Bomb power-up.',
    ),
    Achievement(
      id: AchievementId.useColor,
      title: 'Color Cleanse',
      description: 'Use the Color power-up.',
    ),
  ];

  final ValueNotifier<int> version = ValueNotifier<int>(0);

  List<Achievement> get list => List.unmodifiable(_list);

  void _unlock(AchievementId id) {
    final a = _list.firstWhere((e) => e.id == id);
    if (!a.unlocked) {
      a.unlocked = true;
      a.unlockedAt = DateTime.now();
      version.value++; // notify listeners
    }
  }

  void onPiecePlaced() => _unlock(AchievementId.firstPlacement);
  void onLineCleared() => _unlock(AchievementId.firstLine);

  void onScoreChanged(int score) {
    if (score >= 500) _unlock(AchievementId.score500);
  }

  void onPowerUpUsed(PowerUpType t) {
    if (t == PowerUpType.bomb) _unlock(AchievementId.useBomb);
    if (t == PowerUpType.color) _unlock(AchievementId.useColor);
  }

  void resetSession() {
    // keep unlocked achievements across sessions; no-op for now
  }
}
