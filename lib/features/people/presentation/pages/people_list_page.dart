import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/person/person.dart';
import '../../../../core/providers/tenant_providers.dart';

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
  
  if (tenant == null) return [];

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
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text('Fehler: $error'),
                    const SizedBox(height: AppDimensions.paddingM),
                    ElevatedButton(
                      onPressed: () => ref.refresh(peopleListProvider),
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
              data: (people) {
                final filteredPeople = _filterPeople(people);
                final sortedPeople = _sortPeople(filteredPeople);

                if (people.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 80,
                          color: AppColors.medium,
                        ),
                        const SizedBox(height: AppDimensions.paddingL),
                        Text(
                          'Keine Personen',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        Text(
                          'Füge die erste Person hinzu',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.medium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (sortedPeople.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.medium,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          _searchQuery.isNotEmpty 
                            ? 'Keine Ergebnisse für "$_searchQuery"'
                            : 'Keine Personen für diesen Filter',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
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
                            ...groupPeople.map((person) => _PersonListItem(
                              person: person,
                              onTap: () => context.push('/people/${person.id}'),
                            )),
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
                      return _PersonListItem(
                        person: person,
                        onTap: () => context.push('/people/${person.id}'),
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
}

class _PersonListItem extends StatelessWidget {
  const _PersonListItem({
    required this.person,
    required this.onTap,
  });

  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
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
    );
  }
}