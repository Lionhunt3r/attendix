import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/player_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/person/person.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../shared/widgets/loading/loading.dart';
import '../../../../shared/widgets/common/empty_state.dart';
import '../../../../shared/widgets/animations/animated_list_item.dart';

/// Provider for groups/instruments
final groupsProvider = FutureProvider<Map<int, String>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  
  if (tenant == null) return {};

  final response = await supabase
      .from('instruments')
      .select('id, name')
      .eq('tenantId', tenant.id!);

  final map = <int, String>{};
  for (final row in response as List) {
    map[row['id'] as int] = row['name'] as String;
  }
  return map;
});

/// Provider for people list (active players only)
final peopleListProvider = FutureProvider<List<Person>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  final groups = await ref.watch(groupsProvider.future);
  final repository = ref.watch(playerRepositoryWithTenantProvider);

  if (tenant == null) return [];

  // Check for auto-unpause (players whose pause period has ended)
  await repository.checkAndUnpausePlayers();

  try {
    final response = await supabase
        .from('player')
        .select('*')
        .eq('tenantId', tenant.id!)
        .isFilter('left', null)      // Only active (not archived/left)
        .isFilter('pending', false)  // Only confirmed players
        .order('instrument')         // Sort by group (instrument) first
        .order('isLeader', ascending: false)  // Leaders first
        .order('lastName');

    // Parse and add group name from groups map
    return (response as List).map((e) {
      try {
        final person = Person.fromJson(e as Map<String, dynamic>);
        // Add group name from the groups map
        final groupName = person.instrument != null ? groups[person.instrument] : null;
        return person.copyWith(groupName: groupName);
      } catch (parseError) {
        debugPrint('Error parsing person: $parseError');
        debugPrint('JSON data: $e');
        rethrow;
      }
    }).toList();
  } catch (e, stack) {
    debugPrint('Error fetching people: $e');
    debugPrint('Stack trace: $stack');
    rethrow;
  }
});

/// People list page
class PeopleListPage extends ConsumerStatefulWidget {
  const PeopleListPage({super.key});

