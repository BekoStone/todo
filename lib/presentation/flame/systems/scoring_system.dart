import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:puzzle_box/presentation/cubit/game_cubit_dart.dart';
import 'package:puzzle_box/presentation/cubit/player_cubit_dart.dart';

import '../../../core/constants/game_constants.dart';
import '../../../core/utils/performance_utils.dart';
import '../../../core/services/audio_service.dart';
import '../../../injection_container.dart';
import '../components/game_world.dart';
import '../components/particle_component.dart';

/// Scoring system for managing game scoring, combos, and achievements.
/// Handles score calculation, level progression, and performance tracking.
/// Follows Clean Architecture by coordinating between presentation and domain layers.
class ScoringSystem extends Component with HasGameRef {
  // Dependencies
  final GameWorld gameWorld;
  final GameCubit gameCubit;
  final PlayerCubit playerCubit;
  late final AudioService _audioService;
  
  // Scoring state
  int _currentScore = 0;
  int _sessionScore = 0;
  int _currentLevel = 1;
  int _linesCleared = 0;
  int _blocksPlaced = 0;
  int _comboCount = 0;
  int _maxCombo = 0;
  
  // Streak tracking
  int _currentStreak = 0;
  int _maxStreak = 0;
  bool _isPerfectGame = true;
  
  // Time tracking
  DateTime? _gameStartTime;
  Duration _gameTime = Duration.zero;
  
  // Scoring multipliers and bonuses
  double _currentMultiplier = 1.0;
  final Map<String, int> _scoringEvents = {};
  final List<int> _recentScores = [];
  
  // Performance tracking
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  
  // Achievement tracking
  final Set<String> _sessionAchievements = {};
  final Map<String, int> _statisticCounters = {};

