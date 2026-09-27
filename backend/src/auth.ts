// ============================================================
// auth.ts – POST /auth/facebook
//
// Exchange a Facebook user-access token for a signed session JWT.
// The Worker verifies the token with Facebook directly, upserts
// the user in D1, then returns a JWT the Flutter app stores locally.
// ============================================================

import type { Env, UserRow } from './types.js';
import { signJwt } from './jwt.js';

interface FacebookMeResponse {
  id: string;
  name: string;
  picture?: { data?: { url?: string } };
  error?: { message: string };
}

/**
 * Verify a Facebook user-access token by calling the Graph API,
 * upsert the user in D1, and return a signed JWT.
 */
export async function handleFacebookAuth(
  request: Request,
  env: Env,
): Promise<Response> {
  // ── 1. Parse body ──────────────────────────────────────────
  let body: { fb_access_token?: unknown };
  try {
    body = await request.json();
  } catch {
    return errorResponse(400, 'Invalid JSON body');
  }

  const fbToken = body.fb_access_token;
  if (typeof fbToken !== 'string' || fbToken.trim() === '') {
    return errorResponse(400, 'Missing or invalid fb_access_token');
  }

  // ── 2. Verify token with Facebook Graph API ─────────────────
  const graphUrl = new URL('https://graph.facebook.com/me');
  graphUrl.searchParams.set('fields', 'id,name,picture.width(200)');
  graphUrl.searchParams.set('access_token', fbToken);

  let fbUser: FacebookMeResponse;
  try {
    const fbRes = await fetch(graphUrl.toString());
    fbUser = await fbRes.json() as FacebookMeResponse;
  } catch {
    return errorResponse(502, 'Could not reach Facebook Graph API');
  }

  if (fbUser.error) {
    return errorResponse(401, `Facebook rejected token: ${fbUser.error.message}`);
  }

  const userId = fbUser.id;
  const userName = fbUser.name;
  const avatarUrl = fbUser.picture?.data?.url ?? null;

  // ── 3. Upsert user in D1 ───────────────────────────────────
  await env.DB.prepare(
    `INSERT INTO users (id, name, avatar_url, created_at)
     VALUES (?1, ?2, ?3, unixepoch())
     ON CONFLICT(id) DO UPDATE SET name=excluded.name, avatar_url=excluded.avatar_url`,
  )
    .bind(userId, userName, avatarUrl)
    .run();

  // Ensure a user_scores row exists (ignore if already present)
  await env.DB.prepare(
    `INSERT OR IGNORE INTO user_scores (user_id, total_points, puzzles_solved, updated_at)
     VALUES (?1, 0, 0, unixepoch())`,
  )
    .bind(userId)
    .run();

  // ── 4. Sign and return JWT ──────────────────────────────────
  const jwt = await signJwt({ sub: userId, name: userName }, env.JWT_SECRET);

  return jsonResponse(200, {
    jwt,
    user: { id: userId, name: userName, avatar_url: avatarUrl },
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
