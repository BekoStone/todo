// File: lib/presentation/cubit/player_cubit.dart

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/domain/entities/power_up_entity.dart';
import 'package:puzzle_box/domain/usecases/achievement_usecases_dart.dart';
import '../../domain/usecases/player_usecases.dart';

/// Player state status
enum PlayerStateStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

/// Player cubit state
class PlayerState extends Equatable {
  final PlayerStateStatus status;
  final PlayerStats? playerStats;
  final List<Achievement> achievements;
  final List<Achievement> recentUnlocks;
  final Map<PowerUpType, int> powerUpInventory;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final bool hasUnseenAchievements;
  final int totalCoinsEarned;
  final double achievementProgress;

  const PlayerState({
    this.status = PlayerStateStatus.initial,
    this.playerStats,
    this.achievements = const [],
    this.recentUnlocks = const [],
    this.powerUpInventory = const {},
    this.errorMessage,
    this.lastUpdated,
    this.hasUnseenAchievements = false,
    this.totalCoinsEarned = 0,
    this.achievementProgress = 0.0,
  });

  bool get isLoading => status == PlayerStateStatus.loading || status == PlayerStateStatus.updating;
  bool get isLoaded => status == PlayerStateStatus.loaded;
  bool get hasError => status == PlayerStateStatus.error;
  bool get hasPlayerStats => playerStats != null;
  bool get canAffordPowerUp => playerStats != null && playerStats!.totalCoins > 0;
  
  int get unlockedAchievements => achievements.where((a) => a.isUnlocked).length;
  int get totalAchievements => achievements.length;
  
  List<Achievement> get unlockedAchievementsList => 
      achievements.where((a) => a.isUnlocked).toList();
  
  List<Achievement> get lockedAchievements => 
      achievements.where((a) => !a.isUnlocked).toList();
  
  List<Achievement> get secretAchievements => 
      achievements.where((a) => a.isSecret).toList();

  PlayerState copyWith({
    PlayerStateStatus? status,
    PlayerStats? playerStats,
    List<Achievement>? achievements,
    List<Achievement>? recentUnlocks,
    Map<PowerUpType, int>? powerUpInventory,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? hasUnseenAchievements,
    int? totalCoinsEarned,
    double? achievementProgress,
  }) {
    return PlayerState(
      status: status ?? this.status,
      playerStats: playerStats ?? this.playerStats,
      achievements: achievements ?? this.achievements,
      recentUnlocks: recentUnlocks ?? this.recentUnlocks,
      powerUpInventory: powerUpInventory ?? this.powerUpInventory,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasUnseenAchievements: hasUnseenAchievements ?? this.hasUnseenAchievements,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      achievementProgress: achievementProgress ?? this.achievementProgress,
    );
  }

  @override
  List<Object?> get props => [
        status,
        playerStats,
        achievements,
        recentUnlocks,
        powerUpInventory,
        errorMessage,
        lastUpdated,
        hasUnseenAchievements,
        totalCoinsEarned,
        achievementProgress,
      ];
}

/// Player cubit for managing player data and progress
class PlayerCubit extends Cubit<PlayerState> {
  final PlayerUseCases _playerUseCases;
  final AchievementUseCases _achievementUseCases;
  
  Timer? _statsUpdateTimer;
  StreamSubscription? _achievementSubscription;

  PlayerCubit(
    this._playerUseCases,
    this._achievementUseCases,
  ) : super(const PlayerState()) {
    _initializePeriodicUpdates();
  }

