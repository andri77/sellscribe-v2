// Stands in for OpenAI during Edge Function verification. Provider states switch the mode via
// POST /__control {"mode": ...}; the function under test calls POST /v1/chat/completions.
import http from 'http';
import type { AddressInfo } from 'net';
import { exampleListing } from '../../src/data/fixtures';

export type StubMode = 'ok' | 'http500' | 'nonJson';

export interface OpenAiStub {
  port: number;
  setMode(mode: StubMode): void;
  close(): Promise<void>;
}

const completion = (content: string) => ({
  id: 'chatcmpl-pact',
  object: 'chat.completion',
  model: 'gpt-4o',
  choices: [{ index: 0, message: { role: 'assistant', content }, finish_reason: 'stop' }],
});

export function startOpenAiStub(port = 4010, host = '0.0.0.0'): Promise<OpenAiStub> {
  let mode: StubMode = 'ok';

  const server = http.createServer((req, res) => {
    const send = (status: number, body: unknown) => {
      res.writeHead(status, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(body));
    };

    let raw = '';
    req.on('data', (chunk) => (raw += chunk));
    req.on('end', () => {
      if (req.method === 'POST' && req.url === '/__control') {
        mode = (JSON.parse(raw || '{}').mode ?? 'ok') as StubMode;
        return send(200, { mode });
      }
      if (req.method === 'POST' && req.url === '/v1/chat/completions') {
        if (mode === 'http500') return send(500, { error: { message: 'stubbed outage' } });
        if (mode === 'nonJson') return send(200, completion('Sorry, I cannot help with that.'));
        return send(200, completion(JSON.stringify(exampleListing)));
      }
      send(404, { error: `stub has no route for ${req.method} ${req.url}` });
    });
  });

  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(port, host, () =>
      resolve({
        port: (server.address() as AddressInfo).port,
        setMode: (m) => (mode = m),
        close: () => new Promise((done) => server.close(() => done())),
      }),
    );
  });
}
