# Test-Infrastruktur Gesamtplan - Attendix Flutter

> **Persistenter Plan** - Dieser Plan wird in `.claude/test-infrastructure-plan.md` gespeichert und dient als Roadmap für den schrittweisen Ausbau der Test-Infrastruktur. Fortschritt wird hier getrackt.

## Context

**Problem:** Die Attendix Flutter PWA hat aktuell nur Unit-Tests und Source-Code-Analyse für Multi-Tenant-Security. Für Regressionssicherheit und Refactoring-Vertrauen (z.B. Ionic→Flutter Migration) fehlen Widget-Tests, Integration-Tests und E2E-Tests.

**Ziel:** Umfassende Test-Infrastruktur aufbauen, die:
- Kritische Business-Logik absichert (Attendance-Erfassung, Multi-Tenant)
- Vertrauen bei Refactorings gibt
- Cross-Platform läuft (Web, iOS, Android)
- Mit lokalem Supabase (Docker) isoliert testbar ist

## Fortschritt

| Phase | Status | Letzte Aktualisierung |
|-------|--------|----------------------|
| Phase 1: Foundation | ✅ Abgeschlossen | 2026-02-25 |
| Phase 2: Widget Tests | ✅ Abgeschlossen | 2026-02-25 |
| Phase 3: Local Supabase | ⏳ Nicht gestartet | - |
| Phase 4: Integration Framework | ⏳ Nicht gestartet | - |
| Phase 5: Critical Flows | ⏳ Nicht gestartet | - |
| Phase 6: CI/CD | ⏳ Nicht gestartet | - |
| Phase 7: Advanced | ⏳ Optional | - |

---

## Aktueller Stand

| Bereich | Status |
|---------|--------|
| Unit Tests | ✅ Vorhanden (Factories, Mocks, Helpers) |
| Security Tests | ✅ Source-Code-Analyse für tenantId |
| Widget Tests | ✅ 129 Tests (Display, Animation, Skeleton, Sheets, Layout) |
| Integration Tests | ❌ Nicht vorhanden |
| E2E Tests | ❌ Nicht vorhanden |
| CI/CD | ✅ GitHub Actions (analyze + unit test) |

**Existierende Infrastruktur:**
- `test/factories/test_factories.dart` - Person, Tenant, Attendance, Group
- `test/mocks/repository_mocks.dart` - MockPlayerRepository etc.
- `test/mocks/supabase_mocks.dart` - MockSupabaseClient
- `test/helpers/test_helpers.dart` - createTestContainer, Matchers

---

## Framework-Entscheidung: `integration_test`

Nach Analyse von `integration_test`, Patrol und Maestro empfehle ich **Flutter's `integration_test`** als Basis:

| Kriterium | integration_test | Patrol | Maestro |
|-----------|------------------|--------|---------|
| Dart-native | ✅ 100% | ✅ Ja | ❌ YAML |
| Reuse bestehender Mocks | ✅ Direkt | ⚠️ Eingeschränkt | ❌ Nein |
| Provider-Zugriff | ✅ Riverpod-State prüfbar | ⚠️ Limitiert | ❌ Nur UI |
| CI-Integration | ✅ Einfach | ⚠️ Komplex | ⚠️ Komplex |
| Native OS-Tests | ❌ Nein | ✅ Ja | ✅ Ja |

**Empfehlung:** Start mit `integration_test`, Patrol später bei Bedarf für native OS-Interaktionen.

---

## Architektur

