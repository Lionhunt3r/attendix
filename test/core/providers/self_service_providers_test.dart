import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('self_service_providers does not use supabaseClientProvider directly',
      () {
    final source = File(
      'lib/core/providers/self_service_providers.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('supabaseClientProvider')));
  });
}
