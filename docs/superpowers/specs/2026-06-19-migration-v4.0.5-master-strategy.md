# Migration v4.0.5 — Master Spec & Sprint-Strategie

**Datum:** 2026-06-19
**Autor:** Brainstorming-Session mit Leon
**Bezug:** Re-Crawl `.claude/migration-crawl-report.md` (315 Findings, 30 KRITISCH, 101 HOCH)
**Status:** Draft → User-Review pending

---

## 1. Ziel & Scope

**Ziel:** Die bestehende Flutter-Codebase systematisch und in der "besten Art und Weise" auf den Stand der Ionic-App v4.0.5 bringen — und dabei die identifizierten Architektur-Schulden (Repository-Bypass, fehlende Cross-Cutting Services, DSGVO-Lücken) sauber beheben statt parallel weiterzuwachsen.

**Was NICHT in dieser Spec ist:**
- Greenfield-Neuanfang (verworfen)
- Parallele Worktrees pro Sprint (verworfen — Sprints bauen aufeinander auf, Merge-Konflikt-Risiko)
- Long-Tail-Findings (118 MITTEL + 66 NIEDRIG) — die werden nach Sprint 12 als laufende Wochen-Tickets bearbeitet

**Erfolgs-Kriterium:** Nach Abschluss aller Sprints ist die Flutter-App
- App-Store-Compliance (DSGVO, Legal)
- Funktional auf v4.0.5-Niveau (alle KRITISCH + HOCH-Findings adressiert)
- Architektonisch sauber (kein Repository-Bypass, keine Force-Unwraps auf `tenant.id!`, alle Cross-Cutting Services vorhanden)
- Test-Coverage gewahrt (`flutter test` grün, `dart analyze` ohne Warnings)

---

## 2. Vorgehensmodell

### 2.1 Plan-Driven, Sprint-by-Sprint sequenziell

```
Phase A — Brainstorming (abgeschlossen mit dieser Spec)
   ↓
Phase B — Pro Sprint:
   1. Sprint-Verifikation (3 Iterationen, siehe 2.3)
   2. /writing-plans → detaillierter Implementation-Plan
   3. User-Review des Plans (Stop-Punkt)
   4. /executing-plans oder direkter TDD-Workflow
   5. Tests grün + dart analyze ok
   6. Code-Review (flutter-reviewer + pr-review-toolkit:code-reviewer parallel)
   7. Version-Bump + Memory-Update
   8. User-Review (Stop-Punkt vor Merge)
   9. Merge zu master, Issue schließen
```

**Begründung:** Die 12 Sprints bauen aufeinander auf — Sprint 1 (Cross-Cutting Services) ist Foundation für mind. 5 spätere Sprints. Parallel-Arbeit würde Merge-Konflikte produzieren. Sequenzielles Arbeiten mit klaren Stop-Punkten ist langsamer aber risikoärmer.

### 2.2 Sprint-Workflow im Detail

```
PRE-SPRINT:
  ├─ Worktree erstellen: .worktrees/sprint-N-<short-name>
  ├─ .env-Datei in Worktree kopieren (gitignored)
  ├─ Sprint-Verifikation (siehe 2.3)
  ├─ /writing-plans für detaillierten Plan
  ├─ User-Review des Plans (STOP-PUNKT)
  └─ TaskCreate für jede Plan-Task

EXECUTION (TDD wo möglich):
  ├─ Pro Task: Test schreiben → Code → Test grün
  ├─ dart analyze nach jedem größeren Schritt
  ├─ flutter test nach jedem größeren Schritt
  └─ Memory-Updates wenn neue Patterns auftauchen

PRE-MERGE:
  ├─ flutter test --coverage (alle Tests grün, Coverage gehalten)
  ├─ dart analyze lib/ (keine Warnings)
  ├─ Code-Review parallel:
  │    • flutter-reviewer Agent
  │    • pr-review-toolkit:code-reviewer Agent
  ├─ Findings durcharbeiten
  ├─ Version-Bumps:
  │    • pubspec.yaml
  │    • assets/version_history.json (mit Sprint-Description in deutscher Sprache)
  │    • lib/core/constants/app_constants.dart (appVersion)
  └─ User-Review (STOP-PUNKT vor Merge)

MERGE:
  ├─ Commit mit ausführlichem Body (was, warum, welche Issues)
  ├─ Push, ggf. PR
  ├─ Merge zu master
  ├─ Worktree aufräumen (entfernen oder keep nach User-Wunsch)
  └─ GitHub Issue schließen mit Verweis auf merged commit/PR

POST-SPRINT:
  ├─ Memory updaten (was haben wir gelernt?)
  ├─ Migration-Status-Memo aktualisieren
  └─ Master-Tracking-Issue #222 updaten
```

