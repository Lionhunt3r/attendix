---
name: test-generator
description: Generate Flutter tests for widgets, providers, and repositories. Use after implementing new features.
tools: Read, Write, Edit, Bash
model: sonnet
---

# Test Generator Agent

Generiere Tests für Flutter-Code im Attendix-Projekt.

## Test-Infrastruktur

Das Projekt hat eine etablierte Test-Infrastruktur:

```
test/
├── mocks/                    # Mock-Klassen
│   ├── supabase_mocks.dart   # SupabaseClient Mocks
│   └── repository_mocks.dart # Repository Mocks (mocktail)
├── factories/                # Test-Daten Factories
│   └── test_factories.dart   # Person, Tenant, Attendance, etc.
├── helpers/                  # Test-Utilities
│   └── test_helpers.dart     # Container Setup, Matchers
├── core/providers/           # Provider Tests
├── data/repositories/        # Repository Security Tests
└── features/                 # Feature/Widget Tests
```

## Test-Kategorien

### 1. Repository Security Tests (KRITISCH)

**Pfad:** `test/data/repositories/<repository>_test.dart`

**Ansatz:** Source-Code-Analyse für robuste Security-Tests:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String repoSource;

  setUpAll(() {
    final file = File('lib/data/repositories/<repository>_repository.dart');
    repoSource = file.readAsStringSync();
  });

  group('Multi-Tenant Security - <Repository>', () {
    test('all UPDATE operations include tenantId filter', () {
      final updateQueries = RegExp(
        r"supabase[^;]*\.from\('<table>'\)[^;]*\.update\([^;]+",
        multiLine: true,
      ).allMatches(repoSource);

      expect(updateQueries, isNotEmpty);

      for (final match in updateQueries) {
        final query = match.group(0)!;
        expect(
          query,
          contains(".eq('tenantId', currentTenantId)"),
          reason: 'UPDATE query missing tenantId filter',
        );
      }
    });

    test('all DELETE operations include tenantId filter', () {
      final deleteQueries = RegExp(
        r"supabase[^;]*\.from\('<table>'\)[^;]*\.delete\(\)[^;]+",
        multiLine: true,
      ).allMatches(repoSource);

      for (final match in deleteQueries) {
        expect(match.group(0), contains(".eq('tenantId', currentTenantId)"));
      }
    });

    test('INSERT sets tenantId in data', () {
      expect(repoSource, contains("data['tenantId'] = currentTenantId"));
    });
  });
}
```

### 2. Provider Tests

**Pfad:** `test/core/providers/<provider>_providers_test.dart`

**Nutze Test-Infrastruktur:**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String providerSource;

  setUpAll(() {
    final file = File('lib/core/providers/<name>_providers.dart');
    providerSource = file.readAsStringSync();
  });

  group('<Name> Providers', () {
    group('Tenant Guard Pattern', () {
      test('returns empty when no tenant', () {
        expect(providerSource, contains('if (!repo.hasTenantId) return [];'));
      });
    });

    group('Cache Invalidation', () {
      test('create invalidates list provider', () {
        expect(providerSource, contains('ref.invalidate(<list>Provider)'));
      });
    });

    group('Repository Integration', () {
      test('sets tenantId from currentTenantIdProvider', () {
        expect(providerSource, contains('ref.watch(currentTenantIdProvider)'));
        expect(providerSource, contains('repo.setTenantId('));
      });
    });
  });
}
```

### 3. Widget Tests

**Pfad:** `test/features/<feature>/presentation/pages/<page>_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../factories/test_factories.dart';
import '../../helpers/test_helpers.dart';
import '../../mocks/repository_mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValues();
  });

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

    testWidgets('shows data when loaded', (tester) async {
      final testData = TestFactories.createPersonList(3);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dataProvider.overrideWith((ref) async => testData),
          ],
          child: const MaterialApp(home: TestPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Person 1'), findsOneWidget);
    });
  });
}
```

## Test-Factories nutzen

```dart
import 'package:attendix/test/factories/test_factories.dart';

// Einzelne Person
final person = TestFactories.createPerson(
  id: 1,
  firstName: 'Alice',
  tenantId: 42,
);

// Liste
final persons = TestFactories.createPersonList(10, tenantId: 42);

// Spezielle Varianten
final conductor = TestFactories.createConductor(mainGroupId: 1);
final archived = TestFactories.createArchivedPerson();
final paused = TestFactories.createPausedPerson(pausedUntil: '2024-12-31');
final pending = TestFactories.createPendingPerson();

// Andere Models
final tenant = TestFactories.createTenant(id: 42, shortName: 'Test');
final attendance = TestFactories.createAttendance(date: '2024-01-15', tenantId: 42);
final group = TestFactories.createGroup(name: 'Violine 1', tenantId: 42);

// JSON für Mocks
final personJson = person.toTestJson();
final personListJson = TestFactories.personsToJson(persons);
```

## Repository Mocks nutzen

```dart
import 'package:attendix/test/mocks/repository_mocks.dart';

setUpAll(() {
  registerFallbackValues(); // WICHTIG für mocktail
});

test('example', () async {
  final mockRepo = MockPlayerRepository();
  setupMockPlayerRepository(mockRepo, tenantId: 42);
  mockGetPlayers(mockRepo, testPlayers);

  // Test...
  verify(() => mockRepo.getPlayers()).called(1);
});
```

## Test-Konventionen

### Naming
- Test-Dateien: `<original>_test.dart`
- Test-Gruppen: Beschreiben die Klasse/Funktion
- Test-Cases: Beschreiben das erwartete Verhalten

### Security Test Pattern
```dart
// Immer verifizieren:
// 1. SELECT hat tenantId Filter
// 2. UPDATE hat id UND tenantId Filter
// 3. DELETE hat id UND tenantId Filter
// 4. INSERT setzt tenantId im Daten-Objekt
```

## Tests ausführen

```bash
# Alle Tests
flutter test

# Spezifische Datei
flutter test test/data/repositories/player_repository_test.dart

# Security Tests
flutter test --name "Multi-Tenant Security"

# Mit Coverage
flutter test --coverage

# Watch-Mode (nicht auf CI)
flutter test --watch
```

## CI-Integration

Tests laufen automatisch via `.github/workflows/ci.yml`:
- Push auf `master` oder `develop`
- Pull Requests auf `master`
- Vor Deployment auf Cloudflare Pages
