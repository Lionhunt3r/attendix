---
name: fix-bug
description: Systematic bug-fixing workflow with worktree isolation, root-cause analysis, and TDD-based fixes. Use when fixing any bug.
argument-hint: [bug-beschreibung oder issue-referenz]
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, EnterWorktree, TaskCreate, TaskUpdate, TaskList, AskUserQuestion
---

# Bug-Fixing Workflow

Systematischer Workflow zur Fehlerbehebung mit Isolation, Analyse und TDD.

**Bug:** $ARGUMENTS

---

## PHASE 0: WORKTREE ERSTELLEN (PFLICHT!)

**IMMER zuerst ausführen - keine Ausnahmen!**

1. Erstelle einen Worktree für isolierte Arbeit:
   ```
   EnterWorktree(name: "fix-KURZBESCHREIBUNG")
   ```
   - Extrahiere eine kurze Beschreibung aus $ARGUMENTS (max 20 Zeichen, keine Leerzeichen)
   - Beispiel: "fix-login-button", "fix-tenant-filter"

2. Baseline verifizieren:
   ```bash
   flutter test
   ```
   - Tests müssen grün sein bevor du startest
   - Falls Tests fehlschlagen: STOPP und User informieren

---

## PHASE 1: BUG VERSTEHEN

Erfasse systematisch alle Informationen:

### 1.1 Bug-Beschreibung dokumentieren

Erstelle mentale Notizen zu:
- **Was passiert?** (Aktuelles Verhalten)
- **Was sollte passieren?** (Erwartetes Verhalten)
- **Reproduktionsschritte** (falls bekannt)

### 1.2 Betroffene Bereiche identifizieren

Nutze den Explore-Agent um relevante Dateien zu finden:
```
Task(subagent_type: "Explore", prompt: "Finde Dateien die mit [BEREICH] zusammenhängen...")
```

### 1.3 User-Rückfragen (falls nötig)

Falls Informationen fehlen, frage nach:
- Reproduktionsschritte
- Error Messages / Stack Traces
- Wann ist der Bug aufgetreten?

---

## PHASE 2: ROOT CAUSE ANALYSE

**PFLICHT: Nutze den bug-analyzer Agent!**

```
Task(
  subagent_type: "bug-analyzer",
  prompt: "Analysiere den Bug: [BESCHREIBUNG]. Betroffene Dateien: [LISTE]"
)
```

Der Agent liefert:
1. **Root Cause Hypothese** - Warum tritt der Fehler auf?
2. **Betroffene Code-Stellen** - Exakte Dateien und Zeilen
3. **Empfohlener Fix-Ansatz** - Wie soll korrigiert werden?

### User-Bestätigung erforderlich!

Präsentiere die Hypothese und frage:
```
AskUserQuestion: "Hypothese: [ROOT_CAUSE]. Soll ich mit diesem Ansatz fortfahren?"
```

---

## PHASE 3: FIX PLANEN

Erstelle Tasks für jeden Schritt:

```
TaskCreate(subject: "Failing Test für Bug schreiben", description: "...", activeForm: "Schreibe Failing Test")
TaskCreate(subject: "Bug-Fix implementieren", description: "...", activeForm: "Implementiere Fix")
TaskCreate(subject: "Alle Tests verifizieren", description: "...", activeForm: "Verifiziere Tests")
TaskCreate(subject: "Code Review durchführen", description: "...", activeForm: "Führe Review durch")
```

### User-Bestätigung erforderlich!

```
TaskList()
AskUserQuestion: "Plan erstellt. Soll ich mit der Implementierung starten?"
```

---

## PHASE 4: IMPLEMENTIERUNG (TDD)

**PFLICHT: Folge dem test-driven-development Skill!**

### 4.1 Failing Test schreiben

```dart
// test/features/xxx/xxx_test.dart

test('sollte [erwartetes Verhalten] wenn [Bedingung]', () {
  // Arrange - Setup für den Bug-Fall

  // Act - Aktion die den Bug auslöst

  // Assert - Erwartetes korrektes Verhalten
  expect(actual, expected);
});
```

### 4.2 Test MUSS fehlschlagen!

```bash
flutter test test/features/xxx/xxx_test.dart
```

- Der Test MUSS rot sein
- Falls grün: Test ist falsch oder Bug existiert nicht mehr

### 4.3 Minimalen Fix implementieren

- Ändere nur was nötig ist
- Keine Refactorings "nebenbei"
- Keine zusätzlichen Features

### 4.4 Test MUSS bestehen!

```bash
flutter test test/features/xxx/xxx_test.dart
```

- Der Test MUSS jetzt grün sein
- Falls rot: Fix ist unvollständig

### 4.5 Alle Tests ausführen

```bash
flutter test
```

- ALLE Tests müssen grün sein
- Keine Regressionen erlaubt

---

## PHASE 5: REVIEW & COMPLETION

### 5.1 Code-Analyse

```bash
dart analyze lib/
```

- Keine neuen Warnings erlaubt
- Alle Issues beheben

### 5.2 Flutter-Review

**PFLICHT: Nutze den flutter-reviewer Agent!**

```
Task(
  subagent_type: "flutter-reviewer",
  prompt: "Review die Bug-Fix Änderungen: [BESCHREIBUNG]. Geänderte Dateien: [LISTE]"
)
```

Bei kritischen Issues: STOPP und fixen!

### 5.3 Verification vor Commit

**PFLICHT: Nutze verification-before-completion Skill!**

Vor jedem Commit verifizieren:
```bash
flutter test
dart analyze lib/
```

### 5.4 Commit erstellen

```bash
git add [geänderte Dateien]
git commit -m "fix: [Kurzbeschreibung]

- Root Cause: [Was war das Problem]
- Lösung: [Was wurde geändert]
- Tests: [Welche Tests hinzugefügt/geändert]"
```

### 5.5 Branch abschließen

**PFLICHT: Nutze finishing-a-development-branch Skill!**

Optionen:
- Merge in main (falls berechtigt)
- PR erstellen (empfohlen)
- Worktree behalten für weitere Arbeit

---

## Checkliste

- [ ] Worktree erstellt
- [ ] Baseline-Tests grün
- [ ] Bug verstanden und dokumentiert
- [ ] Root-Cause-Analyse durchgeführt
- [ ] Hypothese vom User bestätigt
- [ ] Plan erstellt und bestätigt
- [ ] Failing Test geschrieben
- [ ] Test fehlgeschlagen (rot)
- [ ] Fix implementiert
- [ ] Test bestanden (grün)
- [ ] Alle Tests grün
- [ ] dart analyze ohne Fehler
- [ ] flutter-reviewer Review bestanden
- [ ] Commit erstellt
- [ ] Branch abgeschlossen

---

## Skill-Abhängigkeiten

Dieser Skill nutzt automatisch:
- `superpowers:systematic-debugging` (Phase 2)
- `superpowers:test-driven-development` (Phase 4)
- `superpowers:verification-before-completion` (Phase 5)
- `superpowers:finishing-a-development-branch` (Phase 5)

Falls du diese Skills nicht kennst, rufe sie auf um die Details zu erfahren.

---

## Anti-Patterns (VERBOTEN!)

1. **Quick-Fix ohne Analyse** - IMMER Root-Cause-Analyse durchführen
2. **Fix ohne Test** - IMMER erst Test schreiben
3. **Commit ohne Verification** - IMMER Tests und Analyze ausführen
4. **Worktree überspringen** - IMMER in Worktree arbeiten
5. **User-Bestätigung überspringen** - IMMER bei Hypothese und Plan fragen
