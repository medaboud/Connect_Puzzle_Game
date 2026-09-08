import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/game_repository.dart';
import '../../data/user_preferences.dart';
import '../../game/cell.dart';
import '../../game/game_engine.dart';
import '../../game/game_serializer.dart';
import '../../game/game_state.dart';
import '../../game/puzzle.dart';
import '../../theme/app_colors.dart';
import '../../widgets/board_widget.dart';
import '../../widgets/game_controls.dart';
import '../../widgets/game_header.dart';
import '../../widgets/win_dialog.dart';

class PlayScreen extends StatefulWidget {
  final Puzzle puzzle;
  final GameRepository repository;
  final VoidCallback? onCompletedNext;

  const PlayScreen({
    super.key,
    required this.puzzle,
    required this.repository,
    this.onCompletedNext,
  });

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late GameState _state;
  UserPreferences _preferences = const UserPreferences();
  Timer? _ticker;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _state = GameState.initial(widget.puzzle);
    _initialize();
  }

  Future<void> _initialize() async {
    _preferences = await widget.repository.loadPreferences();

    // Check for saved progress
    final savedJson = await widget.repository.loadActiveGameState(
      widget.puzzle.id,
    );
    if (savedJson != null && mounted) {
      final restored = GameSerializer.deserialize(savedJson, widget.puzzle);
      if (restored.status != GameStatus.completed) {
        _state = restored;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.status == GameStatus.playing && mounted) {
        setState(() {
          _state = _state.copyWith(elapsedSeconds: _state.elapsedSeconds + 1);
        });
      }
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _triggerHaptic(MoveResultType type) {
    if (!_preferences.hapticsEnabled) return;

    switch (type) {
      case MoveResultType.started:
      case MoveResultType.extended:
        HapticFeedback.selectionClick();
        break;
      case MoveResultType.backtracked:
        HapticFeedback.lightImpact();
        break;
      case MoveResultType.completed:
        HapticFeedback.heavyImpact();
        break;
      case MoveResultType.invalidMustStartAtOne:
      case MoveResultType.invalidOutOfBounds:
      case MoveResultType.invalidNotAdjacent:
      case MoveResultType.invalidAlreadyVisited:
      case MoveResultType.invalidSkippedCheckpoint:
        HapticFeedback.mediumImpact();
        break;
      case MoveResultType.ignoredSameCell:
        break;
    }
  }

  void _onCellInput(Cell cell) {
    if (_state.isCompleted || _state.status == GameStatus.paused) return;

    final result = GameEngine.handleCellInput(_state, cell);
    _triggerHaptic(result.type);

    setState(() {
      _state = result.state;
    });

    if (result.isInvalid && result.message != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message!),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (result.type == MoveResultType.completed) {
      _handleWin();
    } else {
      // Save active progress
      widget.repository.saveActiveGameState(
        widget.puzzle.id,
        GameSerializer.serialize(_state),
      );
    }
  }

  Future<void> _handleWin() async {
    _stopTimer();

    final updatedStats = await widget.repository.recordGameWon(
      puzzle: widget.puzzle,
      elapsedSeconds: _state.elapsedSeconds,
      movesCount: _state.movesCount,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WinDialog(
        puzzle: widget.puzzle,
        state: _state,
        streak: updatedStats.currentStreak,
        onReplay: () {
          Navigator.of(ctx).pop();
          _restartPuzzle();
        },
        onNextOrHome: () {
          Navigator.of(ctx).pop();
          if (widget.onCompletedNext != null) {
            widget.onCompletedNext!();
          } else {
            Navigator.of(context).pop();
          }
        },
        nextButtonLabel: widget.onCompletedNext != null
            ? 'Next Puzzle'
            : 'Back to Home',
      ),
    );
  }

  void _onUndo() {
    if (_state.path.isEmpty || _state.isCompleted) return;

    if (_preferences.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _state = GameEngine.backtrack(_state);
    });

    widget.repository.saveActiveGameState(
      widget.puzzle.id,
      GameSerializer.serialize(_state),
    );
  }

  void _restartPuzzle() {
    if (_preferences.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _state = GameEngine.reset(widget.puzzle);
    });

    widget.repository.clearActiveGameState(widget.puzzle.id);
    _startTimer();
  }

  void _onHint() {
    if (_state.isCompleted) return;

    if (_preferences.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }

    setState(() {
      _state = GameEngine.applyHint(_state);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hint: Follow the glowing amber cell!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _togglePause() {
    if (_state.status == GameStatus.paused) {
      setState(() {
        _state = _state.copyWith(status: GameStatus.playing);
      });
      _startTimer();
    } else if (_state.status == GameStatus.playing) {
      setState(() {
        _state = _state.copyWith(status: GameStatus.paused);
      });
      _stopTimer();

      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Game Paused',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _togglePause();
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Resume Game'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Exit to Menu'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        // Auto-save on exit
        if (!_state.isCompleted) {
          widget.repository.saveActiveGameState(
            widget.puzzle.id,
            GameSerializer.serialize(_state),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              GameHeader(
                puzzle: widget.puzzle,
                state: _state,
                onPauseTapped: _togglePause,
                onBackPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: _state.status == GameStatus.paused
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.cellBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Paused',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        )
                      : BoardWidget(
                          puzzle: widget.puzzle,
                          state: _state,
                          onCellInput: _onCellInput,
                          hapticsEnabled: _preferences.hapticsEnabled,
                          tapToExtendEnabled: _preferences.tapToExtend,
                          reducedMotion: _preferences.reducedMotion,
                        ),
                ),
              ),
              GameControls(
                onUndo: _onUndo,
                onReset: _restartPuzzle,
                onHint: _onHint,
                canUndo: _state.path.isNotEmpty && !_state.isCompleted,
                hintsUsed: _state.hintsUsed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