```
attendix/
├── test/                           # Unit Tests (existiert)
│   ├── mocks/
│   ├── factories/
│   ├── helpers/
│   ├── core/
│   ├── data/
│   └── features/
│
├── integration_test/               # NEU: E2E Tests
│   ├── app_test.dart              # Haupt-Entry-Point
│   ├── config/
│   │   ├── test_config.dart       # Supabase URLs, Timeouts
│   │   └── test_users.dart        # Test-Accounts
│   ├── helpers/
│   │   ├── app_launcher.dart      # App-Start mit Test-Config
│   │   ├── auth_robot.dart        # Login/Logout Automation
│   │   ├── navigation_robot.dart  # Tab-Navigation
│   │   └── wait_helpers.dart      # Async-Waits
│   ├── flows/
│   │   ├── auth_flow_test.dart
│   │   ├── attendance_flow_test.dart
│   │   ├── player_management_flow_test.dart
│   │   └── tenant_switch_flow_test.dart
│   └── pages/                     # Page Object Pattern
│       ├── login_page.dart
│       ├── home_page.dart
│       ├── attendance_page.dart
│       └── players_page.dart
│
├── test_driver/                   # NEU: Web-Driver
│   └── integration_test.dart
│
└── supabase/                      # NEU: Local Backend
    ├── docker-compose.yml
    ├── seed.sql                   # Test-Daten
    └── config.toml
```

---

## Implementierungsplan

### Phase 1: Foundation (Unit Test Coverage)
**Ziel:** Solide Unit-Test-Basis vervollständigen

- [x] **1.1** Widget Test Infrastructure Setup (`test/helpers/widget_test_helpers.dart`)
- [x] **1.2** Repository Tests vervollständigen (attendance_type, teacher hinzugefügt)
- [x] **1.3** Provider Tests erweitern (attendance_providers, group_providers)
- [ ] **1.4** Golden Tests Setup (optional, `test/golden/`)

**Kritische Dateien:**
- `lib/data/repositories/attendance_repository.dart` - 15 Methoden
- `lib/core/providers/attendance_providers.dart` - Kernlogik
- `lib/features/attendance/presentation/pages/` - Haupt-UI

### Phase 2: Widget Tests
**Ziel:** Isolierte UI-Komponenten testen

- [x] **2.1** Shared Widgets testen (Avatar, AnimatedListItem, TapScale)
- [x] **2.2** Animation-Widgets testen (FadeIn, SlideUp)
- [x] **2.3** Skeleton/Loading Widgets testen (SkeletonBase, SkeletonAvatar, SkeletonText, SkeletonListTile, SkeletonCard)
- [x] **2.4** Sheet Widgets testen (VersionHistorySheet)
- [x] **2.5** Layout Widgets testen (MainShell mit role-based navigation)

**Patterns zu verwenden:**
```dart
// Widget Test mit Riverpod
testWidgets('AttendanceStatusChip shows correct color', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...],
      child: MaterialApp(home: AttendanceStatusChip(status: AttendanceStatus.present)),
    ),
  );
  expect(find.byType(Chip), findsOneWidget);
});
```

### Phase 3: Local Supabase Setup
**Ziel:** Isolierte Backend-Umgebung für E2E

- [ ] **3.1** Docker Compose für Supabase erstellen (`supabase/docker-compose.yml`)
- [ ] **3.2** Seed-Daten für Tests (`supabase/seed.sql`)
- [ ] **3.3** Test-Konfiguration (`.env.test`)
- [ ] **3.4** CI-Integration (GitHub Actions Service Container)

**docker-compose.yml Struktur:**
```yaml
services:
  db:
    image: supabase/postgres:15.1.0.147
    ports: ["54322:5432"]

  studio:
    image: supabase/studio:20240101
    ports: ["54323:3000"]

  kong:
    image: kong:2.8.1
    ports: ["54321:8000"]
```

### Phase 4: Integration Test Framework
**Ziel:** E2E-Grundstruktur aufbauen

- [ ] **4.1** `integration_test` Dependency hinzufügen
- [ ] **4.2** App Launcher Helper (Test-Config injection)
- [ ] **4.3** Robot Pattern implementieren (AuthRobot, NavigationRobot)
- [ ] **4.4** Page Objects erstellen (LoginPage, HomePage, etc.)
- [ ] **4.5** Web Driver Setup (`test_driver/integration_test.dart`)

**Robot Pattern Beispiel:**
```dart
class AuthRobot {
  final WidgetTester tester;
  AuthRobot(this.tester);

  Future<void> login({required String email, required String password}) async {
    await tester.enterText(find.byKey(Key('email_field')), email);
    await tester.enterText(find.byKey(Key('password_field')), password);
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();
  }
}
```

