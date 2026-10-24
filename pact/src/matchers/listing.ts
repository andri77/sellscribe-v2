import { MatchersV3 } from '@pact-foundation/pact';
import { exampleListing, exampleListingRow } from '../data/fixtures';
import { isoTimestamp } from './common';

const { like, eachLike, regex, uuid } = MatchersV3;

// The contract is the shape AiService/ListingProvider read, not the AI copy itself.
export const generatedListingBody = {
  title: regex(/^.{1,70}$/, exampleListing.title),
  description: like(exampleListing.description),
  bullets: eachLike(exampleListing.bullets[0], 1),
  tags: eachLike(exampleListing.tags[0], 1),
};

export const errorBody = (example: string) => ({
  error: like(example),
});

// ── listings table rows (C2) ──────────────────────────────────────────────────
// Every key ProductListing.fromJson reads.
export const listingRowBody = (row: typeof exampleListingRow = exampleListingRow) => ({
  id: uuid(row.id),
  user_id: uuid(row.user_id),
  product_name: like(row.product_name),
  category: like(row.category),
  key_features: like(row.key_features),
  target_audience: like(row.target_audience),
  tone: like(row.tone),
  generated_title: like(row.generated_title),
  generated_description: like(row.generated_description),
  generated_bullets: eachLike(row.generated_bullets[0], 1),
  generated_tags: eachLike(row.generated_tags[0], 1),
  image_urls: eachLike(row.image_urls[0], 1),
  platform: like(row.platform),
  created_at: isoTimestamp(row.created_at),
});
