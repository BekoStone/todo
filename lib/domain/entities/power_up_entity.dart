import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';

/// PowerUp represents a special ability that can be used during gameplay.
/// Follows Clean Architecture principles with immutable data and clear interfaces.
/// Optimized for performance with efficient equality checks and minimal memory usage.
class PowerUp extends Equatable {
  /// Unique identifier for this power-up
  final String id;
  
  /// Type of power-up
  final PowerUpType type;
  
  /// Rarity level of the power-up
  final PowerUpRarity rarity;
  
  /// Duration for time-based power-ups (null for instant effects)
  final Duration? duration;
  
  /// Cooldown time before power-up can be used again
  final Duration cooldown;
  
  /// Cost in coins to purchase/use
  final int cost;
  
  /// Whether this power-up is currently active
  final bool isActive;
  
  /// Remaining duration if active
  final Duration? remainingDuration;
  
  /// Timestamp when power-up was acquired
  final DateTime acquiredAt;
  
  /// Timestamp when power-up was last used
  final DateTime? lastUsedAt;
  
  /// Number of uses remaining (-1 for unlimited)
  final int usesRemaining;
  
  /// Custom properties for special power-ups
  final Map<String, dynamic> properties;

  const PowerUp({
    required this.id,
    required this.type,
    this.rarity = PowerUpRarity.common,
    this.duration,
    this.cooldown = const Duration(seconds: 30),
    this.cost = 0,
    this.isActive = false,
    this.remainingDuration,
    required this.acquiredAt,
    this.lastUsedAt,
    this.usesRemaining = 1,
    this.properties = const {},
  });

  /// Create a power-up with default values for type
  factory PowerUp.create({
    required PowerUpType type,
    PowerUpRarity? rarity,
    Map<String, dynamic>? properties,
  }) {
    final config = _getPowerUpConfig(type);
    
    return PowerUp(
      id: _generateId(),
      type: type,
      rarity: rarity ?? config['rarity'],
      duration: config['duration'],
      cooldown: config['cooldown'],
      cost: config['cost'],
      acquiredAt: DateTime.now(),
      usesRemaining: config['uses'],
      properties: properties ?? {},
    );
  }

  /// Create a copy with updated values
  PowerUp copyWith({
    String? id,
    PowerUpType? type,
    PowerUpRarity? rarity,
    Duration? duration,
    Duration? cooldown,
    int? cost,
    bool? isActive,
    Duration? remainingDuration,
    DateTime? acquiredAt,
    DateTime? lastUsedAt,
    int? usesRemaining,
    Map<String, dynamic>? properties,
  }) {
    return PowerUp(
      id: id ?? this.id,
      type: type ?? this.type,
      rarity: rarity ?? this.rarity,
      duration: duration ?? this.duration,
      cooldown: cooldown ?? this.cooldown,
      cost: cost ?? this.cost,
      isActive: isActive ?? this.isActive,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usesRemaining: usesRemaining ?? this.usesRemaining,
      properties: properties ?? Map.from(this.properties),
    );
  }

  /// Activate the power-up
  PowerUp activate() {
    return copyWith(
      isActive: true,
      lastUsedAt: DateTime.now(),
      remainingDuration: duration,
      usesRemaining: usesRemaining > 0 ? usesRemaining - 1 : usesRemaining,
    );
  }

  /// Deactivate the power-up
  PowerUp deactivate() {
    return copyWith(
      isActive: false,
      remainingDuration: null,
    );
  }

  /// Update remaining duration
  PowerUp updateDuration(Duration remaining) {
    if (remaining.inMilliseconds <= 0) {
      return deactivate();
    }
    
    return copyWith(remainingDuration: remaining);
  }

  /// Check if power-up can be used
  bool get canUse {
    if (usesRemaining == 0) return false;
    if (isActive && !type.canStackWithSelf) return false;
    
    if (lastUsedAt != null) {
      final timeSinceLastUse = DateTime.now().difference(lastUsedAt!);
      if (timeSinceLastUse < cooldown) return false;
    }
    
    return true;
  }

