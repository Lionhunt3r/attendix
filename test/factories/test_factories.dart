import 'package:attendix/core/constants/enums.dart';
import 'package:attendix/data/models/attendance/attendance.dart';
import 'package:attendix/data/models/instrument/instrument.dart';
import 'package:attendix/data/models/person/person.dart';
import 'package:attendix/data/models/tenant/tenant.dart';

/// Factory methods for creating test data
class TestFactories {
  TestFactories._();

  // ========== Person Factories ==========

  /// Create a test Person with configurable fields
  static Person createPerson({
    int? id,
    String firstName = 'Test',
    String lastName = 'Person',
    int? tenantId,
    String? email,
    String? appId,
    int? instrument,
    bool isLeader = false,
    bool isCritical = false,
    bool paused = false,
    String? pausedUntil,
    String? birthday,
    String? joined,
    String? left,
    bool pending = false,
    List<PlayerHistoryEntry>? history,
  }) {
    return Person(
      id: id,
      firstName: firstName,
      lastName: lastName,
      tenantId: tenantId,
      email: email ?? '$firstName.$lastName@test.com'.toLowerCase(),
      appId: appId,
      instrument: instrument,
      isLeader: isLeader,
      isCritical: isCritical,
      paused: paused,
      pausedUntil: pausedUntil,
      birthday: birthday ?? '1990-01-01',
      joined: joined ?? '2020-01-01',
      left: left,
      pending: pending,
      history: history ?? [],
    );
  }

  /// Create a list of test persons
  static List<Person> createPersonList(
    int count, {
    int? tenantId,
    int? startId,
    int? instrument,
  }) {
    return List.generate(
      count,
      (i) => createPerson(
        id: startId != null ? startId + i : i + 1,
        firstName: 'Person',
        lastName: '${i + 1}',
        tenantId: tenantId,
        instrument: instrument,
      ),
    );
  }

  /// Create a conductor (person in main group)
  static Person createConductor({
    int? id,
    String firstName = 'Conductor',
    String lastName = 'Test',
    int? tenantId,
    int? mainGroupId,
  }) {
    return createPerson(
      id: id,
      firstName: firstName,
      lastName: lastName,
      tenantId: tenantId,
      instrument: mainGroupId ?? 1,
    );
  }

