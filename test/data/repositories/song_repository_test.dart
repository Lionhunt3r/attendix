import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Security tests for SongRepository
///
/// These tests verify that ALL operations include tenantId filtering
/// to prevent cross-tenant data access.
///
/// Tables:
/// - songs: uses 'tenantId' column
/// - song_categories: uses 'tenant_id' column
/// - song_history: uses 'tenant_id' column
///
/// Security Model:
/// - SELECT: Must have .eq('tenantId', currentTenantId) or .eq('tenant_id', currentTenantId)
/// - UPDATE: Must have .eq('tenantId', currentTenantId)
/// - DELETE: Must have .eq('tenantId', currentTenantId)
/// - INSERT: Must set tenantId/tenant_id in the data object
void main() {
  late String songRepoSource;

  setUpAll(() {
    final file = File('lib/data/repositories/song_repository.dart');
    songRepoSource = file.readAsStringSync();
  });

  group('Multi-Tenant Security - SongRepository', () {
    group('Songs Table - Write Operations', () {
      test('createSong sets tenantId in insert data', () {
        final section = _extractMethodBody(songRepoSource, 'createSong');
        expect(section, isNotNull, reason: 'createSong should exist');
        expect(
          section,
          contains("data['tenantId'] = currentTenantId"),
          reason: 'createSong must set tenantId in insert data',
        );
      });

      test('all UPDATE operations on songs table include tenantId filter', () {
        final updateQueries = RegExp(
          r"supabase[^;]*\.from\('songs'\)[^;]*\.update\([^;]+",
          multiLine: true,
        ).allMatches(songRepoSource);

        expect(updateQueries, isNotEmpty, reason: 'Should have update queries');

        for (final match in updateQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenantId', currentTenantId)"),
            reason: 'UPDATE query on songs missing tenantId filter:\n$query',
          );
        }
      });

      test('all DELETE operations on songs table include tenantId filter', () {
        final deleteQueries = RegExp(
          r"supabase[^;]*\.from\('songs'\)[^;]*\.delete\(\)[^;]+",
          multiLine: true,
        ).allMatches(songRepoSource);

        expect(deleteQueries, isNotEmpty, reason: 'Should have delete queries');

        for (final match in deleteQueries) {
          final query = match.group(0)!;
          expect(
            query,
            contains(".eq('tenantId', currentTenantId)"),
            reason: 'DELETE query on songs missing tenantId filter:\n$query',
          );
        }
      });
    });

    group('Songs Table - Read Operations', () {
      test('all SELECT operations on songs include tenantId filter', () {
        final selectQueries = RegExp(
          r"supabase[^;]*\.from\('songs'\)\s*\n?\s*\.select\([^;]+",
          multiLine: true,
        ).allMatches(songRepoSource);

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
            reason: 'SELECT query on songs missing tenantId filter:\n$query',
          );
        }
      });
    });

    group('Songs Table - Core Methods', () {
      test('getSongs has tenantId filter', () {
        final section = _extractMethodBody(songRepoSource, 'getSongs');
        expect(section, isNotNull, reason: 'getSongs should exist');
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('getSongById has both id and tenantId filter', () {
        final section = _extractMethodBody(songRepoSource, 'getSongById');
        expect(section, isNotNull, reason: 'getSongById should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('updateSong has both id and tenantId filter', () {
        final section = _extractMethodBody(songRepoSource, 'updateSong');
        expect(section, isNotNull, reason: 'updateSong should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('deleteSong has both id and tenantId filter', () {
        final section = _extractMethodBody(songRepoSource, 'deleteSong');
        expect(section, isNotNull, reason: 'deleteSong should exist');
        expect(section, contains(".eq('id', id)"));
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });

      test('searchSongs has tenantId filter', () {
        final section = _extractMethodBody(songRepoSource, 'searchSongs');
        expect(section, isNotNull, reason: 'searchSongs should exist');
        expect(section, contains(".eq('tenantId', currentTenantId)"));
      });
    });

    group('Song Categories Table', () {
      test('getSongCategories has tenant_id filter', () {
        final section = _extractMethodBody(songRepoSource, 'getSongCategories');
        expect(section, isNotNull, reason: 'getSongCategories should exist');
        expect(section, contains(".eq('tenant_id', currentTenantId)"));
      });
    });

    group('Song History Table', () {
      test('getSongHistory has tenant_id filter', () {
        final section = _extractMethodBody(songRepoSource, 'getSongHistory');
        expect(section, isNotNull, reason: 'getSongHistory should exist');
        expect(section, contains(".eq('tenant_id', currentTenantId)"));
      });

      test('addSongHistory sets tenant_id in insert data', () {
        final section = _extractMethodBody(songRepoSource, 'addSongHistory');
        expect(section, isNotNull, reason: 'addSongHistory should exist');
        expect(
          section,
          contains("'tenant_id': currentTenantId"),
          reason: 'addSongHistory must set tenant_id in insert data',
        );
      });
    });

    group('Summary Statistics', () {
      test('high tenantId filter coverage for songs table', () {
        final allSongQueries = RegExp(
          r"\.from\('songs'\)",
        ).allMatches(songRepoSource).length;

        final withTenantFilter = RegExp(
          r"\.from\('songs'\)[^;]*\.eq\('tenantId',\s*currentTenantId\)",
          multiLine: true,
        ).allMatches(songRepoSource).length;

        final insertWithTenant = songRepoSource.contains("data['tenantId'] = currentTenantId")
            ? 1
            : 0;

        final totalCovered = withTenantFilter + insertWithTenant;

        // ignore: avoid_print
        print('Songs queries: $allSongQueries');
        // ignore: avoid_print
        print('With tenantId filter: $withTenantFilter');
        // ignore: avoid_print
        print('Insert with tenant: $insertWithTenant');
        // ignore: avoid_print
        print('Total covered: $totalCovered');

        final coverage = totalCovered / allSongQueries;
        expect(
          coverage,
          greaterThanOrEqualTo(0.8),
          reason: 'Expected at least 80% tenantId coverage for songs, got ${(coverage * 100).toStringAsFixed(1)}%',
        );
      });

      test('high tenant_id filter coverage for song_history table', () {
        final allHistoryQueries = RegExp(
          r"\.from\('song_history'\)",
        ).allMatches(songRepoSource).length;

        final withTenantFilter = RegExp(
          r"\.from\('song_history'\)[^;]*\.eq\('tenant_id',\s*currentTenantId\)",
          multiLine: true,
        ).allMatches(songRepoSource).length;

        final insertWithTenant = RegExp(
          r"'tenant_id':\s*currentTenantId",
        ).allMatches(songRepoSource).length;

        final totalCovered = withTenantFilter + insertWithTenant;

        // ignore: avoid_print
        print('Song history queries: $allHistoryQueries');
        // ignore: avoid_print
        print('With tenant_id filter: $withTenantFilter');
        // ignore: avoid_print
        print('Insert with tenant: $insertWithTenant');
        // ignore: avoid_print
        print('Total covered: $totalCovered');

        // song_history has 2 queries (1 select, 1 insert)
        // Both should be covered
        expect(
          totalCovered,
          greaterThanOrEqualTo(allHistoryQueries),
          reason: 'All song_history queries should have tenant_id filter',
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
