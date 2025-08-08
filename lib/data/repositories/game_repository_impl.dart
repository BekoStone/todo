import 'package:flutter/foundation.dart';
import 'package:puzzle_box/data/datasources/local_storage_datasource.dart';
import 'package:puzzle_box/data/models/block_model.dart';
import 'package:puzzle_box/data/models/game_state_model.dart';
import 'package:puzzle_box/domain/entities/block_entity.dart';
import 'package:puzzle_box/domain/entities/game_session_entity.dart';
import '../../domain/repositories/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  final LocalStorageDataSource _dataSource;
  
  GameRepositoryImpl(this._dataSource);
  
  @override
  Future<GameSession?> loadSavedGame() async {
    try {
      final gameStateModel = _dataSource.loadGameState();
      if (gameStateModel == null) return null;
      
      return _mapGameStateToSession(gameStateModel);
    } catch (e) {
      debugPrint('❌ Failed to load saved game: $e');
      return null;
    }
  }
  
  @override
  Future<bool> saveGame(GameSession gameSession) async {
    try {
      final gameStateModel = _mapSessionToGameState(gameSession);
      return await _dataSource.saveGameState(gameStateModel);
    } catch (e) {
      debugPrint('❌ Failed to save game: $e');
      return false;
    }
  }
  
  @override
  Future<bool> clearSavedGame() async {
    return await _dataSource.clearGameState();
  }
  
  @override
  Future<GameSession> createNewGame() async {
    return GameSession.newGame();
  }
  
  @override
  Future<List<int>> getHighScores() async {
    return _dataSource.loadHighScores();
  }
  
  @override
  Future<bool> saveHighScore(int score) async {
    return await _dataSource.addHighScore(score);
  }
  
  @override
  Future<Map<String, dynamic>> getGameSettings() async {
    return _dataSource.loadSettings();
  }
  
  @override
  Future<bool> saveGameSettings(Map<String, dynamic> settings) async {
    return await _dataSource.saveSettings(settings);
  }
  
  @override
  Future<bool> canClaimDailyReward() async {
    return _dataSource.canClaimDailyReward();
  }
  
  @override
  Future<bool> claimDailyReward() async {
    final now = DateTime.now();
    return await _dataSource.saveLastClaimDate(now);
  }
  
  // Helper methods to convert between domain entities and data models
  GameSession _mapGameStateToSession(GameStateModel model) {
    final blocks = model.activeBlocks
        .map((blockModel) => _mapBlockModelToEntity(blockModel))
        .toList();
    
    return GameSession(
      id: model.metadata['sessionId'] ?? '',
      score: model.score,
      level: model.level,
      linesCleared: model.linesCleared,
      comboCount: model.combo,
      streakCount: model.streak,
      grid: model.grid,
      activeBlocks: blocks,
      startTime: model.metadata['startTime'] != null 
          ? DateTime.tryParse(model.metadata['startTime']) ?? DateTime.now()
          : DateTime.now(),
      lastPlayTime: model.lastPlayed,
      totalPlayTime: model.timePlayed,
      isGameOver: model.isGameOver,
      metadata: model.metadata,
    );
  }
  
  GameStateModel _mapSessionToGameState(GameSession session) {
    final blockModels = session.activeBlocks
        .map((block) => _mapBlockEntityToModel(block))
        .toList();
    
    final metadata = Map<String, dynamic>.from(session.metadata);
    metadata['sessionId'] = session.id;
    metadata['startTime'] = session.startTime.toIso8601String();
    
    return GameStateModel(
      score: session.score,
      level: session.level,
      linesCleared: session.linesCleared,
      combo: session.comboCount,
      streak: session.streakCount,
      grid: session.grid,
      activeBlocks: blockModels,
      lastPlayed: session.lastPlayTime,
      timePlayed: session.totalPlayTime,
      isGameOver: session.isGameOver,
      metadata: metadata,
    );
  }
  
  Block _mapBlockModelToEntity(BlockModel model) {
    return Block(
      id: model.id,
      shape: model.shape,
      position: model.position,
      originalPosition: model.originalPosition,
      isLocked: model.isLocked,
      isActive: model.isActive,
      colorIndex: model.colorIndex,
      createdAt: model.createdAt,
    );
  }
  
  BlockModel _mapBlockEntityToModel(Block entity) {
    return BlockModel(
      id: entity.id,
      shape: entity.shape,
      position: entity.position,
      originalPosition: entity.originalPosition,
      isLocked: entity.isLocked,
      isActive: entity.isActive,
      colorIndex: entity.colorIndex,
      createdAt: entity.createdAt,
    );
  }
}