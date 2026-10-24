import { MatchersV3 } from '@pact-foundation/pact';
import { USER_ID } from '../data/fixtures';

const { integer, regex, uuid } = MatchersV3;

// AuthProvider.deductCredits step 2. transaction_type mirrors the table's CHECK constraint.
export const usedCreditTransactionBody = {
  user_id: uuid(USER_ID),
  amount: integer(-1),
  transaction_type: regex(/^(used|purchased|bonus|refund)$/, 'used'),
  description: 'Listing generation',
};
