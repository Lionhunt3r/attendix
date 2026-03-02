import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests for personAttendanceStatsProvider
///
/// These tests verify that lateCount is calculated based on CriticalRule statuses,
/// not hardcoded values.
void main() {
  late String personDetailPageSource;

  setUpAll(() {
    final file = File('lib/features/people/presentation/pages/person_detail_page.dart');
    personDetailPageSource = file.readAsStringSync();
  });

  group('personAttendanceStatsProvider', () {
    group('lateCount calculation', () {
      test('should use CriticalRule statuses for lateCount, not hardcoded values', () {
        // The lateCount calculation should NOT use hardcoded status == 3 || status == 5
        // Instead it should use the statuses from the CriticalRule

        // Check that there is NO hardcoded late status filter
        final hardcodedLateFilter = RegExp(
          r'status\s*==\s*3\s*\|\|\s*status\s*==\s*5',
        );

        // Find the lateCount calculation section
        final lateCountMatch = RegExp(
          r'lateCount\s*=\s*pastAttendances\.where',
          multiLine: true,
        ).firstMatch(personDetailPageSource);

        expect(
          lateCountMatch,
          isNotNull,
          reason: 'lateCount calculation should exist in personAttendanceStatsProvider',
        );

        // The lateCount section should NOT have hardcoded values
        // Extract the where clause for lateCount
        if (lateCountMatch != null) {
          final startIndex = lateCountMatch.start;
          final searchArea = personDetailPageSource.substring(startIndex, startIndex + 200);

          expect(
            hardcodedLateFilter.hasMatch(searchArea),
            isFalse,
            reason: 'lateCount should use dynamic CriticalRule statuses, not hardcoded status == 3 || status == 5',
          );
        }
      });

      test('should read lateStatuses from CriticalRule before calculating lateCount', () {
        // The provider should extract statuses from CriticalRule
        expect(
          personDetailPageSource,
          contains('criticalRules'),
          reason: 'Provider should access tenant criticalRules to get the relevant statuses',
        );

        // And should use those statuses for filtering
        expect(
          personDetailPageSource,
          anyOf([
            contains('lateStatuses.contains'),
            contains('rule.statuses'),
          ]),
          reason: 'Provider should use CriticalRule statuses for filtering, not hardcoded values',
        );
      });
    });
  });

  group('LateWarningCard', () {
    late String lateWarningCardSource;

    setUpAll(() {
      final file = File('lib/features/people/presentation/widgets/person_detail/late_warning_card.dart');
      lateWarningCardSource = file.readAsStringSync();
    });

    test('should display dynamic text based on CriticalRule statuses', () {
      // The subtitle should not always say "unentschuldigt" if the rule includes status 5 (lateExcused)
      // It should be dynamic based on which statuses the rule includes

      // Check for dynamic text based on statuses
      final hasDynamicText = lateWarningCardSource.contains('lateStatuses.contains(5)') ||
          lateWarningCardSource.contains('statuses.contains(5)') ||
          !lateWarningCardSource.contains("'unentschuldigt zu spät'");

      expect(
        hasDynamicText,
        isTrue,
        reason: 'LateWarningCard should display dynamic text based on CriticalRule statuses, '
            'not always show "unentschuldigt" when rule might include lateExcused (status 5)',
      );
    });
  });
}
