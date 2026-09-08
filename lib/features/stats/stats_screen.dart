import 'package:flutter/material.dart';
import '../../data/game_repository.dart';
import '../../data/player_stats.dart';
import '../../theme/app_colors.dart';

class StatsScreen extends StatefulWidget {
  final GameRepository repository;

  const StatsScreen({super.key, required this.repository});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  PlayerStats _stats = const PlayerStats();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await widget.repository.loadStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content: const Text(
          'This will clear all your streaks, solved puzzle history, and best times. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.invalidRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.resetAllStats();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All stats have been reset.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                children: [
                  // Streak Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.coralLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.coralCheckpoint.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StreakCol(
                          title: 'CURRENT STREAK',
                          value: '${_stats.currentStreak}',
                          subtitle: 'days',
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.coralCheckpoint,
                        ),
                        Container(
                          width: 1,
                          height: 48,
                          color: AppColors.cellBorder,
                        ),
                        _StreakCol(
                          title: 'BEST STREAK',
                          value: '${_stats.maxStreak}',
                          subtitle: 'days',
                          icon: Icons.emoji_events_rounded,
                          color: AppColors.hintGold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Games Solved Summary
                  const Text(
                    'Puzzles Solved',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Daily Solved',
                          value: '${_stats.dailyPuzzlesCompleted}',
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.cobaltPath,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Practice Solved',
                          value: '${_stats.practicePuzzlesCompleted}',
                          icon: Icons.grid_view_rounded,
                          color: AppColors.completedGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Best Times
                  const Text(
                    'Best Completion Times',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Column(
                        children: [
                          _RecordRow(
                            difficulty: 'Easy (4×4 - 5×5)',
                            time: _formatTime(_stats.bestTimes['easy']),
                          ),
                          const Divider(height: 16),
                          _RecordRow(
                            difficulty: 'Medium (5×5 - 6×6)',
                            time: _formatTime(_stats.bestTimes['medium']),
                          ),
                          const Divider(height: 16),
                          _RecordRow(
                            difficulty: 'Hard (6×6 - 7×7)',
                            time: _formatTime(_stats.bestTimes['hard']),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Reset Stats Button
                  OutlinedButton.icon(
                    onPressed: _confirmReset,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Reset Statistics'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.invalidRed,
                      side: const BorderSide(color: AppColors.cellBorder),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

class _StreakCol extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StreakCol({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final String difficulty;
  final String time;

  const _RecordRow({required this.difficulty, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          difficulty,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.cobaltPath,
          ),
        ),
      ],
    );
  }
}
