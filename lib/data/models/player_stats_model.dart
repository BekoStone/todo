import 'package:equatable/equatable.dart';

class PlayerStatsModel extends Equatable {
  final String playerId;
  final int totalScore;
  final int bestScore;
  final int totalGamesPlayed;
  final int totalTimePlayed; // in seconds
  final int totalBlocksPlaced;
  final int totalLinesCleared;
  final int currentCoins;
  final int totalCoinsEarned;
  final int bestCombo;
  final int bestStreak;
  final int perfectClears;
  final Map<String, int> powerUpInventory;
  final Map<String, bool> achievements;
  final List<int> recentScores;
  final DateTime firstPlayDate;
  final DateTime lastPlayDate;
  final Map<String, dynamic> settings;
  final Map<String, dynamic> metadata;
  
  const PlayerStatsModel({
    required this.playerId,
    this.totalScore = 0,
    this.bestScore = 0,
    this.totalGamesPlayed = 0,
    this.totalTimePlayed = 0,
    this.totalBlocksPlaced = 0,
    this.totalLinesCleared = 0,
    this.currentCoins = 100,
    this.totalCoinsEarned = 100,
    this.bestCombo = 0,
    this.bestStreak = 0,
    this.perfectClears = 0,
    this.powerUpInventory = const {},
    this.achievements = const {},
    this.recentScores = const [],
    required this.firstPlayDate,
    required this.lastPlayDate,
    this.settings = const {},
    this.metadata = const {},
  });
  
