/// Supabase table names - single source of truth
///
/// Use these constants instead of hardcoded strings to prevent typos
/// and ensure consistency across the codebase.
abstract class SupabaseTables {
  static const String tenants = 'tenants';
  static const String player = 'player';
  static const String attendance = 'attendance';
  static const String personAttendances = 'person_attendances';
  static const String attendanceTypes = 'attendance_types';
  static const String instruments = 'instruments';
  static const String songs = 'songs';
  static const String meetings = 'meetings';
  static const String history = 'history';
  static const String tenantUsers = 'tenantUsers';
  static const String viewers = 'viewers';
  static const String parents = 'parents';
  static const String conductors = 'conductors';
  static const String teachers = 'teachers';
  static const String shifts = 'shifts';
  static const String notifications = 'notifications';
  static const String songCategories = 'song_categories';
  static const String groupCategories = 'group_categories';
  static const String scores = 'scores';
  static const String feedback = 'feedback';
  static const String questions = 'questions';
  static const String churches = 'churches';
  static const String tenantGroups = 'tenant_groups';
  static const String tenantGroupTenants = 'tenant_group_tenants';
}

/// Supabase storage bucket names
abstract class SupabaseBuckets {
  static const String songs = 'songs';
  static const String attendanceImages = 'attendance-images';
  static const String profiles = 'profiles';
}
