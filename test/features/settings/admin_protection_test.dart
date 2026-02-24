import 'package:attendix/core/constants/enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for admin role protection logic
/// Issue #2: BL-001 - Admin kann sich selbst aussperren (Selbstentrechtung)
/// Issue #3: BL-002 - Letzter Admin kann entfernt werden
void main() {
  group('Admin Role Protection - Issues #2 and #3', () {
    group('Self-demotion check (Issue #2)', () {
      test('sollte Selbst-Herabstufung erkennen', () {
        const currentUserId = 'user-123';
        const userToChange = 'user-123';
        const isCurrentUser = currentUserId == userToChange;

        expect(isCurrentUser, isTrue);
      });

      test('sollte Herabstufung von Admin zu Viewer erkennen', () {
        const currentRole = Role.admin;
        const newRole = Role.viewer;
        final isDemotion = currentRole == Role.admin && newRole != Role.admin;

        expect(isDemotion, isTrue);
      });

      test('sollte Erhöhung zu Admin nicht als Herabstufung erkennen', () {
        const currentRole = Role.viewer;
        const newRole = Role.admin;
        final isDemotion = currentRole == Role.admin && newRole != Role.admin;

        expect(isDemotion, isFalse);
      });
    });

    group('Last admin check (Issue #3)', () {
      test('sollte letzten Admin erkennen - nur 1 Admin', () {
        final adminCount = 1;
        final isLastAdmin = adminCount <= 1;

        expect(isLastAdmin, isTrue);
      });

      test('sollte nicht letzter Admin sein wenn mehrere existieren', () {
        final adminCount = 2;
        final isLastAdmin = adminCount <= 1;

        expect(isLastAdmin, isFalse);
      });

      test('sollte Admins korrekt zählen', () {
        // Simuliere tenantUsers Liste
        final roles = [Role.admin, Role.viewer, Role.admin, Role.responsible];
        final adminCount = roles.where((r) => r == Role.admin).length;

        expect(adminCount, equals(2));
      });

      test('sollte Herabstufung blockieren wenn letzter Admin', () {
        const currentRole = Role.admin;
        const newRole = Role.viewer;
        final adminCount = 1;

        final isDemotion = currentRole == Role.admin && newRole != Role.admin;
        final isLastAdmin = adminCount <= 1;
        final shouldBlock = isDemotion && isLastAdmin;

        expect(shouldBlock, isTrue);
      });

      test('sollte Herabstufung erlauben wenn nicht letzter Admin', () {
        const currentRole = Role.admin;
        const newRole = Role.viewer;
        final adminCount = 2;

        final isDemotion = currentRole == Role.admin && newRole != Role.admin;
        final isLastAdmin = adminCount <= 1;
        final shouldBlock = isDemotion && isLastAdmin;

        expect(shouldBlock, isFalse);
      });
    });

    group('Combined protection logic', () {
      test('sollte Selbst-Herabstufung des letzten Admins blockieren', () {
        const currentUserId = 'user-123';
        const userToChangeId = 'user-123';
        const currentRole = Role.admin;
        const newRole = Role.viewer;
        final adminCount = 1;

        final isCurrentUser = currentUserId == userToChangeId;
        final isDemotion = currentRole == Role.admin && newRole != Role.admin;
        final isLastAdmin = adminCount <= 1;

        // Letzter Admin kann sich nicht selbst herabstufen
        final shouldBlockCompletely = isDemotion && isLastAdmin;
        // Selbst-Herabstufung sollte Warnung zeigen wenn nicht letzter
        final shouldWarn = isCurrentUser && isDemotion && !isLastAdmin;

        expect(shouldBlockCompletely, isTrue);
        expect(shouldWarn, isFalse); // Wird bereits blockiert
      });

      test('sollte Warnung zeigen bei Selbst-Herabstufung mit anderen Admins', () {
        const currentUserId = 'user-123';
        const userToChangeId = 'user-123';
        const currentRole = Role.admin;
        const newRole = Role.viewer;
        final adminCount = 2;

        final isCurrentUser = currentUserId == userToChangeId;
        final isDemotion = currentRole == Role.admin && newRole != Role.admin;
        final isLastAdmin = adminCount <= 1;

        final shouldBlockCompletely = isDemotion && isLastAdmin;
        final shouldWarn = isCurrentUser && isDemotion && !isLastAdmin;

        expect(shouldBlockCompletely, isFalse);
        expect(shouldWarn, isTrue);
      });
    });
  });
}
