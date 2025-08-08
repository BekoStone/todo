
import 'package:puzzle_box/domain/entities/game_session_entity.dart';

abstract class GameRepository {
  // Game session management
  Future<GameSession?> loadSavedGame();
  Future<bool> saveGame(GameSession gameSession);
  Future<bool> clearSavedGame();
  Future<GameSession> createNewGame();
  
  // High scores
  Future<List<int>> getHighScores();
  Future<bool> saveHighScore(int score);
  
  // Settings
  Future<Map<String, dynamic>> getGameSettings();
  Future<bool> saveGameSettings(Map<String, dynamic> settings);
  
  // Daily rewards
  Future<bool> canClaimDailyReward();
  Future<bool> claimDailyReward();
}