import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../models/position.dart';
import '../grid/grid_component.dart';

class PathComponent extends PositionComponent {
  final int gridSize;

  final List<Position> _path = [];

  late Paint _paint;

  GridComponent? grid;

  PathComponent({
    required this.gridSize,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _paint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
  }

  void attachGrid(GridComponent gridComponent) {
    grid = gridComponent;
  }

  void updatePath(List<Position> newPath) {
    _path
      ..clear()
      ..addAll(newPath);
  }

  void clearPath() {
    _path.clear();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_path.length < 2 || grid == null) return;

    final path = Path();

    final first =
    grid!.cellToWorldCenter(_path.first);
    path.moveTo(first.x, first.y);

    for (int i = 1; i < _path.length; i++) {
      final point =
      grid!.cellToWorldCenter(_path[i]);
      path.lineTo(point.x, point.y);
    }

    canvas.drawPath(path, _paint);
  }
}
