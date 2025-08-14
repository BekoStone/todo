import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import 'components/grid_component.dart';
import 'components/dock_component.dart';
import 'systems/input_system.dart';
import 'systems/scoring_system.dart';
import 'systems/power_up_system.dart';
import '../../domain/entities/power_up_entity.dart';
import '../misc/achievements_manager.dart';

class BoxHooksGame extends FlameGame with DragCallbacks, TapCallbacks {
  GridComponent? grid;
  DockComponent? dock;

  final InputSystem inputSystem = InputSystem();
  final ScoringSystem scoringSystem = ScoringSystem();
  final PowerUpSystem powerUpSystem = PowerUpSystem();

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> gold = ValueNotifier<int>(0);
  final ValueNotifier<bool> gameOver = ValueNotifier<bool>(false);

  bool muted = false;

  @override
  Future<void> onLoad() async {
    await add(_GradientBackground()); // render first, under everything

    final g = GridComponent(
      rows: GameConstants.gridRows,
      cols: GameConstants.gridCols,
      cellSize: GameConstants.cellSize,
    );
    await add(g);
    grid = g;

    final d = DockComponent(
      gridRef: g,
      onPlaced: (placedCells, clearedCells) {
        final totalCells = placedCells + clearedCells;
        addScore(totalCells * 10);

        AchievementsManager.instance.onPiecePlaced();
        if (clearedCells > 0) AchievementsManager.instance.onLineCleared();
      },
      onMovesAvailabilityChanged: _handleMovesAvailability,
    );
    await add(d);
    dock = d;

    camera.viewfinder.visibleGameSize = Vector2(size.x, size.y);
  }

  void addScore(int delta) {
    score.value += delta;
    gold.value += (delta ~/ 50);
    AchievementsManager.instance.onScoreChanged(score.value);
  }

  void setMuted(bool v) {
    muted = v;
  }

  void _setGameOver(bool v) {
    if (gameOver.value == v) return;
    gameOver.value = v;
  }

  void _handleMovesAvailability(bool hasMoves) {
    _setGameOver(!hasMoves);
  }

  void resetGame() {
    final g = grid;
    final d = dock;
    if (g != null && d != null) {
      g.clearAllFilled();
      score.value = 0;
      gold.value = 0;
      gameOver.value = false;
      powerUpSystem
        ..cancel()
        ..grant(PowerUpType.bomb, 2 - (powerUpSystem.counts[PowerUpType.bomb] ?? 0))
        ..grant(PowerUpType.line, 2 - (powerUpSystem.counts[PowerUpType.line] ?? 0))
        ..grant(PowerUpType.color, 2 - (powerUpSystem.counts[PowerUpType.color] ?? 0));

      d.reset(); // ensure 3 fresh pieces always
      AchievementsManager.instance.resetSession();
    }
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    final g = grid;
    final d = dock;
    if (g == null || d == null) return;

    final gridPixelW = GameConstants.gridCols * GameConstants.cellSize;
    final gridPixelH = GameConstants.gridRows * GameConstants.cellSize;

    final centeredX = ((canvasSize.x - gridPixelW) / 2).roundToDouble() + 0.5;
    final gridY = GameConstants.topPadding;

    g.position = Vector2(centeredX, gridY);

    final powerUpPanelBottomY =
        gridY + gridPixelH + GameConstants.gridGapToPanel + GameConstants.panelHeight;
    final dockY = powerUpPanelBottomY + GameConstants.panelGapToDock;

    d.position = Vector2(0, dockY);
    camera.viewfinder.visibleGameSize = Vector2(canvasSize.x, canvasSize.y);

    d.layoutAndRespawnIfNeeded();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver.value) return; // freeze interactions on Game Over

    final g = grid;
    if (g == null) return;

    if (powerUpSystem.isActive) {
      final using = powerUpSystem.active;
      final cleared = powerUpSystem.apply(g, event.localPosition);
      if (cleared > 0) {
        addScore(cleared * 5);
        if (using != null) {
          AchievementsManager.instance.onPowerUpUsed(using);
        }
        dock?.layoutAndRespawnIfNeeded();
      }
    } else {
      inputSystem.onTap(event.localPosition.x, event.localPosition.y);
    }
    super.onTapDown(event);
  }

  bool tryActivatePowerUp(PowerUpType t) {
    return powerUpSystem.activate(PowerUpEntity(t));
  }
}

/// Full-screen gradient background behind the board.
/// Uses the component's size (kept in sync with the game size).
class _GradientBackground extends PositionComponent with HasGameRef<FlameGame> {
  @override
  int get priority => -1000; // render first

  @override
  Future<void> onLoad() async {
    size = gameRef.size;
    position = Vector2.zero();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.x, size.y),
        const [
          ui.Color(0xFF0B1220), // deep navy
          ui.Color(0xFF1E293B), // slate blue
        ],
      );
    canvas.drawRect(rect, paint);
  }
}