### 2.3 Verifikations-Regel (3 Iterationen pro Sprint)

**Bevor /writing-plans aufgerufen wird, muss jeder Sprint diese 3 Iterationen durchlaufen:**

1. **Iteration 1 — Erstentwurf aus Re-Crawl:** Findings, Effort, geplante Komponenten
2. **Iteration 2 — Verifikation:** Explore-Agent (oder paralleler Agent) liest tatsächliche Ionic-Implementierung + relevanten Flutter-Code, prüft:
   - Sind die geplanten Komponenten wirklich nötig?
   - Welche Dependencies/Schemas/Edge-Functions sind betroffen?
   - Was ist im Flutter-Projekt schon vorhanden (pubspec, /core/services, /data/repositories)?
   - Welche Plattform-spezifischen Setups (iOS/Android/Web) fehlen?
   - Welche Edge-Cases übersieht der Erstentwurf?
3. **Iteration 3 — Korrigierter Plan:** Effort-Korrektur, Sub-Sprint-Splits falls nötig, Edge-Cases ergänzt, externe Pre-Conditions identifiziert

**Beispiel aus Sprint 1 (siehe Anhang):** Erstentwurf 25h → nach Verifikation 40h. Push war 16h geplant, realistisch 24-32h weil Firebase-Setup im Flutter-Projekt komplett fehlt.

### 2.4 Constraints (gelten für ALLE Sprints)

- ✅ **Tests müssen grün bleiben** (`flutter test` + `dart analyze`)
- ✅ **Version-Bumps pro Sprint** (`pubspec.yaml` + `version_history.json` + `app_constants.dart`)
- ✅ **Code-Review parallel** (`flutter-reviewer` + `pr-review-toolkit:code-reviewer`)
- ✅ **Worktree-Isolation pro Sprint** (`.worktrees/sprint-N-<name>`)
- ✅ **Stop-Punkte für User-Review:** vor Code-Start (Plan-Review), vor Merge (Code-Review)

---

## 3. Sprint-Reihenfolge (mit Begründung)

> **Update 2026-06-19 (nach Sprint 1a):** Sprint 1b (Push-Foundation) wurde nach hinten geschoben, weil externe Pre-Conditions (Firebase-Projekt-Setup, APNS-Auth-Key, physisches iPhone) zum Zeitpunkt nicht verfügbar sind. Sprint 4 wurde in **4a** (ohne Push) und **4b** (mit Push, gemeinsam mit 1b) aufgeteilt. Tracking-Aufrufstellen (`pushReceived/pushOpened`) bleiben bis 1b ungenutzt — kein Funktions-Verlust für andere Sprints.

| # | Sprint | Effort (verifiziert) | Issues | Begründung Reihenfolge |
|---|--------|---------------------|--------|------------------------|
| 1a | **Tracking + Audio Foundation** ✅ DONE | ~38h actual | #220 partial | Merged 2026-06-19, commit 4edf10f. |
| 2 | **Repository-Bypass-Refactor** | ~30h | #219 | Saubere Architektur bevor neue Pages dazukommen. Touched 20+ Files quer durch alle Features. |
| 3 | **DSGVO-Compliance** | ~21h | #211, #215 partial | Erst nach Sprint 2 möglich (saubere AuthService-Basis), Tracking-Event `accountDeleted` ist da (Sprint 1a). App-Store-Submission danach möglich. |
| 4a | **Cold-Start (ohne Push) + Reasons + Conductor + Tenant-Auto-Close** | ~8.5h | #213 partial | User-sichtbare Attendance-Bugs die NICHT von PushService abhängen: B2-007 Notiz-ActionSheet (3h), B2-008 Conductor-Wechsel (4h), B2-009 Tenant-Auto-Close (1.5h). |
| 5 | **Cross-Tenant Person-Matching** | ~37.5h | #214 | Eigenes großes Feature, profitiert von sauberer Repository-Basis aus Sprint 2. |
| 6 | **Settings-Hub + Files + Shifts** | ~25h | #217 | Files-Page nutzt AudioPlayerService aus 1a. |
| 7 | **Bulk-Edit + Role-Permissions** | ~48h | #218, #221 | Beide brauchen Tracking + Repository-Layer. Eventuell weiter splitten. |
| 8 | **Songs Public-Sharing + Audio** | ~19.5h | #216 | AudioPlayer ist da (Sprint 1a), Public-Routing. |
| 9 | **Statistics + Export Bug-Fixes** | ~9h | #215, #216 partial | Quick wins für sichtbare Stats-Korrektheit. |
| 10 | **People Workflows** | ~22h | aus Report | isLeader-Dialog, Email-Account, syncPlayerWithUpcoming. |
| 11 | **Sign-Out Reasons + Description-Modal** | ~24h | aus Report | tenant.absence_reasons + 4× Custom-Reason-Bug zentralisieren. |
| 12 | **Attendance Workflows** | ~15h | aus Report | iOS-FAB, Personen-hinzufügen, Anhang, Status-Mapping. |
| 1b | **Push-Foundation** | ~28h | #212, #220 partial | **Pre-Conditions:** Firebase-Projekt-Audit, APNS-Key, iPhone. Foundation für 4b. |
| 4b | **Cold-Start Push + getAttendanceByIdRobust** | ~7h | #213 partial | B2-010 RLS-Race nach Push-Auth-Restore (4h) + B2-032 Robust-Fetch (3h). Nur sinnvoll mit funktionierendem PushService aus 1b. |
| 13 | **Long Tail** | laufend | viele | 118 MITTEL + 66 NIEDRIG als Wochen-Tickets. |

