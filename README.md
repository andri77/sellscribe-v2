# SellScribe

AI-powered product listing generator for Shopify sellers. Create compelling titles, descriptions, bullet points, and SEO tags in seconds.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture Overview](#architecture-overview)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Components](#components)
- [Scripts](#scripts)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)

## Features

- **AI-Powered Copy Generation**: Uses GPT-4o to create optimized product listings
- **Multiple Tone Options**: Professional, Casual, Luxury, Playful, or Minimalist
- **Image Upload**: Support for up to 5 product images per listing
- **One-Click Copy**: Easy clipboard integration for all generated content
- **Credit System**: Start with 5 free generations
- **History**: Save and revisit all your generated listings
- **Responsive Design**: Works on desktop and tablet (768px+)
- **Mock Mode**: Test without API keys using sample data

## Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Flutter Web | Cross-platform UI framework |
| **State Management** | Provider | Reactive state management |
| **Navigation** | GoRouter | Declarative routing |
| **Backend** | Supabase | PostgreSQL database, Auth, Storage |
| **Serverless** | Supabase Edge Functions | AI API proxy (Deno runtime) |
| **AI** | OpenAI GPT-4o | Marketing copy generation |
| **Hosting** | Vercel / Firebase | Static web hosting |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Web App                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │  Screens │  │ Providers│  │ Services │  │  Widgets │        │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────────┘        │
│       │             │             │                              │
└───────┼─────────────┼─────────────┼──────────────────────────────┘
        │             │             │
        ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Supabase                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐    │
│  │   Auth   │  │ Database │  │ Storage  │  │Edge Functions│    │
│  │(GoTrue)  │  │(Postgres)│  │ (S3-like)│  │   (Deno)     │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────┬───────┘    │
└──────────────────────────────────────────────────┼──────────────┘
                                                    │
                                                    ▼
                                          ┌──────────────────┐
                                          │   OpenAI API     │
                                          │    (GPT-4o)      │
                                          └──────────────────┘
```

### Data Flow

1. **User Authentication**: User signs up/in via Supabase Auth
2. **Profile Creation**: Trigger auto-creates profile with 5 credits
3. **Image Upload**: Images uploaded to Supabase Storage bucket
4. **Listing Generation**:
   - App sends product details to AI Service
   - AI Service calls OpenAI (or Edge Function)
   - Generated content returned and saved to database
5. **Credit Deduction**: 1 credit deducted per generation

## Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Install all requirements
./scripts/install.sh

# Configure environment (edit .env with your keys)
nano .env

# Start the application
./scripts/start.sh
```

### Option 2: Manual Setup

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Copy environment file
cp .env.example .env

# 3. Add your Supabase credentials to .env

# 4. Run the app
flutter run -d chrome
```

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for detailed setup guide.

## Project Structure

```
SellScribe/
├── lib/                          # Flutter application code
│   ├── main.dart                 # App entry point & initialization
│   ├── config/                   # Configuration files
│   │   ├── app_config.dart       # Environment variables loader
│   │   ├── routes.dart           # GoRouter route definitions
│   │   └── theme.dart            # Material 3 theme configuration
│   ├── models/                   # Data models
│   │   ├── user.dart             # UserProfile model
│   │   ├── product_listing.dart  # ProductListing + categories
│   │   └── credit.dart           # CreditTransaction model
│   ├── services/                 # Business logic & API calls
│   │   ├── supabase_service.dart # Supabase client singleton
│   │   ├── auth_service.dart     # Authentication operations
│   │   ├── ai_service.dart       # OpenAI API integration
│   │   └── storage_service.dart  # Image upload handling
│   ├── providers/                # State management
│   │   ├── auth_provider.dart    # Auth state & user profile
│   │   └── listing_provider.dart # Listing CRUD & generation
│   ├── screens/                  # UI screens
│   │   ├── splash/               # Initial loading screen
│   │   ├── auth/                 # Login & Register screens
│   │   ├── home/                 # Dashboard screen
│   │   ├── generator/            # Upload, Details, Results
│   │   └── history/              # Past listings view
│   └── widgets/                  # Reusable UI components
│       ├── common/               # AppButton, AppTextField, etc.
│       └── generator/            # ImagePicker, CopyButton, etc.
├── web/                          # Web-specific files
│   ├── index.html                # HTML entry point
│   ├── manifest.json             # PWA manifest
│   └── icons/                    # App icons
├── supabase/                     # Supabase configuration
│   ├── migrations/               # Database schema SQL files
│   │   ├── 001_initial_schema.sql
│   │   └── 002_storage_bucket.sql
│   └── functions/                # Edge Functions
│       └── generate-listing/     # AI generation function
│           └── index.ts
├── scripts/                      # Automation scripts
│   ├── install.sh                # Install all dependencies
│   ├── start.sh                  # Start development server
│   └── build.sh                  # Build for production
├── .env.example                  # Environment template
├── .env                          # Local environment (git-ignored)
├── pubspec.yaml                  # Flutter dependencies
├── README.md                     # This file
└── INSTRUCTIONS.md               # Detailed setup instructions
```

## Components

### Frontend Components

| Component | Location | Description |
|-----------|----------|-------------|
| **SplashScreen** | `screens/splash/` | Initial loading, auth check |
| **LoginScreen** | `screens/auth/` | Email/password sign in |
| **RegisterScreen** | `screens/auth/` | New user registration |
| **HomeScreen** | `screens/home/` | Dashboard with credits, quick actions |
| **UploadScreen** | `screens/generator/` | Image upload (0-5 images) |
| **DetailsScreen** | `screens/generator/` | Product details form |
| **ResultsScreen** | `screens/generator/` | Generated content display |
| **HistoryScreen** | `screens/history/` | Past listings list |

### Services

| Service | Purpose |
|---------|---------|
| **SupabaseService** | Singleton wrapper for Supabase client |
| **AuthService** | Sign up, sign in, sign out, password reset |
| **AiService** | OpenAI API calls with mock fallback |
| **StorageService** | Image upload to Supabase Storage |

### Database Tables

| Table | Description |
|-------|-------------|
| **profiles** | User profiles (extends auth.users) |
| **listings** | Generated product listings |
| **credit_transactions** | Credit usage history |

## Scripts

| Script | Command | Description |
|--------|---------|-------------|
| **install.sh** | `./scripts/install.sh` | Install Flutter, dependencies, setup env |
| **start.sh** | `./scripts/start.sh` | Start Flutter web dev server |
| **build.sh** | `./scripts/build.sh` | Build production web bundle |

See [INSTRUCTIONS.md](INSTRUCTIONS.md) for detailed script documentation.

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# Required: Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Optional: OpenAI (leave empty for mock mode)
OPENAI_API_KEY=sk-...
```

### Getting API Keys

1. **Supabase**:
   - Create project at [supabase.com](https://supabase.com)
   - Go to Project Settings > API
   - Copy "Project URL" and "anon/public" key

2. **OpenAI** (optional):
   - Get API key at [platform.openai.com](https://platform.openai.com/api-keys)
   - New accounts get ~$5 free credits

## Deployment

### Build for Production

```bash
./scripts/build.sh
# Output: build/web/
```

### Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
cd build/web
vercel
```

### Deploy to Firebase Hosting

```bash
# Install Firebase CLI
npm i -g firebase-tools

# Initialize (select Hosting, use build/web as public dir)
firebase init

# Deploy
firebase deploy
```

### Deploy Supabase Edge Function

```bash
# Install Supabase CLI
npm i -g supabase

# Login and link project
supabase login
supabase link --project-ref your-project-id

# Deploy function
supabase functions deploy generate-listing
```

## API Reference

### Supabase Edge Function

**Endpoint**: `POST /functions/v1/generate-listing`

**Request Body**:
```json
{
  "productName": "Bamboo Wireless Charger",
  "category": "Electronics",
  "keyFeatures": "Eco-friendly, Fast charging, LED indicator",
  "targetAudience": "Tech enthusiasts",
  "tone": "professional"
}
```

**Response**:
```json
{
  "title": "Premium Bamboo Wireless Charger - Fast Qi Charging",
  "description": "<p>Introducing the...</p>",
  "bullets": ["Fast 15W charging...", "..."],
  "tags": ["wireless-charger", "eco-friendly", "..."]
}
```

### Tone Options

| Value | Style |
|-------|-------|
| `professional` | Formal, business-like |
| `casual` | Friendly, conversational |
| `luxury` | Premium, sophisticated |
| `playful` | Fun, energetic |
| `minimalist` | Clean, concise |

### Product Categories

Electronics, Clothing & Apparel, Home & Garden, Beauty & Personal Care, Sports & Outdoors, Toys & Games, Food & Beverages, Health & Wellness, Jewelry & Accessories, Books & Media, Automotive, Pet Supplies, Office Supplies, Arts & Crafts, Baby & Kids, Other

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Supabase not initialized" | Check SUPABASE_URL and SUPABASE_ANON_KEY in .env |
| Images not uploading | Verify storage bucket exists and RLS policies |
| AI returning mock data | Add OPENAI_API_KEY to .env for real generation |
| CORS errors | Ensure Edge Function has correct CORS headers |
| Auth not persisting | Check Supabase Auth settings |

### Debug Mode

Enable verbose logging:
```dart
// In main.dart
debugPrint('Supabase URL: ${AppConfig.supabaseUrl}');
debugPrint('Mock AI: ${AppConfig.useMockAi}');
```

### Reset Local Data

```bash
# Clear Flutter build cache
flutter clean
flutter pub get

# Restart
flutter run -d chrome
```

## Free Tier Limits

| Service | Free Tier Limit |
|---------|-----------------|
| Supabase Database | 500 MB |
| Supabase Storage | 1 GB |
| Supabase Auth | 50,000 MAU |
| Supabase Edge Functions | 500,000 invocations/month |
| OpenAI | ~$5 credits (new accounts) |
| Vercel | 100 GB bandwidth |

## License

MIT License - see LICENSE file for details.

---

For detailed setup instructions, see [INSTRUCTIONS.md](INSTRUCTIONS.md).
