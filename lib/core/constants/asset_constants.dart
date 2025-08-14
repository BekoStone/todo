// lib/core/constants/asset_constants.dart
class AssetConstants {
  AssetConstants._();

  // Images
  static const String blockCat = 'assets/images/block_cat.png';
  static const String blockDog = 'assets/images/block_dog.png';
  static const String blockStar = 'assets/images/block_star.png';

 // Background
  static const String bgGame = 'assets/images/bg_game.png';

  // Audio
  static const String audioClick = 'assets/audio/click.mp3';
  static const String audioClear = 'assets/audio/clear.mp3';
  static const String audioBgm   = 'assets/audio/bgm.mp3';

  // Animations
  static const String animSpark = 'assets/animations/spark.json';

  // Bundles
static const List<String> blockTiles = [blockCat, blockDog, blockStar];
  static const List<String> audioAll  = [audioClick, audioClear, audioBgm];
  static const List<String> animAll   = [animSpark];

  static const List<String> all = [
    ...blockTiles,
    ...audioAll,
    ...animAll,
  ];
}
