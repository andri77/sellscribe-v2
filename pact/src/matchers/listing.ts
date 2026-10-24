import { MatchersV3 } from '@pact-foundation/pact';
import { exampleListing } from '../data/fixtures';

const { like, eachLike, regex } = MatchersV3;

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