  ScoringSystem({
    required this.gameWorld,
    required this.gameCubit,
    required this.playerCubit,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    _audioService = getIt<AudioService>();
    _initializeScoring();
    
    debugPrint('📊 ScoringSystem loaded');
  }

  /// Initialize scoring system
  void _initializeScoring() {
    _gameStartTime = DateTime.now();
    _resetSessionStats();
    _initializeStatisticCounters();
    
    debugPrint('🎯 Scoring system initialized');
  }

  /// Reset all session statistics
  void _resetSessionStats() {
    _currentScore = 0;
    _sessionScore = 0;
    _currentLevel = 1;
    _linesCleared = 0;
    _blocksPlaced = 0;
    _comboCount = 0;
    _maxCombo = 0;
    _currentStreak = 0;
    _maxStreak = 0;
    _isPerfectGame = true;
    _currentMultiplier = 1.0;
    _gameTime = Duration.zero;
    
    _scoringEvents.clear();
    _recentScores.clear();
    _sessionAchievements.clear();
  }

  /// Initialize statistic counters
  void _initializeStatisticCounters() {
    _statisticCounters.clear();
    _statisticCounters['blocks_placed'] = 0;
    _statisticCounters['lines_cleared'] = 0;
    _statisticCounters['perfect_clears'] = 0;
    _statisticCounters['power_ups_used'] = 0;
    _statisticCounters['combos_achieved'] = 0;
    _statisticCounters['time_played'] = 0;
  }

  /// Award points for placing a block
  void awardBlockPlacement(Block block, Vector2 gridPosition) {
    _performanceMonitor.startTracking('score_block_placement');
    
    final baseScore = _calculateBlockPlacementScore(block);
    final multipliedScore = (baseScore * _currentMultiplier).round();
    
    _addScore(multipliedScore, 'block_placement');
    _blocksPlaced++;
    _statisticCounters['blocks_placed'] = _statisticCounters['blocks_placed']! + 1;
    
    // Check for placement achievements
    _checkPlacementAchievements(block, gridPosition);
    
    // Update level if needed
    _updateLevel();
    
    // Create score popup effect
    _createScorePopup(gridPosition, multipliedScore);
    
    // Audio feedback
    _audioService.playSound('score_block');
    
    _performanceMonitor.stopTracking('score_block_placement');
    
    debugPrint('🎯 Block placement score: $multipliedScore (base: $baseScore, multiplier: $_currentMultiplier)');
  }

  /// Award points for clearing lines
  void awardLineClear(List<int> rows, List<int> cols, int totalCells) {
    _performanceMonitor.startTracking('score_line_clear');
    
    final linesCleared = rows.length + cols.length;
    if (linesCleared == 0) {
      _resetCombo();
      _performanceMonitor.stopTracking('score_line_clear');
      return;
    }
    
    // Calculate base score
    final baseScore = _calculateLineClearScore(linesCleared, totalCells);
    
    // Apply combo multiplier
    _comboCount++;
    final comboMultiplier = _calculateComboMultiplier(_comboCount);
    
    // Apply streak bonus
    _currentStreak++;
    final streakBonus = _calculateStreakBonus(_currentStreak);
    
    // Calculate final score
    final finalScore = ((baseScore * comboMultiplier).round() + streakBonus);
    
    _addScore(finalScore, 'line_clear');
    _linesCleared += linesCleared;
    _statisticCounters['lines_cleared'] = _statisticCounters['lines_cleared']! + linesCleared;
    _statisticCounters['combos_achieved'] = _statisticCounters['combos_achieved']! + 1;
    
    // Update tracking
    _maxCombo = math.max(_maxCombo, _comboCount);
    _maxStreak = math.max(_maxStreak, _currentStreak);
    
    // Check for special line clear achievements
    _checkLineClearAchievements(rows, cols, totalCells);
    
    // Update level
    _updateLevel();
    
    // Create effects
    _createLineClearEffects(rows, cols, finalScore);
    
    // Audio feedback
    _playLineClearAudio(linesCleared, _comboCount);
    
    _performanceMonitor.stopTracking('score_line_clear');
    
    debugPrint('💥 Line clear score: $finalScore (base: $baseScore, combo: ${_comboCount}x, streak: $_currentStreak)');
  }

  /// Award points for perfect clear (clearing entire board)
  void awardPerfectClear() {
    _performanceMonitor.startTracking('score_perfect_clear');
    
    final baseScore = GameConstants.perfectClearBaseScore;
    final levelBonus = _currentLevel * GameConstants.perfectClearLevelMultiplier;
    final timeBonus = _calculateTimePerfectBonus();
    
    final totalScore = baseScore + levelBonus + timeBonus;
    
    _addScore(totalScore, 'perfect_clear');
    _statisticCounters['perfect_clears'] = _statisticCounters['perfect_clears']! + 1;
    
    // Perfect clear maintains streak but resets combo
    _comboCount = 0;
    
    // Achievement tracking
    _checkPerfectClearAchievements();
    
    // Create spectacular effect
    _createPerfectClearEffect(totalScore);
    
    // Audio feedback
    _audioService.playSound('perfect_clear');
    
    _performanceMonitor.stopTracking('score_perfect_clear');
    
    debugPrint('🌟 Perfect clear score: $totalScore');
  }

  /// Award points for power-up usage
  void awardPowerUpUsage(String powerUpType, int effectiveness) {
    final baseScore = GameConstants.powerUpBaseScore;
    final effectivenessBonus = effectiveness * GameConstants.powerUpEffectivenessMultiplier;
    
    final totalScore = baseScore + effectivenessBonus;
    
    _addScore(totalScore, 'power_up');
    _statisticCounters['power_ups_used'] = _statisticCounters['power_ups_used']! + 1;
    
    // Power-up usage doesn't break combo but doesn't extend it either
    
    debugPrint('⚡ Power-up score: $totalScore ($powerUpType, effectiveness: $effectiveness)');
  }

  /// Award time-based bonus
  void awardTimeBonus() {
    if (_gameStartTime == null) return;
    
    final gameTime = DateTime.now().difference(_gameStartTime!);
    final timeBonus = _calculateTimeBonus(gameTime);
    
    if (timeBonus > 0) {
      _addScore(timeBonus, 'time_bonus');
      debugPrint('⏱️ Time bonus: $timeBonus');
    }
  }

  /// Award survival bonus (staying alive with high grid fill)
  void awardSurvivalBonus(double gridFillPercentage) {
    if (gridFillPercentage < GameConstants.survivalBonusThreshold) return;
    
    final survivalScore = _calculateSurvivalBonus(gridFillPercentage);
    
    if (survivalScore > 0) {
      _addScore(survivalScore, 'survival_bonus');
      debugPrint('🛡️ Survival bonus: $survivalScore (fill: ${gridFillPercentage.toStringAsFixed(1)}%)');
    }
  }

  /// Reset combo counter
  void _resetCombo() {
    if (_comboCount > 0) {
      debugPrint('💔 Combo reset from $_comboCount');
      _comboCount = 0;
    }
  }

  /// Reset streak counter
  void _resetStreak() {
    if (_currentStreak > 0) {
      debugPrint('⚡ Streak ended at $_currentStreak');
      _currentStreak = 0;
    }
    _isPerfectGame = false;
  }

  /// Calculate score for block placement
  int _calculateBlockPlacementScore(Block block) {
    final cellCount = block.shape.expand((row) => row).where((cell) => cell == 1).length;
    final baseScore = cellCount * GameConstants.blockPlacementScore;
    
    // Bonus for complex shapes
    final shapeComplexity = _calculateShapeComplexity(block.shape);
    final complexityBonus = (shapeComplexity * GameConstants.shapeComplexityMultiplier).round();
    
    return baseScore + complexityBonus;
  }

  /// Calculate score for line clearing
  int _calculateLineClearScore(int linesCleared, int totalCells) {
    int baseScore = 0;
    
    // Score based on lines cleared
    switch (linesCleared) {
      case 1:
        baseScore = GameConstants.singleLineScore;
        break;
      case 2:
        baseScore = GameConstants.doubleLineScore;
        break;
      case 3:
        baseScore = GameConstants.tripleLineScore;
        break;
      case 4:
        baseScore = GameConstants.quadLineScore;
        break;
      default:
        baseScore = GameConstants.quadLineScore + 
                   (linesCleared - 4) * GameConstants.extraLineScore;
    }
    
    // Bonus for total cells cleared
    final cellBonus = totalCells * GameConstants.cellClearScore;
    
    return baseScore + cellBonus;
  }

  /// Calculate combo multiplier
  double _calculateComboMultiplier(int comboCount) {
    if (comboCount <= 1) return 1.0;
    
    // Progressive multiplier with diminishing returns
    return 1.0 + (comboCount - 1) * 0.5 * math.pow(0.9, comboCount - 2);
  }

  /// Calculate streak bonus
  int _calculateStreakBonus(int streakCount) {
    if (streakCount <= 1) return 0;
    
    // Exponential streak bonus
    return (math.pow(streakCount, 1.5) * GameConstants.streakBonusMultiplier).round();
  }

  /// Calculate time-based perfect clear bonus
  int _calculateTimePerfectBonus() {
    if (_gameStartTime == null) return 0;
    
    final gameTime = DateTime.now().difference(_gameStartTime!);
    final timeInMinutes = gameTime.inMinutes;
    
    // Bonus decreases over time
    if (timeInMinutes < 1) return 1000;
    if (timeInMinutes < 3) return 500;
    if (timeInMinutes < 5) return 250;
    
    return 100;
  }

  /// Calculate time bonus
  int _calculateTimeBonus(Duration gameTime) {
    final minutes = gameTime.inMinutes;
    
    // Award time bonus every minute, decreasing over time
    if (minutes < 5) return minutes * 100;
    if (minutes < 10) return 500 + (minutes - 5) * 50;
    
    return 750 + (minutes - 10) * 25;
  }

  /// Calculate survival bonus
  int _calculateSurvivalBonus(double gridFillPercentage) {
    final dangerLevel = (gridFillPercentage - GameConstants.survivalBonusThreshold) / 
                       (100.0 - GameConstants.survivalBonusThreshold);
    
    return (dangerLevel * dangerLevel * GameConstants.maxSurvivalBonus).round();
  }

  /// Calculate shape complexity for bonus scoring
  double _calculateShapeComplexity(List<List<int>> shape) {
    int totalCells = 0;
    int edges = 0;
    
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          totalCells++;
          
          // Count edges (adjacent empty cells or boundaries)
          final neighbors = [
            [-1, 0], [1, 0], [0, -1], [0, 1] // Up, Down, Left, Right
          ];
          
          for (final neighbor in neighbors) {
            final newRow = row + neighbor[0];
            final newCol = col + neighbor[1];
            
            if (newRow < 0 || newRow >= shape.length ||
                newCol < 0 || newCol >= shape[0].length ||
                shape[newRow][newCol] == 0) {
              edges++;
            }
          }
        }
      }
    }
    
    // Complexity is ratio of perimeter to area
    return totalCells > 0 ? edges / totalCells : 0.0;
  }

  /// Add score to current total
  void _addScore(int points, String source) {
    _currentScore += points;
    _sessionScore += points;
    _recentScores.add(points);
    
    // Keep only recent scores for trend analysis
    if (_recentScores.length > 10) {
      _recentScores.removeAt(0);
    }
    
    // Track scoring events
    _scoringEvents[source] = (_scoringEvents[source] ?? 0) + points;
    
    // Update player stats
    _updatePlayerStats();
    
    debugPrint('💰 +$points points from $source (Total: $_currentScore)');
  }

  /// Update current level based on score or lines cleared
  void _updateLevel() {
    final newLevel = (_linesCleared ~/ GameConstants.linesPerLevel) + 1;
    
    if (newLevel > _currentLevel) {
      _currentLevel = newLevel;
      _onLevelUp();
    }
  }

  /// Handle level up event
  void _onLevelUp() {
    // Increase multiplier slightly
    _currentMultiplier += 0.1;
    
    // Award level up bonus
    final levelBonus = _currentLevel * GameConstants.levelUpBonus;
    _addScore(levelBonus, 'level_up');
    
    // Audio feedback
    _audioService.playSound('level_up');
    
    // Create effect
    _createLevelUpEffect();
    
    // Achievement check
    _checkLevelAchievements();
    
    debugPrint('🆙 Level up! Now level $_currentLevel (bonus: $levelBonus)');
  }

  /// Update player statistics
  void _updatePlayerStats() {
    _gameTime = _gameStartTime != null 
        ? DateTime.now().difference(_gameStartTime!)
        : Duration.zero;
    
    _statisticCounters['time_played'] = _gameTime.inSeconds;
    
    final stats = PlayerStats(
      id: 'current_session',
      currentScore: _currentScore,
      highScore: math.max(_currentScore, 0), // Would be loaded from saved data
      totalGamesPlayed: 1,
      totalScore: _sessionScore,
      averageScore: _sessionScore.toDouble(),
      bestCombo: _maxCombo,
      totalLinesCleared: _linesCleared,
      totalBlocksPlaced: _blocksPlaced,
      totalPlayTime: _gameTime,
      achievementsUnlocked: _sessionAchievements.toList(),
      level: _currentLevel,
      experience: _currentScore,
      lastPlayed: DateTime.now(),
    );
    
    playerCubit.updateStats(stats);
  }

  /// Check for placement-related achievements
  void _checkPlacementAchievements(Block block, Vector2 gridPosition) {
    // Check for corner placement
    final gridSize = gameWorld.gridComponent.gridSize;
    final isCorner = (gridPosition.x == 0 || gridPosition.x == gridSize - 1) &&
                     (gridPosition.y == 0 || gridPosition.y == gridSize - 1);
    
    if (isCorner && !_sessionAchievements.contains('corner_master')) {
      _unlockAchievement('corner_master', 'Corner Master - Place block in corner');
    }
    
    // Check for perfect placement (block fits exactly in empty space)
    if (_isPerfectFit(block, gridPosition) && !_sessionAchievements.contains('perfect_fit')) {
      _unlockAchievement('perfect_fit', 'Perfect Fit - Block fits exactly');
    }
  }

  /// Check for line clear achievements
  void _checkLineClearAchievements(List<int> rows, List<int> cols, int totalCells) {
    final linesCleared = rows.length + cols.length;
    
    // Quad line clear
    if (linesCleared >= 4 && !_sessionAchievements.contains('quad_clear')) {
      _unlockAchievement('quad_clear', 'Quad Clear - Clear 4 lines at once');
    }
    
    // Cross clear (both rows and columns)
    if (rows.isNotEmpty && cols.isNotEmpty && !_sessionAchievements.contains('cross_clear')) {
      _unlockAchievement('cross_clear', 'Cross Clear - Clear rows and columns together');
    }
    
    // Combo master
    if (_comboCount >= 5 && !_sessionAchievements.contains('combo_master')) {
      _unlockAchievement('combo_master', 'Combo Master - Achieve 5x combo');
    }
  }

  /// Check for perfect clear achievements
  void _checkPerfectClearAchievements() {
    if (!_sessionAchievements.contains('board_cleaner')) {
      _unlockAchievement('board_cleaner', 'Board Cleaner - Clear entire board');
    }
    
    if (_currentStreak >= 3 && !_sessionAchievements.contains('perfect_streak')) {
      _unlockAchievement('perfect_streak', 'Perfect Streak - 3 perfect clears in a row');
    }
  }

  /// Check for level-based achievements
  void _checkLevelAchievements() {
    if (_currentLevel >= 5 && !_sessionAchievements.contains('level_5')) {
      _unlockAchievement('level_5', 'Level 5 Reached');
    }
    
    if (_currentLevel >= 10 && !_sessionAchievements.contains('level_10')) {
      _unlockAchievement('level_10', 'Level 10 Reached');
    }
  }

  /// Check if a block placement is a perfect fit
  bool _isPerfectFit(Block block, Vector2 gridPosition) {
    // This would check if the block fills an exact empty space
    // Implementation would analyze surrounding occupied cells
    return false; // Simplified for now
  }

  /// Unlock an achievement
  void _unlockAchievement(String achievementId, String description) {
    _sessionAchievements.add(achievementId);
    
    // Create achievement effect
    _createAchievementEffect(description);
    
    // Audio feedback
    _audioService.playSound('achievement_unlock');
    
    debugPrint('🏆 Achievement unlocked: $description');
  }

  /// Create score popup effect
  void _createScorePopup(Vector2 gridPosition, int score) {
    final worldPosition = gameWorld.gridComponent.position + 
                         Vector2(gridPosition.x * gameWorld.cellSize, 
                                gridPosition.y * gameWorld.cellSize);
    
    final particle = ParticleComponent.scorePopup(
      position: worldPosition,
      score: score,
    );
    
    gameWorld.add(particle);
  }

  /// Create line clear effects
  void _createLineClearEffects(List<int> rows, List<int> cols, int score) {
    // Create effects for each cleared line
    for (final row in rows) {
      final worldPosition = gameWorld.gridComponent.position + 
                           Vector2(0, row * gameWorld.cellSize);
      
      final particle = ParticleComponent.lineClear(
        position: worldPosition,
        cellSize: gameWorld.cellSize,
      );
      
      gameWorld.add(particle);
    }
    
    for (final col in cols) {
      final worldPosition = gameWorld.gridComponent.position + 
                           Vector2(col * gameWorld.cellSize, 0);
      
      final particle = ParticleComponent.lineClear(
        position: worldPosition,
        cellSize: gameWorld.cellSize,
      );
      
      gameWorld.add(particle);
    }
    
    // Combo effect if applicable
    if (_comboCount > 1) {
      final centerPosition = gameWorld.gridComponent.position + 
                            gameWorld.gridComponent.size / 2;
      
      final comboParticle = ParticleComponent.combo(
        position: centerPosition,
        comboLevel: _comboCount,
      );
      
      gameWorld.add(comboParticle);
    }
  }

  /// Create perfect clear effect
  void _createPerfectClearEffect(int score) {
    final centerPosition = gameWorld.gridComponent.position + 
                          gameWorld.gridComponent.size / 2;
    
    final particle = ParticleComponent.celebration(
      position: centerPosition,
    );
    
    gameWorld.add(particle);
  }

  /// Create level up effect
  void _createLevelUpEffect() {
    final centerPosition = Vector2(gameRef.size.x / 2, gameRef.size.y / 4);
    
    final particle = ParticleComponent.achievementUnlock(
      position: centerPosition,
    );
    
    gameWorld.add(particle);
  }

  /// Create achievement effect
  void _createAchievementEffect(String description) {
    final centerPosition = Vector2(gameRef.size.x / 2, gameRef.size.y / 3);
    
    final particle = ParticleComponent.achievementUnlock(
      position: centerPosition,
    );
    
    gameWorld.add(particle);
  }

  /// Play audio for line clearing
  void _playLineClearAudio(int linesCleared, int comboCount) {
    if (comboCount > 1) {
      _audioService.playSound('combo_${math.min(comboCount, 5)}');
    } else {
      switch (linesCleared) {
        case 1:
          _audioService.playSound('line_clear_1');
          break;
        case 2:
          _audioService.playSound('line_clear_2');
          break;
        case 3:
          _audioService.playSound('line_clear_3');
          break;
        case 4:
          _audioService.playSound('line_clear_4');
          break;
        default:
          _audioService.playSound('line_clear_mega');
      }
    }
  }

  /// Get current game statistics
  Map<String, dynamic> getGameStatistics() {
    return {
      'score': _currentScore,
      'sessionScore': _sessionScore,
      'level': _currentLevel,
      'linesCleared': _linesCleared,
      'blocksPlaced': _blocksPlaced,
      'currentCombo': _comboCount,
      'maxCombo': _maxCombo,
      'currentStreak': _currentStreak,
      'maxStreak': _maxStreak,
      'multiplier': _currentMultiplier,
      'gameTime': _gameTime.inSeconds,
      'isPerfectGame': _isPerfectGame,
      'achievements': _sessionAchievements.toList(),
      'scoringEvents': Map<String, int>.from(_scoringEvents),
      'statistics': Map<String, int>.from(_statisticCounters),
    };
  }

  /// Get performance analytics
  Map<String, dynamic> getPerformanceAnalytics() {
    final avgRecentScore = _recentScores.isNotEmpty 
        ? _recentScores.reduce((a, b) => a + b) / _recentScores.length
        : 0.0;
    
    final scorePerMinute = _gameTime.inMinutes > 0 
        ? _currentScore / _gameTime.inMinutes
        : 0.0;
    
    return {
      'averageRecentScore': avgRecentScore,
      'scorePerMinute': scorePerMinute,
      'blocksPerMinute': _gameTime.inMinutes > 0 ? _blocksPlaced / _gameTime.inMinutes : 0.0,
      'linesPerMinute': _gameTime.inMinutes > 0 ? _linesCleared / _gameTime.inMinutes : 0.0,
      'efficiency': _blocksPlaced > 0 ? _linesCleared / _blocksPlaced : 0.0,
      'consistencyScore': _calculateConsistencyScore(),
    };
  }

  /// Calculate consistency score based on recent performance
  double _calculateConsistencyScore() {
    if (_recentScores.length < 3) return 0.0;
    
    final avg = _recentScores.reduce((a, b) => a + b) / _recentScores.length;
    final variance = _recentScores
        .map((score) => math.pow(score - avg, 2))
        .reduce((a, b) => a + b) / _recentScores.length;
    
    final standardDeviation = math.sqrt(variance);
    
    // Lower standard deviation = higher consistency
    return math.max(0.0, 100.0 - (standardDeviation / avg * 100));
  }

  @override
  void onRemove() {
    _performanceMonitor.dispose();
    super.onRemove();
  }

  // Getters for external access
  int get currentScore => _currentScore;
  int get sessionScore => _sessionScore;
  int get currentLevel => _currentLevel;
  int get linesCleared => _linesCleared;
  int get blocksPlaced => _blocksPlaced;
  int get comboCount => _comboCount;
  int get maxCombo => _maxCombo;
  int get currentStreak => _currentStreak;
  int get maxStreak => _maxStreak;
  double get currentMultiplier => _currentMultiplier;
  Duration get gameTime => _gameTime;
  bool get isPerfectGame => _isPerfectGame;
  Set<String> get sessionAchievements => Set.unmodifiable(_sessionAchievements);
}