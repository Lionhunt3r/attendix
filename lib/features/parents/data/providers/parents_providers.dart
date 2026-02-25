import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../data/models/person/person.dart';
import '../../../../data/repositories/sign_in_out_repository.dart';

/// Statistics for a child
class ChildStats {
  final int percentage;
  final int lateCount;
  final int totalCount;
  final int presentCount;

  const ChildStats({
    required this.percentage,
    required this.lateCount,
    required this.totalCount,
    required this.presentCount,
  });
}

/// Attendance record for a child
class ChildPersonAttendance {
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
  final Map<String, dynamic>? plan;
  final bool sharePlan;
  final String? typeId;
  final int childId;
  final String childName;

  ChildPersonAttendance({
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
    this.plan,
    this.sharePlan = false,
    this.typeId,
    required this.childId,
    required this.childName,
  });

  bool get isPast {
    if (date == null) return false;
    final attendanceDate = DateTime.tryParse(date!);
    if (attendanceDate == null) return false;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return attendanceDate.isBefore(todayStart);
  }

  bool get isUpcoming {
    if (date == null) return false;
    final attendanceDate = DateTime.tryParse(date!);
    if (attendanceDate == null) return false;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return !attendanceDate.isBefore(todayStart);
  }

  bool get isDeadlinePassed {
    if (deadline == null) return false;
    final deadlineDate = DateTime.tryParse(deadline!);
    if (deadlineDate == null) return false;
    return DateTime.now().isAfter(deadlineDate);
  }

  bool get attended {
    return status == AttendanceStatus.present ||
        status == AttendanceStatus.late ||
        status == AttendanceStatus.lateExcused;
  }

  bool get hasPlan {
    if (!sharePlan || plan == null) return false;
    final fields = plan?['fields'] as List?;
    return fields != null && fields.isNotEmpty;
  }

  String? get deadlineText {
    if (deadline == null) return null;
    final deadlineDate = DateTime.tryParse(deadline!);
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

  String get displayTitle {
    if (typeInfo != null && typeInfo!.isNotEmpty) {
      return typeInfo!;
    }
    return 'Termin';
  }
}

/// Combined attendance with all children's records for that date
class ParentAttendanceGroup {
  final int attendanceId;
  final String? date;
  final String? typeInfo;
  final String? startTime;
  final String? endTime;
  final String? deadline;
  final Map<String, dynamic>? plan;
  final bool sharePlan;
  final List<ChildPersonAttendance> childAttendances;

  ParentAttendanceGroup({
    required this.attendanceId,
    this.date,
    this.typeInfo,
    this.startTime,
    this.endTime,
    this.deadline,
    this.plan,
    this.sharePlan = false,
    required this.childAttendances,
  });

  bool get isPast {
    if (date == null) return false;
    final attendanceDate = DateTime.tryParse(date!);
    if (attendanceDate == null) return false;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return attendanceDate.isBefore(todayStart);
  }

  bool get isUpcoming => !isPast;

  bool get isDeadlinePassed {
    if (deadline == null) return false;
    final deadlineDate = DateTime.tryParse(deadline!);
    if (deadlineDate == null) return false;
    return DateTime.now().isAfter(deadlineDate);
  }

  bool get hasPlan {
    if (!sharePlan || plan == null) return false;
    final fields = plan?['fields'] as List?;
    return fields != null && fields.isNotEmpty;
  }

