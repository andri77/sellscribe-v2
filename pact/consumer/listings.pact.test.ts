import { MatchersV3 } from '@pact-foundation/pact';
import {
  LISTING_ID,
  OTHER_LISTING_ID,
  USER_ID,
  exampleListingRow,
  newListingRow,
} from '../src/data/fixtures';
import { listingRowBody } from '../src/matchers/listing';
import {
  postgrestClient,
  postgrestPact,
  readHeaders,
  writeHeaders,
} from '../src/pact/postgrest';

const { eachLike, like, uuid } = MatchersV3;

const pact = postgrestPact();
const LISTINGS = '/rest/v1/listings';

describe('sellscribe-app → PostgREST /listings', () => {
  it('PR-7: _saveListing inserts and returns the created row', () =>
    pact
      .addInteraction()
      .given('user U1 has a profile with 5 credits')
      .uponReceiving('an insert of a generated listing returning the row')
      .withRequest('POST', LISTINGS, (b) =>
        b
          .query({ select: '*' })
          .headers(writeHeaders({ returnRow: true }))
          .jsonBody({ ...newListingRow, user_id: uuid(USER_ID) }),
      )
      .willRespondWith(201, (b) => b.jsonBody(listingRowBody()))
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).saveListing(newListingRow);
        expect(res.status).toBe(201);
        expect(res.data).toMatchObject({ id: LISTING_ID, user_id: USER_ID });
      }));

  it('PR-8: loadHistory lists the user\'s listings newest first', () =>
    pact
      .addInteraction()
      .given('user U1 has 2 listings')
      .uponReceiving('a request for the listing history')
      .withRequest('GET', LISTINGS, (b) =>
        b
          .query({ select: '*', user_id: `eq.${USER_ID}`, order: 'created_at.desc.nullslast' })
          .headers(readHeaders()),
      )
      .willRespondWith(200, (b) => b.jsonBody(eachLike(listingRowBody(), 2)))
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).loadHistory(USER_ID);
        expect(res.status).toBe(200);
        expect(res.data).toHaveLength(2);
      }));

  it('PR-9: getListingById returns a single row', () =>
    pact
      .addInteraction()
      .given('listing L1 exists for user U1')
      .uponReceiving('a single request for listing L1')
      .withRequest('GET', LISTINGS, (b) =>
        b.query({ select: '*', id: `eq.${LISTING_ID}` }).headers(readHeaders('object')),
      )
      .willRespondWith(200, (b) => b.jsonBody(listingRowBody()))
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).getListingById(LISTING_ID);
        expect(res.status).toBe(200);
        expect(res.data).toMatchObject({ id: LISTING_ID });
      }));

  it('PR-10: updateListing patches only edited fields and returns the row', () => {
    const edits = {
      generated_title: 'Bamboo Wireless Charger — Edited',
      generated_tags: ['bamboo', 'charger'],
    };
    return pact
      .addInteraction()
      .given('listing L1 exists for user U1')
      .uponReceiving('an update of listing L1 returning the row')
      .withRequest('PATCH', LISTINGS, (b) =>
        b
          .query({ id: `eq.${LISTING_ID}`, select: '*' })
          .headers(writeHeaders({ returnRow: true }))
          .jsonBody({
            generated_title: like(edits.generated_title),
            generated_tags: eachLike(edits.generated_tags[0], 1),
          }),
      )
      .willRespondWith(200, (b) =>
        b.jsonBody(listingRowBody({ ...exampleListingRow, ...edits })),
      )
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).updateListing(LISTING_ID, edits);
        expect(res.status).toBe(200);
        expect(res.data).toMatchObject({ id: LISTING_ID });
      });
  });

  it('PR-11: deleteListing removes listing L1', () =>
    pact
      .addInteraction()
      .given('listing L1 exists for user U1')
      .uponReceiving('a delete of listing L1')
      .withRequest('DELETE', LISTINGS, (b) =>
        b.query({ id: `eq.${LISTING_ID}` }).headers(writeHeaders()),
      )
      .willRespondWith(204)
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).deleteListing(LISTING_ID);
        expect(res.status).toBe(204);
      }));

  // RLS hides U2's row, so single() finds zero rows; the app turns this into "Failed to load listing".
  it('PR-12: getListingById cannot read another user\'s listing (RLS)', () =>
    pact
      .addInteraction()
      .given('listing L2 exists for user U2')
      .uponReceiving('a single request for another user\'s listing L2')
      .withRequest('GET', LISTINGS, (b) =>
        b.query({ select: '*', id: `eq.${OTHER_LISTING_ID}` }).headers(readHeaders('object')),
      )
      .willRespondWith(406, (b) =>
        b.jsonBody({
          code: 'PGRST116',
          message: like('JSON object requested, multiple (or no) rows returned'),
        }),
      )
      .executeTest(async (mock) => {
        const res = await postgrestClient(mock.url).getListingById(OTHER_LISTING_ID);
        expect(res.status).toBe(406);
        expect(res.data).toMatchObject({ code: 'PGRST116' });
      }));
});
