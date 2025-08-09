import '../entities/game_session_entity.dart';
import '../entities/block_entity.dart';

/// Repository contract for game-related data operations.
/// Defines all game data management methods including sessions, state, and scores.
/// Follows Repository pattern to abstract data layer implementation details.
abstract class GameRepository {
  // ========================================
  // GAME SESSION MANAGEMENT
  // ========================================

  /// Create a new game session
  Future<GameSession> createGameSession({
    required GameDifficulty difficulty,
    String? sessionId,
    bool isFirstGame = false,
    Map<String, dynamic>? metadata,
  });

  /// Load an existing game session by ID
  Future<GameSession?> loadGameSession(String sessionId);

  /// Save/update a game session
  Future<bool> saveGameSession(GameSession gameSession);

  /// Delete a game session
  Future<bool> deleteGameSession(String sessionId);

  /// Get all game sessions
  Future<List<GameSession>> getAllGameSessions();

  /// Load the most recent saved game (for continue functionality)
  Future<GameSession?> loadSavedGame();

  /// Save game for quick resume
  Future<bool> saveGame(GameSession gameSession);

  /// Create a new game with specified difficulty
  Future<GameSession> createNewGame({GameDifficulty? difficulty});

  /// Clear saved game data
  Future<bool> clearSavedGame();

  /// Get active game session
  Future<GameSession?> getActiveSession();

  /// Mark session as completed
  Future<bool> completeGameSession(String sessionId, Map<String, dynamic> completionData);

  // ========================================
  // GAME STATE MANAGEMENT
  // ========================================

  /// Save current game state for auto-save/resume functionality
  Future<bool> saveGameState({
    required String sessionId,
    required Map<String, dynamic> gameState,
  });

  /// Load saved game state for resuming
  Future<Map<String, dynamic>?> loadGameState(String sessionId);

  /// Get previous game state (for undo functionality)
  Future<Map<String, dynamic>?> getPreviousGameState(String sessionId);

  /// Clear current game state
  Future<bool> clearGameState();

  /// Save game state snapshot (for undo system)
  Future<bool> saveGameStateSnapshot(String sessionId, Map<String, dynamic> state);

  /// Get game state history
  Future<List<Map<String, dynamic>>> getGameStateHistory(String sessionId, {int limit = 10});

  /// Auto-save current game state
  Future<bool> autoSaveGameState(GameSession gameSession);

  // ========================================
  // HIGH SCORES MANAGEMENT
  // ========================================

  /// Save final score for a completed game
  Future<bool> saveFinalScore({
    required String sessionId,
    required int finalScore,
    Map<String, dynamic>? completionData,
  });

  /// Get high scores list
  Future<List<Map<String, dynamic>>> getHighScores({int limit = 10});

  /// Get personal best score
  Future<int> getPersonalBest();

  /// Check if score qualifies as high score
  Future<bool> isHighScore(int score);

  /// Get rank for a specific score
  Future<int> getScoreRank(int score);

  /// Get scores for specific difficulty
  Future<List<Map<String, dynamic>>> getScoresByDifficulty(GameDifficulty difficulty);

  /// Get today's best score
  Future<int> getTodaysBest();

  /// Get this week's best score
  Future<int> getWeeksBest();

  // ========================================
  // GAME ANALYTICS & STATISTICS
  // ========================================

  /// Get comprehensive game statistics
  Future<Map<String, dynamic>> getGameStatistics();

  /// Get recent games summary
  Future<List<Map<String, dynamic>>> getRecentGames({int limit = 10});

  /// Get play time statistics
  Future<Map<String, dynamic>> getPlayTimeStats();

  /// Get level progression statistics
  Future<Map<String, dynamic>> getLevelStats();

  /// Get block placement statistics
  Future<Map<String, dynamic>> getBlockStats();

  /// Get combo and streak statistics
  Future<Map<String, dynamic>> getComboStats();

  /// Record game analytics event
  Future<bool> recordAnalyticsEvent(String eventName, Map<String, dynamic> data);

  // ========================================
  // HINT SYSTEM & ASSISTANCE
  // ========================================

  /// Get hint for current game state
  Future<Map<String, dynamic>?> getHint(GameSession gameSession);

  /// Get optimal move suggestions
  Future<List<Map<String, dynamic>>> getMovesSuggestions(GameSession gameSession);

  /// Check if hint is available
  Future<bool> isHintAvailable(String sessionId);

  /// Record hint usage
  Future<bool> recordHintUsage(String sessionId, String hintType);

  /// Get tutorial progress
  Future<Map<String, dynamic>> getTutorialProgress();

  /// Update tutorial progress
  Future<bool> updateTutorialProgress(String step, bool completed);

  // ========================================
  // GAME CONFIGURATION
  // ========================================

  /// Get game difficulty settings
  Future<Map<String, dynamic>> getDifficultySettings();

  /// Update difficulty settings
  Future<bool> updateDifficultySettings(GameDifficulty difficulty, Map<String, dynamic> settings);

  /// Get game rules configuration
  Future<Map<String, dynamic>> getGameRules();

  /// Get scoring configuration
  Future<Map<String, dynamic>> getScoringRules();

  /// Get power-up configuration
  Future<Map<String, dynamic>> getPowerUpConfig();

  // ========================================
  // BACKUP & RESTORE
  // ========================================

  /// Export all game data
  Future<Map<String, dynamic>> exportGameData();

  /// Import game data from backup
  Future<bool> importGameData(Map<String, dynamic> data);

  /// Validate game data integrity
  Future<bool> validateGameData();

  /// Clear all game data
  Future<bool> clearAllGameData();

  /// Get data backup summary
  Future<Map<String, dynamic>> getBackupSummary();

  // ========================================
  // MULTIPLAYER SUPPORT (Future)
  // ========================================

  /// Create multiplayer session
  Future<GameSession?> createMultiplayerSession({
    required List<String> playerIds,
    required GameDifficulty difficulty,
  });

  /// Join multiplayer session
  Future<bool> joinMultiplayerSession(String sessionId, String playerId);

  /// Leave multiplayer session
  Future<bool> leaveMultiplayerSession(String sessionId, String playerId);

  /// Get multiplayer session data
  Future<Map<String, dynamic>?> getMultiplayerSession(String sessionId);

  /// Sync multiplayer game state
  Future<bool> syncMultiplayerState(String sessionId, Map<String, dynamic> state);

  // ========================================
  // CACHING & PERFORMANCE
  // ========================================

  /// Preload critical game data
  Future<bool> preloadGameData();

  /// Clear game data cache
  Future<bool> clearGameDataCache();

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats();

  /// Optimize data storage
  Future<bool> optimizeDataStorage();
}