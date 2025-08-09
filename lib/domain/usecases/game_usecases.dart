import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import '../repositories/game_repository.dart';

/// Game-related business logic operations.
/// Manages game sessions, scoring, validation, and game mechanics.
/// Follows Clean Architecture by containing all game-specific use cases.
class GameUseCases {
  final GameRepository _repository;
  
  GameUseCases(this._repository);

  // ========================================
  // GAME SESSION MANAGEMENT
  // ========================================
  
  /// Load the most recent saved game
  Future<GameSession?> loadSavedGame() async {
    try {
      return await _repository.loadSavedGame();
    } catch (e) {
      debugPrint('Failed to load saved game: $e');
      return null;
    }
  }
  
  /// Save current game state
  Future<bool> saveGame(GameSession gameSession) async {
    try {
      return await _repository.saveGame(gameSession);
    } catch (e) {
      debugPrint('Failed to save game: $e');
      return false;
    }
  }
  
  /// Create a new game session
  Future<GameSession> createNewGame({GameDifficulty? difficulty}) async {
    try {
      return await _repository.createNewGame(difficulty: difficulty);
    } catch (e) {
      debugPrint('Failed to create new game: $e');
      // Return default game session
      return GameSession.create(
        difficulty: difficulty ?? GameDifficulty.normal,
      );
    }
  }
  
  /// Clear saved game data
  Future<bool> clearSavedGame() async {
    try {
      return await _repository.clearSavedGame();
    } catch (e) {
      debugPrint('Failed to clear saved game: $e');
      return false;
    }
  }

  /// Auto-save game session
  Future<bool> autoSaveGame(GameSession gameSession) async {
    try {
      return await _repository.autoSaveGameState(gameSession);
    } catch (e) {
      debugPrint('Failed to auto-save game: $e');
      return false;
    }
  }

  /// Complete a game session
  Future<bool> completeGameSession(GameSession gameSession, Map<String, dynamic> completionData) async {
    try {
      return await _repository.completeGameSession(gameSession.sessionId, completionData);
    } catch (e) {
      debugPrint('Failed to complete game session: $e');
      return false;
    }
  }

  // ========================================
  // GAME LOGIC OPERATIONS
  // ========================================
  
