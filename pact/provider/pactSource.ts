// Where the verifier gets pacts from, in order of precedence:
//   PACT_URL              — a single pact, as sent by a broker "contract changed" webhook
//   PACT_BROKER_BASE_URL  — latest pacts from the broker, results published back (CI)
//   otherwise             — the local pacts/ directory (offline / no broker yet)
import path from 'path';
import type { VerifierOptions } from '@pact-foundation/pact';
import { CONSUMER } from '../src/data/fixtures';

export function pactSource(provider: string): Partial<VerifierOptions> {
  const brokerUrl = process.env.PACT_BROKER_BASE_URL;
  const broker = brokerUrl
    ? {
        pactBrokerUrl: brokerUrl,
        pactBrokerToken: process.env.PACT_BROKER_TOKEN,
        publishVerificationResult: process.env.CI === 'true',
        providerVersion: process.env.GITHUB_SHA ?? 'local',
        providerVersionBranch: process.env.GITHUB_REF_NAME ?? 'local',
      }
    : {};

  if (process.env.PACT_URL) return { ...broker, pactUrls: [process.env.PACT_URL] };
  if (brokerUrl) {
    return {
      ...broker,
      consumerVersionSelectors: [{ mainBranch: true }, { matchingBranch: true }, { deployedOrReleased: true }],
      enablePending: true,
    };
  }
  return { pactUrls: [path.resolve(__dirname, `../pacts/${CONSUMER}-${provider}.json`)] };
}
