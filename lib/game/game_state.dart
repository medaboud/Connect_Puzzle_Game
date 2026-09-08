import 'package:flutter/foundation.dart';
import 'cell.dart';
import 'puzzle.dart';

enum GameStatus { initial, playing, paused, completed }

/// Represents an immutable snapshot of gameplay for a puzzle.
@immutable
class GameState {
  final Puzzle puzzle;
  final List<Cell> path;
  final int nextRequiredCheckpoint;
  final int movesCount;
  final int hintsUsed;
  final int elapsedSeconds;
  final GameStatus status;
  final Cell? lastInvalidCell;
  final String? lastInvalidMessage;
  final Cell? hintCell;

  const GameState({
    required this.puzzle,
    required this.path,
    required this.nextRequiredCheckpoint,
    this.movesCount = 0,
    this.hintsUsed = 0,
    this.elapsedSeconds = 0,
    this.status = GameStatus.initial,
    this.lastInvalidCell,
    this.lastInvalidMessage,
    this.hintCell,
  });

  /// Creates a fresh starting game state for [puzzle].
  factory GameState.initial(Puzzle puzzle) {
    return GameState(
      puzzle: puzzle,
      path: const [],
      nextRequiredCheckpoint: 1,
      movesCount: 0,
      hintsUsed: 0,
      elapsedSeconds: 0,
      status: GameStatus.initial,
    );
  }

  /// Head (latest cell) of current path, or null if path is empty.
  Cell? get headCell => path.isNotEmpty ? path.last : null;

  /// Cell before head in the path, used to detect backtracking.
  Cell? get previousCell => path.length >= 2 ? path[path.length - 2] : null;

  /// Whether a specific cell is currently in the active path.
  bool isVisited(Cell cell) => path.contains(cell);

  /// Total cells covered so far.
  int get coveredCellsCount => path.length;

  /// Whether the puzzle is fully completed.
  bool get isCompleted => status == GameStatus.completed;

  /// Progress ratio from 0.0 to 1.0.
  double get progress => puzzle.totalCells > 0
      ? (path.length / puzzle.totalCells).clamp(0.0, 1.0)
      : 0.0;

  GameState copyWith({
    Puzzle? puzzle,
    List<Cell>? path,
    int? nextRequiredCheckpoint,
    int? movesCount,
    int? hintsUsed,
    int? elapsedSeconds,
    GameStatus? status,
    Cell? lastInvalidCell,
    bool clearInvalidCell = false,
    String? lastInvalidMessage,
    Cell? hintCell,
    bool clearHintCell = false,
  }) {
    return GameState(
      puzzle: puzzle ?? this.puzzle,
      path: path ?? this.path,
      nextRequiredCheckpoint:
          nextRequiredCheckpoint ?? this.nextRequiredCheckpoint,
      movesCount: movesCount ?? this.movesCount,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
      lastInvalidCell: clearInvalidCell
          ? null
          : (lastInvalidCell ?? this.lastInvalidCell),
      lastInvalidMessage: clearInvalidCell
          ? null
          : (lastInvalidMessage ?? this.lastInvalidMessage),
      hintCell: clearHintCell ? null : (hintCell ?? this.hintCell),
    );
  }

  Map<String, dynamic> toJson() => {
    'puzzleId': puzzle.id,
    'path': path.map((c) => c.toJson()).toList(),
    'nextRequiredCheckpoint': nextRequiredCheckpoint,
    'movesCount': movesCount,
    'hintsUsed': hintsUsed,
    'elapsedSeconds': elapsedSeconds,
    'status': status.name,
  };

  factory GameState.fromJson(Map<String, dynamic> json, Puzzle puzzle) {
    final pathList =
        (json['path'] as List<dynamic>?)
            ?.map((c) => Cell.fromJson(c as Map<String, dynamic>))
            .toList() ??
        const [];

    final statusString = json['status'] as String?;
    final gameStatus = GameStatus.values.firstWhere(
      (s) => s.name == statusString,
      orElse: () => GameStatus.initial,
    );

    return GameState(
      puzzle: puzzle,
      path: pathList,
      nextRequiredCheckpoint: json['nextRequiredCheckpoint'] as int? ?? 1,
      movesCount: json['movesCount'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      status: gameStatus,
    );
  }
}
