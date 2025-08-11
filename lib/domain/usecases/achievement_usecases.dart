import 'dart:developer' as developer;
import 'package:puzzle_box/core/errors/exceptions_dart.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/repositories/player_repository.dart';

/// Data class for achievement progress updates
class AchievementProgressUpdate {
  final String achievementId;
  final int currentProgress;
  final bool isIncrement;

  const AchievementProgressUpdate({
    required this.achievementId,
    required this.currentProgress,
    this.isIncrement = false,
  });
}

/// Result of achievement checking operations
class AchievementCheckResult {
  final List<Achievement> newlyUnlocked;
  final List<Achievement> progressUpdated;
  final bool hasNewUnlocks;

  const AchievementCheckResult({
    required this.newlyUnlocked,
    required this.progressUpdated,
    required this.hasNewUnlocks,
  });
}

/// Statistics about player's achievement progress
class AchievementStatistics {
  final int totalAchievements;
  final int unlockedAchievements;
  final int secretAchievements;
  final int unlockedSecrets;
  final double completionPercentage;
  final int totalCoinsEarned;
  final Map<AchievementCategory, int> categoryProgress;
  final List<Achievement> recentlyUnlocked;

  const AchievementStatistics({
    required this.totalAchievements,
    required this.unlockedAchievements,
    required this.secretAchievements,
    required this.unlockedSecrets,
    required this.completionPercentage,
    required this.totalCoinsEarned,
    required this.categoryProgress,
    required this.recentlyUnlocked,
  });

  Map<String, dynamic> toMap() => {
    'total_achievements': totalAchievements,
    'unlocked_achievements': unlockedAchievements,
    'secret_achievements': secretAchievements,
    'unlocked_secrets': unlockedSecrets,
    'completion_percentage': completionPercentage,
    'total_coins_earned': totalCoinsEarned,
    'category_progress': categoryProgress.map((k, v) => MapEntry(k.name, v)),
    'recently_unlocked': recentlyUnlocked.map((a) => a.toMap()).toList(),
  };
}

/// Use cases for achievement management
class AchievementUseCases {
  final PlayerRepository _playerRepository;

  const AchievementUseCases(this._playerRepository);