**Gesamt-Effort:** ~315h (unverändert; Sprint 4 nur gesplittet, nicht reduziert).

**Wichtige Reihenfolge-Entscheidungen:**

- **DSGVO als Sprint 3, nicht zuerst** — entgegen ursprünglicher Empfehlung im Crawl-Report (dort als "Sprint 0" priorisiert). Begründung: Delete-Account-Page braucht TrackingService (`AccountDeleted`-Event) aus Sprint 1a und sauberen AuthService aus Sprint 2. Wenn DSGVO zuerst gemacht wird, müsste sie später nochmal angefasst werden.
- **Sprint 2 (Bypass-Refactor) früh** — bevor neue Pages dazukommen, sonst werden neue Bypass-Stellen eingebaut.
- **Sprint 7 (Bulk-Edit + Role-Permissions) eventuell splitten** — 48h ist viel. Bei /writing-plans entscheiden ob 7a/7b.

---

## 4. Sprint 1 — Detail (verifiziert, Vorlage für andere Sprints)

> Diese Sektion ist beispielhaft ausführlich, weil Sprint 1 als Erstes durchgeführt wird und gleichzeitig die Vorlage für die Verifikation aller weiteren Sprints ist.

### 4.1 Sprint 1a — Tracking + Audio Foundation

**Pre-Conditions:**
- Sauberer Master-Branch
- Worktree `.worktrees/sprint-1a-tracking-audio` erstellt
- `.env` ins Worktree kopiert

**Komponenten:**

#### 4.1.1 TrackingService (~5h, korrigiert von 3h)

```
lib/core/services/tracking_service.dart
lib/core/services/tracking_event.dart       (Enum mit allen 27 Events)
lib/data/repositories/usage_events_repository.dart
lib/data/models/usage_event.dart            (Freezed)
lib/core/router/tracking_observer.dart      (GoRouter NavigatorObserver)
test/core/services/tracking_service_test.dart
test/data/repositories/usage_events_repository_test.dart
```

**Kernfunktion:**
```dart
Future<void> track(TrackingEvent event, {Map<String, dynamic>? properties});
```

Fire-and-forget via `unawaited()`, Try-Catch swallow.

**Alle 27 TrackingEvents** (vollständige Liste aus tracking.service.ts:6-44):
```dart
enum TrackingEvent {
  pageView,
  login,
  attendanceCheckIn,
  attendanceCheckOut,
  parentSignIn,
  parentSignOut,
  pushReceived,
  pushOpened,
  meetingCreated,
  songShared,
  reportExported,
  handoverCreated,
  playerAdded,
  playerUpdated,
  playerRemoved,
  teacherAdded,
  teacherUpdated,
  instrumentAdded,
  instrumentUpdated,
  instrumentRemoved,
  notificationSettingsChanged,
  fileUploaded,
  accountDeleted,
  attendanceFetchAttempt,
  attendanceFetchStageB,
  attendanceFetchResolved,
  attendanceFetchModifyThrow,
  attendanceTypeUnresolved,
  attendanceSecondaryInitFailed,
}
```

**Device-Type-Detection:**
```dart
String _deviceType() {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'web';  // Fallback
}
```

**GoRouter-Observer für `pageView`:**
```dart
class TrackingObserver extends NavigatorObserver {
  // Bei jedem didPush/didReplace:
  // - Filter: NICHT bei /login, /legal (analog app.component.ts:185)
  // - tracking.track(TrackingEvent.pageView, {'route': route.settings.name})
}
```

