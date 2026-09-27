// ============================================================
// completions.ts – POST /completions
//
// Accepts a puzzle solve from an authenticated Flutter client,
// computes points server-side, persists to D1, and updates the
// aggregated user_scores row used by the leaderboard.
// ============================================================

import type { Env, SubmitCompletionRequest, Difficulty } from './types.js';
import type { JwtPayload } from './types.js';
import { computePoints } from './scoring.js';
import { invalidateLeaderboardCache } from './leaderboard.js';

/** Valid difficulty values – used for runtime validation */
const VALID_DIFFICULTIES: Difficulty[] = ['easy', 'medium', 'hard', 'daily'];

/** Maximum allowed time (prevent absurd values; 2 hours is generous) */
const MAX_TIME_SECONDS = 7200;

export async function handleSubmitCompletion(
  request: Request,
  env: Env,
  user: JwtPayload,
): Promise<Response> {
  // ── 1. Parse and validate body ─────────────────────────────
  let body: Partial<SubmitCompletionRequest>;
  try {
    body = await request.json();
  } catch {
    return errorResponse(400, 'Invalid JSON body');
  }

  const { puzzle_id, difficulty, time_seconds, move_count, hints_used = 0 } = body;

  if (typeof puzzle_id !== 'string' || puzzle_id.trim() === '') {
    return errorResponse(400, 'Missing puzzle_id');
  }
  if (!VALID_DIFFICULTIES.includes(difficulty as Difficulty)) {
    return errorResponse(400, `difficulty must be one of: ${VALID_DIFFICULTIES.join(', ')}`);
  }
  if (typeof time_seconds !== 'number' || time_seconds <= 0 || time_seconds > MAX_TIME_SECONDS) {
    return errorResponse(400, `time_seconds must be between 1 and ${MAX_TIME_SECONDS}`);
  }
  if (typeof move_count !== 'number' || move_count <= 0) {
    return errorResponse(400, 'move_count must be a positive integer');
  }
  if (typeof hints_used !== 'number' || hints_used < 0) {
    return errorResponse(400, 'hints_used must be >= 0');
  }

  // ── 2. Compute points server-side ──────────────────────────
  const points = computePoints(difficulty as Difficulty, time_seconds, hints_used);

  // ── 3. Persist completion (unique per user+puzzle) ─────────
  let inserted = false;
  try {
    await env.DB.prepare(
      `INSERT INTO completions
         (user_id, puzzle_id, difficulty, time_seconds, move_count, hints_used, points, completed_at)
       VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, unixepoch())`,
    )
      .bind(user.sub, puzzle_id, difficulty, time_seconds, move_count, hints_used, points)
      .run();
    inserted = true;
  } catch (err: unknown) {
    // UNIQUE constraint violation → already submitted this puzzle
    if (err instanceof Error && err.message.includes('UNIQUE')) {
      return jsonResponse(409, {
        error: 'Puzzle already submitted',
        puzzle_id,
      });
    }
    throw err; // unexpected error – let the global handler return 500
  }

  if (!inserted) {
    return errorResponse(500, 'Failed to save completion');
  }

  // ── 4. Update aggregated user_scores ──────────────────────
  await env.DB.prepare(
    `INSERT INTO user_scores (user_id, total_points, puzzles_solved, updated_at)
       VALUES (?1, ?2, 1, unixepoch())
     ON CONFLICT(user_id) DO UPDATE SET
       total_points   = total_points + excluded.total_points,
       puzzles_solved = puzzles_solved + 1,
       updated_at     = unixepoch()`,
  )
    .bind(user.sub, points)
    .run();

  // ── 5. Invalidate KV leaderboard cache ────────────────────
  await invalidateLeaderboardCache(env);

  return jsonResponse(201, {
    points_earned: points,
    puzzle_id,
    message: 'Completion recorded',
  });
}

// ── helpers ──────────────────────────────────────────────────

function jsonResponse(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function errorResponse(status: number, message: string): Response {
  return jsonResponse(status, { error: message });
}
