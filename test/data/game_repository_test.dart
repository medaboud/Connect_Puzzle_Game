import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connect_puzzle_game/data/game_repository.dart';
import 'package:connect_puzzle_game/data/user_preferences.dart';
import 'package:connect_puzzle_game/game/puzzle_library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPrefsGameRepository Tests', () {
    late SharedPrefsGameRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = const SharedPrefsGameRepository(userId: 'test_user');
    });

    test('Preferences load default and can be saved and loaded', () async {
      final defaultPrefs = await repository.loadPreferences();
      expect(defaultPrefs.hapticsEnabled, isTrue);
      expect(defaultPrefs.tapToExtend, isTrue);

      const customPrefs = UserPreferences(
        hapticsEnabled: false,
        tapToExtend: false,
        reducedMotion: true,
      );
      await repository.savePreferences(customPrefs);

      final reloaded = await repository.loadPreferences();
      expect(reloaded.hapticsEnabled, isFalse);
      expect(reloaded.tapToExtend, isFalse);
      expect(reloaded.reducedMotion, isTrue);
    });

    test('Stats load default and record game completion', () async {
      final stats = await repository.loadStats();
      expect(stats.currentStreak, equals(0));
      expect(stats.dailyPuzzlesCompleted, equals(0));
      expect(stats.practicePuzzlesCompleted, equals(0));

      final puzzle = PuzzleLibrary.easy1;
      final updated = await repository.recordGameWon(
        puzzle: puzzle,
        elapsedSeconds: 45,
        movesCount: 16,
      );

      expect(updated.practicePuzzlesCompleted, equals(1));
      expect(updated.isPuzzleCompleted(puzzle.id), isTrue);
      expect(updated.bestTimes['easy'], equals(45));

      // Record a faster completion
      final faster = await repository.recordGameWon(
        puzzle: puzzle,
        elapsedSeconds: 30,
        movesCount: 16,
      );
      expect(faster.bestTimes['easy'], equals(30));
    });

    test('Active game state persistence and cleanup', () async {
      const puzzleId = 'test_puz_1';
      const stateJson = '{"puzzleId":"test_puz_1","path":[]}';

      await repository.saveActiveGameState(puzzleId, stateJson);
      final loaded = await repository.loadActiveGameState(puzzleId);
      expect(loaded, equals(stateJson));

      await repository.clearActiveGameState(puzzleId);
      final cleared = await repository.loadActiveGameState(puzzleId);
      expect(cleared, isNull);
    });
  });
}
