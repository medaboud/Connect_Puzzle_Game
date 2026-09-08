import 'cell.dart';
import 'game_state.dart';
import 'puzzle.dart';

enum MoveResultType {
  started,
  extended,
  backtracked,
  completed,
  ignoredSameCell,
  invalidMustStartAtOne,
  invalidOutOfBounds,
  invalidNotAdjacent,
  invalidAlreadyVisited,
  invalidSkippedCheckpoint,
}

class MoveResult {
  final MoveResultType type;
  final GameState state;
  final String? message;
  final Cell? targetCell;

  const MoveResult({
    required this.type,
    required this.state,
    this.message,
    this.targetCell,
  });

  bool get isValid =>
      type == MoveResultType.started ||
      type == MoveResultType.extended ||
      type == MoveResultType.backtracked ||
      type == MoveResultType.completed ||
      type == MoveResultType.ignoredSameCell;

  bool get isInvalid => !isValid;
}

/// Pure functional game engine for Loopline.
/// Contains no Flutter widgets or mutable state.
class GameEngine {
  const GameEngine();

  /// Validates bounds for [cell].
  static bool isCellInBounds(Puzzle puzzle, Cell cell) {
    return cell.isInBounds(puzzle.rows, puzzle.cols);
  }

  /// Validates orthogonal adjacency between [a] and [b].
  static bool isOrthogonallyAdjacent(Cell a, Cell b) {
    return a.isAdjacent(b);
  }

  /// Rule: Starting is permitted ONLY at checkpoint 1.
  static bool canStartAt(Puzzle puzzle, Cell cell) {
    return puzzle.checkpoints[1] == cell;
  }

  /// Core Pure Move Function: Handles drag or tap onto [targetCell].
  static MoveResult handleCellInput(GameState state, Cell targetCell) {
    final puzzle = state.puzzle;

    // 1. If game is already won, ignore further moves.
    if (state.isCompleted) {
      return MoveResult(
        type: MoveResultType.ignoredSameCell,
        state: state,
        targetCell: targetCell,
      );
    }

    // 2. Check bounds.
    if (!isCellInBounds(puzzle, targetCell)) {
      return MoveResult(
        type: MoveResultType.invalidOutOfBounds,
        state: state.copyWith(
          lastInvalidCell: targetCell,
          lastInvalidMessage: 'Outside the board',
        ),
        message: 'Move is outside the board',
        targetCell: targetCell,
      );
    }

    // 3. If path is currently empty, must start at checkpoint 1.
    if (state.path.isEmpty) {
      if (canStartAt(puzzle, targetCell)) {
        final newPath = [targetCell];
        // Checkpoint 1 was visited, next required checkpoint is 2.
        final nextCheckpoint = 2;
        final newState = state.copyWith(
          path: newPath,
          nextRequiredCheckpoint: nextCheckpoint,
          status: GameStatus.playing,
          movesCount: state.movesCount + 1,
          clearInvalidCell: true,
          clearHintCell: true,
        );
        return MoveResult(
          type: MoveResultType.started,
          state: newState,
          targetCell: targetCell,
        );
      } else {
        return MoveResult(
          type: MoveResultType.invalidMustStartAtOne,
          state: state.copyWith(
            lastInvalidCell: targetCell,
            lastInvalidMessage: 'Start at checkpoint 1',
          ),
          message: 'Path must start at checkpoint 1',
          targetCell: targetCell,
        );
      }
    }

    final currentHead = state.headCell!;

    // 4. If user touches the current head again, ignore gently.
    if (currentHead == targetCell) {
      return MoveResult(
        type: MoveResultType.ignoredSameCell,
        state: state,
        targetCell: targetCell,
      );
    }

    // 5. Backtracking rule: Moving to the immediately previous cell backtracks one step.
    if (state.previousCell == targetCell) {
      final newPath = List<Cell>.from(state.path)..removeLast();

      // Recalculate next required checkpoint based on new path.
      final nextCp = _calculateNextRequiredCheckpoint(puzzle, newPath);

      final newState = state.copyWith(
        path: newPath,
        nextRequiredCheckpoint: nextCp,
        status: newPath.isEmpty ? GameStatus.initial : GameStatus.playing,
        movesCount: state.movesCount + 1,
        clearInvalidCell: true,
        clearHintCell: true,
      );

      return MoveResult(
        type: MoveResultType.backtracked,
        state: newState,
        targetCell: targetCell,
      );
    }

    // 6. Move must be orthogonally adjacent to current head.
    if (!isOrthogonallyAdjacent(currentHead, targetCell)) {
      return MoveResult(
        type: MoveResultType.invalidNotAdjacent,
        state: state.copyWith(
          lastInvalidCell: targetCell,
          lastInvalidMessage: 'Moves must be orthogonally adjacent',
        ),
        message: 'Must move orthogonally to an adjacent cell',
        targetCell: targetCell,
      );
    }

    // 7. Cell must not have already been visited in the current path.
    if (state.isVisited(targetCell)) {
      return MoveResult(
        type: MoveResultType.invalidAlreadyVisited,
        state: state.copyWith(
          lastInvalidCell: targetCell,
          lastInvalidMessage: 'Cell already visited',
        ),
        message: 'Cell already visited. You cannot cross your own path.',
        targetCell: targetCell,
      );
    }

    // 8. Checkpoint sequencing rule:
    // A checkpoint higher than the next required number cannot be entered.
    final cellCheckpoint = puzzle.checkpointAt(targetCell);
    if (cellCheckpoint != null) {
      if (cellCheckpoint != state.nextRequiredCheckpoint) {
        return MoveResult(
          type: MoveResultType.invalidSkippedCheckpoint,
          state: state.copyWith(
            lastInvalidCell: targetCell,
            lastInvalidMessage:
                'Must visit checkpoint ${state.nextRequiredCheckpoint} first',
          ),
          message:
              'Checkpoint $cellCheckpoint cannot be visited yet. Next is ${state.nextRequiredCheckpoint}.',
          targetCell: targetCell,
        );
      }
    }

    // 9. Move is valid! Extend path.
    final newPath = List<Cell>.from(state.path)..add(targetCell);
    int newNextCheckpoint = state.nextRequiredCheckpoint;
    if (cellCheckpoint != null &&
        cellCheckpoint == state.nextRequiredCheckpoint) {
      newNextCheckpoint++;
    }

    // 10. Check victory condition:
    // Every cell on the grid must be covered and all checkpoints visited in order.
    final hasCoveredAllCells = newPath.length == puzzle.totalCells;
    final hasVisitedAllCheckpoints =
        newNextCheckpoint > puzzle.totalCheckpoints;

    final isWon = hasCoveredAllCells && hasVisitedAllCheckpoints;

    final newState = state.copyWith(
      path: newPath,
      nextRequiredCheckpoint: newNextCheckpoint,
      status: isWon ? GameStatus.completed : GameStatus.playing,
      movesCount: state.movesCount + 1,
      clearInvalidCell: true,
      clearHintCell: true,
    );

    return MoveResult(
      type: isWon ? MoveResultType.completed : MoveResultType.extended,
      state: newState,
      targetCell: targetCell,
    );
  }