  /// Initialize player data
  Future<void> initializePlayer() async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.loading));

      // Load player stats
      final playerStats = await _playerUseCases.getPlayerStats();
      
      // Load achievements
      final achievements = await _playerUseCases.getAchievements();
      
      // Calculate achievement progress
      final unlockedCount = achievements.where((a) => a.isUnlocked).length;
      final progress = achievements.isNotEmpty ? unlockedCount / achievements.length : 0.0;
      
      // Calculate total coins earned from achievements
      final coinsFromAchievements = achievements
          .where((a) => a.isUnlocked)
          .fold(0, (sum, a) => sum + a.coinReward);

      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: playerStats,
        achievements: achievements,
        achievementProgress: progress,
        totalCoinsEarned: coinsFromAchievements,
        lastUpdated: DateTime.now(),
      ));

      developer.log(
        'Player initialized: ${achievements.length} achievements, ${unlockedCount} unlocked',
        name: 'PlayerCubit',
      );

    } catch (e) {
      developer.log('Failed to initialize player: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to initialize player data: $e',
      ));
    }
  }

  /// Update player statistics
  Future<void> updatePlayerStats({
    int? gamesPlayed,
    int? totalScore,
    int? highScore,
    int? totalCoins,
    int? achievementsUnlocked,
    Duration? totalPlayTime,
  }) async {
    if (state.playerStats == null) return;

    try {
      emit(state.copyWith(status: PlayerStateStatus.updating));

      final updatedStats = state.playerStats!.copyWith(
        gamesPlayed: gamesPlayed ?? state.playerStats!.gamesPlayed,
        totalScore: totalScore ?? state.playerStats!.totalScore,
        highScore: highScore != null 
            ? (highScore > state.playerStats!.highScore ? highScore : state.playerStats!.highScore)
            : state.playerStats!.highScore,
        totalCoins: totalCoins ?? state.playerStats!.totalCoins,
        achievementsUnlocked: achievementsUnlocked ?? state.playerStats!.achievementsUnlocked,
        totalPlayTime: totalPlayTime ?? state.playerStats!.totalPlayTime,
        lastPlayed: DateTime.now(),
      );

      await _playerUseCases.updatePlayerStats(updatedStats);

      emit(state.copyWith(
        status: PlayerStateStatus.loaded,
        playerStats: updatedStats,
        lastUpdated: DateTime.now(),
      ));

      developer.log('Player stats updated', name: 'PlayerCubit');

    } catch (e) {
      developer.log('Failed to update player stats: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to update player stats: $e',
      ));
    }
  }

  /// Add coins to player balance
  Future<void> addCoins(int amount, {String? source}) async {
    if (state.playerStats == null || amount <= 0) return;

    try {
      final newTotal = state.playerStats!.totalCoins + amount;
      await updatePlayerStats(totalCoins: newTotal);

      developer.log(
        'Added $amount coins${source != null ? ' from $source' : ''} (Total: $newTotal)',
        name: 'PlayerCubit',
      );

    } catch (e) {
      developer.log('Failed to add coins: $e', name: 'PlayerCubit');
    }
  }

  /// Spend coins from player balance
  Future<bool> spendCoins(int amount, {String? purpose}) async {
    if (state.playerStats == null || amount <= 0) return false;

    try {
      if (state.playerStats!.totalCoins < amount) {
        developer.log('Insufficient coins: need $amount, have ${state.playerStats!.totalCoins}', 
                     name: 'PlayerCubit');
        return false;
      }

      final newTotal = state.playerStats!.totalCoins - amount;
      await updatePlayerStats(totalCoins: newTotal);

      developer.log(
        'Spent $amount coins${purpose != null ? ' on $purpose' : ''} (Remaining: $newTotal)',
        name: 'PlayerCubit',
      );

      return true;

    } catch (e) {
      developer.log('Failed to spend coins: $e', name: 'PlayerCubit');
      return false;
    }
  }

  /// Purchase power-up with coins
  Future<bool> purchasePowerUp(PowerUpType powerUpType) async {
    try {
      final powerUpCosts = {
        PowerUpType.shuffle: 75,
        PowerUpType.undo: 50,
      };

      final cost = powerUpCosts[powerUpType];
      if (cost == null) return false;

      final success = await spendCoins(cost, purpose: 'power-up ${powerUpType.name}');
      if (!success) return false;

      // Add power-up to inventory
      final currentInventory = Map<PowerUpType, int>.from(state.powerUpInventory);
      currentInventory[powerUpType] = (currentInventory[powerUpType] ?? 0) + 1;

      emit(state.copyWith(powerUpInventory: currentInventory));

      developer.log('Purchased power-up: ${powerUpType.name}', name: 'PlayerCubit');
      return true;

    } catch (e) {
      developer.log('Failed to purchase power-up: $e', name: 'PlayerCubit');
      return false;
    }
  }

  /// Update achievement progress
  Future<void> updateAchievementProgress({
    required String achievementId,
    required int progress,
    bool isIncrement = false,
  }) async {
    try {
      final update = AchievementProgressUpdate(
        achievementId: achievementId,
        currentProgress: progress,
        isIncrement: isIncrement,
      );

      final result = await _achievementUseCases.updateAchievementProgress(update);

      if (result.hasNewUnlocks) {
        // Update achievements list
        final updatedAchievements = List<Achievement>.from(state.achievements);
        for (final newUnlock in result.newlyUnlocked) {
          final index = updatedAchievements.indexWhere((a) => a.id == newUnlock.id);
          if (index != -1) {
            updatedAchievements[index] = newUnlock;
          }
        }

        // Add coins for unlocked achievements
        final totalRewardCoins = result.totalRewardCoins;
        if (totalRewardCoins > 0) {
          await addCoins(totalRewardCoins, source: 'achievements');
        }

        // Calculate new progress
        final unlockedCount = updatedAchievements.where((a) => a.isUnlocked).length;
        final newProgress = updatedAchievements.isNotEmpty ? unlockedCount / updatedAchievements.length : 0.0;

        emit(state.copyWith(
          achievements: updatedAchievements,
          recentUnlocks: [...state.recentUnlocks, ...result.newlyUnlocked],
          hasUnseenAchievements: true,
          achievementProgress: newProgress,
        ));

        developer.log(
          'Achievements unlocked: ${result.newlyUnlocked.length} (+$totalRewardCoins coins)',
          name: 'PlayerCubit',
        );
      }

    } catch (e) {
      developer.log('Failed to update achievement progress: $e', name: 'PlayerCubit');
    }
  }

  /// Mark achievements as seen
  void markAchievementsSeen() {
    emit(state.copyWith(
      hasUnseenAchievements: false,
      recentUnlocks: [],
    ));
  }

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return state.achievements.where((a) => a.category == category).toList();
  }

  /// Get achievements near completion
  List<Achievement> getNearCompletionAchievements({double threshold = 0.8}) {
    return state.achievements
        .where((a) => !a.isUnlocked && 
                     a.currentProgress > 0 && 
                     (a.currentProgress / a.targetValue) >= threshold)
        .toList();
  }

  /// Reset player progress (for testing/debugging)
  Future<void> resetPlayerProgress() async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.loading));

      await _playerUseCases.resetPlayerStats();
      await _achievementUseCases.resetAllAchievements();
      
      await initializePlayer();

      developer.log('Player progress reset', name: 'PlayerCubit');

    } catch (e) {
      developer.log('Failed to reset player progress: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to reset player progress: $e',
      ));
    }
  }

  /// Export player data
  Future<Map<String, dynamic>> exportPlayerData() async {
    try {
      final playerData = await _playerUseCases.exportPlayerData();
      final achievementData = await _achievementUseCases.exportAchievementData();

      return {
        'player_data': playerData,
        'achievement_data': achievementData,
        'exported_at': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0.0',
      };

    } catch (e) {
      developer.log('Failed to export player data: $e', name: 'PlayerCubit');
      throw BusinessLogicException('Failed to export player data: $e');
    }
  }

  /// Import player data
  Future<void> importPlayerData(Map<String, dynamic> data) async {
    try {
      emit(state.copyWith(status: PlayerStateStatus.loading));

      await _playerUseCases.importPlayerData(data);
      await initializePlayer();

      developer.log('Player data imported successfully', name: 'PlayerCubit');

    } catch (e) {
      developer.log('Failed to import player data: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to import player data: $e',
      ));
    }
  }

  /// Process game completion for achievements
  Future<void> processGameCompletion({
    required int finalScore,
    required int level,
    required int linesCleared,
    required int blocksPlaced,
    required Duration gameDuration,
    required bool usedUndo,
  }) async {
    try {
      // Update game stats
      await updatePlayerStats(
        gamesPlayed: (state.playerStats?.gamesPlayed ?? 0) + 1,
        totalScore: (state.playerStats?.totalScore ?? 0) + finalScore,
        highScore: finalScore,
        totalPlayTime: (state.playerStats?.totalPlayTime ?? Duration.zero) + gameDuration,
      );

      // Process achievements
      final result = await _achievementUseCases.processGameSessionAchievements(
        finalScore: finalScore,
        level: level,
        linesCleared: linesCleared,
        blocksPlaced: blocksPlaced,
        comboCount: 0, // Would be passed from game state
        perfectClear: false, // Would be determined from game state
        usedUndo: usedUndo,
        sessionDuration: gameDuration,
      );

      if (result.hasNewUnlocks) {
        await _handleAchievementUnlocks(result);
      }

    } catch (e) {
      developer.log('Failed to process game completion: $e', name: 'PlayerCubit');
    }
  }

  /// Handle achievement unlocks
  Future<void> _handleAchievementUnlocks(AchievementCheckResult result) async {
    // Update achievements
    final updatedAchievements = List<Achievement>.from(state.achievements);
    for (final unlock in result.newlyUnlocked) {
      final index = updatedAchievements.indexWhere((a) => a.id == unlock.id);
      if (index != -1) {
        updatedAchievements[index] = unlock;
      }
    }

    // Award coins
    if (result.totalRewardCoins > 0) {
      await addCoins(result.totalRewardCoins, source: 'achievements');
    }

    // Update state
    emit(state.copyWith(
      achievements: updatedAchievements,
      recentUnlocks: [...state.recentUnlocks, ...result.newlyUnlocked],
      hasUnseenAchievements: true,
    ));
  }

  /// Initialize periodic updates
  void _initializePeriodicUpdates() {
    // Update stats every 30 seconds during active gameplay
    _statsUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (state.isLoaded) {
        // Refresh player data periodically
        _refreshPlayerData();
      }
    });
  }

  /// Refresh player data
  Future<void> _refreshPlayerData() async {
    try {
      final playerStats = await _playerUseCases.getPlayerStats();
      if (playerStats.id == state.playerStats?.id) {
        emit(state.copyWith(
          playerStats: playerStats,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      developer.log('Failed to refresh player data: $e', name: 'PlayerCubit');
    }
  }

  @override
  Future<void> close() {
    _statsUpdateTimer?.cancel();
    _achievementSubscription?.cancel();
    return super.close();
  }
}