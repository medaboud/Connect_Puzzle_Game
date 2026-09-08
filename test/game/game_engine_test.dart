import 'package:flutter_test/flutter_test.dart';
import 'package:connect_puzzle_game/game/cell.dart';
import 'package:connect_puzzle_game/game/game_engine.dart';
import 'package:connect_puzzle_game/game/game_state.dart';
import 'package:connect_puzzle_game/game/puzzle_library.dart';

void main() {
  group('GameEngine Rule Enforcement', () {
    final puzzle = PuzzleLibrary
        .easy1; // 4x4, checkpoints: 1 at (0,0), 2 at (1,1), 3 at (3,0)

    test('Starting must be at checkpoint 1', () {
      final state = GameState.initial(puzzle);

      // Attempting to start at (0, 1) - not checkpoint 1
      final badStart = GameEngine.handleCellInput(state, const Cell(0, 1));
      expect(badStart.type, equals(MoveResultType.invalidMustStartAtOne));
      expect(badStart.state.path, isEmpty);

      // Starting at checkpoint 1 (0, 0)
      final goodStart = GameEngine.handleCellInput(state, const Cell(0, 0));
      expect(goodStart.type, equals(MoveResultType.started));
      expect(goodStart.state.path, equals([const Cell(0, 0)]));
      expect(goodStart.state.nextRequiredCheckpoint, equals(2));
      expect(goodStart.state.status, equals(GameStatus.playing));
    });

    test('Out of bounds moves are rejected', () {
      final state = GameState.initial(puzzle);
      final result = GameEngine.handleCellInput(state, const Cell(-1, 0));
      expect(result.type, equals(MoveResultType.invalidOutOfBounds));
    });

    test('Diagonal moves are strictly prohibited', () {
      var state = GameState.initial(puzzle);
      state = GameEngine.handleCellInput(state, const Cell(0, 0)).state;

      // Attempt diagonal move to (1, 1)
      final diagResult = GameEngine.handleCellInput(state, const Cell(1, 1));
      expect(diagResult.type, equals(MoveResultType.invalidNotAdjacent));
      expect(state.path.length, equals(1));
    });

    test('Revisiting an already visited cell is prohibited', () {
      var state = GameState.initial(puzzle);
      state = GameEngine.handleCellInput(state, const Cell(0, 0)).state;
      state = GameEngine.handleCellInput(state, const Cell(0, 1)).state;
      state = GameEngine.handleCellInput(state, const Cell(0, 2)).state;

      // Try to re-enter (0, 1) from (0, 2)
      // Note: (0, 1) is previousCell, so re-entering previous cell is backtracking!
      // To test non-backtrack revisiting, let's create a loop attempt:
      // (0,0)->(0,1)->(0,2)->(1,2)->(1,1)->(1,0)->try (0,0)
      state = GameEngine.handleCellInput(state, const Cell(0, 3)).state;
      state = GameEngine.handleCellInput(state, const Cell(1, 3)).state;
      state = GameEngine.handleCellInput(state, const Cell(1, 2)).state;

      // Now at (1, 2). (0, 2) is adjacent and visited, but NOT previousCell (which is 1, 3).
      final revisitResult = GameEngine.handleCellInput(state, const Cell(0, 2));
      expect(revisitResult.type, equals(MoveResultType.invalidAlreadyVisited));
    });

    test('Backtracking by moving to immediately previous cell', () {
      var state = GameState.initial(puzzle);
      state = GameEngine.handleCellInput(state, const Cell(0, 0)).state;
      state = GameEngine.handleCellInput(state, const Cell(0, 1)).state;
      expect(state.path.length, equals(2));
      expect(state.headCell, equals(const Cell(0, 1)));

      // Tap or move to previous cell (0, 0)
      final backtrackResult = GameEngine.handleCellInput(
        state,
        const Cell(0, 0),
      );
      expect(backtrackResult.type, equals(MoveResultType.backtracked));
      expect(backtrackResult.state.path.length, equals(1));
      expect(backtrackResult.state.headCell, equals(const Cell(0, 0)));
    });

    test('Checkpoint sequencing: cannot skip checkpoint numbers', () {
      // Create a test scenario where checkpoint 3 is adjacent to head before checkpoint 2 is visited
      var state = GameState.initial(puzzle);
      state = GameEngine.handleCellInput(
        state,
        const Cell(0, 0),
      ).state; // CP 1 visited, next is 2

      // If user reaches CP 3 cell (3, 0) before CP 2 (1, 1), it must be rejected!
      // In easy1, (1, 0) is adjacent to (0, 0). (2, 0) adjacent to (1,0). (3, 0) is CP 3!
      state = GameEngine.handleCellInput(state, const Cell(1, 0)).state;
      state = GameEngine.handleCellInput(state, const Cell(2, 0)).state;

      // At (2, 0). Next cell is (3, 0) which is checkpoint 3, but next required checkpoint is 2!
      final cpSkipResult = GameEngine.handleCellInput(state, const Cell(3, 0));
      expect(
        cpSkipResult.type,
        equals(MoveResultType.invalidSkippedCheckpoint),
      );
      expect(cpSkipResult.state.path.length, equals(3));
    });

    test(
      'Winning: complete solution playthrough leads to GameStatus.completed',
      () {
        var state = GameState.initial(puzzle);

        for (int i = 0; i < puzzle.solution.length; i++) {
          final cell = puzzle.solution[i];
          final result = GameEngine.handleCellInput(state, cell);
          state = result.state;

          if (i == puzzle.solution.length - 1) {
            expect(result.type, equals(MoveResultType.completed));
            expect(state.status, equals(GameStatus.completed));
            expect(state.isCompleted, isTrue);
          } else {
            expect(result.isValid, isTrue);
          }
        }

        expect(state.path.length, equals(puzzle.totalCells));
        expect(
          state.nextRequiredCheckpoint,
          greaterThan(puzzle.totalCheckpoints),
        );
      },
    );

    test('Hint logic highlights next unvisited cell from solution', () {
      var state = GameState.initial(puzzle);

      // Before start, hint suggests start cell (0, 0)
      final hint1 = GameEngine.getNextHintCell(puzzle, state);
      expect(hint1, equals(puzzle.solution[0]));

      state = GameEngine.handleCellInput(state, const Cell(0, 0)).state;
      final hint2 = GameEngine.getNextHintCell(puzzle, state);
      expect(hint2, equals(puzzle.solution[1]));

      // Applying hint increments hintsUsed
      final hintedState = GameEngine.applyHint(state);
      expect(hintedState.hintsUsed, equals(1));
      expect(hintedState.hintCell, equals(puzzle.solution[1]));
    });

    test('Reset clears game back to initial state', () {
      var state = GameState.initial(puzzle);
      state = GameEngine.handleCellInput(state, const Cell(0, 0)).state;
      state = GameEngine.handleCellInput(state, const Cell(0, 1)).state;

      final resetState = GameEngine.reset(puzzle);
      expect(resetState.path, isEmpty);
      expect(resetState.status, equals(GameStatus.initial));
      expect(resetState.nextRequiredCheckpoint, equals(1));
    });
  });
}
