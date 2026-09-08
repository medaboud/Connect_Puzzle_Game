import 'package:flutter_test/flutter_test.dart';
import 'package:connect_puzzle_game/game/cell.dart';
import 'package:connect_puzzle_game/game/game_engine.dart';
import 'package:connect_puzzle_game/game/game_serializer.dart';
import 'package:connect_puzzle_game/game/game_state.dart';
import 'package:connect_puzzle_game/game/puzzle_library.dart';

void main() {
  group('GameSerializer Tests', () {
    final puzzle = PuzzleLibrary.easy1;

    test('Serializing and deserializing an in-progress game state', () {
      var state = GameState.initial(puzzle);
      state = GameEngine.handleCellInput(state, const Cell(0, 0)).state;
      state = GameEngine.handleCellInput(state, const Cell(0, 1)).state;
      state = state.copyWith(elapsedSeconds: 42, hintsUsed: 1);

      final jsonString = GameSerializer.serialize(state);
      expect(jsonString, isNotEmpty);

      final restored = GameSerializer.deserialize(jsonString, puzzle);
      expect(restored.path, equals(state.path));
      expect(restored.elapsedSeconds, equals(42));
      expect(restored.hintsUsed, equals(1));
      expect(restored.movesCount, equals(state.movesCount));
      expect(restored.status, equals(GameStatus.playing));
    });

    test('Gracefully recovers from corrupted or invalid JSON', () {
      // Complete gibberish
      final restoredFromGibberish = GameSerializer.deserialize(
        'NOT_VALID_JSON{:::}}',
        puzzle,
      );
      expect(restoredFromGibberish.status, equals(GameStatus.initial));
      expect(restoredFromGibberish.path, isEmpty);

      // Empty string
      final restoredFromEmpty = GameSerializer.deserialize('', puzzle);
      expect(restoredFromEmpty.status, equals(GameStatus.initial));

      // Mismatched puzzle id
      final jsonMismatchedId =
          '{"puzzleId":"some_other_puzzle","path":[],"status":"playing"}';
      final restoredMismatched = GameSerializer.deserialize(
        jsonMismatchedId,
        puzzle,
      );
      expect(restoredMismatched.puzzle.id, equals(puzzle.id));
      expect(restoredMismatched.status, equals(GameStatus.initial));

      // Disconnected / invalid path coordinates
      final invalidPathJson =
          '{"puzzleId":"${puzzle.id}","path":[{"row":0,"col":0},{"row":3,"col":3}],"status":"playing"}';
      final restoredInvalidPath = GameSerializer.deserialize(
        invalidPathJson,
        puzzle,
      );
      expect(restoredInvalidPath.path, isEmpty);
      expect(restoredInvalidPath.status, equals(GameStatus.initial));
    });
  });
}
