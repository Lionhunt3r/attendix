---
name: ionic-migrate
description: Migrate an Ionic/Angular feature to Flutter. Use when converting existing Ionic pages, services, or components to Flutter equivalents.
argument-hint: [ionic-file-or-feature-name]
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Ionic → Flutter Migration Skill

Du migrierst ein Feature aus dem Ionic-Projekt nach Flutter.

## Quell-Projekt
**Pfad:** `/Users/I576226/repositories/attendance`
**Stack:** Ionic 8 + Angular 18 + Capacitor + Supabase

## Ziel-Projekt
**Pfad:** `/Users/I576226/repositories/attendix`
**Stack:** Flutter 3.x + Riverpod + go_router + Supabase

## Migrations-Workflow

### 1. Ionic-Quelle analysieren

Lies die relevanten Ionic-Dateien aus `/Users/I576226/repositories/attendance/src/app/`:
- Page: `<feature>/<feature>.page.ts` und `.html`
- Service: `services/<name>/<name>.service.ts`
- Interfaces: `utilities/interfaces.ts`

### 2. Pattern-Mapping anwenden

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
| Toast | `ScaffoldMessenger.showSnackBar()` |
| Navigation | `context.go()` / `context.push()` |

### 3. Flutter-Struktur erstellen

```
lib/features/$ARGUMENTS/
├── presentation/
│   ├── pages/
│   │   └── ${ARGUMENTS}_page.dart
│   └── widgets/
│       └── (custom widgets)
```

Bei Bedarf auch:
- `lib/data/models/<name>/` - Freezed Model
- `lib/data/repositories/<name>_repository.dart` - Repository
- `lib/core/providers/<name>_providers.dart` - Providers

### 4. Code-Konventionen

**Provider-Namen:**
```dart
// Daten laden
final ${name}sProvider = FutureProvider<List<$Model>>((ref) {...});

// Mit Parameter
final ${name}ByIdProvider = FutureProvider.family<$Model?, int>((ref, id) {...});

// Mutations
final ${name}NotifierProvider = NotifierProvider<${Name}Notifier, AsyncValue<void>>(...);
```

**Multi-Tenant KRITISCH:**
```dart
// IMMER tenantId filtern!
.eq('tenantId', currentTenantId)
```

**UI-Labels auf Deutsch:**
- Anwesend, Abwesend, Entschuldigt, Verspätet
- Speichern, Abbrechen, Löschen
- Fehler beim Laden, Keine Daten

### 5. Nach der Migration

```bash
# Falls Freezed-Models erstellt wurden
dart run build_runner build --delete-conflicting-outputs

# Code analysieren
dart analyze lib/
```

### 6. Migration Status aktualisieren

**WICHTIG:** Nach erfolgreicher Migration, aktualisiere `.claude/migration-status.md`:

1. Feature von "Ausstehend" nach "Vollständig migriert" verschieben
2. Service-Status aktualisieren falls relevant
3. Datum am Ende aktualisieren

### 7. Commit erstellen

```bash
git add .
git commit -m "feat: Migrate $ARGUMENTS from Ionic to Flutter"
```

---

## Checkliste

- [ ] Ionic-Quelle analysiert
- [ ] Flutter-Code erstellt
- [ ] tenantId-Filter vorhanden (KRITISCH!)
- [ ] Deutsche Labels verwendet
- [ ] Route in `app_router.dart`
- [ ] Provider in `providers.dart` exportiert
- [ ] `flutter analyze` ohne Fehler
- [ ] `migration-status.md` aktualisiert
- [ ] Committed

## Beispiel-Migration

**Ionic Page:**
```typescript
@Component({...})
export class PlayersPage {
  players = signal<Player[]>([]);

  ngOnInit() {
    this.loadPlayers();
  }

  async loadPlayers() {
    const data = await this.playerService.getPlayers();
    this.players.set(data);
  }
}
```

**Flutter Equivalent:**
```dart
class PlayersPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Spieler')),
      body: playersAsync.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => EmptyStateWidget(icon: Icons.error, title: 'Fehler'),
        data: (players) => ListView.builder(...),
      ),
    );
  }
}
```

## Shared Widgets nutzen

Verwende vorhandene Widgets aus `lib/shared/widgets/`:
- `ListSkeleton` - Loading State
- `EmptyStateWidget` - Leere Liste
- `Avatar` - Profilbild mit Fallback
- `StatusBadge` - Anwesenheitsstatus
- `AnimatedListItem` - List-Animationen