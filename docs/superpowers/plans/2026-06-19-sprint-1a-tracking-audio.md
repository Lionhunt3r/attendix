# Sprint 1a — Tracking + Audio Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the two foundational cross-cutting services (`TrackingService`, `AudioPlayerService`) plus the `AudioPlayerWidget` integrated into the main shell. These are pre-conditions for Sprints 1b (Push), 3 (DSGVO/AccountDeleted-Event), 6 (Files-Page), 8 (Songs-Audio) and many others.

**Architecture:**
- `TrackingService` is a thin Riverpod-provided singleton that fires `usage_events` rows (fire-and-forget, never throws). A `TrackingObserver` (GoRouter `NavigatorObserver`) emits `page_view` events on every push/replace, with the same `/login` and `/legal` filter as Ionic.
- `AudioPlayerService` wraps `just_audio` (added as a new dependency) and exposes a Riverpod `Notifier` with a single `AudioPlayerState` record. The `AudioPlayerWidget` is a Mini-Bar rendered inside `MainShell` and only visible when `currentFile != null`. The service's `progress` semantics from Ionic (0-100 for `ion-range`) are dropped in favor of `currentTime/duration` directly — slimmer state, no double-update paths.
- Both services are isolated, low-risk, and testable without mocking Supabase real-time. Call-sites for tracking events are deliberately deferred to later sprints; this sprint only wires the observer for `pageView` and verifies the service plumbing works.

**Tech Stack:** Flutter, Riverpod, Freezed, just_audio, GoRouter, Supabase (insert-only into `usage_events`).

---

## File Structure

**New files:**
- `lib/core/services/tracking/tracking_event.dart` — Enum + extension with the 29 event names (matches Ionic 1:1).
- `lib/core/services/tracking/tracking_service.dart` — `TrackingService` class + Riverpod provider.
- `lib/data/repositories/usage_events_repository.dart` — thin repository wrapping `supabase.from('usage_events').insert(...)`.
- `lib/data/models/usage_event.dart` — Freezed model for `UsageEvent` insert payload.
- `lib/core/router/tracking_observer.dart` — `NavigatorObserver` that fires `pageView` events.
- `lib/core/services/audio_player/audio_player_state.dart` — Freezed `AudioPlayerState`.
- `lib/core/services/audio_player/audio_player_service.dart` — `AudioPlayerService` class + Riverpod `Notifier`.
- `lib/shared/widgets/audio_player/audio_player_widget.dart` — Mini-Bar widget.
- `test/core/services/tracking/tracking_service_test.dart`
- `test/data/repositories/usage_events_repository_test.dart`
- `test/core/router/tracking_observer_test.dart`
- `test/core/services/audio_player/audio_player_service_test.dart`
- `test/shared/widgets/audio_player/audio_player_widget_test.dart`

**Modified files:**
- `pubspec.yaml` — add `just_audio: ^0.9.40`.
- `lib/core/router/app_router.dart` — register `TrackingObserver` on the `GoRouter` and skip tracking for `/login` and `/legal*`.
- `lib/shared/widgets/layout/main_shell.dart` — host the `AudioPlayerWidget` above the bottom navigation bar.
- `lib/data/repositories/repositories.dart` — export `usage_events_repository`.
- `pubspec.yaml` (version bump): `0.1.27+28` → `0.2.0+29`.
- `assets/version_history.json` — append v0.2.0 entry.
- `lib/core/constants/app_constants.dart` — bump `appVersion` to `'0.2.0'`.
- `ios/Runner/Info.plist` — add `UIBackgroundModes` with `audio` so audio keeps playing when the device locks (matches Ionic behavior).

**Out of scope for this sprint** (deferred to later sprints):
- Wiring tracking call-sites for login, attendance, parents, songs, etc. (those land naturally in their respective sprints).
- Push-related events (Sprint 1b).
- Dashboard page (Sprint 5/Issue #220 — but this sprint closes the foundation half of #220).

---

## Pre-Conditions Check

Before starting, verify:

- Worktree `.worktrees/sprint-1a-tracking-audio` exists and `.env` is copied in.
- `supabase/sql/usage_events.sql` is already deployed to the running Supabase project (RLS enabled, insert-policy for authenticated users).
- `dart analyze lib/` is clean on the current `master` and `flutter test` is green.

If any of those is not true, stop and address it before starting.

---

## Task 1: Add `just_audio` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Inspect current dependencies**

Run: `grep -A 1 "^dependencies:" /Users/I576226/repositories/attendix/pubspec.yaml | head -3`

This is to confirm where the `dependencies:` block is so the new line lands in the right place.

- [ ] **Step 2: Add the dependency**

In `pubspec.yaml`, inside the `dependencies:` block (alphabetically placed, near `flutter_riverpod`/`fl_chart`), add:

```yaml
  just_audio: ^0.9.40
```

- [ ] **Step 3: Resolve dependencies**

Run: `flutter pub get`

Expected: success, `just_audio` and its transitive deps resolve. If a Pod-update prompt appears for iOS, ignore for now — iOS pod install runs in Task 11.

- [ ] **Step 4: Confirm import works**

Run: `dart -e "import 'package:just_audio/just_audio.dart'; void main() {}" 2>&1 | head -3`

If you get no errors, the package is wired.

Run: `flutter analyze`. Expected: still clean.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add just_audio dependency for AudioPlayerService"
```

---

## Task 2: Create `TrackingEvent` enum

**Files:**
- Create: `lib/core/services/tracking/tracking_event.dart`
- Test: `test/core/services/tracking/tracking_event_test.dart`

The Ionic source of truth is `services/tracking/tracking.service.ts:6-44` (29 events). The wire-format is `snake_case` strings (e.g., `attendance_check_in`), because the `usage_events.event_name` column and the developer dashboard query against those exact strings. We model this as a Dart enum whose `.wireName` matches the Ionic strings exactly.

- [ ] **Step 1: Write the failing test**

Create `test/core/services/tracking/tracking_event_test.dart`:

```dart
import 'package:attendix/core/services/tracking/tracking_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrackingEvent', () {
    test('exposes all 29 event names from Ionic v4.0.5', () {
      expect(TrackingEvent.values.length, 29);
    });

    test('wireName matches Ionic snake_case strings', () {
      expect(TrackingEvent.pageView.wireName, 'page_view');
      expect(TrackingEvent.login.wireName, 'login');
      expect(TrackingEvent.attendanceCheckIn.wireName, 'attendance_check_in');
      expect(TrackingEvent.attendanceCheckOut.wireName, 'attendance_check_out');
      expect(TrackingEvent.parentSignIn.wireName, 'parent_signin');
      expect(TrackingEvent.parentSignOut.wireName, 'parent_signout');
      expect(TrackingEvent.pushReceived.wireName, 'push_received');
      expect(TrackingEvent.pushOpened.wireName, 'push_opened');
      expect(TrackingEvent.meetingCreated.wireName, 'meeting_created');
      expect(TrackingEvent.songShared.wireName, 'song_shared');
      expect(TrackingEvent.reportExported.wireName, 'report_exported');
      expect(TrackingEvent.handoverCreated.wireName, 'handover_created');
      expect(TrackingEvent.playerAdded.wireName, 'player_added');
      expect(TrackingEvent.playerUpdated.wireName, 'player_updated');
      expect(TrackingEvent.playerRemoved.wireName, 'player_removed');
      expect(TrackingEvent.teacherAdded.wireName, 'teacher_added');
      expect(TrackingEvent.teacherUpdated.wireName, 'teacher_updated');
      expect(TrackingEvent.instrumentAdded.wireName, 'instrument_added');
      expect(TrackingEvent.instrumentUpdated.wireName, 'instrument_updated');
      expect(TrackingEvent.instrumentRemoved.wireName, 'instrument_removed');
      expect(
        TrackingEvent.notificationSettingsChanged.wireName,
        'notification_settings_changed',
      );
      expect(TrackingEvent.fileUploaded.wireName, 'file_uploaded');
      expect(TrackingEvent.accountDeleted.wireName, 'account_deleted');
      expect(
        TrackingEvent.attendanceFetchAttempt.wireName,
        'attendance_fetch_attempt',
      );
      expect(
        TrackingEvent.attendanceFetchStageB.wireName,
        'attendance_fetch_stage_b',
      );
      expect(
        TrackingEvent.attendanceFetchResolved.wireName,
        'attendance_fetch_resolved',
      );
      expect(
        TrackingEvent.attendanceFetchModifyThrow.wireName,
        'attendance_fetch_modify_throw',
      );
      expect(
        TrackingEvent.attendanceTypeUnresolved.wireName,
        'attendance_type_unresolved',
      );
      expect(
        TrackingEvent.attendanceSecondaryInitFailed.wireName,
        'attendance_secondary_init_failed',
      );
    });
  });
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `flutter test test/core/services/tracking/tracking_event_test.dart`