**KEINE Aufrufstellen in dieser Sprint-Phase.** Nur Service + Observer + 1 Aufruf in `app.component`-Equivalent (für Page-Tracking). Die 36 weiteren Call-Sites kommen in den späteren Sprints automatisch (z.B. `attendance.checkIn` in Sprint 4, `account.deleted` in Sprint 3).

**Tests:**
- Mock-Supabase, prüfe Insert-Payload-Struktur
- Device-Type-Detection für iOS/Android/Web
- Filter-Logik (/login, /legal werden NICHT getrackt)
- Fire-and-forget swallowt Fehler ohne UI-Crash

#### 4.1.2 AudioPlayerService + Widget (~5h)

```
lib/core/services/audio_player_service.dart
lib/shared/widgets/audio_player_widget.dart
test/core/services/audio_player_service_test.dart
```

**Dependency:** `just_audio: ^0.9.x` (NEU in pubspec.yaml).

**Pre-Condition iOS:** `Info.plist` muss `UIBackgroundModes` mit `audio` enthalten — entscheiden ob Background-Audio gewollt ist (Default: ja, Ionic spielt ebenfalls im Hintergrund).

**API:**
```dart
class AudioPlayerService {
  Stream<AudioPlayerState> get stateStream;
  
  Future<void> play(SongFile file, {String? title});
  Future<void> playFromUrl(String url, {String? title});
  void togglePlayPause();
  void stop();
  void seek(Duration position);
  void startSeeking();
  void stopSeeking(Duration position);
  
  static bool isAudioFile(String filename); // mp3/wav/ogg/m4a/aac/flac/wma/webm/opus
  static String formatTime(Duration d);     // mm:ss
}
```

**State (Riverpod Notifier):**
```dart
class AudioPlayerState {
  final SongFile? currentFile;
  final String? currentTitle;
  final bool isPlaying;
  final Duration currentTime;
  final Duration duration;
  final bool isSeeking;
}
```

**Wichtig — Korrekturen aus Verifikation:**
- `progress` 0-100 NICHT übernehmen — stattdessen `currentTime/duration` direkt nutzen, redundanten State vermeiden.
- `isSeeking`-Flag MUSS erhalten bleiben, sonst springt Slider während Drag zurück.
- Web-CORS: Supabase Storage `getPublicUrl` statt signed URLs verwenden, sonst Web-Audio kaputt.

**AudioPlayerWidget** (Mini-Bar in Tabs-Shell):
- Play/Pause-Button, Progress-Slider, Zeit-Anzeige (currentTime / duration)
- Versteckt wenn `currentFile == null`
- In `lib/shared/widgets/app_scaffold.dart` (oder vergleichbarer Tabs-Shell) eingebaut
- **WICHTIG:** Wird in dieser Sprint-Phase eingebaut, weil spätere Sprints (Songs, Self-Service, Files) es voraussetzen — Refactor-Vermeidung.

**Tests:**
- Mock just_audio
- isAudioFile-Helper für alle 9 Extensions
- formatTime für 0:00, 1:30, 12:45
- isSeeking verhindert State-Update während Drag

#### 4.1.3 Akzeptanz-Kriterien Sprint 1a

- [ ] `flutter test` grün (alle Tests, inklusive neue)
- [ ] `dart analyze lib/` ohne Warnings
- [ ] `flutter run -d chrome` läuft
- [ ] AudioPlayerWidget sichtbar in Tabs-Shell wenn aktiv
- [ ] Beide Code-Reviewer geben Freigabe
- [ ] Version: `0.2.0+29` (Minor-Bump, neue Architektur-Komponenten)
- [ ] Issue #220 Status-Update (TrackingService + AudioPlayer-Foundation erledigt, Dashboard fehlt noch)

---

### 4.2 Sprint 1b — Push-Foundation

**Pre-Conditions (KRITISCH, müssen VOR Code-Start geklärt sein):**

1. **Firebase-Projekt-Audit:**
   - Existiert ein Firebase-Projekt für Bundle-ID `de.attendix.attendix`?
   - Falls nein: Anlegen + Apps konfigurieren (iOS + Android)
   - `GoogleService-Info.plist` (iOS) und `google-services.json` (Android) downloaden
2. **APNS-Auth-Key:**
   - Apple Developer Account: `.p8`-Auth-Key erstellt?
   - In Firebase-Console hochgeladen?
   - Bundle-ID hat Push-Capability im Provisioning-Profile?
3. **Test-Device verfügbar:** Physisches iPhone (Push funktioniert NICHT im Simulator)

