# Provider Rules

Diese Regeln gelten für alle Dateien in `lib/core/providers/`.

## Naming Convention

| Typ | Pattern | Beispiel |
|-----|---------|----------|
| Daten laden | `${name}sProvider` | `playersProvider` |
| Mit Parameter | `${name}ByIdProvider` | `playerByIdProvider` |
| Mutations | `${name}NotifierProvider` | `playerNotifierProvider` |
| Repository | `${name}RepositoryWithTenantProvider` | `playerRepositoryWithTenantProvider` |

## FutureProvider Pattern

```dart
// Liste laden
final playersProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(playerRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return [];
  return repo.getPlayers();
});

// Mit Parameter (family)
final playerByIdProvider = FutureProvider.family<Person?, int>((ref, id) async {
  final repo = ref.watch(playerRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return null;
  return repo.getPlayerById(id);
});
```

## Notifier Pattern (Mutations)

```dart
class PlayerNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> create(Person player) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(playerRepositoryWithTenantProvider);
      await repo.create(player);
      state = const AsyncValue.data(null);
      ref.invalidate(playersProvider);  // Refresh data!
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final playerNotifierProvider = NotifierProvider<PlayerNotifier, AsyncValue<void>>(
  PlayerNotifier.new,
);
```

## Wichtige Regeln

1. **Immer `WithTenant` Repository nutzen:**
   ```dart
   // ✅ RICHTIG
   ref.watch(playerRepositoryWithTenantProvider)

   // ❌ FALSCH
   ref.watch(playerRepositoryProvider)
   ```

2. **Tenant-Check vor Query:**
   ```dart
   if (!repo.hasTenantId) return [];
   ```

3. **Nach Mutation invalidate:**
   ```dart
   ref.invalidate(playersProvider);
   ```

4. **In `providers.dart` exportieren:**
   ```dart
   export 'player_providers.dart';
   ```

## StateProvider (einfacher State)

```dart
// Filter-State
final playerFilterProvider = StateProvider<String>((ref) => '');

// Boolean-State
final showActiveOnlyProvider = StateProvider<bool>((ref) => true);
```

## Computed Provider

```dart
// Filtered list based on other providers
final filteredPlayersProvider = Provider<List<Person>>((ref) {
  final players = ref.watch(playersProvider).valueOrNull ?? [];
  final filter = ref.watch(playerFilterProvider);

  if (filter.isEmpty) return players;
  return players.where((p) =>
    p.lastName.toLowerCase().contains(filter.toLowerCase())
  ).toList();
});
```