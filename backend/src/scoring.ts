// ============================================================
// scoring.ts – server-side points calculation
// Points are always computed here, never trusted from the client.
// ============================================================

import type { Difficulty } from './types.js';

const DIFFICULTY_MULTIPLIER: Record<Difficulty, number> = {
  easy: 1,
  medium: 2,
  hard: 3,
  daily: 4,
};

const BASE_POINTS = 1000;
const MAX_TIME_BONUS = 500;
const TIME_BONUS_RATE = 2;   // points lost per second
const HINT_PENALTY = 50;     // points lost per hint used

/**
 * Compute the score for a completed puzzle.
 *
 * @param difficulty  - puzzle difficulty tier
 * @param timeSeconds - wall-clock seconds from start to completion
 * @param hintsUsed   - number of hints the player requested
 * @returns           - non-negative integer point value
 */
export function computePoints(
  difficulty: Difficulty,
  timeSeconds: number,
  hintsUsed: number,
): number {
  const base = BASE_POINTS * DIFFICULTY_MULTIPLIER[difficulty];
  const timeBonus = Math.max(0, MAX_TIME_BONUS - timeSeconds * TIME_BONUS_RATE);
  const hintDeduction = hintsUsed * HINT_PENALTY;
  return Math.max(0, Math.round(base + timeBonus - hintDeduction));
}
