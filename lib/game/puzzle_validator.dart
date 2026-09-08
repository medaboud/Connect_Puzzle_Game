import 'cell.dart';
import 'game_engine.dart';
import 'puzzle.dart';

class PuzzleValidationError {
  final String puzzleId;
  final String message;

  const PuzzleValidationError(this.puzzleId, this.message);

  @override
  String toString() => 'PuzzleValidationError[$puzzleId]: $message';
}

/// Development-only validator to verify correctness of puzzle configurations.
class PuzzleValidator {
  const PuzzleValidator();

  /// Validates [puzzle] against all engine rules.
  /// Returns empty list if valid, or a list of errors if invalid.
  static List<PuzzleValidationError> validate(Puzzle puzzle) {
    final errors = <PuzzleValidationError>[];

    // 1. Dimensions check
    if (puzzle.rows <= 0 || puzzle.cols <= 0) {
      errors.add(
        PuzzleValidationError(
          puzzle.id,
          'Invalid dimensions: ${puzzle.rows}x${puzzle.cols}',
        ),
      );
      return errors;
    }

    // 2. Checkpoint bounds and uniqueness
    if (puzzle.checkpoints.isEmpty) {
      errors.add(PuzzleValidationError(puzzle.id, 'Puzzle has no checkpoints'));
      return errors;
    }

    // Checkpoints must start at 1 and increase without gaps
    final checkpointNumbers = puzzle.checkpoints.keys.toList()..sort();
    for (int i = 0; i < checkpointNumbers.length; i++) {
      final expected = i + 1;
      if (checkpointNumbers[i] != expected) {
        errors.add(
          PuzzleValidationError(
            puzzle.id,
            'Checkpoints must be sequential starting at 1. Expected $expected, got ${checkpointNumbers[i]}',
          ),
        );
      }
    }

    final seenCells = <Cell>{};
    for (final entry in puzzle.checkpoints.entries) {
      final cpNum = entry.key;
      final cell = entry.value;

      if (!cell.isInBounds(puzzle.rows, puzzle.cols)) {
        errors.add(
          PuzzleValidationError(
            puzzle.id,
            'Checkpoint $cpNum at $cell is out of bounds (${puzzle.rows}x${puzzle.cols})',
          ),
        );
      }

      if (!seenCells.add(cell)) {
        errors.add(
          PuzzleValidationError(
            puzzle.id,
            'Multiple checkpoints share cell $cell',
          ),
        );
      }
    }

    // 3. Solution path checks
    final solution = puzzle.solution;
    if (solution.length != puzzle.totalCells) {
      errors.add(
        PuzzleValidationError(
          puzzle.id,
          'Solution length (${solution.length}) does not match total cells (${puzzle.totalCells})',
        ),
      );
    }

    // Check solution covers every cell exactly once
    final visited = <Cell>{};
    for (int i = 0; i < solution.length; i++) {
      final cell = solution[i];
      if (!cell.isInBounds(puzzle.rows, puzzle.cols)) {
        errors.add(
          PuzzleValidationError(
            puzzle.id,
            'Solution cell at index $i ($cell) is out of bounds',
          ),
        );
      }

      if (!visited.add(cell)) {
        errors.add(
          PuzzleValidationError(
            puzzle.id,
            'Solution visits cell $cell more than once',
          ),
        );
      }
    }

    // Check solution continuity (orthogonal steps)
    for (int i = 0; i < solution.length - 1; i++) {
      final a = solution[i];
      final b = solution[i + 1];
      if (!a.isAdjacent(b)) {
        errors.add(
          PuzzleValidationError(
            puzzle.id,
            'Solution step from index $i ($a) to ${i + 1} ($b) is not orthogonally adjacent',
          ),
        );
      }
    }

    // Check starting cell is checkpoint 1
    if (solution.isNotEmpty && puzzle.checkpoints[1] != solution.first) {
      errors.add(
        PuzzleValidationError(
          puzzle.id,
          'Solution does not start at checkpoint 1 (${puzzle.checkpoints[1]} vs ${solution.first})',
        ),
      );
    }

    // Check checkpoints are encountered in declared ascending order
    int expectedCheckpoint = 1;
    for (final cell in solution) {
      final cp = puzzle.checkpointAt(cell);
      if (cp != null) {
        if (cp != expectedCheckpoint) {
          errors.add(
            PuzzleValidationError(
              puzzle.id,
              'Checkpoint encountered out of order in solution: expected $expectedCheckpoint, got $cp at $cell',
            ),
          );
        }
        expectedCheckpoint++;
      }
    }

    if (expectedCheckpoint - 1 != puzzle.totalCheckpoints) {
      errors.add(
        PuzzleValidationError(
          puzzle.id,
          'Solution failed to visit all checkpoints: visited ${expectedCheckpoint - 1} of ${puzzle.totalCheckpoints}',
        ),
      );
    }

    // Final check: GameEngine.isSolutionValid
    if (!GameEngine.isSolutionValid(puzzle, solution)) {
      errors.add(
        PuzzleValidationError(
          puzzle.id,
          'GameEngine.isSolutionValid returned false',
        ),
      );
    }

    return errors;
  }
}