**Wenn eine der drei Pre-Conditions nicht erfüllt ist: Sprint 1b STOP — User-Aktion erforderlich.**

**Komponenten:**

#### 4.2.1 Native-Setup

**iOS (`ios/Runner/`):**
- `AppDelegate.swift`: Firebase init + APNS-Token-Forwarding zu Firebase Messaging
- `Info.plist`: `UIBackgroundModes` mit `remote-notification`
- `Runner.entitlements`: `aps-environment` = `development` / `production`
- `GoogleService-Info.plist` ins Runner-Bundle einbinden
- `Podfile`: `pod 'Firebase/Messaging'`

**Android (`android/app/`):**
- `build.gradle.kts`: `google-services` Plugin
- `AndroidManifest.xml`: `<service>` für FCM, `POST_NOTIFICATIONS` Permission (Android 13+)
- `google-services.json` in `android/app/`

**Web (`web/`):**
- `firebase-messaging-sw.js` Service-Worker (für PWA-Push)

#### 4.2.2 Dart-Code

```
lib/core/services/push_service.dart
lib/data/repositories/device_tokens_repository.dart
lib/data/models/device_token.dart  (Freezed)
lib/core/providers/push_providers.dart
test/core/services/push_service_test.dart
```

**Dependencies:**
```yaml
firebase_core: ^3.x
firebase_messaging: ^15.x
flutter_local_notifications: ^17.x
flutter_app_badger: ^1.5.x  # oder app_badge_plus
```

**API:**
```dart
class PushService {
  Future<bool> promptAndEnable();
  Future<void> initPush();
  Future<void> removeToken();
  Future<void> togglePush(bool enabled);
}

// Riverpod-Providers für Cold-Start-Race
final pendingPushDataProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final pendingAttendanceIdProvider = StateProvider<int?>((ref) => null);
```

**iOS Token-Race-Handling (KRITISCH, exakt analog zu push.service.ts:103-161):**

```dart
Future<String?> _getIOSToken() async {
  // 1. APNS-Token zuerst (wartet auf didRegisterForRemoteNotifications via AppDelegate)
  final apnsToken = await FirebaseMessaging.instance
      .getAPNSToken()
      .timeout(Duration(seconds: 10));
  if (apnsToken == null) {
    // Tracking-Event: pushTokenFailed
    return null;
  }
  // 2. Erst danach FCM-Token holen
  return await FirebaseMessaging.instance.getToken();
}
```

**Token-Save-Logik (Single-Device, exakt wie Ionic push.service.ts:396-418):**

1. Lösche dieses Token bei anderen User-IDs (1 Token = 1 User)
2. Lösche andere Tokens dieses Users (1 User = 1 Token)
3. Upsert `device_tokens` mit `user_id`, `token`, `platform` ('ios'/'android'/'web'), `updated_at`

**Cold-Start-Routing-Logik:**

```dart
Future<void> _handleInitialMessage() async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial == null) return;
  
  // Push wurde aus Cold-Start geöffnet
  // → Pending-State setzen, AuthGuard wartet bis tenant geladen
  ref.read(pendingPushDataProvider.notifier).state = initial.data;
  if (initial.data['type'] == 'attendance' && initial.data['attendanceId'] != null) {
    ref.read(pendingAttendanceIdProvider.notifier).state = 
        int.parse(initial.data['attendanceId']);
  }
  
  // Tracking
  await tracking.track(TrackingEvent.pushOpened, {
    'type': initial.data['type'],
    'cold_start': true,
  });
}
```

**Auth-Guard-Integration:** AuthGuard muss nach erfolgreichem `checkToken()` + Tenant-Load `consumePendingPushData()` aufrufen, das die Navigation triggert (analog app.component.ts:64-71).

**Routing nach `data.type` (push.service.ts:266-323):**

```dart
void _route(Map<String, dynamic> data) {
  final type = data['type'];
  final tenantId = data['tenantId'] as int?;
  
  // Tenant-Switch falls anderer Tenant
  if (tenantId != null && tenantId != currentTenant.id) {
    setTenant(tenantId);
  }
  
  switch (type) {
    case 'attendance':
      final attId = data['attendanceId'];
      switch (currentRole) {
        case Role.admin:
        case Role.responsible:
        case Role.helper:
          context.go('/attendance/$attId');
        case Role.parent:
          context.go('/parents');  // mit pendingAttendanceId
        default:
          context.go('/signout');  // mit pendingAttendanceId
      }
    case 'reminder':
    case 'checklist':
    case 'birthday':
    case 'criticals':
      // Analog routen
  }
}
```

**Foreground-Notification:** Custom Dialog (kein nativer Alert) mit Notification-Title + Body, Tap → gleiche Routing-Logik.

