export function testUser() {
  return {
    email: process.env.TEST_EMAIL ?? 'test@example.com',
    password: process.env.TEST_PASSWORD ?? 'Password123!',
    name: process.env.TEST_NAME ?? 'Test User',
  };
}

export function newUser() {
  const ts = Date.now();
  return {
    email: `test_${ts}@example.com`,
    password: 'TestPass123!',
    name: `Test User ${ts}`,
    firstName: 'Test',
    lastName: `User${ts}`,
  };
}

export const mockListingResponse = {
  title: 'Premium Bamboo Wireless Charger — Fast Qi Charging',
  description: '<p>Eco-friendly fast charging solution.</p>',
  bullets: [
    'Fast 15W wireless charging',
    'Sustainable bamboo construction',
    'Universal Qi compatibility',
    'LED charging indicator',
    'Compact travel-friendly design',
  ],
  tags: ['wireless-charger', 'eco-friendly', 'bamboo', 'qi-charging', 'fast-charge'],
};

export const validListingPayload = {
  productName: 'Bamboo Wireless Charger',
  category: 'Electronics',
  keyFeatures: 'Eco-friendly, Fast 15W charging, LED indicator',
  targetAudience: 'Tech enthusiasts who care about sustainability',
  tone: 'professional',
};
