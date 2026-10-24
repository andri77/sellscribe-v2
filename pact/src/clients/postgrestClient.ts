// Mirrors the supabase_flutter (postgrest 2.6.0) wire format for every call in
// AuthService, AuthProvider and ListingProvider. Header quirks are reproduced on purpose:
//   - insert/update/delete set `Prefer: ''`; adding .select() makes it `,return=representation`
//   - maybeSingle() on GET sends `Accept: application/json` and unwraps the array client-side
//   - single() sends `Accept: application/vnd.pgrst.object+json`
//   - reads carry `Accept-Profile: public`, writes `Content-Profile: public`

export const OBJECT_JSON = 'application/vnd.pgrst.object+json';

export interface PostgrestResult<T = unknown> {
  status: number;
  data: T;
}

type Method = 'GET' | 'POST' | 'PATCH' | 'DELETE';

interface RequestOptions {
  query?: Record<string, string>;
  body?: unknown;
  prefer?: string;
  accept?: string;
}

export class PostgrestClient {
  constructor(
    private readonly baseUrl: string,
    private readonly anonKey: string,
    private readonly accessToken: string,
  ) {}

  // ── AuthService ────────────────────────────────────────────────────────────

  /** getCurrentProfile: .select().eq('id', userId).maybeSingle() */
  async getCurrentProfile(userId: string) {
    const res = await this.request('GET', 'profiles', {
      query: { select: '*', id: `eq.${userId}` },
      accept: 'application/json',
    });
    // maybeSingle unwraps the array the same way postgrest-dart does
    const rows = res.data as unknown[];
    return { ...res, data: rows.length === 1 ? rows[0] : null };
  }

  /** getCurrentProfile refetch after create: .select().eq('id', userId).single() */
  getProfileSingle(userId: string) {
    return this.request('GET', 'profiles', {
      query: { select: '*', id: `eq.${userId}` },
      accept: OBJECT_JSON,
    });
  }

  /** _createProfile: .insert({...}) */
  createProfile(row: Record<string, unknown>) {
    return this.request('POST', 'profiles', { body: row, prefer: '' });
  }

  /** updateProfile: .upsert(data, onConflict: 'id') */
  upsertProfile(row: Record<string, unknown>) {
    return this.request('POST', 'profiles', {
      query: { on_conflict: 'id' },
      body: row,
      prefer: 'resolution=merge-duplicates',
    });
  }

  // ── AuthProvider.deductCredits ─────────────────────────────────────────────

  /** step 1: .update({credits_remaining, updated_at}).eq('id', userId) */
  updateCredits(userId: string, creditsRemaining: number, updatedAt: string) {
    return this.request('PATCH', 'profiles', {
      query: { id: `eq.${userId}` },
      body: { credits_remaining: creditsRemaining, updated_at: updatedAt },
      prefer: '',
    });
  }

  /** step 2: credit_transactions.insert({...}) */
  insertCreditTransaction(row: Record<string, unknown>) {
    return this.request('POST', 'credit_transactions', { body: row, prefer: '' });
  }

  // ── ListingProvider ────────────────────────────────────────────────────────

  /** _saveListing: .insert(listing.toJson()).select().single() */
  saveListing(row: Record<string, unknown>) {
    return this.request('POST', 'listings', {
      query: { select: '*' },
      body: row,
      prefer: ',return=representation',
      accept: OBJECT_JSON,
    });
  }

  /** loadHistory: .select().eq('user_id', userId).order('created_at', ascending: false) */
  loadHistory(userId: string) {
    return this.request('GET', 'listings', {
      query: { select: '*', user_id: `eq.${userId}`, order: 'created_at.desc.nullslast' },
    });
  }

  /** getListingById: .select().eq('id', id).single() */
  getListingById(id: string) {
    return this.request('GET', 'listings', {
      query: { select: '*', id: `eq.${id}` },
      accept: OBJECT_JSON,
    });
  }

  /** updateListing: .update(updateData).eq('id', id).select().single() */
  updateListing(id: string, updates: Record<string, unknown>) {
    return this.request('PATCH', 'listings', {
      query: { id: `eq.${id}`, select: '*' },
      body: updates,
      prefer: ',return=representation',
      accept: OBJECT_JSON,
    });
  }

  /** deleteListing: .delete().eq('id', id) */
  deleteListing(id: string) {
    return this.request('DELETE', 'listings', { query: { id: `eq.${id}` }, prefer: '' });
  }

  // ── transport ──────────────────────────────────────────────────────────────

  private async request(
    method: Method,
    table: string,
    { query, body, prefer, accept }: RequestOptions,
  ): Promise<PostgrestResult> {
    const url = new URL(`${this.baseUrl}/rest/v1/${table}`);
    for (const [k, v] of Object.entries(query ?? {})) url.searchParams.set(k, v);

    const headers: Record<string, string> = {
      apikey: this.anonKey,
      Authorization: `Bearer ${this.accessToken}`,
    };
    if (prefer !== undefined) headers.Prefer = prefer;
    if (accept !== undefined) headers.Accept = accept;
    if (method === 'GET') {
      headers['Accept-Profile'] = 'public';
    } else {
      headers['Content-Profile'] = 'public';
      headers['Content-Type'] = 'application/json';
    }

    const res = await fetch(url, {
      method,
      headers,
      body: method === 'GET' || method === 'DELETE' ? undefined : JSON.stringify(body),
    });
    const text = await res.text();
    return { status: res.status, data: text ? JSON.parse(text) : null };
  }
}
