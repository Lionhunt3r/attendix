import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../data/repositories/sign_in_out_repository.dart';

export '../../core/constants/enums.dart' show AttendanceStatus;
export '../../data/repositories/sign_in_out_repository.dart'
    show CrossTenantPersonAttendance, SignInType;

/// Provider for all person attendances across all tenants for the current user
final allPersonAttendancesAcrossTenantsProvider =
    FutureProvider<List<CrossTenantPersonAttendance>>((ref) async {
  final repo = ref.watch(signInOutRepositoryProvider);
  return repo.getAllPersonAttendancesAcrossTenants();
});

/// Provider for upcoming attendances across all tenants
final upcomingAttendancesAcrossTenantsProvider =
    Provider<List<CrossTenantPersonAttendance>>((ref) {
  final allAttendances = ref.watch(allPersonAttendancesAcrossTenantsProvider);

  return allAttendances.maybeWhen(
    data: (attendances) {
      final upcoming = attendances.where((a) => a.isUpcoming).toList()
        ..sort((a, b) {
          final dateA = DateTime.tryParse(a.date ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b.date ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        });
      return upcoming;
    },
    orElse: () => [],
  );
});

/// Provider for past attendances across all tenants
final pastAttendancesAcrossTenantsProvider =
    Provider<List<CrossTenantPersonAttendance>>((ref) {
  final allAttendances = ref.watch(allPersonAttendancesAcrossTenantsProvider);

  return allAttendances.maybeWhen(
    data: (attendances) {
      final past = attendances.where((a) => a.isPast).toList()
        ..sort((a, b) {
          final dateA = DateTime.tryParse(a.date ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b.date ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA); // Most recent first
        });
      return past;
    },
    orElse: () => [],
  );
});

/// Provider for the next upcoming attendance (current)
final currentAttendanceProvider = Provider<CrossTenantPersonAttendance?>((ref) {
  final upcoming = ref.watch(upcomingAttendancesAcrossTenantsProvider);
  return upcoming.isNotEmpty ? upcoming.first : null;
});

/// Provider for attendance statistics
final attendanceStatsProvider = Provider<AttendanceStats>((ref) {
  final past = ref.watch(pastAttendancesAcrossTenantsProvider);

  if (past.isEmpty) {
    return const AttendanceStats(
      percentage: 0,
      lateCount: 0,
      totalCount: 0,
      presentCount: 0,
    );
  }

  final attended = past.where((a) => a.attended).length;
  final late = past
      .where((a) =>
          a.status == AttendanceStatus.late ||
          a.status == AttendanceStatus.lateExcused)
      .length;

  return AttendanceStats(
    percentage: (attended / past.length * 100).round(),
    lateCount: late,
    totalCount: past.length,
    presentCount: attended,
  );
});

/// Notifier for sign in/out operations
class SignInOutNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  SignInOutRepository get _repo => ref.read(signInOutRepositoryProvider);

  /// Sign in to an attendance
  Future<void> signIn(
    String personAttendanceId,
    SignInType type, {
    String notes = '',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signIn(personAttendanceId, type, notes: notes);
      state = const AsyncValue.data(null);
      ref.invalidate(allPersonAttendancesAcrossTenantsProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sign out from attendances
  Future<void> signOut(
    List<String> personAttendanceIds,
    String reason, {
    bool isLateComing = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signOut(personAttendanceIds, reason, isLateComing: isLateComing);
      state = const AsyncValue.data(null);
      ref.invalidate(allPersonAttendancesAcrossTenantsProvider);
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
      ref.invalidate(allPersonAttendancesAcrossTenantsProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final signInOutNotifierProvider =
    NotifierProvider<SignInOutNotifier, AsyncValue<void>>(() {
  return SignInOutNotifier();
});

/// Attendance statistics
class AttendanceStats {
  final int percentage;
  final int lateCount;
  final int totalCount;
  final int presentCount;

  const AttendanceStats({
    required this.percentage,
    required this.lateCount,
    required this.totalCount,
    required this.presentCount,
  });
}
