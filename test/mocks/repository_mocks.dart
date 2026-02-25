import 'package:attendix/data/models/attendance/attendance.dart';
import 'package:attendix/data/models/instrument/instrument.dart';
import 'package:attendix/data/models/person/person.dart';
import 'package:attendix/data/repositories/attendance_repository.dart';
import 'package:attendix/data/repositories/group_repository.dart';
import 'package:attendix/data/repositories/player_repository.dart';
import 'package:mocktail/mocktail.dart';

// ========== Repository Mocks ==========

/// Mock PlayerRepository for testing
class MockPlayerRepository extends Mock implements PlayerRepository {}

/// Mock AttendanceRepository for testing
class MockAttendanceRepository extends Mock implements AttendanceRepository {}

/// Mock GroupRepository for testing
class MockGroupRepository extends Mock implements GroupRepository {}

// ========== Fallback Values ==========

/// Register fallback values for mocktail
///
/// Call this in setUpAll() before using any mocks:
/// ```dart
/// setUpAll(() {
///   registerFallbackValues();
/// });
/// ```
void registerFallbackValues() {
  registerFallbackValue(_FallbackPerson());
  registerFallbackValue(_FallbackAttendance());
  registerFallbackValue(_FallbackPersonAttendance());
  registerFallbackValue(_FallbackGroup());
}

class _FallbackPerson extends Fake implements Person {}

class _FallbackAttendance extends Fake implements Attendance {}

class _FallbackPersonAttendance extends Fake implements PersonAttendance {}

class _FallbackGroup extends Fake implements Group {}

// ========== Mock Setup Helpers ==========

/// Set up a mock PlayerRepository with tenant awareness
///
/// Example:
/// ```dart
/// final mockRepo = MockPlayerRepository();
/// setupMockPlayerRepository(mockRepo, tenantId: 42);
/// ```
void setupMockPlayerRepository(
  MockPlayerRepository mock, {
  required int tenantId,
  bool hasTenant = true,
}) {
  when(() => mock.currentTenantId).thenReturn(tenantId);
  when(() => mock.hasTenantId).thenReturn(hasTenant);
}

/// Set up a mock AttendanceRepository with tenant awareness
void setupMockAttendanceRepository(
  MockAttendanceRepository mock, {
  required int tenantId,
  bool hasTenant = true,
}) {
  when(() => mock.currentTenantId).thenReturn(tenantId);
  when(() => mock.hasTenantId).thenReturn(hasTenant);
}

/// Set up a mock GroupRepository with tenant awareness
void setupMockGroupRepository(
  MockGroupRepository mock, {
  required int tenantId,
  bool hasTenant = true,
}) {
  when(() => mock.currentTenantId).thenReturn(tenantId);
  when(() => mock.hasTenantId).thenReturn(hasTenant);
}

// ========== Common Mock Configurations ==========

/// Configure mock to return a list of players
void mockGetPlayers(
  MockPlayerRepository mock,
  List<Person> players,
) {
  when(() => mock.getPlayers(
        includeAttendances: any(named: 'includeAttendances'),
        all: any(named: 'all'),
      )).thenAnswer((_) async => players);
}

/// Configure mock to return a single player by ID
void mockGetPlayerById(
  MockPlayerRepository mock,
  int id,
  Person? player,
) {
  when(() => mock.getPlayerById(id)).thenAnswer((_) async => player);
}

/// Configure mock to return pending players
void mockGetPendingPlayers(
  MockPlayerRepository mock,
  List<Person> players,
) {
  when(() => mock.getPendingPlayers()).thenAnswer((_) async => players);
}

/// Configure mock to return archived players
void mockGetArchivedPlayers(
  MockPlayerRepository mock,
  List<Person> players,
) {
  when(() => mock.getArchivedPlayers()).thenAnswer((_) async => players);
}

/// Configure mock for create player
void mockCreatePlayer(
  MockPlayerRepository mock,
  Person returnedPlayer,
) {
  when(() => mock.createPlayer(any())).thenAnswer((_) async => returnedPlayer);
}

/// Configure mock for update player
void mockUpdatePlayer(
  MockPlayerRepository mock,
  Person returnedPlayer,
) {
  when(() => mock.updatePlayer(any())).thenAnswer((_) async => returnedPlayer);
}

/// Configure mock for delete player
void mockDeletePlayer(MockPlayerRepository mock) {
  when(() => mock.deletePlayer(any())).thenAnswer((_) async {});
}

/// Configure mock to return attendances
void mockGetAttendances(
  MockAttendanceRepository mock,
  List<Attendance> attendances,
) {
  when(() => mock.getAttendances(
        since: any(named: 'since'),
        withPersonAttendances: any(named: 'withPersonAttendances'),
        limit: any(named: 'limit'),
      )).thenAnswer((_) async => attendances);
}

/// Configure mock to return a single attendance
void mockGetAttendanceById(
  MockAttendanceRepository mock,
  int id,
  Attendance? attendance,
) {
  when(() => mock.getAttendanceById(id)).thenAnswer((_) async => attendance);
}

/// Configure mock for create attendance
void mockCreateAttendance(
  MockAttendanceRepository mock,
  Attendance returnedAttendance,
) {
  when(() => mock.createAttendance(any()))
      .thenAnswer((_) async => returnedAttendance);
}

/// Configure mock to return groups
void mockGetGroups(
  MockGroupRepository mock,
  List<Group> groups,
) {
  when(() => mock.getGroups()).thenAnswer((_) async => groups);
}

/// Configure mock to return groups map
void mockGetGroupsMap(
  MockGroupRepository mock,
  Map<int, String> groupsMap,
) {
  when(() => mock.getGroupsMap()).thenAnswer((_) async => groupsMap);
}

/// Configure mock to return a single group
void mockGetGroupById(
  MockGroupRepository mock,
  int id,
  Group? group,
) {
  when(() => mock.getGroupById(id)).thenAnswer((_) async => group);
}

/// Configure mock to throw an error
void mockThrowError<T extends Mock>(
  T mock,
  void Function(T) whenCall,
  Object error,
) {
  whenCall(mock);
  when(() => mock).thenThrow(error);
}
