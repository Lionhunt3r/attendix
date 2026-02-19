/// Player history type enumeration
enum PlayerHistoryType {
  paused(1),
  unexcused(2),
  criticalPerson(3),
  attendance(4),
  notes(5),
  unpaused(6),
  instrumentChange(7),
  archived(8),
  returned(9),
  transferredFrom(10),
  transferredTo(11),
  copiedFrom(12),
  copiedTo(13),
  approved(14),
  declined(15),
  other(99);

  const PlayerHistoryType(this.value);
  final int value;

  static PlayerHistoryType fromValue(int value) {
    return PlayerHistoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlayerHistoryType.other,
    );
  }
}

/// User role enumeration
enum Role {
  admin(1),
  player(2),
  viewer(3),
  helper(4),
  responsible(5),
  parent(6),
  applicant(7),
  none(99);

  const Role(this.value);
  final int value;

  static Role fromValue(int value) {
    return Role.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Role.none,
    );
  }

  bool get isAdmin => this == Role.admin;
  bool get isPlayer => this == Role.player;
  bool get isViewer => this == Role.viewer;
  bool get isHelper => this == Role.helper;
  bool get isResponsible => this == Role.responsible;
  bool get isParent => this == Role.parent;
  bool get isApplicant => this == Role.applicant;
  bool get canEdit => this == Role.admin || this == Role.responsible || this == Role.helper;
  bool get canView => this != Role.none && this != Role.applicant;
}

/// Attendance status enumeration
enum AttendanceStatus {
  neutral(0),
  present(1),
  excused(2),
  late(3),
  absent(4),
  lateExcused(5);

  const AttendanceStatus(this.value);
  final int value;

  static AttendanceStatus fromValue(int value) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AttendanceStatus.neutral,
    );
  }

  bool get isPresent => this == AttendanceStatus.present;
  bool get isAbsent => this == AttendanceStatus.absent;
  bool get isExcused => this == AttendanceStatus.excused || this == AttendanceStatus.lateExcused;
  bool get isLate => this == AttendanceStatus.late || this == AttendanceStatus.lateExcused;
  bool get isNeutral => this == AttendanceStatus.neutral;
}

/// Supabase table names
enum SupabaseTable {
  conductors('conductors'),
  player('player'),
  viewers('viewers'),
  tenants('tenants'),
  tenantUsers('tenant_users'),
  attendances('attendances'),
  personAttendances('person_attendances'),
  songs('songs'),
  songFiles('song_files'),
  groups('groups'),
  groupCategories('group_categories'),
  teachers('teachers'),
  meetings('meetings'),
  attendanceTypes('attendance_types'),
  shiftPlans('shift_plans'),
  shiftDefinitions('shift_definitions'),
  history('history'),
  organisations('organisations'),
  churches('bfecg_churches');

  const SupabaseTable(this.tableName);
  final String tableName;
}

/// Default attendance type identifiers
enum DefaultAttendanceType {
  orchestra('orchestra'),
  choir('choir'),
  general('general');

  const DefaultAttendanceType(this.value);
  final String value;
}

/// Extra field types for dynamic forms
enum FieldType {
  text('text'),
  textarea('textarea'),
  number('number'),
  date('date'),
  boolean('boolean'),
  select('select'),
  bfecgChurch('bfecg_church');

  const FieldType(this.value);
  final String value;

  static FieldType fromValue(String value) {
    return FieldType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FieldType.text,
    );
  }
}

/// Attendance view mode
enum AttendanceViewMode {
  click('click'),
  select('select');

  const AttendanceViewMode(this.value);
  final String value;

  static AttendanceViewMode fromValue(String value) {
    return AttendanceViewMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AttendanceViewMode.click,
    );
  }
}