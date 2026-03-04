import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import '../../data/models/history/history_entry.dart';
import '../../data/models/song/song.dart';
import 'tenant_providers.dart';

/// Provider for performance history (song performances/Aufführungen)
final performanceHistoryProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('history')
      .select('*, song:songs(name, number)')
      .eq('tenantId', tenant.id!)
      .order('date', ascending: false)
      .limit(200);

  return (response as List).map((e) {
    final songData = e['song'] as Map<String, dynamic>?;
    return HistoryEntry(
      id: e['id'] as int?,
      songId: e['song_id'] as int,
      songName: songData?['name'] as String?,
      songNumber: songData?['number']?.toString(),
      personId: e['person_id'] as int?,
      conductorName: e['conductorName'] as String?,
      otherConductor: e['otherConductor'] as String?,
      date: e['date'] as String? ?? DateTime.now().toIso8601String(),
      attendanceId: e['attendance_id'] as int?,
      count: e['count'] as int? ?? 1,
    );
  }).toList();
});

/// Provider for songs (for history page add dialog)
final planSongsProviderHistory = FutureProvider<List<Song>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('songs')
      .select('*')
      .eq('tenantId', tenant.id!)
      .order('number')
      .order('name');

  return (response as List).map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
});
