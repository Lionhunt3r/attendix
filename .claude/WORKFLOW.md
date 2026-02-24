# Migration Workflow

## Schnellstart

```
/ionic-migrate [feature]
```

Das ist der einzige Befehl, den du brauchst. Der Skill orchestriert automatisch:

1. **Worktree-Frage** - Optional für paralleles Arbeiten
2. **Analyse** - Startet `migration-analyzer` und `Explore` parallel
3. **Planung** - Erstellt Tasks, holt Bestätigung
4. **Implementierung** - Code mit Pattern-Mapping
5. **Review** - `flutter-reviewer` Agent
6. **Commit** - `/commit` Skill + Status-Update

---

## Manuelles Worktree-Setup

Falls du explizit in einem Worktree arbeiten möchtest:

```bash
claude --worktree migrate-[feature]
```

Dann im Worktree:
```
/ionic-migrate [feature]
```

### Worktree-Verwaltung

```bash
# Aktive Worktrees anzeigen
git worktree list

# Worktree entfernen (nach Merge)
git worktree remove .claude/worktrees/[name]
```

---

## Verfügbare Skills & Agents

### Skills

| Skill | Beschreibung |
|-------|--------------|
| `/ionic-migrate [feature]` | **Vollständiger Migrations-Workflow** |
| `/flutter-feature` | Neues Flutter Feature erstellen |
| `/commit` | Commit erstellen |

### Agents (automatisch von Skills genutzt)

| Agent | Zweck |
|-------|-------|
| `migration-analyzer` | Ionic analysieren |
| `flutter-reviewer` | Code prüfen |
| `test-generator` | Tests erstellen |
| `Explore` | Codebase durchsuchen |

---

## Migrations-Checkliste

- [ ] `/ionic-migrate [feature]` ausgeführt
- [ ] Worktree-Entscheidung getroffen
- [ ] Analyse abgeschlossen
- [ ] Tasks bestätigt
- [ ] Code implementiert
- [ ] tenantId-Filter vorhanden (KRITISCH!)
- [ ] Code Review bestanden
- [ ] `dart analyze` ohne Fehler
- [ ] Committed
- [ ] `migration-status.md` aktualisiert

---

## Ausstehende Features

Siehe `.claude/migration-status.md` für aktuelle Liste.

### Quick Reference

| Feature | Komplexität |
|---------|-------------|
| Shifts/Schichtpläne | Mittel |
| Handover | Mittel |
| Sign-out Page | Niedrig |
| Share-Link (Songs) | Mittel |
