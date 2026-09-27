// lib/data/leaderboard_entry.dart
//
// Immutable model for a single leaderboard row.

import 'package:flutter/foundation.dart';

@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.totalPoints,
    required this.puzzlesSolved,
  });

  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;
  final int totalPoints;
  final int puzzlesSolved;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntry &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          totalPoints == other.totalPoints;

  @override
  int get hashCode => Object.hash(userId, totalPoints);
}
