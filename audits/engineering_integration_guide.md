# WellxPetsSDK — Engineering Integration Guide

**Version:** 1.0.0+1
**Generated:** 2026-04-02
**Dart SDK:** ^3.11.4
**Flutter:** 3.x (Material 3)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Full API Surface](#2-full-api-surface)
3. [Environment Configuration](#3-environment-configuration)
4. [Setup Guide](#4-setup-guide)
5. [Database Schema](#5-database-schema)
6. [Integration Points](#6-integration-points)
7. [Known Issues & Limitations](#7-known-issues--limitations)
8. [Testing](#8-testing)

---

## 1. Architecture Overview

### 1.1 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        HOST APPLICATION                         │
│  (Existing Wellx Flutter App)                                   │
│                                                                 │
│  ┌─────────────────┐   ┌──────────────────┐                    │
│  │  WellxAuthDelegate│   │WellxXCoinDelegate│  (host implements) │
│  └────────┬────────┘   └────────┬─────────┘                    │
│           │                     │                               │
│  ┌────────▼─────────────────────▼─────────────────────────┐    │
│  │               WellxPetsSDK.initialize()                 │    │
│  │               sdk.buildRootWidget()                     │    │
│  └────────────────────────┬────────────────────────────────┘    │
└───────────────────────────│─────────────────────────────────────┘
                            │ ProviderScope overrides
┌───────────────────────────▼─────────────────────────────────────┐
│                      SDK INTERNAL LAYERS                         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Navigation Layer (GoRouter)                             │   │
│  │  • ShellRoute (5 tab routes) + 15+ full-screen modals   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  State Management (Riverpod 2.x)                         │   │
│  │  • petProvider, healthProvider, authProvider, ...         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Service Layer                                           │   │
│  │  • PetService          • HealthService                   │   │
│  │  • BCSService          • OcrService                      │   │
│  │  • ClaudeProxyService  • ShelterService                  │   │
│  │  • VenueService        • TravelService                   │   │
│  │  • CreditService       • ScoreCalculator                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  SupabaseManager (singleton, separate from host instance) │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────┬───────────────────────────┘
                                      │
              ┌───────────────────────┼────────────────────────┐
              │                       │                        │
┌─────────────▼──────┐  ┌────────────▼──────────┐  ┌─────────▼────────────┐
│  Supabase Backend  │  │  Anthropic Claude API  │  │  Admin Panel API     │
│  (PostgreSQL)      │  │  /v1/messages          │  │  (Vercel-hosted)     │
│  Row Level Security│  │  Text + Vision (Base64)│  │  /api/pets/upload-   │
│  Storage Buckets   │  │  claude-sonnet-4-6     │  │  photo               │
└────────────────────┘  └───────────────────────┘  └──────────────────────┘
```

### 1.2 Module Directory Structure

```
lib/
├── main.dart                        # Standalone dev entry point (mock delegates)
├── wellx_pets_sdk.dart              # Public library barrel file — exports SDK API
└── src/
    ├── sdk/                         # Core SDK interface — the public contract
    │   ├── wellx_pets_sdk.dart      # SDK singleton: initialize(), buildRootWidget(), dispose()
    │   ├── wellx_pets_config.dart   # Value object holding all API keys/config
    │   ├── auth_delegate.dart       # WellxAuthDelegate + WellxAuthState
    │   └── xcoin_delegate.dart      # WellxXCoinDelegate + WellxCoinEvent + WellxWalletBalance
    │
    ├── models/                      # Immutable data models (manual JSON serialization)
    │   ├── pet.dart                 # Pet, PetCreate, PetUpdate
    │   ├── owner.dart               # Owner, Membership
    │   ├── health_models.dart       # Biomarker, Medication, MedicalRecord, WalkSession,
    │   │                            #   InsuranceClaim, HealthAlert, PetDocument,
    │   │                            #   SymptomLog, WellnessSurveyResult + Create variants
    │   ├── bcs_models.dart          # BCS scoring models
    │   ├── credit_models.dart       # CreditWallet, CreditTransaction
    │   ├── travel_models.dart       # TravelDestination, TravelAirline, TravelPlan, ChecklistItem
    │   ├── shelter_models.dart      # ShelterProfile, ShelterDog, ShelterImpact, CoinAllocation
    │   ├── venue_models.dart        # Venue, VenueCity, DogFriendlyStatus, DogFriendlyDetails
    │   └── app_error.dart           # AppError enum
    │
    ├── providers/                   # Riverpod state management layer
    │   ├── sdk_providers.dart       # configProvider, authDelegateProvider, xCoinDelegateProvider
    │   ├── auth_provider.dart       # authStateProvider, currentAuthProvider, currentOwnerProvider
    │   ├── pet_provider.dart        # petsProvider, selectedPetProvider, selectedPetIdProvider
    │   ├── health_provider.dart     # biomarkersProvider, medicationsProvider, walksProvider, etc.
    │   ├── credit_provider.dart     # creditWalletProvider, transactionsProvider
    │   ├── shelter_provider.dart    # sheltersProvider, shelterDogsProvider
    │   ├── venue_provider.dart      # venuesProvider, venueCitiesProvider
    │   ├── travel_provider.dart     # destinationsProvider, airlinesProvider, travelPlansProvider
    │   └── vet_chat_provider.dart   # vetChatMessagesProvider, vetChatStateProvider
    │
    ├── services/                    # Business logic and external API integration
    │   ├── supabase_client.dart     # SupabaseManager singleton — creates separate Supabase client
    │   ├── pet_service.dart         # CRUD for pets table + photo upload via admin API
    │   ├── health_service.dart      # CRUD for all health tables
    │   ├── bcs_service.dart         # BCS records CRUD + photo upload to pet-documents bucket
    │   ├── credit_service.dart      # Credit wallet and transaction history
    │   ├── shelter_service.dart     # Shelter and dog listings
    │   ├── venue_service.dart       # Dog-friendly venue search
    │   ├── travel_service.dart      # Travel destinations, airlines, plans
    │   ├── ocr_service.dart         # Document OCR using Claude Vision
    │   ├── claude_proxy_service.dart# Anthropic API wrapper (text + vision + streaming)
    │   ├── score_calculator.dart    # 5-pillar health score algorithm (pure Dart, no I/O)
    │   ├── pet_health_context.dart  # Builds Claude context string from pet health data
    │   └── vet_system_prompt.dart   # Dr. Layla AI system prompt
    │
    ├── screens/                     # Feature UI screens
    │   ├── home/                    # Home feed, shelter directory, shelter dogs
    │   ├── health/                  # Health dashboard, wellness survey
    │   ├── track/                   # BCS flow, wellness flow, urine flow, symptom logger
    │   ├── vet/                     # AI vet chat (Dr. Layla)
    │   ├── wallet/                  # Document wallet, document detail
    │   ├── credits/                 # Credits wallet, earn coins
    │   ├── venues/                  # Dog-friendly venue search
    │   ├── travel/                  # Travel planner
    │   ├── pets/                    # Add pet screen
    │   ├── medications/             # Medication tracker
    │   ├── ocr/                     # OCR scan screen
    │   ├── report/                  # Health report screen
    │   └── settings/                # Settings, edit profile
    │
    ├── navigation/                  # GoRouter configuration
    │   ├── navigation_router.dart   # All route definitions
    │   ├── main_tab_shell.dart      # Bottom tab bar shell widget
    │   └── app_destination.dart     # Navigation constants/destinations
    │
    ├── theme/                       # Design system
    │   ├── wellx_colors.dart        # Complete color palette with helpers
    │   ├── wellx_pets_theme.dart    # Material 3 ThemeData
    │   ├── wellx_typography.dart    # Text styles
    │   └── wellx_spacing.dart       # Layout spacing constants
    │
    └── widgets/                     # Shared reusable components
        ├── wellx_primary_button.dart
        ├── wellx_card.dart
        ├── shimmer_loading.dart
        └── coin_earned_toast.dart

test/
├── models/
│   ├── pet_test.dart               # 20+ tests for Pet/PetCreate/PetUpdate
│   ├── health_models_test.dart     # 20+ tests for health model behavior
│   └── credit_models_test.dart     # 10+ tests for credit models
├── services/
│   ├── score_calculator_test.dart  # 15+ tests for health score algorithm
│   └── auth_delegate_test.dart     # Auth delegate interface tests
└── widget_test.dart                # Smoke test
```

### 1.3 State Management (Riverpod)

The SDK uses **Riverpod 2.x** with `flutter_riverpod`. All providers are wrapped in a `ProviderScope` created by `buildRootWidget()`, with three providers mandatorily overridden at initialization:

| Provider | Type | Purpose |
|----------|------|---------|
| `configProvider` | `Provider<WellxPetsConfig>` | SDK configuration (keys, models) |
| `authDelegateProvider` | `Provider<WellxAuthDelegate>` | Auth bridge to host app |
| `xCoinDelegateProvider` | `Provider<WellxXCoinDelegate>` | Coin reward bridge to host app |

These three providers **throw `UnimplementedError` if not overridden** — they must always be supplied via `WellxPetsSDK.initialize()`.

Key application providers:

| Provider | Type | Description |
|----------|------|-------------|
| `authStateProvider` | `StreamProvider<WellxAuthState>` | Live auth state stream from delegate |
| `currentAuthProvider` | `Provider<WellxAuthState>` | Synchronous current auth snapshot |
| `currentOwnerProvider` | `FutureProvider<Owner?>` | Fetches owner record from Supabase |
| `petsProvider` | `FutureProvider<List<Pet>>` | All pets for current user |
| `selectedPetIdProvider` | `StateProvider<String?>` | Active pet selection state |
| `selectedPetProvider` | `Provider<Pet?>` | Derived: resolves selectedPetId → Pet |

### 1.4 Navigation System (GoRouter)

The SDK uses **GoRouter 14.x** with a `ShellRoute` for the bottom tab bar and separate `GoRoute` entries (parented to `_rootNavigatorKey`) for full-screen modal flows.

**Tab Shell Routes** (render inside `MainTabShell` with bottom navigation bar):

| Route | Screen | Tab Index |
|-------|--------|-----------|
| `/home` | HomeScreen | 0 |
| `/reports` | ReportScreen | 1 |
| `/vet` | VetChatScreen (Dr. Layla) | 2 |
| `/track` | TrackScreen | 3 |
| `/wallet` | WalletScreen | 4 |

**Full-Screen Modal Routes** (outside shell, no tab bar):

| Route | Screen |
|-------|--------|
| `/bcs-check` | TrackBCSFlow |
| `/wellness-check` | TrackWellnessFlow |
| `/urine-check` | TrackUrineFlow |
| `/symptom-logger` | SymptomLoggerScreen |
| `/wellness-survey` | WellnessSurveyScreen |
| `/health-dashboard/:petId` | HealthDashboardScreen |
| `/credits-wallet` | CreditsWalletScreen |
| `/earn-coins` | EarnCoinsScreen |
| `/settings` | SettingsScreen |
| `/edit-profile` | EditProfileScreen |
| `/document-detail/:docId` | DocumentDetailScreen |
| `/shelter-directory` | ShelterDirectoryScreen |
| `/shelter-dogs` | ShelterDogsListScreen |
| `/venues` | VenuesScreen |
| `/travel` | TravelScreen |
| `/ocr-scan` | OcrScanScreen |
| `/medications/:petId` | MedicationsScreen |
| `/add-pet` | AddPetScreen |

Initial route is `/home`. No redirect/guard logic is currently implemented in the router — authentication state is handled at the service/provider level (empty responses when unauthenticated).

### 1.5 Service Layer Pattern

Each service follows the same pattern:
- **Stateless class** (no instance state, injected via Riverpod `Provider`)
- **Uses `SupabaseManager.instance.client`** for database access
- **Throws a typed exception** (e.g., `PetServiceException`, `HealthServiceException`) on any failure
- **No retry logic** — errors propagate up to providers/widgets

`SupabaseManager` is a singleton that:
1. Creates a **separate** `SupabaseClient` instance (not using `Supabase.initialize()` — avoids conflict with host app's own Supabase instance)
2. Sets the initial session from `WellxAuthDelegate.currentAuthState` at startup
3. Subscribes to `WellxAuthDelegate.authStateStream` and updates the Supabase session on every auth state change

---

## 2. Full API Surface

### 2.1 Public Exports (`lib/wellx_pets_sdk.dart`)

Only four files are exported publicly. Everything in `src/` is internal.

```dart
export 'src/sdk/wellx_pets_sdk.dart';       // WellxPetsSDK
export 'src/sdk/wellx_pets_config.dart';    // WellxPetsConfig
export 'src/sdk/auth_delegate.dart';        // WellxAuthDelegate, WellxAuthState
export 'src/sdk/xcoin_delegate.dart';       // WellxXCoinDelegate, WellxCoinEvent, WellxWalletBalance, WellxCoinAction
```

### 2.2 `WellxPetsSDK`

The main entry point. Singleton.

```dart
class WellxPetsSDK {
  // Static accessor (asserts initialized)
  static WellxPetsSDK get instance;

  // Read-only properties
  final WellxPetsConfig config;
  final WellxAuthDelegate authDelegate;
  final WellxXCoinDelegate xCoinDelegate;

  // Initialize SDK — must be called before buildRootWidget()
  // Initializes Supabase, sets up auth listener, stores singleton
  static Future<WellxPetsSDK> initialize({
    required WellxPetsConfig config,
    required WellxAuthDelegate authDelegate,
    required WellxXCoinDelegate xCoinDelegate,
  }) async;

  // Returns the embeddable root widget (MaterialApp.router with full SDK UI)
  Widget buildRootWidget();

  // Teardown — cancels auth listener, resets singleton
  Future<void> dispose() async;
}
```

### 2.3 `WellxPetsConfig`

Immutable value object. All fields are `const`-compatible.

```dart
class WellxPetsConfig {
  final String supabaseUrl;           // Required: https://xxx.supabase.co
  final String supabaseAnonKey;       // Required: Supabase anon key (eyJ...)
  final String anthropicApiKey;       // Required: sk-ant-... Anthropic key
  final String claudeModel;           // Default: 'claude-sonnet-4-6'
  final String claudeModelFast;       // Default: 'claude-sonnet-4-6'
  final String? elevenlabsAgentId;    // Optional: ElevenLabs voice agent
  final String? elevenlabsApiKey;     // Optional: ElevenLabs API key
  final String? distributionBaseUrl;  // Optional: Insurance feature API
}
```

### 2.4 `WellxAuthDelegate` (abstract — host must implement)

```dart
abstract class WellxAuthDelegate {
  // REQUIRED: Stream of auth changes — SDK listens continuously
  Stream<WellxAuthState> get authStateStream;

  // REQUIRED: Synchronous current auth snapshot
  WellxAuthState get currentAuthState;

  // REQUIRED: SDK calls this when Supabase token needs refreshing
  // Return the new access token string
  Future<String> refreshToken();

  // REQUIRED: Called when SDK detects auth has become invalid
  // Host should navigate user back to login screen
  void onAuthInvalidated();
}
```

#### `WellxAuthState`

```dart
class WellxAuthState {
  final bool isAuthenticated;
  final String? userId;        // Supabase user UUID
  final String? accessToken;   // JWT access token for Supabase
  final String? refreshToken;  // JWT refresh token
  final String? email;
  final String? firstName;
  final String? lastName;

  // Convenience constructors
  const WellxAuthState({...});
  const WellxAuthState.unauthenticated();  // All nulls, isAuthenticated = false

  // Computed
  String get fullName;  // '$firstName $lastName'
}
```

### 2.5 `WellxXCoinDelegate` (abstract — host must implement)

```dart
abstract class WellxXCoinDelegate {
  // Called when user earns coins — host awards via its own system
  // Returns the NEW coin balance after awarding
  Future<int> onCoinEvent(WellxCoinEvent event);

  // Returns current wallet balance for display in SDK UI
  Future<WellxWalletBalance> getBalance();

  // Push-based balance updates from host (e.g., coins added externally)
  Stream<WellxWalletBalance> get balanceStream;
}
```

#### `WellxCoinAction` (enum)

| Value | Default Coins | Display Name |
|-------|--------------|--------------|
| `dailyLogin` | 5 | Daily Login |
| `completePetProfile` | 20 | Complete Pet Profile |
| `uploadDocument` | 10 | Upload Document |
| `logWalk` | 5 | Log Walk |
| `chatDrLayla` | 10 | Chat with Dr. Layla |
| `healthCheck` | 10 | Health Check |
| `logSymptom` | 5 | Log Symptom |

#### `WellxCoinEvent`

```dart
class WellxCoinEvent {
  final WellxCoinAction action;
  final int suggestedCoins;       // Recommended coins (host may override)
  final String? referenceId;      // Optional: entity ID triggering the event
  final Map<String, dynamic>? metadata; // Optional: additional context
}
```

#### `WellxWalletBalance`

```dart
class WellxWalletBalance {
  final int coinsBalance;
  final int creditsBalance;        // Default 0
  final int totalCoinsEarned;      // Default 0

  int get totalBalance;  // coinsBalance + creditsBalance
}
```

### 2.6 Data Models

#### `Pet`

Maps to the `pets` table.

| Field | Type | Column | Notes |
|-------|------|--------|-------|
| `id` | `String` | `id` | UUID, required |
| `name` | `String` | `name` | Required |
| `breed` | `String` | `breed` | Required |
| `species` | `String?` | `species` | 'dog', 'cat', 'bird', 'rabbit', 'fish', 'hamster' |
| `dateOfBirth` | `String?` | `date_of_birth` | ISO 8601 date string |
| `gender` | `String?` | `gender` | 'Male' / 'Female' |
| `isNeutered` | `bool?` | `is_neutered` | |
| `weight` | `double?` | `weight` | In kg |
| `photoUrl` | `String?` | `photo_url` | Public storage URL |
| `longevityScore` | `int?` | `longevity_score` | 0-100 |
| `ownerId` | `String?` | `owner_id` | FK to owners |
| `microchip` | `String?` | `microchip` | Microchip number |
| `dubaiLicence` | `String?` | `dubai_licence` | UAE licensing number |
| `bloodType` | `String?` | `blood_type` | e.g. 'DEA 1.1+' |
| `createdAt` | `String?` | `created_at` | ISO 8601 timestamp |
| `updatedAt` | `String?` | `updated_at` | ISO 8601 timestamp |

Computed properties: `displayAge` (human string), `speciesEmoji` (emoji char).
Equality: based on `id` only.

Variants: `PetCreate` (for insert, includes `id`), `PetUpdate` (all optional, `toJson()` omits nulls for partial update).

#### `Biomarker`

Maps to the `biomarkers` table.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID |
| `petId` | `String?` | FK to pets |
| `name` | `String` | e.g. 'Creatinine', 'CRP' |
| `value` | `double?` | Numeric reading |
| `unit` | `String?` | e.g. 'mg/dL' |
| `referenceMin` | `double?` | Lower bound of normal range |
| `referenceMax` | `double?` | Upper bound of normal range |
| `pillar` | `String?` | Health pillar keyword |
| `date` | `String?` | Sample date |
| `trend` | `List<TrendPoint>?` | Historical readings |
| `source` | `String?` | Lab source |
| `createdAt` | `String?` | |

Computed: `status` → 'normal' / 'low' / 'high' / 'unknown'.

`TrendPoint`: `{date: String?, value: double?}`.

#### `Medication`

Maps to the `medications` table.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `petId` | `String?` | |
| `name` | `String` | Drug name |
| `dosage` | `String?` | e.g. '10mg twice daily' |
| `category` | `String?` | Drug class |
| `supplyTotal` | `int?` | Total pills/doses dispensed |
| `supplyRemaining` | `int?` | Current count |
| `urgency` | `String?` | 'High' / 'Medium' / 'Low' |
| `refillDate` | `String?` | When to refill |
| `instructions` | `String?` | Administration notes |

Computed: `supplyPercentage` (0.0–1.0), `urgencyColor` ('red' / 'orange' / 'green').

#### `MedicalRecord`

Maps to the `medical_records` table.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `petId` | `String?` | |
| `title` | `String` | Visit summary |
| `date` | `String` | ISO 8601 |
| `clinic` | `String?` | Clinic name |
| `vetName` | `String?` | |
| `category` | `String?` | Visit type |
| `notes` | `String?` | |
| `diagnoses` | `List<Diagnosis>?` | JSON array: `{name, notes}` |
| `prescribedMeds` | `List<PrescribedMed>?` | JSON array: `{name, dosage}` |

#### `WalkSession`

Maps to the `walk_sessions` table.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `petId` | `String?` | |
| `date` | `String` | ISO 8601 |
| `steps` | `int?` | Step count |
| `distanceKm` | `double?` | |
| `durationMin` | `int?` | Total minutes |
| `avgCadence` | `int?` | Steps per minute |

Computed: `durationDisplay` (e.g. '45 min' or '1h 30m').

#### `PetDocument`

Maps to the `documents` table.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `petId` | `String?` | |
| `title` | `String` | |
| `date` | `String` | |
| `fileType` | `String?` | 'pdf' / 'jpg' / etc. |
| `category` | `String?` | 'vaccination' / 'lab' / etc. |
| `fileUrl` | `String?` | Public storage URL |

#### `SymptomLog`

Maps to the `health_events` table (filtered by `event_type = 'symptom'`).

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `petId` | `String?` | |
| `userId` | `String?` | |
| `eventType` | `String` | Always 'symptom' |
| `source` | `String` | 'user' / 'ai' |
| `rawText` | `String?` | Free-text from user |
| `codedTerm` | `String?` | Normalized symptom name |
| `severity` | `String?` | 'mild' / 'moderate' / 'severe' |
| `status` | `String` | 'active' / 'resolved' |
| `eventDate` | `String` | ISO 8601 |
| `metadata` | `Map<String, String>?` | Additional key-value pairs |

Computed: `symptomName`, `isActive`, `severityLabel`.

#### `WellnessSurveyResult`

Loaded from `wellness_surveys` table.

| Field | Type | Notes |
|-------|------|-------|
| `petId` | `String` | |
| `date` | `String` | |
| `answers` | `Map<String, int>` | category → option index (0=best, 3=worst) |
| `isFromOnboarding` | `bool?` | Onboarding surveys don't trigger coin events |

Survey categories: `APPETITE`, `COAT`, `ACTIVITY`, `DENTAL`, `MOBILITY`, `EXERCISE`, `ENVIRONMENT`, `ENRICHMENT`.

Computed: `scoreForCategory(category)` → 0–100, `overallScore` → 0–100.

#### `HealthAlert` — `health_alerts` table

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `petId` | `String?` | |
| `alertType` | `String?` | 'critical' / 'warning' / 'info' |
| `marker` | `String?` | Biomarker name that triggered alert |
| `value` | `double?` | Value at time of alert |
| `status` | `String?` | 'active' / 'resolved' |
| `createdAt` | `String?` | |
| `resolvedAt` | `String?` | |

#### `InsuranceClaim` — `insurance_claims` table

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `petId` | `String?` | |
| `title` | `String` | |
| `amount` | `double?` | Claim amount |
| `status` | `String?` | 'submitted' / 'pending' / 'approved' / 'denied' |
| `date` | `String` | |
| `category` | `String?` | |

### 2.7 `ScoreCalculator` (Core Algorithm)

**Pure Dart class** — no I/O, no async, fully testable.

```dart
class ScoreCalculator {
  // Main entry point — all parameters optional except biomarkers
  static HealthScore calculate({
    required List<Biomarker> biomarkers,
    List<WalkSession> walkSessions = const [],
    WellnessSurveyResult? wellnessResult,
    Pet? pet,  // Used for breed-size-adjusted activity targets
  });
}
```

**Output: `HealthScore`**

```dart
class HealthScore {
  final int overall;              // 0-100 weighted average
  final List<PillarScore> pillars;  // Always 5 pillars
  final String updatedDate;       // 'YYYY-MM-DD'

  PillarScore? get weakestPillar;
  List<PillarScore> pillarsNeedingAttention({int threshold = 60});
}

class PillarScore {
  final String name;    // Pillar name
  final int score;      // 0-100
  final String icon;    // SF Symbol name (informational)
  final String color;   // Color name string (informational)

  double get percent;   // score / 100.0
  String get id;        // same as name
}
```

**Health Pillars:**

| Pillar | Weight | Biomarker Keywords | Wellness Categories |
|--------|--------|-------------------|---------------------|
| Organ Strength | 30% | kidney, liver, albumin, creatinine, bun, sdma, alt, ast, ggt | APPETITE |
| Inflammation | 20% | crp, inflam, wbc, neutrophil | COAT |
| Metabolic | 20% | glucose, thyroid, t4, cholesterol, triglyceride | APPETITE |
| Body & Activity | 15% | weight, bcs, body | ACTIVITY, MOBILITY, EXERCISE |
| Wellness & Dental | 15% | _(none)_ | DENTAL, COAT, APPETITE, ENVIRONMENT, ENRICHMENT |

**Scoring Logic:**
- In-range biomarker: 85–100 (center = 100, edge = 85)
- Slightly out of range (deviation < 20%): 65
- Moderately out of range (deviation < 50%): 40
- Severely out of range (deviation ≥ 50%): 15
- Trend bonus (improving, >10% change toward normal): +8
- Trend bonus (stable normal, <10% change): +5
- Trend penalty (deteriorating, >15% change away from normal): −10
- Score blend: biomarkers (50%) + wellness (30%) + activity (20%), normalized if data is missing
- Default (no data): 50

**Breed-Size Activity Targets (by weight):**

| Weight | Breed Size | Duration Target | Distance Target | Walks/Week |
|--------|-----------|-----------------|-----------------|------------|
| < 10 kg | Small | 20 min | 1.5 km | 5 |
| 10–24 kg | Medium | 30 min | 3.0 km | 5 |
| 25–44 kg | Large | 45 min | 5.0 km | 6 |
| ≥ 45 kg | Giant | 35 min | 3.5 km | 5 |

### 2.8 `ClaudeProxyService` (Anthropic API)

```dart
class ClaudeProxyService {
  ClaudeProxyService(WellxPetsConfig config);

  // Send text messages, return assistant's reply string
  Future<String> sendMessage({
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    String? model,              // Defaults to config.claudeModel
    int maxTokens = 4096,
  });

  // Send messages with base64 image for vision analysis
  Future<String> sendMessageWithVision({
    required List<Map<String, dynamic>> messages,
    required String imageBase64,
    String? systemPrompt,
    String mediaType = 'image/jpeg',
    int maxTokens = 4096,
  });

  // Raw call — returns full decoded response body
  Future<Map<String, dynamic>> callRaw(Map<String, dynamic> body);

  // Call and strip markdown code fences from response (for JSON output)
  Future<String> callAndExtractCleanJson(Map<String, dynamic> body);
}
```

- Endpoint: `https://api.anthropic.com/v1/messages`
- API version header: `2023-06-01`
- Timeout: 60 seconds
- Error type: `ClaudeProxyException`

### 2.9 External API Endpoints

| API | URL | Auth | Purpose |
|-----|-----|------|---------|
| Supabase REST | `{supabaseUrl}/rest/v1/*` | Anon key + JWT session | All database operations |
| Supabase Storage | `{supabaseUrl}/storage/v1/*` | Anon key + JWT session | File upload/download |
| Anthropic Messages | `https://api.anthropic.com/v1/messages` | `x-api-key` header | AI chat, OCR, BCS vision |
| Admin Panel | `https://admin-panel-ruddy-seven.vercel.app/api/pets/upload-photo` | `Authorization: Bearer {jwt}` | Pet photo upload (bypasses storage RLS) |

### 2.10 Supabase Tables Referenced

| Table | Service | Operations |
|-------|---------|-----------|
| `owners` | `auth_provider` | SELECT by id |
| `pets` | `PetService` | SELECT, INSERT, UPDATE, DELETE |
| `biomarkers` | `HealthService` | SELECT, INSERT, DELETE |
| `medications` | `HealthService` | SELECT, INSERT, DELETE |
| `medical_records` | `HealthService` | SELECT, INSERT, DELETE |
| `walk_sessions` | `HealthService` | SELECT, INSERT |
| `insurance_claims` | `HealthService` | SELECT, INSERT, UPDATE (status) |
| `health_alerts` | `HealthService` | SELECT, UPDATE (resolve) |
| `documents` | `HealthService` | SELECT, INSERT |
| `health_events` | `HealthService` | SELECT (symptom), INSERT, UPDATE (resolve) |
| `health_scores` | `HealthService` | UPSERT |
| `wellness_surveys` | `HealthService` | UPSERT, SELECT (latest) |
| `bcs_records` | `BCSService` | SELECT, INSERT |
| `shelters` | `ShelterService` | SELECT |
| `shelter_dogs` | `ShelterService` | SELECT by shelter_id |
| `venues` | `VenueService` | SELECT |
| `venue_cities` | `VenueService` | SELECT |
| `travel_destinations` | `TravelService` | SELECT |
| `travel_airlines` | `TravelService` | SELECT |
| `travel_plans` | `TravelService` | SELECT, INSERT, UPDATE, DELETE |
| `credit_wallets` | `CreditService` | SELECT, UPSERT |
| `credit_transactions` | `CreditService` | SELECT, INSERT |

### 2.11 Supabase Storage Buckets

| Bucket | Used By | Path Pattern | Access |
|--------|---------|--------------|--------|
| `pet-documents` | `HealthService.uploadDocument()`, `BCSService.uploadBCSPhoto()` | `{petId}/{timestamp}_{filename}` | Public URLs via `getPublicUrl()` |
| _(pet photos)_ | Admin Panel API (server-side) | Managed by admin panel | Requires service role key (not in SDK) |

> **Note:** Pet photo uploads bypass Supabase storage RLS by routing through the admin panel at `https://admin-panel-ruddy-seven.vercel.app`. The admin panel holds the service role key server-side. The SDK sends the user's JWT for authentication.

---

## 3. Environment Configuration

### 3.1 Required Keys

| Key | Where Used | How Provided |
|-----|-----------|--------------|
| `SUPABASE_URL` | `WellxPetsConfig.supabaseUrl` | Hardcoded in host app (or config file) |
| `SUPABASE_ANON_KEY` | `WellxPetsConfig.supabaseAnonKey` | Hardcoded or `--dart-define` |
| `ANTHROPIC_API_KEY` | `WellxPetsConfig.anthropicApiKey` | `--dart-define` or secure config |

### 3.2 Standalone Dev Mode (`lib/main.dart`)

Keys are passed via `--dart-define` at run time:

```bash
flutter run \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

Read in `main.dart` via:

```dart
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const anthropicApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
```

The Supabase URL is **hardcoded** in `main.dart`:
```
https://raniqvhddcwfukvaljer.supabase.co
```

### 3.3 Host App Integration Mode

The host app constructs `WellxPetsConfig` directly with string literals or values loaded from its own secure config:

```dart
final sdk = await WellxPetsSDK.initialize(
  config: const WellxPetsConfig(
    supabaseUrl: 'https://raniqvhddcwfukvaljer.supabase.co',
    supabaseAnonKey: kSupabaseAnonKey,   // from your constants file
    anthropicApiKey: kAnthropicKey,      // from your secure config
    // Optional:
    claudeModel: 'claude-sonnet-4-6',
    elevenlabsAgentId: 'agent_...',
    elevenlabsApiKey: 'sk_...',
    distributionBaseUrl: 'https://api.yourinsurer.com',
  ),
  authDelegate: MyAuthDelegate(),
  xCoinDelegate: MyXCoinDelegate(),
);
```

### 3.4 Environment Separation

There is **no built-in environment switching** in the SDK. The host app is responsible for selecting the correct Supabase URL/key per environment. Recommended pattern:

```dart
// In host app constants:
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://raniqvhddcwfukvaljer.supabase.co',  // dev
);
```

Or use separate flavor configurations in the host app that pass different `WellxPetsConfig` instances.

### 3.5 Optional Keys

| Key | Effect if Omitted |
|-----|------------------|
| `elevenlabsAgentId` / `elevenlabsApiKey` | Voice assistant features are unavailable |
| `distributionBaseUrl` | Insurance distribution features are unavailable |
| `claudeModel` | Defaults to `claude-sonnet-4-6` |
| `claudeModelFast` | Defaults to `claude-sonnet-4-6` (same model) |

---

## 4. Setup Guide

### 4.1 Prerequisites

| Tool | Minimum Version | Notes |
|------|----------------|-------|
| Flutter | 3.x (stable) | Dart SDK ^3.11.4 required |
| Dart | 3.11.4+ | Included with Flutter |
| Xcode | 15+ | For iOS builds |
| Android Studio | 2023.x+ | For Android builds / emulator |
| CocoaPods | 1.14+ | `sudo gem install cocoapods` |
| Git | Any | |

### 4.2 Clone and Install

```bash
# Clone repository
git clone <repo-url>
cd WellxPetsSDK

# Install Flutter dependencies
flutter pub get

# Install iOS pods (required for first build)
cd ios && pod install && cd ..
```

### 4.3 Run on iOS Simulator

```bash
# List available simulators
flutter devices

# Run with required dart-defines
flutter run \
  --dart-define=SUPABASE_ANON_KEY=<your_anon_key> \
  --dart-define=ANTHROPIC_API_KEY=<your_anthropic_key>
```

Or select a specific simulator:
```bash
flutter run -d "iPhone 16 Pro" \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=ANTHROPIC_API_KEY=<key>
```

### 4.4 Run on Android Emulator

```bash
# Start AVD from Android Studio first, then:
flutter run \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=ANTHROPIC_API_KEY=<key>
```

Ensure your emulator has Google Play Services and internet access. Check with `flutter devices` to confirm the emulator appears.

### 4.5 Run on Physical Device

**iOS:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your team and update the bundle ID if needed
3. Connect device, trust Mac, then:

```bash
flutter run --release \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=ANTHROPIC_API_KEY=<key>
```

**Android:**
1. Enable Developer Options on device
2. Enable USB Debugging
3. Connect via USB, accept permission prompt
4. Run the same flutter run command as above

### 4.6 Run Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/models/pet_test.dart
flutter test test/services/score_calculator_test.dart

# With verbose output
flutter test --verbose

# Generate coverage report (requires lcov)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 4.7 Code Generation

If you modify models with Freezed or add new Riverpod generators, regenerate:

```bash
# One-time generation
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode during development
flutter pub run build_runner watch
```

> **Note:** Current models use **manual JSON serialization** (not Freezed), so code generation is only needed if you add new providers with `@riverpod` annotations.

### 4.8 Build as Flutter Module (Add-to-App)

The SDK is configured as a Flutter module:
- Android package: `com.wellx.wellx_pets_sdk`
- iOS bundle ID: `com.wellx.wellxPetsSdk`
- `pubspec.yaml` has `flutter.module` section

**Build Android AAR:**
```bash
flutter build aar
# Output: build/host/outputs/repo/
```

**Build iOS xcframework:**
```bash
flutter build ios-framework --output=../MyHostApp/Flutter/
```

---

## 5. Database Schema

### 5.1 Required Tables

Create these tables in your Supabase project. All tables use UUID primary keys and `timestamptz` for timestamps.

---

#### `owners`

```sql
CREATE TABLE owners (
  id           uuid PRIMARY KEY,  -- matches auth.users.id
  email        text,
  first_name   text,
  last_name    text,
  phone        text,
  avatar_url   text,
  membership   jsonb,             -- {type, status, expires_at}
  created_at   timestamptz DEFAULT now()
);
```

---

#### `pets`

```sql
CREATE TABLE pets (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        uuid REFERENCES owners(id) ON DELETE CASCADE,
  name            text NOT NULL,
  breed           text NOT NULL,
  species         text,           -- 'dog', 'cat', 'bird', 'rabbit', 'fish', 'hamster'
  date_of_birth   date,
  gender          text,           -- 'Male', 'Female'
  is_neutered     boolean,
  weight          numeric,        -- kg
  photo_url       text,
  longevity_score integer,        -- 0-100
  microchip       text,
  dubai_licence   text,
  blood_type      text,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);

CREATE INDEX pets_owner_id_idx ON pets(owner_id);
```

---

#### `biomarkers`

```sql
CREATE TABLE biomarkers (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id        uuid REFERENCES pets(id) ON DELETE CASCADE,
  name          text NOT NULL,
  value         numeric,
  unit          text,
  reference_min numeric,
  reference_max numeric,
  pillar        text,             -- health pillar keyword
  date          date,
  trend         jsonb,            -- [{date, value}, ...]
  source        text,
  created_at    timestamptz DEFAULT now()
);

CREATE INDEX biomarkers_pet_id_idx ON biomarkers(pet_id);
```

---

#### `medications`

```sql
CREATE TABLE medications (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id           uuid REFERENCES pets(id) ON DELETE CASCADE,
  name             text NOT NULL,
  dosage           text,
  category         text,
  supply_total     integer,
  supply_remaining integer,
  urgency          text,          -- 'High', 'Medium', 'Low'
  refill_date      date,
  instructions     text,
  created_at       timestamptz DEFAULT now()
);

CREATE INDEX medications_pet_id_idx ON medications(pet_id);
```

---

#### `medical_records`

```sql
CREATE TABLE medical_records (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id          uuid REFERENCES pets(id) ON DELETE CASCADE,
  title           text NOT NULL,
  date            date NOT NULL,
  clinic          text,
  vet_name        text,
  category        text,
  notes           text,
  diagnoses       jsonb,          -- [{name, notes}, ...]
  prescribed_meds jsonb,          -- [{name, dosage}, ...]
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX medical_records_pet_id_idx ON medical_records(pet_id);
```

---

#### `walk_sessions`

```sql
CREATE TABLE walk_sessions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id       uuid REFERENCES pets(id) ON DELETE CASCADE,
  date         date NOT NULL,
  steps        integer,
  distance_km  numeric,
  duration_min integer,
  avg_cadence  integer,
  created_at   timestamptz DEFAULT now()
);

CREATE INDEX walk_sessions_pet_id_idx ON walk_sessions(pet_id);
```

---

#### `insurance_claims`

```sql
CREATE TABLE insurance_claims (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     uuid REFERENCES pets(id) ON DELETE CASCADE,
  title      text NOT NULL,
  amount     numeric,
  status     text,               -- 'submitted', 'pending', 'approved', 'denied'
  date       date NOT NULL,
  category   text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX insurance_claims_pet_id_idx ON insurance_claims(pet_id);
```

---

#### `health_alerts`

```sql
CREATE TABLE health_alerts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id      uuid REFERENCES pets(id) ON DELETE CASCADE,
  alert_type  text,              -- 'critical', 'warning', 'info'
  marker      text,
  value       numeric,
  status      text DEFAULT 'active',  -- 'active', 'resolved'
  resolved_at timestamptz,
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX health_alerts_pet_id_idx ON health_alerts(pet_id);
```

---

#### `documents`

```sql
CREATE TABLE documents (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     uuid REFERENCES pets(id) ON DELETE CASCADE,
  title      text NOT NULL,
  date       date NOT NULL,
  file_type  text,               -- 'pdf', 'jpg', 'png'
  category   text,               -- 'vaccination', 'lab', 'prescription', etc.
  file_url   text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX documents_pet_id_idx ON documents(pet_id);
```

---

#### `health_events`

Used for symptom logs (filtered by `event_type = 'symptom'`).

```sql
CREATE TABLE health_events (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id      uuid REFERENCES pets(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES owners(id),
  event_type  text NOT NULL,     -- always 'symptom' from SDK
  source      text NOT NULL,     -- 'user', 'ai'
  raw_text    text,
  coded_term  text,
  severity    text,              -- 'mild', 'moderate', 'severe'
  status      text NOT NULL DEFAULT 'active',  -- 'active', 'resolved'
  event_date  timestamptz NOT NULL,
  metadata    jsonb,
  created_at  timestamptz DEFAULT now()
);

CREATE INDEX health_events_pet_id_idx ON health_events(pet_id);
CREATE INDEX health_events_type_idx ON health_events(event_type);
```

---

#### `health_scores`

```sql
CREATE TABLE health_scores (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     uuid REFERENCES pets(id) ON DELETE CASCADE,
  score      integer NOT NULL,   -- 0-100
  breakdown  jsonb,              -- {pillarName: score, ...}
  created_at timestamptz DEFAULT now()
);

-- Note: SDK uses upsert without a unique key, so each call inserts a new row.
-- Add unique constraint on (pet_id, DATE(created_at)) if you want daily snapshots.
```

---

#### `wellness_surveys`

```sql
CREATE TABLE wellness_surveys (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     uuid REFERENCES pets(id) ON DELETE CASCADE,
  owner_id   uuid REFERENCES owners(id),
  answers    jsonb NOT NULL,     -- {APPETITE: 0, COAT: 1, ACTIVITY: 0, ...}
  created_at timestamptz DEFAULT now()
);

CREATE INDEX wellness_surveys_pet_id_idx ON wellness_surveys(pet_id);
```

---

#### `bcs_records`

```sql
CREATE TABLE bcs_records (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id              uuid REFERENCES pets(id) ON DELETE CASCADE,
  owner_id            uuid REFERENCES owners(id),
  score               integer NOT NULL CHECK (score BETWEEN 1 AND 9),
  image_url           text,
  body_fat_percentage numeric,
  muscle_condition    text,
  notes               text,
  created_at          timestamptz DEFAULT now()
);

CREATE INDEX bcs_records_pet_id_idx ON bcs_records(pet_id);
```

---

#### Additional tables (referenced but schema not in SDK code)

The following tables are queried by the SDK but their schema is managed outside the core health module:

| Table | Provider/Service | Notes |
|-------|---------|-------|
| `shelters` | `ShelterService` | Shelter profiles |
| `shelter_dogs` | `ShelterService` | Adoptable dogs per shelter |
| `venues` | `VenueService` | Dog-friendly locations |
| `venue_cities` | `VenueService` | City groupings |
| `travel_destinations` | `TravelService` | Country-level pet travel rules |
| `travel_airlines` | `TravelService` | Airline pet policies |
| `travel_plans` | `TravelService` | User-specific itineraries |
| `credit_wallets` | `CreditService` | User coin/credit balances |
| `credit_transactions` | `CreditService` | Transaction log |

### 5.2 Row Level Security (RLS)

All tables should have RLS enabled. Recommended policies (repeat pattern for each table):

```sql
-- Enable RLS
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;

-- Allow users to see only their own pets
CREATE POLICY "Users see own pets" ON pets
  FOR SELECT USING (owner_id = auth.uid());

-- Allow users to insert their own pets
CREATE POLICY "Users insert own pets" ON pets
  FOR INSERT WITH CHECK (owner_id = auth.uid());

-- Allow users to update their own pets
CREATE POLICY "Users update own pets" ON pets
  FOR UPDATE USING (owner_id = auth.uid());

-- Allow users to delete their own pets
CREATE POLICY "Users delete own pets" ON pets
  FOR DELETE USING (owner_id = auth.uid());
```

For child tables (e.g. `biomarkers`), join through the `pets` table:

```sql
ALTER TABLE biomarkers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own biomarkers" ON biomarkers
  FOR SELECT USING (
    pet_id IN (SELECT id FROM pets WHERE owner_id = auth.uid())
  );
-- Repeat INSERT, UPDATE, DELETE with same pattern
```

Read-only tables (`shelters`, `venues`, `travel_destinations`, `travel_airlines`):

```sql
ALTER TABLE shelters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read" ON shelters FOR SELECT USING (true);
```

### 5.3 Storage Bucket Configuration

**Create bucket `pet-documents`:**

```sql
-- Via Supabase dashboard or:
INSERT INTO storage.buckets (id, name, public)
VALUES ('pet-documents', 'pet-documents', true);
```

**Storage RLS policies:**

```sql
-- Allow authenticated users to upload to their own pet's folder
CREATE POLICY "Users upload own pet docs" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'pet-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Allow public read (URLs are public)
CREATE POLICY "Public read pet docs" ON storage.objects
  FOR SELECT USING (bucket_id = 'pet-documents');
```

> **Note:** Pet photo uploads bypass storage RLS and go through the admin panel API. That API uses the Supabase service role key server-side. The `pet-documents` bucket is used for documents and BCS photos only.

---

## 6. Integration Points

### 6.1 Embedding the SDK in a Host Flutter App

**Step 1 — Add as a path dependency** (monorepo):

```yaml
# In host app's pubspec.yaml
dependencies:
  wellx_pets_sdk:
    path: ../WellxPetsSDK
```

Or as a git dependency:
```yaml
dependencies:
  wellx_pets_sdk:
    git:
      url: https://github.com/wellx/wellx-pets-sdk.git
      ref: main
```

**Step 2 — Implement `WellxAuthDelegate`:**

```dart
import 'package:wellx_pets_sdk/wellx_pets_sdk.dart';

class HostAuthDelegate implements WellxAuthDelegate {
  final YourAuthService _auth;

  HostAuthDelegate(this._auth);

  @override
  WellxAuthState get currentAuthState {
    final user = _auth.currentUser;
    if (user == null) return const WellxAuthState.unauthenticated();
    return WellxAuthState(
      isAuthenticated: true,
      userId: user.id,
      accessToken: user.accessToken,
      refreshToken: user.refreshToken,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
    );
  }

  @override
  Stream<WellxAuthState> get authStateStream {
    return _auth.authChanges.map((user) {
      if (user == null) return const WellxAuthState.unauthenticated();
      return WellxAuthState(
        isAuthenticated: true,
        userId: user.id,
        accessToken: user.accessToken,
        refreshToken: user.refreshToken,
        email: user.email,
      );
    });
  }

  @override
  Future<String> refreshToken() async {
    await _auth.refreshSession();
    return _auth.currentUser!.accessToken;
  }

  @override
  void onAuthInvalidated() {
    _auth.signOut();
    // Navigate back to login — use your router
  }
}
```

**Step 3 — Implement `WellxXCoinDelegate`:**

```dart
class HostXCoinDelegate implements WellxXCoinDelegate {
  final YourRewardsService _rewards;
  final _balanceController = StreamController<WellxWalletBalance>.broadcast();

  HostXCoinDelegate(this._rewards) {
    // Forward balance updates from rewards service to SDK
    _rewards.balanceChanges.listen((balance) {
      _balanceController.add(WellxWalletBalance(
        coinsBalance: balance.coins,
        creditsBalance: balance.credits,
        totalCoinsEarned: balance.totalEarned,
      ));
    });
  }

  @override
  Future<int> onCoinEvent(WellxCoinEvent event) async {
    // Award coins via your system
    final newBalance = await _rewards.awardCoins(
      userId: _auth.currentUser!.id,
      amount: event.suggestedCoins,
      reason: event.action.displayName,
      referenceId: event.referenceId,
    );
    return newBalance;
  }

  @override
  Future<WellxWalletBalance> getBalance() async {
    final b = await _rewards.getBalance();
    return WellxWalletBalance(
      coinsBalance: b.coins,
      creditsBalance: b.credits,
      totalCoinsEarned: b.totalEarned,
    );
  }

  @override
  Stream<WellxWalletBalance> get balanceStream => _balanceController.stream;
}
```

**Step 4 — Initialize and embed:**

```dart
class HostApp extends StatefulWidget {
  @override
  State<HostApp> createState() => _HostAppState();
}

class _HostAppState extends State<HostApp> {
  late final WellxPetsSDK _sdk;

  @override
  void initState() {
    super.initState();
    _initSDK();
  }

  Future<void> _initSDK() async {
    _sdk = await WellxPetsSDK.initialize(
      config: const WellxPetsConfig(
        supabaseUrl: 'https://raniqvhddcwfukvaljer.supabase.co',
        supabaseAnonKey: kSupabaseAnonKey,
        anthropicApiKey: kAnthropicKey,
      ),
      authDelegate: HostAuthDelegate(authService),
      xCoinDelegate: HostXCoinDelegate(rewardsService),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _sdk.dispose();
    super.dispose();
  }
}
```

**Step 5 — Launch the SDK UI:**

```dart
// Option A: Full-screen push
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => _sdk.buildRootWidget()),
);

// Option B: As a tab in your host bottom nav
// In your host tab bar, one tab renders:
_sdk.buildRootWidget()

// Option C: Nested navigator
Navigator(
  onGenerateRoute: (_) => MaterialPageRoute(
    builder: (_) => _sdk.buildRootWidget(),
  ),
)
```

### 6.2 Theming Customization

The SDK uses its own self-contained `WellxPetsTheme` (Material 3). **The theme cannot currently be overridden from outside the SDK** — it ignores the host app's theme. Any customization requires modifying `lib/src/theme/`:

- `wellx_colors.dart` — Color palette constants
- `wellx_pets_theme.dart` — `ThemeData` construction
- `wellx_typography.dart` — Text styles
- `wellx_spacing.dart` — Layout constants

### 6.3 Authentication Handoff

The SDK **never shows login/signup UI**. If the user is unauthenticated:
- Providers return empty lists or null values
- Service calls succeed but return empty results (RLS blocks unauthorized reads)
- `onAuthInvalidated()` is called on the delegate if the SDK detects a 401

The auth lifecycle is entirely driven by the host app. The SDK's Supabase client session is updated automatically via `authStateStream`.

### 6.4 Deep Linking

The SDK uses GoRouter internally. Deep linking into specific SDK routes from the host app requires:

1. Accessing the router: The `routerProvider` is internal and not publicly exported
2. Navigating programmatically: Currently not supported via public API — all navigation is internal
3. If you need to deep-link into a specific SDK route, you can use `WellxPetsSDK.instance` and access internal providers (not recommended — subject to change)

**Recommended approach:** Launch the SDK root widget and let the user navigate from there.

### 6.5 Handling the Lifecycle

```dart
// App backgrounded / foregrounded:
// No special handling needed — Riverpod providers handle this automatically

// User logs out:
// 1. Host updates auth state (delegate stream emits WellxAuthState.unauthenticated())
// 2. SDK Supabase session is cleared automatically
// 3. Providers return empty states
// 4. When user logs back in, emit new WellxAuthState and SDK resumes

// Dispose when done:
await _sdk.dispose();
// After this, WellxPetsSDK.instance will throw until re-initialized
```

---

## 7. Known Issues & Limitations

### 7.1 Code TODOs / FIXMEs

A grep of the entire `lib/` directory for `TODO`, `FIXME`, `HACK`, and `XXX` found **zero results**. The codebase is clean of inline technical debt markers.

### 7.2 Known Architecture Limitations

**1. No deep-linking public API**
The SDK does not expose a way to navigate to specific internal routes programmatically from the host app. There is no `navigateTo(route)` method on `WellxPetsSDK`. You can only embed the full SDK widget; internal navigation is opaque.

**2. Hardcoded Supabase URL in `main.dart`**
`lib/main.dart` hardcodes `https://raniqvhddcwfukvaljer.supabase.co`. This is only used in standalone dev mode, but it ties the dev workflow to the production/staging Supabase instance. There is no dev-specific Supabase project configured.

**3. No streaming/realtime subscriptions**
All data fetching uses one-shot Supabase `.select()` queries. Supabase Realtime (websocket subscriptions) is not implemented. Data will not update in real-time without a pull-to-refresh.

**4. Pet photo upload routes through external admin panel**
Photo uploads go to `https://admin-panel-ruddy-seven.vercel.app/api/pets/upload-photo` — an external Vercel deployment. If this service is unavailable, pet photo uploads will fail. There is no fallback or retry. The admin panel URL is hardcoded in `PetService`.

**5. No token refresh logic in SupabaseManager**
`SupabaseManager` calls `client.auth.setSession(accessToken)` but does **not** call `WellxAuthDelegate.refreshToken()` when the token expires. The host app must proactively push fresh tokens via the `authStateStream`. If the token expires mid-session and the host doesn't refresh, API calls will start failing with 401 errors.

**6. Theme is not injectable**
`buildRootWidget()` always applies `WellxPetsTheme.theme`. Host app theming is completely ignored. There is no mechanism to pass a custom `ThemeData` from outside.

**7. Single-instance SDK**
`WellxPetsSDK` enforces a singleton. You cannot run two SDK instances simultaneously (e.g., for testing in the same process). Re-calling `initialize()` overwrites the singleton without disposing the previous instance.

**8. No error boundary / fallback UI**
If a provider throws an unhandled exception, Riverpod will surface it as an `AsyncError`. There are no global error boundaries to catch unhandled Riverpod errors and show a user-friendly fallback screen.

**9. `health_scores` upsert uses no unique key**
`HealthService.saveHealthScore()` calls `.upsert()` without specifying an `onConflict` column. This will insert a new row on every call rather than updating the existing day's record, unless the database has a unique constraint configured.

**10. Anthropic API key exposed in network calls**
`ClaudeProxyService` sends `x-api-key: {anthropicApiKey}` directly from the client device. This means the API key is visible in network traffic and device memory. For production, consider proxying AI calls through a backend service.

**11. ElevenLabs not fully implemented**
`elevenlabsAgentId` and `elevenlabsApiKey` are in `WellxPetsConfig` but there is no `ElevenLabsService` in `lib/src/services/`. Voice assistant functionality is declared in config but not wired up.

**12. `claudeModelFast` defaults to same model as `claudeModel`**
Both default to `claude-sonnet-4-6`. There is no cost optimization for simple/fast calls — all Claude requests use the same model.

### 7.3 Tech Debt

- Models are hand-written (no Freezed code generation). `copyWith` methods are absent on most models. Any mutation requires creating new instances manually.
- `BCSService` returns `Map<String, dynamic>` directly rather than typed `BCSRecord` models — the BCS model layer is incomplete.
- `auth_delegate_test.dart` name suggests delegate testing, but the actual implementation should be verified for coverage gaps.
- The admin panel URL (`https://admin-panel-ruddy-seven.vercel.app`) is a magic string with no configuration path — it cannot be overridden without modifying source code.

---

## 8. Testing

### 8.1 Test Suite Overview

```
test/
├── models/
│   ├── pet_test.dart               # 20 tests
│   ├── health_models_test.dart     # ~20 tests
│   └── credit_models_test.dart     # ~10 tests
├── services/
│   ├── score_calculator_test.dart  # 15 tests
│   └── auth_delegate_test.dart     # Interface contract tests
└── widget_test.dart                # 1 smoke test
```

**Total: ~65+ test cases**

All tests are **unit tests** — no integration tests, no widget tests beyond a basic smoke test. Tests do not hit Supabase or the Anthropic API.

### 8.2 Running Tests

```bash
# Run all tests
flutter test

# Run with name filter
flutter test --name "ScoreCalculator"

# Run a specific file
flutter test test/models/pet_test.dart

# Run with verbose output (see each test name)
flutter test --verbose

# Run with coverage
flutter test --coverage
# Coverage data: coverage/lcov.info
```

### 8.3 Test Coverage by Area

| Area | Coverage | Tests |
|------|---------|-------|
| `Pet` model (JSON, computed props, equality) | High | 20 |
| `PetCreate` / `PetUpdate` | Medium | 5 |
| `Biomarker.status` computed | High | In health_models_test |
| `Medication.supplyPercentage` | High | In health_models_test |
| `WalkSession.durationDisplay` | High | In health_models_test |
| `InsuranceClaim.statusColor` | High | In health_models_test |
| `HealthAlert.severityColor` | High | In health_models_test |
| `SymptomLog` parsing | High | In health_models_test |
| `WellnessSurveyResult.scoreForCategory` | High | In health_models_test |
| `ScoreCalculator.calculate` (all paths) | High | 15 |
| `HealthScore.weakestPillar` | High | 2 |
| `HealthScore.pillarsNeedingAttention` | High | 1 |
| `PillarScore.percent` | High | 1 |
| `CreditWallet` / `CreditTransaction` | Medium | ~10 |
| Services (PetService, HealthService, etc.) | **None** | 0 |
| Providers (Riverpod) | **None** | 0 |
| Screens / UI | **None** | 0 |
| Navigation (GoRouter) | **None** | 0 |
| ClaudeProxyService | **None** | 0 |
| BCSService | **None** | 0 |

### 8.4 Areas Needing More Testing

In priority order:

1. **Services** — `PetService`, `HealthService`, `BCSService` have zero test coverage. These need integration tests against a real or mock Supabase instance.
2. **ClaudeProxyService** — No tests for request construction, error handling, JSON fence stripping, or vision message building.
3. **Providers** — No tests verify that Riverpod providers correctly derive state from service responses.
4. **Score Calculator edge cases** — No tests for biomarkers with null values, zero-range spans, or the `trend` adjustment logic with < 2 data points.
5. **Navigation** — No route tests verify that path parameters (`:petId`, `:docId`) are correctly extracted and passed to widgets.
6. **Widget / Integration** — No end-to-end user flow tests. Consider adding golden tests for key screens (health dashboard, BCS flow, wellness survey).

### 8.5 Testing with Mock Delegates

Use the mock implementations from `main.dart` as a reference for test setup:

```dart
class MockAuthDelegate implements WellxAuthDelegate {
  @override
  WellxAuthState get currentAuthState => const WellxAuthState(
    isAuthenticated: true,
    userId: 'test-user-id',
    accessToken: 'test-token',
    email: 'test@test.com',
  );

  @override
  Stream<WellxAuthState> get authStateStream => Stream.value(currentAuthState);

  @override
  Future<String> refreshToken() async => 'refreshed-token';

  @override
  void onAuthInvalidated() {}
}

class MockXCoinDelegate implements WellxXCoinDelegate {
  @override
  Future<int> onCoinEvent(WellxCoinEvent event) async => 100;

  @override
  Future<WellxWalletBalance> getBalance() async =>
      const WellxWalletBalance(coinsBalance: 100);

  @override
  Stream<WellxWalletBalance> get balanceStream => const Stream.empty();
}
```

Use `mocktail` (already in dev dependencies) for mocking service classes:

```dart
import 'package:mocktail/mocktail.dart';

class MockPetService extends Mock implements PetService {}
class MockHealthService extends Mock implements HealthService {}

void main() {
  final mockPetService = MockPetService();

  test('petsProvider returns empty list when unauthenticated', () async {
    // Override providers in test ProviderContainer
    final container = ProviderContainer(overrides: [
      petServiceProvider.overrideWithValue(mockPetService),
      authDelegateProvider.overrideWithValue(MockAuthDelegate()),
    ]);
    // ...
  });
}
```

---

## Appendix A: Dependency Reference

| Package | Version | Purpose |
|---------|---------|---------|
| `supabase_flutter` | ^2.8.0 | Database, auth, storage |
| `flutter_riverpod` | ^2.6.0 | State management |
| `riverpod_annotation` | ^2.6.0 | Riverpod code gen annotations |
| `go_router` | ^14.8.0 | Declarative navigation |
| `freezed_annotation` | ^2.4.0 | Immutable model annotations |
| `json_annotation` | ^4.9.0 | JSON serialization annotations |
| `cached_network_image` | ^3.4.0 | Image caching and display |
| `image_picker` | ^1.1.0 | Camera / gallery selection |
| `geolocator` | ^13.0.0 | Device location |
| `flutter_markdown` | ^0.7.0 | Render Claude's markdown responses |
| `http` | ^1.3.0 | HTTP client for Anthropic API |
| `path_provider` | ^2.1.0 | File system paths |
| `intl` | ^0.19.0 | Date/number formatting |
| `url_launcher` | ^6.3.0 | Open external links |
| `uuid` | ^4.5.0 | UUID generation |
| `pdf` | ^3.11.1 | PDF report generation |
| `printing` | ^5.13.2 | PDF print/share |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `build_runner` | ^2.4.0 | Code generation runner (dev) |
| `freezed` | ^2.5.0 | Immutable class generator (dev) |
| `json_serializable` | ^6.9.0 | JSON code generator (dev) |
| `riverpod_generator` | ^2.6.0 | Riverpod code generator (dev) |
| `mocktail` | ^1.0.0 | Mock generation for tests (dev) |
| `flutter_lints` | ^6.0.0 | Lint rules (dev) |

---

## Appendix B: WellX Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `deepPurple` | `#4D33B3` | Primary brand, CTA buttons |
| `midPurple` | `#6B4ECC` | Gradient end, active states |
| `lightPurple` | `#9B85E0` | Subtle accents |
| `lavender` | `#B8A9E8` | Chip backgrounds |
| `inkPrimary` | `#1A1A2E` | Tab bar, dark cards |
| `inkSecondary` | `#16162A` | Dark card gradient |
| `background` | `#F7F7FA` | App background |
| `cardSurface` | `#FFFFFF` | Card backgrounds |
| `flatCardFill` | `#F5F4FA` | Flat card backgrounds |
| `border` | `#E8E6F0` | Card borders, dividers |
| `aiPurple` | `#7C5CE0` | AI chat accent |
| `textPrimary` | `#17181A` | Body text |
| `textSecondary` | `#57595B` | Subtext |
| `textTertiary` | `#858789` | Placeholder, metadata |
| `coral` | `#E65A4D` | Errors, alerts |
| `amberWatch` | `#D9A633` | Warning states |
| `organStrength` | `#CC4033` | Organ health pillar |
| `inflammation` | `#D98C33` | Inflammation pillar |
| `metabolic` | `#C4A34F` | Metabolic pillar |
| `bodyActivity` | `#409959` | Body & Activity pillar |
| `wellnessDental` | `#409959` | Wellness & Dental pillar |

Score color thresholds: Red (<30), Orange (<50), Green (<75), Blue (≥75).

---

*End of WellxPetsSDK Engineering Integration Guide*
