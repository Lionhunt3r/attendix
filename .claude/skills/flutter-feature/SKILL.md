---
name: flutter-feature
description: Create a new Flutter feature with proper Riverpod architecture. Use when adding new app functionality.
argument-hint: [feature-name]
disable-model-invocation: false
allowed-tools: Read, Write, Edit, Bash
---

# Flutter Feature Generator

Erstellt ein neues Feature mit korrekter Architektur für das Attendix-Projekt.

## Feature: $ARGUMENTS

### 1. Ordnerstruktur erstellen

```
lib/features/$ARGUMENTS/
├── presentation/
│   ├── pages/
│   │   └── ${ARGUMENTS}_page.dart
│   └── widgets/
│       └── (optional: custom widgets)
```

### 2. Page-Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/loading/list_skeleton.dart';
import '../../../../shared/widgets/display/empty_state_widget.dart';
import '../../../../shared/widgets/animations/animated_list_item.dart';

class ${ARGUMENTS}Page extends ConsumerStatefulWidget {
  const ${ARGUMENTS}Page({super.key});

  @override
  ConsumerState<${ARGUMENTS}Page> createState() => _${ARGUMENTS}PageState();
}

class _${ARGUMENTS}PageState extends ConsumerState<${ARGUMENTS}Page> {
  @override
  Widget build(BuildContext context) {
    // final dataAsync = ref.watch(${ARGUMENTS.toLowerCase()}Provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('${ARGUMENTS}'),
      ),
      body: const Center(
        child: Text('${ARGUMENTS} Feature'),
      ),
    );
  }
}
```

### 3. Route hinzufügen

In `lib/core/router/app_router.dart`:

```dart
GoRoute(
  path: '/${ARGUMENTS.toLowerCase()}',
  builder: (context, state) => const ${ARGUMENTS}Page(),
),
```

### 4. Provider erstellen (falls benötigt)

In `lib/core/providers/${ARGUMENTS.toLowerCase()}_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/${ARGUMENTS.toLowerCase()}_repository.dart';

// Daten laden
final ${ARGUMENTS.toLowerCase()}Provider = FutureProvider<List<Model>>((ref) async {
  final repo = ref.watch(${ARGUMENTS.toLowerCase()}RepositoryWithTenantProvider);
  if (!repo.hasTenantId) return [];
  return repo.getAll();
});

// Mit Parameter
final ${ARGUMENTS.toLowerCase()}ByIdProvider = FutureProvider.family<Model?, int>((ref, id) async {
  final repo = ref.watch(${ARGUMENTS.toLowerCase()}RepositoryWithTenantProvider);
  if (!repo.hasTenantId) return null;
  return repo.getById(id);
});
```

### 5. UI-Konventionen

- **Labels auf Deutsch**: Speichern, Abbrechen, Löschen, Fehler, etc.
- **Loading State**: Immer `ListSkeleton()` oder `CircularProgressIndicator()` zeigen
- **Error State**: `EmptyStateWidget` mit Icon und Fehlermeldung
- **Empty State**: `EmptyStateWidget` mit passendem Icon und Text
- **Animations**: `AnimatedListItem` für Listen verwenden

### 6. PWA-Kompatibilität

Native APIs immer in try-catch wrappen:

```dart
try {
  await HapticFeedback.lightImpact();
} catch (_) {
  // Not available in PWA
}
```

### 7. Nach dem Erstellen

1. Route in `app_router.dart` hinzufügen
2. Falls Provider erstellt: In `providers.dart` exportieren
3. Falls Model erstellt: `dart run build_runner build --delete-conflicting-outputs`
4. Testen mit `flutter run -d chrome`