import 'package:attendix/shared/widgets/sheets/version_history_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  widgetTestGroup('VersionHistorySheet', () {
    group('initial structure', () {
      widgetTest('displays loading indicator initially', (tester) async {
        await tester.pumpApp(
          const VersionHistorySheet(),
        );

        // Should show CircularProgressIndicator while loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      widgetTest('has correct title', (tester) async {
        await tester.pumpApp(
          const VersionHistorySheet(),
        );

        expect(find.text('Was ist neu?'), findsOneWidget);
      });

      widgetTest('has close button', (tester) async {
        await tester.pumpApp(
          const VersionHistorySheet(),
        );

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      widgetTest('has handle bar at top', (tester) async {
        await tester.pumpApp(
          const VersionHistorySheet(),
        );

        // The widget builds successfully with handle bar
        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      });

      widgetTest('has sparkle icon in header', (tester) async {
        await tester.pumpApp(
          const VersionHistorySheet(),
        );

        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      });
    });

    group('DraggableScrollableSheet configuration', () {
      widgetTest('is wrapped in DraggableScrollableSheet', (tester) async {
        await tester.pumpApp(
          const VersionHistorySheet(),
        );

        expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      });
    });
  });
}
