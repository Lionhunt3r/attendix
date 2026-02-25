---
name: fix-issues
description: Systematically fix multiple GitHub issues with parallel analysis and sequential TDD fixes. Use for batch bug-fixing sessions.
argument-hint: [--priority critical|high|medium|low] [#1 #2 #3...]
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, EnterWorktree, TaskCreate, TaskUpdate, TaskList, TaskGet, AskUserQuestion
---

# Fix Issues - Batch Bug-Fixing Workflow

Systematischer Workflow zur Behebung mehrerer GitHub Issues mit paralleler Analyse und sequentiellen TDD-Fixes.

**Arguments:** $ARGUMENTS

---

## PHASE 0: SETUP

### 0.1 Worktree erstellen (PFLICHT!)

**IMMER zuerst ausführen - ein Worktree für ALLE Bugs!**

```
EnterWorktree(name: "fix-issues-YYYYMMDD")
```

Verwende das aktuelle Datum (z.B. "fix-issues-20260224").

### 0.2 GitHub Issues laden

```bash
# Alle Bug-Issues laden
gh issue list --label "bug" --state open --json number,title,labels,body --limit 50

# Oder mit Priority-Filter
gh issue list --label "bug" --label "priority: critical" --state open --json number,title,labels,body
```

### 0.3 Baseline-Tests verifizieren

```bash
flutter test
```

- Tests MÜSSEN grün sein bevor du startest
- Falls Tests fehlschlagen: **STOPP** und User informieren

---

## PHASE 1: TRIAGE

### 1.1 Priority-Sortierung

| Label | Reihenfolge | Beispiel |
|-------|-------------|----------|
| `priority: critical` | 1 | Security-Bugs, Crashes |
| `priority: high` | 2 | Feature broken |
| `priority: medium` | 3 | Edge Cases, UX |
| `priority: low` | 4 | Code-Qualität |

### 1.2 Duplikat-Erkennung

Prüfe `.claude/bug-report.md` auf bereits dokumentierte Duplikate:
- Gleiche Datei + gleiche Zeile = Duplikat
- Ähnliches Problem = zusammen fixen

### 1.3 Gruppierung

Bugs in der **gleichen Datei** sollten zusammen gefixt werden:
- Reduziert Commits
- Vermeidet Merge-Konflikte
- Effizientere Analyse

Beispiel-Gruppen:
```
Gruppe 1 (player_repository.dart):
  - SEC-006, SEC-007, SEC-008, SEC-009

Gruppe 2 (pending_players_page.dart):
  - SEC-001, SEC-002, FN-008/RT-005, RT-006, RT-007
```

### 1.4 User-Scope bestätigen

```
AskUserQuestion:
  question: "Welche Issues sollen bearbeitet werden?"
  options:
    - label: "Alle Issues"
      description: "Alle offenen Bug-Issues systematisch abarbeiten"
    - label: "Nur KRITISCH"
      description: "Nur Issues mit priority: critical"
    - label: "Auswahl"
      description: "Spezifische Issue-Nummern angeben"
```

Falls `$ARGUMENTS` bereits spezifische Issues enthält (z.B. `#1 #2 #4`), diesen Schritt überspringen.

---

## PHASE 2: PARALLELE ANALYSE

### 2.1 Bug-Analyzer parallel starten

**WICHTIG: Für JEDEN Bug/Gruppe PARALLEL einen Analyzer starten!**

```
Task(
  subagent_type: "bug-analyzer",
  description: "Analyze Issue #X",
  prompt: "Analysiere Issue #X: [TITEL]. Details: [BODY]. Liefere: Root-Cause, betroffene Dateien, Fix-Ansatz.",
  run_in_background: true
)
```

Beispiel für mehrere Issues:
```
// Alle parallel starten!
Task(subagent_type: "bug-analyzer", prompt: "Issue #1...", run_in_background: true)
Task(subagent_type: "bug-analyzer", prompt: "Issue #2...", run_in_background: true)
Task(subagent_type: "bug-analyzer", prompt: "Issue #3...", run_in_background: true)
```

### 2.2 Ergebnisse aggregieren

Mit `TaskOutput` auf alle Analyzer warten und sammeln:
- Root-Cause pro Bug
- Betroffene Dateien
- Abhängigkeiten zwischen Bugs

### 2.3 Fix-Reihenfolge optimieren

Nach Analyse die Reihenfolge optimieren:
1. Bugs ohne Abhängigkeiten zuerst
2. Repository-Bugs vor UI-Bugs (Basis stabilisieren)
3. Gruppierte Bugs zusammen

---

## PHASE 3: FIX-LOOP

### 3.1 Fix-Modus wählen (IMMER vor dem Loop!)

```
AskUserQuestion:
  question: "Welcher Fix-Modus?"
  options:
    - label: "Automatisch (Recommended)"
      description: "Läuft durch ohne Bestätigung, pausiert nur bei Fehlern"
    - label: "Interaktiv"
      description: "Bestätigung vor jedem Bug-Fix, maximale Kontrolle"
    - label: "Batch"
      description: "Bestätigung pro Gruppe (z.B. alle Security-Bugs zusammen)"
```

### 3.2 Tasks erstellen

Für jeden Bug/Gruppe einen Task erstellen:

```
TaskCreate(
  subject: "Fix #X: [KURZTITEL]",
  description: "Root-Cause: [CAUSE]. Fix: [APPROACH]. Datei: [FILE]",
  activeForm: "Fixe Issue #X"
)
```

### 3.3 TDD-Zyklus (pro Bug/Gruppe)

**PFLICHT: Für JEDEN Bug den vollständigen Zyklus durchlaufen!**

#### Schritt 1: Failing Test schreiben

```dart
// test/features/xxx/xxx_test.dart

test('sollte [erwartetes Verhalten] - Issue #X', () {
  // Arrange - Setup für den Bug-Fall

  // Act - Aktion die den Bug auslöst

  // Assert - Erwartetes korrektes Verhalten
  expect(actual, expected);
});
```

#### Schritt 2: Test MUSS rot sein

```bash
flutter test test/features/xxx/xxx_test.dart
```

- Falls grün: Test ist falsch oder Bug existiert nicht mehr

#### Schritt 3: Fix implementieren

- Minimaler Fix - nur was nötig ist
- Keine Refactorings "nebenbei"
- Keine zusätzlichen Features

#### Schritt 4: Test MUSS grün sein

```bash
flutter test test/features/xxx/xxx_test.dart
```

#### Schritt 5: Alle Tests grün

```bash
flutter test
```

- ALLE Tests müssen grün sein
- Keine Regressionen erlaubt

#### Schritt 6: Code-Analyse

```bash
dart analyze lib/
```

- Keine neuen Warnings erlaubt

#### Schritt 7: Flutter-Review (bei komplexen Fixes)

```
Task(
  subagent_type: "flutter-reviewer",
  prompt: "Review Bug-Fix für Issue #X. Geänderte Dateien: [LISTE]"
)
```

Bei kritischen Issues: STOPP und fixen!

#### Schritt 8: Commit mit Issue-Referenz

```bash
git add [geänderte Dateien]
git commit -m "$(cat <<'EOF'
fix: [Kurzbeschreibung]

- Root Cause: [Was war das Problem]
- Lösung: [Was wurde geändert]
- Tests: [Welche Tests hinzugefügt]

Closes #X
EOF
)"
```

**WICHTIG:** `Closes #X` schließt das Issue automatisch auf GitHub!

Für mehrere Issues in einer Gruppe:
```
Closes #X, #Y, #Z
```

#### Schritt 9: Task abschließen

```
TaskUpdate(taskId: "...", status: "completed")
```

### 3.4 Fehlerbehandlung im Loop

| Fehler | Reaktion |
|--------|----------|
| Test bleibt rot nach Fix | Debug oder User fragen |
| Fix bricht anderen Test | Optionen anbieten: Fix/Rollback/Debug |
| dart analyze Fehler | Automatisch beheben oder User fragen |
| flutter-reviewer Issues | Fixen vor Commit |

Bei Fehlern im **Automatisch**-Modus:
1. Pausieren
2. User über Fehler informieren
3. Optionen anbieten

---

## PHASE 4: ABSCHLUSS

### 4.1 Zusammenfassung erstellen

Zeige dem User:
- Bearbeitete Issues: X/Y
- Commits: Z
- Neue Tests: N
- Übersprungene Issues (falls vorhanden)

### 4.2 Branch finalisieren

```
AskUserQuestion:
  question: "Wie soll der Branch abgeschlossen werden?"
  options:
    - label: "PR erstellen (Recommended)"
      description: "Pull Request mit Zusammenfassung erstellen"
    - label: "Merge in main"
      description: "Direkt in main mergen (nur wenn berechtigt)"
    - label: "Branch behalten"
      description: "Worktree für weitere Arbeit behalten"
```

Bei **PR erstellen**:
```bash
gh pr create --title "fix: Batch bug fixes (#X, #Y, #Z)" --body "$(cat <<'EOF'
## Summary
- Fixed X issues from bug-hunt
- Added Y new tests
- All tests passing

## Issues Fixed
- #1: [Titel]
- #2: [Titel]
...

## Test Plan
- [x] All existing tests pass
- [x] New tests for each fixed bug
- [x] dart analyze clean
EOF
)"
```

### 4.3 Report speichern

Erstelle `.claude/fix-issues-report-YYYYMMDD.md`:

```markdown
# Fix Issues Report - YYYY-MM-DD

## Zusammenfassung
- **Bearbeitete Issues:** X/Y
- **Commits:** Z
- **Neue Tests:** N
- **Dauer:** ~ X Minuten

## Behobene Issues

| Issue | Titel | Commit |
|-------|-------|--------|
| #1 | [Titel] | abc123 |
| #2 | [Titel] | abc123 |

## Übersprungene Issues

| Issue | Grund |
|-------|-------|
| #X | [Grund] |

## Nächste Schritte
- [ ] PR reviewen und mergen
- [ ] Bug-Hunt wiederholen zur Verifikation
```

---

## Commit-Strategie

| Szenario | Commits | Message-Format |
|----------|---------|----------------|
| Einzelner Bug | 1 Commit | `fix: ... Closes #X` |
| Bugs in gleicher Datei | 1 Commit | `fix: ... Closes #X, #Y` |
| Security-Gruppe | 1 Commit | `fix(security): ... Closes #X, #Y, #Z` |
| Unabhängige Bugs | Je 1 Commit | `fix: ... Closes #X` |

---

## Checkliste

- [ ] Worktree erstellt
- [ ] Baseline-Tests grün
- [ ] GitHub Issues geladen
- [ ] Scope mit User bestätigt
- [ ] Bug-Analyzer parallel gestartet
- [ ] Ergebnisse aggregiert
- [ ] Fix-Modus gewählt
- [ ] Tasks erstellt
- [ ] TDD-Zyklus für jeden Bug durchlaufen
- [ ] Alle Commits mit `Closes #X`
- [ ] Report gespeichert
- [ ] Branch finalisiert (PR/Merge)

---

## Beispiel-Aufrufe

```bash
# Alle offenen Bug-Issues
/fix-issues

# Nur kritische Issues
/fix-issues --priority critical

# Spezifische Issues
/fix-issues #1 #2 #4

# Kombination
/fix-issues --priority high #5 #8
```

---

## Skill-Abhängigkeiten

Dieser Skill nutzt automatisch:
- `superpowers:test-driven-development` (Phase 3)
- `superpowers:verification-before-completion` (Phase 3)
- `superpowers:finishing-a-development-branch` (Phase 4)

---

## Anti-Patterns (VERBOTEN!)

1. **Fixes ohne Tests** - IMMER erst Test schreiben
2. **Commits ohne Issue-Referenz** - IMMER `Closes #X` verwenden
3. **Analyzer sequentiell starten** - IMMER parallel!
4. **Baseline überspringen** - IMMER Tests erst grün haben
5. **Fehler ignorieren** - Bei Fehlern STOPP und User fragen
6. **Worktree überspringen** - IMMER in Worktree arbeiten
7. **Scope nicht bestätigen** - User muss Scope genehmigen
