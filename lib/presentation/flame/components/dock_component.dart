import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color;
import '../../../core/constants/game_constants.dart';
import 'grid_component.dart';
import 'shape_piece_component.dart';

class DockComponent extends PositionComponent with HasGameRef {
  final GridComponent gridRef;

  /// Called after a piece is placed: (placedCells, clearedCells)
  final void Function(int placedCells, int clearedCells) onPlaced;

  /// Called whenever available moves state changes.
  final void Function(bool hasMoves) onMovesAvailabilityChanged;

  final _rng = Random();
  final List<ShapePieceComponent> _pieces = [];
  bool _spawnedAtLeastOnce = false;

  DockComponent({
    required this.gridRef,
    required this.onPlaced,
    required this.onMovesAvailabilityChanged,
  }) : super(priority: 40) {
    size = Vector2(0, GameConstants.dockHeight);
  }

  /// Forcefully clears current pieces and respawns a fresh 3.
  void reset() {
    for (final p in List<ShapePieceComponent>.from(_pieces)) {
      p.removeFromParent();
    }
    _pieces.clear();
    _spawnThree();
    _spawnedAtLeastOnce = true;
  }

  /// Called by the Game **after** layout is positioned.
  void layoutAndRespawnIfNeeded() {
    if (_spawnedAtLeastOnce && _pieces.isNotEmpty) {
      _recomputeMoves();
      return;
    }
    _spawnThree();
    _spawnedAtLeastOnce = true;
  }

  void _spawnThree() {
    for (final p in List<ShapePieceComponent>.from(_pieces)) {
      p.removeFromParent();
    }
    _pieces.clear();

    final shapes = _randomThree();
    final totalWidth = shapes.fold<double>(0, (sum, s) => sum + _shapeWidth(s)) +
        GameConstants.dockPadding * (shapes.length + 1);

    final availableW = game.size.x;
    final startX = (availableW - totalWidth) / 2;
    var x = startX;

    final yWorld = position.y + (GameConstants.dockHeight / 2 - GameConstants.cellSize);

    for (final s in shapes) {
      // Random piece color
      final Color color = GameConstants.shapeColors[_rng.nextInt(GameConstants.shapeColors.length)];

      final piece = ShapePieceComponent(
        grid: gridRef,
        offsets: s,
        cell: GameConstants.cellSize,
        color: color,
      );

      game.add(piece);
      piece.setHome(Vector2(x, yWorld));

      piece.onPlaced = ({required int placedCells, required int clearedCells}) {
        onPlaced(placedCells, clearedCells);
        _pieces.remove(piece);
        if (_pieces.isEmpty) {
          _spawnThree();
        } else {
          _recomputeMoves();
        }
      };

      _pieces.add(piece);
      x += _shapeWidth(s) + GameConstants.dockPadding;
    }

    _recomputeMoves();
  }

  void _recomputeMoves() {
    final hasAny = _pieces.any((p) => gridRef.canPlaceShapeAnywhere(p.offsets));
    onMovesAvailabilityChanged(hasAny);
  }

  double _shapeWidth(List<({int dr, int dc})> s) {
    final minC = s.map((e) => e.dc).reduce(min);
    final maxC = s.map((e) => e.dc).reduce(max);
    return (maxC - minC + 1) * GameConstants.cellSize;
  }

  List<List<({int dr, int dc})>> _randomThree() {
    final pool = _shapePool;
    pool.shuffle(_rng);
    return pool.take(3).toList();
  }

  // Basic shapes
  List<List<({int dr, int dc})>> get _shapePool => [
        // single
        [(dr: 0, dc: 0)],
        // 1x2
        [(dr: 0, dc: 0), (dr: 0, dc: 1)],
        // 2x1
        [(dr: 0, dc: 0), (dr: 1, dc: 0)],
        // 2x2 square
        [(dr: 0, dc: 0), (dr: 0, dc: 1), (dr: 1, dc: 0), (dr: 1, dc: 1)],
        // L
        [(dr: 0, dc: 0), (dr: 1, dc: 0), (dr: 2, dc: 0), (dr: 2, dc: 1)],
        // line-3 horizontal
        [(dr: 0, dc: 0), (dr: 0, dc: 1), (dr: 0, dc: 2)],
        // T
        [(dr: 0, dc: 0), (dr: 0, dc: 1), (dr: 0, dc: 2), (dr: 1, dc: 1)],
        // Z
        [(dr: 0, dc: 0), (dr: 0, dc: 1), (dr: 1, dc: 1), (dr: 1, dc: 2)],
      ];
}
