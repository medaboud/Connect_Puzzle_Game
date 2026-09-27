// lib/widgets/leaderboard_tile.dart
//
// A single row in the leaderboard list.
// Highlights the row that belongs to the currently signed-in user.

import 'package:flutter/material.dart';

import '../data/leaderboard_entry.dart';
import 'rank_badge.dart';

class LeaderboardTile extends StatelessWidget {
  const LeaderboardTile({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
  });

  final LeaderboardEntry entry;

  /// When true the row is highlighted so the player can easily find themselves.
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Semantics(
      label:
          'Rank ${entry.rank}, ${entry.name}, ${entry.totalPoints} points, '
          '${entry.puzzlesSolved} puzzles solved'
          '${isCurrentUser ? ', this is you' : ''}',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? cs.primaryContainer.withAlpha(100)
              : cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentUser
              ? Border.all(color: cs.primary, width: 1.5)
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: RankBadge(rank: entry.rank),
          title: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: entry.avatarUrl != null
                    ? NetworkImage(entry.avatarUrl!)
                    : null,
                child: entry.avatarUrl == null
                    ? Text(
                        entry.name.isNotEmpty
                            ? entry.name[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.titleSmall,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCurrentUser ? '${entry.name} (you)' : entry.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isCurrentUser
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalPoints} pts',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${entry.puzzlesSolved} solved',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
