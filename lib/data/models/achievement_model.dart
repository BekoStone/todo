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

class AchievementModel extends Equatable {
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
  final Map<String, dynamic> metadata;
  
  const AchievementModel({
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
    this.metadata = const {},
  });
  
  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category.index,
      'rarity': rarity.index,
      'targetValue': targetValue,
      'coinReward': coinReward,
      'powerUpRewards': powerUpRewards,
      'isSecret': isSecret,
      'isUnlocked': isUnlocked,
      'currentProgress': currentProgress,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      category: AchievementCategory.values[json['category'] ?? 0],
      rarity: AchievementRarity.values[json['rarity'] ?? 0],
      targetValue: json['targetValue'] ?? 0,
      coinReward: json['coinReward'] ?? 0,
      powerUpRewards: Map<String, int>.from(json['powerUpRewards'] ?? {}),
      isSecret: json['isSecret'] ?? false,
      isUnlocked: json['isUnlocked'] ?? false,
      currentProgress: json['currentProgress'] ?? 0,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.tryParse(json['unlockedAt']) 
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  // Copy with modifications
  AchievementModel copyWith({
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
    Map<String, dynamic>? metadata,
  }) {
    return AchievementModel(
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
      metadata: metadata ?? this.metadata,
    );
  }
  
  // Update progress
  AchievementModel updateProgress(int progress) {
    final newProgress = progress.clamp(0, targetValue);
    final shouldUnlock = newProgress >= targetValue && !isUnlocked;
    
    return copyWith(
      currentProgress: newProgress,
      isUnlocked: shouldUnlock ? true : isUnlocked,
      unlockedAt: shouldUnlock ? DateTime.now() : unlockedAt,
    );
  }
  
  // Unlock achievement
  AchievementModel unlock() {
    return copyWith(
      isUnlocked: true,
      currentProgress: targetValue,
      unlockedAt: DateTime.now(),
    );
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
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
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
    switch (category) {
      case AchievementCategory.beginner:
        return 'Beginner';
      case AchievementCategory.scoring:
        return 'Scoring';
      case AchievementCategory.combo:
        return 'Combo';
      case AchievementCategory.survival:
        return 'Survival';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.special:
        return 'Special';
    }
  }
  
  // Display properties
  String get displayName => isSecret && !isUnlocked ? '???' : name;
  String get displayDescription => isSecret && !isUnlocked ? 'Complete this secret challenge to unlock.' : description;
  String get displayIcon => isSecret && !isUnlocked ? '❓' : icon;
  
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
  
  // Achievement difficulty estimation
  String get difficulty {
    if (targetValue <= 10) return 'Easy';
    if (targetValue <= 100) return 'Medium';
    if (targetValue <= 1000) return 'Hard';
    return 'Extreme';
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
    metadata,
  ];
}

