-- ============================================================
-- Loopline API – D1 Schema
-- Run locally:  npm run db:migrate
-- Run remotely: npm run db:migrate:remote
-- ============================================================

-- ---------------------------------------------------------------
-- Users (one row per Facebook account that has ever signed in)
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id          TEXT    PRIMARY KEY,          -- Facebook user ID (stable)
  name        TEXT    NOT NULL,
  avatar_url  TEXT,
  created_at  INTEGER NOT NULL DEFAULT (unixepoch())
);

-- ---------------------------------------------------------------
-- Puzzle completions – one row per successful solve
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS completions (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id       TEXT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  puzzle_id     TEXT    NOT NULL,            -- e.g. "daily-2026-09-19" | "practice-easy-3"
  difficulty    TEXT    NOT NULL             -- easy | medium | hard | daily
                        CHECK (difficulty IN ('easy','medium','hard','daily')),
  time_seconds  INTEGER NOT NULL CHECK (time_seconds > 0),
  move_count    INTEGER NOT NULL CHECK (move_count > 0),
  hints_used    INTEGER NOT NULL DEFAULT 0 CHECK (hints_used >= 0),
  points        INTEGER NOT NULL CHECK (points >= 0),
  completed_at  INTEGER NOT NULL DEFAULT (unixepoch())
);

-- One solve per user per puzzle (no double-submitting the same puzzle)
CREATE UNIQUE INDEX IF NOT EXISTS uq_completion
  ON completions(user_id, puzzle_id);

-- Fast look-ups for leaderboard aggregation
CREATE INDEX IF NOT EXISTS idx_completions_user
  ON completions(user_id);

-- ---------------------------------------------------------------
-- Aggregated scores per user (updated on every submit for fast reads)
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_scores (
  user_id       TEXT    PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  total_points  INTEGER NOT NULL DEFAULT 0,
  puzzles_solved INTEGER NOT NULL DEFAULT 0,
  updated_at    INTEGER NOT NULL DEFAULT (unixepoch())
);

-- ---------------------------------------------------------------
-- Friend graph (bidirectional; both directions stored as separate rows)
-- Populated by POST /friends/sync – uses Facebook's user_friends scope
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS friends (
  user_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS idx_friends_user
  ON friends(user_id);
