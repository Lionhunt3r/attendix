import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../constants/enums.dart';
import '../../data/models/attendance/attendance.dart';
import '../../data/models/person/person.dart';
import '../../data/models/song/song.dart';
import 'player_providers.dart';
import 'song_providers.dart';
import 'tenant_providers.dart';
import 'group_providers.dart';

/// Provider for realtime player changes subscription
///
/// Subscribes to the player table and invalidates the player list
/// when changes occur. Enriches players with group names.
final realtimePlayersProvider = StreamProvider.autoDispose<List<Person>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  final playerRepo = ref.watch(playerRepositoryWithTenantProvider);

  if (tenantId == null) {
    yield [];
    return;
  }

  // Get groups map for enrichment
  final groupsMap = await ref.watch(groupsMapProvider.future);

  // Helper function to enrich players with group names
  List<Person> enrichPlayers(List<Person> players) {
    return players.map((person) {
      final groupName = person.instrument != null
          ? groupsMap[person.instrument]
          : null;
      return person.copyWith(groupName: groupName);
    }).toList();
  }

  // Initial data
  final initialData = await playerRepo.getPlayers();
  yield enrichPlayers(initialData);

  // Create a stream controller to manage updates
  final controller = StreamController<List<Person>>();

  // Setup realtime channel
  final channel = supabase
      .channel('player_changes_$tenantId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'player',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'tenantId',
          value: tenantId,
        ),
        callback: (payload) async {
          // Fetch fresh data when changes occur
          try {
            final freshData = await playerRepo.getPlayers();
            if (!controller.isClosed) {
              controller.add(enrichPlayers(freshData));
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        },
      )
      .subscribe();

  // Cleanup on dispose
  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  // Yield updates from the controller
  await for (final data in controller.stream) {
    yield data;
  }
});

/// Provider for realtime attendance list with calculated percentages
///
/// Subscribes to the attendance table and refetches with person_attendances
/// to calculate percentages client-side. autoDispose ensures fresh data on remount.
final realtimeAttendanceListProvider = StreamProvider.autoDispose<List<Attendance>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant?.id == null) {
    yield [];
    return;
  }

  // Helper: fetch attendances with person_attendances and calculate percentages
  Future<List<Attendance>> fetchWithPercentages() async {
    final response = await supabase
        .from('attendance')
        .select('*, person_attendances(status)')
        .eq('tenantId', tenant!.id!)
        .order('date', ascending: false)
        .limit(50);

    return (response as List).map((e) {
      final attendance = Attendance.fromJson(e as Map<String, dynamic>);

      if (attendance.percentage == null || attendance.percentage == 0) {
        final personAttendances = e['person_attendances'] as List?;
        if (personAttendances != null && personAttendances.isNotEmpty) {
          final total = personAttendances.length;
          // BL-003: Use centralized countsAsPresent definition
          final present = personAttendances.where((pa) {
            final status = AttendanceStatus.fromValue(pa['status'] as int? ?? 0);
            return status.countsAsPresent;
          }).length;
          final calculatedPercentage = (present / total * 100).roundToDouble();
          return attendance.copyWith(percentage: calculatedPercentage);
        }
      }
      return attendance;
    }).toList();
  }

  // Initial data
  yield await fetchWithPercentages();

  // Create a stream controller to manage updates
  final controller = StreamController<List<Attendance>>();

  // Setup realtime channel
  final channel = supabase
      .channel('attendance_list_changes_${tenant!.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'attendance',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'tenantId',
          value: tenant.id,
        ),
        callback: (payload) async {
          try {
            final freshData = await fetchWithPercentages();
            if (!controller.isClosed) {
              controller.add(freshData);
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        },
      )
      .subscribe();

  // Cleanup on dispose
  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  // Yield updates from the controller
  await for (final data in controller.stream) {
    yield data;
  }
});

/// Provider for realtime song changes subscription
///
/// Subscribes to the songs table and invalidates the list
/// when changes occur
final realtimeSongsProvider = StreamProvider.autoDispose<List<Song>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  final songRepo = ref.watch(songRepositoryWithTenantProvider);

  if (tenantId == null) {
    yield [];
    return;
  }

  // Initial data
  final initialData = await songRepo.getSongs();
  yield initialData;

  // Create a stream controller
  final controller = StreamController<List<Song>>();

  // Setup realtime channel
  final channel = supabase
      .channel('song_changes_$tenantId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'songs',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'tenantId',
          value: tenantId,
        ),
        callback: (payload) async {
          try {
            final freshData = await songRepo.getSongs();
            if (!controller.isClosed) {
              controller.add(freshData);
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  await for (final data in controller.stream) {
    yield data;
  }
});

/// Provider for realtime pending player changes subscription
///
/// Subscribes to the player table filtered by pending=true and invalidates
/// when changes occur (new registrations)
final realtimePendingPlayersProvider = StreamProvider.autoDispose<List<Person>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  final playerRepo = ref.watch(playerRepositoryWithTenantProvider);

  if (tenantId == null) {
    yield [];
    return;
  }

  // Initial data
  final initialData = await playerRepo.getPendingPlayers();
  yield initialData;

  // Create a stream controller
  final controller = StreamController<List<Person>>();

  // Setup realtime channel — listen for all player changes (pending flag changes)
  final channel = supabase
      .channel('pending_player_changes_$tenantId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'player',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'tenantId',
          value: tenantId,
        ),
        callback: (payload) async {
          try {
            final freshData = await playerRepo.getPendingPlayers();
            if (!controller.isClosed) {
              controller.add(freshData);
            }
          } catch (e) {
            if (!controller.isClosed) {
              controller.addError(e);
            }
          }
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  await for (final data in controller.stream) {
    yield data;
  }
});

/// Manager class for handling multiple realtime subscriptions
///
/// Use this to manually manage subscriptions if needed
class RealtimeManager {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeManager(this._supabase);

  /// Subscribe to a table with a callback
  RealtimeChannel subscribe({
    required String channelName,
    required String table,
    PostgresChangeFilter? filter,
    required void Function(PostgresChangePayload) callback,
  }) {
    // Unsubscribe existing channel if any
    _channels[channelName]?.unsubscribe();

    final channel = _supabase.channel(channelName);

    if (filter != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: filter,
        callback: callback,
      );
    } else {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: callback,
      );
    }

    channel.subscribe();
    _channels[channelName] = channel;

    return channel;
  }

  /// Unsubscribe from a specific channel
  void unsubscribe(String channelName) {
    _channels[channelName]?.unsubscribe();
    _channels.remove(channelName);
  }

  /// Unsubscribe from all channels
  void unsubscribeAll() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }

  /// Get all active channel names
  List<String> get activeChannels => _channels.keys.toList();
}

/// Provider for RealtimeManager
final realtimeManagerProvider = Provider<RealtimeManager>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final manager = RealtimeManager(supabase);

  // Clean up on dispose
  ref.onDispose(() {
    manager.unsubscribeAll();
  });

  return manager;
});
