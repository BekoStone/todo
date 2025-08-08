import 'package:flame/components.dart' as flame;
import 'package:flutter/foundation.dart';
import 'package:puzzle_box/core/constants/app_constants.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import '../repositories/game_repository.dart';
import '../../core/constants/game_constants.dart';

class GameUseCases {
  final GameRepository _repository;
  
  GameUseCases(this._repository);
  
  // Game session management
  Future<GameSession?> loadSavedGame() async {
    try {
      return await _repository.loadSavedGame();
    } catch (e) {
      debugPrint('Failed to load saved game: $e');
      return null;
    }
  }
  
  Future<bool> saveGame(GameSession gameSession) async {
    try {
      return await _repository.saveGame(gameSession);
    } catch (e) {
      debugPrint('Failed to save game: $e');
      return false;
    }
  }
  
  Future<GameSession> createNewGame({required GameDifficulty difficulty}) async {
    return await _repository.createNewGame();
  }
  
  Future<bool> clearSavedGame() async {
    return await _repository.clearSavedGame();
  }
  
  // Game logic operations
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
    final newGrid = List<List<bool>>.from(
      gameSession.grid.map((row) => List<bool>.from(row))
    );
    
    // Mark cells as occupied
    final occupiedCells = block.occupiedCells;
    for (final cell in occupiedCells) {
      final gridR = gridRow + cell.y.toInt();
      final gridC = gridCol + cell.x.toInt();
      if (gridR >= 0 && gridR < 8 && gridC >= 0 && gridC < 8) {
        newGrid[gridR][gridC] = true;
      }
    }
    
    // Remove placed block from active blocks
    final newActiveBlocks = List<Block>.from(gameSession.activeBlocks);
    newActiveBlocks.remove(block);
    
    // Calculate score for placing block
    final blockScore = _calculateBlockScore(block, gameSession.level);
    
