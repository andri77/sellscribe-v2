import { Verifier } from '@pact-foundation/pact';
import { PROVIDER_GENERATE_LISTING } from '../src/data/fixtures';
import { pactSource } from './pactSource';
import { edgeFnStates } from './states/edgeFnStates';
import { ANON_KEY, API_URL } from './states/supabaseAdmin';
import { OpenAiStub, startOpenAiStub } from './stubs/openai-stub';

// provider-up.sh serves the function with OPENAI_BASE_URL pointing at this port
const STUB_PORT = Number(process.env.OPENAI_STUB_PORT ?? 4010);

describe('generate-listing Edge Function provider verification', () => {
  let stub: OpenAiStub;

  beforeAll(async () => {
    stub = await startOpenAiStub(STUB_PORT);
  });
  afterAll(() => stub?.close());

  it('honours the sellscribe-app pact', () =>
    new Verifier({
      provider: PROVIDER_GENERATE_LISTING,
      providerBaseUrl: API_URL(),
      ...pactSource(PROVIDER_GENERATE_LISTING),
      stateHandlers: edgeFnStates(() => stub),
      // The gateway verifies the JWT; the anon key is a valid one for the local stack
      requestFilter: (req, _res, next) => {
        req.headers.apikey = ANON_KEY();
        req.headers.authorization = `Bearer ${ANON_KEY()}`;
        next();
      },
      logLevel: 'warn',
    }).verifyProvider(), 120_000);
});