### Phase 5: Critical Flow Tests
**Ziel:** Wichtigste User Journeys absichern

- [ ] **5.1** Auth Flow (P0): Login → Tenant-Auswahl → Home
- [ ] **5.2** Attendance Flow (P0): Erstellen → Erfassen → Speichern
- [ ] **5.3** Multi-Tenant Security (P0): Cross-Tenant Access verhindern
- [ ] **5.4** Player Management (P1): Hinzufügen → Bearbeiten → Archivieren
- [ ] **5.5** Tenant Switch (P1): Wechseln → Daten-Isolation prüfen

### Phase 6: CI/CD Integration
**Ziel:** Automatisierte Tests auf allen Plattformen

- [ ] **6.1** Unit Tests erweitern (Coverage-Threshold)
- [ ] **6.2** Widget Tests Job hinzufügen
- [ ] **6.3** E2E Web Tests (ChromeDriver + Local Supabase)
- [ ] **6.4** E2E iOS Tests (macOS Runner + Simulator)
- [ ] **6.5** E2E Android Tests (Ubuntu + Emulator)
- [ ] **6.6** Coverage Reporting mit Thresholds

**CI Workflow Struktur:**
```yaml
jobs:
  unit-tests:
    runs-on: ubuntu-latest

  widget-tests:
    runs-on: ubuntu-latest

  e2e-web:
    runs-on: ubuntu-latest
    services:
      supabase: ...

  e2e-ios:
    runs-on: macos-latest

  e2e-android:
    runs-on: ubuntu-latest
```

### Phase 7: Advanced Testing (Optional)
**Ziel:** Zusätzliche Qualitätssicherung

- [ ] **7.1** Golden Tests (Visual Regression)
- [ ] **7.2** Performance Tests (Startup-Zeit, Scrolling)
- [ ] **7.3** Accessibility Tests (Semantics)
- [ ] **7.4** Patrol Integration (native OS-Interaktionen)

---

## Session Log

| Datum | Session | Fortschritt |
|-------|---------|-------------|
| 2026-02-25 | Initial | Plan erstellt, Framework-Entscheidung: `integration_test` |
| 2026-02-25 | Phase 1 | ✅ Abgeschlossen: Widget Test Helpers, Repository Tests (7 Repos), Provider Tests (3 Providers), 239 Tests total |
| 2026-02-25 | Phase 2 | ✅ Abgeschlossen: Avatar (15), Animation (22), Skeleton (25), VersionHistorySheet (6), MainShell (8), total 315 Tests |

---

## Nächste Session

**Starte mit:** Phase 3, Task 3.1 - Docker Compose für Supabase erstellen

**Kommando zum Fortsetzen:**
```
Lies .claude/test-infrastructure-plan.md und fahre mit der nächsten offenen Task fort.
```

---

## Abhängigkeiten hinzuzufügen

```yaml
# pubspec.yaml - dev_dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.4
  golden_toolkit: ^0.15.0  # Optional: Golden Tests
```

---

## Zeitschätzung

| Phase | Geschätzter Aufwand |
|-------|---------------------|
| Phase 1: Foundation | 2-3 Tage |
| Phase 2: Widget Tests | 3-4 Tage |
| Phase 3: Local Supabase | 1-2 Tage |
| Phase 4: Integration Framework | 2-3 Tage |
| Phase 5: Critical Flows | 3-4 Tage |
| Phase 6: CI/CD | 1-2 Tage |
| Phase 7: Advanced | Optional |
| **Gesamt** | **~2-3 Wochen** |

---

## Verification

Nach Implementierung jeder Phase:

1. **Unit Tests:** `flutter test`
2. **Widget Tests:** `flutter test test/widgets/`
3. **E2E Lokal:** `flutter test integration_test/`
4. **E2E Web:** `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome`
5. **CI:** GitHub Actions Workflow muss grün sein
6. **Coverage:** `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`

---

## Nächste Schritte nach Approval

1. Phase 1 starten: Unit Test Foundation erweitern
2. Parallel: Docker Supabase Setup vorbereiten
3. Iterativ weitere Phasen umsetzen
