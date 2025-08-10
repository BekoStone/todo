// File: lib/presentation/cubit/cubit_extensions.dart
// Extensions to add missing methods to existing cubits

import 'dart:developer' as developer;
import 'package:puzzle_box/core/state/game_state.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/core/state/state_extensions.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/presentation/flame/box_hooks_game.dart' show GameStateStatus;

/// Extension for GameCubit to add missing methods
extension GameCubitMethods on GameCubit {
  /// Pause the current game
  void pauseGame() {
    if (state.isPlaying) {
      emit(state.copyWith(status: GameStateStatus.paused));
      developer.log('Game paused', name: 'GameCubit');
    }
  }
  
  /// Resume the paused game
  void resumeGame() {
    if (state.isPaused) {
      emit(state.copyWith(status: GameStateStatus.playing));
      developer.log('Game resumed', name: 'GameCubit');
    }
  }
  
  /// End the current game
  void endGame() {
    if (state.isPlaying || state.isPaused) {
      emit(state.copyWith(
        status: GameStateStatus.gameOver,
        lastActionTime: DateTime.now(),
      ));
      developer.log('Game ended', name: 'GameCubit');
    }
  }
  
  /// Load an existing game session
  Future<void> loadGame(String sessionId) async {
    try {
      emit(state.copyWith(status: GameStateStatus.loading));
      
      // Load game session logic here
      // final session = await _gameUseCases.loadGameSession(sessionId);
      
      emit(state.copyWith(
        status: GameStateStatus.playing,
        // currentSession: session,
        lastActionTime: DateTime.now(),
      ));
      
      developer.log('Game loaded: $sessionId', name: 'GameCubit');
    } catch (e) {
      emit(state.copyWith(
        status: GameStateStatus.error,
        errorMessage: 'Failed to load game: $e',
      ));
      developer.log('Failed to load game: $e', name: 'GameCubit');
    }
  }
  
  /// Initialize the game cubit (public method)
  void initialize() {
    developer.log('GameCubit initialized', name: 'GameCubit');
    // Add any initialization logic here
    _initializeAutoSave();
  }
  
  /// Initialize auto-save functionality
  void _initializeAutoSave() {
    // Setup auto-save timer
    // Timer.periodic(AppConstants.autoSaveInterval, (_) => _autoSave());
  }
  
  /// Auto-save current game state
  void _autoSave() {
    if (state.isPlaying && state.currentSession != null) {
      try {
        // Auto-save logic would go here
        developer.log('Game auto-saved', name: 'GameCubit');
      } catch (e) {
        developer.log('Auto-save failed: $e', name: 'GameCubit');
      }
    }
  }
}

/// Extension for PlayerCubit to add missing methods  
extension PlayerCubitMethods on PlayerCubit {
  /// Export player data (if this method was being called)
  Future<Map<String, dynamic>> exportPlayerData() async {
    try {
      final playerData = await super.exportPlayerData();
      developer.log('Player data exported', name: 'PlayerCubit');
      return playerData;
    } catch (e) {
      developer.log('Failed to export player data: $e', name: 'PlayerCubit');
      rethrow;
    }
  }
  
  /// Initialize player (public wrapper)
  Future<void> initializePlayer() async {
    try {
      await super.initializePlayer();
      developer.log('Player initialized', name: 'PlayerCubit');
    } catch (e) {
      developer.log('Failed to initialize player: $e', name: 'PlayerCubit');
      emit(state.copyWith(
        status: PlayerStateStatus.error,
        errorMessage: 'Failed to initialize player: $e',
      ));
    }
  }
  
  /// Add coins safely with validation
  Future<void> addCoins(int amount, {String source = 'unknown'}) async {
    try {
      if (amount <= 0) {
        developer.log('Invalid coin amount: $amount', name: 'PlayerCubit');
        return;
      }
      
      final currentStats = state.playerStats;
      if (currentStats == null) {
        developer.log('No player stats available for adding coins', name: 'PlayerCubit');
        return;
      }
      
      final newCoins = currentStats.totalCoins + amount;
      final updatedStats = currentStats.copyWith(totalCoins: newCoins);
      
      emit(state.copyWith(
        playerStats: updatedStats,
        totalCoinsEarned: state.totalCoinsEarned + amount,
      ));
      
      developer.log('Added $amount coins from $source. Total: $newCoins', name: 'PlayerCubit');
    } catch (e) {
      developer.log('Failed to add coins: $e', name: 'PlayerCubit');
    }
  }
}

/// Extension for UICubit to add missing methods
extension UICubitMethods on UICubit {
  /// Navigate to a specific page with proper error handling
  void navigateToPage(AppPage page, {Map<String, dynamic>? data}) {
    try {
      super.navigateToPage(page, data: data);
    } catch (e) {
      developer.log('Navigation failed: $e', name: 'UICubit');
      showError('Navigation failed: $e');
    }
  }
  