  /// Get remaining cooldown time
  Duration get remainingCooldown {
    if (lastUsedAt == null) return Duration.zero;
    
    final timeSinceLastUse = DateTime.now().difference(lastUsedAt!);
    final remaining = cooldown - timeSinceLastUse;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if power-up is expired
  bool get isExpired {
    if (usesRemaining == 0) return true;
    if (duration == null) return false;
    
    final ageLimit = const Duration(hours: 24); // Power-ups expire after 24 hours
    final age = DateTime.now().difference(acquiredAt);
    
    return age > ageLimit;
  }

  /// Get display name
  String get displayName => type.displayName;

  /// Get description
  String get description => type.description;

  /// Get icon
  IconData get icon => type.icon;

  /// Get color based on rarity
  Color get color => rarity.color;

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'rarity': rarity.name,
      'duration': duration?.inMilliseconds,
      'cooldown': cooldown.inMilliseconds,
      'cost': cost,
      'isActive': isActive,
      'remainingDuration': remainingDuration?.inMilliseconds,
      'acquiredAt': acquiredAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'usesRemaining': usesRemaining,
      'properties': properties,
    };
  }

  /// Create from JSON
  factory PowerUp.fromJson(Map<String, dynamic> json) {
    return PowerUp(
      id: json['id'] as String,
      type: PowerUpType.values.firstWhere((t) => t.name == json['type']),
      rarity: PowerUpRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => PowerUpRarity.common,
      ),
      duration: json['duration'] != null 
          ? Duration(milliseconds: json['duration'])
          : null,
      cooldown: Duration(milliseconds: json['cooldown'] ?? 30000),
      cost: json['cost'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      remainingDuration: json['remainingDuration'] != null 
          ? Duration(milliseconds: json['remainingDuration'])
          : null,
      acquiredAt: DateTime.parse(json['acquiredAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null 
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      usesRemaining: json['usesRemaining'] as int? ?? 1,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }

  /// Generate unique ID for power-up
  static String _generateId() {
    return 'powerup_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get configuration for power-up type
  static Map<String, dynamic> _getPowerUpConfig(PowerUpType type) {
    switch (type) {
      case PowerUpType.clearLine:
        return {
          'rarity': PowerUpRarity.common,
          'duration': null,
          'cooldown': const Duration(seconds: 30),
          'cost': GameConstants.powerUpCosts['clearLine'] ?? 50,
          'uses': 1,
        };
      case PowerUpType.destroyBlock:
        return {
          'rarity': PowerUpRarity.common,
          'duration': null,
          'cooldown': const Duration(seconds: 20),
          'cost': GameConstants.powerUpCosts['destroyBlock'] ?? 30,
          'uses': 1,
        };
      case PowerUpType.doubleScore:
        return {
          'rarity': PowerUpRarity.rare,
          'duration': Duration(seconds: GameConstants.powerUpDurations['doubleScore']?.toInt() ?? 30),
          'cooldown': const Duration(minutes: 2),
          'cost': GameConstants.powerUpCosts['doubleScore'] ?? 60,
          'uses': 1,
        };
      case PowerUpType.slowTime:
        return {
          'rarity': PowerUpRarity.rare,
          'duration': Duration(seconds: GameConstants.powerUpDurations['slowTime']?.toInt() ?? 15),
          'cooldown': const Duration(minutes: 1),
          'cost': 40,
          'uses': 1,
        };
      case PowerUpType.extraTime:
        return {
          'rarity': PowerUpRarity.uncommon,
          'duration': Duration(seconds: GameConstants.powerUpDurations['extraTime']?.toInt() ?? 60),
          'cooldown': const Duration(minutes: 3),
          'cost': GameConstants.powerUpCosts['extraTime'] ?? 40,
          'uses': 1,
        };
      case PowerUpType.perfectClear:
        return {
          'rarity': PowerUpRarity.legendary,
          'duration': null,
          'cooldown': const Duration(minutes: 5),
          'cost': GameConstants.powerUpCosts['perfectClear'] ?? 100,
          'uses': 1,
        };
      case PowerUpType.ghostMode:
        return {
          'rarity': PowerUpRarity.epic,
          'duration': const Duration(seconds: 10),
          'cooldown': const Duration(minutes: 2),
          'cost': 80,
          'uses': 1,
        };
      case PowerUpType.magneticBlocks:
        return {
          'rarity': PowerUpRarity.uncommon,
          'duration': const Duration(seconds: 20),
          'cooldown': const Duration(seconds: 45),
          'cost': 35,
          'uses': 1,
        };
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        rarity,
        duration,
        cooldown,
        cost,
        isActive,
        remainingDuration,
        acquiredAt,
        lastUsedAt,
        usesRemaining,
        properties,
      ];
}

/// Power-up type enumeration
enum PowerUpType {
  clearLine,
  destroyBlock,
  doubleScore,
  slowTime,
  extraTime,
  perfectClear,
  ghostMode,
  magneticBlocks;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case PowerUpType.clearLine:
        return 'Clear Line';
      case PowerUpType.destroyBlock:
        return 'Destroy Block';
      case PowerUpType.doubleScore:
        return 'Double Score';
      case PowerUpType.slowTime:
        return 'Slow Time';
      case PowerUpType.extraTime:
        return 'Extra Time';
      case PowerUpType.perfectClear:
        return 'Perfect Clear';
      case PowerUpType.ghostMode:
        return 'Ghost Mode';
      case PowerUpType.magneticBlocks:
        return 'Magnetic Blocks';
    }
  }

  String get description {
    switch (this) {
      case PowerUpType.clearLine:
        return 'Instantly clear the bottom line';
      case PowerUpType.destroyBlock:
        return 'Remove any single block from the grid';
      case PowerUpType.doubleScore:
        return 'Double all points for 30 seconds';
      case PowerUpType.slowTime:
        return 'Slow down falling blocks for 15 seconds';
      case PowerUpType.extraTime:
        return 'Add extra time to the timer';
      case PowerUpType.perfectClear:
        return 'Clear the entire grid instantly';
      case PowerUpType.ghostMode:
        return 'Blocks can pass through others briefly';
      case PowerUpType.magneticBlocks:
        return 'Blocks automatically snap to best position';
    }
  }

  IconData get icon {
    switch (this) {
      case PowerUpType.clearLine:
        return Icons.horizontal_rule;
      case PowerUpType.destroyBlock:
        return Icons.delete_forever;
      case PowerUpType.doubleScore:
        return Icons.star;
      case PowerUpType.slowTime:
        return Icons.schedule;
      case PowerUpType.extraTime:
        return Icons.access_time;
      case PowerUpType.perfectClear:
        return Icons.clear_all;
      case PowerUpType.ghostMode:
        return Icons.visibility_off;
      case PowerUpType.magneticBlocks:
        return Icons.my_location;
    }
  }

  bool get canStackWithSelf {
    switch (this) {
      case PowerUpType.clearLine:
      case PowerUpType.destroyBlock:
      case PowerUpType.perfectClear:
        return true; // Instant effects can be used multiple times
      case PowerUpType.doubleScore:
      case PowerUpType.slowTime:
      case PowerUpType.extraTime:
      case PowerUpType.ghostMode:
      case PowerUpType.magneticBlocks:
        return false; // Duration-based effects don't stack
    }
  }

  PowerUpCategory get category {
    switch (this) {
      case PowerUpType.clearLine:
      case PowerUpType.destroyBlock:
      case PowerUpType.perfectClear:
        return PowerUpCategory.destructive;
      case PowerUpType.doubleScore:
        return PowerUpCategory.scoring;
      case PowerUpType.slowTime:
      case PowerUpType.extraTime:
        return PowerUpCategory.time;
      case PowerUpType.ghostMode:
      case PowerUpType.magneticBlocks:
        return PowerUpCategory.movement;
    }
  }
}

/// Power-up rarity enumeration
enum PowerUpRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case PowerUpRarity.common:
        return 'Common';
      case PowerUpRarity.uncommon:
        return 'Uncommon';
      case PowerUpRarity.rare:
        return 'Rare';
      case PowerUpRarity.epic:
        return 'Epic';
      case PowerUpRarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case PowerUpRarity.common:
        return const Color(0xFF9E9E9E); // Gray
      case PowerUpRarity.uncommon:
        return const Color(0xFF4CAF50); // Green
      case PowerUpRarity.rare:
        return const Color(0xFF2196F3); // Blue
      case PowerUpRarity.epic:
        return const Color(0xFF9C27B0); // Purple
      case PowerUpRarity.legendary:
        return const Color(0xFFFF9800); // Orange
    }
  }

  double get dropRate {
    switch (this) {
      case PowerUpRarity.common:
        return 0.50; // 50%
      case PowerUpRarity.uncommon:
        return 0.30; // 30%
      case PowerUpRarity.rare:
        return 0.15; // 15%
      case PowerUpRarity.epic:
        return 0.04; // 4%
      case PowerUpRarity.legendary:
        return 0.01; // 1%
    }
  }
}

