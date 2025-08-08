import 'package:equatable/equatable.dart';

class PlayerStats extends Equatable {
  final String playerId;
  final int totalScore;
  final int bestScore;
  final int totalGamesPlayed;
  final Duration totalTimePlayed;
  final int totalBlocksPlaced;
  final int totalLinesCleared;
  final int currentCoins;
  final int totalCoinsEarned;
  final int bestCombo;
  final int bestStreak;
  final int perfectClears;
  final Map<String, int> powerUpInventory;
  final Set<String> unlockedAchievements;
  final List<int> recentScores;
  final DateTime firstPlayDate;
  final DateTime lastPlayDate;
  final Map<String, dynamic> settings;
  
  const PlayerStats({
    required this.playerId,
    this.totalScore = 0,
    this.bestScore = 0,
    this.totalGamesPlayed = 0,
    this.totalTimePlayed = Duration.zero,
    this.totalBlocksPlaced = 0,
    this.totalLinesCleared = 0,
    this.currentCoins = 100,
    this.totalCoinsEarned = 100,
    this.bestCombo = 0,
    this.bestStreak = 0,
    this.perfectClears = 0,
    this.powerUpInventory = const {},
    this.unlockedAchievements = const {},
    this.recentScores = const [],
    required this.firstPlayDate,
    required this.lastPlayDate,
    this.settings = const {},
  });
  
  // Create new player
  factory PlayerStats.newPlayer(String playerId) {
    final now = DateTime.now();
    return PlayerStats(
      playerId: playerId,
      firstPlayDate: now,
      lastPlayDate: now,
      powerUpInventory: {
        'shuffle': 2,
        'undo': 3,
        'hint': 1,
      },
      settings: {
        'musicEnabled': true,
        'sfxEnabled': true,
        'musicVolume': 0.5,
        'sfxVolume': 0.7,
      },
    );
  }
  
  // Copy with modifications
  PlayerStats copyWith({
    String? playerId,
    int? totalScore,
    int? bestScore,
    int? totalGamesPlayed,
    Duration? totalTimePlayed,
    int? totalBlocksPlaced,
    int? totalLinesCleared,
    int? currentCoins,
    int? totalCoinsEarned,
    int? bestCombo,
    int? bestStreak,
    int? perfectClears,
    Map<String, int>? powerUpInventory,
    Set<String>? unlockedAchievements,
    List<int>? recentScores,
    DateTime? firstPlayDate,
    DateTime? lastPlayDate,
    Map<String, dynamic>? settings,
  }) {
    return PlayerStats(
      playerId: playerId ?? this.playerId,
      totalScore: totalScore ?? this.totalScore,
      bestScore: bestScore ?? this.bestScore,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalTimePlayed: totalTimePlayed ?? this.totalTimePlayed,
      totalBlocksPlaced: totalBlocksPlaced ?? this.totalBlocksPlaced,
      totalLinesCleared: totalLinesCleared ?? this.totalLinesCleared,
      currentCoins: currentCoins ?? this.currentCoins,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      bestCombo: bestCombo ?? this.bestCombo,
      bestStreak: bestStreak ?? this.bestStreak,
      perfectClears: perfectClears ?? this.perfectClears,
      powerUpInventory: powerUpInventory ?? this.powerUpInventory,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      recentScores: recentScores ?? this.recentScores,
      firstPlayDate: firstPlayDate ?? this.firstPlayDate,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
      settings: settings ?? this.settings,
    );
  }
  
  // Game session updates
  PlayerStats afterGameSession({
    required int gameScore,
    required int blocksPlaced,
    required int linesCleared,
    required int maxCombo,
    required int maxStreak,
    required Duration sessionTime,
    required int coinsEarned,
    bool hadPerfectClear = false,
  }) {
    final updatedRecentScores = [gameScore, ...recentScores].take(10).toList();
    
    return copyWith(
      totalScore: totalScore + gameScore,
      bestScore: gameScore > bestScore ? gameScore : bestScore,
      totalGamesPlayed: totalGamesPlayed + 1,
      totalTimePlayed: totalTimePlayed + sessionTime,
      totalBlocksPlaced: totalBlocksPlaced + blocksPlaced,
      totalLinesCleared: totalLinesCleared + linesCleared,
      currentCoins: currentCoins + coinsEarned,
      totalCoinsEarned: totalCoinsEarned + coinsEarned,
      bestCombo: maxCombo > bestCombo ? maxCombo : bestCombo,
      bestStreak: maxStreak > bestStreak ? maxStreak : bestStreak,
      perfectClears: hadPerfectClear ? perfectClears + 1 : perfectClears,
      recentScores: updatedRecentScores,
      lastPlayDate: DateTime.now(),
    );
  }
  
  // Power-up operations
  PlayerStats usePowerUp(String powerUpType) {
    final currentInventory = Map<String, int>.from(powerUpInventory);
    final currentCount = currentInventory[powerUpType] ?? 0;
    
    if (currentCount > 0) {
      currentInventory[powerUpType] = currentCount - 1;
      return copyWith(powerUpInventory: currentInventory);
    }
    
    return this;
  }
  
  PlayerStats addPowerUp(String powerUpType, int count) {
    final currentInventory = Map<String, int>.from(powerUpInventory);
    currentInventory[powerUpType] = (currentInventory[powerUpType] ?? 0) + count;
    return copyWith(powerUpInventory: currentInventory);
  }
  
