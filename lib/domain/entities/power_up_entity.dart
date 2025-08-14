enum PowerUpType {
  bomb,
  line,
  color, // ✅ restored
}

class PowerUpEntity {
  final PowerUpType type;
  const PowerUpEntity(this.type);

  String get displayName {
    switch (type) {
      case PowerUpType.bomb:
        return 'Bomb';
      case PowerUpType.line:
        return 'Line';
      case PowerUpType.color:
        return 'Color';
    }
  }
}