#### 4.2.3 Akzeptanz-Kriterien Sprint 1b

- [ ] Pre-Conditions erfüllt (Firebase-Projekt + APNS-Key + iPhone)
- [ ] `flutter test` grün
- [ ] `dart analyze lib/` ohne Warnings
- [ ] `flutter run -d <iPhone>` läuft, erhält FCM-Token (im Log sichtbar)
- [ ] Test-Push aus Firebase-Console wird im Foreground empfangen → Custom-Dialog
- [ ] Test-Push wird im Cold-Start empfangen → korrekte Navigation nach `data.type`
- [ ] Test-Push wird im Background-Open empfangen → korrekte Navigation
- [ ] `device_tokens` Tabelle: ein Token pro User, ein User pro Token (Single-Device)
- [ ] Beide Code-Reviewer geben Freigabe
- [ ] Issue #212 geschlossen, Issue #220 final geschlossen (alles aus Sprint 1)
- [ ] Version: `0.2.1+30` (Patch-Bump, additive Features)

---

## 5. Sprint 2-12 — Grobkörnig (werden vor Start verifiziert)

Für die Sprints 2-12 gilt: **Vor jedem Sprint-Start läuft die 3-Iterationen-Verifikation aus Abschnitt 2.3.** Die Detail-Spec für jeden Sprint entsteht erst dort. Die folgende Übersicht ist Iteration 1 (Erstentwurf) — sie wird sich beim Sprint-Start ändern.

### Sprint 2: Repository-Bypass-Refactor (~30h)

**Issue:** #219
**Ziel:** ~20 Stellen migrieren, die direkt `supabaseClientProvider` nutzen statt Repositories.

**Stellen (verifiziert aus Re-Crawl):**
- `attendance_detail_page.dart` (11 Calls)
- `person_detail_page.dart` (3 Calls)
- `members_providers.dart`, `parents_providers.dart`, `upcoming_songs_provider.dart`
- `copy_to_tenant_sheet.dart`, `copy_shift_to_tenant_sheet.dart`, `handover_sheet.dart`
- `planning_page.dart`, `history_page.dart`, `general_settings_page.dart`
- `profile_page.dart`, `user_management_page.dart`
- `voice_leader_providers.dart` (Defense-in-Depth)
- `self_service_providers.dart`

**Vorgehen:**
1. Für jede Stelle: passendes WithTenant-Repository identifizieren oder neu erstellen
2. Direkten Supabase-Call durch Repository-Aufruf ersetzen
3. `hasTenantId`-Check ergänzen
4. Tests anpassen / ergänzen
5. **Lint-Regel** ergänzen: `ref.read(supabaseClientProvider)` außerhalb von `lib/data/repositories/` → `analyzer` Custom-Rule oder mindestens grep-CI-Check
6. **Force-Unwrap-Regel**: Suche `tenant.id!` → durch Guard ersetzen

**Risiko:** Bei Repository-Änderungen können bestehende Aufrufstellen brechen. Strikt mit Tests absichern.

### Sprint 3: DSGVO-Compliance (~21h)

**Issue:** #211
**Komponenten:**
- Delete-Account-Page (DSGVO Art. 17) + AuthService.deleteAccount() Edge-Function
- Legal-Page (Datenschutz/Impressum) + LegalService + `legal_content` Tabelle anbinden
- Legal-Modal beim Login (Consent vor Account-Erstellung)
- Legal-Link im Login-Footer

**Pre-Condition aus Sprint 1a:** TrackingEvent `accountDeleted` muss existieren.
**Pre-Condition aus Sprint 2:** AuthService sauber (kein Repository-Bypass).

### Sprint 4a: Cold-Start (ohne Push) + Tenant-Auto-Close + Reasons + Conductor (~8.5h)

**Issue:** #213 partial
**Komponenten:**
- Notiz-ActionSheet mit `tenant.absence_reasons` (NEU 7255abc)
- Conductor-Wechsel im Attendance-Modal (NEU abc98c5)
- Tenant-Change Auto-Close (NEU dadbab0)
- App-Lifecycle-Listener für Visibility-Resume (sofern ohne Push sinnvoll — sonst nach 4b)

**KEINE Pre-Condition auf Sprint 1b** — diese drei Findings sind alle UI-/State-Bugs, kein Push beteiligt.

### Sprint 4b: Cold-Start Push (~7h, mit Sprint 1b)

**Issue:** #213 partial
**Komponenten:**
- B2-010 Cold-Start two-stage fetch nach Push-Auth-Restore (4h)
- B2-032 `getAttendanceByIdRobust` Repository-Methode (3h)

