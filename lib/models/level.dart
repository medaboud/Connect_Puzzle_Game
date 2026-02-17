import 'position.dart';

class Level {
  final int gridSize;
  final Map<int, Position> numberPositions;

  Level({
    required this.gridSize,
    required this.numberPositions,
  });

  static Level sample() {
    return Level(
      gridSize: 5,
      numberPositions: {
        1: const Position(0, 0),
        2: const Position(2, 1),
        3: const Position(4, 4),
      },
    );
  }

  int? getNumberAt(Position pos) {
    for (final entry in numberPositions.entries) {
      if (entry.value == pos) {
        return entry.key;
      }
    }
    return null;
  }

  int get maxNumber => numberPositions.length;
}
