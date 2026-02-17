import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'level_manager.dart';

class ConnectPuzzleGame extends FlameGame
    with PanDetector, HasCollisionDetection {

  late LevelManager levelManager;

  @override
  Future<void> onLoad() async {
    levelManager = LevelManager();
    add(levelManager.currentLevelComponent);
  }

  @override
  void onPanStart(DragStartInfo info) {
    levelManager.handlePanStart(info.eventPosition.widget);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    levelManager.handlePanUpdate(info.eventPosition.widget);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    levelManager.handlePanEnd();
  }
}
