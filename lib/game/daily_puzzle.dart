import 'cell.dart';
import 'puzzle.dart';
import 'puzzle_validator.dart';

/// Provides a deterministic daily puzzle based on local calendar date.
/// Every user receives the exact same puzzle on any given date without a backend.
class DailyPuzzle {
  const DailyPuzzle._();

  static final DateTime _epoch = DateTime(2026, 1, 1);

  /// Generates the deterministic puzzle for [date] (defaults to today).
  static Puzzle getForDate([DateTime? date]) {
    final target = date ?? DateTime.now();
    final localDate = DateTime(target.year, target.month, target.day);

    final daysSinceEpoch = localDate.difference(_epoch).inDays;
    final dayIndex = daysSinceEpoch >= 0 ? daysSinceEpoch : 0;

    final dateKey =
        '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

    // Rotate board dimensions and patterns across the week:
    // Weekdays (Mon-Wed): 5x5
    // Thu-Sat: 6x6
    // Sunday: 7x7
    final weekday = localDate.weekday; // 1 = Monday, 7 = Sunday

    final int size;
    final PuzzleDifficulty difficulty;
    if (weekday <= 3) {
      size = 5;
      difficulty = PuzzleDifficulty.easy;
    } else if (weekday <= 6) {
      size = 6;
      difficulty = PuzzleDifficulty.medium;
    } else {
      size = 7;
      difficulty = PuzzleDifficulty.hard;
    }

    final isRowMajor = (dayIndex % 2 == 0);
    final solution = isRowMajor
        ? _generateSnakeRowPath(size, size)
        : _generateSnakeColPath(size, size);

    // Pick 4 to 6 checkpoints along the solution path deterministically based on dayIndex
    final totalCells = size * size;
    final checkpointCount = size == 5 ? 4 : (size == 6 ? 5 : 6);

    final checkpoints = <int, Cell>{};
    // Always start at index 0 (checkpoint 1)
    checkpoints[1] = solution[0];

    // Distribute checkpoints along the path
    final step = (totalCells - 1) / (checkpointCount - 1);
    for (int i = 1; i < checkpointCount - 1; i++) {
      // Add slight day-based variation without breaking sequential ordering
      final baseIndex = (i * step).round();
      final jitter = ((dayIndex + i) % 3) - 1; // -1, 0, or 1
      final index = (baseIndex + jitter).clamp(1, totalCells - 2);

      checkpoints[i + 1] = solution[index];
    }

    // Last checkpoint at the end of the path
    checkpoints[checkpointCount] = solution.last;

    final puzzle = Puzzle(
      id: 'daily_$dateKey',
      title: 'Daily #$dayIndex',
      difficulty: difficulty,
      rows: size,
      cols: size,
      checkpoints: checkpoints,
      solution: solution,
      isDaily: true,
    );

    // Development safety check: verify puzzle is 100% valid
    assert(() {
      final errors = PuzzleValidator.validate(puzzle);
      if (errors.isNotEmpty) {
        throw StateError('Daily puzzle validation failed: $errors');
      }
      return true;
    }());

    return puzzle;
  }

  static List<Cell> _generateSnakeRowPath(int rows, int cols) {
    final path = <Cell>[];
    for (int r = 0; r < rows; r++) {
      if (r % 2 == 0) {
        for (int c = 0; c < cols; c++) {
          path.add(Cell(r, c));
        }
      } else {
        for (int c = cols - 1; c >= 0; c--) {
          path.add(Cell(r, c));
        }
      }
    }
    return path;
  }

  static List<Cell> _generateSnakeColPath(int rows, int cols) {
    final path = <Cell>[];
    for (int c = 0; c < cols; c++) {
      if (c % 2 == 0) {
        for (int r = 0; r < rows; r++) {
          path.add(Cell(r, c));
        }
      } else {
        for (int r = rows - 1; r >= 0; r--) {
          path.add(Cell(r, c));
        }
      }
    }
    return path;
  }
}
