// File: lib/core/state/state_extensions.dart
// Extensions and classes to support proper state management

import 'dart:ui';

import 'package:puzzle_box/core/state/game_state.dart';
import 'package:puzzle_box/core/state/player_state.dart';
import 'package:puzzle_box/core/state/ui_state.dart';
import 'package:puzzle_box/domain/entities/achievement_entity.dart' hide Achievement;
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import 'package:puzzle_box/domain/entities/player_stats_entity.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/ui_cubit_dart.dart';

/// Extensions for GameState to add helper methods
extension GameStateExtensions on GameState {
  /// Check if game is currently being played
  bool get isPlaying => status == GameStateStatus.playing;
  
  /// Check if game is paused
  bool get isPaused => status == GameStateStatus.paused;
  
  /// Check if game is over
  bool get isGameOver => status == GameStateStatus.gameOver;
  
  /// Check if game has error
  bool get hasError => status == GameStateStatus.error;
  
  /// Check if game is loading
  bool get isLoading => status == GameStateStatus.loading;
  
  /// Get current session safely
  GameSession? get safeCurrentSession => currentSession;
}

/// Extensions for PlayerState to add helper methods  
extension PlayerStateExtensions on PlayerState {
  /// Check if player data is loaded
  bool get isDataLoaded => status == PlayerStateStatus.loaded;
  
  /// Check if player is updating
  bool get isUpdating => status == PlayerStateStatus.updating;
  
  /// Get safe player stats
  PlayerStats? get safePlayerStats => playerStats;
  
  /// Get total coins safely
  int get safeCoins => playerStats?.totalCoins ?? 0;
  
  /// Get high score safely
  int get safeHighScore => playerStats?.highScore ?? 0;
}

/// Extensions for UIState to add helper methods
extension UIStateExtensions on UIState {
  /// Check if currently on game page
  bool get isOnGamePage => currentPage == AppPage.game;
  
  /// Check if currently on main menu
  bool get isOnMainMenu => currentPage == AppPage.mainMenu;
  
  /// Check if currently on settings page
  bool get isOnSettings => currentPage == AppPage.settings;
  
  /// Get safe screen size
  Size get safeScreenSize => screenSize ?? const Size(375, 812); // iPhone fallback
}

/// State management helper functions
class StateHelper {
  /// Safely convert game state to display data
  static Map<String, dynamic> gameStateToDisplayData(GameState state) {
    return {
      'score': state.score,
      'level': state.level,
      'linesCleared': state.linesCleared,
      'comboCount': state.comboCount,
      'isPlaying': state.isPlaying,
      'isPaused': state.isPaused,
      'canUndo': state.canUndo,
      'remainingUndos': state.remainingUndos,
    };
  }
  
  /// Safely convert player state to display data
  static Map<String, dynamic> playerStateToDisplayData(PlayerState state) {
    return {
      'totalCoins': state.safeCoins,
      'highScore': state.safeHighScore,
      'gamesPlayed': state.playerStats?.totalGamesPlayed ?? 0,
      'achievementsUnlocked': state.achievements.length,
      'totalAchievements': state.achievements.length,
      'hasUnseenAchievements': state.hasUnseenAchievements,
    };
  }
  
  /// Check if state management is ready
  static bool isStateManagementReady(GameState gameState, PlayerState playerState, UIState uiState) {
    return !gameState.isLoading && 
           playerState.isDataLoaded && 
           !uiState.isLoading;
  }
}

/// State synchronizer for cross-cubit communication
class StateSynchronizer {
  /// Sync game completion with player progress
  static void syncGameCompletion(GameState gameState, PlayerCubit playerCubit) {
    if (gameState.isGameOver && gameState.currentSession != null) {
      playerCubit.processGameCompletion(
        finalScore: gameState.score,
        level: gameState.level,
        linesCleared: gameState.linesCleared,
        blocksPlaced: 0, // Would be tracked in actual game state
        gameDuration: gameState.sessionDuration ?? Duration.zero,
        usedUndo: gameState.remainingUndos < 3, 
        usedPowerUps: {},
      );
    }
  }
  
  /// Sync achievement unlocks with UI notifications
  static void syncAchievementUnlocks(PlayerState playerState, UICubit uiCubit) {
    if (playerState.hasUnseenAchievements && playerState.unlockedAchievements.isNotEmpty) {
      // Could trigger UI celebration or notifications
      for (final achievement in playerState.unlockedAchievements) {
        // Show achievement unlock animation
        uiCubit.showAchievementUnlock(achievement);
      }
    }
  }
}

/// Mock missing methods for UICubit if they don't exist
extension UICubitExtensions on UICubit {
  /// Show achievement unlock notification
  void showAchievementUnlock(Achievement achievement) {
    // Show achievement unlock UI
    showLoading(); // Placeholder - replace with actual achievement UI
    
    // Auto-hide after delay
    Future.delayed(const Duration(seconds: 3), () {
      hideLoading();
    });
  }
  
  /// Show power-up usage effect
  void showPowerUpUsed(String powerUpType) {
    // Show power-up usage visual feedback
  }
  
  /// Update game UI elements
  void updateGameUI(Map<String, dynamic> gameData) {
    // Update game-specific UI elements
  }
}

/// State validation helpers
class StateValidator {
  /// Validate game state consistency
  static bool validateGameState(GameState state) {
    // Check for inconsistent state
    if (state.isPlaying && state.currentSession == null) {
      return false;
    }
    
    if (state.score < 0 || state.level < 1) {
      return false;
    }
    
    return true;
  }
  
  /// Validate player state consistency
  static bool validatePlayerState(PlayerState state) {
    if (state.playerStats != null) {
      if (state.playerStats!.totalCoins < 0) {
        return false;
      }
    }
    
    return true;
  }
}

/// Cross-cubit event system
abstract class StateEvent {
  const StateEvent();
}

class GameCompletedEvent extends StateEvent {
  final GameState gameState;
  const GameCompletedEvent(this.gameState);
}

class AchievementUnlockedEvent extends StateEvent {
  final Achievement achievement;
  const AchievementUnlockedEvent(this.achievement);
}

class PowerUpUsedEvent extends StateEvent {
  final String powerUpType;
  const PowerUpUsedEvent(this.powerUpType);
}

/// Event dispatcher for state management
class StateEventDispatcher {
  static final List<void Function(StateEvent)> _listeners = [];
  
  /// Add event listener
  static void addListener(void Function(StateEvent) listener) {
    _listeners.add(listener);
  }
  
  /// Remove event listener
  static void removeListener(void Function(StateEvent) listener) {
    _listeners.remove(listener);
  }
  
  /// Dispatch event to all listeners
  static void dispatch(StateEvent event) {
    for (final listener in _listeners) {
      try {
        listener(event);
      } catch (e) {
        print('Error in state event listener: $e');
      }
    }
  }
}