// Achievement definitions
class AchievementDefinitions {
  static List<AchievementModel> get allAchievements => [
    // Beginner achievements
    const AchievementModel(
      id: 'first_block',
      name: 'First Steps',
      description: 'Place your first block',
      icon: '🎯',
      category: AchievementCategory.beginner,
      targetValue: 1,
      coinReward: 25,
    ),
    
    const AchievementModel(
      id: 'first_line',
      name: 'Line Breaker',
      description: 'Clear your first line',
      icon: '📏',
      category: AchievementCategory.beginner,
      targetValue: 1,
      coinReward: 50,
      powerUpRewards: {'shuffle': 1},
    ),
    
    const AchievementModel(
      id: 'play_10_games',
      name: 'Getting Started',
      description: 'Play 10 games',
      icon: '🎮',
      category: AchievementCategory.beginner,
      targetValue: 10,
      coinReward: 100,
      powerUpRewards: {'shuffle': 2},
    ),
    
    // Scoring achievements
    const AchievementModel(
      id: 'score_1000',
      name: 'Rising Star',
      description: 'Score 1,000 points in a single game',
      icon: '⭐',
      category: AchievementCategory.scoring,
      rarity: AchievementRarity.rare,
      targetValue: 1000,
      coinReward: 75,
    ),
    
    const AchievementModel(
      id: 'score_5000',
      name: 'High Scorer',
      description: 'Score 5,000 points in a single game',
      icon: '🌟',
      category: AchievementCategory.scoring,
      rarity: AchievementRarity.epic,
      targetValue: 5000,
      coinReward: 150,
      powerUpRewards: {'shuffle': 3},
    ),
    
    const AchievementModel(
      id: 'score_10000',
      name: 'Score Master',
      description: 'Score 10,000 points in a single game',
      icon: '💫',
      category: AchievementCategory.scoring,
      rarity: AchievementRarity.legendary,
      targetValue: 10000,
      coinReward: 300,
      powerUpRewards: {'shuffle': 5, 'undo': 3},
    ),
    
    // Combo achievements
    const AchievementModel(
      id: 'combo_3x',
      name: 'Combo Starter',
      description: 'Achieve a 3x combo',
      icon: '🔥',
      category: AchievementCategory.combo,
      targetValue: 3,
      coinReward: 100,
    ),
    
    const AchievementModel(
      id: 'combo_5x',
      name: 'Combo Master',
      description: 'Achieve a 5x combo',
      icon: '💥',
      category: AchievementCategory.combo,
      rarity: AchievementRarity.epic,
      targetValue: 5,
      coinReward: 200,
      powerUpRewards: {'shuffle': 5},
    ),
    
    const AchievementModel(
      id: 'perfect_clear',
      name: 'Perfect Storm',
      description: 'Clear the entire board',
      icon: '⚡',
      category: AchievementCategory.combo,
      rarity: AchievementRarity.legendary,
      targetValue: 1,
      coinReward: 500,
      powerUpRewards: {'shuffle': 2, 'undo': 2},
    ),
    
    // Survival achievements
    const AchievementModel(
      id: 'survive_5min',
      name: 'Survivor',
      description: 'Play for 5 minutes straight',
      icon: '⏰',
      category: AchievementCategory.survival,
      targetValue: 300, // seconds
      coinReward: 150,
    ),
    
    const AchievementModel(
      id: 'no_undo_game',
      name: 'Pure Skill',
      description: 'Complete a game without using undo',
      icon: '🎯',
      category: AchievementCategory.survival,
      rarity: AchievementRarity.rare,
      targetValue: 1,
      coinReward: 200,
      powerUpRewards: {'shuffle': 3},
    ),
    
    const AchievementModel(
      id: 'place_100_blocks',
      name: 'Block Buster',
      description: 'Place 100 blocks total',
      icon: '🧱',
      category: AchievementCategory.survival,
      targetValue: 100,
      coinReward: 100,
    ),
    
    // Mastery achievements
    const AchievementModel(
      id: 'clear_50_lines',
      name: 'Line Cleaner',
      description: 'Clear 50 lines total',
      icon: '🧹',
      category: AchievementCategory.mastery,
      targetValue: 50,
      coinReward: 250,
    ),
    
    const AchievementModel(
      id: 'reach_level_10',
      name: 'Level Master',
      description: 'Reach level 10',
      icon: '🏅',
      category: AchievementCategory.mastery,
      rarity: AchievementRarity.epic,
      targetValue: 10,
      coinReward: 300,
      powerUpRewards: {'shuffle': 5},
    ),
    
    // Special achievements
    const AchievementModel(
      id: 'secret_pattern',
      name: 'Pattern Genius',
      description: 'Discover the secret...',
      icon: '🎭',
      category: AchievementCategory.special,
      rarity: AchievementRarity.legendary,
      targetValue: 1,
      coinReward: 1000,
      powerUpRewards: {'shuffle': 10},
      isSecret: true,
    ),
    
    const AchievementModel(
      id: 'lucky_777',
      name: 'Lucky Seven',
      description: 'Score exactly 777 points',
      icon: '🍀',
      category: AchievementCategory.special,
      rarity: AchievementRarity.legendary,
      targetValue: 777,
      coinReward: 777,
      isSecret: true,
    ),
  ];
}