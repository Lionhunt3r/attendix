import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/song/song.dart';
import '../../data/models/instrument/instrument.dart';
import '../../data/repositories/repositories.dart';
import 'group_providers.dart';
import 'tenant_providers.dart';

/// Initialized song repository with tenant context
final songRepositoryWithTenantProvider = Provider<SongRepository>((ref) {
  final repo = ref.watch(songRepositoryProvider);
  final tenant = ref.watch(currentTenantIdProvider);

  if (tenant != null) {
    repo.setTenantId(tenant);
  }

  return repo;
});

/// Provider for songs list
final songsProvider = FutureProvider<List<Song>>((ref) async {
  final repo = ref.watch(songRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return [];

  return repo.getSongs();
});

/// Provider for single song by ID
final songByIdProvider =
    FutureProvider.family<Song?, int>((ref, id) async {
  final repo = ref.watch(songRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return null;

  return repo.getSongById(id);
});

/// Provider for song categories
final songCategoriesProvider = FutureProvider<List<SongCategory>>((ref) async {
  final repo = ref.watch(songRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return [];

  return repo.getSongCategories();
});

/// Provider for song history
final songHistoryProvider =
    FutureProvider.family<List<SongHistory>, int?>((ref, songId) async {
  final repo = ref.watch(songRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return [];

  return repo.getSongHistory(songId: songId);
});

/// Notifier for song mutations (CRUD operations)
class SongNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  SongRepository get _repo => ref.read(songRepositoryWithTenantProvider);

  Future<Song?> createSong(Song song) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createSong(song);
      state = const AsyncValue.data(null);
      ref.invalidate(songsProvider);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<Song?> updateSong(int id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.updateSong(id, updates);
      state = const AsyncValue.data(null);
      ref.invalidate(songsProvider);
      ref.invalidate(songByIdProvider(id));
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> deleteSong(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteSong(id);
      state = const AsyncValue.data(null);
      ref.invalidate(songsProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<SongHistory?> addSongHistory({
    required int songId,
    required String date,
    String? conductorName,
    int? attendanceId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.addSongHistory(
        songId: songId,
        date: date,
        conductorName: conductorName,
        attendanceId: attendanceId,
      );
      state = const AsyncValue.data(null);
      ref.invalidate(songHistoryProvider(songId));
      ref.invalidate(songHistoryProvider(null));
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }
}

final songNotifierProvider =
    NotifierProvider<SongNotifier, AsyncValue<void>>(() {
  return SongNotifier();
});

/// Notifier for song category mutations (CRUD operations)
class SongCategoryNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  SongRepository get _repo => ref.read(songRepositoryWithTenantProvider);

  /// Add a new song category
  Future<SongCategory?> add(String name) async {
    state = const AsyncValue.loading();
    try {
      final categories = await _repo.getSongCategories();
      final result = await _repo.addSongCategory(
        name: name,
        index: categories.length,
      );
      state = const AsyncValue.data(null);
      ref.invalidate(songCategoriesProvider);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Update a song category name
  Future<bool> update(String id, String name) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateSongCategory(id, {'name': name});
      state = const AsyncValue.data(null);
      ref.invalidate(songCategoriesProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Delete a song category
  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteSongCategory(id);
      state = const AsyncValue.data(null);
      ref.invalidate(songCategoriesProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Reorder categories
  Future<bool> reorder(List<SongCategory> categories) async {
    state = const AsyncValue.loading();
    try {
      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        if (category.id != null) {
          await _repo.updateSongCategory(category.id!, {'index': i});
        }
      }
      state = const AsyncValue.data(null);
      ref.invalidate(songCategoriesProvider);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final songCategoryNotifierProvider =
    NotifierProvider<SongCategoryNotifier, AsyncValue<void>>(() {
  return SongCategoryNotifier();
});

/// Provider for current songs (all upcoming events from today onwards)
final currentSongsProvider = FutureProvider<
    List<({String date, List<SongHistory> history})>>((ref) async {
  final repo = ref.watch(songRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return [];

  return repo.getCurrentSongs();
});

/// Provider for groups that have at least one song file
/// Used for the group files directory feature
final groupsWithFilesProvider = Provider<List<Group>>((ref) {
  final songs = ref.watch(songsProvider).valueOrNull ?? [];
  final groups = ref.watch(groupsProvider).valueOrNull ?? [];

  // Collect all instrument IDs that have files (instrumentId > 2 means it's a specific group)
  final groupIdsWithFiles = <int>{};
  for (final song in songs) {
    for (final file in song.files ?? []) {
      if (file.instrumentId != null && file.instrumentId! > 2) {
        groupIdsWithFiles.add(file.instrumentId!);
      }
    }
  }

  return groups
      .where((g) => g.id != null && groupIdsWithFiles.contains(g.id))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
});

/// Provider for files filtered by a specific group/instrument
final filesForGroupProvider =
    Provider.family<List<({Song song, SongFile file})>, int>((ref, groupId) {
  final songs = ref.watch(songsProvider).valueOrNull ?? [];

  final result = <({Song song, SongFile file})>[];
  for (final song in songs) {
    for (final file in song.files ?? []) {
      if (file.instrumentId == groupId) {
        result.add((song: song, file: file));
      }
    }
  }

  // Sort by song number then name
  result.sort((a, b) {
    final numA = a.song.number ?? 9999;
    final numB = b.song.number ?? 9999;
    if (numA != numB) return numA.compareTo(numB);
    return a.song.name.compareTo(b.song.name);
  });

  return result;
});
