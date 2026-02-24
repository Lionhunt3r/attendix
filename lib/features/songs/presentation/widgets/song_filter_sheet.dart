import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/providers/song_providers.dart';
import '../../../../core/providers/song_filter_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/song/song_filter.dart';

/// Bottom sheet for filtering and sorting songs
class SongFilterSheet extends ConsumerWidget {
  const SongFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(songFilterProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final categoriesAsync = ref.watch(songCategoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.borderRadiusL),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.medium.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Text(
                        'Filter & Sortierung',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (filter.hasActiveFilters)
                      TextButton(
                        onPressed: () {
                          ref.read(songFilterProvider.notifier).reset();
                        },
                        child: const Text('Zurücksetzen'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  children: [
                    // Sort dropdown
                    _SectionHeader(title: 'Sortierung'),
                    const SizedBox(height: AppDimensions.paddingS),
                    DropdownButtonFormField<SongSortOption>(
                      value: filter.sortOption,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.sort),
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: SongSortOption.values
                          .map((option) => DropdownMenuItem(
                                value: option,
                                child: Text(option.label),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(songFilterProvider.notifier)
                              .setSortOption(value);
                        }
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Difficulty filter
                    _SectionHeader(title: 'Schwierigkeit'),
                    const SizedBox(height: AppDimensions.paddingS),
                    DropdownButtonFormField<int?>(
                      value: filter.difficulty,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.speed),
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Alle')),
                        DropdownMenuItem(value: 1, child: Text('1 - Leicht')),
                        DropdownMenuItem(value: 2, child: Text('2 - Mittel')),
                        DropdownMenuItem(value: 3, child: Text('3 - Schwer')),
                      ],
                      onChanged: (value) {
                        ref
                            .read(songFilterProvider.notifier)
                            .setDifficulty(value);
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Category filter
                    categoriesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (categories) {
                        if (categories.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(title: 'Kategorie'),
                            const SizedBox(height: AppDimensions.paddingS),
                            DropdownButtonFormField<String?>(
                              value: filter.category,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.category),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Alle')),
                                ...categories.map((c) => DropdownMenuItem(
                                      value: c.name,
                                      child: Text(c.name),
                                    )),
                              ],
                              onChanged: (value) {
                                ref
                                    .read(songFilterProvider.notifier)
                                    .setCategory(value);
                              },
                            ),
                            const SizedBox(height: AppDimensions.paddingL),
                          ],
                        );
                      },
                    ),

                    // Toggle filters
                    _SectionHeader(title: 'Eigenschaften'),
                    const SizedBox(height: AppDimensions.paddingS),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Chor & Orchester'),
                            subtitle: const Text('Nur Stücke mit Chor'),
                            secondary: const Icon(Icons.groups),
                            value: filter.withChoir,
                            onChanged: (value) {
                              ref
                                  .read(songFilterProvider.notifier)
                                  .setWithChoir(value);
                            },
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Mit Solo'),
                            subtitle: const Text('Nur Stücke mit Solo-Part'),
                            secondary: const Icon(Icons.mic),
                            value: filter.withSolo,
                            onChanged: (value) {
                              ref
                                  .read(songFilterProvider.notifier)
                                  .setWithSolo(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Instruments multi-select
                    groupsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (groups) {
                        if (groups.isEmpty) return const SizedBox.shrink();
                        // All groups are valid instruments for filtering
                        final instruments = groups;
                        if (instruments.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              title:
                                  'Instrumente (${filter.instrumentIds.length})',
                            ),
                            const SizedBox(height: AppDimensions.paddingS),
                            Card(
                              margin: EdgeInsets.zero,
                              child: ExpansionTile(
                                title: Text(
                                  filter.instrumentIds.isEmpty
                                      ? 'Alle Instrumente'
                                      : '${filter.instrumentIds.length} ausgewählt',
                                ),
                                leading: const Icon(Icons.music_note_outlined),
                                children: [
                                  if (filter.instrumentIds.isNotEmpty)
                                    ListTile(
                                      title: const Text('Alle abwählen'),
                                      leading: const Icon(Icons.clear_all),
                                      onTap: () {
                                        ref
                                            .read(songFilterProvider.notifier)
                                            .clearInstruments();
                                      },
                                    ),
                                  ...instruments.map((g) => CheckboxListTile(
                                        title: Text(g.name),
                                        value: filter.instrumentIds
                                            .contains(g.id),
                                        onChanged: (selected) {
                                          if (g.id != null) {
                                            ref
                                                .read(songFilterProvider
                                                    .notifier)
                                                .toggleInstrumentId(g.id!);
                                          }
                                        },
                                      )),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppDimensions.paddingL),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.medium,
          ),
    );
  }
}

/// Shows the song filter sheet as a bottom sheet
Future<void> showSongFilterSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SongFilterSheet(),
  );
}
