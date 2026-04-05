# WellxPetsSDK — Engineering Documentation

> **Version:** 1.0.0+1 · **Flutter SDK:** ^3.11.4 · **Last updated:** 2026-04-05

---

## Table of Contents

1. [Architecture](#1-architecture)
2. [Setup Guide](#2-setup-guide)
3. [Database Schema](#3-database-schema)
4. [API Surface](#4-api-surface)
5. [Integration Guide](#5-integration-guide)
6. [Known Issues](#6-known-issues)
7. [Testing](#7-testing)

---

## 1. Architecture

### System Diagram

```
┌────────────────────────────────────────────────────────────────────┐
│                          HOST APPLICATION                          │
│                                                                    │
│  ┌──────────────────┐    ┌───────────────────────────────────────┐ │
│  │  WellxAuthDelegate│    │        WellxXCoinDelegate             │ │
│  │  (host-owned auth)│    │  (coin awards / wallet management)    │ │
│  └────────┬─────────┘    └──────────────────┬────────────────────┘ │
│           │                                 │                      │
│           ▼                                 ▼                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     WellxPetsSDK                            │   │
│  │                                                             │   │
│  │  ┌─────────────┐  ┌──────────────────┐  ┌───────────────┐  │   │
│  │  │  Navigation  │  │  State (Riverpod) │  │ Design System │  │   │
│  │  │  (go_router) │  │  Providers/       │  │ M3 + WellxTheme│  │   │
│  │  └──────┬──────┘  │  Notifiers        │  └───────────────┘  │   │
│  │         │         └────────┬─────────┘                      │   │
│  │         ▼                  ▼                                 │   │
│  │  ┌──────────────────────────────────────────────────────┐   │   │
│  │  │                    Screen Layer                       │   │   │
│  │  │  Home · Health · BCS/Track · Vet Chat · Pets          │   │   │
│  │  │  Wallet · Credits · Venues · Travel · OCR             │   │   │
│  │  └──────────────────────────┬───────────────────────────┘   │   │
│  │                             │                                │   │
│  │  ┌──────────────────────────▼───────────────────────────┐   │   │
│  │  │                    Service Layer                      │   │   │
│  │  │  PetService · HealthService · BCSService              │   │   │
│  │  │  ShelterService · TravelService · VenueService        │   │   │
│  │  │  ClaudeProxyService · OCRService · CreditService      │   │   │
│  │  │  ScoreCalculator · AnalyticsService                   │   │   │
│  │  └──────────────────────────┬───────────────────────────┘   │   │
│  │                             │                                │   │
│  │  ┌──────────────────────────▼───────────────────────────┐   │   │
│  │  │              SupabaseManager (singleton)              │   │   │
│  │  │  Token sync from WellxAuthDelegate                    │   │   │
│  │  └──────────────────────────┬───────────────────────────┘   │   │
│  └─────────────────────────────┼───────────────────────────────┘   │
└────────────────────────────────┼───────────────────────────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                   ▼
       ┌────────────┐   ┌──────────────┐   ┌──────────────┐
       │  Supabase  │   │  Anthropic   │   │  Supabase    │
       │ PostgreSQL │   │  Claude API  │   │  Storage     │
       │  (+ RLS)   │   │ (Vet + OCR)  │   │ (Photos/Docs)│
       └────────────┘   └──────────────┘   └──────────────┘
```

### Module Structure

```
lib/
├── main.dart                        # Standalone dev runner (mock delegates)
├── wellx_pets_sdk.dart              # Public barrel export
└── src/
    ├── sdk/                         # Core SDK surface
    │   ├── wellx_pets_sdk.dart      # SDK init + ProviderScope overrides + root widget
    │   ├── wellx_pets_config.dart   # Config model (Supabase, Claude, ElevenLabs keys)
    │   ├── auth_delegate.dart       # WellxAuthDelegate + WellxAuthState interfaces
    │   └── xcoin_delegate.dart      # WellxXCoinDelegate + coin event types
    ├── models/                      # Immutable data models (freezed + json_serializable)
    ├── services/                    # Business logic; no Flutter dependencies
    ├── providers/                   # Riverpod providers + StateNotifiers
    ├── navigation/                  # go_router config + tab shell
    ├── screens/                     # Widget tree, one dir per feature
    ├── theme/                       # Material 3 design system tokens
    └── widgets/                     # Shared UI components
```

### State Management (Riverpod)

The SDK uses **Riverpod 2.6** with three tiers of providers:

| Tier | Type | Purpose |
|------|------|---------|
| SDK Core | `Provider` (overridden) | Config, auth/xCoin delegates injected by host |
| Data | `FutureProvider` / `StreamProvider` | Async Supabase data, real-time streams |
| Screen State | `StateNotifierProvider` | UI state: search, filters, selection, pagination |

**Provider override pattern** at SDK initialization:
```dart
ProviderScope(
  overrides: [
    configProvider.overrideWithValue(config),
    authDelegateProvider.overrideWithValue(authDelegate),
    xCoinDelegateProvider.overrideWithValue(xCoinDelegate),
  ],
  child: WellxPetsApp(),
)
```

**Family providers** are used for parameterized queries:
```dart
// petId scopes all health data to one pet
final biomarkers = ref.watch(biomarkersProvider(petId));
```

**Vet chat lazy-read pattern**: `VetChatNotifier` reads health data only when sending a message (not watched). This prevents the chat history from being cleared when the selected pet changes mid-conversation.

### Navigation (go_router)

Router configured in `lib/src/navigation/navigation_router.dart`. Tab shell wraps the 5 main destinations; all other routes are pushed on top as full-screen dialogs.

```
/ (redirect → /home)
├── ShellRoute (MainTabShell — 5 tabs)
│   ├── /home          → HomeScreen
│   ├── /reports       → ReportScreen
│   ├── /vet           → VetChatScreen (Dr. Layla)
│   ├── /track         → TrackScreen
│   └── /wallet        → WalletScreen
│
├── /bcs-check                → TrackBCSFlow (fullscreenDialog)
├── /wellness-check           → TrackWellnessFlow (fullscreenDialog)
├── /urine-check              → TrackUrineFlow (fullscreenDialog)
├── /symptom-logger           → SymptomLoggerScreen
├── /wellness-survey          → WellnessSurveyScreen
├── /health-dashboard/:petId  → HealthDashboardScreen
├── /credits-wallet           → CreditsWalletScreen
├── /earn-coins               → EarnCoinsScreen
├── /settings                 → SettingsScreen
├── /edit-profile             → EditProfileScreen
├── /document-detail/:docId   → DocumentDetailScreen
├── /shelter-directory        → ShelterDirectoryScreen
├── /shelter-dogs             → ShelterDogsListScreen
├── /venues                   → VenuesScreen
├── /travel                   → TravelScreen
├── /ocr-scan                 → OcrScanScreen
├── /medications/:petId       → MedicationsScreen
└── /add-pet                  → AddPetScreen
```

Tab transitions use `NoTransitionPage` (instant). Modal routes use `MaterialPage(fullscreenDialog: true)`.

Bottom tab bar is a floating pill design. Center tab (index 2) is the "Layla" heart icon with a purple gradient — intentionally oversized as a hero action.

### Service Layer

All services take a `SupabaseManager` (or config values) via their constructor. Services are exposed as Riverpod `Provider` singletons and have **no Flutter dependencies**; they can be unit-tested without a widget tree.

`ClaudeProxyService` hits the Anthropic REST API directly using the `http` package with the API key from `WellxPetsConfig`. `OCRService` wraps `ClaudeProxyService` with vision payloads for document scanning.

`ScoreCalculator` is a pure-Dart static class — no I/O, deterministic output. See §4 for details.

---

## 2. Setup Guide

### Prerequisites

| Tool | Min version |
|------|-------------|
| Flutter | 3.11.4 |
| Dart | 3.x |
| Xcode | 15+ (iOS) |
| Android Studio / SDK | API 21+ |
| Supabase project | Any plan |
| Anthropic API key | Standard tier |

### Clone & Run (standalone dev mode)

```bash
git clone https://github.com/wellx/wellx_pets_sdk.git
cd wellx_pets_sdk

# Install dependencies
flutter pub get

# Generate freezed/json_serializable/riverpod code
dart run build_runner build --delete-conflicting-outputs

# Run on simulator (no env vars needed — main.dart uses mock delegates)
flutter run
```

> `lib/main.dart` wires up `MockAuthDelegate` and `MockXCoinDelegate`. It is the development entry point only and is **not** included in SDK consumers' build.

### Environment Variables

Pass via `--dart-define` at build time (or in your CI/CD environment):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

Optional:

```bash
  --dart-define=ELEVENLABS_AGENT_ID=...     # Voice features
  --dart-define=ELEVENLABS_API_KEY=...
  --dart-define=DISTRIBUTION_BASE_URL=...   # Insurance module
```

These values are consumed by `WellxPetsConfig` and passed into the SDK at initialization time by the host app (see §5).

### Supabase Configuration

1. Create a new Supabase project.
2. Run migrations in order (see §3 for the full DDL):
   ```bash
   supabase db push
   ```
   Migrations live in `supabase/migrations/`:
   - `20260403_travel_venues.sql` — travel destinations, venues, venue_cities
   - `20260403_chat_messages.sql` — vet chat message history
   - All other tables (pets, health, shelter, credits) require their own migrations — see §3 for DDL.
3. Enable **Row Level Security** on all user-scoped tables (enabled automatically by migration files).
4. Create a **Storage bucket** named `pet-photos` (public read, authenticated write).
5. Create a **Storage bucket** named `pet-documents` (authenticated read/write).
6. Photo upload uses a server-side admin call; expose a thin edge function or backend route that holds the service role key and proxies the upload. The SDK hits this via `uploadAndSetPhoto`.

---

## 3. Database Schema

All tables use `UUID` primary keys with `gen_random_uuid()`. `created_at` / `updated_at` default to `NOW()`.

### Core Tables

```sql
-- Owner profiles (linked to auth.users)
CREATE TABLE public.owners (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name   TEXT,
  last_name    TEXT,
  email        TEXT,
  phone        TEXT,
  is_admin     BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: SELECT/UPDATE where id = auth.uid()

-- Pets
CREATE TABLE public.pets (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  breed            TEXT,
  species          TEXT NOT NULL DEFAULT 'dog',
  date_of_birth    DATE,
  gender           TEXT,
  is_neutered      BOOLEAN,
  weight           NUMERIC(5,2),
  photo_url        TEXT,
  longevity_score  INT,
  microchip        TEXT,
  dubai_licence    TEXT,
  blood_type       TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: all ops where owner_id = auth.uid()
```

### Health Tables

```sql
CREATE TABLE public.biomarkers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id          UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  value           NUMERIC NOT NULL,
  unit            TEXT,
  reference_min   NUMERIC,
  reference_max   NUMERIC,
  pillar          TEXT,   -- 'organ'|'inflammation'|'metabolic'|'body'|'wellness'
  date            DATE NOT NULL,
  trend           JSONB,  -- array of {date, value} history points
  source          TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.medications (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id           UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  dosage           TEXT,
  category         TEXT,
  supply_total     INT,
  supply_remaining INT,
  urgency          TEXT,
  refill_date      DATE,
  instructions     TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.medical_records (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id        UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  date          DATE NOT NULL,
  description   TEXT,
  veterinarian  TEXT,
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.walk_sessions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id        UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  date          DATE NOT NULL,
  steps         INT,
  distance_km   NUMERIC(6,2),
  duration_min  INT,
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.symptom_logs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  date       DATE NOT NULL,
  symptoms   TEXT[],
  severity   TEXT,   -- 'mild'|'moderate'|'severe'
  notes      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.pet_documents (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  type       TEXT NOT NULL,
  url        TEXT NOT NULL,
  source     TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.health_alerts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id       UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  alert_type   TEXT NOT NULL,
  severity     TEXT,
  description  TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.wellness_surveys (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  date       DATE NOT NULL,
  answers    JSONB NOT NULL,  -- {APPETITE, COAT, ACTIVITY, DENTAL, ENVIRONMENT, ENRICHMENT, MOBILITY}
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Body Condition Score
CREATE TABLE public.bcs_records (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id              UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  owner_id            UUID NOT NULL REFERENCES auth.users(id),
  score               INT NOT NULL CHECK (score BETWEEN 1 AND 9),
  image_url           TEXT,
  body_fat_percentage NUMERIC(4,1),
  muscle_condition    TEXT,
  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: all ops where owner_id = auth.uid()
```

### Shelter Tables

```sql
CREATE TABLE public.shelter_profiles (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                 TEXT NOT NULL,
  website              TEXT,
  location             TEXT,
  shelter_type         TEXT,
  mission              TEXT,
  description          TEXT,
  animals              TEXT[],
  photo_url            TEXT,
  current_needs        JSONB DEFAULT '[]',
  donation_url         TEXT,
  animals_in_care      INT DEFAULT 0,
  active_campaign      TEXT,
  total_coins_received INT DEFAULT 0,
  total_donors         INT DEFAULT 0,
  is_active            BOOLEAN NOT NULL DEFAULT true
);
-- RLS: SELECT for all authenticated users; INSERT/UPDATE admin only

CREATE TABLE public.shelter_dogs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  breed      TEXT,
  age        TEXT,
  photo_url  TEXT,
  status     TEXT,  -- 'adoptable'|'adopted'|'fostered'|'medical_hold'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.shelter_impact (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dogs_helped             INT NOT NULL DEFAULT 0,
  meals_provided          INT NOT NULL DEFAULT 0,
  shelters_partnered      INT NOT NULL DEFAULT 0,
  adoptions_facilitated   INT NOT NULL DEFAULT 0
);
-- Single-row table; no RLS (public read)
```

### Travel & Venues Tables

```sql
-- (Full DDL in supabase/migrations/20260403_travel_venues.sql)

CREATE TABLE public.travel_destinations (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code             TEXT NOT NULL UNIQUE,
  country_name             TEXT NOT NULL,
  region                   TEXT NOT NULL DEFAULT 'Middle East',
  flag_emoji               TEXT,
  pet_import_allowed       BOOLEAN NOT NULL DEFAULT true,
  quarantine_required      BOOLEAN NOT NULL DEFAULT false,
  quarantine_days          INT NOT NULL DEFAULT 0,
  required_documents       JSONB NOT NULL DEFAULT '[]',
  banned_breeds            JSONB NOT NULL DEFAULT '[]',
  vaccination_requirements JSONB NOT NULL DEFAULT '[]',
  entry_process_summary    TEXT,
  climate_notes            TEXT,
  pet_friendliness_score   INT NOT NULL DEFAULT 50 CHECK (pet_friendliness_score BETWEEN 0 AND 100),
  source_urls              JSONB NOT NULL DEFAULT '[]',
  last_verified_at         TIMESTAMPTZ,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: public SELECT (USING true)
-- Index: region

CREATE TABLE public.travel_airlines (
  id                         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                       TEXT NOT NULL,
  iata_code                  TEXT,
  logo_url                   TEXT,
  allows_cabin               BOOLEAN NOT NULL DEFAULT false,
  allows_cargo               BOOLEAN NOT NULL DEFAULT false,
  allows_checked             BOOLEAN NOT NULL DEFAULT false,
  cabin_max_weight_kg        NUMERIC(4,1),
  cabin_carrier_dimensions   JSONB,
  cargo_restrictions         TEXT,
  breed_restrictions         TEXT,
  pet_fee_cabin_usd          NUMERIC(7,2),
  pet_fee_cargo_usd          NUMERIC(7,2),
  booking_process            TEXT,
  required_documents         TEXT,
  temperature_embargo        BOOLEAN NOT NULL DEFAULT false,
  embargo_months             TEXT[],
  pet_policy_url             TEXT,
  last_verified_at           TIMESTAMPTZ
);
-- RLS: public SELECT

CREATE TABLE public.travel_routes (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  origin_country           TEXT NOT NULL,
  destination_country      TEXT NOT NULL,
  airline_id               UUID REFERENCES public.travel_airlines(id),
  direct_flight            BOOLEAN NOT NULL DEFAULT true,
  typical_duration_hours   NUMERIC(4,1),
  pet_cabin_available      BOOLEAN NOT NULL DEFAULT false,
  pet_cargo_available      BOOLEAN NOT NULL DEFAULT false,
  estimated_total_cost_usd NUMERIC(8,2),
  route_notes              TEXT,
  popularity_rank          INT
);
-- RLS: public SELECT

CREATE TABLE public.travel_plans (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pet_id              UUID REFERENCES public.pets(id),
  destination_country TEXT NOT NULL,
  airline_id          UUID REFERENCES public.travel_airlines(id),
  status              JSONB NOT NULL DEFAULT '{}',
  departure_date      DATE,
  return_date         DATE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: all ops where owner_id = auth.uid()

CREATE TABLE public.venues (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                 TEXT NOT NULL,
  phone                TEXT,
  address              TEXT,
  area                 TEXT,
  category             TEXT NOT NULL,  -- 'cafe'|'park'|'beach'|'hotel'|'restaurant'|'shop'|'vet'
  latitude             DOUBLE PRECISION,
  longitude            DOUBLE PRECISION,
  rating               NUMERIC(2,1) DEFAULT 4.0 CHECK (rating BETWEEN 0 AND 5),
  dog_friendly_status  TEXT NOT NULL DEFAULT 'verified_friendly',
  dog_friendly_details JSONB NOT NULL DEFAULT '{}',
  image_url            TEXT,
  whatsapp_number      TEXT,
  website              TEXT,
  last_verified_at     TIMESTAMPTZ,
  google_place_id      TEXT,
  city                 TEXT NOT NULL DEFAULT 'Dubai',
  country_code         TEXT NOT NULL DEFAULT 'AE',
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: public SELECT
-- Indexes: city, category, (latitude, longitude)

CREATE TABLE public.venue_cities (
  city         TEXT PRIMARY KEY,
  country_code TEXT NOT NULL DEFAULT 'AE',
  venue_count  INT NOT NULL DEFAULT 0
);
-- RLS: public SELECT
-- Populated by trigger or manual INSERT ... SELECT after venue inserts
```

### Chat & Credits Tables

```sql
-- (Full DDL in supabase/migrations/20260403_chat_messages.sql)
CREATE TABLE public.chat_messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     UUID NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role       TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content    TEXT NOT NULL,
  image_url  TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: SELECT/INSERT/DELETE where user_id = auth.uid()
-- Index: (pet_id, created_at DESC)

CREATE TABLE public.user_wallets (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id                UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  credits_balance         INT NOT NULL DEFAULT 0,
  coins_balance           INT NOT NULL DEFAULT 0,
  total_credits_purchased INT NOT NULL DEFAULT 0,
  total_coins_earned      INT NOT NULL DEFAULT 0,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: SELECT/UPDATE where owner_id = auth.uid()

CREATE TABLE public.credit_transactions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type           TEXT NOT NULL,  -- 'purchase'|'award'|'earn'|'spend'
  amount         INT NOT NULL,
  currency       TEXT NOT NULL,  -- 'coins'|'credits'
  balance_after  INT,
  description    TEXT,
  reference_id   TEXT,
  reference_type TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: SELECT/INSERT where owner_id = auth.uid()
```

### RLS Summary

| Table | Read | Write |
|-------|------|-------|
| owners | own row | own row |
| pets | owner_id = uid | owner_id = uid |
| biomarkers / medications / records / walks / symptoms / documents / alerts / surveys / bcs_records | via pet's owner | via pet's owner |
| chat_messages | user_id = uid | user_id = uid |
| user_wallets / credit_transactions | owner_id = uid | owner_id = uid |
| travel_plans | owner_id = uid | owner_id = uid |
| travel_destinations / travel_airlines / travel_routes | public | admin only |
| venues / venue_cities | public | admin only |
| shelter_profiles / shelter_dogs / shelter_impact | authenticated | admin only |

---

## 4. API Surface

### `WellxPetsSDK` (entry point)

```dart
// lib/src/sdk/wellx_pets_sdk.dart

class WellxPetsSDK {
  /// Initialize SDK. Must be called before buildRootWidget().
  static Future<WellxPetsSDK> initialize({
    required WellxPetsConfig config,
    required WellxAuthDelegate authDelegate,
    required WellxXCoinDelegate xCoinDelegate,
  });

  /// Returns the root widget. Embed in host app's widget tree.
  Widget buildRootWidget();

  /// Release resources. Call when removing SDK from widget tree.
  Future<void> dispose();
}
```

### `WellxPetsConfig`

```dart
class WellxPetsConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String anthropicApiKey;
  final String claudeModel;          // default: 'claude-sonnet-4-6'
  final String claudeModelFast;      // default: 'claude-haiku-4-5-20251001'
  final String? elevenlabsAgentId;   // optional — voice features
  final String? elevenlabsApiKey;
  final String? distributionBaseUrl; // optional — insurance module
}
```

### `WellxAuthDelegate`

Host app must implement this abstract class:

```dart
abstract class WellxAuthDelegate {
  /// Emits auth state changes (login, logout, token refresh).
  Stream<WellxAuthState> get authStateStream;

  /// Current synchronous auth state (used on cold start).
  WellxAuthState get currentAuthState;

  /// Called when the SDK needs a fresh access token.
  Future<String> refreshToken();

  /// Called when the SDK detects an unrecoverable auth failure.
  /// Host app should redirect to login.
  void onAuthInvalidated();
}

class WellxAuthState {
  final bool isAuthenticated;
  final String? userId;       // Supabase user UUID
  final String? accessToken;
  final String? refreshToken;
  final String? email;
  final String? firstName;
  final String? lastName;

  static WellxAuthState unauthenticated();  // factory
  String get fullName;  // "$firstName $lastName".trim()
}
```

### `WellxXCoinDelegate`

Host app must implement this abstract class:

```dart
abstract class WellxXCoinDelegate {
  /// SDK calls this when a user completes a coin-earning action.
  /// Host awards coins and returns the final balance.
  Future<int> onCoinEvent(WellxCoinEvent event);

  /// Returns the current wallet balance (used on cold start).
  Future<WellxWalletBalance> getBalance();

  /// Stream of balance updates. SDK reflects changes in the credits UI.
  Stream<WellxWalletBalance> get balanceStream;
}

enum WellxCoinAction {
  dailyLogin,           // 5 coins
  completePetProfile,   // 20 coins
  uploadDocument,       // 10 coins
  logWalk,              // 5 coins
  chatDrLayla,          // 10 coins
  healthCheck,          // 10 coins
  logSymptom,           // 5 coins
}

class WellxCoinEvent {
  final WellxCoinAction action;
  final int suggestedCoins;         // Use this value or override it
  final String? referenceId;        // e.g. pet ID, document ID
  final Map<String, dynamic>? metadata;
}

class WellxWalletBalance {
  final int coinsBalance;
  final int creditsBalance;
  final int totalCoinsEarned;

  int get totalBalance;  // coinsBalance + creditsBalance
}
```

### `ScoreCalculator` (public service)

```dart
// lib/src/services/score_calculator.dart

class ScoreCalculator {
  /// Compute a 5-pillar health score for a pet.
  static HealthScore calculate({
    required List<Biomarker> biomarkers,
    WellnessSurveyResult? wellnessSurvey,
    List<WalkSession> walkSessions = const [],
    String? breed,
    String? species,
  });
}

class HealthScore {
  final int overall;                  // 0–100
  final Map<String, PillarScore> pillars;
  final DateTime updatedAt;

  PillarScore? get weakestPillar;
  List<PillarScore> pillarsNeedingAttention([int threshold = 60]);
}

class PillarScore {
  final String id;     // 'organ'|'inflammation'|'metabolic'|'body'|'wellness'
  final String name;
  final int score;     // 0–100
  final double weight; // pillar's contribution weight
  double get percent;  // score / 100.0
}
```

**Pillar weights:**

| Pillar | Weight | Key inputs |
|--------|--------|-----------|
| Organ Strength | 30% | Kidney, liver, albumin, creatinine, appetite |
| Inflammation | 20% | CRP, WBC, neutrophil, coat condition |
| Metabolic | 20% | Glucose, thyroid, cholesterol, appetite |
| Body & Activity | 15% | Weight, BCS, walk sessions (breed-adjusted) |
| Wellness & Dental | 15% | Dental, coat, general wellness survey |

---

## 5. Integration Guide

### Step 1 — Add the SDK as a dependency

In the host app's `pubspec.yaml`:
```yaml
dependencies:
  wellx_pets_sdk:
    path: ../wellx_pets_sdk   # or git/pub source when published
```

### Step 2 — Implement `WellxAuthDelegate`

```dart
class AppAuthDelegate implements WellxAuthDelegate {
  final _authStateController = StreamController<WellxAuthState>.broadcast();

  @override
  Stream<WellxAuthState> get authStateStream => _authStateController.stream;

  @override
  WellxAuthState get currentAuthState {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return WellxAuthState.unauthenticated();
    return WellxAuthState(
      isAuthenticated: true,
      userId: session.user.id,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      email: session.user.email,
    );
  }

  @override
  Future<String> refreshToken() async {
    final response = await Supabase.instance.client.auth.refreshSession();
    return response.session!.accessToken;
  }

  @override
  void onAuthInvalidated() {
    // Navigate host app to login screen
    appRouter.go('/login');
  }
}
```

### Step 3 — Implement `WellxXCoinDelegate`

```dart
class AppXCoinDelegate implements WellxXCoinDelegate {
  final _walletController = StreamController<WellxWalletBalance>.broadcast();

  @override
  Stream<WellxWalletBalance> get balanceStream => _walletController.stream;

  @override
  Future<WellxWalletBalance> getBalance() async {
    final wallet = await myWalletService.fetchWallet();
    return WellxWalletBalance(
      coinsBalance: wallet.coins,
      creditsBalance: wallet.credits,
      totalCoinsEarned: wallet.totalEarned,
    );
  }

  @override
  Future<int> onCoinEvent(WellxCoinEvent event) async {
    final newBalance = await myWalletService.awardCoins(
      action: event.action.name,
      amount: event.suggestedCoins,
    );
    _walletController.add(WellxWalletBalance(
      coinsBalance: newBalance,
      creditsBalance: 0,
      totalCoinsEarned: newBalance,
    ));
    return newBalance;
  }
}
```

### Step 4 — Initialize & embed

```dart
// In your app's startup (e.g. main.dart or a splash screen)
late final WellxPetsSDK _petsSdk;

Future<void> _initSdk() async {
  _petsSdk = await WellxPetsSDK.initialize(
    config: WellxPetsConfig(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      anthropicApiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
    ),
    authDelegate: AppAuthDelegate(),
    xCoinDelegate: AppXCoinDelegate(),
  );
}

// In your widget tree — sdk.buildRootWidget() is a complete tab-based UI
Widget build(BuildContext context) {
  return MaterialApp(
    home: _petsSdk.buildRootWidget(),
  );
}
```

### Auth Handoff

The SDK syncs auth state automatically via `WellxAuthDelegate.authStateStream`. When the host logs a user in or out, push a `WellxAuthState` event to the stream. The `SupabaseManager` inside the SDK will call `setSession()` / `signOut()` accordingly.

The SDK **does not manage Supabase auth itself** — it relies entirely on tokens from the host. This means the host's Supabase project and the SDK's Supabase project can be the same instance (shared) or different.

### Theming

The SDK renders using its own Material 3 `ThemeData` (`WellxPetsTheme.light()`). It does **not** inherit the host app's theme. If you need to align brand colors, modify `lib/src/theme/wellx_colors.dart` before building the SDK.

Key design tokens:

| Token | Value | Usage |
|-------|-------|-------|
| `WellxColors.primary` | `#5C6BC0` (indigo) | Buttons, active states |
| `WellxColors.scoreGreen` | `#4CAF50` | Health score ≥ 70 |
| `WellxColors.alertRed` | `#EF5350` | Score < 40, critical alerts |
| `WellxColors.coral` | `#FF6B6B` | Moderate alerts |
| `WellxColors.organRed` | `#E53935` | Organ pillar |
| `WellxColors.inflammationOrange` | `#FB8C00` | Inflammation pillar |
| `WellxColors.metabolicGold` | `#FDD835` | Metabolic pillar |
| `WellxColors.bodyGreen` | `#43A047` | Body & Activity pillar |
| `WellxColors.wellnessBlue` | `#1E88E5` | Wellness & Dental pillar |

---

## 6. Known Issues

**No TODO/FIXME/HACK comments exist in the `lib/` source tree** — the codebase is clean by grep.

The following architectural limitations are worth noting for future engineering work:

| Area | Issue | Notes |
|------|-------|-------|
| Photo upload | Uses an external admin API endpoint to bypass RLS | Service role key must never live in the Flutter app; ensure this endpoint is authenticated and rate-limited |
| Pagination | `PetService`, `HealthService`, and `VenueService` fetch all records without limit/offset | Fine for current data volumes; will need cursor-based pagination when records grow |
| Chat history | `chat_messages` table is never pruned | Oldest messages are truncated client-side before sending to Claude; DB will grow unbounded |
| Offline support | No local caching layer (no `drift` / `sqflite`) | All screens show shimmer loading on cold start; offline use is not supported |
| Supabase realtime | Health data uses `FutureProvider` (one-shot fetch), not realtime subscriptions | Biomarker updates from another session don't auto-refresh; user must navigate away and back |
| Venue_cities sync | `venue_cities` is a manually maintained summary table | Must be re-populated after any venue INSERT/DELETE (see migration seed script for the pattern) |
| `travel_airlines` schema | Table DDL not included in committed migrations | Schema must be inferred from `TravelService._airlineColumns`; add a migration before first deploy |
| `shelter_*` tables | DDL not in committed migrations | Same as above — add migrations for `shelter_profiles`, `shelter_dogs`, `shelter_impact` |
| `user_wallets` / `credit_transactions` | DDL not in committed migrations | Add migrations; ensure wallet row is created on user signup (trigger or edge function) |

---

## 7. Testing

### Test Files

| File | Lines | What it tests |
|------|-------|---------------|
| `test/models/pet_test.dart` | 227 | `Pet` JSON round-trip, `displayAge`, `speciesEmoji`, equality/hashCode, `PetCreate`/`PetUpdate` payloads |
| `test/models/health_models_test.dart` | ~150 | `Biomarker`, `Medication`, `WalkSession` JSON serialization |
| `test/models/credit_models_test.dart` | ~80 | `CreditWallet`, `CreditTransaction` serialization |
| `test/sdk/auth_delegate_test.dart` | 102 | `WellxAuthState.fullName`, `.unauthenticated()`, `WellxCoinAction.defaultCoins`/`displayName`, `WellxCoinEvent`, `WellxWalletBalance.totalBalance` |
| `test/services/score_calculator_test.dart` | 237 | `ScoreCalculator.calculate()` with normal/abnormal biomarkers, wellness survey influence, walk session influence, breed-adjusted walk scoring, pillar weight verification, `HealthScore.weakestPillar`, `pillarsNeedingAttention()` |
| `test/widget_test.dart` | ~20 | Basic widget smoke test |

### Running Tests

```bash
# All tests (no flutter commands needed for unit tests)
flutter test

# Single file
flutter test test/services/score_calculator_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

> Do **not** run tests that require Supabase without a `.env` or test doubles — the services will throw on missing config. All currently committed tests are pure-Dart unit tests with no network I/O.

### Test Framework

- **flutter_test** (standard)
- **mocktail** ^1.0.0 for mocking delegates in future integration tests

### Coverage Gaps (needs more tests)

| Area | Priority | Notes |
|------|----------|-------|
| `HealthService` | High | No service-layer tests exist; happy-path and error handling |
| `PetService` | High | No tests; CRUD + photo upload paths |
| `VetChatNotifier` | High | Complex lazy-read pattern; concurrent message handling |
| `ScoreCalculator` edge cases | Medium | Missing data (no biomarkers), all-out-of-range, BCS-only score |
| `BCSService` | Medium | Storage upload, persistence |
| `NavigationRouter` | Medium | Route guard behavior (unauthenticated redirect) |
| `ClaudeProxyService` | Low | Mocked HTTP; verify request shape and error propagation |
| Widget integration | Low | End-to-end tab navigation, deep-link params |

---

*Generated from source: `lib/` · `test/` · `supabase/migrations/` · `pubspec.yaml`*
