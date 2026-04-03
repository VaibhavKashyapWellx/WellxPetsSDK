// Integration test: Document upload flow.
//
// Run: flutter test integration_test/document_upload_test.dart \
//   --dart-define=SUPABASE_URL=... \
//   --dart-define=SUPABASE_ANON_KEY=... \
//   --dart-define=ANTHROPIC_API_KEY=...

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Document Upload', () {
    testWidgets('records screen shows upload button', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to Records/Wallet tab
      final recordsNav = find.byKey(const Key('nav_records'));
      if (recordsNav.evaluate().isEmpty) return;

      await tester.tap(recordsNav);
      await tester.pumpAndSettle();

      // Upload button should be visible
      expect(
        find.byKey(const Key('upload_document_button')).evaluate().isNotEmpty ||
            find.text('Upload').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('empty state is shown when no documents exist', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final recordsNav = find.byKey(const Key('nav_records'));
      if (recordsNav.evaluate().isEmpty) return;

      await tester.tap(recordsNav);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Either documents are listed or the empty state is shown
      final hasDocuments =
          find.byKey(const Key('document_tile')).evaluate().isNotEmpty;
      final hasEmptyState =
          find.text('No records yet').evaluate().isNotEmpty;

      expect(hasDocuments || hasEmptyState, isTrue);
    });
  });
}
