import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('members_providers uses repositories, not supabaseClientProvider', () {
    final source = File(
      'lib/features/members/data/providers/members_providers.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('supabaseClientProvider')),
        reason: 'Repository-bypass forbidden in members_providers');
    expect(source, isNot(contains('tenant.id!')),
        reason: 'Force-unwrap on tenant.id! forbidden');
    expect(source, contains('RepositoryWithTenantProvider'),
        reason: 'Must use a *WithTenantProvider');
  });
}
