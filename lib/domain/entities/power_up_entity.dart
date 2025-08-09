import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PowerUpType {
  shuffle,
  undo,
  hint,
  bomb,
  freeze, hammer, lineClear,
}

enum PowerUpRarity {
  common,
  rare,
  epic,

}

class PowerUp extends Equatable {
  final PowerUpType type;
  final String name;
  final String description;
  final String icon;
  final PowerUpRarity rarity;
  final int cost;
  final Duration? cooldown;
  final int maxUses;
  final Color color;
  final Map<String, dynamic> properties;
  
  const PowerUp({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    this.rarity = PowerUpRarity.common,
    required this.cost,
    this.cooldown,
    this.maxUses = 1,
    required this.color,
    this.properties = const {}, required String id,
  });
  
  // Pre-defined power-ups
  static const Map<PowerUpType, PowerUp> definitions = {
    PowerUpType.shuffle: PowerUp(
      type: PowerUpType.shuffle,
      name: 'Shuffle',
      description: 'Replace current blocks with new ones',
      icon: '🔄',
      rarity: PowerUpRarity.common,
      cost: 75,
      color: Colors.blue,
      properties: {
        'generateNewBlocks': true,
        'clearCurrentBlocks': true,
      }, id: '',
    ),
    
    PowerUpType.undo: PowerUp(
      type: PowerUpType.undo,
      name: 'Undo',
      description: 'Undo your last move',
      icon: '↩️',
      rarity: PowerUpRarity.common,
      cost: 50,
      color: Colors.orange,
      properties: {
        'stepsBack': 1,
        'restoreScore': true,
      }, id: '',
    ),
    
    PowerUpType.hint: PowerUp(
      type: PowerUpType.hint,
      name: 'Hint',
      description: 'Show the best placement for a block',
      icon: '💡',
      rarity: PowerUpRarity.common,
      cost: 25,
      color: Colors.yellow,
      properties: {
        'showOptimalPlacement': true,
        'highlightDuration': 3000,
      }, id: '',
    ),
    
    PowerUpType.bomb: PowerUp(
      type: PowerUpType.bomb,
      name: 'Bomb',
      description: 'Clear a 3x3 area on the grid',
      icon: '💣',
      rarity: PowerUpRarity.rare,
      cost: 100,
      cooldown: Duration(seconds: 60),
      color: Colors.red,
      properties: {
        'explosionRadius': 3,
        'clearBlocks': true,
      }, id: 'bomb',
      
    ),
    
    PowerUpType.freeze: PowerUp(
      type: PowerUpType.freeze,
      name: 'Freeze',
      description: 'Pause time to think about your move',
      icon: '❄️',
      rarity: PowerUpRarity.epic,
      cost: 150,
      cooldown: Duration(seconds: 30),
      color: Colors.lightBlue,
      properties: {
        'freezeDuration': 10000,
        'pauseTimer': true,
      }, id: '',
    ),
  };
  
  // Copy with modifications
  PowerUp copyWith({
    PowerUpType? type,
    String? name,
    String? description,
    String? icon,
    PowerUpRarity? rarity,
    int? cost,
    Duration? cooldown,
    int? maxUses,
    Color? color,
    Map<String, dynamic>? properties,
  }) {
    return PowerUp(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      rarity: rarity ?? this.rarity,
      cost: cost ?? this.cost,
      cooldown: cooldown ?? this.cooldown,
      maxUses: maxUses ?? this.maxUses,
      color: color ?? this.color,
      properties: properties ?? this.properties, id: '',
    );
  }
  
  // Properties
  bool get hasCooldown => cooldown != null;
  bool get isLimitedUse => maxUses > 0;
  bool get isInstantUse => cooldown == null;
  
  String get rarityName {
    return rarity.name.substring(0, 1).toUpperCase() + rarity.name.substring(1);
  }
  
