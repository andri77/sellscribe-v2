import type { StateHandlers } from '../types';
import type { OpenAiStub } from '../stubs/openai-stub';

export const edgeFnStates = (stub: () => OpenAiStub): StateHandlers => ({
  'OpenAI returns a valid listing': async () => stub().setMode('ok'),
  'OpenAI is unavailable': async () => stub().setMode('http500'),
});
