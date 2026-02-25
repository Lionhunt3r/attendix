import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentTenantNotifier - Navigation Bug Fix', () {
    late String tenantProvidersSource;

    setUpAll(() async {
      final file = File('lib/core/providers/tenant_providers.dart');
      tenantProvidersSource = await file.readAsString();
    });

    test('setTenantLocal should exist as a method', () {
      expect(
        tenantProvidersSource.contains('Future<void> setTenantLocal'),
        isTrue,
        reason: 'setTenantLocal() method should be defined in tenant_providers.dart '
            'to allow setting tenant without triggering auth sync',
      );
    });

    test('setTenantLocal should NOT call updateCurrentTenantId', () {
      // Extract the setTenantLocal method body
      final setTenantLocalMatch = RegExp(
        r'Future<void> setTenantLocal\(Tenant\? tenant\) async \{([\s\S]*?)\n  \}',
        multiLine: true,
      ).firstMatch(tenantProvidersSource);

      expect(
        setTenantLocalMatch,
        isNotNull,
        reason: 'setTenantLocal() method should be defined',
      );

      if (setTenantLocalMatch != null) {
        final methodBody = setTenantLocalMatch.group(1)!;

        // Check for actual method call (not just mention in comments)
        // A call would look like .updateCurrentTenantId( or updateCurrentTenantId(
        final hasMethodCall = RegExp(r'\.?updateCurrentTenantId\s*\(')
            .hasMatch(methodBody.replaceAll(RegExp(r'//.*'), '')); // Remove comments

        expect(
          hasMethodCall,
          isFalse,
          reason: 'setTenantLocal() should NOT call updateCurrentTenantId() '
              'to avoid triggering auth events that interrupt navigation',
        );
      }
    });

    test('setTenantLocal should set state and persist to SharedPreferences', () {
      final setTenantLocalMatch = RegExp(
        r'Future<void> setTenantLocal\(Tenant\? tenant\) async \{([\s\S]*?)\n  \}',
        multiLine: true,
      ).firstMatch(tenantProvidersSource);

      expect(setTenantLocalMatch, isNotNull);

      if (setTenantLocalMatch != null) {
        final methodBody = setTenantLocalMatch.group(1)!;

        // Should set state
        expect(
          methodBody.contains('state = tenant'),
          isTrue,
          reason: 'setTenantLocal() should set state',
        );

        // Should persist to SharedPreferences
        expect(
          methodBody.contains('SharedPreferences'),
          isTrue,
          reason: 'setTenantLocal() should persist to SharedPreferences',
        );
      }
    });
  });

  group('TenantSelectionPage - Navigation Bug Fix', () {
    late String tenantSelectionPageSource;

    setUpAll(() async {
      final file = File(
        'lib/features/tenant_selection/presentation/pages/tenant_selection_page.dart',
      );
      tenantSelectionPageSource = await file.readAsString();
    });

    test('_selectTenant should use setTenantLocal instead of setTenant', () {
      // Extract _selectTenant method
      final selectTenantMatch = RegExp(
        r'Future<void> _selectTenant\(Tenant tenant\) async \{([\s\S]*?)\n  \}',
        multiLine: true,
      ).firstMatch(tenantSelectionPageSource);

      expect(selectTenantMatch, isNotNull, reason: '_selectTenant method should exist');

      if (selectTenantMatch != null) {
        final methodBody = selectTenantMatch.group(1)!;

        // Should use setTenantLocal
        expect(
          methodBody.contains('setTenantLocal'),
          isTrue,
          reason: '_selectTenant should call setTenantLocal() to avoid '
              'auth events interrupting navigation',
        );

        // Should NOT call setTenant directly (which triggers auth sync)
        final setTenantCalls = RegExp(r'\.setTenant\(').allMatches(methodBody);
        expect(
          setTenantCalls.isEmpty,
          isTrue,
          reason: '_selectTenant should NOT call setTenant() directly '
              'because it triggers auth events that interrupt navigation',
        );
      }
    });

    test('_selectTenant should call updateCurrentTenantId AFTER navigation', () {
      final selectTenantMatch = RegExp(
        r'Future<void> _selectTenant\(Tenant tenant\) async \{([\s\S]*?)\n  \}',
        multiLine: true,
      ).firstMatch(tenantSelectionPageSource);

      if (selectTenantMatch != null) {
        final methodBody = selectTenantMatch.group(1)!;

        // Find positions of navigation and auth sync
        final goPosition = methodBody.indexOf('context.go(');
        final authSyncPosition = methodBody.indexOf('updateCurrentTenantId');

        // Auth sync should come AFTER navigation
        if (authSyncPosition >= 0 && goPosition >= 0) {
          expect(
            authSyncPosition > goPosition,
            isTrue,
            reason: 'updateCurrentTenantId should be called AFTER context.go() '
                'to prevent auth events from interrupting navigation',
          );
        }
      }
    });
  });
}
