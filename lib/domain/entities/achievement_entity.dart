import 'package:equatable/equatable.dart';

/// Achievement entity represents a player accomplishment in the game.
/// Contains information about the achievement, progress tracking, and rewards.
/// Immutable entity following Clean Architecture principles.
class Achievement extends Equatable {
  /// Unique achievement identifier
  final String id;
  
  /// Achievement title (user-facing)
  final String title;
  
  /// Achievement description
  final String description;
  
  /// Icon path for the achievement
  final String iconPath;
  
  /// Achievement category
  final AchievementCategory category;
  
  /// Achievement rarity/difficulty
  final AchievementRarity rarity;
  
  /// Points awarded for this achievement
  final int points;
  
  /// Coin reward for unlocking
  final int coinReward;
  
  /// Premium currency reward (if any)
  final int premiumReward;
  
  /// Whether this achievement is unlocked
  final bool isUnlocked;
  
  /// Date when achievement was unlocked
  final DateTime? unlockedDate;
  
  /// Current progress towards achievement (0.0 to 1.0)
  final double progress;
  
  /// Current progress value (raw number)
  final int currentValue;
  
  /// Target value to complete achievement
  final int targetValue;
  
  /// Whether this achievement is hidden until unlocked
  final bool isHidden;
  
  /// Whether this achievement can be repeated
  final bool isRepeatable;
  
  /// Prerequisites (other achievement IDs that must be completed first)
  final List<String> prerequisites;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Last updated timestamp
  final DateTime updatedAt;
  
