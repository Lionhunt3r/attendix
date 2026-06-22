# Sprint 2a — Repository-Bypass-Refactor (Existing Repos) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the **non-cross-tenant, non-Realtime, non-Storage** bypass stellen from direct `supabase.from(...)` calls to repository methods. Plus fix the pre-existing `auth_service.dart` bug (wrong table name). This establishes the migration pattern for Sprints 2b (new repos) and 2c (cross-tenant + Realtime + Storage + core/providers).

**Architecture:**
- Replace every `ref.read(supabaseClientProvider)` in UI/page/provider code with a call to an existing repository (mostly `AttendanceRepository.updateAttendance`, `PlayerRepository.getPlayers`, `GroupRepository.getGroups`, etc.).
- Replace every `tenant.id!` force-unwrap with a `hasTenantId`-guard or nullable propagation through the repo layer (the repos already handle tenant filtering via `TenantAwareRepository` mixin).
- Fix `auth_service.dart` to use the actual DB table name `tenantUsers` (camelCase, quoted) with columns `userId`/`tenantId` (camelCase), not the wrong `tenant_users`/`user_id`/`tenant_id`. This is a pre-existing bug that survives only because the broken code path is rarely hit and probably fails silently.

**Tech Stack:** Flutter, Riverpod, existing `AttendanceRepository`/`PlayerRepository`/`GroupRepository`/`SongRepository` (all with `TenantAwareRepository` mixin).

**Out of scope (for Sprint 2b/2c):**
- Realtime subscriptions in `attendance_detail_page.dart:203, 224` — Sprint 2c
- Storage upload in `attendance_detail_page.dart:1615` — Sprint 2c
- Cross-tenant operations (copy-to-tenant, handover-helpers) — Sprint 2c
- New repositories (`TenantUserRepository`, `HistoryRepository`, `TenantRepository`) — Sprint 2b
- ~25 bypass hits in `lib/core/providers/*` — Sprint 2c

---

## File Structure

**Modified files (no new files):**
- `lib/features/members/data/providers/members_providers.dart` (lines 22, 31, 45)
- `lib/features/parents/data/providers/parents_providers.dart` (lines 205, 213, 230)
- `lib/core/providers/self_service_providers.dart` (lines 167-188 — `currentSelfServicePlayerProvider`)
- `lib/features/voice_leader/data/providers/voice_leader_providers.dart` (lines 35, 45, 57, 71, 83)
- `lib/features/planning/presentation/pages/planning_page.dart` (lines 59, 68, 78, 86, 883, 888, 904, 915)
- `lib/features/attendance/presentation/pages/attendance_detail_page.dart` (16 DB-update stellen — Realtime/Storage stellen 203/224/1615 EXPLICITLY skipped)
- `lib/features/people/presentation/pages/person_detail_page.dart` (`_saveChanges` lines 544-569 only — `_updateUserRole`/`_unlinkAccount` are Sprint 2b)
- `lib/data/services/auth_service.dart` (lines 79-82, 100-105, 116-122, 148-152 — bugfix)
- `lib/data/repositories/attendance_repository.dart` (optional: small new methods like `setSongs(id, songIds, conductorIds)` for `_syncHistoryEntries` if needed)
- `lib/data/repositories/player_repository.dart` (optional: small additions for parents-provider needs)
- `pubspec.yaml` (version bump)
- `assets/version_history.json` (version bump)
- `lib/core/constants/app_constants.dart` (version bump)

**Test files added/modified:**
- For each migrated file, ensure existing tests still pass. Where a file has no test, add a minimal smoke test that the repo method is called (mocktail verify).
- `test/data/services/auth_service_test.dart` — likely missing today, add minimal source-code-analysis test that confirms `tenantUsers` (camelCase) is used.

---

## Pre-Conditions Check

Before starting, verify:

- Worktree `.worktrees/sprint-2a-repo-migration` exists, `.env` copied in.
- `dart analyze lib/` baseline (currently 24 pre-existing infos, 0 errors).
- `flutter test` baseline (currently 419 tests passing on master after Sprint 1a merge).
- Pull latest master into the worktree branch.

If any of those is not true, stop and address it before starting.

---

## Task 1: Migrate `members_providers.dart`

The simplest stelle — top-level FutureProvider with two `from('...')` calls (`instruments` and `player`). Both have existing repository methods.

**Files:**
- Modify: `lib/features/members/data/providers/members_providers.dart`

- [ ] **Step 1: Read the current implementation**

Run: `cat lib/features/members/data/providers/members_providers.dart | head -80`

Identify the FutureProvider body. Two queries to migrate:
- `from('instruments').select().eq('tenantId', tenant.id!)` → `GroupRepository.getGroups()`
- `from('player').select().eq('tenantId', tenant.id!)` → `PlayerRepository.getPlayers()`

- [ ] **Step 2: Verify which providers exist**

Run:
```
grep -n "groupRepositoryWithTenantProvider\|playerRepositoryWithTenantProvider" lib/core/providers/group_providers.dart lib/core/providers/player_providers.dart
```

Confirm both `*WithTenantProvider` exist.

- [ ] **Step 3: Rewrite the FutureProvider**

Replace the body (current ~50 lines including direct supabase calls) with this pattern:

