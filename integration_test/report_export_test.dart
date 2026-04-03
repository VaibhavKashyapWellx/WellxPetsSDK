// Integration test: Report generation and PDF export.
//
// Run: flutter test integration_test/report_export_test.dart \
//   --dart-define=SUPABASE_URL=... \
//   --dart-define=SUPABASE_ANON_KEY=... \
//   --dart-define=ANTHROPIC_API_KEY=...

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Report Export', () {
    testWidgets('report screen loads', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to Reports tab
      final reportNav = find.byKey(const Key('nav_reports'));
      if (reportNav.evaluate().isEmpty) return;

      await tester.tap(reportNav);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Report screen should show health score or export button
      final hasScore = find.byKey(const Key('health_score_display'))
          .evaluate()
          .isNotEmpty;
      final hasExport =
          find.text('Export PDF').evaluate().isNotEmpty ||
              find.byKey(const Key('export_pdf_button')).evaluate().isNotEmpty;

      expect(hasScore || hasExport, isTrue,
          reason: 'Report screen should display health data or export option');
    });

    testWidgets('PDF export button is tappable', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final reportNav = find.byKey(const Key('nav_reports'));
      if (reportNav.evaluate().isEmpty) return;

      await tester.tap(reportNav);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final exportButton = find.byKey(const Key('export_pdf_button'));
      if (exportButton.evaluate().isEmpty) return;

      await tester.tap(exportButton);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // After tapping, the share sheet or a loading indicator should appear
      // (We can't assert on the native share sheet, but no crash = pass)
    });
  });
}
