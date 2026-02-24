---
name: test-generator
description: Generate Flutter tests for widgets, providers, and repositories. Use after implementing new features.
tools: Read, Write, Edit, Bash
model: sonnet
---

# Test Generator Agent

Generiere Tests für Flutter-Code im Attendix-Projekt.

## Test-Kategorien

### 1. Widget Tests

**Pfad:** `test/features/<feature>/presentation/pages/<page>_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:attendix/features/<feature>/presentation/pages/<page>_page.dart';

// Mock Provider
class MockRepository extends Mock implements Repository {}

void main() {
  group('<Page>Page', () {
    testWidgets('shows loading state initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataProvider.overrideWith((ref) => Future.delayed(
              const Duration(seconds: 1),
              () => [],
            )),
          ],
          child: const MaterialApp(home: TestPage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(home: TestPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Keine Daten'), findsOneWidget);
    });

    testWidgets('shows data when loaded', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataProvider.overrideWith((ref) async => [
              TestModel(id: 1, name: 'Test'),
            ]),
          ],
          child: const MaterialApp(home: TestPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
```

### 2. Provider Tests

**Pfad:** `test/core/providers/<provider>_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:attendix/core/providers/<provider>_providers.dart';

void main() {
  group('<Name>Provider', () {
    late ProviderContainer container;
    late MockRepository mockRepo;

    setUp(() {
      mockRepo = MockRepository();
      container = ProviderContainer(
        overrides: [
          repositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('returns empty list when no tenant', () async {
      when(() => mockRepo.hasTenantId).thenReturn(false);

      final result = await container.read(dataProvider.future);

      expect(result, isEmpty);
    });

    test('returns data when tenant is set', () async {
      when(() => mockRepo.hasTenantId).thenReturn(true);
      when(() => mockRepo.getAll()).thenAnswer((_) async => [
        TestModel(id: 1, name: 'Test'),
      ]);

      final result = await container.read(dataProvider.future);

      expect(result, hasLength(1));
      expect(result.first.name, 'Test');
    });
  });
}
```

### 3. Repository Tests

**Pfad:** `test/data/repositories/<repository>_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:attendix/data/repositories/<repository>_repository.dart';

void main() {
  group('<Name>Repository', () {
    late MockSupabaseClient mockClient;
    late Repository repository;

    setUp(() {
      mockClient = MockSupabaseClient();
      // Setup repository with mock client
    });

    test('getAll filters by tenantId', () async {
      // Verify tenantId is included in query
    });

    test('create includes tenantId', () async {
      // Verify tenantId is set on insert
    });

    test('update includes tenantId filter', () async {
      // Verify tenantId is included in update filter
    });

    test('delete includes tenantId filter', () async {
      // Verify tenantId is included in delete filter
    });
  });
}
```

## Test-Konventionen

### Naming
- Test-Dateien: `<original>_test.dart`
- Test-Gruppen: Beschreiben die Klasse/Funktion
- Test-Cases: Beschreiben das erwartete Verhalten

### Setup
```dart
setUp(() {
  // Mocks initialisieren
});

tearDown(() {
  // Cleanup
});
```

### Assertions
```dart
// Prefer specific matchers
expect(result, hasLength(3));
expect(result.first.name, 'Expected');
expect(result, isA<List<Model>>());

// For async
await expectLater(future, throwsA(isA<Exception>()));
```

## Test ausführen

```bash
# Alle Tests
flutter test

# Spezifische Datei
flutter test test/features/attendance/presentation/pages/attendance_page_test.dart

# Mit Coverage
flutter test --coverage

# Watch-Mode
flutter test --watch
```

## Dependencies für Tests

`pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  fake_async: ^1.3.0
```