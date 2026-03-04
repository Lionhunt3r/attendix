import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/tenant_label_utils.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/instrument/instrument.dart';
import '../widgets/instrument_categories_sheet.dart';

/// Instruments list page — grouped by category with player counts
class InstrumentsListPage extends ConsumerWidget {
  const InstrumentsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final categoriesAsync = ref.watch(groupCategoriesProvider);
    final playerCountsAsync = ref.watch(playerCountsForGroupsProvider);
    final currentRole = ref.watch(currentRoleProvider);
    final isConductor = currentRole.isConductor;
    final tenant = ref.watch(currentTenantProvider);
    final label = groupLabelPlural(tenant?.type);

    return Scaffold(
      appBar: AppBar(
        title: groupsAsync.when(
          data: (groups) => Text('$label (${groups.length})'),
          loading: () => Text(label),
          error: (_, __) => Text(label),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        actions: [
          if (isConductor)
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () => showInstrumentCategoriesSheet(context),
              tooltip: 'Kategorien verwalten',
            ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: AppDimensions.paddingM),
              Text('Fehler: $error'),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: () => ref.invalidate(groupsProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.piano_outlined, size: 80, color: AppColors.medium),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text('Keine Instrumente', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Füge das erste Instrument hinzu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.medium),
                  ),
                ],
              ),
            );
          }

          final categories = categoriesAsync.valueOrNull ?? [];
          final playerCounts = playerCountsAsync.valueOrNull ?? {};

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(groupsProvider);
              ref.invalidate(groupCategoriesProvider);
              ref.invalidate(playerCountsForGroupsProvider);
              await ref.read(groupsProvider.future);
            },
            child: _GroupedInstrumentsList(
              groups: groups,
              categories: categories,
              playerCounts: playerCounts,
              isConductor: isConductor,
              onEdit: (group) => _showEditDialog(context, ref, group, categories, isConductor),
            ),
          );
        },
      ),
      floatingActionButton: isConductor
          ? FloatingActionButton(
              onPressed: () => _showEditDialog(context, ref, null, categoriesAsync.valueOrNull ?? [], isConductor),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// Grouped list of instruments by category
class _GroupedInstrumentsList extends StatelessWidget {
  const _GroupedInstrumentsList({
    required this.groups,
    required this.categories,
    required this.playerCounts,
    required this.isConductor,
    required this.onEdit,
  });

  final List<Group> groups;
  final List<GroupCategory> categories;
  final Map<int, int> playerCounts;
  final bool isConductor;
  final void Function(Group) onEdit;

  @override
  Widget build(BuildContext context) {
    // Separate maingroups
    final mainGroups = groups.where((g) => g.maingroup == true).toList();
    final regularGroups = groups.where((g) => g.maingroup != true).toList();

    // Group regular instruments by category
    final grouped = <int?, List<Group>>{};
    for (final group in regularGroups) {
      grouped.putIfAbsent(group.categoryId, () => []).add(group);
    }

    // Build category order: known categories first (by index), then uncategorized
    final orderedCategoryIds = categories.map((c) => c.id).toList();
    final categoryMap = {for (final c in categories) c.id: c};

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      children: [
        // Main groups section
        if (mainGroups.isNotEmpty) ...[
          _SectionHeader(title: 'Hauptgruppen', count: mainGroups.length),
          const SizedBox(height: AppDimensions.paddingS),
          ...mainGroups.map((group) => _GroupListItem(
                group: group,
                playerCount: playerCounts[group.id] ?? 0,
                onTap: isConductor ? () => onEdit(group) : null,
              )),
          const SizedBox(height: AppDimensions.paddingL),
        ],
        // Categorized instruments
        for (final catId in orderedCategoryIds)
          if (grouped.containsKey(catId)) ...[
            _SectionHeader(
              title: categoryMap[catId]?.name ?? 'Unbekannt',
              count: grouped[catId]!.length,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            ...grouped[catId]!.map((group) => _GroupListItem(
                  group: group,
                  playerCount: playerCounts[group.id] ?? 0,
                  onTap: isConductor ? () => onEdit(group) : null,
                )),
            const SizedBox(height: AppDimensions.paddingL),
          ],
        // Uncategorized instruments
        if (grouped.containsKey(null)) ...[
          _SectionHeader(
            title: categories.isEmpty ? 'Instrumente' : 'Ohne Kategorie',
            count: grouped[null]!.length,
          ),
          const SizedBox(height: AppDimensions.paddingS),
          ...grouped[null]!.map((group) => _GroupListItem(
                group: group,
                playerCount: playerCounts[group.id] ?? 0,
                onTap: isConductor ? () => onEdit(group) : null,
              )),
        ],
        // Instruments in categories that aren't in the ordered list
        for (final catId in grouped.keys)
          if (catId != null && !orderedCategoryIds.contains(catId)) ...[
            _SectionHeader(
              title: categoryMap[catId]?.name ?? 'Kategorie $catId',
              count: grouped[catId]!.length,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            ...grouped[catId]!.map((group) => _GroupListItem(
                  group: group,
                  playerCount: playerCounts[group.id] ?? 0,
                  onTap: isConductor ? () => onEdit(group) : null,
                )),
            const SizedBox(height: AppDimensions.paddingL),
          ],
      ],
    );
  }
}

/// Section header with title and count badge
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.medium,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: AppDimensions.paddingS),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.medium.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.medium,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

/// Individual instrument list item with player count badge
class _GroupListItem extends StatelessWidget {
  const _GroupListItem({
    required this.group,
    required this.playerCount,
    required this.onTap,
  });

  final Group group;
  final int playerCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = group.color != null
        ? Color(int.tryParse(group.color!.replaceFirst('#', '0xFF')) ?? 0xFF6366F1)
        : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: Icon(
            group.maingroup == true ? Icons.folder : Icons.music_note,
            color: color,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: _buildSubtitle(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PlayerCountBadge(count: playerCount),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.medium),
          ],
        ),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final parts = <String>[];
    if (group.shortName != null && group.shortName != group.name) {
      parts.add(group.shortName!);
    }
    if (group.tuning != null && group.tuning != 'C') {
      parts.add('in ${group.tuning}');
    }
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }
}

