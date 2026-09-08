import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connect_puzzle_game/data/game_repository.dart';
import 'package:connect_puzzle_game/data/user_preferences.dart';
import 'package:connect_puzzle_game/main.dart';
import 'package:connect_puzzle_game/widgets/board_widget.dart';
import 'package:connect_puzzle_game/widgets/game_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Loopline App smoke and navigation test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const repository = SharedPrefsGameRepository(userId: 'test_user');
    const preferences = UserPreferences(reducedMotion: true);

    await tester.pumpWidget(
      const LooplineApp(
        repository: repository,
        initialPreferences: preferences,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Home Screen elements
    expect(find.text('Loopline'), findsOneWidget);
    expect(find.text('Practice Mode'), findsOneWidget);
    expect(find.text('Player Statistics'), findsOneWidget);

    // Open Practice Mode
    await tester.tap(find.text('Practice Mode'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // Finish route push

    expect(find.text('Practice Puzzles'), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);

    // Tap the first practice puzzle
    await tester.tap(find.text('First Steps'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // Finish route push

    // Verify PlayScreen elements
    expect(find.byType(GameHeader), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('MOVES'), findsOneWidget);
    expect(find.byType(BoardWidget), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);

    // Tap Hint button
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hint (1)'), findsOneWidget);

    // Tap Undo button
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Back button
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // Finish route pop

    // Returned to Practice Screen
    expect(find.text('Practice Puzzles'), findsOneWidget);
  });
}
