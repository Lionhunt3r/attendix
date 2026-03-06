import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// RT-001/002/003: Force Unwrap auf tenant.id! und criticalRules! ohne null-Check
/// These tests verify that no force-unwrap on tenant.id! or criticalRules! exists
/// in the affected files (source code analysis pattern).
void main() {
  group('RT-001/002/003: No force-unwrap on tenant fields', () {
    test('people_list_page.dart has no tenant.id! force-unwrap', () {
      final source = File(
        'lib/features/people/presentation/pages/people_list_page.dart',
      ).readAsStringSync();

      expect(
        source.contains('tenant.id!'),
        isFalse,
        reason:
            'people_list_page.dart still uses tenant.id! force-unwrap. '
            'Use local variable with null-check instead.',
      );
    });

    test('person_detail_page.dart has no tenant.id! force-unwrap', () {
      final source = File(
        'lib/features/people/presentation/pages/person_detail_page.dart',
      ).readAsStringSync();

      expect(
        source.contains('tenant.id!'),
        isFalse,
        reason:
            'person_detail_page.dart still uses tenant.id! force-unwrap. '
            'Use local variable with null-check instead.',
      );
    });

    test('person_detail_page.dart has no tenant!.criticalRules! force-unwrap',
        () {
      final source = File(
        'lib/features/people/presentation/pages/person_detail_page.dart',
      ).readAsStringSync();

      expect(
        source.contains('tenant!.criticalRules!'),
        isFalse,
        reason:
            'person_detail_page.dart still uses tenant!.criticalRules! '
            'force-unwrap. Use local variable with null-check instead.',
      );
    });

    test('late_warning_card.dart has no tenant!.criticalRules! force-unwrap',
        () {
      final source = File(
        'lib/features/people/presentation/widgets/person_detail/late_warning_card.dart',
      ).readAsStringSync();

      expect(
        source.contains('tenant!.criticalRules!'),
        isFalse,
        reason:
            'late_warning_card.dart still uses tenant!.criticalRules! '
            'force-unwrap. Use local variable with null-check instead.',
      );
    });
  });
}
