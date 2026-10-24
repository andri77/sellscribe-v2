import path from 'path';
import { MatchersV3, PactV4 } from '@pact-foundation/pact';
import { OBJECT_JSON, PostgrestClient } from '../clients/postgrestClient';
import {
  CONSUMER,
  EXAMPLE_ACCESS_TOKEN,
  EXAMPLE_ANON_KEY,
  PROVIDER_POSTGREST,
} from '../data/fixtures';

const { regex } = MatchersV3;

export const postgrestPact = () =>
  new PactV4({
    consumer: CONSUMER,
    provider: PROVIDER_POSTGREST,
    dir: path.resolve(__dirname, '../../pacts'),
    logLevel: 'warn',
  });

export const postgrestClient = (baseUrl: string) =>
  new PostgrestClient(baseUrl, EXAMPLE_ANON_KEY, EXAMPLE_ACCESS_TOKEN);

// Auth headers vary per session; the provider's requestFilter swaps in a real JWT for the state's user.
const authHeaders = {
  apikey: regex(/^[\w-]+\.[\w-]+\.[\w-]+$/, EXAMPLE_ANON_KEY),
  Authorization: regex(/^Bearer [\w-]+\.[\w-]+\.[\w-]+$/, `Bearer ${EXAMPLE_ACCESS_TOKEN}`),
};

// Only headers that change PostgREST semantics are pinned (plan §8). The empty `Prefer: ''`
// the SDK sends on plain writes is a no-op and deliberately not part of the contract.
const RETURN_REPRESENTATION = /(^|,)\s*return=representation\s*(,|$)/;

// single() responses come back as application/vnd.pgrst.object+json. The SDK ignores the
// response Content-Type, and jsonBody() would otherwise pin it to exactly application/json.
export const objectResponseHeaders = {
  'Content-Type': regex(
    /^application\/(vnd\.pgrst\.object\+)?json(;.*)?$/,
    'application/vnd.pgrst.object+json; charset=utf-8',
  ),
};

export const readHeaders = (accept?: 'array' | 'object') => ({
  ...authHeaders,
  'Accept-Profile': 'public',
  ...(accept === 'array' && { Accept: 'application/json' }),
  ...(accept === 'object' && { Accept: OBJECT_JSON }),
});

export const writeHeaders = (opts: { returnRow?: boolean; prefer?: string } = {}) => ({
  ...authHeaders,
  'Content-Profile': 'public',
  'Content-Type': 'application/json',
  ...(opts.returnRow && {
    Prefer: regex(RETURN_REPRESENTATION, ',return=representation'),
    Accept: OBJECT_JSON,
  }),
  ...(opts.prefer && { Prefer: opts.prefer }),
});