**Pre-Condition aus Sprint 1b:** PushService funktioniert.

**Wird zusammen mit Sprint 1b ausgeführt** (am Ende des Master-Plans, sobald Firebase-Setup verfügbar).

### Sprint 5: Cross-Tenant Person-Matching (~37.5h)

**Issue:** #214
**Komponenten:**
- Email-Vergleich `.ilike()` + `.trim()` (Bugfix)
- Cross-Tenant Person-Matching Typeahead (Levenshtein, RankedMatch)
- Email-Blur Cross-Tenant-Match Lookup
- `getPossiblePersonsByName/Email` Repository-Methoden
- Person-Matcher Utility (mit Umlaut-Transliteration)
- Handover-Felder vollständig kopieren (appId/img/teacher/etc.)
- Role.RESPONSIBLE bei Hauptgruppen-Mapping

### Sprint 6: Settings-Hub + Files + Shifts (~25h)

**Issue:** #217
**Komponenten:**
- Files-Page (Tenant-Datei-Browser) — größter Teil
- FilesService + StorageEntry Model
- Cross-Tenant Shift-Update (`updateShiftAttendances`)

**Pre-Condition aus Sprint 1a:** AudioPlayerService (Files-Page nutzt ihn).
**Pre-Condition aus Sprint 2:** Cross-Tenant-Shift-Operationen über Repository.

### Sprint 7: Bulk-Edit + Role-Permissions (~48h, eventuell splitten)

**Issues:** #218, #221
**Komponenten:**
- Bulk-Edit-Page für Personen
- Role-Permissions-Page (konfigurierbar pro Tenant)
- `tenant_role_permissions` Tabelle anbinden
- Rollen-Berechtigungen tatsächlich durchsetzen (Compliance!)

**Mögliche Splits:** 7a (Bulk-Edit, ~24h), 7b (Role-Permissions, ~24h).

### Sprint 8: Songs Public-Sharing + Audio-Integration (~19.5h)

**Issue:** #216
**Komponenten:**
- Public Song-Viewer Route (`/songs/:sharingId`) ohne Login
- Public Song-Detail Route
- `getTenantBySongSharingId` Repository-Methode
- AudioPlayer in song_detail_page integrieren (Pre-Condition: Sprint 1a)

### Sprint 9: Statistics + Export Bug-Fixes (~9h)

**Issues:** #215, #216 partial
**Komponenten:**
- `include_in_average` Filter in Statistics (KRITISCHER Bug)
- Tenant-`additional_fields` im Export verfügbar machen
- Standard-Export-Felder ergänzen (Eingetreten, Notizen, Anwesenheit %)
- Export-Felder differenziert nach Player vs. Attendance
- Excel-Export 100-Termine-Limit aufheben

### Sprint 10: People Workflows (~22h)

**Aus Report:**
- isLeader-Aktivierung mit Voice-Leader-Role-Dialog (3 Optionen)
- Email-Hinzufügen mit "Konto anlegen?"-Dialog
- `syncPlayerWithUpcomingAttendances` nach Person-Update
- `informUserAboutApproval/Reject` E-Mail-Notifications
- Filter "Mitglied anderer Instanz" + Custom-Felder-Filter

### Sprint 11: Sign-Out Reasons + Description-Modal (~24h)

**Aus Report:**
- `tenant.absence_reasons` / `late_reasons` aus Tenant laden (statt hardcoded)
- 4× Custom-Reason-Bug zentralisieren (B5-006/007/021/022) → ein zentraler `SignOutReasonHelper`
- Beschreibung (Quill HTML) und Anhang-Modal in Self-Service + Parents Portal
- `printAllCurrentFiles` PDF-Merge-Feature
- Choir-Type 'Chor' Files Fallback

### Sprint 12: Attendance Workflows (~15h)

**Aus Report:**
- iOS-only FAB für Ablaufplan (NEU 2026-06-17 b3ea25d)
- Manuelles Hinzufügen von Personen zur Anwesenheit
- Ad-Hoc Erinnerung versenden (Edge-Function)
- Anhang (Datei) hinzufügen/entfernen
- Status-Mapping je available_statuses (8 Varianten)

### Sprint 13+: Long Tail

118 MITTEL + 66 NIEDRIG-Findings als laufende Wochen-Tickets nach Master-Plan-Abschluss.

---

## 6. Skill/Agent-Update-Plan (parallel zu Sprints)

Während der Sprints können sich neue Patterns zeigen, die in die Skills/Agents zurückfließen:

