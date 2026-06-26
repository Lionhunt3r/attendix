import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression test: ensure planning_page never reintroduces a direct
/// supabase bypass or unsafe tenant-id force-unwrap.
void main() {
  test('planning_page does not use supabaseClientProvider directly', () {
    final source = File(
      'lib/features/planning/presentation/pages/planning_page.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('supabaseClientProvider')));
    expect(source, isNot(contains('tenant.id!')));
    expect(source, isNot(contains('tenant!.id!')));
  });
}
