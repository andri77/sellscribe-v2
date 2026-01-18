# SellScribe - Detailed Setup Instructions

This document provides comprehensive instructions for setting up, running, and deploying the SellScribe application.

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Installation](#2-installation)
3. [Configuration](#3-configuration)
4. [Database Setup](#4-database-setup)
5. [Running the Application](#5-running-the-application)
6. [Scripts Reference](#6-scripts-reference)
7. [Component Overview](#7-component-overview)
8. [Deployment](#8-deployment)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

### Required Software

| Software | Version | Purpose | Installation |
|----------|---------|---------|--------------|
| **Flutter SDK** | 3.0.0+ | Frontend framework | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **Chrome/Edge** | Latest | Web development | Pre-installed or download |
| **Git** | Any | Version control | Pre-installed on most systems |

### Optional Software

| Software | Purpose | Installation |
|----------|---------|--------------|
| **Node.js** | Deployment tools | [nodejs.org](https://nodejs.org) |
| **Supabase CLI** | Database management | `npm install -g supabase` |
| **VS Code** | Code editor | [code.visualstudio.com](https://code.visualstudio.com) |

### Required Accounts (Free Tier)

| Service | Purpose | Sign Up |
|---------|---------|---------|
| **Supabase** | Backend (Auth, DB, Storage) | [supabase.com](https://supabase.com) |
| **OpenAI** (Optional) | AI generation | [platform.openai.com](https://platform.openai.com) |

---

## 2. Installation

### Automated Installation

The recommended way to install all dependencies:

```bash
# Navigate to project directory
cd /path/to/SellScribe

# Make scripts executable
chmod +x scripts/*.sh

# Run installation script
./scripts/install.sh
```

The installation script will:
1. Verify Flutter is installed
2. Enable Flutter web support
3. Run `flutter pub get` to install packages
4. Create `.env` file from template
5. Verify project structure

### Manual Installation

If you prefer manual setup:

```bash
# 1. Verify Flutter installation
flutter --version
flutter doctor

# 2. Enable web support
flutter config --enable-web

# 3. Install dependencies
cd /path/to/SellScribe
flutter pub get

# 4. Create environment file
cp .env.example .env
```

### Flutter Installation (if not installed)

**macOS (Homebrew):**
```bash
brew install --cask flutter
```

**macOS (Manual):**
```bash
# Download from https://docs.flutter.dev/get-started/install/macos
# Extract to ~/development/flutter
export PATH="$PATH:$HOME/development/flutter/bin"
```

**Linux (Snap):**
```bash
sudo snap install flutter --classic
```

**Windows:**
Download and run installer from [flutter.dev](https://docs.flutter.dev/get-started/install/windows)

---

## 3. Configuration

### Environment Variables

Edit the `.env` file in the project root:

```env
# REQUIRED: Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# OPTIONAL: OpenAI Configuration
# Leave empty to use mock mode (sample AI responses)
OPENAI_API_KEY=sk-...
```

### Getting Supabase Credentials

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project" and create a project
3. Wait for project to initialize (~2 minutes)
4. Go to **Project Settings** (gear icon) > **API**
5. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`

### Getting OpenAI API Key (Optional)

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign in or create account
3. Go to **API Keys** section
4. Click "Create new secret key"
5. Copy key → `OPENAI_API_KEY`

**Note:** New OpenAI accounts receive ~$5 in free credits. Without an API key, the app uses mock AI responses for testing.

---

## 4. Database Setup

The application requires database tables and a storage bucket in Supabase.

### Running Migrations

1. Open your Supabase project dashboard
2. Go to **SQL Editor** (left sidebar)
3. Click "New query"

**Run Migration 1 (Database Schema):**

Copy and paste the contents of `supabase/migrations/001_initial_schema.sql`:

```sql
-- This creates:
-- - profiles table (user data + credits)
-- - listings table (generated content)
-- - credit_transactions table (usage tracking)
-- - Row Level Security policies
-- - Auto-create profile trigger
```

Click "Run" to execute.

**Run Migration 2 (Storage Bucket):**

Copy and paste the contents of `supabase/migrations/002_storage_bucket.sql`:

```sql
-- This creates:
-- - product-images storage bucket
-- - Storage access policies
```

Click "Run" to execute.

### Verify Setup

After running migrations, verify:

1. **Tables**: Go to "Table Editor" - you should see `profiles`, `listings`, `credit_transactions`
2. **Storage**: Go to "Storage" - you should see `product-images` bucket
3. **Auth**: Go to "Authentication" > "Providers" - Email should be enabled

---

## 5. Running the Application

### Development Server

Start the development server:

```bash
./scripts/start.sh
```

Or manually:

```bash
flutter run -d chrome
```

The app will open in Chrome at `http://localhost:8080`

### Start Script Options

```bash
# Custom port
./scripts/start.sh --port 3000

# Release mode (optimized)
./scripts/start.sh --release

# Without auto-opening browser
./scripts/start.sh --no-browser

# Show help
./scripts/start.sh --help
```

### Hot Reload

While the app is running:
- Press `r` - Hot reload (apply code changes)
- Press `R` - Hot restart (restart app)
- Press `q` - Quit

---

## 6. Scripts Reference

### install.sh

**Purpose:** Install all dependencies and set up the development environment.

**Location:** `scripts/install.sh`

**What it does:**
1. Detects operating system
2. Checks for Flutter SDK
3. Enables Flutter web support
4. Installs Flutter packages (`flutter pub get`)
5. Creates `.env` file from template
6. Checks for optional tools (Supabase CLI, Node.js)
7. Verifies project structure

**Usage:**
```bash
./scripts/install.sh
```

**Output Example:**
```
============================================================
  SellScribe Installation
============================================================

✓ Operating system: macos
✓ Flutter is installed: Flutter 3.x.x
✓ Flutter web support is enabled
✓ Flutter dependencies installed
✓ Created .env file from template
```

---

### start.sh

**Purpose:** Start the Flutter web development server.

**Location:** `scripts/start.sh`

**What it does:**
1. Validates Flutter installation
2. Checks `.env` file exists
3. Validates Supabase configuration
4. Checks OpenAI configuration (warns if missing)
5. Updates dependencies if needed
6. Starts Flutter web server

**Usage:**
```bash
# Default (port 8080, debug mode)
./scripts/start.sh

# Custom port
./scripts/start.sh --port 3000

# Release mode
./scripts/start.sh --release

# No auto-open browser
./scripts/start.sh --no-browser
```

**Options:**
| Option | Description |
|--------|-------------|
| `--port PORT` | Specify port number (default: 8080) |
| `--release` | Run in release mode (optimized) |
| `--no-browser` | Don't open browser automatically |
| `--help` | Show help message |

---

### build.sh

**Purpose:** Build the application for production deployment.

**Location:** `scripts/build.sh`

**What it does:**
1. Optionally cleans previous build
2. Optionally runs code analysis
3. Builds Flutter web in release mode
4. Shows build summary (size, file count)
5. Provides deployment instructions

**Usage:**
```bash
# Standard build
./scripts/build.sh

# Clean build
./scripts/build.sh --clean

# With code analysis
./scripts/build.sh --analyze

# Both
./scripts/build.sh --clean --analyze
```

**Options:**
| Option | Description |
|--------|-------------|
| `--clean` | Clean build cache before building |
| `--analyze` | Run `flutter analyze` before building |
| `--help` | Show help message |

**Output:**
- Build files are placed in `build/web/`
- Ready to deploy to any static hosting

---

## 7. Component Overview

### Frontend Architecture

```
lib/
├── main.dart              # App initialization
├── config/                # Configuration layer
├── models/                # Data structures
├── services/              # Business logic
├── providers/             # State management
├── screens/               # UI pages
└── widgets/               # Reusable components
```

### Configuration Layer (`config/`)

| File | Purpose |
|------|---------|
| `app_config.dart` | Loads environment variables from `.env` |
| `routes.dart` | Defines navigation routes using GoRouter |
| `theme.dart` | Material 3 theme with custom colors |

### Data Models (`models/`)

| Model | Purpose | Database Table |
|-------|---------|----------------|
| `UserProfile` | User data with credits | `profiles` |
| `ProductListing` | Generated listings | `listings` |
| `CreditTransaction` | Credit history | `credit_transactions` |

### Services (`services/`)

| Service | Responsibilities |
|---------|------------------|
| `SupabaseService` | Supabase client singleton, auth state |
| `AuthService` | Sign up, sign in, sign out, profile management |
| `AiService` | OpenAI API calls, mock fallback, prompt building |
| `StorageService` | Image upload to Supabase Storage |

### State Management (`providers/`)

| Provider | State Managed |
|----------|---------------|
| `AuthProvider` | User authentication, profile, credits |
| `ListingProvider` | Listing generation, history, images |

### Screens (`screens/`)

| Screen | Route | Purpose |
|--------|-------|---------|
| `SplashScreen` | `/` | Initial load, auth check |
| `LoginScreen` | `/login` | User sign in |
| `RegisterScreen` | `/register` | User registration |
| `HomeScreen` | `/home` | Dashboard, quick actions |
| `UploadScreen` | `/generator/upload` | Image upload |
| `DetailsScreen` | `/generator/details` | Product form |
| `ResultsScreen` | `/generator/results` | Generated content |
| `HistoryScreen` | `/history` | Past listings |

### Backend Architecture

```
Supabase Project
├── Authentication (GoTrue)
│   └── Email/Password provider
├── Database (PostgreSQL)
│   ├── profiles
│   ├── listings
│   └── credit_transactions
├── Storage (S3-compatible)
│   └── product-images bucket
└── Edge Functions (Deno)
    └── generate-listing
```

---

## 8. Deployment

### Build for Production

```bash
./scripts/build.sh --clean
```

Output: `build/web/`

### Deploy to Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd build/web
vercel

# Follow prompts to configure
```

### Deploy to Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize in project root
firebase init
# Select: Hosting
# Public directory: build/web
# Single-page app: Yes
# Overwrite index.html: No

# Deploy
firebase deploy
```

### Deploy to Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd build/web
netlify deploy --prod
```

### Deploy Supabase Edge Function

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref YOUR_PROJECT_ID

# Set OpenAI key as secret
supabase secrets set OPENAI_API_KEY=sk-your-key

# Deploy function
supabase functions deploy generate-listing
```

---

## 9. Troubleshooting

### Common Issues

#### "Supabase not initialized"

**Cause:** Missing or invalid Supabase credentials in `.env`

**Solution:**
1. Check `.env` file exists
2. Verify `SUPABASE_URL` starts with `https://`
3. Verify `SUPABASE_ANON_KEY` is the anon/public key (not service key)

#### "Images not uploading"

**Cause:** Storage bucket not configured or RLS policies missing

**Solution:**
1. Run `002_storage_bucket.sql` migration in Supabase
2. Verify bucket `product-images` exists in Storage
3. Check bucket is set to public

#### "AI returning mock responses"

**Cause:** OpenAI API key not configured

**Solution:**
1. Add `OPENAI_API_KEY` to `.env`
2. Restart the development server
3. Or use Edge Function (requires deploying function with secret)

#### "Authentication not working"

**Cause:** Auth not configured or policies missing

**Solution:**
1. Verify Email provider is enabled in Supabase Auth settings
2. Run `001_initial_schema.sql` migration
3. Check RLS policies are created

#### "CORS errors in console"

**Cause:** Edge Function CORS headers or Supabase URL mismatch

**Solution:**
1. Verify `SUPABASE_URL` in `.env` matches your project
2. If using Edge Function, check CORS headers are set

### Debug Commands

```bash
# Check Flutter setup
flutter doctor -v

# Check Flutter version
flutter --version

# Clear Flutter cache
flutter clean
flutter pub get

# Analyze code for issues
flutter analyze

# Verbose run
flutter run -d chrome -v
```

### Getting Help

- **Flutter Issues:** [flutter.dev/docs](https://flutter.dev/docs)
- **Supabase Issues:** [supabase.com/docs](https://supabase.com/docs)
- **Project Issues:** Check console logs in browser DevTools

---

## Quick Reference

### Essential Commands

```bash
# Install dependencies
./scripts/install.sh

# Start development server
./scripts/start.sh

# Build for production
./scripts/build.sh

# Clean and rebuild
./scripts/build.sh --clean
```

### File Locations

| Item | Location |
|------|----------|
| Environment config | `.env` |
| Flutter packages | `pubspec.yaml` |
| Database migrations | `supabase/migrations/` |
| Edge functions | `supabase/functions/` |
| Build output | `build/web/` |

### Port Configuration

| Service | Default Port |
|---------|--------------|
| Flutter Web Dev | 8080 |
| Hot Reload | Automatic |
