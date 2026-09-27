// ============================================================
// leaderboard.ts
//
// GET /leaderboard/global?page=1   – top players worldwide
// GET /leaderboard/friends          – caller's friends (JWT required)
// POST /friends/sync                – refresh friend list from Facebook
// ============================================================

import type { Env, LeaderboardEntry, UserScoreRow, UserRow, JwtPayload } from './types.js';

const PAGE_SIZE = 50;
const CACHE_TTL_SECONDS = 60; // global board refreshes every 60 s
const GLOBAL_CACHE_KEY = 'global_leaderboard_page_';

// ── Public helpers ────────────────────────────────────────────

/**
 * Invalidate all cached global leaderboard pages.
 * Called after every completion submission.
 */
export async function invalidateLeaderboardCache(env: Env): Promise<void> {
  // We only cache the first few pages; deleting page 1 is sufficient
  // because KV TTL handles the rest.
  await env.LEADERBOARD_CACHE.delete(`${GLOBAL_CACHE_KEY}1`);
}

// ── Route handlers ────────────────────────────────────────────

/** GET /leaderboard/global?page=N */
export async function handleGlobalLeaderboard(
  request: Request,
  env: Env,
): Promise<Response> {
  const url = new URL(request.url);
  const page = Math.max(1, parseInt(url.searchParams.get('page') ?? '1', 10));
  const cacheKey = `${GLOBAL_CACHE_KEY}${page}`;

  // Try KV cache first
  const cached = await env.LEADERBOARD_CACHE.get(cacheKey, { type: 'json' });
  if (cached !== null) {
    return jsonResponse(200, cached);
  }

  // Cache miss → query D1
  const offset = (page - 1) * PAGE_SIZE;
  const rows = await env.DB.prepare(
    `SELECT u.id, u.name, u.avatar_url, s.total_points, s.puzzles_solved
     FROM user_scores s
     JOIN users u ON u.id = s.user_id
     ORDER BY s.total_points DESC
     LIMIT ?1 OFFSET ?2`,
  )
    .bind(PAGE_SIZE, offset)
    .all<UserScoreRow & UserRow>();

  const entries: LeaderboardEntry[] = (rows.results ?? []).map((r, i) => ({
    rank: offset + i + 1,
    user_id: r.id,
    name: r.name,
    avatar_url: r.avatar_url ?? null,
    total_points: r.total_points,
    puzzles_solved: r.puzzles_solved,
  }));

  const payload = { page, entries };

  // Write to KV cache
  await env.LEADERBOARD_CACHE.put(cacheKey, JSON.stringify(payload), {
    expirationTtl: CACHE_TTL_SECONDS,
  });

  return jsonResponse(200, payload);
}

/** GET /leaderboard/friends  (JWT required) */
export async function handleFriendsLeaderboard(
  _request: Request,
  env: Env,
  user: JwtPayload,
): Promise<Response> {
  // Return the authenticated user + all friends, sorted by total_points
  const rows = await env.DB.prepare(
    `SELECT u.id, u.name, u.avatar_url, s.total_points, s.puzzles_solved
     FROM user_scores s
     JOIN users u ON u.id = s.user_id
     WHERE s.user_id = ?1
        OR s.user_id IN (
             SELECT friend_id FROM friends WHERE user_id = ?1
           )
     ORDER BY s.total_points DESC
     LIMIT 200`,
  )
    .bind(user.sub)
    .all<UserScoreRow & UserRow>();

  const entries: LeaderboardEntry[] = (rows.results ?? []).map((r, i) => ({
    rank: i + 1,
    user_id: r.id,
    name: r.name,
    avatar_url: r.avatar_url ?? null,
    total_points: r.total_points,
    puzzles_solved: r.puzzles_solved,
  }));

  return jsonResponse(200, { entries, viewer_id: user.sub });
}

/** POST /friends/sync  (JWT required)
 *
 * Fetches the caller's Facebook friend list (users who also authorised the app)
 * and upserts them into the friends table.
 *
 * Body: { fb_access_token: string }
 */
export async function handleFriendsSync(
  request: Request,
  env: Env,
  user: JwtPayload,
): Promise<Response> {
  let body: { fb_access_token?: unknown };
  try {
    body = await request.json();
  } catch {
    return errorResponse(400, 'Invalid JSON body');
  }

  const fbToken = body.fb_access_token;
  if (typeof fbToken !== 'string' || fbToken.trim() === '') {
    return errorResponse(400, 'Missing fb_access_token');
  }

  // Fetch friends from Facebook (only returns friends who also use the app)
  const graphUrl = new URL('https://graph.facebook.com/me/friends');
  graphUrl.searchParams.set('fields', 'id');
  graphUrl.searchParams.set('limit', '200');
  graphUrl.searchParams.set('access_token', fbToken);

  interface FbFriend { id: string }
  interface FbFriendsResponse {
    data?: FbFriend[];
    error?: { message: string };
  }

  let fbData: FbFriendsResponse;
  try {
    const res = await fetch(graphUrl.toString());
    fbData = await res.json() as FbFriendsResponse;
  } catch {
    return errorResponse(502, 'Could not reach Facebook Graph API');
  }

  if (fbData.error) {
    return errorResponse(401, `Facebook error: ${fbData.error.message}`);
  }

  const friendIds = (fbData.data ?? []).map((f) => f.id);

  if (friendIds.length > 0) {
    // Batch insert both directions (user→friend and friend→user)
    const stmts = friendIds.flatMap((friendId) => [
      env.DB.prepare(
        `INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?1, ?2)`,
      ).bind(user.sub, friendId),
      env.DB.prepare(
        `INSERT OR IGNORE INTO friends (user_id, friend_id) VALUES (?1, ?2)`,
      ).bind(friendId, user.sub),
    ]);
    await env.DB.batch(stmts);
  }

  return jsonResponse(200, { synced: friendIds.length });
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
