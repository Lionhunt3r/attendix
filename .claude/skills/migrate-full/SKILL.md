---
name: migrate-full
description: "Vollständiger Migrations-Workflow von Ionic zu Flutter. Orchestriert Analyse, Planung, Implementierung und Review automatisch."
---

# Full Migration Workflow

Dieser Skill orchestriert den kompletten Migrations-Prozess von Ionic nach Flutter.

## Workflow-Übersicht

```
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 1: ANALYSE (Parallel Agents)                             │
│  ┌─────────────────────┐  ┌─────────────────────┐               │
│  │ migration-analyzer  │  │ Explore Agent       │               │
│  │ (Ionic Features)    │  │ (Flutter Patterns)  │               │
│  └─────────────────────┘  └─────────────────────┘               │
└──────────────────────────────┬──────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 2: PLANUNG                                               │
│  - Feature-Scope definieren                                     │
│  - Dateien identifizieren (Ionic → Flutter Mapping)             │
│  - Tasks in TodoWrite erstellen                                 │
└──────────────────────────────┬──────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 3: IMPLEMENTIERUNG                                       │
│  - Tasks nacheinander abarbeiten                                │
│  - Code nach flutter-reviewer prüfen lassen                     │
│  - Nach jeder Datei: dart analyze                               │
└──────────────────────────────┬──────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  PHASE 4: VERIFICATION & COMMIT                                 │
│  - Finale Prüfung: dart analyze lib/                            │
│  - Optional: test-generator für Tests                           │
│  - Commit erstellen                                             │
│  - migration-status.md aktualisieren                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## Trigger

Dieser Skill wird aktiviert bei:
- "Migriere [Feature] von Ionic zu Flutter"
- "Migration starten für [Feature]"
- "Ionic [Feature] nach Flutter portieren"
- "/migrate-full [Feature]"

---

## Phase 1: Analyse

### Schritt 1.1: Migration-Status prüfen

Lies zuerst `.claude/migration-status.md` um den aktuellen Stand zu kennen.

### Schritt 1.2: Parallele Agents starten

Starte **gleichzeitig** (in einem Tool-Call mit mehreren Task-Invocations):

**Agent 1: migration-analyzer**
```
Analysiere das Ionic-Feature "[FEATURE]" in /Users/I576226/repositories/attendance/src/app/
- Welche Dateien gehören dazu?
- Welche Services werden genutzt?
- Welche Abhängigkeiten bestehen?
```

**Agent 2: Explore (Flutter Patterns)**
```
Finde in /Users/I576226/repositories/attendix/lib/ ähnliche implementierte Features.
- Welche Patterns werden verwendet?
- Gibt es wiederverwendbare Widgets?
- Wie sind ähnliche Pages strukturiert?
```

### Schritt 1.3: Ergebnisse zusammenführen

Erstelle eine Zusammenfassung:
- Ionic-Dateien zu migrieren
- Flutter-Zielstruktur
- Vorhandene Patterns zum Nutzen
- Geschätzte Komplexität

---

## Phase 2: Planung

### Schritt 2.1: Tasks erstellen

Erstelle TodoWrite-Tasks für jeden Schritt:

```
Beispiel für "Meeting Detail":

Task 1: Repository erstellen (falls nötig)
Task 2: Provider erstellen
Task 3: Page-Widget erstellen
Task 4: Route hinzufügen
Task 5: dart analyze ausführen
Task 6: Manuell testen
Task 7: Commit erstellen
```

### Schritt 2.2: Benutzer-Bestätigung

Zeige dem Benutzer:
1. Geplante Tasks
2. Geschätzte Komplexität
3. Zu erstellende Dateien

Frage: "Soll ich mit der Migration beginnen?"

---

## Phase 3: Implementierung

### Für jeden Task:

1. **Task als in_progress markieren**

2. **Ionic-Code lesen**
   - Verstehe die Logik
   - Identifiziere Supabase-Aufrufe
   - Notiere UI-Elemente

3. **Flutter-Code schreiben**
   - Nutze SKILL `ionic-migrate` für Pattern-Mapping
   - **KRITISCH:** Immer `.eq('tenantId', currentTenantId)`
   - Deutsche Labels verwenden

4. **Prüfen**
   ```bash
   dart analyze lib/features/[feature]/
   ```

5. **Task als completed markieren**

### Nach jedem größeren Abschnitt:

Starte `flutter-reviewer` Agent:
```
Prüfe die neu erstellten Dateien in lib/features/[feature]/ auf:
- Multi-tenant Security (tenantId)
- Riverpod Patterns
- Flutter Best Practices
```

---

## Phase 4: Verification & Commit

### Schritt 4.1: Finale Prüfung

```bash
dart analyze lib/
```

### Schritt 4.2: Optional - Tests generieren

Frage den Benutzer: "Soll ich Tests generieren?"

Falls ja, starte `test-generator` Agent.

### Schritt 4.3: Commit

```bash
git add lib/
git commit -m "feat: Migrate [FEATURE] from Ionic to Flutter"
```

### Schritt 4.4: Migration-Status aktualisieren

Aktualisiere `.claude/migration-status.md`:
- Feature von "Ausstehend" nach "Vollständig" verschieben
- Datum aktualisieren

### Schritt 4.5: Version aktualisieren (bei größeren Features)

Falls signifikantes Feature:
1. `pubspec.yaml` Version erhöhen
2. `assets/version_history.json` aktualisieren
3. `lib/core/constants/app_constants.dart` Version aktualisieren

---

## Checkliste (automatisch prüfen)

- [ ] Ionic-Quelle vollständig analysiert
- [ ] Flutter-Code erstellt
- [ ] tenantId-Filter in allen Queries
- [ ] Deutsche Labels verwendet
- [ ] Route in `app_router.dart`
- [ ] Provider in `providers.dart` exportiert
- [ ] `dart analyze lib/` ohne Fehler
- [ ] Committed
- [ ] `migration-status.md` aktualisiert

---

## Referenzen

### Ionic Quell-Pfad
`/Users/I576226/repositories/attendance/src/app/`

### Flutter Ziel-Pfad
`/Users/I576226/repositories/attendix/lib/`

### Pattern-Mapping (Quick Reference)

| Ionic | Flutter |
|-------|---------|
| `@Component` | `ConsumerStatefulWidget` |
| `signal<T>()` | `StateProvider<T>` |
| Service-Methode | Repository + Provider |
| `*ngFor` | `ListView.builder()` |
| `async pipe` | `.when()` Pattern |
| Modal | `showModalBottomSheet()` |
| Toast | `ToastHelper.showSuccess()` |
| `context.go('/route')` | `context.go('/route')` |

### Kritische Regeln

1. **IMMER tenantId filtern:**
   ```dart
   .eq('tenantId', currentTenantId)
   ```

2. **Repository mit Tenant nutzen:**
   ```dart
   ref.watch(xxxRepositoryWithTenantProvider)
   ```

3. **Deutsche Labels:**
   - Anwesend, Abwesend, Entschuldigt, Verspätet
   - Speichern, Abbrechen, Löschen

---

## Beispiel-Aufruf

Benutzer: "Migriere das Shifts-Feature von Ionic zu Flutter"

Claude:
1. Startet migration-analyzer + Explore Agent parallel
2. Erstellt Migrations-Plan mit Tasks
3. Fragt: "Soll ich beginnen?"
4. Implementiert Task für Task
5. Ruft flutter-reviewer auf
6. Prüft mit dart analyze
7. Committet
8. Aktualisiert migration-status.md
