import { MatchersV3 } from '@pact-foundation/pact';
import { USER_ID } from '../src/data/fixtures';
import { isoTimestamp } from '../src/matchers/common';
import { usedCreditTransactionBody } from '../src/matchers/creditTransaction';
import { postgrestClient, postgrestPact, writeHeaders } from '../src/pact/postgrest';

const { integer } = MatchersV3;

const pact = postgrestPact();

// AuthProvider.deductCredits is two non-atomic calls (D5); both halves are contracted.
describe('sellscribe-app → PostgREST deductCredits', () => {
  it('PR-5: step 1 decrements credits_remaining on the profile', () =>
    pact
      .addInteraction()
      .given('user U1 has a profile with 5 credits')
      .uponReceiving('an update of the remaining credits')
      .withRequest('PATCH', '/rest/v1/profiles', (b) =>
        b
          .query({ id: `eq.${USER_ID}` })
          .headers(writeHeaders())
          .jsonBody({
            credits_remaining: integer(4),
            updated_at: isoTimestamp('2026-10-24T20:00:00.000'),
          }),
      )
      .willRespondWith(204)
      .executeTest(async (mock) => {
        const updatedAt = new Date().toISOString().replace('Z', '');
        const res = await postgrestClient(mock.url).updateCredits(USER_ID, 4, updatedAt);
        expect(res.status).toBe(204);
      }));

  it('PR-6: step 2 records a "used" credit transaction', () =>
    pact
      .addInteraction()
      .given('user U1 has a profile with 5 credits')
      .uponReceiving('an insert of a used credit transaction')
      .withRequest('POST', '/rest/v1/credit_transactions', (b) =>
        b.headers(writeHeaders()).jsonBody(usedCreditTransactionBody),
      )
      .willRespondWith(201)
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).insertCreditTransaction({
          user_id: USER_ID,
          amount: -1,
          transaction_type: 'used',
          description: 'Listing generation',
        });
        expect(res.status).toBe(201);
      }));
});