  /// Get all available achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      return await _playerRepository.getAchievements();
    } catch (e) {
      developer.log('Failed to get all achievements: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to get achievements: $e');
    }
  }

  /// Unlock a specific achievement
  Future<Achievement?> unlockAchievement(String achievementId) async {
    try {
      final achievements = await _playerRepository.getAchievements();
      final achievement = achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => throw NotFoundException('Achievement not found: $achievementId'),
      );

      if (achievement.isUnlocked) {
        developer.log('Achievement already unlocked: $achievementId', name: 'AchievementUseCases');
        return null;
      }

      final unlockedAchievement = achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        currentProgress: achievement.targetValue,
      );

      await _playerRepository.updateAchievement(unlockedAchievement);
      
      developer.log('Achievement unlocked: ${achievement.title}', name: 'AchievementUseCases');
      return unlockedAchievement;
    } catch (e) {
      developer.log('Failed to unlock achievement: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to unlock achievement: $e');
    }
  }

  /// Get achievement progress for a specific achievement
  Future<double> getAchievementProgress(String achievementId, PlayerStats? playerStats) async {
    try {
      final achievements = await _playerRepository.getAchievements();
      final achievement = achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => throw NotFoundException('Achievement not found: $achievementId'),
      );

      if (achievement.isUnlocked) {
        return 1.0;
      }

      return (achievement.currentProgress / achievement.targetValue).clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Failed to get achievement progress: $e', name: 'AchievementUseCases');
      return 0.0;
    }
  }

  /// Update achievement progress and check for unlocks
  Future<AchievementCheckResult> updateAchievementProgress(
    AchievementProgressUpdate update,
  ) async {
    try {
      final currentStats = await _playerRepository.loadPlayerStats();
      final achievements = await _playerRepository.getAchievements();
      
      final achievement = achievements.firstWhere(
        (a) => a.id == update.achievementId,
        orElse: () => throw NotFoundException('Achievement not found: ${update.achievementId}'),
      );

      // Skip if already unlocked
      if (achievement.isUnlocked) {
        return const AchievementCheckResult(
          newlyUnlocked: [],
          progressUpdated: [],
          hasNewUnlocks: false,
        );
      }

      // Calculate new progress
      final newProgress = update.isIncrement
          ? achievement.currentProgress + update.currentProgress
          : update.currentProgress;

      // Update achievement progress
      final updatedAchievement = achievement.copyWith(
        currentProgress: newProgress.clamp(0, achievement.targetValue),
      );

      // Check if achievement should be unlocked
      final shouldUnlock = updatedAchievement.currentProgress >= updatedAchievement.targetValue;
      
      final newlyUnlocked = <Achievement>[];
      final progressUpdated = <Achievement>[updatedAchievement];

      if (shouldUnlock && !updatedAchievement.isUnlocked) {
        final unlockedAchievement = updatedAchievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        
        newlyUnlocked.add(unlockedAchievement);
        progressUpdated.clear();
        progressUpdated.add(unlockedAchievement);

        // Award coins for achievement
        if (currentStats != null) {
          await _playerRepository.updatePlayerStats(
            currentStats.copyWith(
              totalCoins: currentStats.totalCoins + achievement.coinReward,
            ),
          );
        }

        developer.log(
          'Achievement unlocked: ${achievement.title} (+${achievement.coinReward} coins)',
          name: 'AchievementUseCases',
        );
      }

      // Save updated achievement
      await _playerRepository.updateAchievement(progressUpdated.first);

      return AchievementCheckResult(
        newlyUnlocked: newlyUnlocked,
        progressUpdated: progressUpdated,
        hasNewUnlocks: newlyUnlocked.isNotEmpty,
      );

    } catch (e) {
      developer.log('Failed to update achievement progress: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to update achievement progress: $e');
    }
  }

  /// Update multiple achievements at once
  Future<AchievementCheckResult> updateMultipleAchievements(
    List<AchievementProgressUpdate> updates,
  ) async {
    try {
      final allNewlyUnlocked = <Achievement>[];
      final allProgressUpdated = <Achievement>[];

      for (final update in updates) {
        final result = await updateAchievementProgress(update);
        allNewlyUnlocked.addAll(result.newlyUnlocked);
        allProgressUpdated.addAll(result.progressUpdated);
      }

      return AchievementCheckResult(
        newlyUnlocked: allNewlyUnlocked,
        progressUpdated: allProgressUpdated,
        hasNewUnlocks: allNewlyUnlocked.isNotEmpty,
      );

    } catch (e) {
      developer.log('Failed to update multiple achievements: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to update multiple achievements: $e');
    }
  }

  /// Check game completion achievements
  Future<List<Achievement>> checkCompletionAchievements({
    required int finalScore,
    required int level,
    required int linesCleared,
    required Duration gameDuration,
    required bool usedUndo,
    required PlayerStats stats,
  }) async {
    try {
      final updates = <AchievementProgressUpdate>[];

      // Score achievements
      if (finalScore >= 1000) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'score_1000',
          currentProgress: 1,
        ));
      }
      if (finalScore >= 5000) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'score_5000',
          currentProgress: 1,
        ));
      }
      if (finalScore >= 10000) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'score_10000',
          currentProgress: 1,
        ));
      }

      // Level achievements
      if (level >= 5) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'level_5',
          currentProgress: 1,
        ));
      }
      if (level >= 10) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'level_10',
          currentProgress: 1,
        ));
      }

      // Lines cleared achievements
      updates.add(AchievementProgressUpdate(
        achievementId: 'clear_100_lines',
        currentProgress: linesCleared,
        isIncrement: true,
      ));

      // Perfect game (no undo used)
      if (!usedUndo && finalScore > 0) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'perfect_game',
          currentProgress: 1,
        ));
      }

      // Speed achievements (complete game quickly)
      if (gameDuration.inMinutes < 5 && finalScore >= 1000) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'speed_demon',
          currentProgress: 1,
        ));
      }

      // Marathon achievement (long game)
      if (gameDuration.inMinutes >= 30) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'marathon',
          currentProgress: 1,
        ));
      }

      if (updates.isNotEmpty) {
        final result = await updateMultipleAchievements(updates);
        return result.newlyUnlocked;
      }

      return [];
    } catch (e) {
      developer.log('Failed to check completion achievements: $e', name: 'AchievementUseCases');
      return [];
    }
  }

  /// Check beginner achievements
  Future<void> checkBeginnerAchievements() async {
    try {
      final updates = <AchievementProgressUpdate>[
        const AchievementProgressUpdate(
          achievementId: 'welcome',
          currentProgress: 1,
        ),
        const AchievementProgressUpdate(
          achievementId: 'first_game',
          currentProgress: 1,
        ),
      ];

      await updateMultipleAchievements(updates);
    } catch (e) {
      developer.log('Failed to check beginner achievements: $e', name: 'AchievementUseCases');
    }
  }

  /// Check progress-based achievements
  Future<void> checkProgressAchievements(PlayerStats stats) async {
    try {
      final updates = <AchievementProgressUpdate>[];

      // Games played achievements
      if (stats.totalGamesPlayed >= 10) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'play_10_games',
          currentProgress: 1,
        ));
      }
      if (stats.totalGamesPlayed >= 50) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'play_50_games',
          currentProgress: 1,
        ));
      }
      if (stats.totalGamesPlayed >= 100) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'play_100_games',
          currentProgress: 1,
        ));
      }

      // Total score achievements
      if (stats.totalScore >= 50000) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'total_score_50k',
          currentProgress: 1,
        ));
      }
      if (stats.totalScore >= 100000) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'total_score_100k',
          currentProgress: 1,
        ));
      }

      // Time played achievements
      if (stats.totalTimePlayed.inHours >= 1) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'play_1_hour',
          currentProgress: 1,
        ));
      }
      if (stats.totalTimePlayed.inHours >= 10) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'play_10_hours',
          currentProgress: 1,
        ));
      }

      if (updates.isNotEmpty) {
        await updateMultipleAchievements(updates);
      }
    } catch (e) {
      developer.log('Failed to check progress achievements: $e', name: 'AchievementUseCases');
    }
  }

  /// Check game-specific achievements
  Future<void> checkGameAchievements({
    required int score,
    required int level,
    required int linesCleared,
    required int comboCount,
  }) async {
    try {
      final updates = <AchievementProgressUpdate>[];

      // Combo achievements
      if (comboCount >= 5) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'combo_5',
          currentProgress: 1,
        ));
      }
      if (comboCount >= 10) {
        updates.add(const AchievementProgressUpdate(
          achievementId: 'combo_10',
          currentProgress: 1,
        ));
      }

      if (updates.isNotEmpty) {
        await updateMultipleAchievements(updates);
      }
    } catch (e) {
      developer.log('Failed to check game achievements: $e', name: 'AchievementUseCases');
    }
  }

  /// Get achievement statistics
  Future<AchievementStatistics> getAchievementStatistics() async {
    try {
      final achievements = await _playerRepository.getAchievements();
      
      final totalAchievements = achievements.length;
      final unlockedAchievements = achievements.where((a) => a.isUnlocked).length;
      final secretAchievements = achievements.where((a) => a.isSecret).length;
      final unlockedSecrets = achievements.where((a) => a.isSecret && a.isUnlocked).length;
      
      final completionPercentage = totalAchievements > 0 
          ? (unlockedAchievements / totalAchievements) * 100 
          : 0.0;

      final totalCoinsEarned = achievements
          .where((a) => a.isUnlocked)
          .fold(0, (sum, a) => sum + a.coinReward);

      final categoryProgress = <AchievementCategory, int>{};
      for (final category in AchievementCategory.values) {
        final categoryAchievements = achievements.where((a) => a.category == category);
        final unlockedInCategory = categoryAchievements.where((a) => a.isUnlocked).length;
        categoryProgress[category] = unlockedInCategory;
      }

      final now = DateTime.now();
      final recentlyUnlocked = achievements
          .where((a) => a.isUnlocked && 
                      a.unlockedAt != null && 
                      now.difference(a.unlockedAt!).inDays <= 7)
          .toList()
          ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));

      return AchievementStatistics(
        totalAchievements: totalAchievements,
        unlockedAchievements: unlockedAchievements,
        secretAchievements: secretAchievements,
        unlockedSecrets: unlockedSecrets,
        completionPercentage: completionPercentage,
        totalCoinsEarned: totalCoinsEarned,
        categoryProgress: categoryProgress,
        recentlyUnlocked: recentlyUnlocked,
      );

    } catch (e) {
      developer.log('Failed to get achievement statistics: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to get achievement statistics: $e');
    }
  }

  /// Get achievements by category
  Future<List<Achievement>> getAchievementsByCategory(AchievementCategory category) async {
    try {
      final achievements = await _playerRepository.getAchievements();
      return achievements.where((a) => a.category == category).toList();
    } catch (e) {
      developer.log('Failed to get achievements by category: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to get achievements by category: $e');
    }
  }

  /// Get unlocked achievements
  Future<List<Achievement>> getUnlockedAchievements() async {
    try {
      final achievements = await _playerRepository.getAchievements();
      return achievements.where((a) => a.isUnlocked).toList();
    } catch (e) {
      developer.log('Failed to get unlocked achievements: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to get unlocked achievements: $e');
    }
  }

  /// Get achievements near completion
  Future<List<Achievement>> getNearCompletionAchievements({double threshold = 0.8}) async {
    try {
      final achievements = await _playerRepository.getAchievements();
      return achievements
          .where((a) => !a.isUnlocked && 
                       a.currentProgress > 0 && 
                       (a.currentProgress / a.targetValue) >= threshold)
          .toList();
    } catch (e) {
      developer.log('Failed to get near completion achievements: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to get near completion achievements: $e');
    }
  }

  /// Reset achievement progress (for testing/debugging)
  Future<void> resetAchievementProgress(String achievementId) async {
    try {
      final achievements = await _playerRepository.getAchievements();
      final achievement = achievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => throw NotFoundException('Achievement not found: $achievementId'),
      );

      final resetAchievement = achievement.copyWith(
        currentProgress: 0,
        isUnlocked: false,
        unlockedAt: null,
      );

      await _playerRepository.updateAchievement(resetAchievement);
      
      developer.log('Reset achievement progress: $achievementId', name: 'AchievementUseCases');
    } catch (e) {
      developer.log('Failed to reset achievement progress: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to reset achievement progress: $e');
    }
  }

  /// Reset all achievements (for testing/debugging)
  Future<void> resetAllAchievements() async {
    try {
      final achievements = await _playerRepository.getAchievements();
      
      for (final achievement in achievements) {
        final resetAchievement = achievement.copyWith(
          currentProgress: 0,
          isUnlocked: false,
          unlockedAt: null,
        );
        await _playerRepository.updateAchievement(resetAchievement);
      }

      developer.log('Reset all achievement progress', name: 'AchievementUseCases');
    } catch (e) {
      developer.log('Failed to reset all achievements: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to reset all achievements: $e');
    }
  }

  /// Export achievement data
  Future<Map<String, dynamic>> exportAchievementData() async {
    try {
      final achievements = await _playerRepository.getAchievements();
      final statistics = await getAchievementStatistics();

      return {
        'achievements': achievements.map((a) => a.toMap()).toList(),
        'statistics': statistics.toMap(),
        'exported_at': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      developer.log('Failed to export achievement data: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to export achievement data: $e');
    }
  }
}