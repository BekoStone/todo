// File: lib/domain/usecases/achievement_usecases.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:puzzle_box/core/errors/exceptions_dart.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';

import '../repositories/player_repository.dart';

/// Result of checking achievement progress
class AchievementCheckResult {
  final List<Achievement> newlyUnlocked;
  final List<Achievement> progressUpdated;
  final bool hasNewUnlocks;

  const AchievementCheckResult({
    required this.newlyUnlocked,
    required this.progressUpdated,
    required this.hasNewUnlocks,
  });

  int get totalRewardCoins => newlyUnlocked.fold(0, (sum, achievement) => sum + achievement.coinReward);

  Map<String, dynamic> toMap() => {
    'newly_unlocked': newlyUnlocked.map((a) => a.toMap()).toList(),
    'progress_updated': progressUpdated.map((a) => a.toMap()).toList(),
    'has_new_unlocks': hasNewUnlocks,
    'total_reward_coins': totalRewardCoins,
  };
}

/// Achievement progress update data
class AchievementProgressUpdate {
  final String achievementId;
  final int currentProgress;
  final bool isIncrement;
  final Map<String, dynamic>? metadata;

  const AchievementProgressUpdate({
    required this.achievementId,
    required this.currentProgress,
    this.isIncrement = false,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'achievement_id': achievementId,
    'current_progress': currentProgress,
    'is_increment': isIncrement,
    'metadata': metadata,
  };
}

/// Achievement unlock reward
class AchievementReward {
  final Achievement achievement;
  final int coinReward;
  final List<String> powerUpRewards;
  final Map<String, dynamic> metadata;

  const AchievementReward({
    required this.achievement,
    required this.coinReward,
    required this.powerUpRewards,
    required this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'achievement': achievement.toMap(),
    'coin_reward': coinReward,
    'power_up_rewards': powerUpRewards,
    'metadata': metadata,
  };
}

/// Achievement statistics
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

  /// Update achievement progress and check for unlocks
  Future<AchievementCheckResult> updateAchievementProgress(
    AchievementProgressUpdate update,
  ) async {
    try {
      final currentStats = await _playerRepository.getPlayerStats();
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
        await _playerRepository.updatePlayerStats(
          currentStats.copyWith(
            totalCoinsEarned: currentStats.totalCoinsEarned + achievement.coinReward,
              unlockedAchievements: currentStats.unlockedAchievements + 1,
          ),
        );

        developer.log(
          'Achievement unlocked: ${achievement.name} (+${achievement.coinReward} coins)',
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

  /// Process game session achievements
  Future<AchievementCheckResult> processGameSessionAchievements({
    required int finalScore,
    required int level,
    required int linesCleared,
    required int blocksPlaced,
    required int comboCount,
    required bool perfectClear,
    required bool usedUndo,
    required Duration sessionDuration,
  }) async {
    try {
      final updates = <AchievementProgressUpdate>[];

      // Score-based achievements
      updates.add(AchievementProgressUpdate(
        achievementId: 'score_1000',
        currentProgress: finalScore >= 1000 ? 1 : 0,
      ));
      updates.add(AchievementProgressUpdate(
        achievementId: 'score_5000',
        currentProgress: finalScore >= 5000 ? 1 : 0,
      ));
      updates.add(AchievementProgressUpdate(
        achievementId: 'score_10000',
        currentProgress: finalScore >= 10000 ? 1 : 0,
      ));

      // Level achievements
      updates.add(AchievementProgressUpdate(
        achievementId: 'reach_level_10',
        currentProgress: level,
      ));

      // Lines cleared achievements
      updates.add(AchievementProgressUpdate(
        achievementId: 'clear_50_lines',
        currentProgress: linesCleared,
        isIncrement: true,
      ));

      // Blocks placed achievements
      updates.add(AchievementProgressUpdate(
        achievementId: 'place_100_blocks',
        currentProgress: blocksPlaced,
        isIncrement: true,
      ));

      // Combo achievements
      if (comboCount >= 3) {
        updates.add(AchievementProgressUpdate(
          achievementId: 'combo_3x',
          currentProgress: comboCount,
        ));
      }
      if (comboCount >= 5) {
        updates.add(AchievementProgressUpdate(
          achievementId: 'combo_5x',
          currentProgress: comboCount,
        ));
      }

      // Perfect clear achievement
      if (perfectClear) {
        updates.add(AchievementProgressUpdate(
          achievementId: 'perfect_clear',
          currentProgress: 1,
          isIncrement: true,
        ));
      }

      // No undo achievement
      if (!usedUndo) {
        updates.add(AchievementProgressUpdate(
          achievementId: 'no_undo_game',
          currentProgress: 1,
          isIncrement: true,
        ));
      }

      // Survival achievements
      if (sessionDuration.inSeconds >= 300) { // 5 minutes
        updates.add(AchievementProgressUpdate(
          achievementId: 'survive_5min',
          currentProgress: sessionDuration.inSeconds,
        ));
      }

      // Game completion achievement
      updates.add(AchievementProgressUpdate(
        achievementId: 'play_10_games',
        currentProgress: 1,
        isIncrement: true,
      ));

      // Secret achievements
      if (finalScore == 777) {
        updates.add(AchievementProgressUpdate(
          achievementId: 'lucky_777',
          currentProgress: finalScore,
        ));
      }

      return await updateMultipleAchievements(updates);

    } catch (e) {
      developer.log('Failed to process game session achievements: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to process game session achievements: $e');
    }
  }

  /// Process specific game action achievements
  Future<AchievementCheckResult> processGameActionAchievements({
    required String action,
    required Map<String, dynamic> actionData,
  }) async {
    try {
      final updates = <AchievementProgressUpdate>[];

      switch (action) {
        case 'first_block':
          updates.add(const AchievementProgressUpdate(
            achievementId: 'first_block',
            currentProgress: 1,
          ));
          break;

        case 'first_line':
          updates.add(const AchievementProgressUpdate(
            achievementId: 'first_line',
            currentProgress: 1,
          ));
          break;

        case 'block_placed':
          updates.add(const AchievementProgressUpdate(
            achievementId: 'place_100_blocks',
            currentProgress: 1,
            isIncrement: true,
          ));
          break;

        case 'line_cleared':
          final lineCount = actionData['line_count'] as int? ?? 1;
          updates.add(AchievementProgressUpdate(
            achievementId: 'clear_50_lines',
            currentProgress: lineCount,
            isIncrement: true,
          ));
          break;

        default:
          developer.log('Unknown action for achievements: $action', name: 'AchievementUseCases');
      }

      if (updates.isNotEmpty) {
        return await updateMultipleAchievements(updates);
      }

      return const AchievementCheckResult(
        newlyUnlocked: [],
        progressUpdated: [],
        hasNewUnlocks: false,
      );

    } catch (e) {
      developer.log('Failed to process game action achievements: $e', name: 'AchievementUseCases');
      throw BusinessLogicException('Failed to process game action achievements: $e');
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