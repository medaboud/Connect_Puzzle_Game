import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/puzzle.dart';
import 'player_stats.dart';
import 'user_preferences.dart';

abstract class GameRepository {
  Future<UserPreferences> loadPreferences();
  Future<void> savePreferences(UserPreferences preferences);

  Future<PlayerStats> loadStats();
  Future<void> saveStats(PlayerStats stats);

  Future<PlayerStats> recordGameWon({
    required Puzzle puzzle,
    required int elapsedSeconds,
    required int movesCount,
  });

  Future<String?> loadActiveGameState(String puzzleId);
  Future<void> saveActiveGameState(String puzzleId, String serializedState);
  Future<void> clearActiveGameState(String puzzleId);

  Future<void> resetAllStats();
}

class SharedPrefsGameRepository implements GameRepository {
  static const String _prefPrefix = 'loopline_';
  final String userId;

  const SharedPrefsGameRepository({this.userId = 'default_local'});

  String _key(String suffix) => '$_prefPrefix${userId}_$suffix';

  @override
  Future<UserPreferences> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key('preferences'));
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return UserPreferences.fromJson(decoded);
        }
      }
    } catch (_) {
      // Fallback gracefully on corrupt or missing data
    }
    return const UserPreferences();
  }

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key('preferences'),
        jsonEncode(preferences.toJson()),
      );
    } catch (_) {}
  }

  @override
  Future<PlayerStats> loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key('stats'));
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return PlayerStats.fromJson(decoded);
        }
      }
    } catch (_) {}
    return const PlayerStats();
  }

  @override
  Future<void> saveStats(PlayerStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key('stats'), jsonEncode(stats.toJson()));
    } catch (_) {}
  }

  @override
  Future<PlayerStats> recordGameWon({
    required Puzzle puzzle,
    required int elapsedSeconds,
    required int movesCount,
  }) async {
    final currentStats = await loadStats();
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    int newStreak = currentStats.currentStreak;
    int newMaxStreak = currentStats.maxStreak;
    int newDailyCount = currentStats.dailyPuzzlesCompleted;
    int newPracticeCount = currentStats.practicePuzzlesCompleted;

    if (puzzle.isDaily) {
      if (currentStats.lastCompletedDate == null) {
        newStreak = 1;
      } else {
        final parts = currentStats.lastCompletedDate!
            .split('-')
            .map(int.parse)
            .toList();
        final lastDate = DateTime(parts[0], parts[1], parts[2]);
        final diffDays = DateTime(
          now.year,
          now.month,
          now.day,
        ).difference(lastDate).inDays;

        if (diffDays == 1) {
          newStreak += 1;
        } else if (diffDays == 0) {
          // Already solved today or another puzzle on same day: keep streak
        } else {
          // Streak broken
          newStreak = 1;
        }
      }
      if (newStreak > newMaxStreak) {
        newMaxStreak = newStreak;
      }
      if (!currentStats.isPuzzleCompleted(puzzle.id)) {
        newDailyCount += 1;
      }
    } else {
      if (!currentStats.isPuzzleCompleted(puzzle.id)) {
        newPracticeCount += 1;
      }
    }

    // Update best time for this difficulty
    final updatedBestTimes = Map<String, int>.from(currentStats.bestTimes);
    final diffKey = puzzle.difficulty.name;
    final previousBest = updatedBestTimes[diffKey];
    if (previousBest == null || elapsedSeconds < previousBest) {
      updatedBestTimes[diffKey] = elapsedSeconds;
    }

    final updatedCompletedIds = Set<String>.from(
      currentStats.completedPuzzleIds,
    )..add(puzzle.id);

    final updatedStats = currentStats.copyWith(
      currentStreak: newStreak,
      maxStreak: newMaxStreak,
      lastCompletedDate: todayKey,
      dailyPuzzlesCompleted: newDailyCount,
      practicePuzzlesCompleted: newPracticeCount,
      bestTimes: updatedBestTimes,
      completedPuzzleIds: updatedCompletedIds,
    );

    await saveStats(updatedStats);
    await clearActiveGameState(puzzle.id);

    return updatedStats;
  }

  @override
  Future<String?> loadActiveGameState(String puzzleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key('active_$puzzleId'));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveActiveGameState(
    String puzzleId,
    String serializedState,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key('active_$puzzleId'), serializedState);
    } catch (_) {}
  }

  @override
  Future<void> clearActiveGameState(String puzzleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key('active_$puzzleId'));
    } catch (_) {}
  }

  @override
  Future<void> resetAllStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_prefPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }
}
