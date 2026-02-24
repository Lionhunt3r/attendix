---
name: ionic-migrate
description: Migrate an Ionic/Angular feature to Flutter. Use when converting existing Ionic pages, services, or components to Flutter equivalents.
argument-hint: [feature-name]
---

# Ionic → Flutter Migration

Orchestriert den kompletten Migrations-Prozess von Ionic nach Flutter.

## Workflow

```
PHASE 0: WORKTREE ERSTELLEN (IMMER!)
  • EnterWorktree mit name "migrate-$ARGUMENTS"
  • Isolierte Arbeitsumgebung für die Migration
           ▼
PHASE 1: STATUS AKTUALISIEREN
  • migration-analyzer Agent starten
  • migration-status.md automatisch aktualisieren
  • Aktuellen Stand dem Benutzer zeigen
           ▼
PHASE 2: ANALYSE (Parallel Agents)
  • migration-analyzer (Ionic Feature Details)
  • Explore Agent (Flutter Patterns)
           ▼
PHASE 3: PLANUNG
  • Tasks erstellen (TaskCreate)
  • Benutzer-Bestätigung holen
           ▼
PHASE 4: IMPLEMENTIERUNG
  • Tasks abarbeiten
  • flutter-reviewer Agent nach jedem Abschnitt
           ▼
PHASE 5: VERIFICATION & COMMIT
  • dart analyze lib/
  • flutter-reviewer Agent (PFLICHT!)
  • Kritische Probleme fixen
  • /commit Skill
  • migration-status.md aktualisieren
```

---

## Phase 0: Worktree erstellen (IMMER ZUERST!)

### PFLICHT: EnterWorktree aufrufen

**BEVOR du irgendetwas anderes tust, rufe IMMER `EnterWorktree` auf!**

```
EnterWorktree mit name: "migrate-$ARGUMENTS"
```

Beispiele:
- `/ionic-migrate shifts` → `EnterWorktree(name: "migrate-shifts")`
- `/ionic-migrate handover` → `EnterWorktree(name: "migrate-handover")`

**Warum Worktree?**
- Isolierte Arbeitsumgebung
- Eigener Branch für die Migration
- Paralleles Arbeiten möglich
- Sauberer Merge am Ende

**WICHTIG:** Fahre NICHT mit Phase 1 fort, bis der Worktree erstellt ist!

---

## Phase 1: Status aktualisieren

### Schritt 1.1: migration-analyzer starten

Starte den `migration-analyzer` Agent mit folgendem Prompt:

```
Analysiere den aktuellen Migrations-Stand:
1. Scanne /Users/I576226/repositories/attendance/src/app/ für alle Ionic Features
2. Scanne /Users/I576226/repositories/attendix/lib/features/ für migrierte Flutter Features
3. Vergleiche und aktualisiere /Users/I576226/repositories/attendix/.claude/migration-status.md
4. Gib eine Zusammenfassung: Was ist migriert, was fehlt noch?
```

### Schritt 1.2: Benutzer informieren

Zeige dem Benutzer:
- Aktueller Migrations-Fortschritt (X%)
- Liste der ausstehenden Features
- Empfohlenes nächstes Feature

Falls `$ARGUMENTS` angegeben wurde, prüfe ob es in der Liste ist.
Falls nicht angegeben, frage welches Feature migriert werden soll.

---

## Phase 2: Analyse

### Starte PARALLEL (ein Tool-Call mit mehreren Task-Invocations):

**Agent 1: migration-analyzer**
```
Analysiere das Ionic-Feature "$ARGUMENTS" in /Users/I576226/repositories/attendance/src/app/
- Welche Dateien gehören dazu? (Pages, Services, Components)
- Welche Supabase-Tabellen werden genutzt?
- Welche UI-Elemente sind enthalten?
```

**Agent 2: Explore (Flutter Patterns)**
```
Finde in /Users/I576226/repositories/attendix/lib/ ähnliche implementierte Features.
- Welche Patterns werden verwendet?
- Gibt es wiederverwendbare Widgets in lib/shared/widgets/?
- Wie sind ähnliche Pages strukturiert?
```

