---
name: bug-hunt
description: Comprehensive bug scanner that runs parallel agents to find business logic, functional, runtime, and security bugs. Use for systematic codebase audits.
argument-hint: [full|feature-name] - optionaler Scope
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, TaskCreate, TaskUpdate, TaskList, AskUserQuestion
---

# Bug Hunt - Umfassender Bug-Scanner

Systematischer Scan der Attendix App nach allen Bug-Kategorien.

**Scope:** $ARGUMENTS

---

## PHASE 0: SETUP

### 0.1 Scope bestimmen

Falls `$ARGUMENTS` leer oder "full":
- Scanne die gesamte Codebase

Falls `$ARGUMENTS` ein Feature-Name (z.B. "attendance", "songs"):
- Fokussiere auf `lib/features/$ARGUMENTS/` und zugehörige Repositories

### 0.2 Bestehenden Report archivieren

```bash
# Falls Report existiert, archivieren
if [ -f .claude/bug-report.md ]; then
  mv .claude/bug-report.md ".claude/bug-report-$(date +%Y%m%d-%H%M%S).md"
fi
```

### 0.3 Tasks erstellen

```
TaskCreate(subject: "Business-Logik Scan", description: "business-logic-scanner Agent ausführen", activeForm: "Scanne Business-Logik")
TaskCreate(subject: "Funktionaler Scan", description: "functional-scanner Agent ausführen", activeForm: "Scanne UI/Widgets")
TaskCreate(subject: "Runtime Scan", description: "runtime-scanner Agent ausführen", activeForm: "Scanne Runtime-Risiken")
TaskCreate(subject: "Security Scan", description: "security-scanner Agent ausführen", activeForm: "Scanne Security")
TaskCreate(subject: "Report erstellen", description: "Ergebnisse aggregieren und Report generieren", activeForm: "Erstelle Bug-Report")
```

---

## PHASE 1: PARALLEL SCANS

**WICHTIG: Alle 4 Scanner PARALLEL starten!**

Nutze den Task-Tool mit `run_in_background: true` für parallele Ausführung:

```
Task(
  subagent_type: "business-logic-scanner",
  description: "Scan Business Logic",
  prompt: "Scanne die Attendix Codebase auf Business-Logik-Bugs. Fokus: Anwesenheit, Rollen, Meetings, Songs. Scope: [SCOPE]. Liefere strukturierte Bug-Liste.",
  run_in_background: true
)

Task(
  subagent_type: "functional-scanner",
  description: "Scan Functional Bugs",
  prompt: "Scanne die Attendix Codebase auf funktionale Bugs. Fokus: Widgets, UI, Navigation, State Management. Scope: [SCOPE]. Liefere strukturierte Bug-Liste.",
  run_in_background: true
)

Task(
  subagent_type: "runtime-scanner",
  description: "Scan Runtime Bugs",
  prompt: "Scanne die Attendix Codebase auf Runtime-Risiken. Fokus: Types, Null-Safety, Async, Collections. Scope: [SCOPE]. Liefere strukturierte Bug-Liste.",
  run_in_background: true
)

Task(
  subagent_type: "security-scanner",
  description: "Scan Security Bugs",
  prompt: "Scanne die Attendix Codebase auf Security-Bugs. Fokus: Multi-Tenant, Auth, Permissions. Scope: [SCOPE]. Liefere strukturierte Bug-Liste. KRITISCH: Jede Query ohne tenantId ist ein Security-Bug!",
  run_in_background: true
)
```

### Auf Ergebnisse warten

Sammle die Ergebnisse aller 4 Scanner mit `TaskOutput`.

---

## PHASE 2: AGGREGATION

### 2.1 Ergebnisse sammeln

Sammle alle Bug-Listen aus den Scanner-Outputs:
- Business-Logik Bugs (BL-xxx)
- Funktionale Bugs (FN-xxx)
- Runtime Bugs (RT-xxx)
- Security Bugs (SEC-xxx)

### 2.2 Duplikate entfernen

Prüfe ob Bugs die gleiche Root Cause haben:
- Gleiche Datei + gleiche Zeile = Duplikat
- Ähnliches Problem, unterschiedliche Manifestation = zusammenfassen

### 2.3 Priorisieren

Sortiere nach Priorität:
1. **KRITISCH** - Security, Datenverlust, Crashes
2. **HOCH** - Feature broken, wichtige Edge Cases
3. **MITTEL** - Inkonsistenzen, UX-Probleme
4. **NIEDRIG** - Verbesserungen, Code-Qualität

