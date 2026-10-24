import path from 'path';
import { MatchersV3, PactV4 } from '@pact-foundation/pact';
import { EdgeFunctionClient } from '../src/clients/edgeFunctionClient';
import {
  CONSUMER,
  EXAMPLE_ACCESS_TOKEN,
  EXAMPLE_ANON_KEY,
  PROVIDER_GENERATE_LISTING,
  fullListingRequest,
  minimalListingRequest,
} from '../src/data/fixtures';
import { errorBody, generatedListingBody } from '../src/matchers/listing';

const { regex } = MatchersV3;

const PATH = '/functions/v1/generate-listing';

const pact = new PactV4({
  consumer: CONSUMER,
  provider: PROVIDER_GENERATE_LISTING,
  dir: path.resolve(__dirname, '../pacts'),
  logLevel: 'warn',
});

// Auth headers vary per session; only their shape is part of the contract.
const requestHeaders = {
  'Content-Type': 'application/json',
  Authorization: regex(/^Bearer [\w-]+\.[\w-]+\.[\w-]+$/, `Bearer ${EXAMPLE_ACCESS_TOKEN}`),
  apikey: regex(/^[\w-]+\.[\w-]+\.[\w-]+$/, EXAMPLE_ANON_KEY),
};
const responseHeaders = { 'Content-Type': 'application/json' };

const client = (baseUrl: string) =>
  new EdgeFunctionClient(baseUrl, EXAMPLE_ANON_KEY, EXAMPLE_ACCESS_TOKEN);

describe('sellscribe-app → generate-listing Edge Function', () => {
  it('GL-1: returns a listing for a full request (incl. imageUrls)', () =>
    pact
      .addInteraction()
      .given('OpenAI returns a valid listing')
      .uponReceiving('a full generate-listing request')
      .withRequest('POST', PATH, (b) => b.headers(requestHeaders).jsonBody(fullListingRequest))
      .willRespondWith(200, (b) => b.headers(responseHeaders).jsonBody(generatedListingBody))
      .executeTest(async (mock) => {
        const res = await client(mock.url).generateListing(fullListingRequest);
        expect(res.status).toBe(200);
        expect(res.data).toEqual({
          title: expect.any(String),
          description: expect.any(String),
          bullets: expect.arrayContaining([expect.any(String)]),
          tags: expect.arrayContaining([expect.any(String)]),
        });
      }));

  it('GL-2: returns a listing when optional fields are null', () =>
    pact
      .addInteraction()
      .given('OpenAI returns a valid listing')
      .uponReceiving('a minimal generate-listing request with null optionals')
      .withRequest('POST', PATH, (b) => b.headers(requestHeaders).jsonBody(minimalListingRequest))
      .willRespondWith(200, (b) => b.headers(responseHeaders).jsonBody(generatedListingBody))
      .executeTest(async (mock) => {
        const res = await client(mock.url).generateListing(minimalListingRequest);
        expect(res.status).toBe(200);
        expect(res.data).toHaveProperty('title');
      }));

  // productName/category are non-nullable in Dart, so "missing" on the wire is an empty string.
  it('GL-3: rejects an empty productName with 400', () => {
    const body = { ...minimalListingRequest, productName: '' };
    return pact
      .addInteraction()
      .uponReceiving('a generate-listing request with an empty productName')
      .withRequest('POST', PATH, (b) => b.headers(requestHeaders).jsonBody(body))
      .willRespondWith(400, (b) =>
        b.headers(responseHeaders).jsonBody(errorBody('Product name and category are required')),
      )
      .executeTest(async (mock) => {
        const res = await client(mock.url).generateListing(body);
        expect(res.status).toBe(400);
        expect(res.data).toEqual({ error: expect.any(String) });
      });
  });

  it('GL-4: rejects an empty category with 400', () => {
    const body = { ...minimalListingRequest, category: '' };
    return pact
      .addInteraction()
      .uponReceiving('a generate-listing request with an empty category')
      .withRequest('POST', PATH, (b) => b.headers(requestHeaders).jsonBody(body))
      .willRespondWith(400, (b) =>
        b.headers(responseHeaders).jsonBody(errorBody('Product name and category are required')),
      )
      .executeTest(async (mock) => {
        const res = await client(mock.url).generateListing(body);
        expect(res.status).toBe(400);
        expect(res.data).toEqual({ error: expect.any(String) });
      });
  });

  it('GL-5: returns 500 when the upstream AI call fails', () =>
    pact
      .addInteraction()
      .given('OpenAI is unavailable')
      .uponReceiving('a generate-listing request while OpenAI is down')
      .withRequest('POST', PATH, (b) => b.headers(requestHeaders).jsonBody(fullListingRequest))
      .willRespondWith(500, (b) =>
        b.headers(responseHeaders).jsonBody(errorBody('Failed to generate listing')),
      )
      .executeTest(async (mock) => {
        const res = await client(mock.url).generateListing(fullListingRequest);
        expect(res.status).toBe(500);
        expect(res.data).toEqual({ error: expect.any(String) });
      }));
});
