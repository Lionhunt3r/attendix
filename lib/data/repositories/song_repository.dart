import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/song/song.dart';
import 'base_repository.dart';

/// Provider for SongRepository
final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository(ref);
});

/// Repository for song operations
class SongRepository extends BaseRepository with TenantAwareRepository {
  SongRepository(super.ref);

  /// Get all songs for the current tenant
  Future<List<Song>> getSongs() async {
    try {
      final response = await supabase
          .from('songs')
          .select('*')
          .eq('tenantId', currentTenantId)
          .order('number', nullsFirst: false)
          .order('name');

      return (response as List)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getSongs');
      rethrow;
    }
  }

  /// Get a single song by ID
  Future<Song?> getSongById(int id) async {
    try {
      final response = await supabase
          .from('songs')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Song.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'getSongById');
      rethrow;
    }
  }

  /// Create a new song
  Future<Song> createSong(Song song) async {
    try {
      final data = song.toJson();
      // Remove computed/read-only fields
      data.remove('id');
      data.remove('files');
      data.remove('created_at');
      data.remove('createdAt');
      data.remove('lastSung');

      // Set tenant ID
      data['tenantId'] = currentTenantId;

      final response = await supabase
          .from('songs')
          .insert(data)
          .select()
          .single();

      return Song.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'createSong');
      rethrow;
    }
  }

  /// Update an existing song
  Future<Song> updateSong(int id, Map<String, dynamic> updates) async {
    try {
      // Remove read-only fields
      updates.remove('id');
      updates.remove('created_at');
      updates.remove('createdAt');
      updates.remove('tenantId');
      updates.remove('files');
      updates.remove('lastSung');

      final response = await supabase
          .from('songs')
          .update(updates)
          .eq('id', id)
          .eq('tenantId', currentTenantId)
          .select()
          .single();

      return Song.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'updateSong');
      rethrow;
    }
  }

  /// Delete a song
  Future<void> deleteSong(int id) async {
    try {
      await supabase
          .from('songs')
          .delete()
          .eq('id', id)
          .eq('tenantId', currentTenantId);
    } catch (e, stack) {
      handleError(e, stack, 'deleteSong');
      rethrow;
    }
  }

  /// Search songs by name or number
  Future<List<Song>> searchSongs(String query) async {
    try {
      final response = await supabase
          .from('songs')
          .select('*')
          .eq('tenantId', currentTenantId)
          .or('name.ilike.%$query%,conductor.ilike.%$query%')
          .order('number', nullsFirst: false)
          .order('name')
          .limit(50);

      return (response as List)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'searchSongs');
      rethrow;
    }
  }

  /// Get song categories for the tenant
  Future<List<SongCategory>> getSongCategories() async {
    try {
      final response = await supabase
          .from('song_categories')
          .select('*')
          .eq('tenant_id', currentTenantId)
          .order('index');

      return (response as List)
          .map((e) => SongCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getSongCategories');
      rethrow;
    }
  }

  /// Get song history entries
  Future<List<SongHistory>> getSongHistory({int? songId, int? limit}) async {
    try {
      var baseQuery = supabase
          .from('song_history')
          .select('*, song:songs(*)')
          .eq('tenant_id', currentTenantId);

      if (songId != null) {
        baseQuery = baseQuery.eq('song_id', songId);
      }

      var query = baseQuery.order('date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((e) => SongHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getSongHistory');
      rethrow;
    }
  }

  /// Add a song history entry
  Future<SongHistory> addSongHistory({
    required int songId,
    required String date,
    String? conductorName,
    int? attendanceId,
  }) async {
    try {
      final response = await supabase
          .from('song_history')
          .insert({
            'tenant_id': currentTenantId,
            'song_id': songId,
            'date': date,
            'conductorName': conductorName,
            'attendance_id': attendanceId,
          })
          .select()
          .single();

      return SongHistory.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'addSongHistory');
      rethrow;
    }
  }
}
