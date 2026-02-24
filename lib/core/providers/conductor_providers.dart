import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/person/person.dart';
import 'group_providers.dart';
import 'player_providers.dart';

/// Provider for conductors (main group members)
/// Conductors are members of the "main group" (Hauptgruppe/Dirigenten)
final conductorsProvider = FutureProvider<List<Person>>((ref) async {
  final repo = ref.watch(playerRepositoryWithTenantProvider);
  final mainGroup = await ref.watch(mainGroupProvider.future);

  if (!repo.hasTenantId || mainGroup == null || mainGroup.id == null) {
    return [];
  }

  return repo.getConductors(mainGroup.id!, includeLeft: true);
});

/// Provider for active conductors only (not left)
final activeConductorsProvider = FutureProvider<List<Person>>((ref) async {
  final conductors = await ref.watch(conductorsProvider.future);
  return conductors.where((c) => c.left == null).toList();
});
