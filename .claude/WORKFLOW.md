# Migration Workflow mit Worktrees

## Übersicht

Dieser Workflow ermöglicht parallele Migration von Ionic→Flutter Features.

```
┌─────────────────────────────────────────────────────────┐
│  Haupt-Terminal (Koordination)                          │
│  - Migration-Status prüfen                              │
│  - Code Reviews                                         │
│  - Merges                                               │
└─────────────────────────────────────────────────────────┘
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│  Worktree 1      │ │  Worktree 2      │ │  Worktree 3      │
│  feature-xyz     │ │  feature-abc     │ │  bugfix-123      │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

---

## Workflow für ein Feature

### 1. Feature auswählen

Prüfe `.claude/migration-status.md` für ausstehende Features:

```
Zeig mir die ausstehenden Features aus migration-status.md
```

### 2. Worktree starten

```bash
claude --worktree feature-<name>
```

Beispiel:
```bash
claude --worktree feature-meeting-detail
claude --worktree feature-handover
claude --worktree feature-telegram
```

### 3. Migration durchführen

Im Worktree sage:
```
/ionic-migrate meeting
```

Der Skill wird:
1. Ionic-Quelle lesen
2. Flutter-Code erstellen
3. Tests optional generieren

### 4. Testen

```bash
flutter analyze lib/
flutter test
flutter run -d chrome
```

### 5. Committen (im Worktree)

```bash
git add .
git commit -m "feat: Migrate meeting detail from Ionic"
```

### 6. Zurück zum Hauptbranch

Worktree beenden (Ctrl+C oder `/exit`), dann:

```bash
git checkout master
git merge worktree-feature-meeting-detail
```

### 7. Status aktualisieren

In der Haupt-Session:
```
Aktualisiere migration-status.md - Meeting Detail ist jetzt fertig
```

---

## Paralleles Arbeiten

Du kannst mehrere Terminals gleichzeitig nutzen:

```bash
# Terminal 1
claude --worktree feature-meeting-detail

# Terminal 2
claude --worktree feature-telegram

# Terminal 3
claude --worktree feature-handover
```

Jeder Worktree:
- Hat eigenen Branch (`worktree-feature-<name>`)
- Arbeitet isoliert
- Kann unabhängig committen

---

## Quick Reference

| Aktion | Befehl |
|--------|--------|
| Feature starten | `claude --worktree feature-<name>` |
| Migration ausführen | `/ionic-migrate <feature>` |
| Status prüfen | Lies `migration-status.md` |
| Analyzer laufen | "Lauf den migration-analyzer" |
| Code Review | "Prüfe den Code mit flutter-reviewer" |
| Tests generieren | "Generiere Tests mit test-generator" |

---

## Migration-Checkliste pro Feature

- [ ] Ionic-Quelle analysiert
- [ ] Flutter-Code erstellt
- [ ] tenantId-Filter vorhanden
- [ ] Deutsche Labels verwendet
- [ ] Route in `app_router.dart` hinzugefügt
- [ ] Provider in `providers.dart` exportiert
- [ ] `flutter analyze` ohne Fehler
- [ ] Manuell getestet
- [ ] Committed
- [ ] `migration-status.md` aktualisiert

---

## Ausstehende Features (Kurzliste)

### Jetzt bereit zum Migrieren:
1. **meeting-detail** - Niedrig, keine Abhängigkeiten
2. **signout** - Niedrig, nutzt vorhandene Providers
3. **song-viewer** - Mittel, braucht PDF-Package

### Später:
4. **telegram** - Mittel
5. **handover** - Mittel
6. **shifts** - Mittel (falls benötigt)