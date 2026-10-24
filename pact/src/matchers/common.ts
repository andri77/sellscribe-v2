import { MatchersV3 } from '@pact-foundation/pact';

const { regex } = MatchersV3;

// Dart's toIso8601String() omits the offset for local times; PostgREST returns +00:00.
const ISO_TIMESTAMP = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$/;

export const isoTimestamp = (example: string) => regex(ISO_TIMESTAMP, example);
