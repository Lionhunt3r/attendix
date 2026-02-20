import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../data/models/person/person.dart';

/// Model for a voice group member with their upcoming absences
class VoiceGroupMember {
  final Person person;
  final List<UpcomingAbsence> upcomingAbsences;

  const VoiceGroupMember({
    required this.person,
    required this.upcomingAbsences,
  });
}

/// Model for an upcoming absence
class UpcomingAbsence {
  final int attendanceId;
  final DateTime date;
  final int status;
  final String? typeName;

  const UpcomingAbsence({
    required this.attendanceId,
    required this.date,
    required this.status,
    this.typeName,
  });
}

/// Provider for the current user's player record
final currentPlayerProvider = FutureProvider<Person?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  final userId = supabase.auth.currentUser?.id;

  if (tenant == null || userId == null) return null;

  final response = await supabase
      .from('player')
      .select('*')
      .eq('appId', userId)
      .eq('tenantId', tenant.id!)
      .maybeSingle();

  if (response == null) return null;
  return Person.fromJson(response);
});

/// Provider for the voice group name
final voiceGroupNameProvider = FutureProvider<String?>((ref) async {
  final currentPlayer = await ref.watch(currentPlayerProvider.future);
  if (currentPlayer?.instrument == null) return null;

  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('instruments')
      .select('name')
      .eq('id', currentPlayer!.instrument!)
      .maybeSingle();

  if (response == null) return null;
  return response['name'] as String?;
});

/// Provider for voice group members with their upcoming absences
final voiceGroupMembersProvider = FutureProvider<List<VoiceGroupMember>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  final currentPlayer = await ref.watch(currentPlayerProvider.future);

  if (tenant == null || currentPlayer == null || currentPlayer.instrument == null) {
    return [];
  }

  // Get all players in the same group
  final playersResponse = await supabase
      .from('player')
      .select('*')
      .eq('tenantId', tenant.id!)
      .eq('instrument', currentPlayer.instrument!)
      .isFilter('left', null)
      .isFilter('pending', false)
      .order('isLeader', ascending: false)
      .order('lastName');

  final players = (playersResponse as List)
      .map((e) => Person.fromJson(e as Map<String, dynamic>))
      .toList();

  // Get upcoming absences for all players
  final List<VoiceGroupMember> members = [];
  final now = DateTime.now();

  for (final player in players) {
    if (player.id == null) continue;

    // Get upcoming absences (excused=2, absent=4, late_excused=5)
    final absencesResponse = await supabase
        .from('person_attendances')
        .select('*, attendance:attendance_id(id, date, type, typeInfo)')
        .eq('person_id', player.id!)
        .inFilter('status', [2, 4, 5]);

    final absences = <UpcomingAbsence>[];
    for (final item in absencesResponse as List) {
      final attendance = item['attendance'];
      if (attendance == null) continue;

      final dateStr = attendance['date'] as String?;
      if (dateStr == null) continue;

      final date = DateTime.tryParse(dateStr);
      if (date == null || date.isBefore(now)) continue;

      absences.add(UpcomingAbsence(
        attendanceId: attendance['id'] as int,
        date: date,
        status: item['status'] as int,
        typeName: attendance['typeInfo']?['short'] as String?,
      ));
    }

    // Sort by date
    absences.sort((a, b) => a.date.compareTo(b.date));

    members.add(VoiceGroupMember(
      person: player,
      upcomingAbsences: absences,
    ));
  }

  return members;
});
