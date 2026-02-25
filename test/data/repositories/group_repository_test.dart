import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Security tests for GroupRepository
///
/// These tests verify that ALL operations include tenantId filtering
/// to prevent cross-tenant data access.
///
/// Tables:
/// - instruments: uses 'tenantId' column
/// - group_categories: uses 'tenant_id' column
///
/// Security Model:
/// - SELECT: Must have .eq('tenantId', currentTenantId) or .eq('tenant_id', currentTenantId)
/// - UPDATE: Must have .eq('tenantId', currentTenantId) or .eq('tenant_id', currentTenantId)
/// - DELETE: Must have .eq('tenantId', currentTenantId) or .eq('tenant_id', currentTenantId)
/// - INSERT: Must set tenantId/tenant_id in the data object
void main() {
  late String groupRepoSource;

  setUpAll(() {
    final file = File('lib/data/repositories/group_repository.dart');
    groupRepoSource = file.readAsStringSync();
  });

  group('Multi-Tenant Security - GroupRepository', () {
    group('Instruments Table - Write Operations', () {
      test('createGroup sets tenantId in insert data', () {
        // Find insert on instruments table
        final insertQuery = RegExp(
          r"\.from\('instruments'\)[^;]*\.insert\(\{[^}]+\}",
          multiLine: true,
        ).firstMatch(groupRepoSource);

        expect(insertQuery, isNotNull, reason: 'Should have insert query');
        expect(
          insertQuery!.group(0),
          contains("'tenantId': currentTenantId"),
          reason: 'createGroup must set tenantId in insert data',
        );
      });

      test('all UPDATE operations on instruments table include tenantId filter', () {
        final updateQueries = RegExp(
          r"supabase[^;]*\.from\('instruments'\)[^;]*\.update\([^;]+",
          multiLine: true,
        ).allMatches(groupRepoSource);

        expect(updateQueries, isNotEmpty, reason: 'Should have update queries');

        for (final match in updateQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenantId', currentTenantId)"),
            reason: 'UPDATE query on instruments missing tenantId filter:\n$query',
          );
        }
      });

      test('all DELETE operations on instruments table include tenantId filter', () {
        final deleteQueries = RegExp(
          r"supabase[^;]*\.from\('instruments'\)[^;]*\.delete\(\)[^;]+",
          multiLine: true,
        ).allMatches(groupRepoSource);

        expect(deleteQueries, isNotEmpty, reason: 'Should have delete queries');

        for (final match in deleteQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenantId', currentTenantId)"),
            reason: 'DELETE query on instruments missing tenantId filter:\n$query',
          );
        }
      });
    });

    group('Instruments Table - Read Operations', () {
      test('all SELECT operations on instruments include tenantId filter', () {
        final selectQueries = RegExp(
          r"supabase[^;]*\.from\('instruments'\)\s*\n?\s*\.select\([^;]+",
          multiLine: true,
        ).allMatches(groupRepoSource);

        // Filter out INSERT chains
        final readQueries = selectQueries.where((m) {
          final query = m.group(0)!;
          return !query.contains('.insert(');
        }).toList();

        expect(readQueries, isNotEmpty, reason: 'Should have select queries');

        for (final match in readQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenantId', currentTenantId)"),
            reason: 'SELECT query on instruments missing tenantId filter:\n$query',
          );
        }
      });
    });

    group('Instruments Table - Core Methods', () {
      test('getGroups has tenantId filter', () {
        final section = _extractMethodBody(groupRepoSource, 'getGroups');
        expect(section, isNotNull, reason: 'getGroups should exist');
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('getGroupsMap has tenantId filter', () {
        final section = _extractMethodBody(groupRepoSource, 'getGroupsMap');
        expect(section, isNotNull, reason: 'getGroupsMap should exist');
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('getMainGroup has tenantId filter', () {
        final section = _extractMethodBody(groupRepoSource, 'getMainGroup');
        expect(section, isNotNull, reason: 'getMainGroup should exist');
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('getGroupById has both id and tenantId filter', () {
        final section = _extractMethodBody(groupRepoSource, 'getGroupById');
        expect(section, isNotNull, reason: 'getGroupById should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('updateGroup has both id and tenantId filter', () {
        final section = _extractMethodBody(groupRepoSource, 'updateGroup');
        expect(section, isNotNull, reason: 'updateGroup should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('deleteGroup has both id and tenantId filter', () {
        final section = _extractMethodBody(groupRepoSource, 'deleteGroup');
        expect(section, isNotNull, reason: 'deleteGroup should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });
    });

    group('Group Categories Table - Write Operations', () {
      test('createGroupCategory sets tenant_id in insert data', () {
        final section = _extractMethodBody(groupRepoSource, 'createGroupCategory');
        expect(section, isNotNull, reason: 'createGroupCategory should exist');
        expect(
          section,
          contains("'tenant_id': currentTenantId"),
          reason: 'createGroupCategory must set tenant_id in insert data',
        );
      });

      test('all UPDATE operations on group_categories include tenant_id filter', () {
        final updateQueries = RegExp(
          r"supabase[^;]*\.from\('group_categories'\)[^;]*\.update\([^;]+",
          multiLine: true,
        ).allMatches(groupRepoSource);

        expect(updateQueries, isNotEmpty, reason: 'Should have update queries');

        for (final match in updateQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenant_id', currentTenantId)"),
            reason: 'UPDATE query on group_categories missing tenant_id filter:\n$query',
          );
        }
      });

      test('all DELETE operations on group_categories include tenant_id filter', () {
        final deleteQueries = RegExp(
          r"supabase[^;]*\.from\('group_categories'\)[^;]*\.delete\(\)[^;]+",
          multiLine: true,
        ).allMatches(groupRepoSource);

        expect(deleteQueries, isNotEmpty, reason: 'Should have delete queries');

        for (final match in deleteQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenant_id', currentTenantId)"),
            reason: 'DELETE query on group_categories missing tenant_id filter:\n$query',
          );
        }
      });
    });

    group('Group Categories Table - Read Operations', () {
      test('getGroupCategories has tenant_id filter', () {
        final section = _extractMethodBody(groupRepoSource, 'getGroupCategories');
        expect(section, isNotNull, reason: 'getGroupCategories should exist');
        expect(section, contains(".eq('tenant_id', currentTenantId)"));
      });
    });

    group('Group Categories Table - Core Methods', () {
      test('updateGroupCategory has both id and tenant_id filter', () {
        final section = _extractMethodBody(groupRepoSource, 'updateGroupCategory');
        expect(section, isNotNull, reason: 'updateGroupCategory should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenant_id', currentTenantId)"));
      });

      test('deleteGroupCategory has both id and tenant_id filter', () {
        final section = _extractMethodBody(groupRepoSource, 'deleteGroupCategory');
        expect(section, isNotNull, reason: 'deleteGroupCategory should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenant_id', currentTenantId)"));
      });
    });

    group('Summary Statistics', () {
      test('high tenantId filter coverage for instruments table', () {
        final allInstrumentQueries = RegExp(
          r"\.from\('instruments'\)",
        ).allMatches(groupRepoSource).length;

        final withTenantFilter = RegExp(
          r"\.from\('instruments'\)[^;]*\.eq\('tenantId',\s*currentTenantId\)",
          multiLine: true,
        ).allMatches(groupRepoSource).length;

        final insertWithTenant = groupRepoSource.contains("'tenantId': currentTenantId")
            ? 1
            : 0;

        final totalCovered = withTenantFilter + insertWithTenant;

        // ignore: avoid_print
        print('Instruments queries: $allInstrumentQueries');
        // ignore: avoid_print
        print('With tenantId filter: $withTenantFilter');
        // ignore: avoid_print
        print('Insert with tenant: $insertWithTenant');
        // ignore: avoid_print
        print('Total covered: $totalCovered');

        final coverage = totalCovered / allInstrumentQueries;
        expect(
          coverage,
          greaterThanOrEqualTo(0.8),
          reason: 'Expected at least 80% tenantId coverage for instruments, got ${(coverage * 100).toStringAsFixed(1)}%',
        );
      });

      test('high tenant_id filter coverage for group_categories table', () {
        final allCategoryQueries = RegExp(
          r"\.from\('group_categories'\)",
        ).allMatches(groupRepoSource).length;

        final withTenantFilter = RegExp(
          r"\.from\('group_categories'\)[^;]*\.eq\('tenant_id',\s*currentTenantId\)",
          multiLine: true,
        ).allMatches(groupRepoSource).length;

        final insertWithTenant = groupRepoSource.contains("'tenant_id': currentTenantId")
            ? 1
            : 0;

        final totalCovered = withTenantFilter + insertWithTenant;

        // ignore: avoid_print
        print('Group categories queries: $allCategoryQueries');
        // ignore: avoid_print
        print('With tenant_id filter: $withTenantFilter');
        // ignore: avoid_print
        print('Insert with tenant: $insertWithTenant');
        // ignore: avoid_print
        print('Total covered: $totalCovered');

        final coverage = totalCovered / allCategoryQueries;
        expect(
          coverage,
          greaterThanOrEqualTo(0.8),
          reason: 'Expected at least 80% tenant_id coverage for group_categories, got ${(coverage * 100).toStringAsFixed(1)}%',
        );
      });
    });
  });
}

/// Extract method body from source code
String? _extractMethodBody(String source, String methodName) {
  // More flexible regex that handles generic return types like Future<List<T>>
  final methodStart = RegExp(
    '(Future<[^>]*(?:<[^>]*>)?[^>]*>|void)\\s+$methodName\\s*\\(',
  ).firstMatch(source);

  if (methodStart == null) return null;

  final startIndex = methodStart.start;

  int braceIndex = startIndex;
  int parenCount = 0;
  bool foundMethodBrace = false;

  for (int i = startIndex; i < source.length && !foundMethodBrace; i++) {
    final char = source[i];
    if (char == '(' || char == '{' && parenCount > 0) {
      parenCount++;
    } else if (char == ')' || char == '}' && parenCount > 1) {
      parenCount--;
    } else if (char == '{' && parenCount == 0) {
      braceIndex = i;
      foundMethodBrace = true;
    }
  }

  if (!foundMethodBrace) return null;

  int braceCount = 0;
  int endIndex = braceIndex;

  for (int i = braceIndex; i < source.length; i++) {
    if (source[i] == '{') {
      braceCount++;
    } else if (source[i] == '}') {
      braceCount--;
      if (braceCount == 0) {
        endIndex = i + 1;
        break;
      }
    }
  }

  return source.substring(startIndex, endIndex);
}
