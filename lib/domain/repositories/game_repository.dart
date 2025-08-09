import '../entities/game_session_entity.dart';

/// GameRepository defines the contract for game data operations.
/// Provides abstraction for game session management, state persistence, and analytics.
/// Follows Clean Architecture principles by defining domain-level contracts.
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

  /// Get player's personal best score
  Future<int?> getPersonalBest();

  // ========================================
  // GAME ANALYTICS
  // ========================================

  /// Get comprehensive game statistics
  Future<Map<String, dynamic>> getGameStatistics();

  /// Get recent game sessions
  Future<List<Map<String, dynamic>>> getRecentGames({int limit = 10});

  // ========================================
  // HINT SYSTEM
  // ========================================

  /// Generate a hint for the current game state
  Future<Map<String, dynamic>?> generateHint({
    required List<List<int>> gridState,
    required List<Map<String, dynamic>> availableBlocks,
  });

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  /// Clear all game-related data
  Future<bool> clearAllGameData();

  /// Export all game data for backup
  Future<Map<String, dynamic>> exportGameData();

  /// Import game data from backup
  Future<bool> importGameData(Map<String, dynamic> gameData);
}