import 'dart:async';
import 'dart:developer' as developer;
import '../../domain/entities/game_session_entity.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/local_storage_datasource.dart';

/// GameRepositoryImpl provides concrete implementation of GameRepository.
/// Manages game session data, state persistence, and game-related operations.
/// Acts as a bridge between domain layer and data sources.
class GameRepositoryImpl implements GameRepository {
  final LocalStorageDataSource _localDataSource;

  GameRepositoryImpl(this._localDataSource);

  // ========================================
  // GAME SESSION MANAGEMENT
  // ========================================

  @override
  Future<GameSession> createGameSession({
    required GameDifficulty difficulty,
    String? sessionId,
    bool isFirstGame = false,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      developer.log('Creating new game session with difficulty: $difficulty', name: 'GameRepository');
      
      final gameSession = GameSession.create(
        sessionId: sessionId,
        difficulty: difficulty,
        isFirstGame: isFirstGame,
        metadata: metadata,
      );
      
      // Save the new session
      final success = await _localDataSource.saveGameSession(gameSession);
      if (!success) {
        throw Exception('Failed to save new game session');
      }
      
      developer.log('Game session created: ${gameSession.sessionId}', name: 'GameRepository');
      return gameSession;
      
    } catch (e, stackTrace) {
      developer.log('Error creating game session: $e', name: 'GameRepository', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<GameSession?> loadGameSession(String sessionId) async {
    try {
      developer.log('Loading game session: $sessionId', name: 'GameRepository');
      
      final gameSession = await _localDataSource.loadGameSession(sessionId);
      
      if (gameSession != null) {
        developer.log('Game session loaded successfully', name: 'GameRepository');
      } else {
        developer.log('Game session not found: $sessionId', name: 'GameRepository');
      }
      
      return gameSession;
      
    } catch (e, stackTrace) {
      developer.log('Error loading game session: $e', name: 'GameRepository', stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<bool> saveGameSession(GameSession gameSession) async {
    try {
      developer.log('Saving game session: ${gameSession.sessionId}', name: 'GameRepository');
      
      final success = await _localDataSource.saveGameSession(gameSession);
      
      if (success) {
        developer.log('Game session saved successfully', name: 'GameRepository');
      } else {
        developer.log('Failed to save game session', name: 'GameRepository');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      developer.log('Error saving game session: $e', name: 'GameRepository', stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<bool> deleteGameSession(String sessionId) async {
    try {
      developer.log('Deleting game session: $sessionId', name: 'GameRepository');
      
      final success = await _localDataSource.deleteGameSession(sessionId);
      
      if (success) {
        developer.log('Game session deleted successfully', name: 'GameRepository');
      } else {
        developer.log('Failed to delete game session', name: 'GameRepository');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      developer.log('Error deleting game session: $e', name: 'GameRepository', stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<List<GameSession>> getAllGameSessions() async {
    try {
      developer.log('Loading all game sessions', name: 'GameRepository');
      
      final sessions = await _localDataSource.loadAllGameSessions();
      
      developer.log('Loaded ${sessions.length} game sessions', name: 'GameRepository');
      return sessions;
      
    } catch (e, stackTrace) {
      developer.log('Error loading all game sessions: $e', name: 'GameRepository', stackTrace: stackTrace);
      return [];
    }
  }

  // ========================================
  // GAME STATE MANAGEMENT
  // ========================================

  @override
  Future<bool> saveGameState({
    required String sessionId,
    required Map<String, dynamic> gameState,
  }) async {
    try {
      developer.log('Saving game state for session: $sessionId', name: 'GameRepository');
      
      // Add session ID and timestamp to game state
      gameState['sessionId'] = sessionId;
      gameState['savedAt'] = DateTime.now().toIso8601String();
      
      final success = await _localDataSource.saveCurrentGameState(gameState);
      
      if (success) {
        developer.log('Game state saved successfully', name: 'GameRepository');
      } else {
        developer.log('Failed to save game state', name: 'GameRepository');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      developer.log('Error saving game state: $e', name: 'GameRepository', stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> loadGameState(String sessionId) async {
    try {
      developer.log('Loading game state for session: $sessionId', name: 'GameRepository');
      
      final gameState = await _localDataSource.loadCurrentGameState();
      
      // Verify the game state belongs to the requested session
      if (gameState != null && gameState['sessionId'] == sessionId) {
        developer.log('Game state loaded successfully', name: 'GameRepository');
        return gameState;
      } else if (gameState != null) {
        developer.log('Game state found but for different session', name: 'GameRepository');
        return null;
      } else {
        developer.log('No game state found', name: 'GameRepository');
        return null;
      }
      
    } catch (e, stackTrace) {
      developer.log('Error loading game state: $e', name: 'GameRepository', stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPreviousGameState(String sessionId) async {
    try {
      developer.log('Getting previous game state for session: $sessionId', name: 'GameRepository');
      
      // For now, return the current saved state
      // In a more complex implementation, this could maintain a history
      final gameState = await loadGameState(sessionId);
      
      if (gameState != null) {
        developer.log('Previous game state found', name: 'GameRepository');
      } else {
        developer.log('No previous game state found', name: 'GameRepository');
      }
      
      return gameState;
      
    } catch (e, stackTrace) {
      developer.log('Error getting previous game state: $e', name: 'GameRepository', stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<bool> clearGameState() async {
    try {
      developer.log('Clearing current game state', name: 'GameRepository');
      
      final success = await _localDataSource.saveCurrentGameState({});
      
      if (success) {
        developer.log('Game state cleared successfully', name: 'GameRepository');
      } else {
        developer.log('Failed to clear game state', name: 'GameRepository');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      developer.log('Error clearing game state: $e', name: 'GameRepository', stackTrace: stackTrace);
      return false;
    }
  }

  // ========================================
  // HIGH SCORES MANAGEMENT
  // ========================================

  @override
  Future<bool> saveFinalScore({
    required String sessionId,
    required int finalScore,
    Map<String, dynamic>? completionData,
  }) async {
    try {
      developer.log('Saving final score: $finalScore for session: $sessionId', name: 'GameRepository');
      
      final scoreData = {
        'sessionId': sessionId,
        'score': finalScore,
        'date': DateTime.now().toIso8601String(),
        'completionData': completionData ?? {},
      };
      
      final success = await _localDataSource.addHighScore(scoreData);
      
      if (success) {
        developer.log('Final score saved successfully', name: 'GameRepository');
      } else {
        developer.log('Failed to save final score', name: 'GameRepository');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      developer.log('Error saving final score: $e', name: 'GameRepository', stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHighScores({int limit = 10}) async {
    try {
      developer.log('Getting high scores (limit: $limit)', name: 'GameRepository');
      
      final allScores = await _localDataSource.loadHighScores();
      
      // Sort by score descending and apply limit
      allScores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      
      final limitedScores = allScores.take(limit).toList();
      
      developer.log('Retrieved ${limitedScores.length} high scores', name: 'GameRepository');
      return limitedScores;
      
    } catch (e, stackTrace) {
      developer.log('Error getting high scores: $e', name: 'GameRepository', stackTrace: stackTrace);
      return [];
    }
  }

  @override
  Future<int?> getPersonalBest() async {
    try {
      developer.log('Getting personal best score', name: 'GameRepository');
      
      final highScores = await getHighScores(limit: 1);
      
      if (highScores.isNotEmpty) {
        final personalBest = highScores.first['score'] as int;
        developer.log('Personal best: $personalBest', name: 'GameRepository');
        return personalBest;
      } else {
        developer.log('No personal best found', name: 'GameRepository');
        return null;
      }
      
    } catch (e, stackTrace) {
      developer.log('Error getting personal best: $e', name: 'GameRepository', stackTrace: stackTrace);
      return null;
    }
  }

  // ========================================
  // GAME ANALYTICS
  // ========================================

  @override
  Future<Map<String, dynamic>> getGameStatistics() async {
    try {
      developer.log('Getting game statistics', name: 'GameRepository');
      
      final sessions = await getAllGameSessions();
      final highScores = await _localDataSource.loadHighScores();
      
      // Calculate statistics
      int totalGames = sessions.length;
      int completedGames = sessions.where((s) => s.isCompleted).length;
      int totalScore = sessions.fold(0, (sum, s) => sum + s.currentScore);
      double averageScore = totalGames > 0 ? totalScore / totalGames : 0.0;
      int totalPlayTime = sessions.fold(0, (sum, s) => sum + s.actualPlayTime.inSeconds);
      int totalLinesCleared = sessions.fold(0, (sum, s) => sum + s.linesCleared);
      
      final statistics = {
        'totalGames': totalGames,
        'completedGames': completedGames,
        'completionRate': totalGames > 0 ? (completedGames / totalGames) * 100 : 0.0,
        'totalScore': totalScore,
        'averageScore': averageScore,
        'totalPlayTime': totalPlayTime,
        'totalLinesCleared': totalLinesCleared,
        'highScoreCount': highScores.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      developer.log('Game statistics calculated', name: 'GameRepository');
      return statistics;
      
    } catch (e, stackTrace) {
      developer.log('Error getting game statistics: $e', name: 'GameRepository', stackTrace: stackTrace);
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentGames({int limit = 10}) async {
    try {
      developer.log('Getting recent games (limit: $limit)', name: 'GameRepository');
      
      final sessions = await getAllGameSessions();
      
      // Sort by creation date descending
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      final recentSessions = sessions.take(limit).toList();
      
      // Convert to simple maps for easier consumption
      final recentGames = recentSessions.map((session) => {
        'sessionId': session.sessionId,
        'score': session.currentScore,
        'level': session.currentLevel,
        'linesCleared': session.linesCleared,
        'playTime': session.actualPlayTime.inSeconds,
        'difficulty': session.difficulty.displayName,
        'isCompleted': session.isCompleted,
        'date': session.createdAt.toIso8601String(),
      }).toList();
      
      developer.log('Retrieved ${recentGames.length} recent games', name: 'GameRepository');
      return recentGames;
      
    } catch (e, stackTrace) {
      developer.log('Error getting recent games: $e', name: 'GameRepository', stackTrace: stackTrace);
      return [];
    }
  }

  // ========================================
  // HINT SYSTEM
  // ========================================

  @override
  Future<Map<String, dynamic>?> generateHint({
    required List<List<int>> gridState,
    required List<Map<String, dynamic>> availableBlocks,
  }) async {
    try {
      developer.log('Generating hint for current game state', name: 'GameRepository');
      
      // Simple hint generation algorithm
      // In a real implementation, this would be more sophisticated
      
      for (int row = 0; row < gridState.length; row++) {
        for (int col = 0; col < gridState[0].length; col++) {
          if (gridState[row][col] == 0) { // Empty cell
            // Check if any available block can fit here
            for (final blockData in availableBlocks) {
              final blockShape = blockData['shape'] as List<List<int>>;
              
              if (_canBlockFit(gridState, blockShape, row, col)) {
                final hint = {
                  'targetRow': row,
                  'targetCol': col,
                  'blockId': blockData['id'],
                  'confidence': 0.8, // Confidence score
                  'description': 'Try placing this block here',
                  'scorePreview': _calculateScorePreview(gridState, blockShape, row, col),
                };
                
                developer.log('Hint generated at position ($row, $col)', name: 'GameRepository');
                return hint;
              }
            }
          }
        }
      }
      
      developer.log('No hint could be generated', name: 'GameRepository');
      return null;
      
    } catch (e, stackTrace) {
      developer.log('Error generating hint: $e', name: 'GameRepository', stackTrace: stackTrace);
      return null;
    }
  }

  /// Check if a block can fit at the specified position
  bool _canBlockFit(List<List<int>> grid, List<List<int>> blockShape, int row, int col) {
    for (int r = 0; r < blockShape.length; r++) {
      for (int c = 0; c < blockShape[r].length; c++) {
        if (blockShape[r][c] == 1) {
          final gridRow = row + r;
          final gridCol = col + c;
          
          // Check bounds
          if (gridRow < 0 || gridRow >= grid.length ||
              gridCol < 0 || gridCol >= grid[0].length) {
            return false;
          }
          
          // Check if cell is occupied
          if (grid[gridRow][gridCol] != 0) {
            return false;
          }
        }
      }
    }
    return true;
  }

  /// Calculate potential score for placing a block
  int _calculateScorePreview(List<List<int>> grid, List<List<int>> blockShape, int row, int col) {
    // Simplified score calculation
    // In a real implementation, this would calculate potential line clears
    
    int baseScore = 10; // Base score for placing a block
    
    // Bonus for placing near other blocks (clustering)
    int adjacencyBonus = 0;
    for (int r = 0; r < blockShape.length; r++) {
      for (int c = 0; c < blockShape[r].length; c++) {
        if (blockShape[r][c] == 1) {
          final gridRow = row + r;
          final gridCol = col + c;
          
          // Check adjacent cells
          final adjacentPositions = [
            [gridRow - 1, gridCol], [gridRow + 1, gridCol],
            [gridRow, gridCol - 1], [gridRow, gridCol + 1],
          ];
          
          for (final pos in adjacentPositions) {
            if (pos[0] >= 0 && pos[0] < grid.length &&
                pos[1] >= 0 && pos[1] < grid[0].length &&
                grid[pos[0]][pos[1]] != 0) {
              adjacencyBonus += 5;
            }
          }
        }
      }
    }
    
    return baseScore + adjacencyBonus;
  }

  // ========================================
  // DATA MANAGEMENT
  // ========================================

  @override
  Future<bool> clearAllGameData() async {
    try {
      developer.log('Clearing all game data', name: 'GameRepository');
      
      final success = await _localDataSource.clearAllGameData();
      
      if (success) {
        developer.log('All game data cleared successfully', name: 'GameRepository');
      } else {
        developer.log('Failed to clear all game data', name: 'GameRepository');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      developer.log('Error clearing all game data: $e', name: 'GameRepository', stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> exportGameData() async {
    try {
      developer.log('Exporting game data', name: 'GameRepository');
      
      final exportData = await _localDataSource.exportAllData();
      
      // Add export metadata
      exportData['exportType'] = 'game_data';
      exportData['version'] = '1.0';
      
      developer.log('Game data exported successfully', name: 'GameRepository');
      return exportData;
      
    } catch (e, stackTrace) {
      developer.log('Error exporting game data: $e', name: 'GameRepository', stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> importGameData(Map<String, dynamic> gameData) async {
    try {
      developer.log('Importing game data', name: 'GameRepository');
      
      final success = await _localDataSource.importAllData(gameData);
      
      if (success) {
        developer.log('Game data imported successfully', name: 'GameRepository');
      } else {
        developer.log('Failed to import game data', name: 'GameRepository');
      }
      
      return success;
      
    } catch (e, stackTrace) {
      developer.log('Error importing game data: $e', name: 'GameRepository', stackTrace: stackTrace);
      return false;
    }
  }
}