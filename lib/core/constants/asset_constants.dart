class AssetConstants {
  // Images
  static const String _imagesPath = 'assets/images';
  
  // UI Assets
  static const String logo = '$_imagesPath/ui/logo.png';
  static const String iconStar = '$_imagesPath/ui/icon_star.png';
  static const String iconCoin = '$_imagesPath/ui/icon_coin.png';
  static const String splashImage = '$_imagesPath/ui/splash.png';
  
  // Backgrounds
  static const String bgMainMenu = '$_imagesPath/backgrounds/bg_mainmenu.jpg';
  static const String bgGame = '$_imagesPath/backgrounds/bg_game.jpg';
  
  // Block Assets
  static const String blockTexture = '$_imagesPath/blocks/block_texture.png';
  static const String blockGlow = '$_imagesPath/blocks/block_glow.png';
  
  // Audio
  static const String _audioPath = 'assets/audio';
  
  // Sound Effects
  static const String sfxClick = '$_audioPath/sfx/click.mp3';
  static const String sfxDrop = '$_audioPath/sfx/drop.mp3';
  static const String sfxClear = '$_audioPath/sfx/clear.mp3';
  static const String sfxCombo = '$_audioPath/sfx/combo.mp3';
  static const String sfxPerfect = '$_audioPath/sfx/perfect.mp3';
  static const String sfxError = '$_audioPath/sfx/error.mp3';
  static const String sfxReward = '$_audioPath/sfx/reward.mp3';
  static const String sfxButton = '$_audioPath/sfx/button.mp3';
  static const String sfxWin = '$_audioPath/sfx/win.mp3';
  static const String sfxLose = '$_audioPath/sfx/lose.mp3';
  
  // Background Music
  static const String musicMenu = '$_audioPath/music/menu.mp3';
  static const String musicGame = '$_audioPath/music/game.mp3';
  static const String musicGameOver = '$_audioPath/music/game_over.mp3';
  
  // Asset Lists for Preloading
  static const List<String> criticalImages = [
    logo,
    iconStar,
    iconCoin,
    splashImage,
  ];
  
  static const List<String> gameImages = [
    bgMainMenu,
    bgGame,
    blockTexture,
    blockGlow,
  ];
    static const List<String> requiredImages = [
    ...criticalImages,
    ...gameImages,
  ];

  
  static const List<String> criticalSounds = [
    sfxClick,
    sfxDrop,
    sfxClear,
    sfxButton,
  ];
  
  static const List<String> gameSounds = [
    sfxCombo,
    sfxPerfect,
    sfxError,
    sfxReward,
    sfxWin,
    sfxLose,
  ];
  
  static const List<String> musicTracks = [
    musicMenu,
    musicGame,
    musicGameOver,
  ];
  static const List<String> requiredAudio = [
    ...criticalSounds,
    ...gameSounds,
    ...musicTracks,
  ];
  
  
  // Asset Priorities
  static const Map<String, int> assetPriorities = {
    // Critical = 0, High = 1, Medium = 2, Low = 3
    'splash': 0,
    'ui': 1,
    'game': 1,
    'effects': 2,
    'music': 2,
  };
}