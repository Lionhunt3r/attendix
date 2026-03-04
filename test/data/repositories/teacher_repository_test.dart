import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Security tests for TeacherRepository
///
/// These tests verify that ALL operations include tenantId filtering
/// to prevent cross-tenant data access.
///
/// Tables:
/// - teachers: uses 'tenantId' column
///
/// Security Model:
/// - SELECT: Must have .eq('tenantId', currentTenantId)
/// - UPDATE: Must have .eq('tenantId', currentTenantId)
/// - DELETE: Must have .eq('tenantId', currentTenantId)
/// - INSERT: Must set tenantId in the data object
void main() {
  late String repoSource;

  setUpAll(() {
    final file = File('lib/data/repositories/teacher_repository.dart');
    repoSource = file.readAsStringSync();
  });

  group('Multi-Tenant Security - TeacherRepository', () {
    group('Ausbilder Table - Write Operations', () {
      test('createTeacher sets tenant_id in insert data', () {
        final section = _extractMethodBody(repoSource, 'createTeacher');
        expect(section, isNotNull, reason: 'createTeacher should exist');
        expect(
          section,
          contains("'tenantId': currentTenantId"),
          reason: 'createTeacher must set tenantId in insert data',
        );
      });

      test('all UPDATE operations include tenant_id filter', () {
        final updateQueries = RegExp(
          r"supabase[^;]*\.from\('teachers'\)[^;]*\.update\([^;]+",
          multiLine: true,
        ).allMatches(repoSource);

        expect(updateQueries, isNotEmpty, reason: 'Should have update queries');

        for (final match in updateQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenantId', currentTenantId)"),
            reason: 'UPDATE query on teachers missing tenantId filter:\n$query',
          );
        }
      });

      test('all DELETE operations include tenant_id filter', () {
        final deleteQueries = RegExp(
          r"supabase[^;]*\.from\('teachers'\)[^;]*\.delete\(\)[^;]+",
          multiLine: true,
        ).allMatches(repoSource);

        expect(deleteQueries, isNotEmpty, reason: 'Should have delete queries');

        for (final match in deleteQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenantId', currentTenantId)"),
            reason: 'DELETE query on teachers missing tenantId filter:\n$query',
          );
        }
      });
    });

    group('Ausbilder Table - Read Operations', () {
      test('all SELECT operations on teachers include tenant_id filter', () {
        final selectQueries = RegExp(
          r"supabase[^;]*\.from\('teachers'\)\s*\n?\s*\.select\([^;]+",
          multiLine: true,
        ).allMatches(repoSource);

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
            reason: 'SELECT query on teachers missing tenantId filter:\n$query',
          );
        }
      });
    });

    group('Core Methods Security', () {
      test('getTeachers has tenant_id filter', () {
        final section = _extractMethodBody(repoSource, 'getTeachers');
        expect(section, isNotNull, reason: 'getTeachers should exist');
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('getTeacherById has both id and tenant_id filter', () {
        final section = _extractMethodBody(repoSource, 'getTeacherById');
        expect(section, isNotNull, reason: 'getTeacherById should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('updateTeacher has both id and tenant_id filter', () {
        final section = _extractMethodBody(repoSource, 'updateTeacher');
        expect(section, isNotNull, reason: 'updateTeacher should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('deleteTeacher has both id and tenant_id filter', () {
        final section = _extractMethodBody(repoSource, 'deleteTeacher');
        expect(section, isNotNull, reason: 'deleteTeacher should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('getStudentCounts has tenant_id filter', () {
        final section = _extractMethodBody(repoSource, 'getStudentCounts');
        expect(section, isNotNull, reason: 'getStudentCounts should exist');
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });
    });

    group('Summary Statistics', () {
      test('high tenant_id filter coverage for teachers table', () {
        final allQueries = RegExp(
          r"\.from\('teachers'\)",
        ).allMatches(repoSource).length;

        final withTenantFilter = RegExp(
          r"\.from\('teachers'\)[^;]*\.eq\('tenantId',\s*currentTenantId\)",
          multiLine: true,
        ).allMatches(repoSource).length;

        final insertWithTenant = repoSource.contains("'tenantId': currentTenantId")
            ? 1
            : 0;

        final totalCovered = withTenantFilter + insertWithTenant;

        // ignore: avoid_print
        print('Total teachers queries: $allQueries');
        // ignore: avoid_print
        print('With tenantId filter: $withTenantFilter');
        // ignore: avoid_print
        print('Insert with tenant: $insertWithTenant');
        // ignore: avoid_print
        print('Total covered: $totalCovered');

        final coverage = totalCovered / allQueries;
        expect(
          coverage,
          greaterThanOrEqualTo(0.8),
          reason: 'Expected at least 80% tenantId coverage for teachers, got ${(coverage * 100).toStringAsFixed(1)}%',
        );
      });
    });
  });
}

/// Extract method body from source code
String? _extractMethodBody(String source, String methodName) {
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