/// Player count badge — red when 0
class _PlayerCountBadge extends StatelessWidget {
  const _PlayerCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = count == 0 ? AppColors.danger : AppColors.medium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show dialog to edit/create an instrument
Future<void> _showEditDialog(
  BuildContext context,
  WidgetRef ref,
  Group? group,
  List<GroupCategory> categories,
  bool isConductor,
) async {
  if (!isConductor) return;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => _InstrumentEditDialog(
      group: group,
      categories: categories,
    ),
  );

  if (result != null && context.mounted) {
    try {
      final notifier = ref.read(groupNotifierProvider.notifier);

      if (result['_delete'] == true) {
        await notifier.deleteGroup(group!.id!);
        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Instrument gelöscht');
        }
      } else if (group != null) {
        await notifier.updateGroup(group.id!, result);
        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Instrument aktualisiert');
        }
      } else {
        await notifier.createGroup(result);
        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Instrument erstellt');
        }
      }
      // Refresh player counts after changes
      ref.invalidate(playerCountsForGroupsProvider);
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

/// Tuning options for instruments
const _tuningOptions = ['C', 'Es', 'B', 'F'];

/// Clef options
const _clefOptions = ['G', 'F', 'C'];

/// Dialog for editing/creating an instrument with all fields
class _InstrumentEditDialog extends StatefulWidget {
  const _InstrumentEditDialog({
    this.group,
    required this.categories,
  });

  final Group? group;
  final List<GroupCategory> categories;

  @override
  State<_InstrumentEditDialog> createState() => _InstrumentEditDialogState();
}