  Color get rarityColor {
    switch (rarity) {
      case PowerUpRarity.common:
        return Colors.grey;
      case PowerUpRarity.rare:
        return Colors.blue;
      case PowerUpRarity.epic:
        return Colors.purple;
    }
  }
  
  // Get property value
  T? getProperty<T>(String key, [T? defaultValue]) {
    return properties[key] as T? ?? defaultValue;
  }
  
  // Effect descriptions
  String get effectDescription {
    switch (type) {
      case PowerUpType.shuffle:
        return 'Removes all current blocks and generates new ones';
      case PowerUpType.undo:
        return 'Reverts the game state to before your last move';
      case PowerUpType.hint:
        return 'Highlights the optimal position for placing a block';
      case PowerUpType.bomb:
        return 'Destroys blocks in a ${getProperty('explosionRadius', 3)}x${getProperty('explosionRadius', 3)} area';
      case PowerUpType.freeze:
        return 'Pauses all timers for ${getProperty('freezeDuration', 10000)! ~/ 1000} seconds';
      case PowerUpType.hammer:
        // TODO: Handle this case.
        throw UnimplementedError();
      case PowerUpType.lineClear:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
  
  // Usage validation
  bool canBeUsed(Map<String, dynamic> gameState) {
    switch (type) {
      case PowerUpType.shuffle:
        return gameState['hasActiveBlocks'] == true;
      
      case PowerUpType.undo:
        return gameState['canUndo'] == true;
      
      case PowerUpType.hint:
        return gameState['hasActiveBlocks'] == true && 
               gameState['hasValidMoves'] == true;
      
      case PowerUpType.bomb:
        return gameState['hasPlacedBlocks'] == true;
      
      case PowerUpType.freeze:
        return gameState['isTimerRunning'] == true;
      
      default:
        return true;
    }
  }
  
  // Effect duration (if applicable)
  Duration? get effectDuration {
    switch (type) {
      case PowerUpType.hint:
        return Duration(milliseconds: getProperty('highlightDuration', 3000));
      case PowerUpType.freeze:
        return Duration(milliseconds: getProperty('freezeDuration', 10000));
      default:
        return null;
    }
  }
  
  @override
  List<Object?> get props => [
    type,
    name,
    description,
    icon,
    rarity,
    cost,
    cooldown,
    maxUses,
    color,
    properties,
  ];
  
  @override
  String toString() {
    return 'PowerUp(type: $type, name: $name, cost: $cost)';
  }
}

// Power-up inventory item
class PowerUpInventoryItem extends Equatable {
  final PowerUp powerUp;
  final int quantity;
  final DateTime? lastUsed;
  final int timesUsed;
  
  const PowerUpInventoryItem({
    required this.powerUp,
    this.quantity = 0,
    this.lastUsed,
    this.timesUsed = 0,
  });
  
  // Copy with modifications
  PowerUpInventoryItem copyWith({
    PowerUp? powerUp,
    int? quantity,
    DateTime? lastUsed,
    int? timesUsed,
  }) {
    return PowerUpInventoryItem(
      powerUp: powerUp ?? this.powerUp,
      quantity: quantity ?? this.quantity,
      lastUsed: lastUsed ?? this.lastUsed,
      timesUsed: timesUsed ?? this.timesUsed,
    );
  }
  
  // Operations
  PowerUpInventoryItem use() {
    if (quantity <= 0) return this;
    
    return copyWith(
      quantity: quantity - 1,
      lastUsed: DateTime.now(),
      timesUsed: timesUsed + 1,
    );
  }
  
  PowerUpInventoryItem add(int amount) {
    return copyWith(quantity: quantity + amount);
  }
  
  // Status checks
  bool get isEmpty => quantity <= 0;
  bool get hasItems => quantity > 0;
  
  bool get isOnCooldown {
    if (powerUp.cooldown == null || lastUsed == null) return false;
    
    final timeSinceLastUse = DateTime.now().difference(lastUsed!);
    return timeSinceLastUse < powerUp.cooldown!;
  }
  
  Duration? get remainingCooldown {
    if (!isOnCooldown) return null;
    
    final timeSinceLastUse = DateTime.now().difference(lastUsed!);
    return powerUp.cooldown! - timeSinceLastUse;
  }
  
  bool canUse(Map<String, dynamic> gameState) {
    return hasItems && 
           !isOnCooldown && 
           powerUp.canBeUsed(gameState);
  }
  
  @override
  List<Object?> get props => [powerUp, quantity, lastUsed, timesUsed];
}

// Power-up manager for handling inventory and usage
class PowerUpManager {
  final Map<PowerUpType, PowerUpInventoryItem> _inventory;
  
  PowerUpManager(this._inventory);
  
  // Factory constructor with default inventory
  factory PowerUpManager.withDefaults() {
    return PowerUpManager({
      PowerUpType.shuffle: PowerUpInventoryItem(
        powerUp: PowerUp.definitions[PowerUpType.shuffle]!,
        quantity: 2,
      ),
      PowerUpType.undo: PowerUpInventoryItem(
        powerUp: PowerUp.definitions[PowerUpType.undo]!,
        quantity: 3,
      ),
      PowerUpType.hint: PowerUpInventoryItem(
        powerUp: PowerUp.definitions[PowerUpType.hint]!,
        quantity: 1,
      ),
    });
  }
  
  // Inventory operations
  PowerUpInventoryItem? getItem(PowerUpType type) => _inventory[type];
  
  int getQuantity(PowerUpType type) => _inventory[type]?.quantity ?? 0;
  
  bool hasItem(PowerUpType type) => getQuantity(type) > 0;
  
  bool canUse(PowerUpType type, Map<String, dynamic> gameState) {
    final item = _inventory[type];
    return item?.canUse(gameState) ?? false;
  }
  
  // Use power-up
  bool usePowerUp(PowerUpType type) {
    final item = _inventory[type];
    if (item == null || !item.hasItems) return false;
    
    _inventory[type] = item.use();
    return true;
  }
  
  // Add power-up
  void addPowerUp(PowerUpType type, int quantity) {
    final item = _inventory[type];
    if (item != null) {
      _inventory[type] = item.add(quantity);
    } else {
      final powerUp = PowerUp.definitions[type];
      if (powerUp != null) {
        _inventory[type] = PowerUpInventoryItem(
          powerUp: powerUp,
          quantity: quantity,
        );
      }
    }
  }
  
  // Get all available power-ups
  List<PowerUpInventoryItem> get availableItems {
    return _inventory.values.where((item) => item.hasItems).toList();
  }
  
  // Get all power-ups (including empty ones)
  List<PowerUpInventoryItem> get allItems {
    return PowerUp.definitions.keys.map((type) {
      return _inventory[type] ?? PowerUpInventoryItem(
        powerUp: PowerUp.definitions[type]!,
        quantity: 0,
      );
    }).toList();
  }
  
  // Purchase validation
  bool canAfford(PowerUpType type, int coins) {
    final powerUp = PowerUp.definitions[type];
    return powerUp != null && coins >= powerUp.cost;
  }
  
  // Cooldown management
  Map<PowerUpType, Duration> getActiveCooldowns() {
    final cooldowns = <PowerUpType, Duration>{};
    
    for (final entry in _inventory.entries) {
      final remainingCooldown = entry.value.remainingCooldown;
      if (remainingCooldown != null) {
        cooldowns[entry.key] = remainingCooldown;
      }
    }
    
    return cooldowns;
  }
  
  // Statistics
  int get totalPowerUps => _inventory.values
      .map((item) => item.quantity)
      .fold(0, (sum, quantity) => sum + quantity);
  
  int get totalUsed => _inventory.values
      .map((item) => item.timesUsed)
      .fold(0, (sum, used) => sum + used);
  
  Map<PowerUpType, int> get usageStats => Map.fromEntries(
    _inventory.entries.map((entry) => 
      MapEntry(entry.key, entry.value.timesUsed)
    )
  );
}