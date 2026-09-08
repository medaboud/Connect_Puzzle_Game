import 'dart:convert';
import 'game_state.dart';
import 'puzzle.dart';

/// Handles safe JSON serialization and deserialization of GameState.
/// Resilient against corrupted or unexpected inputs.
class GameSerializer {
  const GameSerializer._();

  /// Serializes [state] to a JSON string.
  static String serialize(GameState state) {
    try {
      final map = state.toJson();
      return jsonEncode(map);
    } catch (_) {
      return '';
    }
  }

  /// Deserializes a JSON string back into a [GameState].
  /// If the data is corrupted, returns a fresh [GameState.initial(puzzle)].
  static GameState deserialize(String jsonString, Puzzle puzzle) {
    if (jsonString.isEmpty) {
      return GameState.initial(puzzle);
    }

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return GameState.initial(puzzle);
      }

      // Check puzzle id matches
      if (decoded['puzzleId'] != puzzle.id) {
        return GameState.initial(puzzle);
      }

      final restored = GameState.fromJson(decoded, puzzle);

      // Sanity check path validity: must start at checkpoint 1 and be contiguous
      if (restored.path.isNotEmpty) {
        if (restored.path.first != puzzle.checkpoints[1]) {
          return GameState.initial(puzzle);
        }

        for (int i = 0; i < restored.path.length - 1; i++) {
          final a = restored.path[i];
          final b = restored.path[i + 1];
          if (!a.isAdjacent(b) || !b.isInBounds(puzzle.rows, puzzle.cols)) {
            return GameState.initial(puzzle);
          }
        }
      }

      return restored;
    } catch (_) {
      // Graceful corrupt recovery
      return GameState.initial(puzzle);
    }
  }
}
