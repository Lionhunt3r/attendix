import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import 'base_repository.dart';

/// Provider for SignInOutRepository
final signInOutRepositoryProvider = Provider<SignInOutRepository>((ref) {
  return SignInOutRepository(ref);
});

/// Repository for self-service sign in/out operations
class SignInOutRepository extends BaseRepository with TenantAwareRepository {
  SignInOutRepository(super.ref);

  /// Predefined distinct colors for tenant visual separation (from Ionic app)
  static const _distinctColors = [
    '#E53935', // Red
    '#1E88E5', // Blue
    '#43A047', // Green
    '#FB8C00', // Orange
    '#8E24AA', // Purple
    '#00ACC1', // Cyan
    '#F4511E', // Deep Orange
    '#3949AB', // Indigo
    '#7CB342', // Light Green
    '#C2185B', // Pink
    '#00897B', // Teal
    '#6D4C41', // Brown
    '#5E35B1', // Deep Purple
    '#039BE5', // Light Blue
    '#D81B60', // Pink Dark
  ];

  /// Get color for tenant based on index (like Ionic app)
  String _getTenantColor(int tenantId, List<dynamic> tenantIds) {
    final index = tenantIds.indexOf(tenantId);
    final colorIndex = index >= 0
        ? index % _distinctColors.length
        : tenantId.abs() % _distinctColors.length;
    return _distinctColors[colorIndex];
  }

  /// Sign in to an attendance
  Future<void> signIn(
    String personAttendanceId,
    SignInType type, {
    String notes = '',
  }) async {
    try {
      AttendanceStatus newStatus;

      switch (type) {
        case SignInType.normal:
          newStatus = AttendanceStatus.present;
          break;
        case SignInType.neutral:
          newStatus = AttendanceStatus.neutral;
          break;
        case SignInType.late:
          newStatus = AttendanceStatus.late;
          break;
      }

      await supabase.from('person_attendances').update({
        'status': newStatus.value,
        'notes': notes,
        'changed_at': DateTime.now().toIso8601String(),
        'changed_by': supabase.auth.currentUser?.id,
      }).eq('id', personAttendanceId);
    } catch (e, stack) {
      handleError(e, stack, 'signIn');
      rethrow;
    }
  }

  /// Sign out from attendances
  Future<void> signOut(
    List<String> personAttendanceIds,
    String reason, {
    bool isLateComing = false,
  }) async {
    try {
      final status =
          isLateComing ? AttendanceStatus.lateExcused : AttendanceStatus.excused;

      await supabase.from('person_attendances').update({
        'status': status.value,
        'notes': reason,
        'changed_at': DateTime.now().toIso8601String(),
        'changed_by': supabase.auth.currentUser?.id,
      }).inFilter('id', personAttendanceIds);
    } catch (e, stack) {
      handleError(e, stack, 'signOut');
      rethrow;
    }
  }

  /// Update attendance note
  Future<void> updateAttendanceNote(
    String personAttendanceId,
    String note,
  ) async {
    try {
      await supabase.from('person_attendances').update({
        'notes': note,
        'changed_at': DateTime.now().toIso8601String(),
        'changed_by': supabase.auth.currentUser?.id,
      }).eq('id', personAttendanceId);
    } catch (e, stack) {
      handleError(e, stack, 'updateAttendanceNote');
      rethrow;
    }
  }

  /// Get all person attendances for the current user across all tenants
  Future<List<CrossTenantPersonAttendance>> getAllPersonAttendancesAcrossTenants() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      // Get all person records for this user (linked via appId)
      final personRecords = await supabase
          .from('player')
          .select('id, tenantId')
          .eq('appId', userId);

      if (personRecords.isEmpty) return [];

      final personIds = (personRecords as List).map((p) => p['id']).toList();
      final tenantIds = (personRecords as List)
          .map((p) => p['tenantId'])
          .toSet()
          .toList();

      // Get all person attendances with attendance details
      final response = await supabase
          .from('person_attendances')
          .select('''
            *,
            attendance:attendance_id(
              id, date, type, typeInfo, start_time, end_time, deadline, tenantId,
              type_id, plan, share_plan
            )
          ''')
          .inFilter('person_id', personIds)
          .order('attendance(date)', ascending: false);

      // Get tenant info (no color column - we generate colors programmatically)
      final tenants = await supabase
          .from('tenants')
          .select('id, shortName')
          .inFilter('id', tenantIds);

      // Build tenant map with programmatically generated colors
      final tenantIdsList = tenantIds.toList();
      final tenantMap = {
        for (final t in tenants as List)
          t['id'] as int: {
            'name': t['shortName'] as String,
            'color': _getTenantColor(t['id'] as int, tenantIdsList),
          }
      };