    return gameSession.copyWith(
      grid: newGrid,
      activeBlocks: newActiveBlocks,
      score: gameSession.score + blockScore,
      lastPlayTime: DateTime.now(),
    );
  }
  
  bool canPlaceBlock(GameSession gameSession, Block block, int gridRow, int gridCol) {
    final occupiedCells = block.occupiedCells;
    
    for (final cell in occupiedCells) {
      final gridR = gridRow + cell.y.toInt();
      final gridC = gridCol + cell.x.toInt();
      
      // Check boundaries
      if (gridR < 0 || gridR >= 8 || gridC < 0 || gridC >= 8) {
        return false;
      }
      
      // Check if cell is already occupied
      if (gameSession.grid[gridR][gridC]) {
        return false;
      }
    }
    
    return true;
  }
  
  GameSession clearCompletedLines(GameSession gameSession) {
    final grid = gameSession.grid;
    int linesCleared = 0;
    int columnsCleared = 0;
    final newGrid = List<List<bool>>.from(
      grid.map((row) => List<bool>.from(row))
    );
    
    // Check for completed rows
    final completedRows = <int>[];
    for (int row = 0; row < 8; row++) {
      if (grid[row].every((cell) => cell)) {
        completedRows.add(row);
      }
    }
    
    // Check for completed columns
    final completedCols = <int>[];
    for (int col = 0; col < 8; col++) {
      bool isComplete = true;
      for (int row = 0; row < 8; row++) {
        if (!grid[row][col]) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        completedCols.add(col);
      }
    }
    
    // Clear completed lines
    for (final row in completedRows) {
      for (int col = 0; col < 8; col++) {
        newGrid[row][col] = false;
      }
      linesCleared++;
    }
    
    for (final col in completedCols) {
      for (int row = 0; row < 8; row++) {
        newGrid[row][col] = false;
      }
      columnsCleared++;
    }
    
    final totalLinesCleared = linesCleared + columnsCleared;
    
    if (totalLinesCleared == 0) {
      // Reset combo if no lines cleared
      return gameSession.copyWith(comboCount: 0);
    }
    
    // Calculate score for cleared lines
    final lineScore = _calculateLineScore(
      linesCleared,
      columnsCleared,
      gameSession.comboCount + 1,
      gameSession.level,
    );
    
    // Check for perfect clear
    final isPerfectClear = _isPerfectClear(newGrid);
    final perfectClearBonus = isPerfectClear ? GameConstants.baseScores['perfectClear']! : 0;
    
    // Update level based on lines cleared
    final newLevel = _calculateLevel(gameSession.linesCleared + totalLinesCleared);
    
    return gameSession.copyWith(
      grid: newGrid,
      score: gameSession.score + lineScore + perfectClearBonus,
      linesCleared: gameSession.linesCleared + totalLinesCleared,
      comboCount: gameSession.comboCount + 1,
      streakCount: gameSession.streakCount + 1,
      level: newLevel,
    );
  }
  
  bool isGameOver(GameSession gameSession) {
    // Game is over if no active blocks can be placed
    for (final block in gameSession.activeBlocks) {
      for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
          if (canPlaceBlock(gameSession, block, row, col)) {
            return false; // Found at least one valid placement
          }
        }
      }
    }
    return true; // No valid placements found
  }
  List<Block> generateInitialBlocks({int count = 3}) {
    final newBlocks = <Block>[];
    for (int i = 0; i < count; i++) {
      final block = BlockFactory.createRandomBlock(flame.Vector2.zero());
      newBlocks.add(block);
    }
    return newBlocks;
  }
  GameSession generateNewBlocks(GameSession gameSession, {int count = 3}) {
    final newBlocks = <Block>[];
    
    for (int i = 0; i < count; i++) {
      final block = BlockFactory.createRandomBlock(flame.Vector2.zero());
      newBlocks.add(block);
    }
    
    return gameSession.copyWith(activeBlocks: newBlocks);
  }
  
  List<flame.Vector2> getValidPlacements(GameSession gameSession, Block block) {
    final validPlacements = <flame.Vector2>[];
    
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if (canPlaceBlock(gameSession, block, row, col)) {
          validPlacements.add(flame.Vector2(col.toDouble(), row.toDouble()));
        }
      }
    }
    
    return validPlacements;
  }
  
  flame.Vector2? getBestPlacement(GameSession gameSession, Block block) {
    final validPlacements = getValidPlacements(gameSession, block);
    if (validPlacements.isEmpty) return null;
    
    // Simple heuristic: prefer positions that would complete lines
    flame.Vector2? bestPlacement;
    int bestScore = -1;
    
    for (final placement in validPlacements) {
      final score = _evaluatePlacement(gameSession, block, placement);
      if (score > bestScore) {
        bestScore = score;
        bestPlacement = placement;
      }
    }
    
    return bestPlacement;
  }
  
  // High scores
  Future<List<int>> getHighScores() async {
    return await _repository.getHighScores();
  }
  
  Future<bool> saveHighScore(int score) async {
    return await _repository.saveHighScore(score);
  }
  
  // Settings
  Future<Map<String, dynamic>> getGameSettings() async {
    return await _repository.getGameSettings();
  }
  
  Future<bool> saveGameSettings(Map<String, dynamic> settings) async {
    return await _repository.saveGameSettings(settings);
  }
  
  // Daily rewards
  Future<bool> canClaimDailyReward() async {
    return await _repository.canClaimDailyReward();
  }
  
  Future<bool> claimDailyReward() async {
    return await _repository.claimDailyReward();
  }
  
  // Private helper methods
  int _calculateBlockScore(Block block, int level) {
    final baseScore = GameConstants.baseScores['blockPlace']! * block.cellCount;
    return (baseScore * level).round();
  }
  
  int _calculateLineScore(int linesCleared, int columnsCleared, int combo, int level) {
    int baseScore = 0;
    
    if (linesCleared == 1) {
      baseScore = GameConstants.baseScores['singleLine']!;
    } else if (linesCleared == 2) {
      baseScore = GameConstants.baseScores['doubleLine']!;
    } else if (linesCleared >= 3) {
      baseScore = GameConstants.baseScores['tripleLine']!;
    }
    
    // Add column clear bonus
    baseScore += columnsCleared * GameConstants.baseScores['singleLine']!;
    
    // Apply combo multiplier
    final comboIndex = combo.clamp(0, GameConstants.comboMultipliers.length - 1);
    final multiplier = GameConstants.comboMultipliers[comboIndex];
    
    return (baseScore * multiplier * level).round();
  }
  
  int _calculateLevel(int totalLinesCleared) {
    return (totalLinesCleared / GameConstants.linesPerLevel).floor() + 1;
  }
  
  bool _isPerfectClear(List<List<bool>> grid) {
    for (final row in grid) {
      for (final cell in row) {
        if (cell) return false;
      }
    }
    return true;
  }
  
  int _evaluatePlacement(GameSession gameSession, Block block, flame.Vector2 placement) {
    // Simple evaluation: count how many lines would be completed
    int score = 0;
    
    // Simulate placing the block
    final tempGrid = List<List<bool>>.from(
      gameSession.grid.map((row) => List<bool>.from(row))
    );
    
    final occupiedCells = block.occupiedCells;
    for (final cell in occupiedCells) {
      final gridR = placement.y.toInt() + cell.y.toInt();
      final gridC = placement.x.toInt() + cell.x.toInt();
      if (gridR >= 0 && gridR < 8 && gridC >= 0 && gridC < 8) {
        tempGrid[gridR][gridC] = true;
      }
    }
    
    // Count completed lines
    for (int row = 0; row < 8; row++) {
      if (tempGrid[row].every((cell) => cell)) {
        score += 100; // Row completion bonus
      }
    }
    
    for (int col = 0; col < 8; col++) {
      bool isComplete = true;
      for (int row = 0; row < 8; row++) {
        if (!tempGrid[row][col]) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        score += 100; // Column completion bonus
      }
    }
    
    // Prefer positions closer to existing blocks
    int adjacentBlocks = 0;
    for (final cell in occupiedCells) {
      final gridR = placement.y.toInt() + cell.y.toInt();
      final gridC = placement.x.toInt() + cell.x.toInt();
      
      // Check adjacent cells
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final r = gridR + dr;
          final c = gridC + dc;
          if (r >= 0 && r < 8 && c >= 0 && c < 8 && gameSession.grid[r][c]) {
            adjacentBlocks++;
          }
        }
      }
    }
    
    score += adjacentBlocks * 5; // Adjacency bonus
    
    return score;
  }
}