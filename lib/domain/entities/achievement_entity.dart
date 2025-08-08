import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AchievementCategory {
  beginner,
  scoring,
  combo,
  survival,
  mastery,
  special,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

class Achievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int targetValue;
  final int coinReward;
  final Map<String, int> powerUpRewards;
  final bool isSecret;
  final bool isUnlocked;
  final int currentProgress;
  final DateTime? unlockedAt;
   
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.rarity = AchievementRarity.common,
    required this.targetValue,
    this.coinReward = 0,
    this.powerUpRewards = const {},
    this.isSecret = false,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.unlockedAt,
  });
  
  // Copy with modifications
  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    AchievementCategory? category,
    AchievementRarity? rarity,
    int? targetValue,
    int? coinReward,
    Map<String, int>? powerUpRewards,
    bool? isSecret,
    bool? isUnlocked,
    int? currentProgress,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      targetValue: targetValue ?? this.targetValue,
      coinReward: coinReward ?? this.coinReward,
      powerUpRewards: powerUpRewards ?? this.powerUpRewards,
      isSecret: isSecret ?? this.isSecret,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category.name,
      'rarity': rarity.name,
      'targetValue': targetValue,
      'coinReward': coinReward,
      'powerUpRewards': powerUpRewards,
      'isSecret': isSecret,
      'isUnlocked': isUnlocked,
      'currentProgress': currentProgress,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
  // Progress operations
  Achievement updateProgress(int progress) {
    final newProgress = progress.clamp(0, targetValue);
    final shouldUnlock = newProgress >= targetValue && !isUnlocked;
    
    return copyWith(
      currentProgress: newProgress,
      isUnlocked: shouldUnlock ? true : isUnlocked,
      unlockedAt: shouldUnlock ? DateTime.now() : unlockedAt,
    );
  }
  
  Achievement unlock() {
    return copyWith(
      isUnlocked: true,
      currentProgress: targetValue,
      unlockedAt: DateTime.now(),
    );
  }
  
  Achievement incrementProgress([int amount = 1]) {
    return updateProgress(currentProgress + amount);
  }
  
  // Progress calculations
  double get progressPercentage {
    if (targetValue == 0) return 100.0;
    return (currentProgress / targetValue * 100).clamp(0.0, 100.0);
  }
  
  bool get isCompleted => currentProgress >= targetValue;
  bool get isInProgress => currentProgress > 0 && !isCompleted;
  bool get canBeDisplayed => !isSecret || isUnlocked;
  
  int get remainingProgress => (targetValue - currentProgress).clamp(0, targetValue);
  
  // Display properties
  String get displayName => isSecret && !isUnlocked ? '???' : name;
  String get displayDescription => isSecret && !isUnlocked 
      ? 'Complete this secret challenge to unlock.' 
      : description;
  String get displayIcon => isSecret && !isUnlocked ? '❓' : icon;
  
  // Rarity properties
  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }
  
  String get rarityName {
    return rarity.name.substring(0, 1).toUpperCase() + rarity.name.substring(1);
  }
  
  // Category properties
  Color get categoryColor {
    switch (category) {
      case AchievementCategory.beginner:
        return Colors.green;
      case AchievementCategory.scoring:
        return Colors.blue;
      case AchievementCategory.combo:
        return Colors.orange;
      case AchievementCategory.survival:
        return Colors.red;
      case AchievementCategory.mastery:
        return Colors.purple;
      case AchievementCategory.special:
        return Colors.pink;
    }
  }
  
  String get categoryName {
    return category.name.substring(0, 1).toUpperCase() + category.name.substring(1);
  }
  
  // Reward summary
  String get rewardSummary {
    final rewards = <String>[];
    
    if (coinReward > 0) {
      rewards.add('$coinReward coins');
    }
    
    for (final entry in powerUpRewards.entries) {
      rewards.add('${entry.value}x ${entry.key}');
    }
    
    return rewards.isEmpty ? 'No rewards' : rewards.join(', ');
  }
  
  // Difficulty estimation
  String get difficulty {
    if (targetValue <= 10) return 'Easy';
    if (targetValue <= 100) return 'Medium';
    if (targetValue <= 1000) return 'Hard';
    return 'Extreme';
  }
  
  // Time since unlock
  Duration? get timeSinceUnlock {
    return unlockedAt != null ? DateTime.now().difference(unlockedAt!) : null;
  }
  
  bool get isRecentlyUnlocked {
    final timeSince = timeSinceUnlock;
    return timeSince != null && timeSince.inHours < 24;
  }
  
  // Validation
  bool get isValid {
    return id.isNotEmpty && 
           name.isNotEmpty && 
           description.isNotEmpty && 
           targetValue > 0;
  }
  
  @override
  List<Object?> get props => [
    id,
    name,
    description,
    icon,
    category,
    rarity,
    targetValue,
    coinReward,
    powerUpRewards,
    isSecret,
    isUnlocked,
    currentProgress,
    unlockedAt,
  ];
  
  @override
  String toString() {
    return 'Achievement(id: $id, name: $name, progress: $currentProgress/$targetValue, unlocked: $isUnlocked)';
  }
}