```dart
final membersGroupedProvider = FutureProvider<List<MemberGroup>>((ref) async {
  final groupRepo = ref.watch(groupRepositoryWithTenantProvider);
  final playerRepo = ref.watch(playerRepositoryWithTenantProvider);
  if (!groupRepo.hasTenantId || !playerRepo.hasTenantId) return [];

  final groups = await groupRepo.getGroups();
  final players = await playerRepo.getPlayers();

  // [Existing in-Dart grouping logic preserved — group players by instrument]
  // [Filter and ordering rules from the original code stay unchanged]
});
```

Preserve all in-Dart logic (filtering, sorting, grouping) exactly. Only the data-fetch is migrated.

- [ ] **Step 4: Run analyzer**

Run: `dart analyze lib/features/members/data/providers/members_providers.dart`

Expected: no errors.

- [ ] **Step 5: Run existing tests for this provider**

Run: `flutter test test/features/members/` (or wherever members-related tests live)

Expected: all pass.

- [ ] **Step 6: Add a regression test for the bypass**

Append to (or create) `test/features/members/data/providers/members_providers_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 2a guard: members_providers must NOT use supabaseClientProvider
/// directly (would violate the repository pattern).
void main() {
  test('members_providers uses repositories, not supabaseClientProvider', () {
    final source = File(
      'lib/features/members/data/providers/members_providers.dart',
    ).readAsStringSync();

    expect(
      source,
      isNot(contains('supabaseClientProvider')),
      reason: 'Repository-bypass forbidden in members_providers',
    );
    expect(
      source,
      isNot(contains('tenant.id!')),
      reason: 'Force-unwrap on tenant.id! forbidden',
    );
    expect(
      source,
      contains('RepositoryWithTenantProvider'),
      reason: 'Must use a *WithTenantProvider',
    );
  });
}
```

- [ ] **Step 7: Run the new test**

Run: `flutter test test/features/members/data/providers/members_providers_test.dart`

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/members/data/providers/members_providers.dart \
        test/features/members/data/providers/members_providers_test.dart
git commit -m "refactor(members): migrate to repository pattern

- members_providers reads via GroupRepository.getGroups() and
  PlayerRepository.getPlayers() instead of direct supabase calls