  /// Toggle music with proper state management
  Future<void> toggleMusic() async {
    try {
      await super.toggleMusic();
      developer.log('Music toggled', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle music: $e', name: 'UICubit');
      showError('Failed to toggle music');
    }
  }
  
  /// Toggle animations safely
  Future<void> toggleAnimations() async {
    try {
      await super.toggleAnimations();
      developer.log('Animations toggled', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle animations: $e', name: 'UICubit');
      showError('Failed to toggle animations');
    }
  }
  
  /// Set volume with validation
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await setMusicVolume(clampedVolume);
      developer.log('Volume set to: $clampedVolume', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to set volume: $e', name: 'UICubit');
      showError('Failed to set volume');
    }
  }
  
  /// Toggle theme safely
  Future<void> toggleTheme() async {
    try {
      await toggleThemeMode();
      developer.log('Theme toggled', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to toggle theme: $e', name: 'UICubit');
      showError('Failed to toggle theme');
    }
  }
  
  /// Show achievement unlock (if referenced in other files)
  void showAchievementUnlock(Achievement achievement) {
    try {
      // Show achievement unlock UI
      showLoading();
      
      // You could emit a specific state for achievement display
      emit(state.copyWith(
        pageData: {
          'achievement_unlock': {
            'achievement_id': achievement.id,
            'title': achievement.title,
            'description': achievement.description,
            'reward_coins': achievement.coinReward,
          }
        }
      ));
      
      // Auto-hide after delay
      Future.delayed(const Duration(seconds: 3), () {
        hideLoading();
        emit(state.copyWith(pageData: {}));
      });
      
      developer.log('Achievement unlock shown: ${achievement.title}', name: 'UICubit');
    } catch (e) {
      developer.log('Failed to show achievement unlock: $e', name: 'UICubit');
    }
  }
}

/// Helper class for safe state transitions
class StateTransitionHelper {
  /// Safely transition game state
  static void safeGameStateTransition(GameCubit cubit, GameStateStatus newStatus) {
    try {
      final currentStatus = cubit.state.status;
      
      // Validate state transition
      if (_isValidGameStateTransition(currentStatus, newStatus)) {
        cubit.emit(cubit.state.copyWith(status: newStatus));
        developer.log('Game state: $currentStatus → $newStatus', name: 'StateTransition');
      } else {
        developer.log('Invalid game state transition: $currentStatus → $newStatus', name: 'StateTransition');
      }
    } catch (e) {
      developer.log('Failed to transition game state: $e', name: 'StateTransition');
    }
  }
  
  /// Check if game state transition is valid
  static bool _isValidGameStateTransition(GameStateStatus from, GameStateStatus to) {
    // Define valid state transitions
    const validTransitions = {
      GameStateStatus.initial: [GameStateStatus.loading],
      GameStateStatus.loading: [GameStateStatus.playing, GameStateStatus.error],
      GameStateStatus.playing: [GameStateStatus.paused, GameStateStatus.gameOver, GameStateStatus.error],
      GameStateStatus.paused: [GameStateStatus.playing, GameStateStatus.gameOver],
      GameStateStatus.gameOver: [GameStateStatus.loading, GameStateStatus.playing],
      GameStateStatus.error: [GameStateStatus.initial, GameStateStatus.loading],
    };
    
    return validTransitions[from]?.contains(to) ?? false;
  }
  
  /// Safely transition player state
  static void safePlayerStateTransition(PlayerCubit cubit, PlayerStateStatus newStatus) {
    try {
      final currentStatus = cubit.state.status;
      
      if (_isValidPlayerStateTransition(currentStatus, newStatus)) {
        cubit.emit(cubit.state.copyWith(status: newStatus));
        developer.log('Player state: $currentStatus → $newStatus', name: 'StateTransition');
      } else {
        developer.log('Invalid player state transition: $currentStatus → $newStatus', name: 'StateTransition');
      }
    } catch (e) {
      developer.log('Failed to transition player state: $e', name: 'StateTransition');
    }
  }
  
  /// Check if player state transition is valid
  static bool _isValidPlayerStateTransition(PlayerStateStatus from, PlayerStateStatus to) {
    const validTransitions = {
      PlayerStateStatus.initial: [PlayerStateStatus.loading],
      PlayerStateStatus.loading: [PlayerStateStatus.loaded, PlayerStateStatus.error],
      PlayerStateStatus.loaded: [PlayerStateStatus.updating, PlayerStateStatus.error],
      PlayerStateStatus.updating: [PlayerStateStatus.loaded, PlayerStateStatus.error],
      PlayerStateStatus.error: [PlayerStateStatus.loading],
    };
    
    return validTransitions[from]?.contains(to) ?? false;
  }
}