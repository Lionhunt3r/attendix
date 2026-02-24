import '../constants/enums.dart';

/// Result of shift-based status calculation
class ShiftStatusResult {
  final AttendanceStatus status;
  final String note;

  const ShiftStatusResult({
    required this.status,
    this.note = '',
  });
}

/// Utility class for calculating attendance status based on player shifts
///
/// This is a placeholder implementation. The full shift feature requires:
/// 1. ShiftPlan model with definition and shifts
/// 2. ShiftDefinition model with start_time, duration, repeat_count, free
/// 3. Shift repository to fetch shift plans
///
/// For now, returns the default status since shifts are not yet implemented.
class ShiftUtils {
  /// Calculate status based on player's shift and attendance times
  ///
  /// [shiftId] - Player's assigned shift plan ID
  /// [attendanceDate] - Date of the attendance event
  /// [attendanceStart] - Start time (HH:mm format)
  /// [attendanceEnd] - End time (HH:mm format)
  /// [defaultStatus] - Default status to use if no shift conflict
  /// [shiftStart] - Player's shift start date (optional)
  /// [shiftName] - Player's shift name for lookup (optional)
  static ShiftStatusResult getStatusByShift({
    required String? shiftId,
    required DateTime attendanceDate,
    required String attendanceStart,
    required String attendanceEnd,
    required AttendanceStatus defaultStatus,
    String? shiftStart,
    String? shiftName,
  }) {
    // TODO: Implement full shift logic when Shift models are available
    //
    // Full implementation would:
    // 1. Load ShiftPlan by shiftId
    // 2. Calculate player's position in shift rotation
    // 3. Check if shift overlaps with attendance time
    // 4. Return AttendanceStatus.excused with "Schichtbedingt" if overlap
    //
    // For now, return default status
    if (shiftId == null || shiftId.isEmpty) {
      return ShiftStatusResult(status: defaultStatus);
    }

    // Placeholder: Without ShiftPlan data, we can't calculate conflicts
    return ShiftStatusResult(status: defaultStatus);
  }

  /// Parse time string (HH:mm) to DateTime on a specific date
  static DateTime? parseTimeOnDate(String time, DateTime date) {
    final parts = time.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Check if two time ranges overlap
  static bool timesOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }
}
