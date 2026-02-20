# Attendix Migration Status

## Übersicht

**Ionic Projekt:** `/Users/I576226/repositories/attendance` (~25K Zeilen TypeScript)
**Flutter Projekt:** `/Users/I576226/repositories/attendix`
**Migrationsfortschritt:** ~70% (Kern-Features + Statistics + Attendance Types)

---

## Abgeschlossene Phasen

### Phase 1: Shared Widgets & Utils ✅
- `lib/shared/widgets/display/avatar.dart` - Avatar mit Bild oder Initialen
- `lib/shared/widgets/display/status_badge.dart` - Farbcodierte Status-Badges
- `lib/shared/widgets/common/empty_state.dart` - Leerzustands-Widget
- `lib/core/utils/toast_helper.dart` - Toast-Nachrichten (success/error/info/warning)
- `lib/core/utils/dialog_helper.dart` - Bestätigungs- und Alert-Dialoge
- `lib/core/utils/date_helper.dart` - Deutsche Datumsformatierung (Heute, Morgen, etc.)

### Phase 2: Attendance Detail ✅
- `lib/features/attendance/presentation/pages/attendance_detail_page.dart`
  - Personen-Liste gruppiert nach Instrument
  - Tap → Status-Cycle (Present → Absent → Excused → etc.)
  - Long-Press → Selection Mode für Batch-Updates
  - "Alle anwesend" / "Alle abwesend" Quick-Actions
  - Speichern-Funktion mit Backend-Sync
- `lib/data/repositories/attendance_repository.dart`
  - `batchUpdatePersonAttendances()` hinzugefügt
- `lib/core/providers/attendance_providers.dart`
  - AttendanceNotifier mit Batch-Update-Support

### Phase 3: Self-Service Portal ✅
- `lib/data/repositories/sign_in_out_repository.dart` (NEU)
  - `signIn()`, `signOut()`, `updateAttendanceNote()`
  - `getAllPersonAttendancesAcrossTenants()` - Cross-Tenant Abfragen
  - `CrossTenantPersonAttendance` Model
- `lib/core/providers/self_service_providers.dart` (NEU)
  - `allPersonAttendancesAcrossTenantsProvider`
  - `upcomingAttendancesAcrossTenantsProvider`
  - `pastAttendancesAcrossTenantsProvider`
  - `currentAttendanceProvider`
  - `attendanceStatsProvider`
  - `SignInOutNotifier`
- `lib/features/self_service/presentation/pages/self_service_overview_page.dart` (NEU)
  - Statistik-Header (Anwesenheit %, Verspätungen)
  - Aktueller Termin Card mit Sign-In/Out Buttons
  - Kommende und vergangene Termine Listen
  - Gruppierung: Chronologisch oder nach Tenant

### Phase 4: Real-time Subscriptions ✅
- `lib/core/providers/realtime_providers.dart` (NEU)
  - `realtimePlayersProvider` - Live Player-Updates
  - `realtimeAttendancesProvider` - Live Attendance-Updates
  - `realtimeAttendanceDetailProvider` - Live Detail-Updates
  - `RealtimeManager` Klasse für manuelle Channel-Verwaltung

### Phase 5: Statistics & Charts ✅
- `lib/core/providers/statistics_providers.dart` (NEU)
  - `statisticsDateRangeProvider` - Zeitraum-Filter
  - `filteredAttendancesForStatsProvider` - Gefilterte Attendances
  - `allPersonAttendancesForStatsProvider` - Person-Attendance Daten
  - `attendanceStatisticsProvider` - Berechnete Statistiken
  - `trendChartDataProvider` - Trend Line Chart Daten
  - `groupChartDataProvider` - Instrument Bar Chart Daten
  - `topPlayersChartDataProvider` - Top 20 Spieler
  - `divaIndexChartDataProvider` - Unentschuldigte Abwesenheiten
  - `ageDistributionProvider` - Altersverteilung
  - `avgAgePerInstrumentProvider` - Durchschnittsalter pro Instrument
- `lib/features/statistics/presentation/pages/statistics_page.dart` (NEU)
  - 7 Charts mit fl_chart
  - Date Range Picker
  - Pull-to-refresh

### Phase 6.1: Attendance Types ✅
- `lib/features/settings/presentation/pages/attendance_types_page.dart` (NEU)
  - Liste aller Typen
  - Drag & Drop Reordering
  - Create-Dialog
