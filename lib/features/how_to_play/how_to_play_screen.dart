import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Play')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            const Text(
              'The Goal of Loopline',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Draw a single continuous line that connects every cell on the grid while visiting numbered checkpoints in order.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            _RuleCard(
              number: '1',
              title: 'Start at Checkpoint 1',
              description:
                  'Every puzzle begins by touching or dragging from the circle labeled "1".',
              icon: Icons.play_circle_outline_rounded,
              accentColor: AppColors.coralCheckpoint,
            ),
            const SizedBox(height: 16),
            _RuleCard(
              number: '2',
              title: 'Cover Every Cell',
              description:
                  'Your line must cover every single square on the board exactly once. No empty cells can remain when you reach the end.',
              icon: Icons.grid_on_rounded,
              accentColor: AppColors.cobaltPath,
            ),
            const SizedBox(height: 16),
            _RuleCard(
              number: '3',
              title: 'Sequential Order',
              description:
                  'Pass through numbered checkpoints in ascending order (1 → 2 → 3...). You cannot enter checkpoint 3 until you have visited checkpoint 2.',
              icon: Icons.format_list_numbered_rounded,
              accentColor: AppColors.hintGold,
            ),
            const SizedBox(height: 16),
            _RuleCard(
              number: '4',
              title: 'No Diagonals or Crossing',
              description:
                  'Moves must be orthogonal (up, down, left, right). You cannot cut diagonally, branch out, or cross your own path.',
              icon: Icons.do_not_disturb_on_outlined,
              accentColor: AppColors.invalidRed,
            ),
            const SizedBox(height: 16),
            _RuleCard(
              number: '5',
              title: 'Easy Backtracking',
              description:
                  'Made a mistake? Simply drag backward onto the previous cell or tap the Undo button to step back without starting over.',
              icon: Icons.undo_rounded,
              accentColor: AppColors.completedGreen,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Got it, let\'s play!'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const _RuleCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
