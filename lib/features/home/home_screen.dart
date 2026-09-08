import 'package:flutter/material.dart';
import '../../data/game_repository.dart';
import '../../data/player_stats.dart';
import '../../game/daily_puzzle.dart';
import '../../theme/app_colors.dart';
import '../how_to_play/how_to_play_screen.dart';
import '../play/play_screen.dart';
import '../practice/practice_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  final GameRepository repository;

  const HomeScreen({super.key, required this.repository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PlayerStats _stats = const PlayerStats();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await widget.repository.loadStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _playToday() {
    final dailyPuzzle = DailyPuzzle.getForDate();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                PlayScreen(puzzle: dailyPuzzle, repository: widget.repository),
          ),
        )
        .then((_) => _loadData());
  }

  void _openPractice() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PracticeScreen(repository: widget.repository),
          ),
        )
        .then((_) => _loadData());
  }

  void _openStats() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => StatsScreen(repository: widget.repository),
          ),
        )
        .then((_) => _loadData());
  }

  void _openHowToPlay() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HowToPlayScreen()));
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daily = DailyPuzzle.getForDate();
    final isDailyCompleted = _stats.isPuzzleCompleted(daily.id);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                children: [
                  // Top Navigation Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.cobaltPath,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.gesture_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Loopline',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.help_outline_rounded),
                            tooltip: 'How to play',
                            onPressed: _openHowToPlay,
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            tooltip: 'Settings',
                            onPressed: _openSettings,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Play Today - Hero Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDailyCompleted
                            ? AppColors.completedGreen.withValues(alpha: 0.5)
                            : AppColors.cobaltPath.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cellActive,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  daily.title.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    color: AppColors.cobaltPath,
                                  ),
                                ),
                              ),
                              if (_stats.currentStreak > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.coralLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 16,
                                        color: AppColors.coralCheckpoint,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_stats.currentStreak} day streak',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.coralCheckpoint,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isDailyCompleted
                                ? 'Daily Solved!'
                                : 'Today\'s Puzzle',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isDailyCompleted
                                ? 'Great job! You\'ve completed today\'s challenge.'
                                : '${daily.rows}×${daily.cols} grid • ${daily.difficulty.displayName} difficulty',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _playToday,
                            icon: Icon(
                              isDailyCompleted
                                  ? Icons.replay_rounded
                                  : Icons.play_arrow_rounded,
                              size: 20,
                            ),
                            label: Text(
                              isDailyCompleted ? 'Replay Today' : 'Play Today',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: isDailyCompleted
                                  ? AppColors.textInk
                                  : AppColors.cobaltPath,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Practice Puzzles Card
                  Card(
                    child: InkWell(
                      onTap: _openPractice,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.cellActive,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                color: AppColors.cobaltPath,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Practice Mode',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_stats.practicePuzzlesCompleted} completed',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Snapshot Card
                  Card(
                    child: InkWell(
                      onTap: _openStats,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.coralLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.bar_chart_rounded,
                                color: AppColors.coralCheckpoint,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Player Statistics',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_stats.totalSolved} total solved • ${_stats.currentStreak} day streak',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}
