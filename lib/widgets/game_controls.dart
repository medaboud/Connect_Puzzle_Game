import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GameControls extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final VoidCallback onHint;
  final bool canUndo;
  final int hintsUsed;

  const GameControls({
    super.key,
    required this.onUndo,
    required this.onReset,
    required this.onHint,
    required this.canUndo,
    required this.hintsUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reset Button
          _ControlButton(
            icon: Icons.refresh_rounded,
            label: 'Restart',
            onTap: onReset,
          ),
          // Undo Button
          _ControlButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: canUndo ? onUndo : null,
          ),
          // Hint Button
          _ControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: hintsUsed > 0 ? 'Hint ($hintsUsed)' : 'Hint',
            accentColor: AppColors.hintGold,
            onTap: onHint,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? accentColor;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = isEnabled
        ? (accentColor ?? AppColors.textInk)
        : AppColors.textLight.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isEnabled
              ? Theme.of(context).cardTheme.color
              : AppColors.cellBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? (accentColor?.withValues(alpha: 0.4) ?? AppColors.cellBorder)
                : AppColors.cellBorder.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
