import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../../../core/constants/game_constants.dart';
import 'grid_component.dart';

typedef ShapeOffsets = List<({int dr, int dc})>;

class ShapePieceComponent extends PositionComponent with DragCallbacks, HasGameRef {
  final GridComponent grid;
  final ShapeOffsets offsets;
  final double cell;
  final Color color; // piece color

  /// After successful placement
 void Function({required int placedCells, required int clearedCells})? onPlaced;

  late Vector2 _home;
  bool _hoverValid = false;

  // Bounds for clamping/snap
  late final int _minDr;
  late final int _maxDr;
  late final int _minDc;
  late final int _maxDc;

  ShapePieceComponent({
    required this.grid,
    required this.offsets,
    required this.cell,
    required this.color,
    this.onPlaced,
  }) : super(priority: 50) {
    _minDr = offsets.map((e) => e.dr).reduce(min);
    _maxDr = offsets.map((e) => e.dr).reduce(max);
    _minDc = offsets.map((e) => e.dc).reduce(min);
    _maxDc = offsets.map((e) => e.dc).reduce(max);

    size = Vector2((_maxDc - _minDc + 1) * cell, (_maxDr - _minDr + 1) * cell);
  }

  void setHome(Vector2 p) {
    _home = p.clone();
    position = p;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;

    // Check validity using snapped base
    final base = grid.snapBaseForShape(
      approxTopLeftWorld: position,
      minDr: _minDr,
      maxDr: _maxDr,
      minDc: _minDc,
      maxDc: _maxDc,
    );
    _hoverValid = grid.canPlaceAt(base.r, base.c, offsets);
    super.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // Snap to nearest + clamped base cell
    final base = grid.snapBaseForShape(
      approxTopLeftWorld: position,
      minDr: _minDr,
      maxDr: _maxDr,
      minDc: _minDc,
      maxDc: _maxDc,
    );

    if (grid.canPlaceAt(base.r, base.c, offsets)) {
      grid.placeAt(base.r, base.c, offsets, color);
      final cleared = grid.clearFullLines();     // cells cleared from full rows/cols
      onPlaced?.call(placedCells: offsets.length, clearedCells: cleared);
      removeFromParent();
    } else {
      position = _home.clone();
      _hoverValid = false;
    }
    super.onDragEnd(event);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final basePaint = Paint()..color = color;
    final hoverOutline = Paint()
      ..color = _hoverValid ? const Color(0xAAFFFFFF) : const Color(0x00000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // subtle shadow
    final shadow = Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (final o in offsets) {
      final rect = Rect.fromLTWH(
        o.dc * cell + GameConstants.shapeCellPadding,
        o.dr * cell + GameConstants.shapeCellPadding,
        cell - GameConstants.shapeCellPadding * 2,
        cell - GameConstants.shapeCellPadding * 2,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(0, 1)), const Radius.circular(6)), shadow);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), basePaint);
      if (_hoverValid) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(1.0), const Radius.circular(7)), hoverOutline);
      }
    }
  }
}
