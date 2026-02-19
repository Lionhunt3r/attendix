import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/person/person.dart';
import 'base_repository.dart';

/// Repository for Teacher (Ausbilder/Dirigent) operations
class TeacherRepository extends BaseRepository with TenantAwareRepository {
  TeacherRepository(super.ref);

  /// Get all teachers for current tenant
  /// Teachers are stored in the 'ausbilder' table
  Future<List<Person>> getTeachers() async {
    try {
      final response = await supabase
          .from('ausbilder')
          .select()
          .eq('tenant_id', currentTenantId)
          .order('lastName', ascending: true);

      return (response as List).map((json) => Person.fromJson(json)).toList();
    } catch (e, stack) {
      handleError(e, stack, 'getTeachers');
      return [];
    }
  }

  /// Get a single teacher by ID
  Future<Person?> getTeacherById(int id) async {
    try {
      final response = await supabase
          .from('ausbilder')
          .select()
          .eq('id', id)
          .eq('tenant_id', currentTenantId)
          .single();

      return Person.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'getTeacherById');
      return null;
    }
  }

  /// Create a new teacher
  Future<Person?> createTeacher(Person teacher) async {
    try {
      final data = {
        'firstName': teacher.firstName,
        'lastName': teacher.lastName,
        'email': teacher.email,
        'phone': teacher.phone,
        'notes': teacher.notes,
        'instrument': teacher.instrument,
        'tenant_id': currentTenantId,
      };

      final response = await supabase
          .from('ausbilder')
          .insert(data)
          .select()
          .single();

      return Person.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'createTeacher');
      return null;
    }
  }

  /// Update a teacher
  Future<Person?> updateTeacher(int id, Map<String, dynamic> updates) async {
    try {
      final response = await supabase
          .from('ausbilder')
          .update(updates)
          .eq('id', id)
          .eq('tenant_id', currentTenantId)
          .select()
          .single();

      return Person.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'updateTeacher');
      return null;
    }
  }

  /// Delete a teacher
  Future<bool> deleteTeacher(int id) async {
    try {
      await supabase
          .from('ausbilder')
          .delete()
          .eq('id', id)
          .eq('tenant_id', currentTenantId);

      return true;
    } catch (e, stack) {
      handleError(e, stack, 'deleteTeacher');
      return false;
    }
  }

  /// Get count of students per teacher
  Future<Map<int, int>> getStudentCounts() async {
    try {
      final response = await supabase
          .from('person')
          .select('teacher')
          .eq('tenant_id', currentTenantId)
          .not('teacher', 'is', null);

      final counts = <int, int>{};
      for (final row in (response as List)) {
        final teacherId = row['teacher'] as int?;
        if (teacherId != null) {
          counts[teacherId] = (counts[teacherId] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e, stack) {
      handleError(e, stack, 'getStudentCounts');
      return {};
    }
  }
}

/// Provider for TeacherRepository
final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository(ref);
});
