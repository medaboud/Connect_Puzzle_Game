// ============================================================
// jwt.ts – lightweight JWT sign / verify using Web Crypto API
// (no external dependency – uses the runtime built-in)
// ============================================================

import type { JwtPayload } from './types.js';

const ALGORITHM = { name: 'HMAC', hash: 'SHA-256' };
const JWT_TTL_SECONDS = 60 * 60 * 24; // 24 hours

// ---------- helpers ----------

function base64UrlEncode(buf: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function base64UrlDecode(str: string): Uint8Array {
  const base64 = str.replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(base64);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

async function importKey(secret: string): Promise<CryptoKey> {
  const encoder = new TextEncoder();
  return crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    ALGORITHM,
    false,
    ['sign', 'verify'],
  );
}

// ---------- public API ----------

/** Sign a JWT and return the compact token string. */
export async function signJwt(
  payload: Omit<JwtPayload, 'iat' | 'exp'>,
  secret: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const fullPayload: JwtPayload = {
    ...payload,
    iat: now,
    exp: now + JWT_TTL_SECONDS,
  };

  const headerBytes = new TextEncoder().encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const header = base64UrlEncode(headerBytes.buffer as ArrayBuffer);
  const bodyBytes = new TextEncoder().encode(JSON.stringify(fullPayload));
  const body = base64UrlEncode(bodyBytes.buffer as ArrayBuffer);
  const signingInput = `${header}.${body}`;

  const key = await importKey(secret);
  const signingInputBytes = new TextEncoder().encode(signingInput);
  const signature = await crypto.subtle.sign(
    ALGORITHM.name,
    key,
    signingInputBytes.buffer as ArrayBuffer,
  );

  return `${signingInput}.${base64UrlEncode(signature)}`;
}

/** Verify a JWT and return the payload, or null if invalid / expired. */
export async function verifyJwt(
  token: string,
  secret: string,
): Promise<JwtPayload | null> {
  const parts = token.split('.');
  if (parts.length !== 3) return null;

  const [header, body, sig] = parts as [string, string, string];
  const signingInput = `${header}.${body}`;

  try {
    const key = await importKey(secret);
    const sigBytes = base64UrlDecode(sig);
    const inputBytes = new TextEncoder().encode(signingInput);
    const valid = await crypto.subtle.verify(
      ALGORITHM.name,
      key,
      sigBytes.buffer as ArrayBuffer,
      inputBytes.buffer as ArrayBuffer,
    );
    if (!valid) return null;

    const payload = JSON.parse(
      new TextDecoder().decode(base64UrlDecode(body)),
    ) as JwtPayload;

    if (payload.exp < Math.floor(Date.now() / 1000)) return null; // expired

    return payload;
  } catch {
    return null;
  }
}
