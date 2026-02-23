# Attendix - Claude Instructions

## Projekt-Übersicht

- **App:** Flutter PWA für Anwesenheits-Tracking (Orchester, Chöre, Gruppen)
- **Migriert von:** Ionic/Angular → Flutter-native Patterns bevorzugen
- **Backend:** Supabase (Auth, Database, Realtime)
- **State Management:** Riverpod
- **Routing:** go_router
- **Models:** Freezed (immutable)

## Architektur

```
lib/
├── core/           # Shared: providers, router, theme, utils
├── data/           # Models (Freezed) + Repositories (Supabase)
├── features/       # Feature-Module: presentation/pages/
└── shared/         # Wiederverwendbare Widgets
```

## Kritische Regeln

### 1. Multi-Tenant - IMMER tenantId filtern!

```dart
// ✅ Richtig
.eq('tenantId', currentTenantId)

// ❌ Falsch - Sicherheitslücke!
.select('*')  // ohne tenantId Filter
```

### 2. Riverpod Namenskonventionen

```dart
// Daten laden
final playersProvider = FutureProvider<List<Person>>((ref) {...});

// Mit Parameter
final playerByIdProvider = FutureProvider.family<Person?, int>((ref, id) {...});

// Mutations
final attendanceNotifierProvider = NotifierProvider<AttendanceNotifier, AsyncValue<void>>(...);

// Repository mit Tenant
final playerRepositoryWithTenantProvider = Provider<PlayerRepository>((ref) {...});
```

### 3. Freezed - Nach Model-Änderungen

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. UI-Labels auf Deutsch

Anwesenheitsstatus: `Anwesend`, `Abwesend`, `Entschuldigt`, `Verspätet`

### 5. PWA-Kompatibilität

Native APIs (Haptics etc.) immer in try-catch wrappen.

## Wichtige Dateien

| Bereich | Pfad |
|---------|------|
| Providers | `lib/core/providers/*.dart` |
| Repositories | `lib/data/repositories/*.dart` |
| Enums | `lib/core/constants/*.dart` |
| Router | `lib/core/router/app_router.dart` |
| Theme | `lib/core/theme/` |

## Befehle

```bash
# Freezed/JSON generieren
dart run build_runner build --delete-conflicting-outputs

# Code analysieren
dart analyze lib/

# Tests ausführen
flutter test

# PWA starten
flutter run -d chrome
```

## Vor dem Commit/Push

**WICHTIG:** Bei Feature-Änderungen immer Version und History aktualisieren!

1. **Version erhöhen** in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+1  # Format: major.minor.patch+build
   ```

2. **History aktualisieren** in `assets/version_history.json`:
   ```json
   {
     "version": "1.0.0",
     "date": "23.2.2026",
     "changes": [
       "✨ Neue Feature-Beschreibung",
       "🐛 Bug-Fix Beschreibung"
     ]
   }
   ```

3. **App-Version Badge aktualisieren** in `lib/core/constants/app_constants.dart`:
   ```dart
   static const String appVersion = '1.0.0';
   ```

Dies sorgt dafür, dass Benutzer in der App sehen, dass es eine neue Version gibt.

## Rollen-System

- **Dirigent (conductor):** Vollzugriff
- **Helfer (helper):** Eingeschränkt
- **Spieler (player):** Nur eigene Daten

Prüfung via `role.isConductor`, `role.canSeePeopleTab`, etc.

## App auf Geräte deployen

### iPhone (iOS)

```bash
# 1. Release-Build erstellen
flutter build ios --release

# 2. Auf iPhone installieren und starten (Device-ID anpassen)
xcrun devicectl device install app --device 00008120-000C4D5C0205A01E build/ios/iphoneos/Runner.app
xcrun devicectl device process launch --device 00008120-000C4D5C0205A01E de.attendix.attendix
```

**Voraussetzungen:**
- iPhone per USB verbunden
- Entwicklermodus auf iPhone aktiviert (Einstellungen → Datenschutz & Sicherheit → Entwicklermodus)
- Code Signing in Xcode konfiguriert (Team ausgewählt)
- Beim ersten Mal: Zertifikat auf iPhone vertrauen (Einstellungen → Allgemein → VPN & Geräteverwaltung)

**Wichtig:** Debug-Builds funktionieren nur über Flutter CLI oder Xcode direkt. Für standalone: immer `--release` verwenden.

**Device-ID finden:**
```bash
flutter devices
```

### macOS

```bash
# 1. Release-Build erstellen
flutter build macos --release

# 2. In Applications installieren und starten
cp -r build/macos/Build/Products/Release/attendix.app /Applications/
open /Applications/attendix.app
```

**Wichtig:** Die Datei `macos/Runner/Release.entitlements` muss `com.apple.security.network.client` enthalten für Netzwerkzugriff:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

## Weiterführende Dokumentation

Für ausführliche Patterns, Ionic→Flutter Mappings und Code-Beispiele:
→ [.github/copilot-instructions.md](.github/copilot-instructions.md)
