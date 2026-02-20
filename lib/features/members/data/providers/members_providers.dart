import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../data/models/person/person.dart';

/// Model for a grouped member list
class MembersGroup {
  final int groupId;
  final String groupName;
  final List<Person> members;

  const MembersGroup({
    required this.groupId,
    required this.groupName,
    required this.members,
  });
}

/// Provider for all active members grouped by instrument
final membersGroupedProvider = FutureProvider<List<MembersGroup>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  // Get all groups/instruments
  final groupsResponse = await supabase
      .from('instruments')
      .select('id, name, maingroup')
      .eq('tenantId', tenant.id!)
      .order('maingroup', ascending: false)
      .order('name');

  final groups = (groupsResponse as List).map((g) => {
    'id': g['id'] as int,
    'name': g['name'] as String,
    'maingroup': g['maingroup'] as bool? ?? false,
  }).toList();

  // Get all active players
  final playersResponse = await supabase
      .from('player')
      .select('*')
      .eq('tenantId', tenant.id!)
      .isFilter('left', null)
      .isFilter('pending', false)
      .order('isLeader', ascending: false)
      .order('lastName');

  final players = (playersResponse as List)
      .map((e) => Person.fromJson(e as Map<String, dynamic>))
      .toList();

  // Group players by instrument
  final List<MembersGroup> result = [];

  for (final group in groups) {
    final groupId = group['id'] as int;
    final groupName = group['name'] as String;
    final groupMembers = players.where((p) => p.instrument == groupId).toList();

    if (groupMembers.isNotEmpty) {
      result.add(MembersGroup(
        groupId: groupId,
        groupName: groupName,
        members: groupMembers,
      ));
    }
  }

  return result;
});

/// Provider for total member count
final memberCountProvider = Provider<int>((ref) {
  final groupsAsync = ref.watch(membersGroupedProvider);
  return groupsAsync.whenOrNull(
    data: (groups) => groups.fold<int>(0, (sum, g) => sum + g.members.length),
  ) ?? 0;
});

/// Provider for filtered members based on search term
final membersSearchTermProvider = StateProvider<String>((ref) => '');

/// Provider for filtered members
final filteredMembersGroupedProvider = Provider<AsyncValue<List<MembersGroup>>>((ref) {
  final groupsAsync = ref.watch(membersGroupedProvider);
  final searchTerm = ref.watch(membersSearchTermProvider).toLowerCase();

  return groupsAsync.whenData((groups) {
    if (searchTerm.isEmpty) return groups;

    final List<MembersGroup> filtered = [];

    for (final group in groups) {
      final matchingMembers = group.members.where((p) {
        return p.firstName.toLowerCase().contains(searchTerm) ||
            p.lastName.toLowerCase().contains(searchTerm) ||
            group.groupName.toLowerCase().contains(searchTerm);
      }).toList();

      if (matchingMembers.isNotEmpty) {
        filtered.add(MembersGroup(
          groupId: group.groupId,
          groupName: group.groupName,
          members: matchingMembers,
        ));
      }
    }

    return filtered;
  });
});
