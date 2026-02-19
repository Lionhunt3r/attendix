import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/person/person.dart';
import '../../data/repositories/teacher_repository.dart';
import 'tenant_providers.dart';

/// Initialized teacher repository with tenant context
final teacherRepositoryWithTenantProvider = Provider<TeacherRepository>((ref) {
  final repo = ref.watch(teacherRepositoryProvider);
  final tenant = ref.watch(currentTenantIdProvider);

  if (tenant != null) {
    repo.setTenantId(tenant);
  }

  return repo;
});

/// Provider for teachers list
final teachersProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(teacherRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return [];

  return repo.getTeachers();
});

/// Provider for a single teacher by ID
final teacherByIdProvider = FutureProvider.family<Person?, int>((ref, id) async {
  final repo = ref.watch(teacherRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return null;

  return repo.getTeacherById(id);
});

/// Provider for student counts per teacher
final studentCountsProvider = FutureProvider<Map<int, int>>((ref) async {
  final repo = ref.watch(teacherRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return {};

  return repo.getStudentCounts();
});

/// Notifier for teacher mutations
class TeacherNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  TeacherRepository get _repo => ref.read(teacherRepositoryWithTenantProvider);

  Future<Person?> createTeacher(Person teacher) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createTeacher(teacher);
      state = const AsyncValue.data(null);
      ref.invalidate(teachersProvider);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<Person?> updateTeacher(int id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.updateTeacher(id, updates);
      state = const AsyncValue.data(null);
      ref.invalidate(teachersProvider);
      ref.invalidate(teacherByIdProvider(id));
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> deleteTeacher(int id) async {
    state = const AsyncValue.loading();
    try {
      final success = await _repo.deleteTeacher(id);
      state = const AsyncValue.data(null);
      ref.invalidate(teachersProvider);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final teacherNotifierProvider = NotifierProvider<TeacherNotifier, AsyncValue<void>>(() {
  return TeacherNotifier();
});