      // Map to CrossTenantPersonAttendance
      return (response as List).map((json) {
        final attendance = json['attendance'] as Map<String, dynamic>?;
        final tenantId = attendance?['tenantId'] as int? ?? 0;
        final tenantInfo = tenantMap[tenantId];

        return CrossTenantPersonAttendance(
          id: json['id']?.toString(),
          personId: json['person_id'] as int?,
          attendanceId: json['attendance_id'] as int?,
          status: _parseStatus(json['status']),
          notes: json['notes'] as String?,
          date: attendance?['date'] as String?,
          typeInfo: attendance?['typeInfo'] as String?,
          startTime: attendance?['start_time'] as String?,
          endTime: attendance?['end_time'] as String?,
          deadline: attendance?['deadline'] as String?,
          tenantId: tenantId,
          tenantName: tenantInfo?['name'] ?? 'Unbekannt',
          tenantColor: tenantInfo?['color'] ?? '#000000',
          plan: attendance?['plan'] as Map<String, dynamic>?,
          sharePlan: attendance?['share_plan'] == true,
          typeId: attendance?['type_id']?.toString(),
        );
      }).toList();
    } catch (e, stack) {
      handleError(e, stack, 'getAllPersonAttendancesAcrossTenants');
      rethrow;
    }
  }

  AttendanceStatus _parseStatus(dynamic status) {
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

    return AttendanceStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
      orElse: () => AttendanceStatus.neutral,
    );
  }
}

/// Type of sign-in
enum SignInType {
  normal,
  neutral,
  late,
}

/// Cross-tenant person attendance data
class CrossTenantPersonAttendance {
  final String? id;
  final int? personId;
  final int? attendanceId;
  final AttendanceStatus status;
  final String? notes;
  final String? date;
  final String? typeInfo;
  final String? startTime;
  final String? endTime;
  final String? deadline;
  final int tenantId;
  final String tenantName;
  final String tenantColor;
  final Map<String, dynamic>? plan;
  final bool sharePlan;
  final String? typeId;

  CrossTenantPersonAttendance({
    this.id,
    this.personId,
    this.attendanceId,
    this.status = AttendanceStatus.neutral,
    this.notes,
    this.date,
    this.typeInfo,
    this.startTime,
    this.endTime,
    this.deadline,
    required this.tenantId,
    required this.tenantName,
    required this.tenantColor,
    this.plan,
    this.sharePlan = false,
    this.typeId,
  });

  /// Check if this attendance is in the past
  bool get isPast {
    if (date == null) return false;
    final attendanceDate = DateTime.tryParse(date!);
    if (attendanceDate == null) return false;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return attendanceDate.isBefore(todayStart);
  }

  /// Check if this attendance is today or in the future
  bool get isUpcoming {
    if (date == null) return false;
    final attendanceDate = DateTime.tryParse(date!);
    if (attendanceDate == null) return false;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return !attendanceDate.isBefore(todayStart);
  }

  /// Check if the deadline has passed
  bool get isDeadlinePassed {
    if (deadline == null) return false;
    final deadlineDate = DateTime.tryParse(deadline!);
    if (deadlineDate == null) return false;
    return DateTime.now().isAfter(deadlineDate);
  }

  /// Check if the person was present (attended)
  bool get attended {
    return status == AttendanceStatus.present ||
        status == AttendanceStatus.late ||
        status == AttendanceStatus.lateExcused;
  }

  /// Check if plan is available for viewing
  bool get hasPlan {
    if (!sharePlan || plan == null) return false;
    final fields = plan?['fields'] as List?;
    return fields != null && fields.isNotEmpty;
  }

  /// Get deadline as DateTime
  DateTime? get deadlineDateTime {
    if (deadline == null) return null;
    return DateTime.tryParse(deadline!);
  }

  /// Get readable deadline text
  String? get deadlineText {
    final deadlineDate = deadlineDateTime;
    if (deadlineDate == null) return null;

    final now = DateTime.now();
    if (now.isAfter(deadlineDate)) {
      return 'Anmeldefrist abgelaufen';
    }

    final day = deadlineDate.day.toString().padLeft(2, '0');
    final month = deadlineDate.month.toString().padLeft(2, '0');
    final year = deadlineDate.year;
    final hour = deadlineDate.hour.toString().padLeft(2, '0');
    final minute = deadlineDate.minute.toString().padLeft(2, '0');
    return 'Anmelden bis $day.$month.$year $hour:$minute Uhr';
  }

  /// Display title - returns typeInfo if not empty, otherwise 'Termin'
  String get displayTitle {
    if (typeInfo != null && typeInfo!.isNotEmpty) {
      return typeInfo!;
    }
    return 'Termin';
  }
}