- `lib/features/settings/presentation/pages/attendance_type_edit_page.dart` (NEU)
  - Name, Farbe, Zeiten bearbeiten
  - Default-Status und verfügbare Status
  - Optionen (manageSongs, visible, highlight, etc.)
  - Delete mit Bestätigung
- Routes: `/settings/types`, `/settings/types/:id`

---

## Ausstehende Phasen
- `lib/features/settings/presentation/pages/attendance_types_page.dart`
- Typen: Probe, Konzert, Generalprobe, etc.

#### 6.4 General Settings
- `lib/features/settings/presentation/pages/settings_page.dart`
- Tenant-Einstellungen, Benachrichtigungen, etc.

**Ionic Referenz:**
- `src/app/teacher/`
- `src/app/settings/`

---

### Phase 7: Advanced Features 🚀
**Priorität:** Niedrig
**Geschätzte Zeit:** 15-20 Stunden

#### 7.1 Song Detail mit PDF Viewer
- `lib/features/songs/presentation/pages/song_detail_page.dart`
- PDF-Anzeige für Noten
- **Dependency:** `flutter_pdfview` oder `syncfusion_flutter_pdfviewer`

#### 7.2 Export (PDF/Excel)
- `lib/core/services/export_service.dart`
- Anwesenheitslisten als PDF
- Statistiken als Excel
- **Dependencies:** `pdf`, `excel`

#### 7.3 History/Timeline
- `lib/features/history/presentation/pages/history_page.dart`
- Änderungsverlauf für Personen und Attendances

#### 7.4 Planning/Probenplan
- `lib/features/planning/presentation/pages/planning_page.dart`
- Kalender-Ansicht
- Termin-Erstellung

#### 7.5 Notifications
- Push-Benachrichtigungen
- Erinnerungen vor Terminen
- **Dependency:** `firebase_messaging`

---

## Noch nicht geplante Features

Diese Features existieren in Ionic, sind aber noch nicht im Migrationsplan:

1. **Parents Portal** - Eltern-Zugang für Minderjährige
2. **Registration Flow** - Neuen Spieler registrieren
3. **Handover Management** - Übergabe von Noten/Instrumenten
4. **Telegram Integration** - Bot für Benachrichtigungen
5. **Holiday Management** - Ferien-/Urlaubsverwaltung
6. **Instrument Matcher** - Automatische Instrumenten-Zuordnung

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
        .eq('tenantId', tenantId);
    return (response as List).map((e) => MyModel.fromJson(e)).toList();
  }
}
```

### Provider Pattern
```dart
final myRepositoryProvider = Provider<MyRepository>((ref) {
  return MyRepository(ref);
});

final myListProvider = FutureProvider<List<MyModel>>((ref) async {
  final repo = ref.watch(myRepositoryProvider);
  return repo.getAll();
});
```

### Realtime Pattern
```dart
final realtimeMyDataProvider = StreamProvider.autoDispose<List<MyModel>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);

  // Initial data
  yield await fetchInitialData();

  // Setup channel
  final channel = supabase.channel('my_channel')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      table: 'my_table',
      callback: (payload) async {
        controller.add(await fetchFreshData());
      },
    )
    .subscribe();

  ref.onDispose(() => channel.unsubscribe());

  await for (final data in controller.stream) {
    yield data;
  }
});
```

---

## Ionic Referenz-Dateien

| Feature | Ionic Datei | Zeilen |
|---------|-------------|--------|
| Attendance Detail | `src/app/attendance/attendance/attendance.page.ts` | ~470 |
| Self-Service | `src/app/selfService/overview/overview.page.ts` | ~403 |
| Statistics | `src/app/services/stats/stats.service.ts` | ~200 |
| Realtime | `src/app/services/db.service.ts` (350-450) | ~100 |
| Interfaces | `src/app/utilities/interfaces.ts` | ~500 |
| Constants | `src/app/utilities/Constants.ts` | ~150 |
| Utils | `src/app/utilities/Utils.ts` | ~300 |

---

## Nächste Schritte

1. **Entscheidung:** Welche Phase als nächstes?
   - Phase 5 (Statistics) für Datenvisualisierung
   - Phase 6 (Admin) für vollständiges Admin-Backend
   - Phase 7.x (einzelnes Feature) nach Bedarf

2. **Testing:** Bestehende Features testen
   - `flutter analyze` ausführen
   - Manuelle Tests auf Gerät/Emulator
   - Multi-User Realtime testen

3. **Router Integration:** Alle neuen Routes in `app_router.dart` hinzufügen

---

*Zuletzt aktualisiert: 2026-02-19*
