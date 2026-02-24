# Attendix Migration Status

## Übersicht

**Ionic Projekt:** `/Users/I576226/repositories/attendance` (~12.600 Zeilen TypeScript)
**Flutter Projekt:** `/Users/I576226/repositories/attendix` (~16.800 Zeilen Dart)
**Migrationsfortschritt:** ~75-80%

| Metrik | Wert |
|--------|------|
| Ionic Pages | 35 |
| Flutter Pages | 38 |
| Flutter Repositories | 8 |

*Zuletzt aktualisiert: 2026-02-24*

---

## Vollständig Migrierte Features ✅

| Feature | Status |
|---------|--------|
| Login/Auth | ✅ |
| Attendance List | ✅ |
| Attendance Detail | ✅ |
| Attendance Create | ✅ |
| People List | ✅ |
| Person Detail | ✅ |
| Person Create | ✅ |
| Members | ✅ |
| Statistics (7 Charts) | ✅ |
| Settings | ✅ |
| General Settings | ✅ |
| Attendance Types | ✅ |
| Self-Service | ✅ |
| Teachers | ✅ |
| Instruments | ✅ |
| Tenant Selection | ✅ |
| Notifications Page | ✅ |
| Notification Settings | ✅ |
| Voice Leader | ✅ |
| User Management | ✅ |
| Pending Players | ✅ |
| Left Players | ✅ |
| Registration | ✅ |
| Profile | ✅ |
| Parents Portal | ✅ |
| Calendar Subscription | ✅ |
| Songs (CRUD + Filter) | ✅ |
| History | ✅ |
| Export | ✅ |
| Planning (Basis) | ✅ |
| Meeting Detail | ✅ |

---

## Ausstehende Features

### Hohe Priorität 🔴

| Feature | Ionic-Dateien | Komplexität | Beschreibung |
|---------|---------------|-------------|--------------|
| Song Viewer (PDF) | `song-viewer.page.ts` | Mittel | PDF-Anzeige für Noten |
| Telegram Integration | `telegram.service.ts` | Mittel | Plan per Telegram senden |

### Mittlere Priorität 🟡

| Feature | Ionic-Dateien | Komplexität | Beschreibung |
|---------|---------------|-------------|--------------|
| Shifts/Schichtpläne | `shifts.page.ts`, `shift.service.ts` | Mittel | Schichtplan-Verwaltung |
| Handover | `handover.page.ts`, `handover.service.ts` | Mittel | Spieler zu anderem Tenant übertragen |
| Sign-out Page | `signout.page.ts` | Niedrig | Abmelde-Flow |

### Niedrige Priorität 🟢

| Feature | Komplexität | Beschreibung |
|---------|-------------|--------------|
| Holiday Service | Niedrig | Feiertage/Schulferien anzeigen |
| AI Service | Niedrig | GPT-basierte Gruppen-Synonyme |
| Cross-Tenant | Mittel | Daten zwischen Tenants teilen |
| Feedback Service | Niedrig | Feedback-Funktion |

---

## Services-Migrationsstatus

| Ionic Service | Flutter Equivalent | Status |
|---------------|-------------------|--------|
| `attendance.service.ts` | `attendance_repository.dart` | ✅ |
| `attendance-type.service.ts` | `attendance_type_repository.dart` | ✅ |
| `player.service.ts` | `player_repository.dart` | ✅ |
| `teacher.service.ts` | `teacher_repository.dart` | ✅ |
| `group.service.ts` | `group_repository.dart` | ✅ |
| `sign-in-out.service.ts` | `sign_in_out_repository.dart` | ✅ |
| `song.service.ts` | `song_repository.dart` | ✅ |
| `holiday.service.ts` | `holiday_service.dart` | ✅ |
| `meeting.service.ts` | `meeting_repository.dart` | ✅ |
| `shift.service.ts` | - | ❌ |
| `handover.service.ts` | - | ❌ |
| `telegram.service.ts` | `telegram_service.dart` | ⚠️ Teilweise |
| `ai.service.ts` | - | ❌ |
| `cross-tenant.service.ts` | - | ❌ |

---

## Empfohlene Migrationsreihenfolge

### Phase 1: Vervollständigung (1-2 Stunden)
1. **Meeting Detail Page** - Einfache CRUD-Seite
2. **Sign-out Page** - Nutzt vorhandene Providers

### Phase 2: Erweiterungen (3-5 Stunden)
3. **Song Viewer mit PDF** - Package evaluieren
4. **Planning Telegram-Versand** - Service existiert

### Phase 3: Neue Features (5-8 Stunden)
5. **Handover System** - Cross-tenant Logik
6. **Shifts/Schichtpläne** - Falls benötigt

### Phase 4: Nice-to-Have (2-4 Stunden)
7. **Holiday Integration** - Feiertage in Kalender
8. **AI Service** - GPT-Synonyme

---

## Untracked Dateien (zum Committen)

Diese Dateien wurden kürzlich erstellt:
- `lib/core/providers/conductor_providers.dart`
- `lib/core/providers/holiday_providers.dart`
- `lib/core/providers/song_filter_providers.dart`
- `lib/core/providers/song_providers.dart`
- `lib/core/services/holiday_service.dart`
- `lib/core/utils/shift_utils.dart`
- `lib/data/models/song/song_filter.dart`
- `lib/data/repositories/song_repository.dart`
- `lib/features/songs/presentation/pages/song_create_page.dart`
- `lib/features/songs/presentation/pages/song_edit_page.dart`
- `lib/features/songs/presentation/widgets/`
- `lib/features/attendance/presentation/widgets/`

---

## Nächste Schritte

- [x] Meeting Detail Page erstellen (`/meetings/:id`)
- [ ] PDF-Viewer evaluieren (flutter_pdfview vs syncfusion)
- [ ] Telegram-Versand vervollständigen
- [ ] Untracked Dateien committen
- [ ] Shifts-Feature prüfen (wird es benötigt?)

---

## Wichtige Patterns

### Repository Pattern
```dart
class MyRepository extends BaseRepository with TenantAwareRepository {
  MyRepository(super.ref);

  Future<List<MyModel>> getAll() async {
    final response = await supabase
        .from('my_table')
        .select()
        .eq('tenantId', currentTenantId);  // KRITISCH!
    return (response as List).map((e) => MyModel.fromJson(e)).toList();
  }
}
```

### Provider Pattern
```dart
final myListProvider = FutureProvider<List<MyModel>>((ref) async {
  final repo = ref.watch(myRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return [];
  return repo.getAll();
});
```

---

## Ionic Referenz-Dateien

| Feature | Ionic Datei | Zeilen |
|---------|-------------|--------|
| Attendance Detail | `attendance/attendance.page.ts` | ~470 |
| Self-Service | `selfService/overview/overview.page.ts` | ~403 |
| Planning | `planning/planning.page.ts` | ~610 |
| Statistics | `services/stats/stats.service.ts` | ~200 |
| Songs | `songs/songs.page.ts` | ~500 |
| Handover | `handover/handover.page.ts` | ~180 |
| Shifts | `shifts/shifts.page.ts` | ~250 |