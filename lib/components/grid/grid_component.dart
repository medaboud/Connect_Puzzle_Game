import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/position.dart';

class GridComponent extends PositionComponent {
  final int gridSize;
  final Map<int, Position> numberPositions;

  late double cellSize;
  late Vector2 gridOffset;

  GridComponent({
    required this.gridSize,
    required this.numberPositions,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final numberPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );

    final boardSize = size.x < size.y ? size.x : size.y;
    cellSize = boardSize / gridSize;

    gridOffset = Vector2(
      (size.x - boardSize) / 2,
      (size.y - boardSize) / 2,
    );

    // Draw grid lines
    for (int i = 0; i <= gridSize; i++) {
      final offset = i * cellSize;

      // Horizontal
      canvas.drawLine(
        Offset(gridOffset.x, gridOffset.y + offset),
        Offset(gridOffset.x + boardSize, gridOffset.y + offset),
        paint,
      );

      // Vertical
      canvas.drawLine(
        Offset(gridOffset.x + offset, gridOffset.y),
        Offset(gridOffset.x + offset, gridOffset.y + boardSize),
        paint,
      );
    }

    // Draw numbers
    for (final entry in numberPositions.entries) {
      final number = entry.key;
      final pos = entry.value;

      final center = cellToWorldCenter(pos);

      numberPaint.render(
        canvas,
        number.toString(),
        center - Vector2(8, 12),
      );
    }
  }

  /* ===========================
      COORDINATE CONVERSION
     =========================== */

  Position? worldToCell(Vector2 worldPosition) {
    final boardSize = cellSize * gridSize;

    if (worldPosition.x < gridOffset.x ||
        worldPosition.y < gridOffset.y ||
        worldPosition.x > gridOffset.x + boardSize ||
        worldPosition.y > gridOffset.y + boardSize) {
      return null;
    }

    final col =
    ((worldPosition.x - gridOffset.x) / cellSize).floor();
    final row =
    ((worldPosition.y - gridOffset.y) / cellSize).floor();

    if (row < 0 ||
        row >= gridSize ||
        col < 0 ||
        col >= gridSize) {
      return null;
    }

    return Position(row, col);
  }

  Vector2 cellToWorldCenter(Position pos) {
    return Vector2(
      gridOffset.x + (pos.col + 0.5) * cellSize,
      gridOffset.y + (pos.row + 0.5) * cellSize,
    );
  }
}
