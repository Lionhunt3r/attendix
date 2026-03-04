---
name: review-code
description: Run both Flutter-specific and general code reviewers in parallel. Use after completing features or before committing.
argument-hint: [optionale Datei-/Feature-Beschreibung]
disable-model-invocation: false
allowed-tools: Read, Glob, Grep, Bash, Agent, TaskCreate, TaskUpdate, TaskList
---

# Code Review Workflow

Startet beide Reviewer parallel für umfassende Review-Abdeckung.

**Scope:** $ARGUMENTS

---

## SCHRITT 1: Geänderte Dateien identifizieren

```bash
git diff --name-only HEAD
git diff --staged --name-only
```

Falls $ARGUMENTS spezifische Dateien/Features nennt, diese priorisieren.

## SCHRITT 2: Beide Reviewer parallel starten

**PFLICHT: Immer BEIDE Agents in einer einzigen Nachricht starten!**

### Agent 1: Flutter Reviewer (Custom)
```
Agent(subagent_type="flutter-reviewer", prompt="Review the following changed files for Flutter-specific issues: Riverpod patterns, Freezed models, Multi-Tenant Security (tenantId filtering), Repository patterns, and Attendix-specific conventions. Files: [DATEILISTE]")
```

**Prüft:**
- tenantId-Filter auf allen Supabase-Queries
- WithTenant Repository-Nutzung
- Riverpod Naming Conventions
- Freezed Model-Korrektheit
- PWA-Kompatibilität

### Agent 2: PR Review Toolkit (Plugin)
```
Agent(subagent_type="pr-review-toolkit:code-reviewer", prompt="Review the following changed files against CLAUDE.md rules and coding standards. Focus on style guide, best practices, and project conventions. Files: [DATEILISTE]")
```

**Prüft:**
- CLAUDE.md Regeln (Deutsch UI-Labels, Architektur)
- Code Style und Best Practices
- Naming Conventions
- Error Handling Patterns

## SCHRITT 3: Ergebnisse zusammenfassen

Nach Abschluss beider Agents:

1. **KRITISCH** (Security, Datenverlust): Sofort beheben
2. **HOCH** (Architektur-Verletzungen): Vor Commit beheben
3. **MITTEL** (Style, Conventions): Empfohlen
4. **NIEDRIG** (Verbesserungen): Optional

Format:
```
## Code Review Ergebnis

### Kritisch (0)
- keine

### Hoch (N)
- [Datei:Zeile] Beschreibung

### Mittel (N)
- [Datei:Zeile] Beschreibung

### Niedrig (N)
- [Datei:Zeile] Beschreibung
```
