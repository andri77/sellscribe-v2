// Seeds the local Supabase stack for provider states. Writes go through the service-role key
// (bypassing RLS); verified requests then run as a real user JWT so RLS is exercised.
import { config } from 'dotenv';
import path from 'path';

config({ path: path.resolve(__dirname, '../../.env.provider') });

const env = (name: string) => {
  const value = process.env[name];
  if (!value) throw new Error(`${name} missing — run scripts/provider-up.sh first`);
  return value;
};

export const API_URL = () => env('API_URL');
export const ANON_KEY = () => env('ANON_KEY');
const SERVICE_ROLE_KEY = () => env('SERVICE_ROLE_KEY');

export const PASSWORD = 'Pact-Verify-123!';

async function call(method: string, urlPath: string, body?: unknown, extra: Record<string, string> = {}) {
  const res = await fetch(`${API_URL()}${urlPath}`, {
    method,
    headers: {
      apikey: SERVICE_ROLE_KEY(),
      Authorization: `Bearer ${SERVICE_ROLE_KEY()}`,
      'Content-Type': 'application/json',
      ...extra,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  return { status: res.status, ok: res.ok, text };
}

const expectOk = (what: string, r: { ok: boolean; status: number; text: string }) => {
  if (!r.ok) throw new Error(`${what} failed: HTTP ${r.status} ${r.text}`);
};

/** Removes the user; ON DELETE CASCADE clears their profile, listings and transactions. */
export async function deleteUser(id: string) {
  const r = await call('DELETE', `/auth/v1/admin/users/${id}`);
  if (r.status !== 404) expectOk(`delete user ${id}`, r);
}

/** Creates a confirmed auth user with a fixed id. The on_auth_user_created trigger adds a profile. */
export async function createUser(id: string, email: string) {
  expectOk(
    `create user ${email}`,
    await call('POST', '/auth/v1/admin/users', { id, email, password: PASSWORD, email_confirm: true }),
  );
}

export async function signIn(email: string): Promise<string> {
  const res = await fetch(`${API_URL()}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { apikey: ANON_KEY(), 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: PASSWORD }),
  });
  if (!res.ok) throw new Error(`sign in ${email} failed: HTTP ${res.status} ${await res.text()}`);
  return ((await res.json()) as { access_token: string }).access_token;
}

export async function patchRows(table: string, filter: string, values: Record<string, unknown>) {
  expectOk(`update ${table}?${filter}`, await call('PATCH', `/rest/v1/${table}?${filter}`, values));
}

export async function deleteRows(table: string, filter: string) {
  expectOk(`delete ${table}?${filter}`, await call('DELETE', `/rest/v1/${table}?${filter}`));
}

export async function insertRows(table: string, rows: Record<string, unknown>[]) {
  expectOk(`insert ${table}`, await call('POST', `/rest/v1/${table}`, rows));
}
