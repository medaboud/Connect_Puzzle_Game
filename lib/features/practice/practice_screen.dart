import 'package:flutter/material.dart';
import '../../data/game_repository.dart';
import '../../data/player_stats.dart';
import '../../game/puzzle.dart';
import '../../game/puzzle_library.dart';
import '../../theme/app_colors.dart';
import '../play/play_screen.dart';

class PracticeScreen extends StatefulWidget {
  final GameRepository repository;

  const PracticeScreen({super.key, required this.repository});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  PuzzleDifficulty _selectedDifficulty = PuzzleDifficulty.easy;
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

  void _openPuzzle(Puzzle puzzle) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PlayScreen(
              puzzle: puzzle,
              repository: widget.repository,
              onCompletedNext: () {
                // Find next puzzle in sequence if available
                final currentList = PuzzleLibrary.getByDifficulty(
                  _selectedDifficulty,
                );
                final currentIndex = currentList.indexWhere(
                  (p) => p.id == puzzle.id,
                );
                if (currentIndex != -1 &&
                    currentIndex + 1 < currentList.length) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PlayScreen(
                        puzzle: currentList[currentIndex + 1],
                        repository: widget.repository,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        )
        .then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final puzzles = PuzzleLibrary.getByDifficulty(_selectedDifficulty);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Puzzles')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Segmented control for difficulty
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SegmentedButton<PuzzleDifficulty>(
                      segments: const [
                        ButtonSegment(
                          value: PuzzleDifficulty.easy,
                          label: Text('Easy'),
                          icon: Icon(Icons.sentiment_satisfied_rounded),
                        ),
                        ButtonSegment(
                          value: PuzzleDifficulty.medium,
                          label: Text('Medium'),
                          icon: Icon(Icons.bolt_rounded),
                        ),
                        ButtonSegment(
                          value: PuzzleDifficulty.hard,
                          label: Text('Hard'),
                          icon: Icon(Icons.whatshot_rounded),
                        ),
                      ],
                      selected: {_selectedDifficulty},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedDifficulty = newSelection.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: puzzles.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final puzzle = puzzles[index];
                        final isCompleted = _stats.isPuzzleCompleted(puzzle.id);

                        return Card(
                          child: InkWell(
                            onTap: () => _openPuzzle(puzzle),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? AppColors.completedGreen.withValues(
                                              alpha: 0.15,
                                            )
                                          : AppColors.cellActive,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.grid_view_rounded,
                                      color: isCompleted
                                          ? AppColors.completedGreen
                                          : AppColors.cobaltPath,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          puzzle.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${puzzle.rows}×${puzzle.cols} Grid • ${puzzle.totalCheckpoints} Checkpoints',
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
