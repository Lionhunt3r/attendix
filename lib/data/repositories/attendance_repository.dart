import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../models/attendance/attendance.dart';
import 'base_repository.dart';

/// Provider for AttendanceRepository
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref);
});

/// Repository for attendance operations
class AttendanceRepository extends BaseRepository with TenantAwareRepository {
  AttendanceRepository(super.ref);

  /// Get all attendances for the current tenant
  Future<List<Attendance>> getAttendances({
    DateTime? since,
    bool withPersonAttendances = false,
    int limit = 50,
  }) async {
    try {
      final sinceDate = since ?? DateTime.now().subtract(const Duration(days: 180));
      
      String selectQuery = '*';
      if (withPersonAttendances) {
        selectQuery = '''*, persons:person_attendances(
          *, person:person_id(
            firstName, lastName, img, instrument(id, name), joined
          )
        )''';
      }

      final response = await supabase
          .from('attendance')
          .select(selectQuery)
          .eq('tenantId', currentTenantId)
          .gt('date', sinceDate.toIso8601String())
          .order('date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => _parseAttendance(e as Map<String, dynamic>, withPersonAttendances))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getAttendances');
      rethrow;
    }
  }

  /// Get upcoming attendances (future dates)
  Future<List<Attendance>> getUpcomingAttendances() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await supabase
          .from('attendance')
          .select('*')
          .eq('tenantId', currentTenantId)
          .gte('date', startOfDay.toIso8601String())
          .order('date');

