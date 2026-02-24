---
name: supabase-repo
description: Create a Supabase repository with tenant-aware queries. Use when adding new data access layers.
argument-hint: [repository-name]
disable-model-invocation: true
allowed-tools: Read, Write, Edit
---

# Supabase Repository Generator

Erstellt ein neues Repository für Supabase-Datenzugriff mit Multi-Tenant-Support.

## Repository: $ARGUMENTS

### 1. Repository erstellen

**Pfad:** `lib/data/repositories/${ARGUMENTS.toLowerCase()}_repository.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/${ARGUMENTS.toLowerCase()}/${ARGUMENTS.toLowerCase()}.dart';
import 'base_repository.dart';

class ${ARGUMENTS}Repository extends BaseRepository with TenantAwareRepository {
  ${ARGUMENTS}Repository(super.ref);

  /// Alle ${ARGUMENTS}s für den aktuellen Tenant laden
  Future<List<$ARGUMENTS>> getAll() async {
    try {
      final response = await supabase
          .from('${ARGUMENTS.toLowerCase()}')
          .select('*')
          .eq('tenantId', currentTenantId)  // KRITISCH: Immer tenantId filtern!
          .order('created', ascending: false);

      return (response as List)
          .map((e) => $ARGUMENTS.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getAll');
      rethrow;
    }
  }

  /// Einzelnes $ARGUMENTS per ID laden
  Future<$ARGUMENTS?> getById(int id) async {
    try {
      final response = await supabase
          .from('${ARGUMENTS.toLowerCase()}')
          .select('*')
          .eq('id', id)
          .eq('tenantId', currentTenantId)  // KRITISCH!
          .maybeSingle();

      if (response == null) return null;
      return $ARGUMENTS.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'getById');
      rethrow;
    }
  }

  /// Neues $ARGUMENTS erstellen
  Future<$ARGUMENTS> create($ARGUMENTS item) async {
    try {
      final response = await supabase
          .from('${ARGUMENTS.toLowerCase()}')
          .insert({
            ...item.toJson(),
            'tenantId': currentTenantId,  // KRITISCH!
          })
          .select()
          .single();

      return $ARGUMENTS.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'create');
      rethrow;
    }
  }

  /// $ARGUMENTS aktualisieren
  Future<$ARGUMENTS> update($ARGUMENTS item) async {
    try {
      final response = await supabase
          .from('${ARGUMENTS.toLowerCase()}')
          .update(item.toJson())
          .eq('id', item.id)
          .eq('tenantId', currentTenantId)  // KRITISCH!
          .select()
          .single();

      return $ARGUMENTS.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'update');
      rethrow;
    }
  }

  /// $ARGUMENTS löschen
  Future<void> delete(int id) async {
    try {
      await supabase
          .from('${ARGUMENTS.toLowerCase()}')
          .delete()
          .eq('id', id)
          .eq('tenantId', currentTenantId);  // KRITISCH!
    } catch (e, stack) {
      handleError(e, stack, 'delete');
      rethrow;
    }
  }
}
```

### 2. Provider erstellen

**Pfad:** `lib/core/providers/${ARGUMENTS.toLowerCase()}_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/${ARGUMENTS.toLowerCase()}_repository.dart';
import 'tenant_providers.dart';

/// Repository ohne Tenant (für interne Nutzung)
final ${ARGUMENTS.toLowerCase()}RepositoryProvider = Provider<${ARGUMENTS}Repository>((ref) {
  return ${ARGUMENTS}Repository(ref);
});

/// Repository mit Tenant-Kontext (für Features nutzen!)
final ${ARGUMENTS.toLowerCase()}RepositoryWithTenantProvider = Provider<${ARGUMENTS}Repository>((ref) {
  final repo = ref.watch(${ARGUMENTS.toLowerCase()}RepositoryProvider);
  final tenantId = ref.watch(currentTenantIdProvider);

  if (tenantId != null) {
    repo.setTenantId(tenantId);
  }

  return repo;
});

/// Alle ${ARGUMENTS}s laden
final ${ARGUMENTS.toLowerCase()}sProvider = FutureProvider<List<$ARGUMENTS>>((ref) async {
  final repo = ref.watch(${ARGUMENTS.toLowerCase()}RepositoryWithTenantProvider);
  if (!repo.hasTenantId) return [];
  return repo.getAll();
});

/// ${ARGUMENTS} per ID laden
final ${ARGUMENTS.toLowerCase()}ByIdProvider = FutureProvider.family<$ARGUMENTS?, int>((ref, id) async {
  final repo = ref.watch(${ARGUMENTS.toLowerCase()}RepositoryWithTenantProvider);
  if (!repo.hasTenantId) return null;
  return repo.getById(id);
});
```

### 3. Exports hinzufügen

**In `lib/data/repositories/repositories.dart`:**
```dart
export '${ARGUMENTS.toLowerCase()}_repository.dart';
```

**In `lib/core/providers/providers.dart`:**
```dart
export '${ARGUMENTS.toLowerCase()}_providers.dart';
```

### 4. KRITISCHE Multi-Tenant Regeln

**JEDE Supabase-Query MUSS `tenantId` filtern!**

```dart
// ✅ RICHTIG
.eq('tenantId', currentTenantId)

// ❌ FALSCH - Sicherheitslücke!
.select('*')  // ohne tenantId
```

**Bei INSERT immer tenantId setzen:**
```dart
.insert({
  ...item.toJson(),
  'tenantId': currentTenantId,
})
```

### 5. Realtime-Subscription (optional)

```dart
/// Echtzeit-Updates für ${ARGUMENTS}s
RealtimeChannel subscribe${ARGUMENTS}Changes(void Function() onChanged) {
  return supabase
      .channel('${ARGUMENTS.toLowerCase()}-changes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: '${ARGUMENTS.toLowerCase()}',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'tenantId',
          value: currentTenantId,
        ),
        callback: (_) => onChanged(),
      )
      .subscribe();
}
```