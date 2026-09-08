import 'package:flutter_test/flutter_test.dart';
import 'package:connect_puzzle_game/game/daily_puzzle.dart';
import 'package:connect_puzzle_game/game/game_engine.dart';
import 'package:connect_puzzle_game/game/game_state.dart';
import 'package:connect_puzzle_game/game/puzzle_library.dart';
import 'package:connect_puzzle_game/game/puzzle_validator.dart';

void main() {
  group('Puzzle Validation & Full Playthrough Tests', () {
    test('All bundled practice puzzles pass validator', () {
      for (final puzzle in PuzzleLibrary.allPracticePuzzles) {
        final errors = PuzzleValidator.validate(puzzle);
        expect(
          errors,
          isEmpty,
          reason: 'Puzzle ${puzzle.id} failed validation: $errors',
        );
      }
    });

    test('All bundled practice puzzles can be fully solved programmatically', () {
      for (final puzzle in PuzzleLibrary.allPracticePuzzles) {
        var state = GameState.initial(puzzle);

        for (final cell in puzzle.solution) {
          final result = GameEngine.handleCellInput(state, cell);
          expect(
            result.isValid,
            isTrue,
            reason:
                'Failed step at $cell for puzzle ${puzzle.id}. Reason: ${result.message}',
          );
          state = result.state;
        }

        expect(
          state.isCompleted,
          isTrue,
          reason: 'Puzzle ${puzzle.id} did not complete',
        );
      }
    });

    test(
      'Daily puzzles across a full month pass validator and can be solved',
      () {
        final baseDate = DateTime(2026, 9, 1);

        for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
          final testDate = baseDate.add(Duration(days: dayOffset));
          final daily = DailyPuzzle.getForDate(testDate);

          final errors = PuzzleValidator.validate(daily);
          expect(
            errors,
            isEmpty,
            reason: 'Daily puzzle for $testDate failed validation: $errors',
          );

          // Verify programmatic solve
          var state = GameState.initial(daily);
          for (final cell in daily.solution) {
            final result = GameEngine.handleCellInput(state, cell);
            expect(result.isValid, isTrue);
            state = result.state;
          }
          expect(state.isCompleted, isTrue);
        }
      },
    );
  });
}
