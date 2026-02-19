import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../data/models/attendance/attendance.dart';
import '../../data/repositories/repositories.dart';
import 'tenant_providers.dart';

/// Initialized attendance repository with tenant context
final attendanceRepositoryWithTenantProvider = Provider<AttendanceRepository>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  final tenant = ref.watch(currentTenantIdProvider);
  
  if (tenant != null) {
    repo.setTenantId(tenant);
  }
  
  return repo;
});

/// Provider for attendance list
final attendancesProvider = FutureProvider<List<Attendance>>((ref) async {
  final repo = ref.watch(attendanceRepositoryWithTenantProvider);
  
  if (!repo.hasTenantId) return [];
  
  return repo.getAttendances();
});

/// Provider for upcoming attendances
final upcomingAttendancesProvider = FutureProvider<List<Attendance>>((ref) async {
  final repo = ref.watch(attendanceRepositoryWithTenantProvider);
  
  if (!repo.hasTenantId) return [];
  
  return repo.getUpcomingAttendances();
});

/// Provider for a single attendance by ID
final attendanceByIdProvider = FutureProvider.family<Attendance?, int>((ref, id) async {
  final repo = ref.watch(attendanceRepositoryWithTenantProvider);
  
  if (!repo.hasTenantId) return null;
  
  return repo.getAttendanceById(id);
});

/// Provider for person attendances by person ID
final personAttendancesProvider = FutureProvider.family<List<PersonAttendance>, int>((ref, personId) async {
  final repo = ref.watch(attendanceRepositoryWithTenantProvider);
  
  if (!repo.hasTenantId) return [];
  
  return repo.getPersonAttendancesForPerson(personId);
});

/// Notifier for attendance mutations
class AttendanceNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AttendanceRepository get _repo => ref.read(attendanceRepositoryWithTenantProvider);

  Future<Attendance?> createAttendance(Attendance attendance) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createAttendance(attendance);
      state = const AsyncValue.data(null);
      ref.invalidate(attendancesProvider);
      ref.invalidate(upcomingAttendancesProvider);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<Attendance?> updateAttendance(int id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.updateAttendance(id, updates);
      state = const AsyncValue.data(null);
      ref.invalidate(attendancesProvider);
      ref.invalidate(attendanceByIdProvider(id));
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> deleteAttendance(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAttendance(id);
      state = const AsyncValue.data(null);
      ref.invalidate(attendancesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createPersonAttendances(List<PersonAttendance> records) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createPersonAttendances(records);
      state = const AsyncValue.data(null);
      // Invalidate relevant providers
      for (final record in records) {
        if (record.attendanceId != null) {
          ref.invalidate(attendanceByIdProvider(record.attendanceId!));
        }
        if (record.personId != null) {
          ref.invalidate(personAttendancesProvider(record.personId!));
        }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<PersonAttendance?> updatePersonAttendance(
    String id, 
    int attendanceId,
    int personId,
    Map<String, dynamic> updates,
  ) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.updatePersonAttendance(id, updates);
      state = const AsyncValue.data(null);
      ref.invalidate(attendanceByIdProvider(attendanceId));
      ref.invalidate(personAttendancesProvider(personId));
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> recalculatePercentage(int attendanceId) async {
    try {
      await _repo.recalculatePercentage(attendanceId);
      ref.invalidate(attendanceByIdProvider(attendanceId));
      ref.invalidate(attendancesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Batch update multiple person attendances with the same status
  Future<void> batchUpdatePersonAttendances(
    List<String> personAttendanceIds,
    int attendanceId,
    AttendanceStatus newStatus,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repo.batchUpdatePersonAttendances(personAttendanceIds, newStatus);
      state = const AsyncValue.data(null);
      ref.invalidate(attendanceByIdProvider(attendanceId));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final attendanceNotifierProvider = NotifierProvider<AttendanceNotifier, AsyncValue<void>>(() {
  return AttendanceNotifier();
});