Expected: FAIL with "Target of URI doesn't exist: 'package:attendix/core/services/tracking/tracking_event.dart'".

- [ ] **Step 3: Implement the enum**

Create `lib/core/services/tracking/tracking_event.dart`:

```dart
/// Cross-cutting analytics events written to Supabase `usage_events`.
///
/// Wire-format strings MUST match Ionic v4.0.5
/// (`src/app/services/tracking/tracking.service.ts:6-44`) exactly — the
/// super-developer dashboard queries `event_name` by string.
enum TrackingEvent {
  pageView('page_view'),
  login('login'),
  attendanceCheckIn('attendance_check_in'),
  attendanceCheckOut('attendance_check_out'),
  parentSignIn('parent_signin'),
  parentSignOut('parent_signout'),
  pushReceived('push_received'),
  pushOpened('push_opened'),
  meetingCreated('meeting_created'),
  songShared('song_shared'),
  reportExported('report_exported'),
  handoverCreated('handover_created'),
  playerAdded('player_added'),
  playerUpdated('player_updated'),
  playerRemoved('player_removed'),
  teacherAdded('teacher_added'),
  teacherUpdated('teacher_updated'),
  instrumentAdded('instrument_added'),
  instrumentUpdated('instrument_updated'),
  instrumentRemoved('instrument_removed'),
  notificationSettingsChanged('notification_settings_changed'),
  fileUploaded('file_uploaded'),
  accountDeleted('account_deleted'),
  attendanceFetchAttempt('attendance_fetch_attempt'),
  attendanceFetchStageB('attendance_fetch_stage_b'),
  attendanceFetchResolved('attendance_fetch_resolved'),
  attendanceFetchModifyThrow('attendance_fetch_modify_throw'),
  attendanceTypeUnresolved('attendance_type_unresolved'),
  attendanceSecondaryInitFailed('attendance_secondary_init_failed');

  const TrackingEvent(this.wireName);

  /// snake_case string written to `usage_events.event_name`.
  final String wireName;
}
```

- [ ] **Step 4: Run the test and verify it passes**

Run: `flutter test test/core/services/tracking/tracking_event_test.dart`

Expected: PASS, both tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/tracking/tracking_event.dart \
        test/core/services/tracking/tracking_event_test.dart
git commit -m "feat(tracking): add TrackingEvent enum (29 events, Ionic v4.0.5 parity)"
```

---

## Task 3: Create `UsageEvent` Freezed model

**Files:**
- Create: `lib/data/models/usage_event.dart`

The model is a thin payload object representing a row insert into `usage_events`. We don't need to read these rows from Flutter (read access is restricted to `developer@attendix.de` per RLS policy in `supabase/sql/usage_events.sql:25-30`), so only the insert shape matters.

- [ ] **Step 1: Implement the model**

Create `lib/data/models/usage_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_event.freezed.dart';
part 'usage_event.g.dart';

/// Insert payload for the `usage_events` table.
///
/// Schema source: `supabase/sql/usage_events.sql`. The columns
/// `id` and `created_at` have DB-side defaults and are NOT sent.
@freezed
class UsageEvent with _$UsageEvent {
  const factory UsageEvent({
    @JsonKey(name: 'event_name') required String eventName,
    @JsonKey(name: 'tenant_id') int? tenantId,
    @JsonKey(name: 'device_type') required String deviceType,
    @Default(<String, dynamic>{}) Map<String, dynamic> properties,
  }) = _UsageEvent;

  factory UsageEvent.fromJson(Map<String, dynamic> json) =>
      _$UsageEventFromJson(json);
}
```

- [ ] **Step 2: Generate Freezed code**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: `lib/data/models/usage_event.freezed.dart` and `usage_event.g.dart` are created.

- [ ] **Step 3: Verify it compiles**

Run: `dart analyze lib/data/models/usage_event.dart`

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/data/models/usage_event.dart \
        lib/data/models/usage_event.freezed.dart \
        lib/data/models/usage_event.g.dart
git commit -m "feat(tracking): add UsageEvent Freezed model"
```

---

## Task 4: Create `UsageEventsRepository`

**Files:**
- Create: `lib/data/repositories/usage_events_repository.dart`
- Modify: `lib/data/repositories/repositories.dart`
- Test: `test/data/repositories/usage_events_repository_test.dart`

