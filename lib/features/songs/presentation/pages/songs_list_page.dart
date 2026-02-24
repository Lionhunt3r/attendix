import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/song_providers.dart';
import '../../../../core/providers/song_filter_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/song/song.dart';
import '../../../../data/models/song/song_filter.dart';
import '../widgets/song_filter_sheet.dart';

/// Songs list page with filter and sort support
class SongsListPage extends ConsumerStatefulWidget {
  const SongsListPage({super.key});

  @override
  ConsumerState<SongsListPage> createState() => _SongsListPageState();
}

class _SongsListPageState extends ConsumerState<SongsListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize search controller with current search query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(songSearchQueryProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);
    final filteredSongs = ref.watch(filteredSongsProvider);
    final filter = ref.watch(songFilterProvider);
    final searchQuery = ref.watch(songSearchQueryProvider);
    final categoriesAsync = ref.watch(songCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        actions: [
          // Filter button with indicator
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color:
                      filter.hasActiveFilters ? AppColors.primary : null,
                ),
                onPressed: () => showSongFilterSheet(context),
                tooltip: 'Filter & Sortierung',
              ),
              if (filter.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${filter.activeFilterCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(songSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(songSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Category chips (horizontal scroll)
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Alle'),
                        selected: filter.category == null,
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                .read(songFilterProvider.notifier)
                                .setCategory(null);
                          }
                        },
                      ),
                    ),
                    ...categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c.name),
                            selected: filter.category == c.name,
                            onSelected: (selected) {
                              ref
                                  .read(songFilterProvider.notifier)
                                  .setCategory(selected ? c.name : null);
                            },
                          ),
                        )),
                  ],
                ),
              );
            },
          ),

          // Active filter chips
          if (filter.hasActiveFilters && filter.category == null)
            _ActiveFilterChips(filter: filter),

          // Sort indicator
          if (filter.sortOption != SongSortOption.numberAsc)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingXS,
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 16, color: AppColors.medium),
                  const SizedBox(width: 4),
                  Text(
                    filter.sortOption.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.medium,
                    ),
                  ),
                ],
              ),
            ),

          // Songs list
          Expanded(
            child: songsAsync.when(
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
                      onPressed: () => ref.invalidate(songsProvider),
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
              data: (songs) {
                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.music_note_outlined,
                          size: 80,
                          color: AppColors.medium,
                        ),
                        const SizedBox(height: AppDimensions.paddingL),
                        Text(
                          'Keine Lieder',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        Text(
                          'Füge das erste Lied hinzu',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.medium,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredSongs.isEmpty) {
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
                          searchQuery.isNotEmpty
                              ? 'Keine Ergebnisse für "$searchQuery"'
                              : 'Keine Lieder mit diesen Filtern',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        if (filter.hasActiveFilters)
                          TextButton.icon(
                            onPressed: () {
                              ref.read(songFilterProvider.notifier).reset();
                            },
                            icon: const Icon(Icons.filter_list_off),
                            label: const Text('Filter zurücksetzen'),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(songsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                    ),
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      return _SongListItem(
                        song: song,
                        onTap: () => context.push('/settings/songs/${song.id}'),
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
        onPressed: () => context.push('/settings/songs/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Active filter chips row (removable)
class _ActiveFilterChips extends ConsumerWidget {
  final SongFilter filter;

  const _ActiveFilterChips({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (filter.withChoir)
            Chip(
              label: const Text('Chor & Orchester'),
              onDeleted: () {
                ref.read(songFilterProvider.notifier).setWithChoir(false);
              },
              visualDensity: VisualDensity.compact,
            ),
          if (filter.withSolo)
            Chip(
              label: const Text('Mit Solo'),
              onDeleted: () {
                ref.read(songFilterProvider.notifier).setWithSolo(false);
              },
              visualDensity: VisualDensity.compact,
            ),
          if (filter.difficulty != null)
            Chip(
              label: Text('Schwierigkeit: ${filter.difficulty}'),
              onDeleted: () {
                ref.read(songFilterProvider.notifier).clearDifficulty();
              },
              visualDensity: VisualDensity.compact,
            ),
          if (filter.instrumentIds.isNotEmpty)
            Chip(
              label: Text('${filter.instrumentIds.length} Instrumente'),
              onDeleted: () {
                ref.read(songFilterProvider.notifier).clearInstruments();
              },
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _SongListItem extends StatelessWidget {
  const _SongListItem({
    required this.song,
    required this.onTap,
  });

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: Center(
            child: song.fullNumber.isNotEmpty
                ? Text(
                    song.fullNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.music_note,
                    color: AppColors.primary,
                  ),
          ),
        ),
        title: Text(
          song.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (song.conductor != null)
              Text(
                song.conductor!,
                style: const TextStyle(fontSize: 13),
              ),
            Row(
              children: [
                if (song.withChoir)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text('Chor'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (song.withSolo)
                  const Chip(
                    label: Text('Solo'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: song.lastSung != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Zuletzt',
                    style: TextStyle(fontSize: 11, color: AppColors.medium),
                  ),
                  Text(
                    song.lastSung!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              )
            : const Icon(
                Icons.chevron_right,
                color: AppColors.medium,
              ),
      ),
    );
  }
}