  bool hasPowerUp(String powerUpType) {
    return (powerUpInventory[powerUpType] ?? 0) > 0;
  }
  
  int getPowerUpCount(String powerUpType) {
    return powerUpInventory[powerUpType] ?? 0;
  }
  
  // Coin operations
  PlayerStats spendCoins(int amount) {
    if (currentCoins >= amount) {
      return copyWith(currentCoins: currentCoins - amount);
    }
    return this;
  }
  
  PlayerStats addCoins(int amount) {
    return copyWith(
      currentCoins: currentCoins + amount,
      totalCoinsEarned: totalCoinsEarned + amount,
    );
  }
  
  bool canAfford(int amount) => currentCoins >= amount;
  
  // Achievement operations
  PlayerStats unlockAchievement(String achievementId) {
    final updatedAchievements = Set<String>.from(unlockedAchievements);
    updatedAchievements.add(achievementId);
    return copyWith(unlockedAchievements: updatedAchievements);
  }
  
  bool hasAchievement(String achievementId) {
    return unlockedAchievements.contains(achievementId);
  }
  
  // Settings operations
  PlayerStats updateSetting(String key, dynamic value) {
    final updatedSettings = Map<String, dynamic>.from(settings);
    updatedSettings[key] = value;
    return copyWith(settings: updatedSettings);
  }
  
  T? getSetting<T>(String key, [T? defaultValue]) {
    return settings[key] as T? ?? defaultValue;
  }
  
  // Statistics calculations
  double get averageScore {
    return totalGamesPlayed > 0 ? totalScore / totalGamesPlayed : 0;
  }
  
  double get averageGameTime {
    return totalGamesPlayed > 0 
        ? totalTimePlayed.inSeconds / totalGamesPlayed 
        : 0;
  }
  
  double get blocksPerGame {
    return totalGamesPlayed > 0 ? totalBlocksPlaced / totalGamesPlayed : 0;
  }
  
  double get linesPerGame {
    return totalGamesPlayed > 0 ? totalLinesCleared / totalGamesPlayed : 0;
  }
  
  double get efficiency {
    return totalBlocksPlaced > 0 ? totalLinesCleared / totalBlocksPlaced : 0;
  }
  
  int get playDays => DateTime.now().difference(firstPlayDate).inDays + 1;
  
  double get gamesPerDay => playDays > 0 ? totalGamesPlayed / playDays : 0;
  
  // Performance ratings
  String get skillLevel {
    if (averageScore >= 5000) return 'Master';
    if (averageScore >= 3000) return 'Expert';
    if (averageScore >= 1500) return 'Advanced';
    if (averageScore >= 500) return 'Intermediate';
    return 'Beginner';
  }
  
  int get experienceLevel => (totalScore / 10000).floor() + 1;
  
  double get experienceProgress {
    final currentLevelScore = (experienceLevel - 1) * 10000;
    final nextLevelScore = experienceLevel * 10000;
    final progressScore = totalScore - currentLevelScore;
    return progressScore / (nextLevelScore - currentLevelScore);
  }
  
  // Streaks and consistency
  bool get isOnStreak => recentScores.length >= 3 && 
      recentScores.take(3).every((score) => score > averageScore * 0.8);
  
  bool get isImproving => recentScores.length >= 5 &&
      recentScores.take(3).reduce((a, b) => a + b) >
      recentScores.skip(2).take(3).reduce((a, b) => a + b);
  
  // Daily reward eligibility
  bool get canClaimDailyReward {
    final now = DateTime.now();
    final daysSinceLastPlay = now.difference(lastPlayDate).inDays;
    return daysSinceLastPlay >= 1;
  }
  
  // Achievement progress helpers
  double getAchievementProgress(String achievementId, int targetValue) {
    switch (achievementId) {
      case 'total_score':
        return (totalScore / targetValue).clamp(0.0, 1.0);
      case 'games_played':
        return (totalGamesPlayed / targetValue).clamp(0.0, 1.0);
      case 'blocks_placed':
        return (totalBlocksPlaced / targetValue).clamp(0.0, 1.0);
      case 'lines_cleared':
        return (totalLinesCleared / targetValue).clamp(0.0, 1.0);
      case 'best_combo':
        return (bestCombo / targetValue).clamp(0.0, 1.0);
      case 'perfect_clears':
        return (perfectClears / targetValue).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }
  
  // Summary data for UI
  Map<String, dynamic> getSummaryData() {
    return {
      'skillLevel': skillLevel,
      'experienceLevel': experienceLevel,
      'experienceProgress': experienceProgress,
      'totalPlayTime': totalTimePlayed.inHours,
      'averageScore': averageScore.round(),
      'efficiency': (efficiency * 100).round(),
      'achievementCount': unlockedAchievements.length,
      'isOnStreak': isOnStreak,
      'isImproving': isImproving,
      'playDays': playDays,
      'gamesPerDay': gamesPerDay.toStringAsFixed(1),
    };
  }
  
  @override
  List<Object?> get props => [
    playerId,
    totalScore,
    bestScore,
    totalGamesPlayed,
    totalTimePlayed,
    totalBlocksPlaced,
    totalLinesCleared,
    currentCoins,
    totalCoinsEarned,
    bestCombo,
    bestStreak,
    perfectClears,
    powerUpInventory,
    unlockedAchievements,
    recentScores,
    firstPlayDate,
    lastPlayDate,
    settings,
  ];
}