import 'dart:math';
import 'package:flutter/material.dart';
import '../game/cell.dart';
import '../game/game_state.dart';
import '../game/puzzle.dart';
import 'board_painter.dart';

class BoardWidget extends StatefulWidget {
  final Puzzle puzzle;
  final GameState state;
  final ValueChanged<Cell> onCellInput;
  final bool hapticsEnabled;
  final bool tapToExtendEnabled;
  final bool reducedMotion;

  const BoardWidget({
    super.key,
    required this.puzzle,
    required this.state,
    required this.onCellInput,
    this.hapticsEnabled = true,
    this.tapToExtendEnabled = true,
    this.reducedMotion = false,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Cell? _lastDragCell;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (!widget.reducedMotion) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant BoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _pulseController.stop();
        _pulseController.value = 0.5;
      } else {
        _pulseController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Cell? _cellFromLocalPosition(Offset localOffset, Size size) {
    final rows = widget.puzzle.rows;
    final cols = widget.puzzle.cols;

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final cellSize = min(cellWidth, cellHeight);

    final offsetX = (size.width - (cols * cellSize)) / 2;
    final offsetY = (size.height - (rows * cellSize)) / 2;

    if (localOffset.dx < offsetX ||
        localOffset.dx >= offsetX + cols * cellSize ||
        localOffset.dy < offsetY ||
        localOffset.dy >= offsetY + rows * cellSize) {
      return null;
    }

    final col = ((localOffset.dx - offsetX) / cellSize).floor();
    final row = ((localOffset.dy - offsetY) / cellSize).floor();

    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      return Cell(row, col);
    }
    return null;
  }

  void _handleTouch(Offset localPosition, Size size) {
    final cell = _cellFromLocalPosition(localPosition, size);
    if (cell != null && cell != _lastDragCell) {
      _lastDragCell = cell;
      widget.onCellInput(cell);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = widget.puzzle.rows;
    final cols = widget.puzzle.cols;

    final semanticsLabel =
        'Loopline puzzle board, $rows rows by $cols columns. '
        'Covered ${widget.state.path.length} of ${widget.puzzle.totalCells} cells. '
        'Next checkpoint is ${widget.state.nextRequiredCheckpoint} of ${widget.puzzle.totalCheckpoints}.';

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxSide = min(constraints.maxWidth, constraints.maxHeight);
          final boardSize = Size(maxSide, maxSide);

          return Center(
            child: SizedBox(
              width: boardSize.width,
              height: boardSize.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  _lastDragCell = null;
                  _handleTouch(details.localPosition, boardSize);
                },
                onPanUpdate: (details) {
                  _handleTouch(details.localPosition, boardSize);
                },
                onPanEnd: (_) {
                  _lastDragCell = null;
                },
                onTapUp: widget.tapToExtendEnabled
                    ? (details) {
                        _lastDragCell = null;
                        _handleTouch(details.localPosition, boardSize);
                      }
                    : null,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: boardSize,
                      painter: BoardPainter(
                        puzzle: widget.puzzle,
                        state: widget.state,
                        invalidCell: widget.state.lastInvalidCell,
                        hintCell: widget.state.hintCell,
                        isDarkMode: isDark,
                        animationValue: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
