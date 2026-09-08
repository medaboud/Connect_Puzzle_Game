import 'cell.dart';
import 'puzzle.dart';

/// Predefined, validated practice puzzles for Loopline.
class PuzzleLibrary {
  const PuzzleLibrary._();

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

  // --- EASY PUZZLES ---

  static Puzzle get easy1 {
    final solution = _generateSnakeRowPath(4, 4);
    return Puzzle(
      id: 'practice_easy_1',
      title: 'First Steps',
      difficulty: PuzzleDifficulty.easy,
      rows: 4,
      cols: 4,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[6], // (1, 1)
        3: solution[15], // (3, 0)
      },
      solution: solution,
    );
  }

  static Puzzle get easy2 {
    final solution = _generateSnakeColPath(4, 4);
    return Puzzle(
      id: 'practice_easy_2',
      title: 'River Run',
      difficulty: PuzzleDifficulty.easy,
      rows: 4,
      cols: 4,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[5], // (2, 1)
        3: solution[9], // (1, 2)
        4: solution[15], // (0, 3)
      },
      solution: solution,
    );
  }

  static Puzzle get easy3 {
    final solution = _generateSnakeRowPath(5, 5);
    return Puzzle(
      id: 'practice_easy_3',
      title: 'Meadow Path',
      difficulty: PuzzleDifficulty.easy,
      rows: 5,
      cols: 5,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[7], // (1, 2)
        3: solution[14], // (2, 4)
        4: solution[24], // (4, 4)
      },
      solution: solution,
    );
  }

  // --- MEDIUM PUZZLES ---

  static Puzzle get medium1 {
    final solution = _generateSnakeColPath(5, 5);
    return Puzzle(
      id: 'practice_medium_1',
      title: 'Cobalt Circuit',
      difficulty: PuzzleDifficulty.medium,
      rows: 5,
      cols: 5,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[6], // (3, 1)
        3: solution[12], // (2, 2)
        4: solution[18], // (1, 3)
        5: solution[24], // (4, 4)
      },
      solution: solution,
    );
  }

  static Puzzle get medium2 {
    final solution = _generateSnakeRowPath(6, 6);
    return Puzzle(
      id: 'practice_medium_2',
      title: 'Woven Ribbon',
      difficulty: PuzzleDifficulty.medium,
      rows: 6,
      cols: 6,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[8], // (1, 3)
        3: solution[16], // (2, 4)
        4: solution[21], // (3, 2)
        5: solution[35], // (5, 0)
      },
      solution: solution,
    );
  }

  static Puzzle get medium3 {
    final solution = _generateSnakeColPath(6, 6);
    return Puzzle(
      id: 'practice_medium_3',
      title: 'Labyrinth',
      difficulty: PuzzleDifficulty.medium,
      rows: 6,
      cols: 6,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[8], // (3, 1)
        3: solution[14], // (2, 2)
        4: solution[19], // (4, 3)
        5: solution[26], // (2, 4)
        6: solution[35], // (0, 5)
      },
      solution: solution,
    );
  }

  // --- HARD PUZZLES ---

  static Puzzle get hard1 {
    final solution = _generateSnakeRowPath(6, 6);
    return Puzzle(
      id: 'practice_hard_1',
      title: 'Perimeter Sweep',
      difficulty: PuzzleDifficulty.hard,
      rows: 6,
      cols: 6,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[5], // (0, 5)
        3: solution[11], // (1, 0)
        4: solution[17], // (2, 5)
        5: solution[23], // (3, 0)
        6: solution[29], // (4, 5)
        7: solution[35], // (5, 0)
      },
      solution: solution,
    );
  }

  static Puzzle get hard2 {
    final solution = _generateSnakeRowPath(7, 7);
    return Puzzle(
      id: 'practice_hard_2',
      title: 'The Great Grid',
      difficulty: PuzzleDifficulty.hard,
      rows: 7,
      cols: 7,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[8], // (1, 5)
        3: solution[16], // (2, 2)
        4: solution[24], // (3, 3)
        5: solution[32], // (4, 4)
        6: solution[40], // (5, 1)
        7: solution[48], // (6, 6)
      },
      solution: solution,
    );
  }

  static Puzzle get hard3 {
    final solution = _generateSnakeColPath(7, 7);
    return Puzzle(
      id: 'practice_hard_3',
      title: 'Master Weaver',
      difficulty: PuzzleDifficulty.hard,
      rows: 7,
      cols: 7,
      checkpoints: {
        1: solution[0], // (0, 0)
        2: solution[7], // (6, 1)
        3: solution[14], // (0, 2)
        4: solution[21], // (6, 3)
        5: solution[28], // (0, 4)
        6: solution[35], // (6, 5)
        7: solution[42], // (0, 6)
        8: solution[48], // (6, 6)
      },
      solution: solution,
    );
  }

  /// All practice puzzles grouped by difficulty.
  static List<Puzzle> get allPracticePuzzles => [
    easy1,
    easy2,
    easy3,
    medium1,
    medium2,
    medium3,
    hard1,
    hard2,
    hard3,
  ];

  static List<Puzzle> getByDifficulty(PuzzleDifficulty difficulty) {
    return allPracticePuzzles.where((p) => p.difficulty == difficulty).toList();
  }

  static Puzzle? getById(String id) {
    for (final p in allPracticePuzzles) {
      if (p.id == id) return p;
    }
    return null;
  }
}
