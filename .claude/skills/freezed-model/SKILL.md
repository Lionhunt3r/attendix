---
name: freezed-model
description: Create a new Freezed model with JSON serialization. Use when adding new data models.
argument-hint: [model-name]
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash
---

# Freezed Model Generator

Erstellt ein neues Freezed-Model für das Attendix-Projekt.

## Model: $ARGUMENTS

### 1. Ordnerstruktur

```
lib/data/models/${ARGUMENTS.toLowerCase()}/
├── ${ARGUMENTS.toLowerCase()}.dart
├── ${ARGUMENTS.toLowerCase()}.freezed.dart  (generiert)
└── ${ARGUMENTS.toLowerCase()}.g.dart        (generiert)
```

### 2. Model-Template

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '${ARGUMENTS.toLowerCase()}.freezed.dart';
part '${ARGUMENTS.toLowerCase()}.g.dart';

@freezed
class $ARGUMENTS with _$$ARGUMENTS {
  const factory $ARGUMENTS({
    required int id,
    required int tenantId,
    // TODO: Add fields
    DateTime? created,
  }) = _$ARGUMENTS;

  factory $ARGUMENTS.fromJson(Map<String, dynamic> json) =>
      _$${ARGUMENTS}FromJson(json);
}
```

### 3. Häufige Patterns

**Mit Default-Werten:**
```dart
@Default(false) bool isActive,
@Default([]) List<String> tags,
```

**Mit JSON-Key-Mapping:**
```dart
@JsonKey(name: 'first_name') String firstName,
@JsonKey(name: 'created_at') DateTime? createdAt,
```

**Mit Enum:**
```dart
@JsonKey(unknownEnumValue: Status.unknown) Status status,
```

**Nullable vs Required:**
```dart
required int id,        // Muss vorhanden sein
String? description,    // Optional, kann null sein
@Default('') String name,  // Optional mit Default
```

### 4. Code generieren

Nach dem Erstellen IMMER ausführen:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Model exportieren

In `lib/data/models/models.dart` hinzufügen:

```dart
export '${ARGUMENTS.toLowerCase()}/${ARGUMENTS.toLowerCase()}.dart';
```

### 6. Beispiel: Person-Model

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'person.freezed.dart';
part 'person.g.dart';

@freezed
class Person with _$Person {
  const factory Person({
    required int id,
    required int tenantId,
    @JsonKey(name: 'firstName') required String firstName,
    @JsonKey(name: 'lastName') required String lastName,
    String? email,
    int? instrument,
    @Default(false) bool isLeader,
    @JsonKey(name: 'created') DateTime? created,
  }) = _Person;

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}
```

### 7. Wichtige Hinweise

- **tenantId**: Fast jedes Model braucht `tenantId` für Multi-Tenant-Support
- **Naming**: Verwende camelCase in Dart, JSON-Keys können snake_case sein
- **Immutability**: Freezed-Models sind immutable, nutze `copyWith` für Änderungen
- **Nach Änderungen**: IMMER `build_runner` ausführen!