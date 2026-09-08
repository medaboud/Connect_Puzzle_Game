import 'package:flutter/foundation.dart';

/// Represents an immutable coordinate on the puzzle grid.
@immutable
class Cell {
  final int row;
  final int col;

  const Cell(this.row, this.col);

  /// Checks whether [other] is orthogonally adjacent (up, down, left, right).
  bool isAdjacent(Cell other) {
    final int dRow = (row - other.row).abs();
    final int dCol = (col - other.col).abs();
    return (dRow + dCol) == 1;
  }

  /// Checks whether this cell is within the bounds of a [rows] x [cols] grid.
  bool isInBounds(int rows, int cols) {
    return row >= 0 && row < rows && col >= 0 && col < cols;
  }

  Map<String, dynamic> toJson() => {'row': row, 'col': col};

  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(json['row'] as int, json['col'] as int);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'Cell($row, $col)';
}
