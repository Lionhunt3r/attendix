import '../constants/enums.dart';

/// BL-010: Central function for parsing AttendanceStatus from various sources.
/// Supports: int, String (numeric or enum name), AttendanceStatus
AttendanceStatus parseAttendanceStatus(dynamic status) {
  if (status == null) return AttendanceStatus.neutral;
  if (status is AttendanceStatus) return status;

  // Handle integer values (as stored in database)
  if (status is int) {
    return AttendanceStatus.fromValue(status);
  }

  // Handle string values (enum names or integer strings)
  final statusStr = status.toString();
  final intValue = int.tryParse(statusStr);
  if (intValue != null) {
    return AttendanceStatus.fromValue(intValue);
  }

  // Fallback: try to match enum name
  return AttendanceStatus.values.firstWhere(
    (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
    orElse: () => AttendanceStatus.neutral,
  );
}
