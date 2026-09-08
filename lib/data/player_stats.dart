import 'package:flutter/foundation.dart';

@immutable
class PlayerStats {
  final int currentStreak;
  final int maxStreak;
  final String? lastCompletedDate; // 'YYYY-MM-DD'
  final int dailyPuzzlesCompleted;
  final int practicePuzzlesCompleted;
  final Map<String, int> bestTimes; // e.g. 'easy': 24, 'medium': 65
  final Set<String> completedPuzzleIds;

  const PlayerStats({
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.lastCompletedDate,
    this.dailyPuzzlesCompleted = 0,
    this.practicePuzzlesCompleted = 0,
    this.bestTimes = const {},
    this.completedPuzzleIds = const {},
  });

  int get totalSolved => dailyPuzzlesCompleted + practicePuzzlesCompleted;

  bool isPuzzleCompleted(String puzzleId) =>
      completedPuzzleIds.contains(puzzleId);

  PlayerStats copyWith({
    int? currentStreak,
    int? maxStreak,
    String? lastCompletedDate,
    int? dailyPuzzlesCompleted,
    int? practicePuzzlesCompleted,
    Map<String, int>? bestTimes,
    Set<String>? completedPuzzleIds,
  }) {
    return PlayerStats(
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      dailyPuzzlesCompleted:
          dailyPuzzlesCompleted ?? this.dailyPuzzlesCompleted,
      practicePuzzlesCompleted:
          practicePuzzlesCompleted ?? this.practicePuzzlesCompleted,
      bestTimes: bestTimes ?? this.bestTimes,
      completedPuzzleIds: completedPuzzleIds ?? this.completedPuzzleIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'maxStreak': maxStreak,
    'lastCompletedDate': lastCompletedDate,
    'dailyPuzzlesCompleted': dailyPuzzlesCompleted,
    'practicePuzzlesCompleted': practicePuzzlesCompleted,
    'bestTimes': bestTimes,
    'completedPuzzleIds': completedPuzzleIds.toList(),
  };

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    final bestMap =
        (json['bestTimes'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v as int),
        ) ??
        const {};

    final completedList =
        (json['completedPuzzleIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toSet() ??
        const <String>{};

    return PlayerStats(
      currentStreak: json['currentStreak'] as int? ?? 0,
      maxStreak: json['maxStreak'] as int? ?? 0,
      lastCompletedDate: json['lastCompletedDate'] as String?,
      dailyPuzzlesCompleted: json['dailyPuzzlesCompleted'] as int? ?? 0,
      practicePuzzlesCompleted: json['practicePuzzlesCompleted'] as int? ?? 0,
      bestTimes: bestMap,
      completedPuzzleIds: completedList,
    );
  }
}