  /// Place a block on the game grid
  GameSession placeBlock(
    GameSession gameSession,
    Block block,
    int gridRow,
    int gridCol,
  ) {
    // Validate placement
    if (!canPlaceBlock(gameSession, block, gridRow, gridCol)) {
      return gameSession;
    }
    
    // Create new grid with placed block
    final newGrid = List<List<int>>.from(
      gameSession.gridState.map((row) => List<int>.from(row)),
    );
    
    // Place block on grid
    for (int r = 0; r < block.shape.length; r++) {
      for (int c = 0; c < block.shape[r].length; c++) {
        if (block.shape[r][c] == 1) {
          final targetRow = gridRow + r;
          final targetCol = gridCol + c;
          if (targetRow >= 0 && targetRow < newGrid.length &&
              targetCol >= 0 && targetCol < newGrid[0].length) {
            newGrid[targetRow][targetCol] = block.colorId;
          }
        }
      }
    }
    
    // Calculate score for placement
    final placementScore = _calculatePlacementScore(block, gameSession.currentLevel);
    
    // Update session statistics
    final updatedStats = gameSession.statistics.copyWith(
      blocksPlaced: gameSession.statistics.blocksPlaced + 1,
      totalMoves: gameSession.statistics.totalMoves + 1,
    );
    
    return gameSession.copyWith(
      gridState: newGrid,
      currentScore: gameSession.currentScore + placementScore,
      statistics: updatedStats,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Check if a block can be placed at the specified position
  bool canPlaceBlock(GameSession gameSession, Block block, int gridRow, int gridCol) {
    final grid = gameSession.gridState;
    
    // Check each cell of the block
    for (int r = 0; r < block.shape.length; r++) {
      for (int c = 0; c < block.shape[r].length; c++) {
        if (block.shape[r][c] == 1) {
          final targetRow = gridRow + r;
          final targetCol = gridCol + c;
          
          // Check bounds
          if (targetRow < 0 || targetRow >= grid.length ||
              targetCol < 0 || targetCol >= grid[0].length) {
            return false;
          }
          
          // Check if cell is already occupied
          if (grid[targetRow][targetCol] != 0) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  /// Check for completed lines and clear them
  (List<int> rowsCleared, List<int> colsCleared, int scoreEarned) checkAndClearLines(GameSession gameSession) {
    final grid = gameSession.gridState;
    final gridSize = grid.length;
    final rowsCleared = <int>[];
    final colsCleared = <int>[];
    
    // Check rows
    for (int row = 0; row < gridSize; row++) {
      if (grid[row].every((cell) => cell != 0)) {
        rowsCleared.add(row);
      }
    }
    
    // Check columns
    for (int col = 0; col < gridSize; col++) {
      bool isComplete = true;
      for (int row = 0; row < gridSize; row++) {
        if (grid[row][col] == 0) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        colsCleared.add(col);
      }
    }
    
    // Calculate score for cleared lines
    final totalLinesCleared = rowsCleared.length + colsCleared.length;
    final scoreEarned = _calculateLineClearScore(totalLinesCleared, gameSession.currentLevel);
    
    return (rowsCleared, colsCleared, scoreEarned);
  }

  /// Clear specified lines from the grid
  GameSession clearLines(GameSession gameSession, List<int> rowsCleared, List<int> colsCleared, int scoreEarned) {
    final newGrid = List<List<int>>.from(
      gameSession.gridState.map((row) => List<int>.from(row)),
    );
    
    // Clear rows
    for (final row in rowsCleared) {
      for (int col = 0; col < newGrid[row].length; col++) {
        newGrid[row][col] = 0;
      }
    }
    
    // Clear columns
    for (final col in colsCleared) {
      for (int row = 0; row < newGrid.length; row++) {
        newGrid[row][col] = 0;
      }
    }
    
    final totalLinesCleared = rowsCleared.length + colsCleared.length;
    final newLevel = _calculateLevel(gameSession.linesCleared + totalLinesCleared);
    
    // Update session statistics
    final updatedStats = gameSession.statistics.copyWith(
      linesCleared: gameSession.statistics.linesCleared + totalLinesCleared,
      totalScore: gameSession.currentScore + scoreEarned,
    );
    
    return gameSession.copyWith(
      gridState: newGrid,
      currentScore: gameSession.currentScore + scoreEarned,
      currentLevel: newLevel,
      linesCleared: gameSession.linesCleared + totalLinesCleared,
      statistics: updatedStats,
      updatedAt: DateTime.now(),
    );
  }

  /// Generate next block set for the game
  List<Block> generateNextBlocks(GameSession gameSession) {
    final random = math.Random();
    final difficulty = gameSession.difficulty;
    final level = gameSession.currentLevel;
    
    // Determine number of blocks based on difficulty
    int blockCount;
    switch (difficulty) {
      case GameDifficulty.easy:
        blockCount = 2;
        break;
      case GameDifficulty.normal:
        blockCount = 3;
        break;
      case GameDifficulty.hard:
        blockCount = 4;
        break;
      case GameDifficulty.expert:
        blockCount = 5;
        break;
    }
    
    final blocks = <Block>[];
    final availableShapes = AppConstants.blockShapes;
    
    for (int i = 0; i < blockCount; i++) {
      final shapeIndex = random.nextInt(availableShapes.length);
      final colorId = random.nextInt(7) + 1; // Colors 1-7
      
      blocks.add(Block(
        id: 'block_${DateTime.now().millisecondsSinceEpoch}_$i',
        shape: availableShapes[shapeIndex],
        colorId: colorId,
        size: _calculateBlockSize(availableShapes[shapeIndex]),
      ));
    }
    
    return blocks;
  }

  /// Check if game is over (no valid moves)
  bool isGameOver(GameSession gameSession, List<Block> availableBlocks) {
    for (final block in availableBlocks) {
      if (_hasValidPlacement(gameSession, block)) {
        return false;
      }
    }
    return true;
  }

  /// Get hint for best move
  Map<String, dynamic>? getGameHint(GameSession gameSession, List<Block> availableBlocks) {
    for (final block in availableBlocks) {
      final bestPosition = _findBestPlacement(gameSession, block);
      if (bestPosition != null) {
        return {
          'blockId': block.id,
          'row': bestPosition.row,
          'col': bestPosition.col,
          'reason': 'Best scoring position',
        };
      }
    }
    return null;
  }

  // ========================================
  // SCORING SYSTEM
  // ========================================

  /// Calculate score for placing a block
  int _calculatePlacementScore(Block block, int level) {
    final blockSize = block.shape.expand((row) => row).where((cell) => cell == 1).length;
    return blockSize * 10 * level;
  }

  /// Calculate score for clearing lines
  int _calculateLineClearScore(int linesCleared, int level) {
    if (linesCleared == 0) return 0;
    
    final baseScore = [0, 100, 300, 500, 800, 1200][math.min(linesCleared, 5)];
    return baseScore * level;
  }

  /// Calculate level based on lines cleared
  int _calculateLevel(int totalLinesCleared) {
    return math.max(1, (totalLinesCleared ~/ 10) + 1);
  }

  /// Calculate block size
  int _calculateBlockSize(List<List<int>> shape) {
    return shape.expand((row) => row).where((cell) => cell == 1).length;
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Check if block has any valid placement
  bool _hasValidPlacement(GameSession gameSession, Block block) {
    final gridSize = gameSession.gridState.length;
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (canPlaceBlock(gameSession, block, row, col)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Find best placement for a block
  ({int row, int col})? _findBestPlacement(GameSession gameSession, Block block) {
    final gridSize = gameSession.gridState.length;
    int bestScore = -1;
    ({int row, int col})? bestPosition;
    
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (canPlaceBlock(gameSession, block, row, col)) {
          final score = _evaluatePlacement(gameSession, block, row, col);
          if (score > bestScore) {
            bestScore = score;
            bestPosition = (row: row, col: col);
          }
        }
      }
    }
    
    return bestPosition;
  }

  /// Evaluate placement score for AI hints
  int _evaluatePlacement(GameSession gameSession, Block block, int row, int col) {
    // Simple heuristic: prefer positions that complete lines
    final tempSession = placeBlock(gameSession, block, row, col);
    final (rowsCleared, colsCleared, _) = checkAndClearLines(tempSession);
    
    // Score based on potential line clears
    return (rowsCleared.length + colsCleared.length) * 100;
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================

  /// Get game statistics
  Future<Map<String, dynamic>> getGameStatistics() async {
    try {
      return await _repository.getGameStatistics();
    } catch (e) {
      debugPrint('Failed to get game statistics: $e');
      return {};
    }
  }

  /// Record game analytics event
  Future<bool> recordAnalyticsEvent(String eventName, Map<String, dynamic> data) async {
    try {
      return await _repository.recordAnalyticsEvent(eventName, data);
    } catch (e) {
      debugPrint('Failed to record analytics event: $e');
      return false;
    }
  }

  /// Get high scores
  Future<List<Map<String, dynamic>>> getHighScores({int limit = 10}) async {
    try {
      return await _repository.getHighScores(limit: limit);
    } catch (e) {
      debugPrint('Failed to get high scores: $e');
      return [];
    }
  }

  /// Check if score is a high score
  Future<bool> isHighScore(int score) async {
    try {
      return await _repository.isHighScore(score);
    } catch (e) {
      debugPrint('Failed to check if high score: $e');
      return false;
    }
  }

  /// Save final score
  Future<bool> saveFinalScore(String sessionId, int finalScore, Map<String, dynamic>? completionData) async {
    try {
      return await _repository.saveFinalScore(
        sessionId: sessionId,
        finalScore: finalScore,
        completionData: completionData,
      );
    } catch (e) {
      debugPrint('Failed to save final score: $e');
      return false;
    }
  }
}