/// Power-up category enumeration
enum PowerUpCategory {
  destructive,
  scoring,
  time,
  movement;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case PowerUpCategory.destructive:
        return 'Destructive';
      case PowerUpCategory.scoring:
        return 'Scoring';
      case PowerUpCategory.time:
        return 'Time';
      case PowerUpCategory.movement:
        return 'Movement';
    }
  }

  IconData get icon {
    switch (this) {
      case PowerUpCategory.destructive:
        return Icons.delete_forever;
      case PowerUpCategory.scoring:
        return Icons.star;
      case PowerUpCategory.time:
        return Icons.access_time;
      case PowerUpCategory.movement:
        return Icons.open_with;
    }
  }
}

/// Power-up collection for managing multiple power-ups
class PowerUpCollection extends Equatable {
  final List<PowerUp> powerUps;
  final int maxCapacity;

  const PowerUpCollection({
    this.powerUps = const [],
    this.maxCapacity = 5,
  });

  /// Add a power-up to the collection
  PowerUpCollection add(PowerUp powerUp) {
    final newList = List<PowerUp>.from(powerUps);
    
    if (newList.length >= maxCapacity) {
      // Remove oldest common power-up to make room
      final oldestCommon = newList
          .where((p) => p.rarity == PowerUpRarity.common)
          .reduce((a, b) => a.acquiredAt.isBefore(b.acquiredAt) ? a : b);
      newList.remove(oldestCommon);
    }
    
    newList.add(powerUp);
    return PowerUpCollection(powerUps: newList, maxCapacity: maxCapacity);
  }

  /// Remove a power-up from the collection
  PowerUpCollection remove(String powerUpId) {
    final newList = powerUps.where((p) => p.id != powerUpId).toList();
    return PowerUpCollection(powerUps: newList, maxCapacity: maxCapacity);
  }

  /// Get power-ups by type
  List<PowerUp> getByType(PowerUpType type) {
    return powerUps.where((p) => p.type == type).toList();
  }

  /// Get power-ups by category
  List<PowerUp> getByCategory(PowerUpCategory category) {
    return powerUps.where((p) => p.type.category == category).toList();
  }

  /// Get active power-ups
  List<PowerUp> get activePowerUps {
    return powerUps.where((p) => p.isActive).toList();
  }

  /// Get usable power-ups
  List<PowerUp> get usablePowerUps {
    return powerUps.where((p) => p.canUse).toList();
  }

  /// Check if collection is full
  bool get isFull => powerUps.length >= maxCapacity;

  /// Get total value of all power-ups
  int get totalValue {
    return powerUps.fold(0, (sum, p) => sum + p.cost);
  }

  @override
  List<Object> get props => [powerUps, maxCapacity];
}