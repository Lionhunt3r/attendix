import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/constants/enums.dart';

part 'attendance.freezed.dart';
part 'attendance.g.dart';

/// Custom converter for flexible int/string handling
class _FlexibleIntConverter implements JsonConverter<int?, dynamic> {
  const _FlexibleIntConverter();
  @override
  int? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return json;
    if (json is String) return int.tryParse(json);
    if (json is double) return json.toInt();
    return null;
  }
  @override
  dynamic toJson(int? object) => object;
}

/// Custom converter for flexible string handling
class _FlexibleStringConverter implements JsonConverter<String?, dynamic> {
  const _FlexibleStringConverter();
  @override
  String? fromJson(dynamic json) {
    if (json == null) return null;
    return json.toString();
  }
  @override
  dynamic toJson(String? object) => object;
}

/// Custom converter for flexible bool handling
class _FlexibleBoolConverter implements JsonConverter<bool, dynamic> {
  const _FlexibleBoolConverter();
  @override
  bool fromJson(dynamic json) {
    if (json == null) return false;
    if (json is bool) return json;
    if (json is int) return json != 0;
    if (json is String) return json.toLowerCase() == 'true' || json == '1';
    return false;
  }
  @override
  dynamic toJson(bool object) => object;
}

/// Custom converter for flexible AttendanceStatus handling (int or string)
class _FlexibleAttendanceStatusConverter implements JsonConverter<AttendanceStatus, dynamic> {
  const _FlexibleAttendanceStatusConverter();
  @override
  AttendanceStatus fromJson(dynamic json) {
    if (json == null) return AttendanceStatus.neutral;
    if (json is int) return AttendanceStatus.fromValue(json);
    if (json is String) {
      // Try to parse as integer first
      final intValue = int.tryParse(json);
      if (intValue != null) return AttendanceStatus.fromValue(intValue);
      // Try to match enum name
      return AttendanceStatus.values.firstWhere(
        (s) => s.name == json,
        orElse: () => AttendanceStatus.neutral,
      );
    }
    return AttendanceStatus.neutral;
  }
  @override
  dynamic toJson(AttendanceStatus status) => status.value;
}

/// Attendance model
@freezed
class Attendance with _$Attendance {
  const factory Attendance({
    @_FlexibleIntConverter() int? id,
    @_FlexibleIntConverter() int? tenantId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'created_by') @_FlexibleStringConverter() String? createdBy,
    required String date,
    @_FlexibleStringConverter() String? type,
    @JsonKey(name: 'type_id') @_FlexibleStringConverter() String? typeId,
    @JsonKey(name: 'save_in_history') @_FlexibleBoolConverter() @Default(false) bool saveInHistory,
    double? percentage,
    List<String>? excused,
    @_FlexibleStringConverter() String? typeInfo,
    @_FlexibleStringConverter() String? notes,
    @_FlexibleStringConverter() String? img,
    Map<String, dynamic>? plan,
    List<String>? lateExcused,
    List<int>? songs,
    List<int>? criticalPlayers,
    Map<String, dynamic>? playerNotes,
    @JsonKey(name: 'start_time') @_FlexibleStringConverter() String? startTime,
    @JsonKey(name: 'end_time') @_FlexibleStringConverter() String? endTime,
    @_FlexibleStringConverter() String? deadline,
    @JsonKey(name: 'duration_days') @_FlexibleIntConverter() int? durationDays,
    List<ChecklistItem>? checklist,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) =>
      _$AttendanceFromJson(json);
}

/// Person's attendance record
@freezed
class PersonAttendance with _$PersonAttendance {
  const factory PersonAttendance({
    @_FlexibleStringConverter() String? id,
    @JsonKey(name: 'attendance_id') @_FlexibleIntConverter() int? attendanceId,
    @JsonKey(name: 'person_id') @_FlexibleIntConverter() int? personId,
    @_FlexibleAttendanceStatusConverter() @Default(AttendanceStatus.neutral) AttendanceStatus status,
    @_FlexibleStringConverter() String? notes,
    @_FlexibleStringConverter() String? firstName,
    @_FlexibleStringConverter() String? lastName,
    @_FlexibleStringConverter() String? img,
    @_FlexibleIntConverter() int? instrument,
    @_FlexibleStringConverter() String? groupName,
    @_FlexibleStringConverter() String? joined,
    @_FlexibleStringConverter() String? date,
    @_FlexibleStringConverter() String? text,
    @_FlexibleStringConverter() String? title,
    @JsonKey(name: 'changed_by') @_FlexibleStringConverter() String? changedBy,
    @JsonKey(name: 'changed_at') @_FlexibleStringConverter() String? changedAt,
    @JsonKey(name: 'type_id') @_FlexibleStringConverter() String? typeId,
    @_FlexibleBoolConverter() @Default(false) bool highlight,
    @_FlexibleStringConverter() String? left,
    @_FlexibleBoolConverter() @Default(false) bool paused,
  }) = _PersonAttendance;

