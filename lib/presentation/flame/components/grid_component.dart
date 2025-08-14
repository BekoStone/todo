import 'dart:ui';
import 'package:flame/components.dart';
import '../../../core/constants/game_constants.dart';

class GridComponent extends PositionComponent {
  final int rows;
  final int cols;
  final double cellSize;

  /// Occupancy & colors per cell
  late final List<List<bool>> _filled;
  late final List<List<Color?>> _colors;

  GridComponent({
    required this.rows,
    required this.cols,
    required this.cellSize,
  }) {
    size = Vector2(cols * cellSize, rows * cellSize);
    _filled = List.generate(rows, (_) => List<bool>.filled(cols, false));
    _colors = List.generate(rows, (_) => List<Color?>.filled(cols, null));
  }

  // ---------- Coordinate helpers ----------

  ({int r, int c})? pointToCell(Vector2 world) {
    final local = world - position;
    if (local.x < 0 || local.y < 0 || local.x >= size.x || local.y >= size.y) return null;
    final c = (local.x / cellSize).floor();
    final r = (local.y / cellSize).floor();
    return (r: r, c: c);
  }

  ({int r, int c})? topLeftToCell(Vector2 worldTopLeft) {
    final local = worldTopLeft - position;
    if (local.x < 0 || local.y < 0 || local.x >= size.x || local.y >= size.y) return null;
    final c = (local.x / cellSize).floor();
    final r = (local.y / cellSize).floor();
    return (r: r, c: c);
  }

  /// Find the best base cell for a shape near [approxTopLeftWorld], clamped so shape fits.
  ({int r, int c}) snapBaseForShape({
    required Vector2 approxTopLeftWorld,
    required int minDr,
    required int maxDr,
    required int minDc,
    required int maxDc,
  }) {
    final local = approxTopLeftWorld - position;
    var c0 = (local.x / cellSize).round();
    var r0 = (local.y / cellSize).round();

    final shapeH = (maxDr - minDr + 1);
    final shapeW = (maxDc - minDc + 1);
    r0 = r0.clamp(0, rows - shapeH);
    c0 = c0.clamp(0, cols - shapeW);

    return (r: r0, c: c0);
  }

  // ---------- Placement & validation ----------

  bool canPlaceAt(int baseR, int baseC, Iterable<({int dr, int dc})> shape) {
    for (final o in shape) {
      final r = baseR + o.dr;
      final c = baseC + o.dc;
      if (r < 0 || c < 0 || r >= rows || c >= cols) return false;
      if (_filled[r][c]) return false;
    }
    return true;
  }

  /// Check if this [shape] can be placed *anywhere* on the grid.
  bool canPlaceShapeAnywhere(Iterable<({int dr, int dc})> shape) {
    // Compute shape size to limit search window
    var minDr = 999, maxDr = -999, minDc = 999, maxDc = -999;
    for (final o in shape) {
      if (o.dr < minDr) minDr = o.dr;
      if (o.dr > maxDr) maxDr = o.dr;
      if (o.dc < minDc) minDc = o.dc;
      if (o.dc > maxDc) maxDc = o.dc;
    }
    final h = maxDr - minDr + 1;
    final w = maxDc - minDc + 1;
    final maxBaseR = rows - h;
    final maxBaseC = cols - w;
    for (var r = 0; r <= maxBaseR; r++) {
      for (var c = 0; c <= maxBaseC; c++) {
        if (canPlaceAt(r, c, shape)) return true;
      }
    }
    return false;
  }

  /// Place a shape and paint its cells with [color].
  void placeAt(int baseR, int baseC, Iterable<({int dr, int dc})> shape, Color color) {
    for (final o in shape) {
      final r = baseR + o.dr;
      final c = baseC + o.dc;
      _filled[r][c] = true;
      _colors[r][c] = color;
    }
  }

  // ---------- Line/Area clearing ----------

  bool _isRowFull(int r) => _filled[r].every((v) => v);
  bool _isColFull(int c) {
    for (var r = 0; r < rows; r++) {
      if (!_filled[r][c]) return false;
    }
    return true;
  }

  int clearFullLines() {
    final rowsToClear = <int>[];
    final colsToClear = <int>[];

    for (var r = 0; r < rows; r++) {
      if (_isRowFull(r)) rowsToClear.add(r);
    }
    for (var c = 0; c < cols; c++) {
      if (_isColFull(c)) colsToClear.add(c);
    }

    var cleared = 0;
    for (final r in rowsToClear) {
      for (var c = 0; c < cols; c++) {
        if (_filled[r][c]) {
          _filled[r][c] = false;
          _colors[r][c] = null;
          cleared++;
        }
      }
    }
    for (final c in colsToClear) {
      for (var r = 0; r < rows; r++) {
        if (_filled[r][c]) {
          _filled[r][c] = false;
          _colors[r][c] = null;
          cleared++;
        }
      }
    }
    return cleared;
  }

  int clearRow(int r) {
    if (r < 0 || r >= rows) return 0;
    var count = 0;
    for (var c = 0; c < cols; c++) {
      if (_filled[r][c]) {
        _filled[r][c] = false;
        _colors[r][c] = null;
        count++;
      }
    }
    return count;
  }

  int clearColumn(int c) {
    if (c < 0 || c >= cols) return 0;
    var count = 0;
    for (var r = 0; r < rows; r++) {
      if (_filled[r][c]) {
        _filled[r][c] = false;
        _colors[r][c] = null;
        count++;
      }
    }
    return count;
  }

  int clearArea({required int centerR, required int centerC, int radius = 1}) {
    var count = 0;
    for (var dr = -radius; dr <= radius; dr++) {
      for (var dc = -radius; dc <= radius; dc++) {
        final r = centerR + dr;
        final c = centerC + dc;
        if (r >= 0 && r < rows && c >= 0 && c < cols && _filled[r][c]) {
          _filled[r][c] = false;
          _colors[r][c] = null;
          count++;
        }
      }
    }
    return count;
  }

  int clearAllFilled() {
    var count = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_filled[r][c]) {
          _filled[r][c] = false;
          _colors[r][c] = null;
          count++;
        }
      }
    }
    return count;
  }

  // ---------- Color-based helpers ----------

  Color? cellColorAt(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
    return _colors[r][c];
  }

  int clearAllOfColor(Color target) {
    var count = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_colors[r][c] == target) {
          _filled[r][c] = false;
          _colors[r][c] = null;
          count++;
        }
      }
    }
    return count;
  }

  // ---------- Rendering ----------

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // BOLD outer border
    final outer = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final outerRect = Rect.fromLTWH(1.5, 1.5, size.x - 3.0, size.y - 3.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(8)),
      outer,
    );

    // Bold per-cell borders
    final cellStroke = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
        canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(6)), cellStroke);
      }
    }

    // Filled cells (stored color)
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_filled[r][c]) {
          final col = _colors[r][c] ?? const Color(0xFF6A5AE0);
          final fill = Paint()..color = col;
          final rect = Rect.fromLTWH(
            c * cellSize + GameConstants.shapeCellPadding,
            r * cellSize + GameConstants.shapeCellPadding,
            cellSize - GameConstants.shapeCellPadding * 2,
            cellSize - GameConstants.shapeCellPadding * 2,
          );
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), fill);
        }
      }
    }
  }
}
