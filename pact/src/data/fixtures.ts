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