      return (response as List)
          .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getUpcomingAttendances');
      rethrow;
    }
  }

  /// Get a single attendance by ID with person attendances
  Future<Attendance?> getAttendanceById(int id) async {
    try {
      final response = await supabase
          .from('attendance')
          .select('''*, persons:person_attendances(
            *, person:person_id(
              firstName, lastName, img, instrument(id, name), joined, appId, additional_fields
            )
          )''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return _parseAttendance(response, true);
    } catch (e, stack) {
      handleError(e, stack, 'getAttendanceById');
      rethrow;
    }
  }

  /// Create a new attendance
  Future<Attendance> createAttendance(Attendance attendance) async {
    try {
      final data = attendance.toJson();
      data['tenantId'] = currentTenantId;
      // Remove computed fields
      data.remove('persons');

      final response = await supabase
          .from('attendance')
          .insert(data)
          .select()
          .single();

      return Attendance.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'createAttendance');
      rethrow;
    }
  }

  /// Update an existing attendance
  Future<Attendance> updateAttendance(int id, Map<String, dynamic> updates) async {
    try {
      // Remove read-only fields
      updates.remove('id');
      updates.remove('created_at');
      updates.remove('tenantId');
      updates.remove('persons');

      final response = await supabase
          .from('attendance')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Attendance.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'updateAttendance');
      rethrow;
    }
  }

  /// Delete an attendance
  Future<void> deleteAttendance(int id) async {
    try {
      await supabase
          .from('attendance')
          .delete()
          .eq('id', id);
    } catch (e, stack) {
      handleError(e, stack, 'deleteAttendance');
      rethrow;
    }
  }

  /// Get person attendances for a specific person
  Future<List<PersonAttendance>> getPersonAttendancesForPerson(
    int personId, {
    DateTime? since,
  }) async {
    try {
      final sinceDate = since ?? DateTime.now().subtract(const Duration(days: 180));

      final response = await supabase
          .from('person_attendances')
          .select('*, attendance:attendance_id(id, date, type, typeInfo, songs, type_id, start_time, end_time, deadline)')
          .eq('person_id', personId)
          .gt('attendance.date', sinceDate.toIso8601String());

      return (response as List)
          .where((row) => row['attendance'] != null)
          .map((e) => _parsePersonAttendanceWithAttendance(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getPersonAttendancesForPerson');
      rethrow;
    }
  }

  /// Create person attendance records (batch)
  Future<void> createPersonAttendances(List<PersonAttendance> records) async {
    try {
      final data = records.map((r) {
        final json = r.toJson();
        // Only include necessary fields
        return {
          'attendance_id': json['attendance_id'],
          'person_id': json['person_id'],
          'status': json['status'],
          'notes': json['notes'],
        };
      }).toList();

      await supabase
          .from('person_attendances')
          .insert(data);
    } catch (e, stack) {
      handleError(e, stack, 'createPersonAttendances');
      rethrow;
    }
  }

  /// Update a single person attendance
  Future<PersonAttendance> updatePersonAttendance(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates.remove('id');
      updates.remove('firstName');
      updates.remove('lastName');
      updates.remove('img');
      updates.remove('instrument');
      updates.remove('groupName');
      updates.remove('joined');
      updates.remove('person');
      updates.remove('attendance');

      // Add changed metadata
      updates['changed_at'] = DateTime.now().toIso8601String();
      updates['changed_by'] = supabase.auth.currentUser?.id;

      final response = await supabase
          .from('person_attendances')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return PersonAttendance.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'updatePersonAttendance');
      rethrow;
    }
  }

  /// Delete person attendances for a specific person and attendance IDs
  Future<void> deletePersonAttendances(int personId, List<int> attendanceIds) async {
    try {
      await supabase
          .from('person_attendances')
          .delete()
          .eq('person_id', personId)
          .inFilter('attendance_id', attendanceIds);
    } catch (e, stack) {
      handleError(e, stack, 'deletePersonAttendances');
      rethrow;
    }
  }

  /// Batch update multiple person attendances with the same status
  Future<void> batchUpdatePersonAttendances(
    List<String> personAttendanceIds,
    AttendanceStatus newStatus,
  ) async {
    try {
      await supabase
          .from('person_attendances')
          .update({
            'status': newStatus.value,
            'changed_at': DateTime.now().toIso8601String(),
            'changed_by': supabase.auth.currentUser?.id,
          })
          .inFilter('id', personAttendanceIds);
    } catch (e, stack) {
      handleError(e, stack, 'batchUpdatePersonAttendances');
      rethrow;
    }
  }

  /// Get attendances for a specific date
  Future<List<Attendance>> getAttendancesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await supabase
          .from('attendance')
          .select('*')
          .eq('tenantId', currentTenantId)
          .gte('date', startOfDay.toIso8601String())
          .lt('date', endOfDay.toIso8601String())
          .order('date');

      return (response as List)
          .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getAttendancesByDate');
      rethrow;
    }
  }

  /// Calculate percentage for an attendance
  Future<void> recalculatePercentage(int attendanceId) async {
    try {
      final response = await supabase
          .from('person_attendances')
          .select('status')
          .eq('attendance_id', attendanceId);

      final statusList = (response as List).map((e) => e['status']).toList();

      if (statusList.isEmpty) {
        await updateAttendance(attendanceId, {'percentage': null});
        return;
      }

      final presentCount = statusList.where((s) {
        final status = _parseStatus(s);
        return status == AttendanceStatus.present ||
               status == AttendanceStatus.late ||
               status == AttendanceStatus.lateExcused;
      }).length;

      final percentage = (presentCount / statusList.length * 100).round();

      await updateAttendance(attendanceId, {'percentage': percentage.toDouble()});
    } catch (e, stack) {
      handleError(e, stack, 'recalculatePercentage');
      rethrow;
    }
  }

  // Helper to parse attendance with optional person attendances
  Attendance _parseAttendance(Map<String, dynamic> data, bool withPersons) {
    if (withPersons && data['persons'] != null) {
      // Parse nested person attendances
      final persons = (data['persons'] as List).map((pa) {
        final personData = pa['person'] as Map<String, dynamic>?;
        return PersonAttendance(
          id: pa['id']?.toString(),
          attendanceId: pa['attendance_id'],
          personId: pa['person_id'],
          status: _parseStatus(pa['status']),
          notes: pa['notes'],
          firstName: personData?['firstName'],
          lastName: personData?['lastName'],
          img: personData?['img'],
          instrument: personData?['instrument']?['id'],
          groupName: personData?['instrument']?['name'],
          joined: personData?['joined'],
        );
      }).toList();

      // Create attendance with parsed persons
      final attendance = Attendance.fromJson(data);
      // Note: We'd need to add a persons field to the Attendance model
      // For now, we return the base attendance
      return attendance;
    }

    return Attendance.fromJson(data);
  }

  PersonAttendance _parsePersonAttendanceWithAttendance(Map<String, dynamic> data) {
    final attendanceData = data['attendance'] as Map<String, dynamic>?;
    
    return PersonAttendance(
      id: data['id']?.toString(),
      attendanceId: data['attendance_id'],
      personId: data['person_id'],
      status: _parseStatus(data['status']),
      notes: data['notes'],
      date: attendanceData?['date'],
      title: attendanceData?['typeInfo'],
    );
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