  /// Create an archived person
  static Person createArchivedPerson({
    int? id,
    String firstName = 'Archived',
    String lastName = 'Person',
    int? tenantId,
    String? leftDate,
  }) {
    return createPerson(
      id: id,
      firstName: firstName,
      lastName: lastName,
      tenantId: tenantId,
      left: leftDate ?? DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  /// Create a paused person
  static Person createPausedPerson({
    int? id,
    String firstName = 'Paused',
    String lastName = 'Person',
    int? tenantId,
    String? pausedUntil,
  }) {
    return createPerson(
      id: id,
      firstName: firstName,
      lastName: lastName,
      tenantId: tenantId,
      paused: true,
      pausedUntil: pausedUntil,
    );
  }

  /// Create a pending person (awaiting approval)
  static Person createPendingPerson({
    int? id,
    String firstName = 'Pending',
    String lastName = 'Person',
    int? tenantId,
  }) {
    return createPerson(
      id: id,
      firstName: firstName,
      lastName: lastName,
      tenantId: tenantId,
      pending: true,
    );
  }

  // ========== Tenant Factories ==========

  /// Create a test Tenant
  static Tenant createTenant({
    int? id,
    String shortName = 'Test',
    String longName = 'Test Orchestra',
    bool maintainTeachers = false,
    bool showHolidays = false,
    String type = 'orchestra',
    bool withExcuses = true,
    bool betaProgram = false,
    bool showMembersList = false,
    String? region,
  }) {
    return Tenant(
      id: id ?? 1,
      shortName: shortName,
      longName: longName,
      maintainTeachers: maintainTeachers,
      showHolidays: showHolidays,
      type: type,
      withExcuses: withExcuses,
      betaProgram: betaProgram,
      showMembersList: showMembersList,
      region: region,
    );
  }

  /// Create a list of test tenants
  static List<Tenant> createTenantList(int count, {int? startId}) {
    return List.generate(
      count,
      (i) => createTenant(
        id: startId != null ? startId + i : i + 1,
        shortName: 'Tenant${i + 1}',
        longName: 'Test Tenant ${i + 1}',
      ),
    );
  }

  /// Create a TenantUser association
  static TenantUser createTenantUser({
    int? id,
    required int tenantId,
    required String userId,
    int role = 1,
    String? email,
    bool favorite = false,
  }) {
    return TenantUser(
      id: id,
      tenantId: tenantId,
      userId: userId,
      role: role,
      email: email,
      favorite: favorite,
    );
  }

  // ========== Attendance Factories ==========

  /// Create a test Attendance
  static Attendance createAttendance({
    int? id,
    int? tenantId,
    required String date,
    String? type,
    String? typeId,
    String? typeInfo,
    double? percentage,
    String? notes,
    String? startTime,
    String? endTime,
    bool saveInHistory = false,
  }) {
    return Attendance(
      id: id,
      tenantId: tenantId,
      date: date,
      type: type ?? 'uebung',
      typeId: typeId,
      typeInfo: typeInfo,
      percentage: percentage,
      notes: notes,
      startTime: startTime,
      endTime: endTime,
      saveInHistory: saveInHistory,
    );
  }

  /// Create a list of attendances for a date range
  static List<Attendance> createAttendanceList(
    int count, {
    int? tenantId,
    int? startId,
    DateTime? startDate,
  }) {
    final base = startDate ?? DateTime.now();
    return List.generate(
      count,
      (i) => createAttendance(
        id: startId != null ? startId + i : i + 1,
        tenantId: tenantId,
        date: base.add(Duration(days: i)).toIso8601String().substring(0, 10),
      ),
    );
  }

  /// Create a PersonAttendance record
  static PersonAttendance createPersonAttendance({
    String? id,
    int? attendanceId,
    int? personId,
    AttendanceStatus status = AttendanceStatus.neutral,
    String? notes,
    String? firstName,
    String? lastName,
    int? instrument,
    String? groupName,
    String? date,
  }) {
    return PersonAttendance(
      id: id ?? 'pa_${attendanceId}_$personId',
      attendanceId: attendanceId,
      personId: personId,
      status: status,
      notes: notes,
      firstName: firstName,
      lastName: lastName,
      instrument: instrument,
      groupName: groupName,
      date: date,
    );
  }

  /// Create an AttendanceType
  static AttendanceType createAttendanceType({
    String? id,
    required String name,
    int? tenantId,
    AttendanceStatus defaultStatus = AttendanceStatus.neutral,
    List<AttendanceStatus>? availableStatuses,
    List<int>? relevantGroups,
    String? startTime,
    String? endTime,
    bool visible = true,
    bool hideName = false,
    String? color,
  }) {
    return AttendanceType(
      id: id,
      name: name,
      tenantId: tenantId,
      defaultStatus: defaultStatus,
      availableStatuses: availableStatuses,
      relevantGroups: relevantGroups,
      startTime: startTime,
      endTime: endTime,
      visible: visible,
      hideName: hideName,
      color: color,
    );
  }

  // ========== Group/Instrument Factories ==========

  /// Create a test Group (instrument)
  static Group createGroup({
    int? id,
    int? tenantId,
    required String name,
    String? shortName,
    String? color,
    int? index,
    bool maingroup = false,
  }) {
    return Group(
      id: id,
      tenantId: tenantId,
      name: name,
      shortName: shortName,
      color: color,
      index: index,
      maingroup: maingroup,
    );
  }

  /// Create a list of groups
  static List<Group> createGroupList(
    int count, {
    int? tenantId,
    int? startId,
  }) {
    final groupNames = [
      'Violine 1',
      'Violine 2',
      'Viola',
      'Cello',
      'Kontrabass',
      'Flöte',
      'Oboe',
      'Klarinette',
      'Fagott',
      'Horn',
    ];
    return List.generate(
      count,
      (i) => createGroup(
        id: startId != null ? startId + i : i + 1,
        tenantId: tenantId,
        name: i < groupNames.length ? groupNames[i] : 'Group ${i + 1}',
        index: i,
      ),
    );
  }

  /// Create a main group (conductors group)
  static Group createMainGroup({
    int? id,
    int? tenantId,
    String name = 'Dirigenten',
  }) {
    return createGroup(
      id: id,
      tenantId: tenantId,
      name: name,
      maingroup: true,
    );
  }

  /// Create a GroupCategory
  static GroupCategory createGroupCategory({
    int? id,
    int? tenantId,
    required String name,
    int? index,
  }) {
    return GroupCategory(
      id: id,
      tenantId: tenantId,
      name: name,
      index: index,
    );
  }

  // ========== JSON Factories ==========

  /// Create Person as JSON map (simulates Supabase response)
  static Map<String, dynamic> personToJson(Person person) {
    return person.toJson();
  }

  /// Create a list of persons as JSON (simulates Supabase response)
  static List<Map<String, dynamic>> personsToJson(List<Person> persons) {
    return persons.map((p) => p.toJson()).toList();
  }

  /// Create Tenant as JSON map
  static Map<String, dynamic> tenantToJson(Tenant tenant) {
    return tenant.toJson();
  }

  /// Create Attendance as JSON map
  static Map<String, dynamic> attendanceToJson(Attendance attendance) {
    return attendance.toJson();
  }

  /// Create Group as JSON map
  static Map<String, dynamic> groupToJson(Group group) {
    return group.toJson();
  }
}

/// Extension for convenient test data JSON generation
extension TestJsonExtension on Person {
  Map<String, dynamic> toTestJson() => TestFactories.personToJson(this);
}

extension TestTenantJsonExtension on Tenant {
  Map<String, dynamic> toTestJson() => TestFactories.tenantToJson(this);
}

extension TestAttendanceJsonExtension on Attendance {
  Map<String, dynamic> toTestJson() => TestFactories.attendanceToJson(this);
}

extension TestGroupJsonExtension on Group {
  Map<String, dynamic> toTestJson() => TestFactories.groupToJson(this);
}