- **Nach Sprint 2:** `flutter-reviewer.md` mit konkreten Code-Beispielen aus dem Bypass-Refactor erweitern
- **Nach Sprint 5:** Person-Matcher-Pattern in `flutter-reviewer.md` ergänzen
- **Nach Sprint 7:** Role-Permission-Enforcement-Pattern dokumentieren
- **Generell:** Wenn ein Sprint 3 Iterationen braucht, wird der Verifikations-Output als Lessons-Learned in Memory abgelegt

---

## 7. Risiken & Annahmen

### 7.1 Externe Pre-Conditions (außerhalb Code)

- **Firebase-Projekt + APNS-Key** für Sprint 1b — falls nicht vorhanden, 1-2 Tage extra Setup
- **Physisches iPhone für Push-Tests** (Simulator kann keine Push)
- **Apple Developer Account** mit gültigem Provisioning-Profile

### 7.2 Schema-Bindung an Edge-Functions

`device_tokens.platform` Strings ('ios'/'android'/'web') sind hart in Server-Edge-Functions verdrahtet. Strikt 1:1-Schema einhalten.

`tenant_role_permissions` (Sprint 7) wird voraussichtlich von Edge-Functions gelesen — Schema vor Sprint-Start verifizieren.

### 7.3 Multi-Device-Frage offen

Ionic ist Single-Device hardcoded (1 Token pro User). Frage: Soll Flutter Multi-Device unterstützen (Web + Mobile gleichzeitig)?
**Default-Annahme:** Nein, exakt wie Ionic. Falls später Multi-Device gewünscht, Token-Save-Logik aufbrechen.

### 7.4 Ionic entwickelt sich weiter

Während der 3-4 Monate Migration kann Ionic neue Commits bekommen. **Mitigation:**
- Vor jedem Sprint: `git -C /Users/I576226/repositories/attendance fetch --all` und neue Commits sichten
- Falls relevant für anstehenden Sprint: Verifikation einbauen
- Nach Sprint 12: Final-Check-Crawl

### 7.5 Effort-Schätzungen sind vorläufig

Der Verifikations-Schritt für Sprint 1 hat gezeigt: Erstentwurf 25h → real 40h. **Erwartungshaltung:** Andere Sprints können ähnlich nach oben korrigiert werden. Master-Effort 315h ist Untergrenze.

---

## 8. Stop-Punkte & Eskalations-Regeln

**Stop-Punkte (User-Aktion erforderlich):**

1. **Vor Sprint 1b** (jetzt am Ende des Master-Plans): Firebase-Projekt-Audit. Wenn nicht eingerichtet → User muss handeln. Falls Firebase nie eingerichtet wird, fällt 1b + 4b komplett aus dem Plan, B2-010 und B11-017 wandern in den Long-Tail-Backlog. Nicht-Push-Sprints sind alle unabhängig davon.
2. **Vor jedem Sprint-Start:** Plan-Review nach `/writing-plans` (User akzeptiert oder ändert).
3. **Vor jedem Merge:** Code-Review-Output + User-Freigabe.
4. **Wenn Sprint-Verifikation Effort > 200% des Erstentwurfs ergibt:** Re-Brainstorming des Sprints.
5. **Wenn Tests bei einem Refactor brechen:** Stop, User informieren, gemeinsam entscheiden.

**Eskalations-Regeln:**

- Wenn Ionic während eines laufenden Sprints einen Commit macht, der diesen Sprint betrifft → User informieren, Sprint pausieren falls nötig.
- Wenn ein KRITISCHER Bug während des Sprints sichtbar wird, der nicht im Sprint-Scope ist → User informieren, separat priorisieren.

---

## 9. Anhang: Sprint-1-Verifikations-Bericht

Vollständiger Bericht aus der Iteration 2 in dieser Brainstorming-Session — siehe Memory `migration-status-2026-06.md` und Conversation-History.

**Kernpunkte:**
- Firebase ist im Flutter-Projekt KOMPLETT ungesetzt
- TrackingService hat 27 Events (nicht 25), 36 Call-Sites
- AudioPlayerService braucht Widget in Tabs-Shell
- Push-Effort 16h zu niedrig — realistisch 24-32h
- Sprint 1 als 1a (10h) + 1b (28h) splitten

---

## 10. Nächste Schritte

1. **User reviewt diese Spec** — Stop-Punkt
2. **`/writing-plans` für Sprint 1a** — detaillierter Implementation-Plan
3. **User reviewt Plan** — Stop-Punkt
4. **Worktree + Code-Start** für Sprint 1a
5. **Wiederholen** für 1b, 2, 3, ...

---

**Status:** Draft — wartet auf User-Review.
