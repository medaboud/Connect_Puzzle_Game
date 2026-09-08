import 'package:flutter/foundation.dart';
import 'cell.dart';

enum PuzzleDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case PuzzleDifficulty.easy:
        return 'Easy';
      case PuzzleDifficulty.medium:
        return 'Medium';
      case PuzzleDifficulty.hard:
        return 'Hard';
    }
  }
}

/// Represents an immutable puzzle definition.
@immutable
class Puzzle {
  final String id;
  final String title;
  final PuzzleDifficulty difficulty;
  final int rows;
  final int cols;

  /// Map of checkpoint number (1..N) to Cell.
  final Map<int, Cell> checkpoints;

  /// Internal reference solution path covering every cell in order.
  final List<Cell> solution;

  final bool isDaily;

  const Puzzle({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.rows,
    required this.cols,
    required this.checkpoints,
    required this.solution,
    this.isDaily = false,
  });

  int get totalCells => rows * cols;
  int get totalCheckpoints => checkpoints.length;

  /// Starting cell must be checkpoint 1.
  Cell get startCell => checkpoints[1]!;

  /// Returns checkpoint number at [cell], or null if none.
  int? checkpointAt(Cell cell) {
    for (final entry in checkpoints.entries) {
      if (entry.value == cell) {
        return entry.key;
      }
    }
    return null;
  }

  /// Returns cell for [checkpointNumber], or null if not found.
  Cell? cellForCheckpoint(int checkpointNumber) =>
      checkpoints[checkpointNumber];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'difficulty': difficulty.name,
    'rows': rows,
    'cols': cols,
    'checkpoints': checkpoints.map(
      (k, v) => MapEntry(k.toString(), v.toJson()),
    ),
    'solution': solution.map((c) => c.toJson()).toList(),
    'isDaily': isDaily,
  };

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    final checkpointsMap = (json['checkpoints'] as Map<String, dynamic>).map(
      (k, v) =>
          MapEntry(int.parse(k), Cell.fromJson(v as Map<String, dynamic>)),
    );
    final solutionList = (json['solution'] as List<dynamic>)
        .map((c) => Cell.fromJson(c as Map<String, dynamic>))
        .toList();

    return Puzzle(
      id: json['id'] as String,
      title: json['title'] as String,
      difficulty: PuzzleDifficulty.values.firstWhere(
        (d) => d.name == json['difficulty'],
        orElse: () => PuzzleDifficulty.easy,
      ),
      rows: json['rows'] as int,
      cols: json['cols'] as int,
      checkpoints: checkpointsMap,
      solution: solutionList,
      isDaily: json['isDaily'] as bool? ?? false,
    );
  }
}
