import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Tests for UsageEventsRepository
///
/// `usage_events` is tenant-anonymous (no security boundary on tenant_id),
/// insert-only, and readable only by `developer@attendix.de` per RLS.
/// We verify the repo:
///   - calls `from('usage_events').insert(...)` with the model JSON
///   - does NOT extend TenantAwareRepository
///   - is INSERT-only (no select/update/delete)
void main() {
  late String repoSource;

  setUpAll(() {
    final file = File('lib/data/repositories/usage_events_repository.dart');
    repoSource = file.readAsStringSync();
  });

  group('UsageEventsRepository', () {
    test('inserts into the usage_events table', () {
      expect(
        repoSource,
        contains("from('usage_events')"),
        reason: 'Must target the usage_events table',
      );
      expect(
        repoSource,
        contains('.insert('),
        reason: 'Must call .insert(...)',
      );
    });

    test('writes the model JSON via toJson()', () {
      // The Freezed model serializes the snake_case keys; insert payload must use it.
      expect(
        repoSource,
        contains('event.toJson()'),
        reason: 'Insert payload must be event.toJson() to match snake_case schema',
      );
    });

    test('is tenant-anonymous (does NOT extend TenantAwareRepository)', () {
      expect(
        repoSource,
        isNot(contains('TenantAwareRepository')),
        reason: 'usage_events is anonymous; must not be TenantAware',
      );
      expect(
        repoSource,
        isNot(contains(".eq('tenantId'")),
        reason: 'No tenantId filter on usage_events',
      );
    });

    test('is insert-only (no select/update/delete on usage_events)', () {
      // Allow .insert(...) but no other write/read ops on this table.
      expect(
        repoSource,
        isNot(matches(RegExp(r"from\('usage_events'\)[^;]*\.select\("))),
        reason: 'usage_events is insert-only',
      );
      expect(
        repoSource,
        isNot(matches(RegExp(r"from\('usage_events'\)[^;]*\.update\("))),
        reason: 'usage_events is insert-only',
      );
      expect(
        repoSource,
        isNot(matches(RegExp(r"from\('usage_events'\)[^;]*\.delete\("))),
        reason: 'usage_events is insert-only',
      );
    });

    test('exposes a Riverpod Provider', () {
      expect(
        repoSource,
        contains('usageEventsRepositoryProvider'),
        reason: 'Must expose a Provider for DI',
      );
      expect(
        repoSource,
        contains('UsageEventsRepository.new'),
        reason: 'Provider should use the .new tearoff',
      );
    });
  });
}
