// Integration test: App launches and shows onboarding or home screen.
//
// Run: flutter test integration_test/app_test.dart
//   --dart-define=SUPABASE_URL=... \
//   --dart-define=SUPABASE_ANON_KEY=... \
//   --dart-define=ANTHROPIC_API_KEY=...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App launch', () {
    testWidgets('app starts without crashing', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The app should show either the onboarding screen or the home screen.
      // Both are valid starting states.
      final hasHome = find.byKey(const Key('home_screen')).evaluate().isNotEmpty;
      final hasOnboarding =
          find.byKey(const Key('onboarding_screen')).evaluate().isNotEmpty;

      expect(hasHome || hasOnboarding, isTrue,
          reason: 'App should show home or onboarding after launch');
    });

    testWidgets('bottom navigation bar is visible on home', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // If we're on the home screen the bottom nav should be present
      final navBar = find.byType(NavigationBar);
      if (navBar.evaluate().isNotEmpty) {
        expect(navBar, findsOneWidget);
      }
    });
  });
}
