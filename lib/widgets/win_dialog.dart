import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_state.dart';
import '../game/puzzle.dart';
import '../theme/app_colors.dart';

class WinDialog extends StatelessWidget {
  final Puzzle puzzle;
  final GameState state;
  final int streak;
  final VoidCallback onReplay;
  final VoidCallback onNextOrHome;
  final String nextButtonLabel;

  const WinDialog({
    super.key,
    required this.puzzle,
    required this.state,
    required this.streak,
    required this.onReplay,
    required this.onNextOrHome,
    this.nextButtonLabel = 'Next Puzzle',
  });

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _shareResult(BuildContext context) {
    final timeStr = _formatTimer(state.elapsedSeconds);
    final streakText = puzzle.isDaily ? '\n🔥 Streak: $streak days' : '';
    final shareText =
        '''Loopline 🧩
${puzzle.title} (${puzzle.difficulty.displayName})
⏱️ Time: $timeStr
👟 Moves: ${state.movesCount}
💡 Hints: ${state.hintsUsed}$streakText''';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Result copied to clipboard! (No spoilers)'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy / Checkmark icon
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.cellActive,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.completedGreen,
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Puzzle Solved!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              puzzle.title,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Metrics Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cellBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WinStatItem(
                    label: 'TIME',
                    value: _formatTimer(state.elapsedSeconds),
                    icon: Icons.timer_outlined,
                  ),
                  _WinStatItem(
                    label: 'MOVES',
                    value: state.movesCount.toString(),
                    icon: Icons.touch_app_outlined,
                  ),
                  _WinStatItem(
                    label: 'HINTS',
                    value: state.hintsUsed.toString(),
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                  if (puzzle.isDaily)
                    _WinStatItem(
                      label: 'STREAK',
                      value: '$streak',
                      icon: Icons.local_fire_department_rounded,
                      accentColor: AppColors.coralCheckpoint,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Share Result Button
            OutlinedButton.icon(
              onPressed: () => _shareResult(context),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('Share Result'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: AppColors.cobaltPath, width: 1.5),
                foregroundColor: AppColors.cobaltPath,
              ),
            ),
            const SizedBox(height: 12),

            // Primary Action Button (Next / Home)
            FilledButton(
              onPressed: onNextOrHome,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(nextButtonLabel),
            ),
            const SizedBox(height: 8),

            // Replay Button
            TextButton(onPressed: onReplay, child: const Text('Replay Puzzle')),
          ],
        ),
      ),
    );
  }
}

class _WinStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;

  const _WinStatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: accentColor ?? AppColors.textMuted),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentColor ?? AppColors.textInk,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
