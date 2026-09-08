import 'dart:math';
import 'package:flutter/material.dart';
import '../game/cell.dart';
import '../game/game_state.dart';
import '../game/puzzle.dart';
import '../theme/app_colors.dart';

class BoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final GameState state;
  final Cell? invalidCell;
  final Cell? hintCell;
  final bool isDarkMode;
  final double animationValue;

  BoardPainter({
    required this.puzzle,
    required this.state,
    this.invalidCell,
    this.hintCell,
    this.isDarkMode = false,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = puzzle.rows;
    final cols = puzzle.cols;

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final cellSize = min(cellWidth, cellHeight);

    // Center board if size is not square
    final offsetX = (size.width - (cols * cellSize)) / 2;
    final offsetY = (size.height - (rows * cellSize)) / 2;

    final cellBgPaint = Paint()
      ..color = isDarkMode
          ? AppColors.darkCellBackground
          : AppColors.cellBackground
      ..style = PaintingStyle.fill;

    final cellBorderPaint = Paint()
      ..color = isDarkMode ? AppColors.darkCellBorder : AppColors.cellBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final activeCellPaint = Paint()
      ..color = isDarkMode
          ? AppColors.cobaltPath.withValues(alpha: 0.2)
          : AppColors.cellActive
      ..style = PaintingStyle.fill;

    // 1. Draw Grid Cells
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = Cell(r, c);
        final rect = Rect.fromLTWH(
          offsetX + c * cellSize + 2,
          offsetY + r * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

        final isVisited = state.isVisited(cell);
        canvas.drawRRect(rrect, isVisited ? activeCellPaint : cellBgPaint);
        canvas.drawRRect(rrect, cellBorderPaint);

        // Highlight hint cell if active
        if (hintCell == cell) {
          final hintPaint = Paint()
            ..color = AppColors.hintGold.withValues(
              alpha: 0.35 + 0.2 * sin(animationValue * pi * 2),
            )
            ..style = PaintingStyle.fill;
          final hintBorder = Paint()
            ..color = AppColors.hintGold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5;
          canvas.drawRRect(rrect, hintPaint);
          canvas.drawRRect(rrect, hintBorder);
        }

        // Highlight invalid cell flash
        if (invalidCell == cell) {
          final invalidPaint = Paint()
            ..color = AppColors.invalidRed.withValues(alpha: 0.4)
            ..style = PaintingStyle.fill;
          final invalidBorder = Paint()
            ..color = AppColors.invalidRed
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5;
          canvas.drawRRect(rrect, invalidPaint);
          canvas.drawRRect(rrect, invalidBorder);
        }
      }
    }

    // 2. Draw Drawn Path
    if (state.path.length >= 2) {
      final pathStroke = Paint()
        ..color = AppColors.cobaltPath
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(cellSize * 0.26, 6.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final drawnPath = Path();
      final firstCenter = _cellCenter(
        state.path.first,
        offsetX,
        offsetY,
        cellSize,
      );
      drawnPath.moveTo(firstCenter.dx, firstCenter.dy);

      for (int i = 1; i < state.path.length; i++) {
        final pt = _cellCenter(state.path[i], offsetX, offsetY, cellSize);
        drawnPath.lineTo(pt.dx, pt.dy);
      }

      canvas.drawPath(drawnPath, pathStroke);
    }

    // 3. Draw Active Head Node
    if (state.headCell != null) {
      final headCenter = _cellCenter(
        state.headCell!,
        offsetX,
        offsetY,
        cellSize,
      );
      final headRadius = cellSize * 0.22;

      // Subtle glow
      final glowPaint = Paint()
        ..color = AppColors.cobaltPath.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(headCenter, headRadius * 1.35, glowPaint);

      // Solid core
      final corePaint = Paint()
        ..color = AppColors.cobaltHead
        ..style = PaintingStyle.fill;
      canvas.drawCircle(headCenter, headRadius, corePaint);

      // Inner dot
      final innerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(headCenter, headRadius * 0.4, innerDot);
    }

    // 4. Draw Checkpoints
    for (final entry in puzzle.checkpoints.entries) {
      final cpNumber = entry.key;
      final cell = entry.value;
      final center = _cellCenter(cell, offsetX, offsetY, cellSize);
      final badgeRadius = cellSize * 0.32;

      final isVisited = state.isVisited(cell);
      final isNextTarget = (cpNumber == state.nextRequiredCheckpoint);

      final Color badgeColor;
      if (isVisited) {
        badgeColor = AppColors.completedGreen;
      } else if (isNextTarget) {
        badgeColor = AppColors.coralCheckpoint;
      } else {
        badgeColor = AppColors.coralCheckpointDark.withValues(alpha: 0.85);
      }

      // Checkpoint badge shadow/outline
      if (isNextTarget) {
        final pulseRadius =
            badgeRadius + 3.0 + 2.0 * sin(animationValue * pi * 2);
        final pulsePaint = Paint()
          ..color = AppColors.coralCheckpoint.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, pulseRadius, pulsePaint);
      }

      final badgePaint = Paint()
        ..color = badgeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, badgeRadius, badgePaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, badgeRadius, borderPaint);

      // Checkpoint Number Text
      final textSpan = TextSpan(
        text: cpNumber.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: badgeRadius * 1.15,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  Offset _cellCenter(
    Cell cell,
    double offsetX,
    double offsetY,
    double cellSize,
  ) {
    return Offset(
      offsetX + cell.col * cellSize + cellSize / 2,
      offsetY + cell.row * cellSize + cellSize / 2,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.invalidCell != invalidCell ||
        oldDelegate.hintCell != hintCell ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
