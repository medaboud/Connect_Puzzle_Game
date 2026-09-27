// ============================================================
// index.ts – Cloudflare Worker entry point
//
// Route table:
//   POST /auth/facebook             – exchange FB token for JWT
//   POST /completions               – submit a puzzle solve (auth)
//   GET  /leaderboard/global        – global top scores
//   GET  /leaderboard/friends       – friends scores (auth)
//   POST /friends/sync              – refresh friend list (auth)
//   GET  /health                    – uptime probe
// ============================================================

import type { Env } from './types.js';
import { verifyJwt } from './jwt.js';
import { handleFacebookAuth } from './auth.js';
import { handleSubmitCompletion } from './completions.js';
import {
  handleGlobalLeaderboard,
  handleFriendsLeaderboard,
  handleFriendsSync,
} from './leaderboard.js';

// ---------------------------------------------------------------------------
// CORS – restrict to your Flutter app's origin in production.
// During development the value below allows all origins.
// Update ALLOWED_ORIGIN to your actual domain when you go live.
// ---------------------------------------------------------------------------
const ALLOWED_ORIGIN = '*'; // TODO: change to 'https://your-app-domain.com'

function corsHeaders(): HeadersInit {
  return {
    'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

function addCors(response: Response): Response {
  const headers = new Headers(response.headers);
  for (const [k, v] of Object.entries(corsHeaders())) {
    headers.set(k, v);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  });
}

// ---------------------------------------------------------------------------
// Request handler
// ---------------------------------------------------------------------------

export default {
  async fetch(request: Request, env: Env, _ctx: ExecutionContext): Promise<Response> {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    try {
      // ── Unauthenticated routes ────────────────────────────

      if (path === '/health' && method === 'GET') {
        return addCors(json(200, { status: 'ok', timestamp: Date.now() }));
      }

      if (path === '/auth/facebook' && method === 'POST') {
        return addCors(await handleFacebookAuth(request, env));
      }

      if (path === '/leaderboard/global' && method === 'GET') {
        return addCors(await handleGlobalLeaderboard(request, env));
      }

      // ── JWT-protected routes ─────────────────────────────

      const authHeader = request.headers.get('Authorization') ?? '';
      const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

      if (path === '/leaderboard/friends' && method === 'GET') {
        if (!token) return addCors(json(401, { error: 'Authentication required' }));
        const user = await verifyJwt(token, env.JWT_SECRET);
        if (!user) return addCors(json(401, { error: 'Invalid or expired token' }));
        return addCors(await handleFriendsLeaderboard(request, env, user));
      }

      if (path === '/completions' && method === 'POST') {
        if (!token) return addCors(json(401, { error: 'Authentication required' }));
        const user = await verifyJwt(token, env.JWT_SECRET);
        if (!user) return addCors(json(401, { error: 'Invalid or expired token' }));
        return addCors(await handleSubmitCompletion(request, env, user));
      }

      if (path === '/friends/sync' && method === 'POST') {
        if (!token) return addCors(json(401, { error: 'Authentication required' }));
        const user = await verifyJwt(token, env.JWT_SECRET);
        if (!user) return addCors(json(401, { error: 'Invalid or expired token' }));
        return addCors(await handleFriendsSync(request, env, user));
      }

      // ── 404 fallback ──────────────────────────────────────
      return addCors(json(404, { error: 'Not found' }));

    } catch (err: unknown) {
      console.error('Unhandled error:', err);
      return addCors(json(500, { error: 'Internal server error' }));
    }
  },
};
