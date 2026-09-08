import 'package:flutter_test/flutter_test.dart';
import 'package:connect_puzzle_game/game/cell.dart';

void main() {
  group('Cell Model Tests', () {
    test('Cell equality and hashCode', () {
      const c1 = Cell(1, 2);
      const c2 = Cell(1, 2);
      const c3 = Cell(2, 1);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('Orthogonal adjacency', () {
      const center = Cell(2, 2);

      // Orthogonally adjacent
      expect(center.isAdjacent(const Cell(1, 2)), isTrue); // Up
      expect(center.isAdjacent(const Cell(3, 2)), isTrue); // Down
      expect(center.isAdjacent(const Cell(2, 1)), isTrue); // Left
      expect(center.isAdjacent(const Cell(2, 3)), isTrue); // Right

      // Diagonals must NOT be adjacent
      expect(center.isAdjacent(const Cell(1, 1)), isFalse);
      expect(center.isAdjacent(const Cell(1, 3)), isFalse);
      expect(center.isAdjacent(const Cell(3, 1)), isFalse);
      expect(center.isAdjacent(const Cell(3, 3)), isFalse);

      // Same cell
      expect(center.isAdjacent(const Cell(2, 2)), isFalse);

      // Distant cells
      expect(center.isAdjacent(const Cell(0, 2)), isFalse);
    });

    test('Bounds checking', () {
      const c = Cell(2, 3);
      expect(c.isInBounds(4, 4), isTrue);
      expect(c.isInBounds(2, 4), isFalse); // row 2 out of 2 (0..1)
      expect(c.isInBounds(3, 3), isFalse); // col 3 out of 3 (0..2)

      const negativeRow = Cell(-1, 2);
      expect(negativeRow.isInBounds(4, 4), isFalse);

      const negativeCol = Cell(2, -1);
      expect(negativeCol.isInBounds(4, 4), isFalse);
    });

    test('JSON serialization', () {
      const cell = Cell(3, 4);
      final json = cell.toJson();
      final restored = Cell.fromJson(json);

      expect(restored, equals(cell));
    });
  });
}
