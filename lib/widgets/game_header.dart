import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../game/puzzle.dart';
import '../theme/app_colors.dart';

class GameHeader extends StatelessWidget {
  final Puzzle puzzle;
  final GameState state;
  final VoidCallback onPauseTapped;
  final VoidCallback onBackPressed;

  const GameHeader({
    super.key,
    required this.puzzle,
    required this.state,
    required this.onPauseTapped,
    required this.onBackPressed,
  });

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                tooltip: 'Back',
                onPressed: onBackPressed,
              ),
              Column(
                children: [
                  Text(
                    puzzle.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cellActive,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${puzzle.difficulty.displayName} • ${puzzle.rows}×${puzzle.cols}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cobaltPath,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  state.status == GameStatus.paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  size: 26,
                ),
                tooltip: state.status == GameStatus.paused ? 'Resume' : 'Pause',
                onPressed: onPauseTapped,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row: Timer, Moves, Progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cellBorder, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.timer_outlined,
                  label: 'TIME',
                  value: _formatTimer(state.elapsedSeconds),
                ),
                Container(width: 1, height: 28, color: AppColors.cellBorder),
                _StatItem(
                  icon: Icons.touch_app_outlined,
                  label: 'MOVES',
                  value: state.movesCount.toString(),
                ),
                Container(width: 1, height: 28, color: AppColors.cellBorder),
                _StatItem(
                  icon: Icons.flag_outlined,
                  label: 'TARGET',
                  value: state.nextRequiredCheckpoint <= puzzle.totalCheckpoints
                      ? '#${state.nextRequiredCheckpoint}'
                      : 'FINISH',
                  accentColor: AppColors.coralCheckpoint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor ?? AppColors.textMuted),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textLight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentColor ?? AppColors.textInk,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