// Achievement checker - determines if conditions are met
class AchievementChecker {
  static bool checkCondition(
    Achievement achievement,
    Map<String, dynamic> gameData,
  ) {
    switch (achievement.id) {
      case 'first_block':
        return (gameData['blocksPlaced'] ?? 0) >= 1;
      
      case 'first_line':
        return (gameData['linesCleared'] ?? 0) >= 1;
      
      case 'play_10_games':
        return (gameData['gamesPlayed'] ?? 0) >= 10;
      
      case 'score_1000':
        return (gameData['currentScore'] ?? 0) >= 1000;
      
      case 'score_5000':
        return (gameData['currentScore'] ?? 0) >= 5000;
      
      case 'score_10000':
        return (gameData['currentScore'] ?? 0) >= 10000;
      
      case 'combo_3x':
        return (gameData['maxCombo'] ?? 0) >= 3;
      
      case 'combo_5x':
        return (gameData['maxCombo'] ?? 0) >= 5;
      
      case 'perfect_clear':
        return gameData['hadPerfectClear'] == true;
      
      case 'survive_5min':
        return (gameData['sessionTime'] ?? 0) >= 300; // 5 minutes
      
      case 'no_undo_game':
        return gameData['usedUndo'] == false && (gameData['currentScore'] ?? 0) > 500;
      
      case 'place_100_blocks':
        return (gameData['totalBlocksPlaced'] ?? 0) >= 100;
      
      case 'clear_50_lines':
        return (gameData['totalLinesCleared'] ?? 0) >= 50;
      
      case 'reach_level_10':
        return (gameData['level'] ?? 1) >= 10;
      
      case 'lucky_777':
        return (gameData['currentScore'] ?? 0) == 777;
      
      case 'secret_pattern':
        return gameData['secretPatternFound'] == true;
      
      default:
        return false;
    }
  }
  
  static int calculateProgress(
    Achievement achievement,
    Map<String, dynamic> gameData,
  ) {
    switch (achievement.id) {
      case 'first_block':
        return (gameData['blocksPlaced'] ?? 0).clamp(0, 1);
      
      case 'first_line':
        return (gameData['linesCleared'] ?? 0).clamp(0, 1);
      
      case 'play_10_games':
        return (gameData['gamesPlayed'] ?? 0).clamp(0, 10);
      
      case 'score_1000':
        return (gameData['bestScore'] ?? 0).clamp(0, 1000);
      
      case 'score_5000':
        return (gameData['bestScore'] ?? 0).clamp(0, 5000);
      
      case 'score_10000':
        return (gameData['bestScore'] ?? 0).clamp(0, 10000);
      
      case 'combo_3x':
        return (gameData['bestCombo'] ?? 0).clamp(0, 3);
      
      case 'combo_5x':
        return (gameData['bestCombo'] ?? 0).clamp(0, 5);
      
      case 'place_100_blocks':
        return (gameData['totalBlocksPlaced'] ?? 0).clamp(0, 100);
      
      case 'clear_50_lines':
        return (gameData['totalLinesCleared'] ?? 0).clamp(0, 50);
      
      case 'reach_level_10':
        return (gameData['bestLevel'] ?? 1).clamp(1, 10);
      
      case 'survive_5min':
        return (gameData['longestSession'] ?? 0).clamp(0, 300);
      
      default:
        return achievement.currentProgress;
    }
  }
}