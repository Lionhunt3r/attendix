import 'package:attendix/core/constants/enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// BL-007: Tests for Role.canSeeMembersTab permission logic.
void main() {
  group('BL-007: canSeeMembersTab role permissions', () {
    test('player can see members tab', () {
      expect(Role.player.canSeeMembersTab, isTrue);
    });

    test('helper can see members tab', () {
      expect(Role.helper.canSeeMembersTab, isTrue);
    });

    test('voiceLeader can see members tab', () {
      expect(Role.voiceLeader.canSeeMembersTab, isTrue);
    });

    test('voiceLeaderHelper can see members tab', () {
      expect(Role.voiceLeaderHelper.canSeeMembersTab, isTrue);
    });

    test('applicant cannot see members tab', () {
      expect(Role.applicant.canSeeMembersTab, isFalse);
    });

    test('none cannot see members tab (fallback role has no permissions)', () {
      expect(Role.none.canSeeMembersTab, isFalse);
    });

    test('conductors do not see members tab (they have People tab)', () {
      expect(Role.admin.canSeeMembersTab, isFalse);
      expect(Role.responsible.canSeeMembersTab, isFalse);
      expect(Role.viewer.canSeeMembersTab, isFalse);
    });

    test('parent cannot see members tab', () {
      expect(Role.parent.canSeeMembersTab, isFalse);
    });
  });

  group('BL-007: canSeeMembersTab consistency', () {
    test('no role has canSeeMembersTab but not canView', () {
      for (final role in Role.values) {
        if (role.canSeeMembersTab) {
          expect(
            role.canView,
            isTrue,
            reason:
                '${role.name} has canSeeMembersTab but not canView - inconsistent',
          );
        }
      }
    });
  });
}
