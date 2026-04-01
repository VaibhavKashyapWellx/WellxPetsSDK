# WellxPetsSDK

A Flutter module (add-to-app) that delivers a full-featured pet health and wellness experience. Drop it into any existing iOS or Android host app and get a complete pet management UI backed by Supabase and Claude AI.

---

## Features

- **Pet Profiles** — create, edit, and manage multiple pets with photos
- **Health Dashboard** — biomarker arc gauges, BCS/wellness/urine tracking flows, symptom logger
- **AI Vet Chat** — real-time streaming chat powered by Claude (Anthropic)
- **Document Wallet** — OCR scan and store lab reports, vaccination records, and more
- **Shelter Directory** — browse local shelters and adoptable dogs
- **Travel Planner** — pet-friendly destination info and airline comparison
- **Venue Finder** — dog parks, groomers, and vet clinics with geo search
- **xCoins / Credits** — reward system for completing health tasks; delegate balance management to host app
- **Theming** — WellX design system (colors, typography, spacing) fully encapsulated

---

## Installation

### As a Flutter module dependency

In your host app's `pubspec.yaml`:

```yaml
dependencies:
  wellx_pets_sdk:
    path: ../WellxPetsSDK   # local path
    # — or via git —
    # git:
    #   url: https://github.com/VaibhavKashyapWellx/WellxPetsSDK.git
    #   ref: main
```

### iOS (add-to-app)

```bash
# In your iOS project directory
flutter pub get
# Then add the Flutter module via CocoaPods or XCFramework per the Flutter docs:
# https://flutter.dev/to/add-to-app
```

### Android (add-to-app)

Follow the [Flutter add-to-app guide](https://flutter.dev/to/add-to-app) and point your `settings.gradle` at this module.

---

## Quick Start

```dart
import 'package:wellx_pets_sdk/wellx_pets_sdk.dart';

// 1. Initialize once — typically in your app's startup flow
final sdk = await WellxPetsSDK.initialize(
  config: const WellxPetsConfig(
    supabaseUrl: 'https://<your-project>.supabase.co',
    supabaseAnonKey: '<your-supabase-anon-key>',
    anthropicApiKey: '<your-anthropic-api-key>',
  ),
  authDelegate: MyAuthDelegate(),   // bridges your auth system
  xCoinDelegate: MyXCoinDelegate(), // bridges your rewards system
);

// 2. Launch the full SDK UI
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => sdk.buildRootWidget()),
);
```

---

## Configuration

### Keys

| Key | How to provide |
|-----|---------------|
| `SUPABASE_ANON_KEY` | `--dart-define=SUPABASE_ANON_KEY=<key>` at build time |
| `ANTHROPIC_API_KEY` | `--dart-define=ANTHROPIC_API_KEY=<key>` at build time |

**Never hard-code secrets in source.** For standalone dev runs:

```bash
flutter run \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

### Auth Delegate

Implement `WellxAuthDelegate` to bridge the SDK to your existing auth system:

```dart
class MyAuthDelegate implements WellxAuthDelegate {
  @override
  WellxAuthState get currentAuthState => WellxAuthState(
    isAuthenticated: true,
    userId: myUser.id,
    accessToken: myUser.token,
    email: myUser.email,
    firstName: myUser.firstName,
    lastName: myUser.lastName,
  );

  @override
  Stream<WellxAuthState> get authStateStream => myAuthStream;

  @override
  Future<String> refreshToken() => myAuth.refreshToken();

  @override
  void onAuthInvalidated() => myAuth.signOut();
}
```

### xCoin Delegate

Implement `WellxXCoinDelegate` to plug the rewards system into your wallet:

```dart
class MyXCoinDelegate implements WellxXCoinDelegate {
  @override
  Future<int> onCoinEvent(WellxCoinEvent event) async {
    // Award event.suggestedCoins to the user in your system
    return newBalance;
  }

  @override
  Future<WellxWalletBalance> getBalance() async =>
      WellxWalletBalance(coinsBalance: ..., totalCoinsEarned: ...);

  @override
  Stream<WellxWalletBalance> get balanceStream => myWalletStream;
}
```

### Supabase Setup

The SDK expects the following tables in your Supabase project:

- `pets` — pet profiles
- `health_records` — BCS, wellness, urine, symptom entries
- `documents` — OCR-scanned records linked to pets
- `shelters` / `shelter_dogs` — shelter directory data
- `venues` — geo-indexed pet venues

Row-level security (RLS) should restrict all tables to `auth.uid() = owner_id`.

---

## Architecture

```
lib/
├── main.dart                  # Standalone entry point (dev only)
├── wellx_pets_sdk.dart        # Public API surface
└── src/
    ├── sdk/
    │   ├── wellx_pets_sdk.dart      # SDK singleton + initialize()
    │   ├── wellx_pets_config.dart   # Config value object
    │   ├── auth_delegate.dart       # Auth bridge interface
    │   └── xcoin_delegate.dart      # Rewards bridge interface
    ├── models/                # Freezed data models
    ├── providers/             # Riverpod providers
    ├── services/              # Supabase + Claude API services
    ├── screens/               # Feature screens
    ├── navigation/            # GoRouter configuration
    ├── theme/                 # Colors, typography, spacing
    └── widgets/               # Shared UI components
```

**State management:** Riverpod (code-gen providers)
**Navigation:** GoRouter with shell routes for tab bar
**Backend:** Supabase (auth, database, storage)
**AI:** Anthropic Claude via proxy service

---

## Development

```bash
# Install dependencies
flutter pub get

# Run code generation (Freezed, Riverpod, JSON)
dart run build_runner build --delete-conflicting-outputs

# Run standalone (requires dart-defines)
flutter run \
  --dart-define=SUPABASE_ANON_KEY=<key> \
  --dart-define=ANTHROPIC_API_KEY=<key>

# Run tests
flutter test
```

---

## License

Proprietary — WellX. All rights reserved.
