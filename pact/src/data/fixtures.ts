// Fixed identifiers and payloads shared by consumer tests and provider states.
// Payloads mirror playwright/utils/test-data.ts so the two suites describe the same product.

export const CONSUMER = 'sellscribe-app';
export const PROVIDER_GENERATE_LISTING = 'sellscribe-generate-listing';

export const USER_ID = '11111111-1111-4111-8111-111111111111';
export const LISTING_ID = '22222222-2222-4222-8222-222222222222';

// Example tokens only — matched by regex, never sent to a real backend.
export const EXAMPLE_ANON_KEY = 'eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiJ9.example-anon';
export const EXAMPLE_ACCESS_TOKEN = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyIn0.example-user';

export const fullListingRequest = {
  productName: 'Bamboo Wireless Charger',
  category: 'Electronics',
  keyFeatures: 'Eco-friendly, Fast 15W charging, LED indicator',
  targetAudience: 'Tech enthusiasts who care about sustainability',
  tone: 'professional',
  imageUrls: ['https://example.supabase.co/storage/v1/object/public/product-images/u1/charger.jpg'],
};

// Optional fields the user left blank: the Dart client still sends the keys, as JSON null.
export const minimalListingRequest = {
  productName: 'Bamboo Wireless Charger',
  category: 'Electronics',
  keyFeatures: null,
  targetAudience: null,
  tone: 'professional',
  imageUrls: null,
};

export const exampleListing = {
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

// ── PostgREST (C2) ────────────────────────────────────────────────────────────
export const PROVIDER_POSTGREST = 'sellscribe-postgrest';

export const USER_EMAIL = 'pact-user1@example.com';
export const OTHER_USER_ID = '33333333-3333-4333-8333-333333333333';
export const OTHER_LISTING_ID = '44444444-4444-4444-8444-444444444444';

// Provider states seed these rows; every column UserProfile.fromJson reads is populated.
export const exampleProfile = {
  id: USER_ID,
  email: USER_EMAIL,
  display_name: 'pact-user1',
  first_name: 'Pact',
  last_name: 'User',
  mobile: '0400000000',
  address: '1 Contract St',
  city: 'Melbourne',
  state: 'VIC',
  zip_code: '3000',
  country: 'Australia',
  credits_remaining: 5,
  created_at: '2026-10-24T09:00:00.000000+00:00',
  updated_at: '2026-10-24T09:00:00.000000+00:00',
};

// ProductListing.toJson() for a freshly generated listing (no id / created_at yet).
export const newListingRow = {
  user_id: USER_ID,
  product_name: fullListingRequest.productName,
  category: fullListingRequest.category,
  key_features: fullListingRequest.keyFeatures,
  target_audience: fullListingRequest.targetAudience,
  tone: fullListingRequest.tone,
  generated_title: exampleListing.title,
  generated_description: exampleListing.description,
  generated_bullets: exampleListing.bullets,
  generated_tags: exampleListing.tags,
  image_urls: fullListingRequest.imageUrls,
  platform: 'shopify',
};

export const exampleListingRow = {
  id: LISTING_ID,
  ...newListingRow,
  created_at: '2026-10-24T09:05:00.000000+00:00',
};

// What Dart's DateTime.now().toIso8601String() produces: local time, no offset.
export const EXAMPLE_DART_TIMESTAMP = '2026-10-24T20:00:00.000';
