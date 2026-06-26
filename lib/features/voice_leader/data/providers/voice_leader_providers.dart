import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/providers/attendance_providers.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/providers/player_providers.dart';
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
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId = authState?.session?.user.id;
  if (userId == null) return null;

  final repo = ref.watch(playerRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return null;

  return repo.getPlayerByAppId(userId);
});

/// Provider for the voice group name (instrument display name).
final voiceGroupNameProvider = FutureProvider<String?>((ref) async {
  final currentPlayer = await ref.watch(currentPlayerProvider.future);
  final instrumentId = currentPlayer?.instrument;
  if (instrumentId == null) return null;

  final repo = ref.watch(groupRepositoryWithTenantProvider);
  if (!repo.hasTenantId) return null;

  final group = await repo.getGroupById(instrumentId);
  return group?.name;
});

/// Provider for voice group members with their upcoming absences
final voiceGroupMembersProvider =
    FutureProvider<List<VoiceGroupMember>>((ref) async {
  final currentPlayer = await ref.watch(currentPlayerProvider.future);
  final instrumentId = currentPlayer?.instrument;
  if (instrumentId == null) return [];

  final playerRepo = ref.watch(playerRepositoryWithTenantProvider);
  final attendanceRepo = ref.watch(attendanceRepositoryWithTenantProvider);
  if (!playerRepo.hasTenantId || !attendanceRepo.hasTenantId) return [];

  // Load every active player in the same voice group.
  final players = await playerRepo.getPlayersByInstrument(instrumentId);

  // Batch-fetch upcoming absences for all of them in a single query.
  final playerIds = players
      .where((p) => p.id != null)
      .map((p) => p.id!)
      .toList(growable: false);
  final absencesRows =
      await attendanceRepo.getUpcomingAbsencesForPersons(playerIds);

  // Group absences by person_id, filtering past dates in Dart so the SQL
  // semantics stay identical to the previous implementation.
  final now = DateTime.now();
  final absencesByPerson = <int, List<UpcomingAbsence>>{};
  for (final row in absencesRows) {
    final personId = row['person_id'] as int?;
    final attendance = row['attendance'];
    if (personId == null || attendance is! Map) continue;

    final dateStr = attendance['date'] as String?;
    if (dateStr == null) continue;
    final date = DateTime.tryParse(dateStr);
    if (date == null || date.isBefore(now)) continue;

    final typeInfo = attendance['typeInfo'];
    absencesByPerson.putIfAbsent(personId, () => []).add(
          UpcomingAbsence(
            attendanceId: attendance['id'] as int,
            date: date,
            status: row['status'] as int,
            typeName: typeInfo is Map ? typeInfo['short'] as String? : null,
          ),
        );
  }

  return [
    for (final player in players)
      VoiceGroupMember(
        person: player,
        upcomingAbsences: (absencesByPerson[player.id] ?? [])
          ..sort((a, b) => a.date.compareTo(b.date)),
      ),
  ];
});
