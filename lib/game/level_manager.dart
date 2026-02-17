import 'package:flame/components.dart';

import '../models/level.dart';
import '../models/position.dart';
import '../components/grid/grid_component.dart';
import '../components/path/path_component.dart';

enum GameStatus {
  idle,
  drawing,
  completed,
  failed,
}

class LevelManager {
  late Level _currentLevel;
  late GridComponent _gridComponent;
  late PathComponent _pathComponent;

  GameStatus status = GameStatus.idle;

  int _currentTargetNumber = 1;
  final List<Position> _currentPath = [];

  /// Public getter used by ConnectPuzzleGame
  Component get currentLevelComponent =>
      Component(children: [_gridComponent, _pathComponent]);

  LevelManager() {
    _loadLevel();
  }

  void _loadLevel() {
    _currentLevel = Level.sample(); // static for now

    _gridComponent = GridComponent(
      gridSize: _currentLevel.gridSize,
      numberPositions: _currentLevel.numberPositions,
    );

    _pathComponent = PathComponent(
      gridSize: _currentLevel.gridSize,
    );

    _resetState();
  }

  void _resetState() {
    status = GameStatus.idle;
    _currentTargetNumber = 1;
    _currentPath.clear();
    _pathComponent.clearPath();
  }

  /* ===========================
        INPUT HANDLING
     =========================== */

  void handlePanStart(Vector2 gamePosition) {
    if (status == GameStatus.completed) return;

    final cell = _gridComponent.worldToCell(gamePosition);
    if (cell == null) return;

    if (!_isStartingCell(cell)) return;

    status = GameStatus.drawing;

    _currentPath.add(cell);
    _pathComponent.updatePath(_currentPath);

    _advanceTargetIfNumber(cell);
  }

  void handlePanUpdate(Vector2 gamePosition) {
    if (status != GameStatus.drawing) return;

    final cell = _gridComponent.worldToCell(gamePosition);
    if (cell == null) return;

    if (!_canAddCell(cell)) return;

    _currentPath.add(cell);
    _pathComponent.updatePath(_currentPath);

    _advanceTargetIfNumber(cell);

    if (_checkWin()) {
      status = GameStatus.completed;
    }
  }

  void handlePanEnd() {
    if (status == GameStatus.drawing &&
        status != GameStatus.completed) {
      _resetState();
    }
  }

  /* ===========================
        VALIDATION LOGIC
     =========================== */

  bool _isStartingCell(Position cell) {
    final number = _currentLevel.getNumberAt(cell);
    return number == 1;
  }

  bool _canAddCell(Position next) {
    if (_currentPath.contains(next)) return false;

    if (!_isAdjacent(_currentPath.last, next)) return false;

    final number = _currentLevel.getNumberAt(next);

    if (number != null && number != _currentTargetNumber) {
      return false;
    }

    return true;
  }

  void _advanceTargetIfNumber(Position cell) {
    final number = _currentLevel.getNumberAt(cell);

    if (number == _currentTargetNumber) {
      _currentTargetNumber++;
    }
  }

  bool _checkWin() {
    final totalCells =
        _currentLevel.gridSize * _currentLevel.gridSize;

    return _currentPath.length == totalCells &&
        _currentTargetNumber >
            _currentLevel.maxNumber;
  }

  bool _isAdjacent(Position a, Position b) {
    final dx = (a.col - b.col).abs();
    final dy = (a.row - b.row).abs();
    return (dx + dy) == 1;
  }
}