class _InstrumentEditDialogState extends State<_InstrumentEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _notesController;
  late final TextEditingController _rangeController;
  late final TextEditingController _synonymsController;
  final _formKey = GlobalKey<FormState>();

  int? _selectedCategoryId;
  String _selectedTuning = 'C';
  Set<String> _selectedClefs = {'G'};

  bool get isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _shortNameController = TextEditingController(text: group?.shortName ?? '');
    _notesController = TextEditingController(text: group?.notes ?? '');
    _rangeController = TextEditingController(text: group?.range ?? '');
    _synonymsController = TextEditingController(text: group?.synonyms ?? '');
    _selectedCategoryId = group?.categoryId;
    _selectedTuning = group?.tuning ?? 'C';
    _selectedClefs = (group?.clefs ?? ['g'])
        .map((c) => c.toUpperCase())
        .toSet();
    if (_selectedClefs.isEmpty) _selectedClefs = {'G'};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _notesController.dispose();
    _rangeController.dispose();
    _synonymsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Instrument bearbeiten' : 'Neues Instrument'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'z.B. Violine',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name ist erforderlich';
                    }
                    return null;
                  },
                  autofocus: !isEditing,
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Short name
                TextFormField(
                  controller: _shortNameController,
                  decoration: const InputDecoration(
                    labelText: 'Kurzname',
                    hintText: 'z.B. Vl.',
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Category dropdown
                if (widget.categories.isNotEmpty) ...[
                  DropdownButtonFormField<int?>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategorie',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Keine Kategorie'),
                      ),
                      ...widget.categories.map((cat) => DropdownMenuItem<int?>(
                            value: cat.id,
                            child: Text(cat.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                ],

                // Tuning dropdown
                DropdownButtonFormField<String>(
                  value: _selectedTuning,
                  decoration: const InputDecoration(
                    labelText: 'Stimmung',
                  ),
                  items: _tuningOptions.map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t),
                      )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTuning = value);
                    }
                  },
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Clefs multi-select (chips)
                Text(
                  'Notenschlüssel',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.medium,
                      ),
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Wrap(
                  spacing: AppDimensions.paddingS,
                  children: _clefOptions.map((clef) {
                    final isSelected = _selectedClefs.contains(clef);
                    return FilterChip(
                      label: Text('$clef-Schlüssel'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedClefs.add(clef);
                          } else if (_selectedClefs.length > 1) {
                            _selectedClefs.remove(clef);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Range (Tonumfang)
                TextFormField(
                  controller: _rangeController,
                  decoration: const InputDecoration(
                    labelText: 'Tonumfang',
                    hintText: 'z.B. g - e3',
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Synonyms
                TextFormField(
                  controller: _synonymsController,
                  decoration: const InputDecoration(
                    labelText: 'Synonyme',
                    hintText: 'z.B. Geige, Fidel',
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notizen',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () => _confirmDelete(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Löschen'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Speichern' : 'Erstellen'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final result = <String, dynamic>{
        'name': _nameController.text.trim(),
        'tuning': _selectedTuning,
        'clefs': _selectedClefs.map((c) => c.toLowerCase()).toList(),
      };

      final shortName = _shortNameController.text.trim();
      if (shortName.isNotEmpty) {
        result['shortName'] = shortName;
      } else {
        result['shortName'] = null;
      }

      // Category — send the value even if null to clear it
      result['category'] = _selectedCategoryId;

      final range = _rangeController.text.trim();
      result['range'] = range.isNotEmpty ? range : null;

      final synonyms = _synonymsController.text.trim();
      result['synonyms'] = synonyms.isNotEmpty ? synonyms : null;

      final notes = _notesController.text.trim();
      result['notes'] = notes.isNotEmpty ? notes : null;

      Navigator.of(context).pop(result);
    }
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Instrument löschen?'),
        content: Text('Möchtest du "${widget.group!.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop({'_delete': true});
    }
  }
}
