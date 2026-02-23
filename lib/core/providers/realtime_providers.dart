import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../../data/models/attendance/attendance.dart';
import '../../data/models/person/person.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/player_repository.dart';
import 'tenant_providers.dart';

/// Provider for realtime player changes subscription
///
/// Subscribes to the player table and invalidates the player list
/// when changes occur
final realtimePlayersProvider = StreamProvider.autoDispose<List<Person>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  final playerRepo = ref.watch(playerRepositoryProvider);

  if (tenantId == null) {
    yield [];
    return;
  }

  // Set tenant ID for repository
  playerRepo.setTenantId(tenantId);

  // Initial data
  final initialData = await playerRepo.getPlayers();
  yield initialData;

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

/// Provider for realtime attendance changes subscription
///
/// Subscribes to the attendance table and invalidates the list
/// when changes occur
final realtimeAttendancesProvider = StreamProvider.autoDispose<List<Attendance>>((ref) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  final attendanceRepo = ref.watch(attendanceRepositoryProvider);

  if (tenantId == null) {
    yield [];
    return;
  }

  // Set tenant ID for repository
  attendanceRepo.setTenantId(tenantId);

  // Initial data
  final initialData = await attendanceRepo.getAttendances();
  yield initialData;

  // Create a stream controller
  final controller = StreamController<List<Attendance>>();

  // Setup realtime channel
  final channel = supabase
      .channel('attendance_changes_$tenantId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'attendance',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'tenantId',
          value: tenantId,
        ),
        callback: (payload) async {
          try {
            final freshData = await attendanceRepo.getAttendances();
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

/// Provider for realtime person attendance changes for a specific attendance
///
/// Subscribes to person_attendances table filtered by attendance_id
final realtimeAttendanceDetailProvider = StreamProvider.autoDispose
    .family<Attendance?, int>((ref, attendanceId) async* {
  final supabase = ref.watch(supabaseClientProvider);
  final attendanceRepo = ref.watch(attendanceRepositoryProvider);
  final tenantId = ref.watch(currentTenantIdProvider);

  if (tenantId == null) {
    yield null;
    return;
  }

  attendanceRepo.setTenantId(tenantId);

  // Initial data
  final initialData = await attendanceRepo.getAttendanceById(attendanceId);
  yield initialData;

  // Create a stream controller
  final controller = StreamController<Attendance?>();

  // Setup realtime channel for person_attendances changes
  final channel = supabase
      .channel('person_attendance_changes_$attendanceId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'person_attendances',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'attendance_id',
          value: attendanceId,
        ),
        callback: (payload) async {
          try {
            final freshData = await attendanceRepo.getAttendanceById(attendanceId);
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
