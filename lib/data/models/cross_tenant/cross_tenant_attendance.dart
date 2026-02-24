import 'package:freezed_annotation/freezed_annotation.dart';

import '../attendance/attendance.dart';

part 'cross_tenant_attendance.freezed.dart';
part 'cross_tenant_attendance.g.dart';

/// Cross-tenant attendance record
/// Combines a PersonAttendance with tenant information for multi-tenant views
@freezed
class CrossTenantPersonAttendance with _$CrossTenantPersonAttendance {
  const factory CrossTenantPersonAttendance({
    /// The base attendance record
    required PersonAttendance attendance,

    /// Tenant ID this attendance belongs to
    required int tenantId,

    /// Display name of the tenant (shortName or longName)
    required String tenantName,

    /// Deterministic color for UI differentiation
    required String tenantColor,

    /// Optional: Attendance type configuration for this tenant
    AttendanceType? attendanceType,

    /// Date string for sorting (from the attendance record)
    String? date,

    /// Start time of the attendance
    String? startTime,

    /// End time of the attendance
    String? endTime,

    /// Title/description of the attendance
    String? title,
  }) = _CrossTenantPersonAttendance;

  factory CrossTenantPersonAttendance.fromJson(Map<String, dynamic> json) =>
      _$CrossTenantPersonAttendanceFromJson(json);
}

/// Extension for CrossTenantPersonAttendance
extension CrossTenantPersonAttendanceExtension on CrossTenantPersonAttendance {
  /// Parsed date for comparisons
  DateTime? get dateTime => date != null ? DateTime.tryParse(date!) : null;

  /// Check if this attendance is today
  bool get isToday {
    final dt = dateTime;
    if (dt == null) return false;
    final today = DateTime.now();
    return dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day;
  }

  /// Check if this attendance is in the future
  bool get isFuture {
    final dt = dateTime;
    if (dt == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dt.isAfter(todayOnly);
  }

  /// Check if this attendance is in the past
  bool get isPast {
    final dt = dateTime;
    if (dt == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return dt.isBefore(todayOnly);
  }

  /// Formatted date string (DD.MM.YYYY)
  String get formattedDate {
    final dt = dateTime;
    if (dt == null) return date ?? '';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  /// Weekday name (Mo, Di, Mi, ...)
  String get weekdayName {
    final dt = dateTime;
    if (dt == null) return '';
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[dt.weekday - 1];
  }

  /// Display title with date and info
  String get displayTitle {
    final typeInfo = title ?? attendanceType?.name ?? '';
    if (typeInfo.isNotEmpty) {
      return '$weekdayName, $formattedDate | $typeInfo';
    }
    return '$weekdayName, $formattedDate';
  }
}
