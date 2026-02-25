import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attendance/attendance.dart';
import '../../data/models/person/person.dart';
import '../config/supabase_config.dart';
import 'tenant_providers.dart';

/// Provider for attendance detail
/// FN-004: Added tenantId filter for multi-tenant security
final attendanceDetailProvider = FutureProvider.autoDispose.family<Attendance?, int>((ref, attendanceId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant?.id == null) return null;

  final response = await supabase
      .from('attendance')
      .select('*')
      .eq('id', attendanceId)
      .eq('tenantId', tenant!.id!)
      .maybeSingle();

  if (response == null) return null;
  // response is already Map<String, dynamic> from maybeSingle()
  return Attendance.fromJson(response);
});

/// Provider for attendance type of a specific attendance
/// FN-005: Added tenant_id filter for multi-tenant security
final attendanceTypeForAttendanceProvider = FutureProvider.autoDispose.family<AttendanceType?, int>((ref, attendanceId) async {
  final attendance = await ref.watch(attendanceDetailProvider(attendanceId).future);
  if (attendance?.typeId == null) return null;

  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant?.id == null) return null;

  final response = await supabase
      .from('attendance_types')
      .select('*')
      .eq('id', attendance!.typeId!)
      .eq('tenant_id', tenant!.id!)
      .maybeSingle();

  if (response == null) return null;
  return AttendanceType.fromJson(response);
});

/// Provider for person attendances for a specific attendance
/// NOTE: This is different from personAttendancesProvider in attendance_providers.dart
/// which gets attendances for a specific PERSON. This one gets persons for a specific ATTENDANCE.
/// SEC-017: Added tenant filter via inner join with attendance table
final personAttendancesForAttendanceProvider = FutureProvider.autoDispose.family<List<PersonAttendance>, int>((ref, attendanceId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  // Get all persons with their attendance status for this attendance
  // SEC-017: Use inner join with attendance to filter by tenant
  final response = await supabase
      .from('person_attendances')
      .select('*, player:person_id(firstName, lastName, img, instrument, left, paused), attendance:attendance_id!inner(tenantId)')
      .eq('attendance_id', attendanceId)
      .eq('attendance.tenantId', tenant.id!);

  return (response as List).map((e) {
    // Extract player data from nested structure - handle potential type mismatch
    final playerData = e['player'];
    final playerMap = playerData is Map<String, dynamic> ? playerData : null;
    return PersonAttendance.fromJson({
      ...e,
      'firstName': playerMap?['firstName'],
      'lastName': playerMap?['lastName'],
      'img': playerMap?['img'],
      'instrument': playerMap?['instrument'],
      'left': playerMap?['left'],
      'paused': playerMap?['paused'],
    });
  }).toList();
});

/// Provider that returns filtered person attendances based on attendance date
/// - Past attendances: Show all persons (including archived/paused for historical correctness)
/// - Future attendances: Only show active persons
final filteredPersonAttendancesForAttendanceProvider = FutureProvider.autoDispose.family<List<PersonAttendance>, int>((ref, attendanceId) async {
  final personAttendances = await ref.watch(personAttendancesForAttendanceProvider(attendanceId).future);
  final attendance = await ref.watch(attendanceDetailProvider(attendanceId).future);

  if (attendance == null) return personAttendances;

  final attendanceDate = DateTime.tryParse(attendance.date);
  final isPast = attendanceDate != null &&
      attendanceDate.isBefore(DateTime.now().subtract(const Duration(hours: 12)));

  if (isPast) {
    // Past attendances: Show all persons
    return personAttendances;
  } else {
    // Future attendances: Only show active persons
    return personAttendances.where((pa) => pa.isActive).toList();
  }
});

/// Provider for all persons in tenant (for attendance taking)
final allPersonsForAttendanceProvider = FutureProvider.autoDispose<List<Person>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('player')
      .select('*, instrument:instrument(id, name)')
      .eq('tenantId', tenant.id!)
      .order('lastName', ascending: true);

  return (response as List).map((e) {
    final instrumentData = e['instrument'] as Map<String, dynamic>?;
    return Person.fromJson(e as Map<String, dynamic>).copyWith(
      groupName: instrumentData?['name'] as String?,
    );
  }).toList();
});

/// Provider for filtered persons based on attendance date
/// - Past attendances: Show all persons
/// - Future attendances: Only show active persons (not left, not paused)
final filteredPersonsForAttendanceProvider = FutureProvider.autoDispose.family<List<Person>, int>((ref, attendanceId) async {
  final allPersons = await ref.watch(allPersonsForAttendanceProvider.future);
  final attendance = await ref.watch(attendanceDetailProvider(attendanceId).future);

  if (attendance == null) return allPersons;

  final attendanceDate = DateTime.tryParse(attendance.date);
  final isPast = attendanceDate != null &&
      attendanceDate.isBefore(DateTime.now().subtract(const Duration(hours: 12)));

  if (isPast) {
    // Past attendances: Show all persons
    return allPersons;
  } else {
    // Future attendances: Only show active persons
    return allPersons.where((p) => p.isActive).toList();
  }
});
