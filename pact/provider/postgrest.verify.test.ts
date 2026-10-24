import { Verifier } from '@pact-foundation/pact';
import { PROVIDER_POSTGREST } from '../src/data/fixtures';
import { pactSource } from './pactSource';
import { currentUserToken, postgrestStates } from './states/postgrestStates';
import { ANON_KEY, API_URL } from './states/supabaseAdmin';

describe('PostgREST provider verification', () => {
  it('honours the sellscribe-app pact', () =>
    new Verifier({
      provider: PROVIDER_POSTGREST,
      // pact paths already start with /rest/v1
      providerBaseUrl: API_URL(),
      ...pactSource(PROVIDER_POSTGREST),
      stateHandlers: postgrestStates,
      // Swap the pact's example tokens for U1's real session so RLS applies as in the app
      requestFilter: (req, _res, next) => {
        req.headers.apikey = ANON_KEY();
        req.headers.authorization = `Bearer ${currentUserToken}`;
        next();
      },
      logLevel: 'warn',
    }).verifyProvider(), 120_000);
});
