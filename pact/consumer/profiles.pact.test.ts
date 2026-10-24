import { MatchersV3 } from '@pact-foundation/pact';
import { USER_EMAIL, USER_ID } from '../src/data/fixtures';
import { isoTimestamp } from '../src/matchers/common';
import { createProfileBody, profileBody } from '../src/matchers/profile';
import {
  postgrestClient,
  postgrestPact,
  readHeaders,
  writeHeaders,
} from '../src/pact/postgrest';

const { integer, like, uuid } = MatchersV3;

const pact = postgrestPact();
const PROFILES = '/rest/v1/profiles';
const byId = { select: '*', id: `eq.${USER_ID}` };

// DateTime.now().toIso8601String(): local time, no offset
const dartNow = () => new Date().toISOString().replace('Z', '');

describe('sellscribe-app → PostgREST /profiles', () => {
  it('PR-1: getCurrentProfile (maybeSingle) returns the profile as a one-row array', () =>
    pact
      .addInteraction()
      .given('user U1 has a profile with 5 credits')
      .uponReceiving('a maybeSingle request for the current profile')
      .withRequest('GET', PROFILES, (b) => b.query(byId).headers(readHeaders('array')))
      .willRespondWith(200, (b) => b.jsonBody([profileBody]))
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).getCurrentProfile(USER_ID);
        expect(res.status).toBe(200);
        expect(res.data).toMatchObject({ id: USER_ID, credits_remaining: 5 });
      }));

  it('PR-2: getCurrentProfile (maybeSingle) returns an empty array when no profile exists', () =>
    pact
      .addInteraction()
      .given('user U1 has no profile')
      .uponReceiving('a maybeSingle request for a missing profile')
      .withRequest('GET', PROFILES, (b) => b.query(byId).headers(readHeaders('array')))
      .willRespondWith(200, (b) => b.jsonBody([]))
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).getCurrentProfile(USER_ID);
        expect(res.status).toBe(200);
        expect(res.data).toBeNull();
      }));

  it('PR-3: _createProfile inserts a profile row', () =>
    pact
      .addInteraction()
      .given('user U1 has no profile')
      .uponReceiving('an insert of a new profile')
      .withRequest('POST', PROFILES, (b) => b.headers(writeHeaders()).jsonBody(createProfileBody))
      .willRespondWith(201)
      .executeTest(async (mock) => {
        const now = dartNow();
        const res = await postgrestClient(mock.url).createProfile({
          id: USER_ID,
          email: USER_EMAIL,
          display_name: null,
          first_name: null,
          last_name: null,
          credits_remaining: 5,
          created_at: now,
          updated_at: now,
        });
        expect(res.status).toBe(201);
      }));

  it('PR-13: getCurrentProfile refetch (single) returns the profile object', () =>
    pact
      .addInteraction()
      .given('user U1 has a profile with 5 credits')
      .uponReceiving('a single request for the current profile')
      .withRequest('GET', PROFILES, (b) => b.query(byId).headers(readHeaders('object')))
      .willRespondWith(200, (b) => b.jsonBody(profileBody))
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).getProfileSingle(USER_ID);
        expect(res.status).toBe(200);
        expect(res.data).toMatchObject({ id: USER_ID, email: USER_EMAIL });
      }));

  // updateProfile always sends credits_remaining: 5, so saving the profile resets credits (D6).
  // The contract records the request as the app sends it today.
  it('PR-4: updateProfile upserts on id with merge-duplicates', () =>
    pact
      .addInteraction()
      .given('user U1 has a profile with 5 credits')
      .uponReceiving('an upsert of profile details')
      .withRequest('POST', PROFILES, (b) =>
        b
          .query({ on_conflict: 'id' })
          .headers(writeHeaders({ prefer: 'resolution=merge-duplicates' }))
          .jsonBody({
            id: uuid(USER_ID),
            email: like(USER_EMAIL),
            credits_remaining: integer(5),
            updated_at: isoTimestamp('2026-10-24T20:00:00.000'),
            first_name: like('Pact'),
            last_name: like('User'),
            city: like('Melbourne'),
          }),
      )
      // PostgREST answers 201 for upserts; the SDK accepts any 2xx (confirm in M4).
      .willRespondWith(201)
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).upsertProfile({
          id: USER_ID,
          email: USER_EMAIL,
          credits_remaining: 5,
          updated_at: dartNow(),
          first_name: 'Pact',
          last_name: 'User',
          city: 'Melbourne',
        });
        expect(res.status).toBe(201);
      }));
});