---

## PHASE 3: REPORT GENERIEREN

Erstelle `.claude/bug-report.md` mit folgendem Format:

```markdown
# Bug Report - Attendix
Generiert: [DATUM]
Scope: [full|feature-name]

## Zusammenfassung

| Kategorie | KRITISCH | HOCH | MITTEL | NIEDRIG | Gesamt |
|-----------|----------|------|--------|---------|--------|
| Security | X | X | X | X | X |
| Business-Logik | X | X | X | X | X |
| Funktional | X | X | X | X | X |
| Runtime | X | X | X | X | X |
| **Gesamt** | **X** | **X** | **X** | **X** | **X** |

## Handlungsempfehlungen

1. 🔴 **Sofort:** X kritische Bugs fixen (besonders Security!)
2. 🟠 **Diese Woche:** X hohe Bugs fixen
3. 🟡 **Backlog:** X mittlere/niedrige Bugs

---

## KRITISCH

### SEC-001: [Titel]
- **Kategorie:** Security
- **Datei:** `lib/data/repositories/xxx.dart:40`
- **Problem:** [Beschreibung]
- **Fix:** [Lösung]
- **Status:** [ ] Offen

### BL-001: [Titel]
...

---

## HOCH

### FN-001: [Titel]
...

---

## MITTEL

...

---

## NIEDRIG

...

---

## Scan-Details

- **Gescannte Dateien:** X
- **Scanner verwendet:** business-logic, functional, runtime, security
- **Dauer:** X Minuten
- **False Positives entfernt:** X

## Nächste Schritte

1. Kritische Security-Bugs SOFORT fixen (Multi-Tenant!)
2. Business-Logik Bugs reviewen mit Product Owner
3. Funktionale Bugs in Sprint einplanen
4. Runtime-Bugs mit Tests abdecken
```

---

## PHASE 4: ABSCHLUSS

### 4.1 Report speichern

```
Write(file_path: ".claude/bug-report.md", content: [REPORT])
```

### 4.2 Zusammenfassung anzeigen

Zeige dem User:
- Anzahl gefundener Bugs pro Kategorie
- Top 3 kritischste Bugs
- Empfohlene nächste Schritte

### 4.3 Tasks abschließen

Alle Tasks als completed markieren.

---

## Checkliste

- [ ] Scope bestimmt (full oder feature)
- [ ] Alter Report archiviert (falls vorhanden)
- [ ] Tasks erstellt
- [ ] 4 Scanner parallel gestartet
- [ ] Auf alle Scanner-Ergebnisse gewartet
- [ ] Duplikate entfernt
- [ ] Nach Priorität sortiert
- [ ] Report in `.claude/bug-report.md` geschrieben
- [ ] Zusammenfassung angezeigt
- [ ] Tasks abgeschlossen

---

## Hinweise

### Scanner-Agents

| Agent | Fokus |
|-------|-------|
| `business-logic-scanner` | Anwesenheit, Rollen, Berechnungen, Validierungen |
| `functional-scanner` | Widgets, UI, Navigation, Forms, State |
| `runtime-scanner` | Types, Null-Safety, Async, Collections |
| `security-scanner` | Multi-Tenant, Auth, Permissions, Data Exposure |

### Prioritäts-Kriterien

| Priorität | Definition |
|-----------|------------|
| KRITISCH | Datenverlust, Security-Breach, App-Crash |
| HOCH | Feature kaputt, wichtiger Workflow blockiert |
| MITTEL | Edge Case, inkonsistente Daten, UX-Problem |
| NIEDRIG | Verbesserung, Code-Qualität, Performance |

### Nach dem Bug-Hunt

1. Kritische Bugs sofort mit `/fix-bug [BUG-ID]` beheben
2. Bug-Report als Referenz für Sprint-Planung nutzen
3. Regelmäßig (z.B. monatlich) Bug-Hunt wiederholen

---

## Anti-Patterns (VERBOTEN!)

1. **Scanner sequentiell starten** - IMMER parallel!
2. **Ohne Report abschließen** - Report ist Pflicht!
3. **Duplikate nicht entfernen** - Gleiche Bugs zusammenfassen!
4. **Security-Bugs ignorieren** - IMMER höchste Priorität!
5. **Ohne Scope starten** - Immer klären: full oder feature
