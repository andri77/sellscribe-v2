import * as path from 'path';
import { testUser } from './test-data';

// Storage state written by tests/auth.setup.ts and loaded via test.use(authenticated)
export const AUTH_FILE = path.join(__dirname, '..', '.auth', 'user.json');
export const authenticated = { storageState: AUTH_FILE };

/**
 * Signs the test user in through the Supabase password grant and returns the localStorage
 * entry supabase_flutter restores its session from. The /token response already has the
 * shape of gotrue's Session.toJson, so it is stored as-is.
 */
export async function createSession(): Promise<{ name: string; value: string }> {
  const url = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY must be set to create a test session');
  }

  const { email, password } = testUser();
  const res = await fetch(`${url}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { apikey: anonKey, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) {
    throw new Error(`Test user sign-in failed (${res.status}): ${await res.text()}`);
  }

  // Same key supabase_flutter derives: sb-<project ref>-auth-token
  const projectRef = new URL(url).host.split('.')[0];
  return { name: `sb-${projectRef}-auth-token`, value: await res.text() };
}
