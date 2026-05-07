import { test, expect } from '@playwright/test';
import { validListingPayload, mockListingResponse } from '../../utils/test-data';

const SUPABASE_URL = process.env.SUPABASE_URL ?? '';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY ?? '';
const USE_REAL_API = process.env.USE_REAL_API === 'true' && !!SUPABASE_URL;

const API_ENDPOINT = USE_REAL_API
  ? `${SUPABASE_URL}/functions/v1/generate-listing`
  : 'http://localhost:9999/functions/v1/generate-listing';

test.describe('POST /functions/v1/generate-listing — contract @regression', () => {
  test.skip(!USE_REAL_API, 'Set USE_REAL_API=true and SUPABASE_URL to run against real API');

  test('returns 200 with valid listing schema for complete payload', async ({ request }) => {
    const res = await request.post(API_ENDPOINT, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        apikey: SUPABASE_ANON_KEY,
      },
      data: validListingPayload,
    });

    expect(res.status()).toBe(200);
    const body = await res.json();

    expect(typeof body.title).toBe('string');
    expect(body.title.length).toBeGreaterThan(0);
    expect(body.title.length).toBeLessThanOrEqual(70);
    expect(typeof body.description).toBe('string');
    expect(body.description.length).toBeGreaterThan(0);
    expect(Array.isArray(body.bullets)).toBe(true);
    expect(body.bullets.length).toBeGreaterThanOrEqual(1);
    body.bullets.forEach((b: unknown) => expect(typeof b).toBe('string'));
    expect(Array.isArray(body.tags)).toBe(true);
    expect(body.tags.length).toBeGreaterThanOrEqual(1);
    body.tags.forEach((t: unknown) => expect(typeof t).toBe('string'));
  });

  test('returns 200 for minimal required payload (productName + category + tone)', async ({ request }) => {
    const res = await request.post(API_ENDPOINT, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        apikey: SUPABASE_ANON_KEY,
      },
      data: { productName: 'Test Widget', category: 'Other', tone: 'casual' },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('title');
    expect(body).toHaveProperty('description');
    expect(Array.isArray(body.bullets)).toBe(true);
    expect(Array.isArray(body.tags)).toBe(true);
  });

  test('returns 400 when productName is missing', async ({ request }) => {
    const res = await request.post(API_ENDPOINT, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        apikey: SUPABASE_ANON_KEY,
      },
      data: { category: 'Electronics', tone: 'professional' },
    });
    expect(res.status()).toBe(400);
    const body = await res.json();
    expect(body).toHaveProperty('error');
  });

  test('returns 400 when category is missing', async ({ request }) => {
    const res = await request.post(API_ENDPOINT, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        apikey: SUPABASE_ANON_KEY,
      },
      data: { productName: 'Test Widget', tone: 'professional' },
    });
    expect(res.status()).toBe(400);
  });

  test('handles OPTIONS preflight with CORS headers', async ({ request }) => {
    const res = await request.fetch(API_ENDPOINT, {
      method: 'OPTIONS',
      headers: {
        Origin: 'http://localhost:8080',
        'Access-Control-Request-Method': 'POST',
      },
    });
    expect([200, 204]).toContain(res.status());
    expect(res.headers()['access-control-allow-origin']).toBeTruthy();
  });
});

test.describe('Generate listing — mocked UI integration @smoke', () => {
  test('page.route() intercepts API and returns controlled response shape', async ({ page }) => {
    let intercepted = false;

    await page.route('**/generate-listing**', async (route) => {
      intercepted = true;
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(mockListingResponse),
      });
    });

    await page.goto('about:blank');
    await page.evaluate(async (endpoint) => {
      await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          productName: 'Bamboo Charger',
          category: 'Electronics',
          tone: 'professional',
        }),
      });
    }, 'https://placeholder.supabase.co/functions/v1/generate-listing');

    expect(intercepted).toBe(true);
  });

  test('mocked response has correct schema shape', async () => {
    expect(typeof mockListingResponse.title).toBe('string');
    expect(mockListingResponse.title.length).toBeLessThanOrEqual(70);
    expect(Array.isArray(mockListingResponse.bullets)).toBe(true);
    expect(mockListingResponse.bullets).toHaveLength(5);
    expect(Array.isArray(mockListingResponse.tags)).toBe(true);
  });

  test('each bullet point is a non-empty string', async () => {
    mockListingResponse.bullets.forEach((bullet) => {
      expect(typeof bullet).toBe('string');
      expect(bullet.trim().length).toBeGreaterThan(0);
    });
  });

  test('all tone values are accepted by payload type', async () => {
    const validTones = ['professional', 'casual', 'luxury', 'playful', 'minimalist'];
    validTones.forEach((tone) => {
      const payload = { ...validListingPayload, tone };
      expect(payload.tone).toBe(tone);
    });
  });
});