  // Create new player
  factory PlayerStatsModel.newPlayer(String playerId) {
    final now = DateTime.now();
    return PlayerStatsModel(
      playerId: playerId,
      firstPlayDate: now,
      lastPlayDate: now,
      currentCoins: 100,
      totalCoinsEarned: 100,
      powerUpInventory: const {
        'shuffle': 2,
        'undo': 3,
        'hint': 1,
      },
      settings: const {
        'musicEnabled': true,
        'sfxEnabled': true,
        'musicVolume': 0.5,
        'sfxVolume': 0.7,
        'showHints': true,
        'autoSave': true,
      },
    );
  }
  
  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'totalScore': totalScore,
      'bestScore': bestScore,
      'totalGamesPlayed': totalGamesPlayed,
      'totalTimePlayed': totalTimePlayed,
      'totalBlocksPlaced': totalBlocksPlaced,
      'totalLinesCleared': totalLinesCleared,
      'currentCoins': currentCoins,
      'totalCoinsEarned': totalCoinsEarned,
      'bestCombo': bestCombo,
      'bestStreak': bestStreak,
      'perfectClears': perfectClears,
      'powerUpInventory': powerUpInventory,
      'achievements': achievements,
      'recentScores': recentScores,
      'firstPlayDate': firstPlayDate.toIso8601String(),
      'lastPlayDate': lastPlayDate.toIso8601String(),
      'settings': settings,
      'metadata': metadata,
    };
  }
  
  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    return PlayerStatsModel(
      playerId: json['playerId'] ?? '',
      totalScore: json['totalScore'] ?? 0,
      bestScore: json['bestScore'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalTimePlayed: json['totalTimePlayed'] ?? 0,
      totalBlocksPlaced: json['totalBlocksPlaced'] ?? 0,
      totalLinesCleared: json['totalLinesCleared'] ?? 0,
      currentCoins: json['currentCoins'] ?? 100,
      totalCoinsEarned: json['totalCoinsEarned'] ?? 100,
      bestCombo: json['bestCombo'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      perfectClears: json['perfectClears'] ?? 0,
      powerUpInventory: Map<String, int>.from(json['powerUpInventory'] ?? {}),
      achievements: Map<String, bool>.from(json['achievements'] ?? {}),
      recentScores: List<int>.from(json['recentScores'] ?? []),
      firstPlayDate: DateTime.tryParse(json['firstPlayDate'] ?? '') ?? DateTime.now(),
      lastPlayDate: DateTime.tryParse(json['lastPlayDate'] ?? '') ?? DateTime.now(),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  // Copy with modifications
  PlayerStatsModel copyWith({
    String? playerId,
    int? totalScore,
    int? bestScore,
    int? totalGamesPlayed,
    int? totalTimePlayed,
    int? totalBlocksPlaced,
    int? totalLinesCleared,
    int? currentCoins,
    int? totalCoinsEarned,
    int? bestCombo,
    int? bestStreak,
    int? perfectClears,
    Map<String, int>? powerUpInventory,
    Map<String, bool>? achievements,
    List<int>? recentScores,
    DateTime? firstPlayDate,
    DateTime? lastPlayDate,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return PlayerStatsModel(
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
      achievements: achievements ?? this.achievements,
      recentScores: recentScores ?? this.recentScores,
      firstPlayDate: firstPlayDate ?? this.firstPlayDate,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }
  
  // Update after game session
  PlayerStatsModel updateAfterGame({
    required int gameScore,
    required int blocksPlaced,
    required int linesCleared,
    required int maxCombo,
    required int maxStreak,
    required int timePlayed,
    required int coinsEarned,
    bool hadPerfectClear = false,
  }) {
    final updatedRecentScores = [gameScore, ...recentScores].take(10).toList();
    
    return copyWith(
      totalScore: totalScore + gameScore,
      bestScore: gameScore > bestScore ? gameScore : bestScore,
      totalGamesPlayed: totalGamesPlayed + 1,
      totalTimePlayed: totalTimePlayed + timePlayed,
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
  
  // Power-up management
  PlayerStatsModel usePowerUp(String powerUpType) {
    final currentInventory = Map<String, int>.from(powerUpInventory);
    final currentCount = currentInventory[powerUpType] ?? 0;
    
    if (currentCount > 0) {
      currentInventory[powerUpType] = currentCount - 1;
      return copyWith(powerUpInventory: currentInventory);
    }
    
    return this;
  }
  
  PlayerStatsModel addPowerUp(String powerUpType, int count) {
    final currentInventory = Map<String, int>.from(powerUpInventory);
    currentInventory[powerUpType] = (currentInventory[powerUpType] ?? 0) + count;
    return copyWith(powerUpInventory: currentInventory);
  }
  
  // Coin management
  PlayerStatsModel spendCoins(int amount) {
    if (currentCoins >= amount) {
      return copyWith(currentCoins: currentCoins - amount);
    }
    return this;
  }
  
  PlayerStatsModel addCoins(int amount) {
    return copyWith(
      currentCoins: currentCoins + amount,
      totalCoinsEarned: totalCoinsEarned + amount,
    );
  }
  
  // Achievement management
  PlayerStatsModel unlockAchievement(String achievementId) {
    final updatedAchievements = Map<String, bool>.from(achievements);
    updatedAchievements[achievementId] = true;
    return copyWith(achievements: updatedAchievements);
  }
  
  // Settings management
  PlayerStatsModel updateSetting(String key, dynamic value) {
    final updatedSettings = Map<String, dynamic>.from(settings);
    updatedSettings[key] = value;
    return copyWith(settings: updatedSettings);
  }
  
  // Statistics calculations
  double get averageScore {
    return totalGamesPlayed > 0 ? totalScore / totalGamesPlayed : 0;
  }
  
  double get averageGameTime {
    return totalGamesPlayed > 0 ? totalTimePlayed / totalGamesPlayed : 0;
  }
  
  double get blocksPerGame {
    return totalGamesPlayed > 0 ? totalBlocksPlaced / totalGamesPlayed : 0;
  }
  
  double get linesPerGame {
    return totalGamesPlayed > 0 ? totalLinesCleared / totalGamesPlayed : 0;
  }
  
  double get coinsPerGame {
    return totalGamesPlayed > 0 ? totalCoinsEarned / totalGamesPlayed : 0;
  }
  
  int get playDays => DateTime.now().difference(firstPlayDate).inDays + 1;
  
  double get gamesPerDay => playDays > 0 ? totalGamesPlayed / playDays : 0;
  
  // Performance metrics
  String get performanceRating {
    if (averageScore >= 5000) return 'Master';
    if (averageScore >= 3000) return 'Expert';
    if (averageScore >= 1500) return 'Advanced';
    if (averageScore >= 500) return 'Intermediate';
    return 'Beginner';
  }
  
  double get efficiency {
    if (totalBlocksPlaced == 0) return 0;
    return totalLinesCleared / totalBlocksPlaced;
  }
  
  // Progress tracking
  Map<String, dynamic> getProgressData() {
    return {
      'level': (totalScore / 10000).floor() + 1,
      'levelProgress': (totalScore % 10000) / 10000,
      'experiencePoints': totalScore,
      'rank': performanceRating,
      'achievements': achievements.length,
      'totalAchievements': 20, // This should come from achievement definitions
      'completionPercentage': (achievements.length / 20) * 100,
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
    achievements,
    recentScores,
    firstPlayDate,
    lastPlayDate,
    settings,
    metadata,
  ];
}