  factory PersonAttendance.fromJson(Map<String, dynamic> json) =>
      _$PersonAttendanceFromJson(json);
}

/// Checklist item for attendance
@freezed
class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({
    required String id,
    required String text,
    @_FlexibleIntConverter() int? deadlineHours,
    @_FlexibleBoolConverter() @Default(false) bool completed,
    @_FlexibleStringConverter() String? dueDate,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);
}

/// Attendance type configuration
@freezed
class AttendanceType with _$AttendanceType {
  const factory AttendanceType({
    @_FlexibleStringConverter() String? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    required String name,
    @JsonKey(name: 'default_status') @_FlexibleAttendanceStatusConverter() @Default(AttendanceStatus.neutral) AttendanceStatus defaultStatus,
    @JsonKey(name: 'available_statuses') List<AttendanceStatus>? availableStatuses,
    @JsonKey(name: 'default_plan') Map<String, dynamic>? defaultPlan,
    @JsonKey(name: 'tenant_id') @_FlexibleIntConverter() int? tenantId,
    @JsonKey(name: 'relevant_groups') List<int>? relevantGroups,
    @JsonKey(name: 'start_time') @_FlexibleStringConverter() String? startTime,
    @JsonKey(name: 'end_time') @_FlexibleStringConverter() String? endTime,
    @JsonKey(name: 'manage_songs') @_FlexibleBoolConverter() @Default(false) bool manageSongs,
    @_FlexibleIntConverter() int? index,
    @_FlexibleBoolConverter() @Default(true) bool visible,
    @_FlexibleStringConverter() String? color,
    @_FlexibleBoolConverter() @Default(false) bool highlight,
    @JsonKey(name: 'hide_name') @_FlexibleBoolConverter() @Default(false) bool hideName,
    @JsonKey(name: 'include_in_average') @_FlexibleBoolConverter() @Default(true) bool includeInAverage,
    @JsonKey(name: 'all_day') @_FlexibleBoolConverter() @Default(false) bool allDay,
    @JsonKey(name: 'duration_days') @_FlexibleIntConverter() int? durationDays,
    @_FlexibleBoolConverter() @Default(false) bool notification,
    List<int>? reminders,
    @JsonKey(name: 'additional_fields_filter') Map<String, dynamic>? additionalFieldsFilter,
    List<ChecklistItem>? checklist,
  }) = _AttendanceType;

  factory AttendanceType.fromJson(Map<String, dynamic> json) =>
      _$AttendanceTypeFromJson(json);
}

/// Extension for Attendance
extension AttendanceExtension on Attendance {
  /// Formatted date
  String get formattedDate {
    final dateObj = DateTime.tryParse(date);
    if (dateObj == null) return date;
    return '${dateObj.day.toString().padLeft(2, '0')}.${dateObj.month.toString().padLeft(2, '0')}.${dateObj.year}';
  }
  
  /// Weekday name
  String get weekdayName {
    final dateObj = DateTime.tryParse(date);
    if (dateObj == null) return '';
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[dateObj.weekday - 1];
  }
  
  /// Is today
  bool get isToday {
    final dateObj = DateTime.tryParse(date);
    if (dateObj == null) return false;
    final today = DateTime.now();
    return dateObj.year == today.year &&
        dateObj.month == today.month &&
        dateObj.day == today.day;
  }
}

/// Extension for PersonAttendance
extension PersonAttendanceExtension on PersonAttendance {
  /// Full name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    return '$first $last'.trim();
  }

  /// Status label
  String get statusLabel {
    switch (status) {
      case AttendanceStatus.present:
        return 'Anwesend';
      case AttendanceStatus.absent:
        return 'Abwesend';
      case AttendanceStatus.excused:
        return 'Entschuldigt';
      case AttendanceStatus.late:
        return 'Verspätet';
      case AttendanceStatus.lateExcused:
        return 'Verspätet (entsch.)';
      case AttendanceStatus.neutral:
        return 'Unbekannt';
    }
  }

  /// Check if person is archived (left the organization)
  bool get isArchived => left != null && left!.isNotEmpty;

  /// Check if person is active (not archived and not paused)
  bool get isActive => !isArchived && !paused;
}