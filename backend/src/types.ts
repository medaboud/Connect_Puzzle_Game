// ============================================================
// types.ts – shared TypeScript interfaces for the Loopline API
// ============================================================

export interface Env {
  // D1 database binding (declared in wrangler.toml)
  DB: D1Database;
  // KV namespace for pre-aggregated leaderboard cache
  LEADERBOARD_CACHE: KVNamespace;
  // Secrets (set via `wrangler secret put`)
  JWT_SECRET: string;
  FB_APP_SECRET: string;
  // Vars
  ENVIRONMENT: string;
}

// --------------- Database row shapes (mirrors schema.sql) ---------------

export interface UserRow {
  id: string;
  name: string;
  avatar_url: string | null;
  created_at: number;
}

export interface CompletionRow {
  id: number;
  user_id: string;
  puzzle_id: string;
  difficulty: Difficulty;
  time_seconds: number;
  move_count: number;
  hints_used: number;
  points: number;
  completed_at: number;
}

export interface UserScoreRow {
  user_id: string;
  total_points: number;
  puzzles_solved: number;
  updated_at: number;
}

// --------------- API request / response shapes ---------------

export type Difficulty = 'easy' | 'medium' | 'hard' | 'daily';

export interface SubmitCompletionRequest {
  puzzle_id: string;
  difficulty: Difficulty;
  time_seconds: number;
  move_count: number;
  hints_used: number;
}

export interface LeaderboardEntry {
  rank: number;
  user_id: string;
  name: string;
  avatar_url: string | null;
  total_points: number;
  puzzles_solved: number;
}

export interface JwtPayload {
  sub: string;   // user_id
  name: string;
  iat: number;   // issued-at (unix seconds)
  exp: number;   // expiry (unix seconds)
}
