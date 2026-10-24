/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/consumer/**/*.pact.test.ts', '**/provider/**/*.verify.test.ts'],
  testTimeout: 30_000,
};
