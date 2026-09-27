// lib/widgets/rank_badge.dart
//
// Displays 🥇 🥈 🥉 for rank 1–3, or a numeric chip for rank 4+.

import 'package:flutter/material.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank});

  final int rank;

  static const _medals = {1: '🥇', 2: '🥈', 3: '🥉'};

  @override
  Widget build(BuildContext context) {
    final medal = _medals[rank];
    if (medal != null) {
      return SizedBox(
        width: 36,
        child: Text(
          medal,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22),
        ),
      );
    }
    return Container(
      width: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        '$rank',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