  @override
  ConsumerState<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends ConsumerState<PeopleListPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _filterOption = 'all';
  String _sortOption = 'group';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Person> _filterPeople(List<Person> people) {
    var filtered = people;
    
    // Apply filter
    switch (_filterOption) {
      case 'critical':
        filtered = filtered.where((p) => p.isCritical).toList();
        break;
      case 'paused':
        filtered = filtered.where((p) => p.paused).toList();
        break;
      case 'leaders':
        filtered = filtered.where((p) => p.isLeader).toList();
        break;
      case 'active':
        filtered = filtered.where((p) => !p.paused).toList();
        break;
    }
    
    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((person) {
        return person.firstName.toLowerCase().contains(query) ||
            person.lastName.toLowerCase().contains(query) ||
            (person.groupName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return filtered;
  }

  List<Person> _sortPeople(List<Person> people) {
    final sorted = List<Person>.from(people);
    
    switch (_sortOption) {
      case 'firstName':
        sorted.sort((a, b) => a.firstName.compareTo(b.firstName));
        break;
      case 'lastName':
        sorted.sort((a, b) => a.lastName.compareTo(b.lastName));
        break;
      case 'group':
      default:
        sorted.sort((a, b) {
          final groupCompare = (a.groupName ?? '').compareTo(b.groupName ?? '');
          if (groupCompare != 0) return groupCompare;
          return a.lastName.compareTo(b.lastName);
        });
        break;
    }
    
    return sorted;
  }

  /// Group people by their group name
  Map<String, List<Person>> _groupByGroup(List<Person> people) {
    final grouped = <String, List<Person>>{};
    for (final person in people) {
      final group = person.groupName ?? 'Keine Gruppe';
      grouped.putIfAbsent(group, () => []);
      grouped[group]!.add(person);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final tenant = ref.watch(currentTenantProvider);
    final peopleAsync = ref.watch(peopleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personen'),
            if (tenant != null)
              Text(
                tenant.shortName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.medium,
                ),
              ),
          ],
        ),
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: Icon(
              Icons.filter_list,
              color: _filterOption != 'all' ? AppColors.primary : null,
            ),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() {
                _filterOption = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Alle')),
              const PopupMenuItem(value: 'active', child: Text('Aktiv')),
              const PopupMenuItem(value: 'paused', child: Text('Pausiert')),
              const PopupMenuItem(value: 'critical', child: Text('Kritisch')),
              const PopupMenuItem(value: 'leaders', child: Text('Leiter')),
            ],
          ),
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sortierung',
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'group',
                child: Row(
                  children: [
                    if (_sortOption == 'group') 
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Nach Gruppe'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'lastName',
                child: Row(
                  children: [
                    if (_sortOption == 'lastName') 
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Nach Nachname'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'firstName',
                child: Row(
                  children: [
                    if (_sortOption == 'firstName') 
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Nach Vorname'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Gruppe wechseln',
            onPressed: () => context.go('/tenants'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Active filter chip
          if (_filterOption != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
              child: Row(
                children: [
                  Chip(
                    label: Text(_getFilterLabel(_filterOption)),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _filterOption = 'all';
                      });
                    },
                  ),
                ],
              ),
            ),

          // People list
          Expanded(
            child: peopleAsync.when(
              loading: () => const ListSkeleton(
                itemCount: 10,
                showAvatar: true,
                showSubtitle: true,
              ),
              error: (error, stack) => EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Fehler beim Laden',
                subtitle: 'Die Personenliste konnte nicht geladen werden.',
                actionLabel: 'Erneut versuchen',
                onAction: () => ref.refresh(peopleListProvider),
              ),
              data: (people) {
                final filteredPeople = _filterPeople(people);
                final sortedPeople = _sortPeople(filteredPeople);

                if (people.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'Keine Personen',
                    subtitle: 'Füge die erste Person hinzu',
                    actionLabel: 'Person hinzufügen',
                    onAction: () => context.push('/people/new'),
                  );
                }

                if (sortedPeople.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off,
                    title: _searchQuery.isNotEmpty
                        ? 'Keine Ergebnisse für "$_searchQuery"'
                        : 'Keine Personen für diesen Filter',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Versuche es mit einem anderen Suchbegriff'
                        : 'Passe den Filter an oder setze ihn zurück',
                    animateIcon: false,
                  );
                }

                // Group by group if sorted by group
                if (_sortOption == 'group') {
                  final grouped = _groupByGroup(sortedPeople);
                  final groups = grouped.keys.toList()..sort();
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.refresh(peopleListProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                      ),
                      itemCount: groups.length,
                      itemBuilder: (context, groupIndex) {
                        final groupName = groups[groupIndex];
                        final groupPeople = grouped[groupName]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Group header
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppDimensions.paddingM,
                                bottom: AppDimensions.paddingS,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    groupName,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppDimensions.paddingS),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${groupPeople.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Group members
                            ...groupPeople.asMap().entries.map((entry) {
                              final index = entry.key;
                              final person = entry.value;
                              return AnimatedListItem(
                                index: index,
                                child: _PersonListItem(
                                  person: person,
                                  onTap: () => context.push('/people/${person.id}'),
                                  onPause: () => _showPauseDialog(person),
                                  onUnpause: () => _unpausePerson(person),
                                  onArchive: () => _showArchiveDialog(person),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(peopleListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                    ),
                    itemCount: sortedPeople.length,
                    itemBuilder: (context, index) {
                      final person = sortedPeople[index];
                      return AnimatedListItem(
                        index: index,
                        child: _PersonListItem(
                          person: person,
                          onTap: () => context.push('/people/${person.id}'),
                          onPause: () => _showPauseDialog(person),
                          onUnpause: () => _unpausePerson(person),
                          onArchive: () => _showArchiveDialog(person),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/people/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    return switch (filter) {
      'critical' => 'Kritisch',
      'paused' => 'Pausiert',
      'leaders' => 'Leiter',
      'active' => 'Aktiv',
      _ => 'Alle',
    };
  }

  /// Show pause dialog for a person
  Future<void> _showPauseDialog(Person person) async {
    final reasonController = TextEditingController();
    DateTime? pauseUntil;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppDimensions.paddingL,
            right: AppDimensions.paddingL,
            top: AppDimensions.paddingL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.pause_circle, color: AppColors.warning, size: 28),
                  const SizedBox(width: AppDimensions.paddingS),
                  Expanded(
                    child: Text(
                      '${person.firstName} pausieren',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingL),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Grund *',
                  hintText: 'Warum wird pausiert?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Pausiert bis (optional)'),
                subtitle: Text(
                  pauseUntil != null
                      ? DateFormat('dd.MM.yyyy').format(pauseUntil!)
                      : 'Kein Enddatum',
                  style: TextStyle(
                    color: pauseUntil != null ? AppColors.primary : AppColors.medium,
                  ),
                ),
                trailing: pauseUntil != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.medium),
                        onPressed: () => setDialogState(() => pauseUntil = null),
                      )
                    : null,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() => pauseUntil = date);
                  }
                },
              ),
              const SizedBox(height: AppDimensions.paddingL),
              FilledButton.icon(
                onPressed: () {
                  if (reasonController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bitte Grund angeben')),
                    );
                    return;
                  }
                  Navigator.pop(context, {
                    'reason': reasonController.text,
                    'until': pauseUntil?.toIso8601String(),
                  });
                },
                icon: const Icon(Icons.pause),
                label: const Text('Pausieren'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
            ],
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      await _pausePerson(person, result['reason'], result['until']);
    }
  }

  /// Pause a person
  Future<void> _pausePerson(Person person, String reason, String? until) async {
    final repository = ref.read(playerRepositoryWithTenantProvider);
    // Cache ScaffoldMessenger before async gap to avoid disposed context issues
    final messenger = ScaffoldMessenger.of(context);

    // Format reason with date if provided
    final reasonText = until != null
        ? '$reason (bis ${DateFormat('dd.MM.yyyy').format(DateTime.parse(until))})'
        : reason;

    try {
      await repository.pausePlayer(person, until, reasonText);
      ref.invalidate(peopleListProvider);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${person.firstName} wurde pausiert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  /// Unpause a person
  Future<void> _unpausePerson(Person person) async {
    final repository = ref.read(playerRepositoryWithTenantProvider);
    // Cache ScaffoldMessenger before async gap to avoid disposed context issues
    final messenger = ScaffoldMessenger.of(context);

    try {
      await repository.unpausePlayer(person);
      ref.invalidate(peopleListProvider);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${person.firstName} wurde reaktiviert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  /// Show archive confirmation dialog
  Future<void> _showArchiveDialog(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${person.firstName} archivieren?'),
        content: const Text(
          'Die Person wird als "ausgetreten" markiert und erscheint nicht mehr in der aktiven Liste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archivieren'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _archivePerson(person);
    }
  }

  /// Archive a person
  Future<void> _archivePerson(Person person) async {
    final repository = ref.read(playerRepositoryWithTenantProvider);

    try {
      await repository.archivePlayer(
        person,
        DateTime.now().toIso8601String(),
        null,
      );
      ref.invalidate(peopleListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${person.firstName} wurde archiviert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }
}

class _PersonListItem extends StatelessWidget {
  const _PersonListItem({
    required this.person,
    required this.onTap,
    this.onPause,
    this.onUnpause,
    this.onArchive,
  });

  final Person person;
  final VoidCallback onTap;
  final VoidCallback? onPause;
  final VoidCallback? onUnpause;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardShape = theme.cardTheme.shape as RoundedRectangleBorder? ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
        );
    final cardBorderRadius = cardShape.borderRadius.resolve(Directionality.of(context));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Slidable(
        key: ValueKey(person.id),
        // Swipe left for pause/unpause
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (slideContext) {
                // Close the slidable first
                Slidable.of(slideContext)?.close();
                if (!person.paused && onPause != null) {
                  onPause!();
                } else if (person.paused && onUnpause != null) {
                  onUnpause!();
                }
              },
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.only(left: AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: person.paused ? AppColors.success : AppColors.warning,
                  borderRadius: cardBorderRadius,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        person.paused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        person.paused ? 'Aktiv' : 'Pause',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Swipe right for archive
        startActionPane: onArchive != null
            ? ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.25,
                children: [
                  CustomSlidableAction(
                    onPressed: (slideContext) {
                      Slidable.of(slideContext)?.close();
                      onArchive!();
                    },
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    child: Container(
                      margin: const EdgeInsets.only(right: AppDimensions.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: cardBorderRadius,
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.archive,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Archiv',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : null,
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: onTap,
            leading: CircleAvatar(
              backgroundColor: person.critical
                  ? AppColors.danger.withValues(alpha: 0.2)
                  : person.paused
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : AppColors.primaryLight.withValues(alpha: 0.2),
              backgroundImage: (person.imageUrl != null &&
                  !person.imageUrl!.contains('.svg'))
                  ? NetworkImage(person.imageUrl!)
                  : null,
              child: (person.imageUrl == null || person.imageUrl!.contains('.svg'))
                  ? Text(
                      person.initials,
                      style: TextStyle(
                        color: person.critical
                            ? AppColors.danger
                            : person.paused
                                ? AppColors.warning
                                : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    person.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (person.isLeader)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.star,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                if (person.paused)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.pause_circle_outline,
                      size: 18,
                      color: AppColors.warning,
                    ),
                  ),
                if (person.critical)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.warning_amber,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),
            subtitle: person.groupName != null
                ? Text(
                    person.groupName!,
                    style: const TextStyle(
                      color: AppColors.medium,
                      fontSize: 13,
                    ),
                  )
                : null,
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.medium,
            ),
          ),
        ),
      ),
    );
  }
}