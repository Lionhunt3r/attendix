# Attendix - Flutter Migration Instructions

## Project Overview

Attendix is a Flutter migration of the Ionic/Angular "Attendance" app. It's a multi-tenant attendance tracking app for organizations (orchestras, choirs, groups).

**Source:** Ionic 8 + Angular 18 + Capacitor + Supabase  
**Target:** Flutter 3.x + Riverpod + go_router + Supabase

## Architecture

### Directory Structure

```
lib/
├── core/                    # Shared infrastructure
│   ├── config/              # Supabase config, env
│   ├── constants/           # Enums, app constants
│   ├── providers/           # Riverpod providers (state management)
│   ├── router/              # go_router configuration
│   ├── theme/               # Colors, theme data
│   └── utils/               # Helpers, converters
├── data/                    # Data layer
│   ├── models/              # Freezed models (immutable)
│   │   ├── attendance/
│   │   ├── person/
│   │   ├── tenant/
│   │   └── ...
│   └── repositories/        # Supabase data access
├── features/                # Feature modules
│   ├── attendance/
│   │   └── presentation/
│   │       └── pages/
│   ├── people/
│   ├── songs/
│   ├── settings/
│   └── ...
└── shared/                  # Shared widgets
    └── widgets/
```

### State Management: Riverpod

```dart
// Provider für Daten laden
final playersProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(playerRepositoryWithTenantProvider);
  return repo.getPlayers();
});

// Provider mit Parameter
final playerByIdProvider = FutureProvider.family<Person?, int>((ref, id) async {
  final repo = ref.watch(playerRepositoryWithTenantProvider);
  return repo.getPlayerById(id);
});

// Notifier für Mutations
class AttendanceNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);
  
  Future<void> updateStatus(int id, String status) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateStatus(id, status);
      state = const AsyncValue.data(null);
      ref.invalidate(attendancesProvider); // Refresh data
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

### Models: Freezed

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'person.freezed.dart';
part 'person.g.dart';

@freezed
class Person with _$Person {
  const factory Person({
    required int id,
    required int tenantId,
    required String firstName,
    required String lastName,
    String? email,
    int? instrument,
    @Default(false) bool isLeader,
    DateTime? created,
  }) = _Person;

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}
```

### Repository Pattern

```dart
class PlayerRepository extends BaseRepository with TenantAwareRepository {
  PlayerRepository(super.ref);

  Future<List<Person>> getPlayers() async {
    try {
      final response = await supabase
          .from('player')
          .select('*')
          .eq('tenantId', currentTenantId)
          .isFilter('left', null)
          .order('lastName');
      
      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getPlayers');
      rethrow;
    }
  }
}
```

### Page Structure

```dart
class PeoplePage extends ConsumerStatefulWidget {
  const PeoplePage({super.key});

  @override
  ConsumerState<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends ConsumerState<PeoplePage> {
  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Personen')),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (players) => ListView.builder(
          itemCount: players.length,
          itemBuilder: (context, index) => PlayerTile(player: players[index]),
        ),
      ),
    );
  }
}
```

## Migration Mappings

### Ionic → Flutter Translations

| Ionic/Angular | Flutter Equivalent |
|---------------|-------------------|
| `@Component` | `ConsumerStatefulWidget` / `ConsumerWidget` |
| `ngOnInit()` | `initState()` or provider auto-fetch |
| `ionViewWillEnter` | `initState()` + `ref.watch()` |
| `ngOnDestroy` | `dispose()` |
| `@Input()` | Constructor parameter |
| `@Output() EventEmitter` | Callback function |
| `WritableSignal<T>` | `StateProvider<T>` or `Notifier<T>` |
| `effect()` | `ref.listen()` |
| `ModalController` | `showModalBottomSheet()` or `showDialog()` |
| `ToastController` | `ScaffoldMessenger.showSnackBar()` |
| `NavController.navigateTo` | `context.go()` / `context.push()` |
| `*ngIf` | Conditional widget / `if (condition)` |
| `*ngFor` | `ListView.builder` / `.map()` |
| `[ngClass]` | Conditional decoration |
| `async pipe` | `.when()` pattern |
| `RealtimeChannel.subscribe` | `supabase.channel().onPostgresChanges()` |
| `isPlatform('ios')` | `Platform.isIOS` / `Theme.of(context).platform` |

### Service → Repository/Provider

```
// Ionic Service
export class PlayerService {
  getPlayers(): Promise<Player[]> { ... }
}

// Flutter Repository + Provider
class PlayerRepository extends BaseRepository { ... }
final playersProvider = FutureProvider<List<Person>>((ref) { ... });
```

### Component → Widget

```
// Ionic Component
<ion-item *ngFor="let player of players" (click)="openPlayer(player)">
  <ion-avatar slot="start">
    <img [src]="player.image">
  </ion-avatar>
  <ion-label>{{ player.firstName }} {{ player.lastName }}</ion-label>
</ion-item>

// Flutter Widget
ListTile(
  leading: CircleAvatar(backgroundImage: NetworkImage(player.image ?? '')),
  title: Text('${player.firstName} ${player.lastName}'),
  onTap: () => context.push('/people/${player.id}'),
)
```

## Key Conventions

### Error Handling

```dart
// Always wrap async operations
try {
  await repository.updatePlayer(player);
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gespeichert')),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
    );
  }
}
```

### Platform Checks (PWA Compatibility)

```dart
// Native APIs need try-catch for PWA
Future<void> triggerHaptic() async {
  try {
    await HapticFeedback.lightImpact();
  } catch (_) {
    // Not available in PWA
  }
}
```

### Realtime Subscriptions

```dart
late final RealtimeChannel _channel;

@override
void initState() {
  super.initState();
  _subscribeToChanges();
}

void _subscribeToChanges() {
  _channel = supabase
      .channel('player-changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'player',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'tenantId',
          value: tenantId,
        ),
        callback: (payload) {
          ref.invalidate(playersProvider);
        },
      )
      .subscribe();
}

@override
void dispose() {
  _channel.unsubscribe();
  super.dispose();
}
```

### Multi-Tenant Always

```dart
// ALWAYS include tenantId in queries
final response = await supabase
    .from('player')
    .select('*')
    .eq('tenantId', currentTenantId)  // ← Required
    .order('lastName');
```

## Packages in Use

- `flutter_riverpod` - State management
- `freezed` + `json_serializable` - Immutable models
- `go_router` - Navigation
- `supabase_flutter` - Backend
- `fl_chart` - Charts/Statistics
- `pdf` + `printing` - PDF export
- `excel` - Excel export
- `share_plus` - Sharing
- `cached_network_image` - Image caching
- `connectivity_plus` - Network status

## Commands

```bash
# Generate freezed/json files
dart run build_runner build --delete-conflicting-outputs

# Analyze code
dart analyze lib/

# Run tests
flutter test

# Run on Chrome
flutter run -d chrome
```
