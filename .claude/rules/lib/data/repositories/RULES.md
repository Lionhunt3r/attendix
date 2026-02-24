# Repository Rules

Diese Regeln gelten für alle Dateien in `lib/data/repositories/`.

## KRITISCH: Multi-Tenant Security

**JEDE Supabase-Query MUSS nach `tenantId` filtern!**

```dart
// ✅ RICHTIG
.eq('tenantId', currentTenantId)

// ❌ FALSCH - Sicherheitslücke!
.select('*')  // ohne tenantId
```

## Repository-Struktur

```dart
class XxxRepository extends BaseRepository with TenantAwareRepository {
  XxxRepository(super.ref);

  Future<List<Xxx>> getAll() async {
    try {
      final response = await supabase
          .from('xxx')
          .select('*')
          .eq('tenantId', currentTenantId)  // PFLICHT!
          .order('created', ascending: false);

      return (response as List)
          .map((e) => Xxx.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getAll');
      rethrow;
    }
  }
}
```

## Pflicht-Methoden

Jedes Repository sollte mindestens haben:
- `getAll()` - Alle Einträge laden
- `getById(int id)` - Einzelnen Eintrag laden
- `create(Model item)` - Neuen Eintrag erstellen
- `update(Model item)` - Eintrag aktualisieren
- `delete(int id)` - Eintrag löschen

## Error Handling

Immer try-catch mit `handleError()`:

```dart
try {
  // Supabase operation
} catch (e, stack) {
  handleError(e, stack, 'methodName');
  rethrow;
}
```

## Provider-Erstellung

Nach Repository-Erstellung IMMER Provider erstellen:

```dart
// In lib/core/providers/<name>_providers.dart
final xxxRepositoryWithTenantProvider = Provider<XxxRepository>((ref) {
  final repo = ref.watch(xxxRepositoryProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  if (tenantId != null) repo.setTenantId(tenantId);
  return repo;
});
```