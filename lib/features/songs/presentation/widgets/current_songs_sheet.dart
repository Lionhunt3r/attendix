import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/song_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/song/song.dart';

/// Bottom sheet showing songs planned for the next 14 days
class CurrentSongsSheet extends ConsumerWidget {
  const CurrentSongsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSongsAsync = ref.watch(currentSongsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
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
                    const Icon(Icons.calendar_month, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktuelle Werke',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Nächste 14 Tage',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.medium,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(currentSongsProvider),
                      tooltip: 'Aktualisieren',
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
                child: currentSongsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.danger),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text('Fehler: $error'),
                        const SizedBox(height: AppDimensions.paddingM),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(currentSongsProvider),
                          child: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                  data: (groupedSongs) {
                    if (groupedSongs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_busy,
                              size: 64,
                              color: AppColors.medium,
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                            Text(
                              'Keine geplanten Werke',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppDimensions.paddingS),
                            const Text(
                              'In den nächsten 14 Tagen sind\nkeine Auftritte geplant',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.medium),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: groupedSongs.length,
                      itemBuilder: (context, index) {
                        final group = groupedSongs[index];
                        return _DateGroup(
                          date: group.date,
                          songs: group.history,
                          onSongTap: (songId) {
                            Navigator.of(context).pop();
                            context.push('/settings/songs/$songId');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<SongHistory> songs;
  final void Function(int songId) onSongTap;

  const _DateGroup({
    required this.date,
    required this.songs,
    required this.onSongTap,
  });

  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);

      if (dateOnly == today) {
        return 'Heute';
      } else if (dateOnly == tomorrow) {
        return 'Morgen';
      } else {
        return DateFormat('EEEE, d. MMMM', 'de_DE').format(parsed);
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            children: [
              const Icon(Icons.event, size: 16, color: AppColors.primary),
              const SizedBox(width: AppDimensions.paddingXS),
              Text(
                _formatDate(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
        ),
        ...songs.map((history) {
          final song = history.song;
          if (song == null) return const SizedBox.shrink();

          return Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
            child: ListTile(
              onTap: song.id != null ? () => onSongTap(song.id!) : null,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusS),
                ),
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              title: Text(
                song.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: song.conductor != null
                  ? Text(
                      song.conductor!,
                      style: const TextStyle(fontSize: 12),
                    )
                  : null,
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.medium,
              ),
            ),
          );
        }),
        const SizedBox(height: AppDimensions.paddingS),
      ],
    );
  }
}

/// Shows the current songs sheet
Future<void> showCurrentSongsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CurrentSongsSheet(),
  );
}