  String? get deadlineText {
    if (deadline == null) return null;
    final deadlineDate = DateTime.tryParse(deadline!);
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

  String get displayTitle {
    if (typeInfo != null && typeInfo!.isNotEmpty) {
      return typeInfo!;
    }
    return 'Termin';
  }
}

/// Provider for children linked to the current parent
final parentChildrenProvider = FutureProvider<List<Person>>((ref) async {
  final tenantUser = ref.watch(currentTenantUserProvider).valueOrNull;
  if (tenantUser?.parentId == null) return [];

  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('player')
      .select('*')
      .eq('tenantId', tenant.id!)
      .eq('parent_id', tenantUser!.parentId!)
      .isFilter('pending', null)
      .isFilter('left', null)
      .order('lastName');

  return (response as List)
      .map((e) => Person.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Provider for all attendances of children
final childrenAttendancesProvider =
    FutureProvider<List<ChildPersonAttendance>>((ref) async {
  final children = ref.watch(parentChildrenProvider).valueOrNull ?? [];
  if (children.isEmpty) return [];

  final supabase = ref.watch(supabaseClientProvider);

  final childIds = children.map((c) => c.id).whereType<int>().toList();
  if (childIds.isEmpty) return [];

  // Build child name map
  final childNameMap = {
    for (final child in children)
      if (child.id != null) child.id!: '${child.firstName} ${child.lastName}',
  };

  // Fetch all person attendances for children
  final response = await supabase
      .from('person_attendances')
      .select('''
        *,
        attendance:attendance_id(
          id, date, type, typeInfo, start_time, end_time, deadline, tenantId,
          type_id, plan, share_plan
        )
      ''')
      .inFilter('person_id', childIds)
      .order('attendance(date)', ascending: false);

  return (response as List).map((json) {
    final attendance = json['attendance'] as Map<String, dynamic>?;
    final personId = json['person_id'] as int?;

    return ChildPersonAttendance(
      id: json['id']?.toString(),
      personId: personId,
      attendanceId: json['attendance_id'] as int?,
      status: _parseStatus(json['status']),
      notes: json['notes'] as String?,
      date: attendance?['date'] as String?,
      typeInfo: attendance?['typeInfo'] as String?,
      startTime: attendance?['start_time'] as String?,
      endTime: attendance?['end_time'] as String?,
      deadline: attendance?['deadline'] as String?,
      plan: attendance?['plan'] as Map<String, dynamic>?,
      sharePlan: attendance?['share_plan'] == true,
      typeId: attendance?['type_id']?.toString(),
      childId: personId ?? 0,
      childName: childNameMap[personId] ?? 'Kind',
    );
  }).toList();
});

/// Provider for attendance groups (combined by date)
final parentAttendanceGroupsProvider =
    Provider<List<ParentAttendanceGroup>>((ref) {
  final attendances = ref.watch(childrenAttendancesProvider).valueOrNull ?? [];
  if (attendances.isEmpty) return [];

  // Group by attendance ID
  final Map<int, List<ChildPersonAttendance>> grouped = {};
  for (final att in attendances) {
    if (att.attendanceId != null) {
      grouped.putIfAbsent(att.attendanceId!, () => []).add(att);
    }
  }

  // Convert to ParentAttendanceGroup
  // BL-008: Use firstOrNull for safety even though grouped entries should never be empty
  return grouped.entries
      .where((entry) => entry.value.isNotEmpty)
      .map((entry) {
    final childAtts = entry.value;
    final first = childAtts.first;
    return ParentAttendanceGroup(
      attendanceId: entry.key,
      date: first.date,
      typeInfo: first.typeInfo,
      startTime: first.startTime,
      endTime: first.endTime,
      deadline: first.deadline,
      plan: first.plan,
      sharePlan: first.sharePlan,
      childAttendances: childAtts,
    );
  }).toList();
});

/// Provider for upcoming attendance groups
final upcomingParentAttendancesProvider =
    Provider<List<ParentAttendanceGroup>>((ref) {
  final groups = ref.watch(parentAttendanceGroupsProvider);
  final upcoming = groups.where((g) => g.isUpcoming).toList()
    ..sort((a, b) {
      final dateA = DateTime.tryParse(a.date ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b.date ?? '') ?? DateTime.now();
      return dateA.compareTo(dateB);
    });
  return upcoming;
});

/// Provider for past attendance groups
final pastParentAttendancesProvider =
    Provider<List<ParentAttendanceGroup>>((ref) {
  final groups = ref.watch(parentAttendanceGroupsProvider);
  final past = groups.where((g) => g.isPast).toList()
    ..sort((a, b) {
      final dateA = DateTime.tryParse(a.date ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b.date ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA); // Most recent first
    });
  // Limit to 10 past attendances
  return past.take(10).toList();
});

/// Provider for current (next) attendance
final currentParentAttendanceProvider = Provider<ParentAttendanceGroup?>((ref) {
  final upcoming = ref.watch(upcomingParentAttendancesProvider);
  return upcoming.isNotEmpty ? upcoming.first : null;
});

/// Provider for child statistics
final childStatsProvider = Provider.family<ChildStats, int>((ref, childId) {
  final attendances = ref.watch(childrenAttendancesProvider).valueOrNull ?? [];
  final childAttendances =
      attendances.where((a) => a.childId == childId && a.isPast).toList();

  if (childAttendances.isEmpty) {
    return const ChildStats(
      percentage: 0,
      lateCount: 0,
      totalCount: 0,
      presentCount: 0,
    );
  }

  final attended = childAttendances.where((a) => a.attended).length;
  final late = childAttendances
      .where((a) =>
          a.status == AttendanceStatus.late ||
          a.status == AttendanceStatus.lateExcused)
      .length;

  return ChildStats(
    // BL-002: Safe division - avoid division by zero
    percentage: childAttendances.isEmpty
        ? 0
        : (attended / childAttendances.length * 100).round(),
    lateCount: late,
    totalCount: childAttendances.length,
    presentCount: attended,
  );
});

/// Notifier for parent sign in/out operations
class ParentSignInOutNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  SignInOutRepository get _repo => ref.read(signInOutRepositoryProvider);

  /// Sign in a child to an attendance
  Future<void> signIn(
    String personAttendanceId,
    SignInType type, {
    String notes = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signIn(personAttendanceId, type, notes: notes);
      state = const AsyncValue.data(null);
      ref.invalidate(childrenAttendancesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sign out a child from attendance
  Future<void> signOut(
    List<String> personAttendanceIds,
    String reason, {
    bool isLateComing = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signOut(personAttendanceIds, reason,
          isLateComing: isLateComing);
      state = const AsyncValue.data(null);
      ref.invalidate(childrenAttendancesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update attendance note
  Future<void> updateNote(String personAttendanceId, String note) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateAttendanceNote(personAttendanceId, note);
      state = const AsyncValue.data(null);
      ref.invalidate(childrenAttendancesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final parentSignInOutNotifierProvider =
    NotifierProvider<ParentSignInOutNotifier, AsyncValue<void>>(() {
  return ParentSignInOutNotifier();
});

// Helper function to parse status
AttendanceStatus _parseStatus(dynamic status) {
  if (status == null) return AttendanceStatus.neutral;
  if (status is AttendanceStatus) return status;

  if (status is int) {
    return AttendanceStatus.fromValue(status);
  }

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