### Ergebnisse zusammenführen

Erstelle eine Zusammenfassung:
- Ionic-Dateien zu migrieren
- Flutter-Zielstruktur
- Vorhandene Patterns/Widgets zum Nutzen

---

## Phase 3: Planung

### Tasks erstellen mit TaskCreate

Beispiel für ein typisches Feature:

```
Task 1: Repository erstellen (falls nötig)
Task 2: Provider erstellen
Task 3: Page-Widget erstellen
Task 4: Route in app_router.dart hinzufügen
Task 5: dart analyze ausführen
Task 6: Code Review mit flutter-reviewer
```

### Benutzer-Bestätigung

Zeige dem Benutzer:
1. Geplante Tasks
2. Zu erstellende Dateien
3. Frage: "Soll ich mit der Migration beginnen?"

---

## Phase 4: Implementierung

### Für jeden Task:

1. **Task als in_progress markieren** (TaskUpdate)

2. **Ionic-Code lesen** aus `/Users/I576226/repositories/attendance/src/app/`

3. **Flutter-Code schreiben** mit Pattern-Mapping (siehe unten)

4. **Task als completed markieren**

### Nach Implementierung: Code Review

Starte `flutter-reviewer` Agent:
```
Prüfe die neu erstellten Dateien in lib/features/$ARGUMENTS/ auf:
- Multi-tenant Security (tenantId in allen Queries)
- Riverpod Patterns (Naming, Repository-Zugriff)
- Flutter Best Practices
```

---

## Phase 5: Verification & Commit

### Schritt 5.1: Analyse

```bash
dart analyze lib/
```

### Schritt 5.2: Code Review (PFLICHT!)

Starte den `flutter-reviewer` Agent mit folgendem Prompt:

```
Führe ein vollständiges Code Review durch für die Migration von "$ARGUMENTS":

1. Prüfe ALLE neu erstellten/geänderten Dateien:
   - lib/features/$ARGUMENTS/**
   - lib/data/repositories/*$ARGUMENTS* (falls vorhanden)
   - lib/core/providers/*$ARGUMENTS* (falls vorhanden)

2. Checke diese kritischen Punkte:
   - Multi-tenant Security: tenantId in ALLEN Supabase-Queries?
   - Repository mit Tenant: xxxRepositoryWithTenantProvider verwendet?
   - Riverpod Patterns: Naming korrekt (xxxsProvider, xxxByIdProvider)?
   - Async-Handling: .when() Pattern statt direktem .value?
   - Error Handling: try-catch mit mounted-Check?
   - Deutsche Labels: Alle UI-Texte auf Deutsch?
   - PWA-Kompatibilität: Native APIs in try-catch?

3. Gib einen Review-Report mit:
   - 🔴 Kritische Probleme (müssen gefixt werden)
   - 🟡 Verbesserungsvorschläge
   - 🟢 Was gut gemacht wurde
```

**WICHTIG:** Bei kritischen Problemen (🔴) ERST fixen, dann weiter!

### Schritt 5.3: Optional - Tests

Frage: "Soll ich Tests generieren?"
Falls ja: Starte `test-generator` Agent.

### Schritt 5.4: Commit

Rufe den `/commit` Skill auf mit Message:
```
feat: Migrate $ARGUMENTS from Ionic to Flutter
```

### Schritt 5.5: Migration-Status aktualisieren

Aktualisiere `.claude/migration-status.md`:
- Feature von "Ausstehend" nach "Vollständig migriert" verschieben
- Datum aktualisieren

---

## Pattern-Mapping Referenz

### Ionic → Flutter

