import type { VerifierOptions } from '@pact-foundation/pact';

// Not re-exported from the package root in pact-js 17
export type StateHandlers = NonNullable<VerifierOptions['stateHandlers']>;
