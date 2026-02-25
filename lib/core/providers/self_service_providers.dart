import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/supabase_config.dart';
import '../../core/constants/enums.dart';
import '../../data/models/person/person.dart';
import '../../data/repositories/sign_in_out_repository.dart';
import 'tenant_providers.dart';

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

/// Provider for current player (user's linked player record for the current tenant)
/// SEC-008: Added tenantId filter to prevent cross-tenant identity confusion
final currentSelfServicePlayerProvider = FutureProvider<Person?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  final tenantId = ref.watch(currentTenantIdProvider);

  if (userId == null) return null;
  if (tenantId == null) return null;

  // SEC-008: Filter by both appId AND tenantId
  final response = await supabase
      .from('player')
      .select('*')
      .eq('appId', userId)
      .eq('tenantId', tenantId)
      .limit(1)
      .maybeSingle();

  if (response == null) return null;
  return Person.fromJson(response);
});

/// Provider to check if current user is an applicant in the current tenant
final isApplicantProvider = Provider<bool>((ref) {
  final tenantUser = ref.watch(currentTenantUserProvider).valueOrNull;
  if (tenantUser == null) return false;
  return Role.fromValue(tenantUser.role).isApplicant;
});