This repository deliberately does NOT extend `TenantAwareRepository` — `usage_events` is tenant-anonymous (the `tenant_id` is a foreign key but not a security boundary; it's just a property). The Ionic equivalent (`tracking.service.ts:60-70`) writes `tenant_id` derived from `DbService.tenant().id`, falling back to `null` when no tenant is set. We mirror that.

- [ ] **Step 1: Write the failing test**

Create `test/data/repositories/usage_events_repository_test.dart`:

```dart
import 'package:attendix/data/models/usage_event.dart';
import 'package:attendix/data/repositories/usage_events_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/supabase_mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  group('UsageEventsRepository', () {
    late MockSupabaseClient client;
    late MockSupabaseQueryBuilder builder;
    late ProviderContainer container;

    setUp(() {
      client = MockSupabaseClient();
      builder = MockSupabaseQueryBuilder();
      when(() => client.from('usage_events')).thenReturn(builder);
      when(() => builder.insert(any())).thenAnswer((_) async => null);

      container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
    });

    test('insert writes the payload to usage_events', () async {
      final repo = container.read(usageEventsRepositoryProvider);
      await repo.insert(const UsageEvent(
        eventName: 'login',
        tenantId: 42,
        deviceType: 'web',
        properties: {'foo': 'bar'},
      ));

      verify(() => client.from('usage_events')).called(1);
      verify(() => builder.insert(<String, dynamic>{
            'event_name': 'login',
            'tenant_id': 42,
            'device_type': 'web',
            'properties': {'foo': 'bar'},
          })).called(1);
    });

    test('insert tolerates a Supabase error and does not rethrow', () async {
      when(() => builder.insert(any())).thenThrow(const PostgrestException(
        message: 'boom',
        code: '500',
      ));

      final repo = container.read(usageEventsRepositoryProvider);

      // The contract is: tracking never disrupts UX. The repo itself MAY
      // throw (the service swallows), but we want to assert the wire shape
      // even on the failure path. So here we assert it threw a known type:
      await expectLater(
        () => repo.insert(const UsageEvent(
          eventName: 'login',
          deviceType: 'web',
        )),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
```

If `test/mocks/supabase_mocks.dart` does not yet exist with `MockSupabaseClient` / `MockSupabaseQueryBuilder`, see the existing `test/mocks/` directory for the pattern (other repo tests use the same fixture). If those mocks already exist, reuse them. If not, add them in Step 1b below.

- [ ] **Step 1b: Verify shared Supabase mocks exist**

Run: `grep -l "class MockSupabaseClient" test/mocks/*.dart 2>/dev/null`

Expected: prints a path. If empty, look at how `test/data/repositories/attendance_repository_test.dart` mocks Supabase and copy that pattern. The test in Step 1 assumes `MockSupabaseClient` and `MockSupabaseQueryBuilder` are available from `test/mocks/supabase_mocks.dart` — adjust the import to whatever path the existing mocks live at.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/data/repositories/usage_events_repository_test.dart`

Expected: FAIL with "Target of URI doesn't exist: 'package:attendix/data/repositories/usage_events_repository.dart'".

- [ ] **Step 3: Implement the repository**

Create `lib/data/repositories/usage_events_repository.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/supabase_config.dart';
import '../models/usage_event.dart';

/// Insert-only repository for the `usage_events` table.
///
/// `usage_events` is tenant-anonymous (no security boundary on tenant_id) and
/// readable only by `developer@attendix.de` per RLS, so this repo deliberately
/// skips `TenantAwareRepository`.
class UsageEventsRepository {
  UsageEventsRepository(this._ref);

  final Ref _ref;

  Future<void> insert(UsageEvent event) async {
    final client = _ref.read(supabaseClientProvider);
    await client.from('usage_events').insert(event.toJson());
  }
}

final usageEventsRepositoryProvider = Provider<UsageEventsRepository>(
  UsageEventsRepository.new,
);
```

- [ ] **Step 4: Export the provider**

Append to `lib/data/repositories/repositories.dart` (alphabetically placed):

```dart
export 'usage_events_repository.dart';
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/data/repositories/usage_events_repository_test.dart`

Expected: PASS, both tests green.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/usage_events_repository.dart \
        lib/data/repositories/repositories.dart \
        test/data/repositories/usage_events_repository_test.dart
git commit -m "feat(tracking): add UsageEventsRepository (insert-only)"
```

---

## Task 5: Create `TrackingService`

**Files:**
- Create: `lib/core/services/tracking/tracking_service.dart`
- Test: `test/core/services/tracking/tracking_service_test.dart`

The service has three responsibilities:
1. Resolve `device_type` once at construction (`'ios' | 'android' | 'web'`).
2. Resolve `tenant_id` lazily on each call from `currentTenantProvider` (mirrors Ionic's lazy `injector.get(DbService)`).
3. Fire-and-forget — `track()` returns `void`, internal failures are swallowed so tracking never disrupts UX.

The Ionic source is `services/tracking/tracking.service.ts:49-90`.

- [ ] **Step 1: Write the failing test**

Create `test/core/services/tracking/tracking_service_test.dart`:

```dart
import 'package:attendix/core/services/tracking/tracking_event.dart';
import 'package:attendix/core/services/tracking/tracking_service.dart';
import 'package:attendix/data/models/tenant/tenant.dart';
import 'package:attendix/data/models/usage_event.dart';
import 'package:attendix/data/repositories/usage_events_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_factories.dart';

class _MockUsageEventsRepository extends Mock
    implements UsageEventsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const UsageEvent(
      eventName: 'fallback',
      deviceType: 'web',
    ));
  });

  group('TrackingService', () {
    late _MockUsageEventsRepository repo;

    setUp(() {
      repo = _MockUsageEventsRepository();
      when(() => repo.insert(any())).thenAnswer((_) async {});
    });

    ProviderContainer makeContainer({Tenant? tenant}) {
      return ProviderContainer(
        overrides: [
          usageEventsRepositoryProvider.overrideWithValue(repo),
          currentTenantProvider.overrideWith((_) => tenant),
          // Force web so test runs deterministically on any platform
          trackingDeviceTypeProvider.overrideWithValue('web'),
        ],
      );
    }

    test('track inserts a UsageEvent with current tenant id and device type',
        () async {
      final container = makeContainer(tenant: TestFactories.createTenant(id: 7));
      addTearDown(container.dispose);

      container
          .read(trackingServiceProvider)
          .track(TrackingEvent.login, properties: const {'foo': 'bar'});

      // fire-and-forget: give the unawaited future a tick to run
      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => repo.insert(captureAny())).captured.single
          as UsageEvent;
      expect(captured.eventName, 'login');
      expect(captured.tenantId, 7);
      expect(captured.deviceType, 'web');
      expect(captured.properties, const {'foo': 'bar'});
    });

    test('track sends tenant_id null when no tenant is selected', () async {
      final container = makeContainer(tenant: null);
      addTearDown(container.dispose);

      container.read(trackingServiceProvider).track(TrackingEvent.pageView);
      await Future<void>.delayed(Duration.zero);

      final captured = verify(() => repo.insert(captureAny())).captured.single
          as UsageEvent;
      expect(captured.tenantId, isNull);
    });

    test('track swallows repository errors (fire-and-forget)', () async {
      when(() => repo.insert(any())).thenThrow(StateError('boom'));
      final container = makeContainer();
      addTearDown(container.dispose);

      // Must not throw synchronously and must not propagate the async error.
      expect(
        () =>
            container.read(trackingServiceProvider).track(TrackingEvent.login),
        returnsNormally,
      );
      await Future<void>.delayed(Duration.zero);
    });
  });
}
```

If `currentTenantProvider` lives somewhere other than the test's import path, find it via `grep -rn "currentTenantProvider" lib/core/providers/ | head -3` and adjust the import. Same for `TestFactories.createTenant` — see `test/factories/test_factories.dart`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/services/tracking/tracking_service_test.dart`

Expected: FAIL — `tracking_service.dart` and its providers don't exist yet.

- [ ] **Step 3: Implement the service**

Create `lib/core/services/tracking/tracking_service.dart`:

```dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/tenant_providers.dart';
import '../../../data/models/usage_event.dart';
import '../../../data/repositories/usage_events_repository.dart';
import 'tracking_event.dart';

/// Resolves the current device platform once per process.
///
/// Override in tests with `trackingDeviceTypeProvider.overrideWithValue('web')`
/// so suites are deterministic on any host.
final trackingDeviceTypeProvider = Provider<String>((ref) {
  if (kIsWeb) return 'web';
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'web';
});

/// Cross-cutting analytics service. Fire-and-forget — never throws.
///
/// Mirrors Ionic's `TrackingService` (`tracking.service.ts:49-90`):
/// inserts a row into `usage_events` for every `track()` call, derives
/// `tenant_id` lazily so a service-construction-before-login sequence still
/// works, and swallows all errors because tracking must not disrupt UX.
class TrackingService {
  TrackingService(this._ref);

  final Ref _ref;

  void track(
    TrackingEvent event, {
    Map<String, dynamic> properties = const {},
  }) {
    unawaited(_fire(event, properties));
  }

  Future<void> _fire(
    TrackingEvent event,
    Map<String, dynamic> properties,
  ) async {
    try {
      final tenant = _ref.read(currentTenantProvider);
      final repo = _ref.read(usageEventsRepositoryProvider);
      await repo.insert(UsageEvent(
        eventName: event.wireName,
        tenantId: tenant?.id,
        deviceType: _ref.read(trackingDeviceTypeProvider),
        properties: properties,
      ));
    } catch (_) {
      // Swallow — tracking must never disrupt UX.
    }
  }
}

final trackingServiceProvider = Provider<TrackingService>(
  TrackingService.new,
);
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/services/tracking/tracking_service_test.dart`

Expected: PASS, all three tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/tracking/tracking_service.dart \
        test/core/services/tracking/tracking_service_test.dart
git commit -m "feat(tracking): add TrackingService (fire-and-forget, tenant-aware)"
```

---

## Task 6: Create `TrackingObserver` for GoRouter

**Files:**
- Create: `lib/core/router/tracking_observer.dart`
- Test: `test/core/router/tracking_observer_test.dart`

The Ionic equivalent lives in `app.component.ts:184-187` and skips routes containing `/login` or `/legal`. We replicate that filter exactly. The observer fires `pageView` with the route name as a property.

- [ ] **Step 1: Write the failing test**

Create `test/core/router/tracking_observer_test.dart`:

```dart
import 'package:attendix/core/router/tracking_observer.dart';
import 'package:attendix/core/services/tracking/tracking_event.dart';
import 'package:attendix/core/services/tracking/tracking_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTrackingService extends Mock implements TrackingService {}

void main() {
  setUpAll(() {
    registerFallbackValue(TrackingEvent.pageView);
  });

  group('TrackingObserver', () {
    late _MockTrackingService tracking;
    late TrackingObserver observer;

    setUp(() {
      tracking = _MockTrackingService();
      final container = ProviderContainer(
        overrides: [
          trackingServiceProvider.overrideWithValue(tracking),
        ],
      );
      addTearDown(container.dispose);
      observer = TrackingObserver(container);
    });

    PageRoute<void> route(String name) {
      return PageRouteBuilder<void>(
        settings: RouteSettings(name: name),
        pageBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }

    test('fires page_view on didPush with the route name', () {
      observer.didPush(route('/people'), null);

      verify(() => tracking.track(
            TrackingEvent.pageView,
            properties: {'route': '/people'},
          )).called(1);
    });

    test('fires page_view on didReplace with the new route name', () {
      observer.didReplace(
        newRoute: route('/attendance/42'),
        oldRoute: route('/attendance'),
      );

      verify(() => tracking.track(
            TrackingEvent.pageView,
            properties: {'route': '/attendance/42'},
          )).called(1);
    });

    test('skips routes starting with /login', () {
      observer.didPush(route('/login'), null);
      verifyNever(() => tracking.track(any(), properties: any(named: 'properties')));
    });

    test('skips routes starting with /legal', () {
      observer.didPush(route('/legal'), null);
      observer.didPush(route('/legal/datenschutz'), null);
      verifyNever(() => tracking.track(any(), properties: any(named: 'properties')));
    });

    test('does not fire when route name is null', () {
      final r = PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const SizedBox.shrink(),
      );
      observer.didPush(r, null);
      verifyNever(() => tracking.track(any(), properties: any(named: 'properties')));
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/router/tracking_observer_test.dart`

Expected: FAIL — `tracking_observer.dart` doesn't exist.

- [ ] **Step 3: Implement the observer**

Create `lib/core/router/tracking_observer.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tracking/tracking_event.dart';
import '../services/tracking/tracking_service.dart';

/// `NavigatorObserver` that fires a `page_view` event on every route push or
/// replace. Routes whose names start with `/login` or `/legal` are skipped,
/// matching Ionic v4.0.5 (`app.component.ts:184-187`).
class TrackingObserver extends NavigatorObserver {
  TrackingObserver(this._container);

  final ProviderContainer _container;

  static const _skipPrefixes = ['/login', '/legal'];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _track(newRoute);
  }

  void _track(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null) return;
    for (final prefix in _skipPrefixes) {
      if (name.startsWith(prefix)) return;
    }
    _container.read(trackingServiceProvider).track(
          TrackingEvent.pageView,
          properties: {'route': name},
        );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/router/tracking_observer_test.dart`

Expected: PASS, all five tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/tracking_observer.dart \
        test/core/router/tracking_observer_test.dart
git commit -m "feat(tracking): add TrackingObserver (GoRouter NavigatorObserver, /login + /legal filter)"
```

---

## Task 7: Wire `TrackingObserver` into the GoRouter

**Files:**
- Modify: `lib/core/router/app_router.dart`

GoRouter accepts a list of `NavigatorObserver`s through the `observers:` parameter on the root `GoRouter` constructor. We pass our observer there, sourcing the `ProviderContainer` from the `Ref` that already builds the router.

- [ ] **Step 1: Read the current router builder**

Run: `grep -n "GoRouter(" lib/core/router/app_router.dart | head -3`

Find the `return GoRouter(` line (around line 117 per current code).

- [ ] **Step 2: Add the observer to the router**

In `lib/core/router/app_router.dart`:

1. Add the import near the top with the other imports:

   ```dart
   import 'tracking_observer.dart';
   ```

2. In the `routerProvider` body, replace the `return GoRouter(` line and the `initialLocation` line with:

   ```dart
   return GoRouter(
     initialLocation: '/login',
     debugLogDiagnostics: true,
     refreshListenable: authNotifier,
     observers: [TrackingObserver(ref.container)],
   ```

Note: `ref.container` is available on a Riverpod `Ref` and is the `ProviderContainer` the router itself was built in. Using it inside an observer is safe — the container outlives the router.

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/core/router/app_router.dart`

Expected: no errors.

- [ ] **Step 4: Run the existing test suite**

Run: `flutter test`

Expected: all existing tests still pass. `dart run build_runner build` may need a re-run if generated providers are stale — if any test fails for that reason, run the build_runner step again and re-test.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/app_router.dart
git commit -m "feat(tracking): register TrackingObserver on the GoRouter"
```

---

## Task 8: Create `AudioPlayerState` Freezed model

**Files:**
- Create: `lib/core/services/audio_player/audio_player_state.dart`

The Ionic service stores six separate `WritableSignal`s (`audio-player.service.ts:8-14`). In Flutter we collapse those into a single immutable record, which is cheaper to update reactively and simpler to test. The Ionic `progress` (0-100 for `ion-range`) is intentionally dropped — Flutter's `Slider` works directly with `Duration`/`max` and a separate field would just create double-update paths.

- [ ] **Step 1: Implement the state**

Create `lib/core/services/audio_player/audio_player_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_player_state.freezed.dart';

/// Immutable snapshot of the audio player.
///
/// Mirrors Ionic v4.0.5 `AudioPlayerService` (`audio-player.service.ts:7-17`)
/// minus `progress` (0-100 for `ion-range`). In Flutter we drive the slider
/// directly off `currentTime / duration` to avoid a redundant state field.
@freezed
class AudioPlayerState with _$AudioPlayerState {
  const factory AudioPlayerState({
    String? currentUrl,
    @Default('') String currentSongName,
    String? currentFileName,
    @Default(false) bool isPlaying,
    @Default(Duration.zero) Duration currentTime,
    @Default(Duration.zero) Duration duration,
    @Default(false) bool isSeeking,
  }) = _AudioPlayerState;

  const AudioPlayerState._();

  /// Whether the bar should be rendered.
  bool get hasFile => currentUrl != null;
}
```

- [ ] **Step 2: Generate Freezed code**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: `audio_player_state.freezed.dart` is generated.

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/core/services/audio_player/`

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/core/services/audio_player/audio_player_state.dart \
        lib/core/services/audio_player/audio_player_state.freezed.dart
git commit -m "feat(audio): add AudioPlayerState Freezed model"
```

---

## Task 9: Create `AudioPlayerService` (Riverpod Notifier)

**Files:**
- Create: `lib/core/services/audio_player/audio_player_service.dart`
- Test: `test/core/services/audio_player/audio_player_service_test.dart`

The service is a `Notifier<AudioPlayerState>` that owns a single `AudioPlayer` (from `just_audio`). It exposes the same operations as the Ionic service:

| Ionic method | Flutter method |
|--------------|----------------|
| `isAudioFile(file)` (static) | `AudioPlayerService.isAudioFile(filename)` (static) |
| `play(file, songName)` | `play(url, fileName, songName)` |
| `playFromUrl(url, fileName, songName)` | (same name, same shape) |
| `togglePlayPause()` | `togglePlayPause()` |
| `stop()` | `stop()` |
| `seek(value: 0-100)` | `seek(Duration position)` |
| `startSeeking() / stopSeeking(value)` | `startSeeking() / stopSeeking(Duration)` |
| `formatTime(seconds)` (instance) | `AudioPlayerService.formatTime(Duration)` (static) |

Test strategy: we don't mock `just_audio` itself (it's complex). Instead we extract the seam — `AudioPlayerService` accepts an `AudioPlayer Function()` factory in its constructor (defaulted in production). The test passes a `_FakeAudioPlayer` that records calls and emits events through `Stream`s.

- [ ] **Step 1: Write the failing test**

Create `test/core/services/audio_player/audio_player_service_test.dart`:

```dart
import 'dart:async';

import 'package:attendix/core/services/audio_player/audio_player_service.dart';
import 'package:attendix/core/services/audio_player/audio_player_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class _FakeAudioPlayer implements AudioPlayer {
  final _playingCtrl = StreamController<bool>.broadcast();
  final _positionCtrl = StreamController<Duration>.broadcast();
  final _durationCtrl = StreamController<Duration?>.broadcast();
  final _processingStateCtrl = StreamController<ProcessingState>.broadcast();

  bool playing = false;
  Duration position = Duration.zero;
  String? lastUrl;
  bool disposed = false;

  @override
  Stream<bool> get playingStream => _playingCtrl.stream;

  @override
  Stream<Duration> get positionStream => _positionCtrl.stream;

  @override
  Stream<Duration?> get durationStream => _durationCtrl.stream;

  @override
  Stream<ProcessingState> get processingStateStream =>
      _processingStateCtrl.stream;

  @override
  Future<Duration?> setUrl(String url, {Map<String, String>? headers}) async {
    lastUrl = url;
    return const Duration(minutes: 3);
  }

  @override
  Future<void> play() async {
    playing = true;
    _playingCtrl.add(true);
  }

  @override
  Future<void> pause() async {
    playing = false;
    _playingCtrl.add(false);
  }

  @override
  Future<void> stop() async {
    playing = false;
    _playingCtrl.add(false);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    this.position = position ?? Duration.zero;
    _positionCtrl.add(this.position);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _playingCtrl.close();
    await _positionCtrl.close();
    await _durationCtrl.close();
    await _processingStateCtrl.close();
  }

  // Unused members throw to keep the test honest about coverage.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  group('AudioPlayerService.isAudioFile', () {
    test('matches all 9 supported extensions, case-insensitive', () {
      const cases = [
        'foo.mp3',
        'FOO.WAV',
        'piece.ogg',
        'voice.m4a',
        'note.aac',
        'tune.flac',
        'old.wma',
        'web.webm',
        'opus.opus',
        'CAPS.MP3',
      ];
      for (final c in cases) {
        expect(AudioPlayerService.isAudioFile(c), isTrue, reason: c);
      }
    });

    test('rejects non-audio extensions', () {
      expect(AudioPlayerService.isAudioFile('score.pdf'), isFalse);
      expect(AudioPlayerService.isAudioFile('cover.jpg'), isFalse);
      expect(AudioPlayerService.isAudioFile(''), isFalse);
    });
  });

  group('AudioPlayerService.formatTime', () {
    test('formats Duration as m:ss', () {
      expect(AudioPlayerService.formatTime(Duration.zero), '0:00');
      expect(
        AudioPlayerService.formatTime(const Duration(seconds: 5)),
        '0:05',
      );
      expect(
        AudioPlayerService.formatTime(const Duration(minutes: 1, seconds: 30)),
        '1:30',
      );
      expect(
        AudioPlayerService.formatTime(
          const Duration(minutes: 12, seconds: 45),
        ),
        '12:45',
      );
    });
  });

  group('AudioPlayerService notifier', () {
    late _FakeAudioPlayer fake;

    ProviderContainer makeContainer() {
      fake = _FakeAudioPlayer();
      return ProviderContainer(
        overrides: [
          audioPlayerFactoryProvider.overrideWithValue(() => fake),
        ],
      );
    }

    test('initial state has no file and is not playing', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final state = c.read(audioPlayerServiceProvider);
      expect(state.hasFile, isFalse);
      expect(state.isPlaying, isFalse);
    });

    test('playFromUrl sets currentUrl, currentSongName and starts playback',
        () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final svc = c.read(audioPlayerServiceProvider.notifier);

      await svc.playFromUrl(
        'https://example.com/song.mp3',
        'song.mp3',
        'Test Song',
      );

      final state = c.read(audioPlayerServiceProvider);
      expect(state.currentUrl, 'https://example.com/song.mp3');
      expect(state.currentSongName, 'Test Song');
      expect(state.currentFileName, 'song.mp3');
      expect(fake.lastUrl, 'https://example.com/song.mp3');
      expect(fake.playing, isTrue);
    });

    test('togglePlayPause flips between play and pause', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final svc = c.read(audioPlayerServiceProvider.notifier);

      await svc.playFromUrl('https://example.com/a.mp3', 'a.mp3', 'A');
      expect(fake.playing, isTrue);

      await svc.togglePlayPause();
      expect(fake.playing, isFalse);

      await svc.togglePlayPause();
      expect(fake.playing, isTrue);
    });

    test('stop clears state and stops the underlying player', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final svc = c.read(audioPlayerServiceProvider.notifier);

      await svc.playFromUrl('https://example.com/a.mp3', 'a.mp3', 'A');
      await svc.stop();

      final state = c.read(audioPlayerServiceProvider);
      expect(state.hasFile, isFalse);
      expect(state.isPlaying, isFalse);
      expect(fake.playing, isFalse);
    });

    test('isSeeking suppresses position updates while user drags', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final svc = c.read(audioPlayerServiceProvider.notifier);

      await svc.playFromUrl('https://example.com/a.mp3', 'a.mp3', 'A');
      svc.startSeeking();

      // Simulate a position event from just_audio while seeking
      fake._positionCtrl.add(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);

      // currentTime must NOT have followed the event — anti-flicker.
      expect(c.read(audioPlayerServiceProvider).currentTime, Duration.zero);

      // Releasing the slider seeks AND re-enables position updates.
      await svc.stopSeeking(const Duration(seconds: 90));
      expect(fake.position, const Duration(seconds: 90));
      expect(c.read(audioPlayerServiceProvider).isSeeking, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/core/services/audio_player/audio_player_service_test.dart`

Expected: FAIL — `audio_player_service.dart` doesn't exist.

- [ ] **Step 3: Implement the service**

Create `lib/core/services/audio_player/audio_player_service.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_player_state.dart';

/// Factory for the underlying `just_audio` `AudioPlayer`.
///
/// Tests override this with a fake; production uses the real player.
final audioPlayerFactoryProvider = Provider<AudioPlayer Function()>(
  (_) => AudioPlayer.new,
);

/// Cross-cutting audio playback service.
///
/// Mirrors Ionic v4.0.5 `AudioPlayerService` (`audio-player.service.ts`).
/// Exactly one file plays at a time. Calling `play`/`playFromUrl` while
/// another file is loaded stops the current playback first.
class AudioPlayerService extends Notifier<AudioPlayerState> {
  AudioPlayer? _player;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ProcessingState>? _processingSub;

  static const _audioExtensions = [
    '.mp3', '.wav', '.ogg', '.m4a', '.aac',
    '.flac', '.wma', '.webm', '.opus',
  ];

  /// True if the file name ends with any recognized audio extension.
  static bool isAudioFile(String fileName) {
    final lower = fileName.toLowerCase();
    return _audioExtensions.any(lower.endsWith);
  }

  /// `m:ss` formatting for slider labels (e.g. `1:30`, `12:45`).
  static String formatTime(Duration d) {
    if (d == Duration.zero) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  AudioPlayerState build() {
    ref.onDispose(_disposePlayer);
    return const AudioPlayerState();
  }

  Future<void> playFromUrl(
    String url,
    String fileName,
    String songName,
  ) async {
    await _stopInternal();

    final player = ref.read(audioPlayerFactoryProvider)();
    _player = player;
    _wireStreams(player);

    final loadedDuration = await player.setUrl(url);
    state = state.copyWith(
      currentUrl: url,
      currentFileName: fileName,
      currentSongName: songName,
      duration: loadedDuration ?? Duration.zero,
      currentTime: Duration.zero,
      isSeeking: false,
    );
    await player.play();
  }

  Future<void> togglePlayPause() async {
    final player = _player;
    if (player == null) return;
    if (state.isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> stop() => _stopInternal();

  Future<void> seek(Duration position) async {
    final player = _player;
    if (player == null) return;
    await player.seek(position);
    state = state.copyWith(currentTime: position);
  }

  void startSeeking() {
    state = state.copyWith(isSeeking: true);
  }

  Future<void> stopSeeking(Duration position) async {
    state = state.copyWith(isSeeking: false);
    await seek(position);
  }

  void _wireStreams(AudioPlayer player) {
    _playingSub = player.playingStream.listen((p) {
      state = state.copyWith(isPlaying: p);
    });
    _positionSub = player.positionStream.listen((pos) {
      // Anti-flicker: while the user drags the slider, ignore the player's
      // own position updates so the knob doesn't snap back.
      if (state.isSeeking) return;
      state = state.copyWith(currentTime: pos);
    });
    _durationSub = player.durationStream.listen((d) {
      if (d != null) state = state.copyWith(duration: d);
    });
    _processingSub = player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) {
        state = state.copyWith(
          isPlaying: false,
          currentTime: Duration.zero,
        );
      }
    });
  }

  Future<void> _stopInternal() async {
    await _playingSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _processingSub?.cancel();
    _playingSub = null;
    _positionSub = null;
    _durationSub = null;
    _processingSub = null;

    final player = _player;
    if (player != null) {
      await player.stop();
      await player.dispose();
      _player = null;
    }
    state = const AudioPlayerState();
  }

  void _disposePlayer() {
    // Best-effort fire-and-forget; a Notifier's onDispose can't await.
    unawaited(_stopInternal());
  }
}

final audioPlayerServiceProvider =
    NotifierProvider<AudioPlayerService, AudioPlayerState>(
  AudioPlayerService.new,
);
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/core/services/audio_player/audio_player_service_test.dart`

Expected: PASS, all tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/audio_player/audio_player_service.dart \
        test/core/services/audio_player/audio_player_service_test.dart
git commit -m "feat(audio): add AudioPlayerService backed by just_audio"
```

---

## Task 10: Create `AudioPlayerWidget` mini-bar

**Files:**
- Create: `lib/shared/widgets/audio_player/audio_player_widget.dart`
- Test: `test/shared/widgets/audio_player/audio_player_widget_test.dart`

The widget renders a row with: play/pause icon · song title · close icon · slider · current time / total time. Visible only when `state.hasFile`. The slider's `onChangeStart` calls `startSeeking()`, `onChanged` updates a local "drag" value (so the knob follows the finger smoothly), and `onChangeEnd` calls `stopSeeking(Duration)`.

Keep it Material — Ionic's component is `ion-icon` + `ion-range`; in Flutter we use `Icons` and `Slider`.

- [ ] **Step 1: Write the failing widget test**

Create `test/shared/widgets/audio_player/audio_player_widget_test.dart`:

```dart
import 'package:attendix/core/services/audio_player/audio_player_service.dart';
import 'package:attendix/core/services/audio_player/audio_player_state.dart';
import 'package:attendix/shared/widgets/audio_player/audio_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubService extends AudioPlayerService {
  _StubService(this._state);
  AudioPlayerState _state;

  @override
  AudioPlayerState build() => _state;

  void setForTest(AudioPlayerState s) {
    _state = s;
    state = s;
  }
}

Widget _harness({required AudioPlayerState initial}) {
  final stub = _StubService(initial);
  return ProviderScope(
    overrides: [
      audioPlayerServiceProvider.overrideWith(() => stub),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AudioPlayerWidget()),
    ),
  );
}

void main() {
  group('AudioPlayerWidget', () {
    testWidgets('renders nothing when no file is loaded', (tester) async {
      await tester.pumpWidget(_harness(initial: const AudioPlayerState()));
      expect(find.byType(Slider), findsNothing);
      expect(find.byIcon(Icons.play_circle_fill), findsNothing);
    });

    testWidgets('shows song title and current/total time when a file is loaded',
        (tester) async {
      await tester.pumpWidget(_harness(
        initial: const AudioPlayerState(
          currentUrl: 'https://example.com/a.mp3',
          currentFileName: 'a.mp3',
          currentSongName: 'Konzert in D',
          isPlaying: true,
          currentTime: Duration(seconds: 12),
          duration: Duration(minutes: 3, seconds: 30),
        ),
      ));

      expect(find.text('Konzert in D'), findsOneWidget);
      expect(find.text('0:12'), findsOneWidget);
      expect(find.text('3:30'), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('falls back to file name when songName is empty',
        (tester) async {
      await tester.pumpWidget(_harness(
        initial: const AudioPlayerState(
          currentUrl: 'https://example.com/foo.mp3',
          currentFileName: 'foo.mp3',
          duration: Duration(minutes: 1),
        ),
      ));

      expect(find.text('foo.mp3'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/shared/widgets/audio_player/audio_player_widget_test.dart`

Expected: FAIL — widget doesn't exist.

- [ ] **Step 3: Implement the widget**

Create `lib/shared/widgets/audio_player/audio_player_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_player/audio_player_service.dart';

/// Mini audio player bar. Hidden when no file is loaded.
///
/// Mirrors Ionic v4.0.5 `audio-player.component.html` layout:
/// `[play/pause] [title]   [close]
///                [time]   [slider]   [time]`
class AudioPlayerWidget extends ConsumerStatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  // Local drag value for smooth slider feedback during a drag gesture.
  double? _dragValueMs;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioPlayerServiceProvider);
    if (!state.hasFile) return const SizedBox.shrink();

    final svc = ref.read(audioPlayerServiceProvider.notifier);
    final maxMs = state.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
    final value = _dragValueMs ?? state.currentTime.inMilliseconds.toDouble();
    final clamped = value.clamp(0.0, maxMs);

    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                state.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                size: 36,
              ),
              onPressed: svc.togglePlayPause,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.currentSongName.isNotEmpty
                              ? state.currentSongName
                              : (state.currentFileName ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Schließen',
                        onPressed: svc.stop,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        AudioPlayerService.formatTime(state.currentTime),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Expanded(
                        child: Slider(
                          min: 0,
                          max: maxMs,
                          value: clamped,
                          onChangeStart: (_) {
                            svc.startSeeking();
                          },
                          onChanged: (v) {
                            setState(() => _dragValueMs = v);
                          },
                          onChangeEnd: (v) async {
                            setState(() => _dragValueMs = null);
                            await svc.stopSeeking(
                              Duration(milliseconds: v.round()),
                            );
                          },
                        ),
                      ),
                      Text(
                        AudioPlayerService.formatTime(state.duration),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/shared/widgets/audio_player/audio_player_widget_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/audio_player/audio_player_widget.dart \
        test/shared/widgets/audio_player/audio_player_widget_test.dart
git commit -m "feat(audio): add AudioPlayerWidget mini-bar"
```

---

## Task 11: Mount `AudioPlayerWidget` inside `MainShell`

**Files:**
- Modify: `lib/shared/widgets/layout/main_shell.dart`
- Modify: `ios/Runner/Info.plist`

The widget must sit just above the bottom navigation so it's visible on every shell route. We add it as a `bottomSheet` inside the `Scaffold` that `MainShell` already builds. The `Info.plist` change adds `audio` to `UIBackgroundModes`, matching Ionic's behavior of letting recordings keep playing after the screen locks.

- [ ] **Step 1: Inspect the current `MainShell.build`**

Run: `grep -n "Scaffold(\|bottomNavigationBar:\|body:" lib/shared/widgets/layout/main_shell.dart | head -10`

Locate the `Scaffold(...)` returned from `build` (the one with `body: child` and a bottom nav). The widget will be added there.

- [ ] **Step 2: Insert the audio bar**

In `lib/shared/widgets/layout/main_shell.dart`:

1. Add this import next to the existing ones:

   ```dart
   import '../audio_player/audio_player_widget.dart';
   ```

2. In the returned `Scaffold` add `bottomSheet: const AudioPlayerWidget(),`. If the file already passes a `bottomSheet`, leave that one and instead wrap the body so the audio bar sits just above the bottom nav. Concretely, change the `body:` from `child` to:

   ```dart
   body: Column(
     children: [
       Expanded(child: child),
       const AudioPlayerWidget(),
     ],
   ),
   ```

   The widget renders `SizedBox.shrink()` when no file is playing, so it costs nothing visually when idle.

- [ ] **Step 3: Add iOS background-audio entitlement**

In `ios/Runner/Info.plist`, add (or extend) the `UIBackgroundModes` array so it contains `audio`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

If `UIBackgroundModes` is already present, add `<string>audio</string>` to the existing `<array>`. Do NOT remove other entries (e.g., `remote-notification` will be added in Sprint 1b).

- [ ] **Step 4: Pod install**

Run: `cd ios && pod install && cd ..`

Expected: `just_audio` and its dependencies are installed in `ios/Pods/`.

- [ ] **Step 5: Smoke test on chrome**

Run: `flutter run -d chrome` (or `flutter analyze` if device is unavailable).

Expected: app boots, you can navigate the shell, no audio bar is visible (correct — no file is playing).

- [ ] **Step 6: Run the full test suite**

Run: `flutter test`

Expected: all tests still green. If any layout test asserts on `Scaffold.body` shape, update it to expect the new `Column`.

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/layout/main_shell.dart ios/Runner/Info.plist
git commit -m "feat(audio): mount AudioPlayerWidget in MainShell + iOS background audio"
```

---

## Task 12: Version bump and release notes

**Files:**
- Modify: `pubspec.yaml`
- Modify: `assets/version_history.json`
- Modify: `lib/core/constants/app_constants.dart`

Per the Master Spec (section 2.4), every sprint bumps the version. Sprint 1a is a Minor bump because we're shipping new architecture pieces (TrackingService + AudioPlayerService) that other sprints will build on.

- [ ] **Step 1: Bump `pubspec.yaml`**

Change the `version:` line in `pubspec.yaml`:

```yaml
version: 0.2.0+29
```

(Current is `0.1.27+28`.)

- [ ] **Step 2: Append to `assets/version_history.json`**

Open the file and add a new top-level entry (it's a JSON array — newest first; mirror existing entries' shape):

```json
{
  "version": "0.2.0",
  "date": "19.6.2026",
  "changes": [
    "🏗️ Foundation: Tracking-Service & Audio-Player",
    "📊 TrackingService schreibt anonyme Nutzungs-Events (für Dashboard)",
    "🎵 AudioPlayerService + Mini-Bar im App-Shell für Aufnahmen",
    "🔄 PageView-Tracking via GoRouter Observer (Login/Legal ausgeschlossen)"
  ]
}
```

If the file already has a `0.2.0` entry, replace it. Use the exact date `19.6.2026` (matches Ionic's display style elsewhere; confirm format matches existing entries — adjust if the project uses ISO dates).

- [ ] **Step 3: Update `app_constants.dart`**

In `lib/core/constants/app_constants.dart` change:

```dart
static const String appVersion = '0.2.0';
```

- [ ] **Step 4: Verify build**

Run: `flutter analyze` and `flutter test`.

Expected: green.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml assets/version_history.json lib/core/constants/app_constants.dart
git commit -m "chore: bump version to 0.2.0+29 (Sprint 1a foundation)"
```

---

## Task 13: Code review and merge prep

**Files:** none modified directly — review-only step.

Per Master Spec section 2.2, every sprint runs both code reviewers in parallel before merge.

- [ ] **Step 1: Run flutter-reviewer agent on the diff**

Use the Agent tool with `subagent_type: "flutter-reviewer"` and a prompt like:

> Review the diff between `master` and the current branch for Sprint 1a (Tracking + Audio Foundation). Focus areas:
> - TrackingService is fire-and-forget and never throws to UI
> - No `ref.read(supabaseClientProvider)` outside `lib/data/repositories/`
> - No force-unwrap on `tenant.id!` anywhere
> - AudioPlayerService disposes its `just_audio` instance correctly
> - All new code follows the project's Riverpod naming conventions

- [ ] **Step 2: Run general code-reviewer agent in parallel**

Use the Agent tool with `subagent_type: "pr-review-toolkit:code-reviewer"` on the same diff. Address every reported issue and re-run tests after fixes.

- [ ] **Step 3: Final test run**

Run: `flutter test --coverage` and `dart analyze lib/`.

Expected: all tests green, no analyzer warnings.

- [ ] **Step 4: Open / update PR**

Either commit-push for direct merge or open a PR with this body:

```
Sprint 1a — Tracking + Audio Foundation

Closes part of #220 (TrackingService + AudioPlayerService foundation).
Foundation work for #211, #212, #213, #216, #217.

Changes:
- TrackingService (29 events, GoRouter observer, /login + /legal filter)
- UsageEventsRepository
- AudioPlayerService (just_audio backed Riverpod Notifier)
- AudioPlayerWidget mini-bar in MainShell
- iOS background-audio entitlement
- Version bump 0.2.0+29

Reference: docs/superpowers/specs/2026-06-19-migration-v4.0.5-master-strategy.md
```

- [ ] **Step 5: Wait for user review (STOP-PUNKT)**

Per Master Spec section 8, no merge before user explicitly approves.

- [ ] **Step 6: Merge and clean up**

After approval:

```bash
git checkout master
git merge --no-ff <sprint-branch>
git push origin master
gh issue comment 220 --body "Sprint 1a foundation merged: TrackingService + AudioPlayerService + AudioPlayerWidget. Dashboard piece of this issue still open (Sprint 5)."
```

Then exit the worktree per the master spec workflow (keep or remove).

---

## Self-Review Notes (filled in after writing the plan)

- **Spec coverage:** Master Spec section 4.1 (Sprint 1a) lists TrackingService, AudioPlayerService, AudioPlayerWidget, and the Tabs-Shell integration — all four covered (Tasks 5, 9, 10, 11 respectively). Section 4.1's acceptance criteria (5 items) are addressed in Tasks 11 (smoke test), 12 (version bump), 13 (analyzer + test + reviewers + issue update). The 27-events-list grew to 29 because the source has two additional diagnostic events (`attendance_type_unresolved`, `attendance_secondary_init_failed`); see Task 2 — flagged here so the master spec wording is updated post-merge.
- **Placeholder scan:** No "TBD"/"TODO"/"similar to X"/"add appropriate Y" remain.
- **Type consistency:** `AudioPlayerState` is referenced consistently across Tasks 8, 9, 10. `TrackingEvent` is referenced consistently across Tasks 2, 5, 6. `UsageEvent` is referenced across Tasks 3, 4. Provider names (`trackingServiceProvider`, `audioPlayerServiceProvider`, `audioPlayerFactoryProvider`, `usageEventsRepositoryProvider`, `trackingDeviceTypeProvider`) are stable.
- **Open assumption to verify on first task run:** the Riverpod `Ref.container` API used in Task 7 — if the project's pinned Riverpod version exposes the container differently, swap to `ref.read(...)` from inside an observer that holds `Ref` directly. Either path achieves the same goal.