| Ionic/Angular | Flutter Equivalent |
|---------------|-------------------|
| `@Component` | `ConsumerStatefulWidget` |
| `ngOnInit()` | `initState()` + Provider |
| `ionViewWillEnter` | `ref.watch()` (auto-refresh) |
| Service-Methode | Repository-Methode + Provider |
| `WritableSignal<T>` | `StateProvider<T>` oder `Notifier<T>` |
| `effect()` | `ref.listen()` |
| `*ngFor` | `ListView.builder()` |
| `async pipe` | `.when()` Pattern |
| Modal | `showModalBottomSheet()` |
| Toast | `ToastHelper.show...()` |
| `this.router.navigate()` | `context.go()` / `context.push()` |

### Provider-Naming

```dart
// Daten laden (Liste)
final ${name}sProvider = FutureProvider<List<$Model>>((ref) {...});

// Mit Parameter
final ${name}ByIdProvider = FutureProvider.family<$Model?, int>((ref, id) {...});

// Mutations
final ${name}NotifierProvider = NotifierProvider<${Name}Notifier, AsyncValue<void>>(...);
```

### Async-Handling

```dart
// RICHTIG - .when() Pattern
dataAsync.when(
  loading: () => const ListSkeleton(),
  error: (e, _) => EmptyStateWidget(icon: Icons.error, title: 'Fehler'),
  data: (items) => ListView.builder(...),
)
```

---

## Kritische Regeln

### 1. Multi-Tenant Security (KRITISCH!)

```dart
// RICHTIG - IMMER tenantId filtern
.eq('tenantId', currentTenantId)

// RICHTIG - Repository mit Tenant nutzen
ref.watch(xxxRepositoryWithTenantProvider)

// FALSCH - Sicherheitslücke!
.select('*')  // ohne tenantId Filter
```

### 2. UI-Labels auf Deutsch

- Anwesend, Abwesend, Entschuldigt, Verspätet
- Speichern, Abbrechen, Löschen
- Fehler beim Laden, Keine Daten gefunden

### 3. PWA-Kompatibilität

```dart
// Native APIs in try-catch wrappen
try {
  await HapticFeedback.lightImpact();
} catch (_) {}
```

---

## Quell- und Ziel-Pfade

| Typ | Pfad |
|-----|------|
| **Ionic Quelle** | `/Users/I576226/repositories/attendance/src/app/` |
| **Flutter Ziel** | `/Users/I576226/repositories/attendix/lib/` |
| **Migration Status** | `/Users/I576226/repositories/attendix/.claude/migration-status.md` |

### Flutter-Struktur

```
lib/features/$ARGUMENTS/
├── presentation/
│   ├── pages/
│   │   └── ${name}_page.dart
│   └── widgets/
│       └── (custom widgets)
```

Bei Bedarf auch:
- `lib/data/models/<name>/` - Freezed Model
- `lib/data/repositories/<name>_repository.dart` - Repository
- `lib/core/providers/<name>_providers.dart` - Providers

---

## Shared Widgets (wiederverwenden!)

Aus `lib/shared/widgets/`:
- `ListSkeleton` - Loading State
- `EmptyStateWidget` - Leere Liste
- `Avatar` - Profilbild mit Fallback
- `StatusBadge` - Anwesenheitsstatus
- `AnimatedListItem` - List-Animationen

---

## Checkliste

- [ ] **Worktree erstellt (PFLICHT - Phase 0)**
- [ ] Migration-Status aktualisiert (Phase 1)
- [ ] Ionic-Quelle analysiert (migration-analyzer)
- [ ] Flutter-Patterns gefunden (Explore)
- [ ] Tasks erstellt und bestätigt
- [ ] Flutter-Code erstellt
- [ ] tenantId-Filter in allen Queries (KRITISCH!)
- [ ] Deutsche Labels verwendet
- [ ] Route in `app_router.dart`
- [ ] Provider in `providers.dart` exportiert
- [ ] `dart analyze lib/` ohne Fehler
- [ ] **Code Review mit flutter-reviewer (PFLICHT!)**
- [ ] Kritische Probleme gefixt
- [ ] Committed
- [ ] `migration-status.md` aktualisiert
