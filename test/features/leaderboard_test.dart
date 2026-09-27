import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:connect_puzzle_game/data/cloud_repository.dart';
import 'package:connect_puzzle_game/data/leaderboard_entry.dart';
import 'package:connect_puzzle_game/features/leaderboard/leaderboard_controller.dart';

void main() {
  group('LeaderboardEntry Model Tests', () {
    test('Equality and properties test', () {
      const entry1 = LeaderboardEntry(
        rank: 1,
        userId: 'u1',
        name: 'Alice',
        avatarUrl: 'https://example.com/avatar.jpg',
        totalPoints: 2500,
        puzzlesSolved: 5,
      );

      const entry2 = LeaderboardEntry(
        rank: 1,
        userId: 'u1',
        name: 'Alice',
        totalPoints: 2500,
        puzzlesSolved: 5,
      );

      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));
      expect(entry1.avatarUrl, isNotNull);
    });
  });

  group('CloudRepository & LeaderboardController Tests', () {
    test('Fetch global leaderboard correctly parses responses', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/leaderboard/global')) {
          return http.Response(
            jsonEncode({
              'page': 1,
              'entries': [
                {
                  'rank': 1,
                  'user_id': 'u1',
                  'name': 'Player One',
                  'avatar_url': null,
                  'total_points': 5000,
                  'puzzles_solved': 4,
                },
                {
                  'rank': 2,
                  'user_id': 'u2',
                  'name': 'Player Two',
                  'avatar_url': 'https://avatar.url',
                  'total_points': 3200,
                  'puzzles_solved': 3,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final cloudRepo = CloudRepository(client: mockClient);
      final controller = LeaderboardController(cloudRepository: cloudRepo);

      expect(controller.status, equals(LeaderboardStatus.idle));
      expect(controller.activeTab, equals(LeaderboardTab.global));

      await controller.load();

      expect(controller.status, equals(LeaderboardStatus.loaded));
      expect(controller.globalEntries.length, 2);
      expect(controller.globalEntries.first.name, 'Player One');
      expect(controller.globalEntries.first.rank, 1);
      expect(controller.globalEntries.first.totalPoints, 5000);
    });

    test('Friends leaderboard requires and passes JWT token', () async {
      String? capturedAuthHeader;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/leaderboard/friends')) {
          capturedAuthHeader = request.headers['Authorization'];
          return http.Response(
            jsonEncode({
              'entries': [
                {
                  'rank': 1,
                  'user_id': 'f1',
                  'name': 'Friend Bob',
                  'avatar_url': null,
                  'total_points': 1500,
                  'puzzles_solved': 2,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final cloudRepo = CloudRepository(client: mockClient);
      final controller = LeaderboardController(cloudRepository: cloudRepo);

      controller.switchTab(LeaderboardTab.friends);
      expect(controller.activeTab, equals(LeaderboardTab.friends));

      await controller.load(jwt: 'test-jwt-token');

      expect(capturedAuthHeader, equals('Bearer test-jwt-token'));
      expect(controller.status, equals(LeaderboardStatus.loaded));
      expect(controller.friendsEntries.length, 1);
      expect(controller.friendsEntries.first.name, 'Friend Bob');
    });

    test('Submit puzzle completion parses points earned', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/completions')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['puzzle_id'], 'daily_1');
          expect(body['difficulty'], 'daily');
          return http.Response(
            jsonEncode({
              'points_earned': 4200,
              'puzzle_id': 'daily_1',
              'message': 'Completion recorded',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final cloudRepo = CloudRepository(client: mockClient);
      final points = await cloudRepo.submitCompletion(
        jwt: 'jwt',
        puzzleId: 'daily_1',
        difficulty: 'daily',
        timeSeconds: 30,
        moveCount: 16,
        hintsUsed: 0,
      );

      expect(points, equals(4200));
    });
  });
}