  /// Additional metadata
  final Map<String, dynamic> metadata;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.category,
    this.rarity = AchievementRarity.common,
    this.points = 10,
    this.coinReward = 100,
    this.premiumReward = 0,
    this.isUnlocked = false,
    this.unlockedDate,
    this.progress = 0.0,
    this.currentValue = 0,
    required this.targetValue,
    this.isHidden = false,
    this.isRepeatable = false,
    this.prerequisites = const [],
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Create a new achievement definition
  factory Achievement.create({
    required String id,
    required String title,
    required String description,
    required String iconPath,
    required AchievementCategory category,
    required int targetValue,
    AchievementRarity rarity = AchievementRarity.common,
    int? points,
    int? coinReward,
    int premiumReward = 0,
    bool isHidden = false,
    bool isRepeatable = false,
    List<String> prerequisites = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    
    // Calculate points and rewards based on rarity if not specified
    final achievementPoints = points ?? _getDefaultPoints(rarity);
    final achievementCoins = coinReward ?? _getDefaultCoinReward(rarity);
    
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconPath: iconPath,
      category: category,
      rarity: rarity,
      points: achievementPoints,
      coinReward: achievementCoins,
      premiumReward: premiumReward,
      targetValue: targetValue,
      isHidden: isHidden,
      isRepeatable: isRepeatable,
      prerequisites: prerequisites,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
  }

  /// Create a copy with updated values
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    AchievementCategory? category,
    AchievementRarity? rarity,
    int? points,
    int? coinReward,
    int? premiumReward,
    bool? isUnlocked,
    DateTime? unlockedDate,
    double? progress,
    int? currentValue,
    int? targetValue,
    bool? isHidden,
    bool? isRepeatable,
    List<String>? prerequisites,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      points: points ?? this.points,
      coinReward: coinReward ?? this.coinReward,
      premiumReward: premiumReward ?? this.premiumReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      isHidden: isHidden ?? this.isHidden,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      prerequisites: prerequisites ?? this.prerequisites,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  // ========================================
  // ACHIEVEMENT OPERATIONS
  // ========================================

  /// Update progress towards this achievement
  Achievement updateProgress(int newValue) {
    if (isUnlocked && !isRepeatable) {
      return this; // Already unlocked and not repeatable
    }
    
    final clampedValue = newValue.clamp(0, targetValue);
    final newProgress = targetValue > 0 ? clampedValue / targetValue : 0.0;
    final shouldUnlock = clampedValue >= targetValue && !isUnlocked;
    
    return copyWith(
      currentValue: clampedValue,
      progress: newProgress,
      isUnlocked: shouldUnlock ? true : isUnlocked,
      unlockedDate: shouldUnlock ? DateTime.now() : unlockedDate,
      updatedAt: DateTime.now(),
    );
  }

  /// Increment progress by a specific amount
  Achievement incrementProgress(int amount) {
    return updateProgress(currentValue + amount);
  }

  /// Unlock the achievement immediately
  Achievement unlock() {
    if (isUnlocked && !isRepeatable) {
      return this; // Already unlocked
    }
    
    return copyWith(
      isUnlocked: true,
      unlockedDate: DateTime.now(),
      progress: 1.0,
      currentValue: targetValue,
      updatedAt: DateTime.now(),
    );
  }

  /// Reset achievement progress (for repeatable achievements)
  Achievement reset() {
    if (!isRepeatable) {
      return this; // Cannot reset non-repeatable achievements
    }
    
    return copyWith(
      isUnlocked: false,
      unlockedDate: null,
      progress: 0.0,
      currentValue: 0,
      updatedAt: DateTime.now(),
    );
  }

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  /// Check if the achievement is complete
  bool get isComplete => isUnlocked;

  /// Check if the achievement is in progress
  bool get isInProgress => currentValue > 0 && !isUnlocked;

  /// Get progress percentage (0-100)
  double get progressPercentage => progress * 100;

  /// Get remaining value to complete
  int get remainingValue => (targetValue - currentValue).clamp(0, targetValue);

  /// Check if achievement should be visible to player
  bool get isVisible => !isHidden || isUnlocked || isInProgress;

  /// Get time since unlocked (if unlocked)
  Duration? get timeSinceUnlocked {
    return unlockedDate != null 
        ? DateTime.now().difference(unlockedDate!)
        : null;
  }

  /// Check if prerequisites are met
  bool arePrerequisitesMet(List<Achievement> allAchievements) {
    if (prerequisites.isEmpty) return true;
    
    for (final prereqId in prerequisites) {
      final prereq = allAchievements.firstWhere(
        (a) => a.id == prereqId,
        orElse: () => Achievement.create(
          id: '',
          title: '',
          description: '',
          iconPath: '',
          category: AchievementCategory.general,
          targetValue: 1,
        ),
      );
      
      if (prereq.id.isEmpty || !prereq.isUnlocked) {
        return false;
      }
    }
    
    return true;
  }

  /// Get display title (with progress if in progress)
  String get displayTitle {
    if (isUnlocked) {
      return title;
    } else if (isInProgress) {
      return '$title ($currentValue/$targetValue)';
    } else {
      return isHidden ? '???' : title;
    }
  }

  /// Get display description
  String get displayDescription {
    if (isHidden && !isUnlocked && !isInProgress) {
      return 'Complete more achievements to unlock this secret achievement.';
    }
    return description;
  }

  /// Get rarity color (for UI display)
  String get rarityColorHex {
    switch (rarity) {
      case AchievementRarity.common:
        return '#9E9E9E'; // Gray
      case AchievementRarity.rare:
        return '#2196F3'; // Blue  
      case AchievementRarity.epic:
        return '#9C27B0'; // Purple
      case AchievementRarity.legendary:
        return '#FF9800'; // Orange
    }
  }

  // ========================================
  // SERIALIZATION
  // ========================================

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'category': category.name,
      'rarity': rarity.name,
      'points': points,
      'coinReward': coinReward,
      'premiumReward': premiumReward,
      'isUnlocked': isUnlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
      'progress': progress,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'isHidden': isHidden,
      'isRepeatable': isRepeatable,
      'prerequisites': prerequisites,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconPath: json['iconPath'] as String,
      category: AchievementCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AchievementCategory.general,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      points: json['points'] as int? ?? 10,
      coinReward: json['coinReward'] as int? ?? 100,
      premiumReward: json['premiumReward'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedDate: json['unlockedDate'] != null
          ? DateTime.parse(json['unlockedDate'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentValue: json['currentValue'] as int? ?? 0,
      targetValue: json['targetValue'] as int,
      isHidden: json['isHidden'] as bool? ?? false,
      isRepeatable: json['isRepeatable'] as bool? ?? false,
      prerequisites: (json['prerequisites'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Get default points based on rarity
  static int _getDefaultPoints(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 10;
      case AchievementRarity.rare:
        return 25;
      case AchievementRarity.epic:
        return 50;
      case AchievementRarity.legendary:
        return 100;
    }
  }

  /// Get default coin reward based on rarity
  static int _getDefaultCoinReward(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 50;
      case AchievementRarity.rare:
        return 100;
      case AchievementRarity.epic:
        return 200;
      case AchievementRarity.legendary:
        return 500;
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconPath,
        category,
        rarity,
        points,
        coinReward,
        premiumReward,
        isUnlocked,
        unlockedDate,
        progress,
        currentValue,
        targetValue,
        isHidden,
        isRepeatable,
        prerequisites,
        createdAt,
        updatedAt,
        metadata,
      ];

  @override
  String toString() {
    return 'Achievement('
        'id: $id, '
        'title: $title, '
        'unlocked: $isUnlocked, '
        'progress: ${progressPercentage.toStringAsFixed(1)}%'
        ')';
  }
}

/// Achievement category enumeration
enum AchievementCategory {
  general,
  scoring,
  gameplay,
  progression,
  mastery,
  social,
  collection,
  time,
  special;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case AchievementCategory.general:
        return 'General';
      case AchievementCategory.scoring:
        return 'Scoring';
      case AchievementCategory.gameplay:
        return 'Gameplay';
      case AchievementCategory.progression:
        return 'Progression';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.collection:
        return 'Collection';
      case AchievementCategory.time:
        return 'Time';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  String get description {
    switch (this) {
      case AchievementCategory.general:
        return 'Basic game achievements';
      case AchievementCategory.scoring:
        return 'Score and point-based achievements';
      case AchievementCategory.gameplay:
        return 'Gameplay mechanic achievements';
      case AchievementCategory.progression:
        return 'Level and progress achievements';
      case AchievementCategory.mastery:
        return 'Skill and mastery achievements';
      case AchievementCategory.social:
        return 'Social and sharing achievements';
      case AchievementCategory.collection:
        return 'Collection and completion achievements';
      case AchievementCategory.time:
        return 'Time-based achievements';
      case AchievementCategory.special:
        return 'Special event achievements';
    }
  }
}

/// Achievement rarity enumeration
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
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

  double get spawnRate {
    switch (this) {
      case AchievementRarity.common:
        return 0.7; // 70% of achievements
      case AchievementRarity.rare:
        return 0.2; // 20% of achievements
      case AchievementRarity.epic:
        return 0.08; // 8% of achievements
      case AchievementRarity.legendary:
        return 0.02; // 2% of achievements
    }
  }
}

/// Predefined achievement definitions
class AchievementDefinitions {
  // Prevent instantiation
  AchievementDefinitions._();

  /// Get all predefined achievement definitions
  static List<Achievement> getAllDefinitions() {
    final now = DateTime.now();
    
    return [
      // General achievements
      Achievement.create(
        id: 'first_game',
        title: 'Welcome to Box Hooks!',
        description: 'Play your first game',
        iconPath: 'assets/images/achievements/first_game.png',
        category: AchievementCategory.general,
        targetValue: 1,
        rarity: AchievementRarity.common,
      ),
      
      Achievement.create(
        id: 'first_line',
        title: 'Line Clearer',
        description: 'Clear your first line',
        iconPath: 'assets/images/achievements/first_line.png',
        category: AchievementCategory.general,
        targetValue: 1,
        rarity: AchievementRarity.common,
      ),
      
      // Scoring achievements
      Achievement.create(
        id: 'score_1k',
        title: 'Rising Star',
        description: 'Score 1,000 points in a single game',
        iconPath: 'assets/images/achievements/score_1k.png',
        category: AchievementCategory.scoring,
        targetValue: 1000,
        rarity: AchievementRarity.common,
      ),
      
      Achievement.create(
        id: 'score_10k',
        title: 'High Scorer',
        description: 'Score 10,000 points in a single game',
        iconPath: 'assets/images/achievements/score_10k.png',
        category: AchievementCategory.scoring,
        targetValue: 10000,
        rarity: AchievementRarity.rare,
      ),
      
      Achievement.create(
        id: 'score_100k',
        title: 'Score Master',
        description: 'Score 100,000 points in a single game',
        iconPath: 'assets/images/achievements/score_100k.png',
        category: AchievementCategory.scoring,
        targetValue: 100000,
        rarity: AchievementRarity.legendary,
      ),
      
      // Gameplay achievements
      Achievement.create(
        id: 'combo_5',
        title: 'Combo Starter',
        description: 'Achieve a 5x combo',
        iconPath: 'assets/images/achievements/combo_5.png',
        category: AchievementCategory.gameplay,
        targetValue: 5,
        rarity: AchievementRarity.common,
      ),
      
      Achievement.create(
        id: 'combo_10',
        title: 'Combo Master',
        description: 'Achieve a 10x combo',
        iconPath: 'assets/images/achievements/combo_10.png',
        category: AchievementCategory.gameplay,
        targetValue: 10,
        rarity: AchievementRarity.epic,
      ),
      
      Achievement.create(
        id: 'perfect_clear',
        title: 'Perfect Clear',
        description: 'Clear the entire grid',
        iconPath: 'assets/images/achievements/perfect_clear.png',
        category: AchievementCategory.gameplay,
        targetValue: 1,
        rarity: AchievementRarity.epic,
      ),
      
      // Progression achievements
      Achievement.create(
        id: 'level_10',
        title: 'Climbing High',
        description: 'Reach level 10',
        iconPath: 'assets/images/achievements/level_10.png',
        category: AchievementCategory.progression,
        targetValue: 10,
        rarity: AchievementRarity.common,
      ),
      
      Achievement.create(
        id: 'level_25',
        title: 'Quarter Century',
        description: 'Reach level 25',
        iconPath: 'assets/images/achievements/level_25.png',
        category: AchievementCategory.progression,
        targetValue: 25,
        rarity: AchievementRarity.rare,
      ),
      
      // Mastery achievements
      Achievement.create(
        id: 'efficient_player',
        title: 'Efficiency Expert',
        description: 'Maintain 80% line clearing efficiency in a game',
        iconPath: 'assets/images/achievements/efficient.png',
        category: AchievementCategory.mastery,
        targetValue: 80,
        rarity: AchievementRarity.epic,
      ),
      
      // Collection achievements
      Achievement.create(
        id: 'games_played_100',
        title: 'Dedicated Player',
        description: 'Play 100 games',
        iconPath: 'assets/images/achievements/games_100.png',
        category: AchievementCategory.collection,
        targetValue: 100,
        rarity: AchievementRarity.rare,
        isRepeatable: true,
      ),
      
      // Time achievements
      Achievement.create(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Clear 10 lines in under 60 seconds',
        iconPath: 'assets/images/achievements/speed.png',
        category: AchievementCategory.time,
        targetValue: 10,
        rarity: AchievementRarity.epic,
      ),
      
      // Special achievements
      Achievement.create(
        id: 'daily_player',
        title: 'Daily Dedication',
        description: 'Play for 7 consecutive days',
        iconPath: 'assets/images/achievements/daily.png',
        category: AchievementCategory.special,
        targetValue: 7,
        rarity: AchievementRarity.rare,
        isRepeatable: true,
      ),
      
      // Hidden achievements
      Achievement.create(
        id: 'secret_master',
        title: 'Secret Master',
        description: 'Unlock all other achievements',
        iconPath: 'assets/images/achievements/secret_master.png',
        category: AchievementCategory.special,
        targetValue: 1,
        rarity: AchievementRarity.legendary,
        isHidden: true,
      ),
    ];
  }
}