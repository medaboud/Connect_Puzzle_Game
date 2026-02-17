class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Position &&
          other.row == row &&
          other.col == col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}
