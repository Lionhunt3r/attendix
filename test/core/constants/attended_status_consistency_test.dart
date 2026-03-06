import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BL-003: Tests that all "attended" status checks use the centralized
/// countsAsPresent getter instead of manual inline comparisons.
void main() {
  group('BL-003: No raw integer checks for attended status', () {
    test('person_detail_page.dart uses countsAsPresent instead of raw int check',
        () {
      final source = File(
        'lib/features/people/presentation/pages/person_detail_page.dart',
      ).readAsStringSync();

      expect(
        RegExp(r'status\s*==\s*1\s*\|\|\s*status\s*==\s*3\s*\|\|\s*status\s*==\s*5')
            .hasMatch(source),
        isFalse,
        reason: 'person_detail_page.dart uses raw integer status check. '
            'Use AttendanceStatus.fromValue(status).countsAsPresent instead.',
      );
    });

    test(
        'andere_instanzen_accordion.dart uses countsAsPresent instead of raw int check',
        () {
      final source = File(
        'lib/features/people/presentation/widgets/person_detail/andere_instanzen_accordion.dart',
      ).readAsStringSync();

      expect(
        RegExp(r'status\s*==\s*1\s*\|\|\s*status\s*==\s*3\s*\|\|\s*status\s*==\s*5')
            .hasMatch(source),
        isFalse,
        reason: 'andere_instanzen_accordion.dart uses raw integer status check. '
            'Use AttendanceStatus.fromValue(status).countsAsPresent instead.',
      );
    });

    test(
        'statistics_providers.dart uses countsAsPresent instead of inline enum check',
        () {
      final source = File(
        'lib/core/providers/statistics_providers.dart',
      ).readAsStringSync();

      // Should not have inline "pa.status == AttendanceStatus.present || .late || .lateExcused"
      final inlinePattern = RegExp(
        r'\.status\s*==\s*AttendanceStatus\.present\s*\|\|'
        r'\s*\w+\.status\s*==\s*AttendanceStatus\.late\s*\|\|'
        r'\s*\w+\.status\s*==\s*AttendanceStatus\.lateExcused',
      );

      expect(
        inlinePattern.hasMatch(source),
        isFalse,
        reason: 'statistics_providers.dart uses inline attended check. '
            'Use .status.countsAsPresent instead.',
      );
    });

    test(
        'export_service.dart uses countsAsPresent instead of inline enum check',
        () {
      final source = File(
        'lib/core/services/export_service.dart',
      ).readAsStringSync();

      // Should not have inline "s == AttendanceStatus.present || .late || .lateExcused"
      final inlinePattern = RegExp(
        r'==\s*AttendanceStatus\.present\s*\|\|'
        r'\s*\w+\s*==\s*AttendanceStatus\.late\s*\|\|'
        r'\s*\w+\s*==\s*AttendanceStatus\.lateExcused',
      );

      expect(
        inlinePattern.hasMatch(source),
        isFalse,
        reason: 'export_service.dart uses inline attended check. '
            'Use .countsAsPresent instead.',
      );
    });
  });
}
