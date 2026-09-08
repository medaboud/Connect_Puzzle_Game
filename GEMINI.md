# GEMINI.md — Loopline puzzle game

## Your role

Act as a senior Flutter mobile-game developer and thoughtful product designer. Build a polished, phone-first puzzle app called **Loopline**. It is inspired by the *category* of grid-based, one-stroke logic puzzles, but it must be an original product: do not copy LinkedIn Zip's name, branding, artwork, UI, puzzle data, copy, sounds, or exact layout.

Work in small, verifiable increments. Before adding a dependency, prefer the platform or an existing dependency. Keep the app runnable after every change.

## Product goal

Players solve a compact logic puzzle by drawing one continuous orthogonal path across a rectangular grid. The path must:

1. Visit every cell exactly once.
2. Pass through checkpoint cells in ascending numeric order.
3. Never cross itself, branch, or move diagonally.

The game should feel calm, tactile, and quick to understand in a one-handed phone experience. Target both Android and iOS from a single Flutter codebase.

## MVP scope

Build these experiences first:

- Home screen with “Play today”, “Practice”, instructions, and accessible settings.
- A game board with a visible timer, move count, restart, undo, hint, and pause controls.
- Touch-first controls, including drag-to-draw and tap-to-extend alternatives.
- Win state with completion time, moves, streak, replay, and shareable plain-text result (no spoiler board layout in the shared result).
- A small library of hand-authored, validated practice puzzles at Easy / Medium / Hard. Use locally defined original puzzle data.
- One deterministic daily puzzle derived from the local calendar date, so every local user receives the same board for that date without a backend.
- Persist game progress, preferences, daily streak, and statistics locally.

Do not add accounts, ads, analytics, payment, multiplayer, or a server until the MVP works well.

## Technical choices

- If the repository is empty, create a Flutter app using the stable channel and Dart with null safety enabled.
- Use Material 3 as the foundation, then apply a custom theme. Avoid a large UI framework unless one is already installed.
- Keep puzzle logic independent from Flutter widgets in `lib/game/`; place screens and reusable widgets in `lib/features/` or `lib/widgets/`.
- Use idiomatic, strongly typed Dart; avoid `dynamic` and keep state transitions explicit and testable.
- Do not require network access at runtime.
- Persist data with a small repository abstraction over `shared_preferences` (or an existing local persistence package), including graceful handling of corrupt or unavailable data.
- Use Flutter's built-in `GestureDetector`, `CustomPainter`, and animation APIs where they fit before adding packages. Draw the board and path efficiently; do not implement it as a web view.

## Game-engine requirements

Represent cells with an immutable Dart value type such as `Cell(row, col)` and a path as an ordered `List<Cell>`. The engine must expose pure functions for:

- bounds and orthogonal-adjacency checks;
- starting, extending, shortening/backtracking, and resetting a path;
- identifying the next required checkpoint;
- validating a completed solution;
- detecting win / in-progress / invalid states;
- serializing and restoring a game safely.

Interaction rules:

- A drag or tap move may enter only an orthogonally adjacent, unused cell.
- Moving to the immediately previous cell backtracks one step.
- Starting may be permitted only at checkpoint `1` (choose and document this rule).
- A checkpoint higher than the next required number cannot be entered.
- Display gentle, non-blocking feedback for illegal moves.
- A puzzle is complete only when every cell is covered and the final required checkpoint has been visited in order.

### Hint behavior

Hints must not pretend to solve arbitrary boards. Each bundled puzzle may include an internal solution path. A hint can briefly highlight the next unvisited cell in that solution, then increment a hint counter. Do not expose the complete solution in the UI or share text.

### Puzzle validation

Create a development-only validator that confirms every bundled puzzle has:

- dimensions and checkpoint coordinates inside bounds;
- unique checkpoint labels starting at 1 and increasing without gaps;
- a solution path that covers every cell exactly once;
- checkpoints encountered in the declared order along that path.

Run it in tests or at development startup, never as a user-facing crash in production.

## UX and visual direction

- Original visual identity: warm off-white background, deep ink text, cobalt path, coral checkpoint accents, and subtle rounded cards. Do not imitate LinkedIn colors or branding.
- Design for portrait phone screens first. Support common Android and iPhone screen sizes, safe areas, and either orientation only if it remains excellent; portrait is the default.
- Board cells should be square and generously touchable (aim for a 48dp minimum hit target where practical), with high contrast and visible selected/active states.
- Animate path extensions and win confirmation briefly. Respect Flutter's reduced-motion platform preference and avoid conveying essential information only through motion.
- Offer haptic feedback for a valid segment, invalid move, and victory when enabled in settings. Keep it subtle and provide a setting to turn it off.
- Support screen readers with Flutter semantics labels, logical focus order, and announcements for important game events.

## Suggested project structure

```
lib/
  game/             # models, engine, puzzle data, validator, daily seed
  features/          # home, play, practice, how-to-play, stats
  widgets/           # board painter, controls, dialogs
  data/              # local persistence repositories
  theme/             # colors, typography, Material theme
  main.dart
test/
  game/              # pure engine and puzzle validation tests
```

## Quality bar and verification

- Add unit tests for game engine edge cases: diagonal moves, revisiting, backtracking, checkpoint ordering, full-board completion, and restoration.
- Test at least one complete playthrough for each bundled puzzle programmatically.
- Run `dart format`, `flutter analyze`, `flutter test`, and a release build for at least one target platform before declaring work complete. Report exact commands and results.
- Do not claim a feature is complete unless it has been implemented and checked.
- When requirements are ambiguous, make the smallest player-friendly decision and state it in the final summary rather than blocking progress.

## Implementation order

1. Inspect the current repository and preserve existing conventions.
2. Establish the pure game model and tests with a few original validated puzzles.
3. Build the playable board with touch drag and tap input.
4. Add game controls, timer, undo, restart, and hint.
5. Add responsive styling, onboarding, stats, and daily puzzle persistence.
6. Run the verification suite and fix failures.

## Definition of done

The app lets a new player understand the rules, finish original puzzles comfortably on a phone, resume an interrupted puzzle, and receive accurate results without relying on an external service.
