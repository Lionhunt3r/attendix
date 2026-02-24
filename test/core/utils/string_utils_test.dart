import 'package:attendix/core/utils/string_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringUtils - Issue #4 RT-001', () {
    group('getInitials', () {
      test('sollte 2 Zeichen bei normalen Strings zurückgeben', () {
        expect(StringUtils.getInitials('Orchestra', 2), equals('OR'));
        expect(StringUtils.getInitials('Test', 2), equals('TE'));
      });

      test('sollte mit genau 1 Zeichen funktionieren - keine RangeError', () {
        expect(StringUtils.getInitials('A', 2), equals('A'));
        expect(StringUtils.getInitials('X', 2), equals('X'));
      });

      test('sollte mit genau 2 Zeichen funktionieren', () {
        expect(StringUtils.getInitials('AB', 2), equals('AB'));
      });

      test('sollte Fallback bei leerem String zurückgeben', () {
        expect(StringUtils.getInitials('', 2), equals('?'));
      });

      test('sollte Fallback bei null zurückgeben', () {
        expect(StringUtils.getInitials(null, 2), equals('?'));
      });

      test('sollte custom Fallback unterstützen', () {
        expect(StringUtils.getInitials('', 2, fallback: '??'), equals('??'));
        expect(StringUtils.getInitials(null, 2, fallback: 'N/A'), equals('N/A'));
      });

      test('sollte immer uppercase zurückgeben', () {
        expect(StringUtils.getInitials('orchestra', 2), equals('OR'));
        expect(StringUtils.getInitials('a', 2), equals('A'));
      });

      test('sollte mit verschiedenen Längen funktionieren', () {
        expect(StringUtils.getInitials('Orchestra', 1), equals('O'));
        expect(StringUtils.getInitials('Orchestra', 3), equals('ORC'));
        expect(StringUtils.getInitials('AB', 3), equals('AB')); // String kürzer als gewünschte Länge
      });
    });

    group('getTenantInitials', () {
      test('sollte shortName bevorzugen wenn nicht leer', () {
        expect(StringUtils.getTenantInitials('Short', 'Long Name'), equals('SH'));
      });

      test('sollte auf longName fallen wenn shortName leer', () {
        expect(StringUtils.getTenantInitials('', 'Orchestra'), equals('OR'));
      });

      test('sollte mit kurzem shortName funktionieren - keine RangeError', () {
        expect(StringUtils.getTenantInitials('A', 'Long'), equals('A'));
      });

      test('sollte mit kurzem longName funktionieren wenn shortName leer', () {
        expect(StringUtils.getTenantInitials('', 'X'), equals('X'));
      });

      test('sollte Fallback bei beiden leeren Namen zurückgeben', () {
        expect(StringUtils.getTenantInitials('', ''), equals('?'));
      });
    });
  });
}
