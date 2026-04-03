// Integration test: Vet Chat — send a message and receive a response.
//
// Run: flutter test integration_test/vet_chat_test.dart \
//   --dart-define=SUPABASE_URL=... \
//   --dart-define=SUPABASE_ANON_KEY=... \
//   --dart-define=ANTHROPIC_API_KEY=...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Vet Chat', () {
    testWidgets('chat screen loads', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to vet chat via bottom nav or home card
      final chatNav = find.byKey(const Key('nav_chat'));
      if (chatNav.evaluate().isNotEmpty) {
        await tester.tap(chatNav);
        await tester.pumpAndSettle();
      }

      // Dr. Layla greeting or empty state should be visible
      final drLayla = find.text('Dr. Layla');
      final chatInput = find.byKey(const Key('chat_input_field'));
      expect(drLayla.evaluate().isNotEmpty || chatInput.evaluate().isNotEmpty,
          isTrue);
    });

    testWidgets('can type and send a message', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final chatNav = find.byKey(const Key('nav_chat'));
      if (chatNav.evaluate().isEmpty) return;

      await tester.tap(chatNav);
      await tester.pumpAndSettle();

      final input = find.byKey(const Key('chat_input_field'));
      if (input.evaluate().isEmpty) return;

      await tester.enterText(input, 'What should I feed my dog?');
      await tester.pump();

      final sendButton = find.byKey(const Key('chat_send_button'));
      if (sendButton.evaluate().isEmpty) return;

      await tester.tap(sendButton);
      await tester.pump();

      // User message should appear immediately
      expect(find.text('What should I feed my dog?'), findsOneWidget);

      // Wait for AI response (up to 30 seconds for real API call)
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // A response bubble from the assistant should appear
      final messages = find.byKey(const Key('chat_message_bubble'));
      expect(messages.evaluate().length, greaterThanOrEqualTo(2));
    });
  });
}
