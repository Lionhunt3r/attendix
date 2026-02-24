import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/song/song.dart';
import '../../data/repositories/repositories.dart';
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