  /// Recalculates the next checkpoint needed from a given path.
  static int _calculateNextRequiredCheckpoint(Puzzle puzzle, List<Cell> path) {
    int next = 1;
    for (final cell in path) {
      final cp = puzzle.checkpointAt(cell);
      if (cp == next) {
        next++;
      }
    }
    return next;
  }

  /// Pure backtrack function: steps back one cell.
  static GameState backtrack(GameState state) {
    if (state.path.isEmpty || state.isCompleted) return state;

    final newPath = List<Cell>.from(state.path)..removeLast();
    final nextCp = _calculateNextRequiredCheckpoint(state.puzzle, newPath);

    return state.copyWith(
      path: newPath,
      nextRequiredCheckpoint: nextCp,
      status: newPath.isEmpty ? GameStatus.initial : GameStatus.playing,
      movesCount: state.movesCount + 1,
      clearInvalidCell: true,
      clearHintCell: true,
    );
  }

  /// Pure reset function: clears path to initial state.
  static GameState reset(Puzzle puzzle) {
    return GameState.initial(puzzle);
  }

  /// Hint logic: Identifies the next cell according to the internal solution.
  /// If the player's path diverges from the solution, hints to backtrack to the divergence.
  /// Otherwise, highlights the next cell in the solution.
  static Cell? getNextHintCell(Puzzle puzzle, GameState state) {
    final solution = puzzle.solution;
    if (solution.isEmpty) return null;

    if (state.path.isEmpty) {
      return solution.first;
    }

    // Check if current path matches solution prefix
    for (int i = 0; i < state.path.length; i++) {
      if (i >= solution.length || state.path[i] != solution[i]) {
        // Divergence found: recommend backtracking
        return state.previousCell ?? state.puzzle.startCell;
      }
    }

    // Path is on track: next step is solution[state.path.length]
    if (state.path.length < solution.length) {
      return solution[state.path.length];
    }

    return null;
  }

  /// Pure hint application: increments hintsUsed and sets hintCell.
  static GameState applyHint(GameState state) {
    final hint = getNextHintCell(state.puzzle, state);
    if (hint == null) return state;

    return state.copyWith(
      hintsUsed: state.hintsUsed + 1,
      hintCell: hint,
      clearInvalidCell: true,
    );
  }

  /// Pure validation check of an arbitrary solution path.
  static bool isSolutionValid(Puzzle puzzle, List<Cell> path) {
    if (path.length != puzzle.totalCells) return false;

    // All cells must be in bounds and unique
    final visited = <Cell>{};
    for (final cell in path) {
      if (!isCellInBounds(puzzle, cell)) return false;
      if (!visited.add(cell)) return false; // Duplicate
    }

    // Path must start at checkpoint 1
    if (path.first != puzzle.checkpoints[1]) return false;

    // Check orthogonal continuity and checkpoint ordering
    int nextCheckpoint = 2; // Checkpoint 1 visited at start
    for (int i = 0; i < path.length - 1; i++) {
      final current = path[i];
      final next = path[i + 1];

      if (!isOrthogonallyAdjacent(current, next)) return false;

      final nextCp = puzzle.checkpointAt(next);
      if (nextCp != null) {
        if (nextCp != nextCheckpoint) {
          return false;
        }
        nextCheckpoint++;
      }
    }

    return nextCheckpoint > puzzle.totalCheckpoints;
  }
}
