---
name: migrate
description: "Starte vollständige Migration eines Ionic Features nach Flutter"
allowed-tools: ["Task", "Read", "Glob", "Grep", "Write", "Edit", "Bash", "TodoWrite"]
---

# /migrate [feature-name]

Startet den vollständigen Migrations-Workflow für ein Ionic Feature.

## Verwendung

```
/migrate shifts
/migrate handover
/migrate signout
```

## Was passiert

1. **Analyse** - Ionic und Flutter Code werden parallel analysiert
2. **Planung** - Tasks werden erstellt und dir zur Bestätigung gezeigt
3. **Implementierung** - Code wird schrittweise migriert
4. **Review** - Automatische Code-Prüfung
5. **Commit** - Änderungen werden committed

## Skill

Nutzt: `migrate-full` Skill

## Ohne Argument

Zeigt die ausstehenden Features aus `migration-status.md`.