- removes tenant.id! force-unwraps (repos enforce tenantId via mixin)
- adds source-grep regression test"
```

---

## Task 2: Migrate `self_service_providers.dart` (currentSelfServicePlayerProvider)

Trivial one-method migration. The provider at lines 167-188 queries `player` by `appId` and `tenantId`. `PlayerRepository.getPlayerByAppId(String appId)` already exists with the tenant filter built in.

**Files:**
- Modify: `lib/core/providers/self_service_providers.dart`

- [ ] **Step 1: Read the provider**

Run: `sed -n '160,195p' lib/core/providers/self_service_providers.dart`

- [ ] **Step 2: Confirm `getPlayerByAppId` exists on PlayerRepository**

Run: `grep -n "getPlayerByAppId" lib/data/repositories/player_repository.dart`

Expected: a method signature `Future<Person?> getPlayerByAppId(String appId)`.

- [ ] **Step 3: Rewrite the provider**

Replace the supabase-based body with:

```dart
final currentSelfServicePlayerProvider = FutureProvider<Person?>((ref) async {
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId = authState?.session?.user.id;
  if (userId == null) return null;

  final repo = ref.watch(playerRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return null;

  return repo.getPlayerByAppId(userId);
});
```

(Adjust the imports if `Person` model is not already imported.)

- [ ] **Step 4: Run analyzer + tests**

Run:
```
dart analyze lib/core/providers/self_service_providers.dart
flutter test test/features/self_service/
```

Expected: both clean.

- [ ] **Step 5: Commit**

```bash
git add lib/core/providers/self_service_providers.dart
git commit -m "refactor(self-service): migrate currentSelfServicePlayerProvider to repo"
```

---

## Task 3: Migrate `voice_leader_providers.dart`

Three providers (currentPlayer, voiceGroupName, voiceGroupMembers). Need 1 new repo method (`PlayerRepository.getPlayersByInstrument`).

**Files:**
- Modify: `lib/features/voice_leader/data/providers/voice_leader_providers.dart`
- Modify: `lib/data/repositories/player_repository.dart` (add method)

- [ ] **Step 1: Add `getPlayersByInstrument` to PlayerRepository**

In `lib/data/repositories/player_repository.dart`, find a logical place (e.g., near `getPlayers()`):

```dart
/// Returns all active players assigned to the given instrument/group,
/// in the current tenant. Excludes paused and left players.
Future<List<Person>> getPlayersByInstrument(int instrumentId) async {
  try {
    final response = await supabase
        .from('player')
        .select('*')
        .eq('tenantId', currentTenantId)
        .eq('instrument', instrumentId)
        .filter('left', 'is', null)
        .eq('paused', false)
        .order('lastName', ascending: true);

    return (response as List)
        .map((e) => Person.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, stack) {
    handleError(e, stack, 'getPlayersByInstrument');
    rethrow;
  }
}
```

- [ ] **Step 2: Add a smoke test in the existing player_repository_test.dart**

Append in the existing test group:

```dart
test('getPlayersByInstrument includes tenantId filter', () {
  final section = _extractMethodBody(playerRepoSource, 'getPlayersByInstrument');
  expect(section, isNotNull, reason: 'getPlayersByInstrument should exist');
  expect(
    section,
    contains(".eq('tenantId', currentTenantId)"),
    reason: 'must filter by tenantId',
  );
});
```

(Use the project's existing `_extractMethodBody` helper from neighboring tests.)

- [ ] **Step 3: Run repo tests**

Run: `flutter test test/data/repositories/player_repository_test.dart`

Expected: all pass (existing + new).

- [ ] **Step 4: Migrate currentPlayerProvider in voice_leader_providers.dart**

Replace lines 34-50 (the `from('player').select().eq('appId').eq('tenantId').maybeSingle()` block) with:

```dart
final currentPlayerProvider = FutureProvider<Person?>((ref) async {
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId = authState?.session?.user.id;
  if (userId == null) return null;

  final repo = ref.watch(playerRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return null;

  return repo.getPlayerByAppId(userId);
});
```

- [ ] **Step 5: Migrate voiceGroupNameProvider**

Replace the lines 52-67 (the `from('instruments').select('shortName').eq('id', ...).maybeSingle()` block) with a call to `GroupRepository.getGroupById(int)`:

```dart
final voiceGroupNameProvider = FutureProvider.family<String?, int>((ref, instrumentId) async {
  final repo = ref.watch(groupRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return null;
  final group = await repo.getGroupById(instrumentId);
  return group?.shortName;
});
```

Verify `getGroupById` exists on `GroupRepository`. If only `getGroups()` exists, add `getGroupById(int)` in `lib/data/repositories/group_repository.dart`:

```dart
Future<Group?> getGroupById(int id) async {
  try {
    final response = await supabase
        .from('instruments')
        .select('*')
        .eq('id', id)
        .eq('tenantId', currentTenantId)
        .maybeSingle();
    if (response == null) return null;
    return Group.fromJson(response);
  } catch (e, stack) {
    handleError(e, stack, 'getGroupById');
    rethrow;
  }
}
```

And add the corresponding repo-test entry.

- [ ] **Step 6: Migrate voiceGroupMembersProvider**

Replace lines 69-95 (the player query + person_attendances query) with two repo calls:

```dart
final voiceGroupMembersProvider = FutureProvider.family<List<VoiceGroupMember>, int>((ref, instrumentId) async {
  final playerRepo = ref.watch(playerRepositoryWithTenantProvider);
  final attendanceRepo = ref.watch(attendanceRepositoryWithTenantProvider);
  if (!playerRepo.hasTenantId) return [];

  final players = await playerRepo.getPlayersByInstrument(instrumentId);
  final upcomingAbsences = await attendanceRepo.getUpcomingAbsencesForPersons(
    players.map((p) => p.id!).toList(),
  );

  // [Existing combination logic preserved unchanged]
});
```

`getUpcomingAbsencesForPersons` may not yet exist on `AttendanceRepository`. If not, add it:

```dart
/// Returns person_attendances for the given persons where the attendance
/// is upcoming (date >= today) and status is excused/absent/late_excused.
Future<List<PersonAttendance>> getUpcomingAbsencesForPersons(
  List<int> personIds,
) async {
  if (personIds.isEmpty) return [];
  final today = DateTime.now().toIso8601String().substring(0, 10);
  try {
    final response = await supabase
        .from('person_attendances')
        .select('*, attendance!inner(id, date, tenantId)')
        .inFilter('person_id', personIds)
        .inFilter('status', [2, 4, 5])
        .gte('attendance.date', today)
        .eq('attendance.tenantId', currentTenantId);

    return (response as List)
        .map((e) => PersonAttendance.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, stack) {
    handleError(e, stack, 'getUpcomingAbsencesForPersons');
    rethrow;
  }
}
```

Add a repo-test for it.

- [ ] **Step 7: Run all related tests**

```
flutter test test/data/repositories/player_repository_test.dart
flutter test test/data/repositories/attendance_repository_test.dart
flutter test test/data/repositories/group_repository_test.dart
flutter test test/features/voice_leader/
```

Expected: all green.

- [ ] **Step 8: Add bypass regression test**

`test/features/voice_leader/data/providers/voice_leader_providers_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voice_leader_providers uses repositories, not supabaseClientProvider', () {
    final source = File(
      'lib/features/voice_leader/data/providers/voice_leader_providers.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('supabaseClientProvider')));
    expect(source, isNot(contains('tenant.id!')));
  });
}
```

- [ ] **Step 9: Commit**

```bash
git add lib/data/repositories/player_repository.dart \
        lib/data/repositories/group_repository.dart \
        lib/data/repositories/attendance_repository.dart \
        lib/features/voice_leader/data/providers/voice_leader_providers.dart \
        test/data/repositories/ \
        test/features/voice_leader/
git commit -m "refactor(voice-leader): migrate to repository pattern

- adds PlayerRepository.getPlayersByInstrument
- adds GroupRepository.getGroupById (if missing)
- adds AttendanceRepository.getUpcomingAbsencesForPersons
- all three voice_leader providers now use *WithTenantProvider
- removes tenant.id! force-unwraps
- adds source-grep regression test"
```

---

## Task 4: Migrate `parents_providers.dart`

Two providers: `parentChildrenProvider` (line 200-222) and `childrenAttendancesProvider` (line 225+).

**Files:**
- Modify: `lib/features/parents/data/providers/parents_providers.dart`
- Modify: `lib/data/repositories/player_repository.dart` (add `getChildrenForParent(int parentId)`)
- Modify: `lib/data/repositories/attendance_repository.dart` (add `getPersonAttendancesForPersons(List<int> personIds)` if not exists)

- [ ] **Step 1: Read both providers**

Run: `sed -n '200,280p' lib/features/parents/data/providers/parents_providers.dart`

- [ ] **Step 2: Add `getChildrenForParent` to PlayerRepository**

```dart
/// Returns players whose `parent` field equals [parentId], in the
/// current tenant. Skips left and pending players.
Future<List<Person>> getChildrenForParent(int parentId) async {
  try {
    final response = await supabase
        .from('player')
        .select('*')
        .eq('tenantId', currentTenantId)
        .eq('parent', parentId)
        .filter('left', 'is', null)
        .eq('pending', false)
        .order('firstName', ascending: true);

    return (response as List)
        .map((e) => Person.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, stack) {
    handleError(e, stack, 'getChildrenForParent');
    rethrow;
  }
}
```

Verify the actual schema column name first — it might be `parent_id` or `parentId`. Run: `grep -n "parent" lib/data/models/person/person.dart | head -10`.

- [ ] **Step 3: Add `getPersonAttendancesForPersons` to AttendanceRepository**

If it doesn't exist:

```dart
/// Returns all person_attendances for the given person IDs in the
/// current tenant. Used for parent-portal multi-child views.
Future<List<PersonAttendance>> getPersonAttendancesForPersons(
  List<int> personIds, {
  String? sinceDate,
  String? untilDate,
}) async {
  if (personIds.isEmpty) return [];
  try {
    var query = supabase
        .from('person_attendances')
        .select('*, attendance!inner(*)')
        .inFilter('person_id', personIds)
        .eq('attendance.tenantId', currentTenantId);

    if (sinceDate != null) query = query.gte('attendance.date', sinceDate);
    if (untilDate != null) query = query.lte('attendance.date', untilDate);

    final response = await query;

    return (response as List)
        .map((e) => PersonAttendance.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, stack) {
    handleError(e, stack, 'getPersonAttendancesForPersons');
    rethrow;
  }
}
```

- [ ] **Step 4: Repo tests for both new methods**

Add source-grep tests in `player_repository_test.dart` and `attendance_repository_test.dart` confirming tenantId filter is present.

- [ ] **Step 5: Migrate `parentChildrenProvider`**

```dart
final parentChildrenProvider = FutureProvider<List<Person>>((ref) async {
  final currentPlayer = await ref.watch(currentSelfServicePlayerProvider.future);
  if (currentPlayer?.id == null) return [];

  final repo = ref.watch(playerRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return [];

  return repo.getChildrenForParent(currentPlayer!.id!);
});
```

- [ ] **Step 6: Migrate `childrenAttendancesProvider`**

```dart
final childrenAttendancesProvider = FutureProvider<List<PersonAttendance>>((ref) async {
  final children = await ref.watch(parentChildrenProvider.future);
  if (children.isEmpty) return [];

  final repo = ref.watch(attendanceRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return [];

  return repo.getPersonAttendancesForPersons(
    children.map((c) => c.id!).toList(),
  );
});
```

- [ ] **Step 7: Run tests**

```
flutter test test/data/repositories/player_repository_test.dart
flutter test test/data/repositories/attendance_repository_test.dart
flutter test test/features/parents/
```

Expected: all green.

- [ ] **Step 8: Add regression test**

`test/features/parents/data/providers/parents_providers_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parents_providers uses repositories, not supabaseClientProvider', () {
    final source = File(
      'lib/features/parents/data/providers/parents_providers.dart',
    ).readAsStringSync();

    // Note: this file may still contain other bypasses unrelated to
    // parentChildren/childrenAttendances (e.g. helpers being migrated
    // in later sprints). Scope the check to the two migrated providers.
    expect(source, isNot(contains('tenant.id!')),
        reason: 'Force-unwrap forbidden');
  });
}
```

Note: if `parents_providers.dart` still has unrelated `supabaseClientProvider` lines that belong to Sprint 2b/2c work, the test cannot blanket-forbid the symbol. Scope appropriately.

- [ ] **Step 9: Commit**

```bash
git add lib/data/repositories/player_repository.dart \
        lib/data/repositories/attendance_repository.dart \
        lib/features/parents/data/providers/parents_providers.dart \
        test/data/repositories/ \
        test/features/parents/
git commit -m "refactor(parents): migrate child + attendance providers to repos

- adds PlayerRepository.getChildrenForParent
- adds AttendanceRepository.getPersonAttendancesForPersons
- migrates parentChildrenProvider + childrenAttendancesProvider
- removes tenant.id! force-unwrap on parents_providers.dart:213"
```

---

## Task 5: Migrate `planning_page.dart`

Four bypass stellen: 2 top-level FutureProviders (upcomingAttendances, planSongs) + 2 mutation methods (`_savePlan`, `_toggleSharePlan`). All use existing repo methods.

**Files:**
- Modify: `lib/features/planning/presentation/pages/planning_page.dart`
- Modify: `lib/data/repositories/attendance_repository.dart` (verify `getUpcomingAttendances` exists with optional limit)

- [ ] **Step 1: Verify `AttendanceRepository.getUpcomingAttendances` signature**

Run: `grep -n "getUpcomingAttendances" lib/data/repositories/attendance_repository.dart`

If it exists without a `limit` parameter, add one. Default `null` (no limit) for backward compatibility.

- [ ] **Step 2: Migrate `upcomingAttendancesProvider` (line 56-75)**

Replace direct supabase query with:

```dart
final upcomingAttendancesProvider = FutureProvider<List<Attendance>>((ref) async {
  final repo = ref.watch(attendanceRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return [];
  return repo.getUpcomingAttendances(limit: 50);  // arbitrary upper bound
});
```

- [ ] **Step 3: Migrate `planSongsProvider` (line 78-95)**

Replace with `SongRepository.getSongs()` (already exists):

```dart
final planSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(songRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return [];
  return repo.getSongs();
});
```

- [ ] **Step 4: Migrate `_savePlan` (line 874-922)**

Replace the direct update with `AttendanceRepository.updateAttendance`:

```dart
Future<void> _savePlan() async {
  if (_attendance == null) return;
  final repo = ref.read(attendanceRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return;
  try {
    await repo.updateAttendance(_attendance!.id!, {
      'plan': _planFields.map((f) => f.toJson()).toList(),
      'time': _startTime,
      'end_time': _endTime,
    });
    if (mounted) ToastHelper.showSuccess(context, 'Plan gespeichert');
  } catch (e, stack) {
    if (mounted) ToastHelper.showError(context, 'Fehler beim Speichern');
  }
}
```

(Preserve the existing error-handling and state-reset logic exactly — only the supabase call is replaced.)

- [ ] **Step 5: Migrate `_toggleSharePlan` (lines 896-922)**

```dart
Future<void> _toggleSharePlan() async {
  if (_attendance == null) return;
  final repo = ref.read(attendanceRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return;
  try {
    await repo.updateAttendance(_attendance!.id!, {
      'share_plan': !_attendance!.sharePlan,
    });
    ref.invalidate(attendanceDetailProvider(_attendance!.id!));
  } catch (e, stack) {
    if (mounted) ToastHelper.showError(context, 'Fehler beim Teilen');
  }
}
```

- [ ] **Step 6: Run analyzer + tests**

```
dart analyze lib/features/planning/presentation/pages/planning_page.dart
flutter test test/features/planning/
```

Expected: clean.

- [ ] **Step 7: Add regression test**

`test/features/planning/planning_page_bypass_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('planning_page does not use supabaseClientProvider directly', () {
    final source = File(
      'lib/features/planning/presentation/pages/planning_page.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('supabaseClientProvider')));
    expect(source, isNot(contains('tenant.id!')));
    expect(source, isNot(contains('tenant!.id!')));
  });
}
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/planning/presentation/pages/planning_page.dart \
        lib/data/repositories/attendance_repository.dart \
        test/features/planning/
git commit -m "refactor(planning): migrate 4 bypass stellen to AttendanceRepository

- upcomingAttendancesProvider + planSongsProvider use *WithTenantProvider
- _savePlan + _toggleSharePlan use updateAttendance(id, updates)
- removes 4× tenant.id!/tenant!.id! force-unwraps
- adds regression test for the file"
```

---

## Task 6: Migrate `person_detail_page.dart._saveChanges`

Only the `_saveChanges` stelle at lines 510-569 is in Sprint 2a. The other 7 bypass stellen in this file (`personProvider` line 23, `appointmentsProvider` line 49, accordion providers line 156, `_getUserRole` line 399, `_unlinkAccount` line 1283, etc.) are Sprint 2b (they involve `tenantUsers` and the new `TenantUserRepository`).

**Files:**
- Modify: `lib/features/people/presentation/pages/person_detail_page.dart` (only `_saveChanges`)

- [ ] **Step 1: Read the current `_saveChanges`**

Run: `sed -n '505,575p' lib/features/people/presentation/pages/person_detail_page.dart`

- [ ] **Step 2: Verify `PlayerRepository.updatePlayer` signature**

Run: `grep -n "updatePlayer\|updatePerson" lib/data/repositories/player_repository.dart`

Should accept `(int id, Map<String, dynamic> updates)` or similar. If only a `Person`-object overload exists, we need a Map-based variant.

- [ ] **Step 3: Add a Map-based update method if not present**

Add to `PlayerRepository`:

```dart
/// Update arbitrary fields on a player row. Used by inline-edit pages
/// where building a full Person object would be overkill.
Future<void> updatePlayerFields(int id, Map<String, dynamic> updates) async {
  try {
    // Remove read-only fields
    updates.remove('id');
    updates.remove('tenantId');
    updates.remove('created_at');

    await supabase
        .from('player')
        .update(updates)
        .eq('id', id)
        .eq('tenantId', currentTenantId);
  } catch (e, stack) {
    handleError(e, stack, 'updatePlayerFields');
    rethrow;
  }
}
```

Add source-grep test in `player_repository_test.dart` confirming tenantId filter.

- [ ] **Step 4: Migrate `_saveChanges`**

Replace the direct `supabase.from('player').update(...)` call (around line 544) with:

```dart
final repo = ref.read(playerRepositoryWithTenantProvider);
if (!repo.hasTenantId) return;
await repo.updatePlayerFields(widget.personId, {
  'firstName': _firstName,
  'lastName': _lastName,
  // ... all other fields kept verbatim
});
```

Preserve all build-up logic (history appendix, validation, etc.) exactly. Only the actual write call changes.

- [ ] **Step 5: Run analyzer + tests**

```
dart analyze lib/features/people/presentation/pages/person_detail_page.dart
flutter test test/features/people/
```

Expected: clean. Note: this file still contains other bypasses (Sprint 2b scope) — don't fix them here.

- [ ] **Step 6: Commit**

```bash
git add lib/features/people/presentation/pages/person_detail_page.dart \
        lib/data/repositories/player_repository.dart \
        test/data/repositories/player_repository_test.dart
git commit -m "refactor(person-detail): migrate _saveChanges to PlayerRepository

- adds PlayerRepository.updatePlayerFields(id, Map)
- _saveChanges now writes through the repo with automatic tenantId filter
- other bypass stellen in this file are Sprint 2b (TenantUserRepository scope)
- no regression-grep yet because file still has Sprint-2b stellen"
```

---

## Task 7: Migrate `attendance_detail_page.dart` DB-update stellen (16 calls)

The biggest single task in Sprint 2a. **Explicitly excluded:** Realtime (203, 224) and Storage (1615) — those go to Sprint 2c. **In scope:** 16 db-update stellen.

**Files:**
- Modify: `lib/features/attendance/presentation/pages/attendance_detail_page.dart` (16 stellen migrated)
- Possibly modify: `lib/data/repositories/attendance_repository.dart` (one new method if needed)

The stellen and their semantics:

| Line | Method | What it does | Target repo method |
|------|--------|--------------|---------------------|
| 235 | `_ensurePersonAttendances` | insert if missing | `AttendanceRepository.ensurePersonAttendances` (new — see below) |
| 485 | inline change-conductor | update attendance.conductors | `updateAttendance(id, {conductors: …})` |
| 586 | `validatePersonAttendanceTenant` | select 1 row | `AttendanceRepository.validatePersonAttendanceTenant` (new) |
| 622 | `_updatePersonNote` | update person_attendances.notes | `updatePersonAttendance(personAttId, {notes: …})` |
| 820 | `_takeStatusOverview` | update attendance.notes | `updateAttendance(id, {notes: …})` |
| 905 | `_saveTypeInfo` | update attendance.typeInfo | `updateAttendance(id, {typeInfo: …})` |
| 967 | `_saveDeadline` | update attendance.deadline | `updateAttendance(id, {deadline: …})` |
| 1194 | `_toggleChecklist` | update attendance.checklist | `updateAttendance(id, {checklist: …})` |
| 1254 | `_loadSongEntries` | select from history+attendance | `AttendanceRepository.getSongEntries(id)` (new) |
| 1293 | `_syncHistoryEntries` delete | delete from history | Sprint 2b's `HistoryRepository` (defer to 2b) |
| 1327 | `_saveStartTime` | update attendance.time | `updateAttendance(id, {time: …})` |
| 1369 | `_saveEndTime` | update attendance.end_time | `updateAttendance(id, {end_time: …})` |
| 1412 | `_toggleSharePlan` | update attendance.share_plan | `updateAttendance(id, {share_plan: …})` |
| 1486 | `_deletePersonAttendance` | delete person_attendances | `AttendanceRepository.deletePersonAttendance(id)` (new) |
| 1546 | `_savePlanFields` | update attendance.plan | `updateAttendance(id, {plan: …})` |
| 1681 | `_updateStatus` | update person_attendances.status | `updatePersonAttendance(personAttId, {status: …})` |

**Note:** Line 1293 (`_syncHistoryEntries` — delete from `history` table) is a Sprint-2b concern (needs `HistoryRepository`). Skip in 2a; leave a `// TODO(sprint-2b)` comment and the existing direct supabase call in place.

- [ ] **Step 1: Add three new methods to AttendanceRepository**

```dart
/// Ensures person_attendances rows exist for all active players of the
/// current tenant for [attendanceId]. Idempotent (uses upsert).
Future<void> ensurePersonAttendances(
  int attendanceId,
  int defaultStatus,
) async {
  try {
    // First, fetch players in this tenant who don't yet have a row
    // [logic from attendance_detail_page._ensurePersonAttendances 231-274,
    // preserved verbatim except for the supabase calls]
    // ... use this.supabase + currentTenantId via mixin
  } catch (e, stack) {
    handleError(e, stack, 'ensurePersonAttendances');
    rethrow;
  }
}

/// Returns true if the given person_attendances row belongs to an
/// attendance in the current tenant. Used to guard cross-tenant writes.
Future<bool> validatePersonAttendanceTenant(String personAttendanceId) async {
  try {
    final response = await supabase
        .from('person_attendances')
        .select('attendance!inner(tenantId)')
        .eq('id', personAttendanceId)
        .maybeSingle();
    if (response == null) return false;
    final attendance = response['attendance'] as Map<String, dynamic>?;
    return attendance?['tenantId'] == currentTenantId;
  } catch (e, stack) {
    handleError(e, stack, 'validatePersonAttendanceTenant');
    rethrow;
  }
}

/// Delete a single person_attendances row, after verifying it belongs
/// to the current tenant.
Future<void> deletePersonAttendance(String personAttendanceId) async {
  try {
    final isValid = await validatePersonAttendanceTenant(personAttendanceId);
    if (!isValid) throw RepositoryException(
      message: 'Cross-tenant delete attempted',
      operation: 'deletePersonAttendance',
    );
    await supabase
        .from('person_attendances')
        .delete()
        .eq('id', personAttendanceId);
  } catch (e, stack) {
    handleError(e, stack, 'deletePersonAttendance');
    rethrow;
  }
}

/// Returns the (songId, conductorId, otherConductor) tuples for the
/// `_syncHistoryEntries` UI in attendance_detail_page. Combines
/// attendance.songs / attendance.conductors with history table joins.
Future<List<({int songId, int? conductorId, String? otherConductor})>>
    getSongEntries(int attendanceId) async {
  // [implementation that matches the current SELECT in
  //  attendance_detail_page._loadSongEntries:1250-1280]
}
```

Add corresponding source-grep tests for tenantId filtering.

- [ ] **Step 2: Migrate the 16 in-scope stellen one method at a time**

For each line in the table above (except 1293), replace the `final supabase = ref.read(supabaseClientProvider); ... .from('...').update/delete/insert/select ...` block with the corresponding repo call. The boilerplate `if (tenant?.id == null) return` becomes `if (!repo.hasTenantId) return;` where `repo = ref.read(attendanceRepositoryWithTenantProvider)`.

For mutations that update many fields at once (like `_savePlanFields`), use `repo.updateAttendance(id, {…})` — pass the partial map.

For `updatePersonAttendance`, use the existing `repo.updatePersonAttendance(id, updates)`.

Group the migrations into 4 commits to keep them reviewable:
- Commit A: lines 235, 485, 586 (ensure + change-conductor + validate)
- Commit B: lines 622, 1681, 1486 (person_attendances mutations + delete)
- Commit C: lines 820, 905, 967, 1194, 1327, 1369, 1412, 1546 (attendance updates)
- Commit D: line 1254 (load song entries)

- [ ] **Step 3: For each commit, run analyzer + relevant tests**

```
dart analyze lib/features/attendance/presentation/pages/attendance_detail_page.dart
flutter test test/features/attendance/
flutter test test/data/repositories/attendance_repository_test.dart
```

Expected: clean after each commit.

- [ ] **Step 4: Leave Sprint 2b/2c TODOs**

After all in-scope stellen are migrated, the file should still contain exactly **3** `ref.read(supabaseClientProvider)` calls: lines 203 + 224 (Realtime) and 1615 (Storage). Plus the history-delete at line 1293.

Add comments above each remaining call:

```dart
// TODO(sprint-2c): migrate Realtime subscription to AttendanceRepository
final supabase = ref.read(supabaseClientProvider);
```

```dart
// TODO(sprint-2c): migrate Storage upload to AttendanceRepository.uploadAttendanceImage
final supabase = ref.read(supabaseClientProvider);
```

```dart
// TODO(sprint-2b): migrate history-delete to HistoryRepository.deleteForAttendance
final supabase = ref.read(supabaseClientProvider);
```

- [ ] **Step 5: Add partial regression test**

`test/features/attendance/attendance_detail_bypass_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attendance_detail_page has only 4 known bypasses left (2c/2b scope)', () {
    final source = File(
      'lib/features/attendance/presentation/pages/attendance_detail_page.dart',
    ).readAsStringSync();

    final hits = 'supabaseClientProvider'.allMatches(source).length;
    // 2 Realtime + 1 Storage + 1 history-delete = 4 documented exceptions.
    // When Sprint 2b and 2c finish, this should drop to 0.
    expect(hits, equals(4),
        reason: 'Only Realtime (2c), Storage (2c), and history-delete (2b) should remain. '
                'If you fixed any of those in Sprint 2a, lower this count and remove the TODO.');
  });
}
```

This is an exact-count assertion so any unintended bypass slipping back in gets caught.

---

## Task 8: Fix `auth_service.dart` (pre-existing bug)

The DB table is `tenantUsers` (camelCase, quoted-identifier) with columns `userId`/`tenantId` (camelCase). `auth_service.dart` uses `tenant_users` with `user_id`/`tenant_id`. The auth flow probably fails silently — fix it.

**Files:**
- Modify: `lib/data/services/auth_service.dart` (4 occurrences)
- New test: `test/data/services/auth_service_test.dart`

- [ ] **Step 1: Show the offending lines**

Run: `grep -n "tenant_users\|user_id\|tenant_id" lib/data/services/auth_service.dart`

Expected matches near lines 79, 100, 116, 148.

- [ ] **Step 2: Fix each occurrence**

For each `.from('tenant_users')`, replace with `.from('tenantUsers')`.

For each `'user_id': value` inside an insert/update map, replace with `'userId': value`.

For each `.eq('user_id', value)` filter, replace with `.eq('userId', value)`.

Same for `tenant_id` → `tenantId`.

- [ ] **Step 3: Add source-grep test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Pre-existing bug fix: auth_service.dart used the wrong table name
/// `tenant_users` (snake_case) while the actual DB table is `tenantUsers`
/// (camelCase). Same for the columns `user_id` / `tenant_id`. Confirmed
/// by inspecting Ionic db.service.ts and supabase/sql/enable_rls_all_tables.sql.
void main() {
  test('auth_service uses correct camelCase table and column names', () {
    final source = File('lib/data/services/auth_service.dart').readAsStringSync();

    expect(source, contains("from('tenantUsers')"),
        reason: 'must target tenantUsers (camelCase)');
    expect(source, isNot(contains("from('tenant_users')")),
        reason: 'tenant_users (snake_case) is wrong — fixed in Sprint 2a');

    // Spot-check that user_id / tenant_id no longer appear as bare
    // column names (they may still appear in code comments).
    expect(source, isNot(contains("'user_id'")),
        reason: 'column name is userId, not user_id');
    expect(source, isNot(contains("'tenant_id'")),
        reason: 'column name is tenantId, not tenant_id');
  });
}
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/data/services/auth_service_test.dart`

Expected: PASS after the fix, FAIL before.

- [ ] **Step 5: Run analyzer + full test suite**

```
dart analyze lib/data/services/auth_service.dart
flutter test
```

Expected: clean.

- [ ] **Step 6: Commit**

```bash
git add lib/data/services/auth_service.dart test/data/services/auth_service_test.dart
git commit -m "fix(auth): use correct tenantUsers casing in AuthService

Pre-existing bug discovered during Sprint 2 verification:
auth_service.dart used \`from('tenant_users')\` with columns
\`user_id\`/\`tenant_id\` (snake_case) while the actual DB table
is \`tenantUsers\` (camelCase) with columns \`userId\`/\`tenantId\`,
as confirmed by:
- Ionic db.service.ts (all queries use tenantUsers)
- supabase/sql/enable_rls_all_tables.sql RLS policies on \"tenantUsers\"

The bug survived because createAccountForPerson and related auth flows
are rarely hit and probably swallow the resulting Postgres error.

Adds regression test that asserts the correct table/column names."
```

---

## Task 9: Final verification + version bump

- [ ] **Step 1: Run full test suite**

Run: `flutter test`

Expected: all tests pass (baseline 419 + new regression tests).

- [ ] **Step 2: Run analyzer**

Run: `dart analyze lib/`

Expected: 24 pre-existing infos, 0 errors.

- [ ] **Step 3: Count remaining `supabaseClientProvider` hits outside repos**

Run:
```
grep -rn "ref\.\(read\|watch\)(supabaseClientProvider)" lib/ | grep -v "data/repositories" | grep -v "data/services/auth_service.dart" | wc -l
```

Expected: a smaller number than the baseline (~100). Note it in the commit message for Sprint 2a so we can track progress.

- [ ] **Step 4: Count remaining `tenant.id!` hits**

Run: `grep -rn "tenant\.id!" lib/ | wc -l`

Expected: less than 35 (baseline). Note in commit message.

- [ ] **Step 5: Version bump**

Update three files:
- `pubspec.yaml`: `0.2.0+29` → `0.2.1+30`
- `lib/core/constants/app_constants.dart`: `appVersion = '0.2.0'` → `'0.2.1'`
- `assets/version_history.json`: prepend new entry:

```json
{
  "version": "0.2.1",
  "date": "22.6.2026",
  "changes": [
    "🏗️ Architektur: 7 Pages/Provider auf Repository-Pattern migriert",
    "🐛 AuthService: Tabellenname (tenantUsers) und Spalten (userId/tenantId) korrigiert",
    "🧪 Regressions-Tests gegen Repository-Bypass eingebaut"
  ]
}
```

- [ ] **Step 6: Commit version bump**

```bash
git add pubspec.yaml lib/core/constants/app_constants.dart assets/version_history.json
git commit -m "chore: bump version to 0.2.1+30 (Sprint 2a)"
```

---

## Task 10: Code review + merge prep

- [ ] **Step 1: Run flutter-reviewer in parallel with pr-review-toolkit:code-reviewer on the diff master..HEAD**

Both should focus on:
- No new `supabaseClientProvider` reads outside repos / auth_service
- No new `tenant.id!` force-unwraps
- Repo methods that were added have tenantId filter (and source-grep test)
- Migrated providers still preserve all in-Dart logic (no behavior change)
- The `attendance_detail_page` partial-migration is correctly bounded by TODO comments + the exact-count regression test

- [ ] **Step 2: Address findings**

- [ ] **Step 3: User-review-gate (STOP-PUNKT)**

Per Master Spec section 8, no merge before user explicitly approves.

- [ ] **Step 4: Merge to master**

```bash
git checkout master
git merge --no-ff worktree-sprint-2a-repo-migration
git push origin master
gh issue comment 219 --body "Sprint 2a complete: 7 of ~15 plan stellen migrated to repository pattern. Plus auth_service.dart bug fix. See [polish-backlog](docs/superpowers/polish-backlog.md) for Sprint 2b/2c remaining scope."
```

---

## Self-Review Notes (filled in after writing the plan)

- **Spec coverage:** Master spec section 3 lists Sprint 2a as "Existing Repos + auth_service bugfix". Task 1-7 cover the 7 in-scope files; Task 8 covers the auth_service bugfix. Realtime / Storage / new-repos / core/providers explicitly out-of-scope, mirrored in Task 7's TODO comments.
- **Placeholder scan:** Tasks 7-B/C/D mention "4 commits to keep them reviewable" without spelling out each commit's exact files. Acceptable because each commit is "migrate stelle at line N as documented in the table at task start" — but if an executor finds the table ambiguous, they should split further or ask.
- **Type consistency:** `updatePlayerFields`, `getPlayersByInstrument`, `getChildrenForParent`, `getPersonAttendancesForPersons`, `ensurePersonAttendances`, `validatePersonAttendanceTenant`, `deletePersonAttendance`, `getSongEntries`, `getUpcomingAbsencesForPersons` — all consistently named across tasks. Existing method names (`updateAttendance`, `updatePersonAttendance`, `getPlayers`, `getPlayerByAppId`, `getGroups`, `getGroupById`, `getSongs`, `getUpcomingAttendances`) are referenced consistently.
- **Out-of-scope guardrails:** Task 7 includes an exact-count regression test that catches bypass-leak; Task 6 explicitly excludes the other person_detail bypass stellen. The TODO comments on remaining attendance_detail bypass stellen clearly attribute them to Sprint 2b or 2c.
- **Open question for executor:** in Task 7-A's `ensurePersonAttendances`, the "logic from attendance_detail_page._ensurePersonAttendances 231-274, preserved verbatim" requires the executor to copy that block faithfully — they should re-read those lines before writing the repo method, not paraphrase from memory.
