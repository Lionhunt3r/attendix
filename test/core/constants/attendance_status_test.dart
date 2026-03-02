import 'package:flutter_test/flutter_test.dart';
import 'package:attendix/core/constants/enums.dart';

/// BL-003: Tests for consistent "attended" definition
void main() {
  group('AttendanceStatus.countsAsPresent', () {
    test('present counts as present', () {
      expect(AttendanceStatus.present.countsAsPresent, isTrue);
    });

    test('late counts as present', () {
      expect(AttendanceStatus.late.countsAsPresent, isTrue);
    });

    test('lateExcused counts as present', () {
      expect(AttendanceStatus.lateExcused.countsAsPresent, isTrue);
    });

    test('absent does not count as present', () {
      expect(AttendanceStatus.absent.countsAsPresent, isFalse);
    });

    test('excused does not count as present', () {
      expect(AttendanceStatus.excused.countsAsPresent, isFalse);
    });

    test('neutral does not count as present', () {
      expect(AttendanceStatus.neutral.countsAsPresent, isFalse);
    });
  });

  group('AttendanceStatus numeric values - BL-003 regression', () {
    test('late is 3 (not 4!)', () {
      expect(AttendanceStatus.late.value, equals(3));
    });

    test('absent is 4', () {
      expect(AttendanceStatus.absent.value, equals(4));
    });

    test('lateExcused is 5', () {
      expect(AttendanceStatus.lateExcused.value, equals(5));
    });

    test('countsAsPresent matches numeric values correctly', () {
      // These should count as present (1, 3, 5)
      expect(AttendanceStatus.fromValue(1).countsAsPresent, isTrue); // present
      expect(AttendanceStatus.fromValue(3).countsAsPresent, isTrue); // late
      expect(AttendanceStatus.fromValue(5).countsAsPresent, isTrue); // lateExcused

      // These should NOT count as present (0, 2, 4)
      expect(AttendanceStatus.fromValue(0).countsAsPresent, isFalse); // neutral
      expect(AttendanceStatus.fromValue(2).countsAsPresent, isFalse); // excused
      expect(AttendanceStatus.fromValue(4).countsAsPresent, isFalse); // absent!
    });
  });
}
