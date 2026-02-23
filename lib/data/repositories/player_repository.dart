import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../models/person/person.dart';
import 'base_repository.dart';

/// Provider for PlayerRepository
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  return PlayerRepository(ref);
});

/// Repository for player/person operations
class PlayerRepository extends BaseRepository with TenantAwareRepository {
  PlayerRepository(super.ref);

  /// Get all active players for the current tenant
  Future<List<Person>> getPlayers({
    bool includeAttendances = false,
    bool all = false,
  }) async {
    try {
      var query = supabase
          .from('player')
          .select(includeAttendances ? '*, person_attendances(*)' : '*')
          .eq('tenantId', currentTenantId)
          .isFilter('pending', false);

      if (!all) {
        query = query.isFilter('left', null);
      }

      final response = await query
          .order('instrument')
          .order('isLeader', ascending: false)
          .order('lastName');

      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getPlayers');
      rethrow;
    }
  }

  /// Get a single player by ID
  Future<Person?> getPlayerById(int id) async {
    try {
      final response = await supabase
          .from('player')
          .select('*')
          .eq('id', id)
          .eq('tenantId', currentTenantId)
          .maybeSingle();

      if (response == null) return null;
      return Person.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'getPlayerById');
      rethrow;
    }
  }

  /// Get player by app ID (user ID)
  Future<Person?> getPlayerByAppId(String appId) async {
    try {
      final response = await supabase
          .from('player')
          .select('*')
          .eq('appId', appId)
          .eq('tenantId', currentTenantId)
          .maybeSingle();

      if (response == null) return null;
      return Person.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'getPlayerByAppId');
      rethrow;
    }
  }

  /// Get pending (not yet approved) players
  Future<List<Person>> getPendingPlayers() async {
    try {
      final response = await supabase
          .from('player')
          .select('*')
          .eq('tenantId', currentTenantId)
          .eq('pending', true)
          .order('created_at');

      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getPendingPlayers');
      rethrow;
    }
  }

  /// Get archived (left) players
  Future<List<Person>> getArchivedPlayers() async {
    try {
      final response = await supabase
          .from('player')
          .select('*')
          .eq('tenantId', currentTenantId)
          .isFilter('pending', false)
          .not('left', 'is', null)
          .order('left', ascending: false);

      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getArchivedPlayers');
      rethrow;
    }
  }

  /// Get conductors (main group members)
  Future<List<Person>> getConductors(int mainGroupId, {bool includeLeft = false}) async {
    try {
      var query = supabase
          .from('player')
          .select('*')
          .eq('tenantId', currentTenantId)
          .eq('instrument', mainGroupId)
          .isFilter('pending', false);

      if (!includeLeft) {
        query = query.isFilter('left', null);
      }

      final response = await query.order('lastName');

      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getConductors');
      rethrow;
    }
  }

  /// Get players by parent ID (for parent role)
  Future<List<Person>> getPlayersByParentId(int parentId) async {
    try {
      final response = await supabase
          .from('player')
          .select('*, person_attendances(*)')
          .eq('tenantId', currentTenantId)
          .eq('parent_id', parentId)
          .isFilter('pending', false)
          .isFilter('left', null)
          .order('instrument')
          .order('isLeader', ascending: false)
          .order('lastName');

      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getPlayersByParentId');
      rethrow;
    }
  }

  /// Create a new player
  Future<Person> createPlayer(Person player) async {
    try {
      final data = player.toJson();
      // Remove computed fields
      data.remove('groupName');
      data.remove('firstOfInstrument');
      data.remove('instrumentLength');
      data.remove('teacherName');
      data.remove('criticalReasonText');
      data.remove('person_attendances');
      data.remove('percentage');
      
      // Set tenant ID
      data['tenantId'] = currentTenantId;

      final response = await supabase
          .from('player')
          .insert(data)
          .select()
          .single();

      return Person.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'createPlayer');
      rethrow;
    }
  }

  /// Update an existing player
  Future<Person> updatePlayer(Person player) async {
    if (player.id == null) {
      throw RepositoryException(
        message: 'Player ID is required for update',
        operation: 'updatePlayer',
      );
    }

    try {
      final data = player.toJson();
      // Remove read-only and computed fields
      data.remove('id');
      data.remove('created_at');
      data.remove('createdAt');
      data.remove('groupName');
      data.remove('firstOfInstrument');
      data.remove('instrumentLength');
      data.remove('teacherName');
      data.remove('criticalReasonText');
      data.remove('isPresent');
      data.remove('text');
      data.remove('attStatus');
      data.remove('person_attendances');
      data.remove('percentage');

      final response = await supabase
          .from('player')
          .update(data)
          .eq('id', player.id!)
          .select()
          .single();

      return Person.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'updatePlayer');
      rethrow;
    }
  }

  /// Archive a player (soft delete)
  Future<void> archivePlayer(Person player, String leftDate, String? reason) async {
    if (player.id == null) {
      throw RepositoryException(
        message: 'Player ID is required for archive',
        operation: 'archivePlayer',
      );
    }

    try {
      // Add history entry
      final history = List<Map<String, dynamic>>.from(
        player.history.map((e) => e.toJson()),
      );
      history.add({
        'date': DateTime.now().toIso8601String(),
        'text': reason ?? 'Kein Grund angegeben',
        'type': PlayerHistoryType.archived.value,
      });

      await supabase
          .from('player')
          .update({
            'left': leftDate,
            'history': history,
            'appId': null,
          })
          .eq('id', player.id!);
    } catch (e, stack) {
      handleError(e, stack, 'archivePlayer');
      rethrow;
    }
  }

  /// Reactivate an archived player
  Future<void> reactivatePlayer(Person player) async {
    if (player.id == null) {
      throw RepositoryException(
        message: 'Player ID is required for reactivate',
        operation: 'reactivatePlayer',
      );
    }

    try {
      // Add history entry
      final history = List<Map<String, dynamic>>.from(
        player.history.map((e) => e.toJson()),
      );
      history.add({
        'date': DateTime.now().toIso8601String(),
        'text': 'Person wurde reaktiviert',
        'type': PlayerHistoryType.returned.value,
      });

      await supabase
          .from('player')
          .update({
            'left': null,
            'history': history,
          })
          .eq('id', player.id!);
    } catch (e, stack) {
      handleError(e, stack, 'reactivatePlayer');
      rethrow;
    }
  }

  /// Delete a player permanently
  Future<void> deletePlayer(int playerId) async {
    try {
      await supabase
          .from('player')
          .delete()
          .eq('id', playerId);
    } catch (e, stack) {
      handleError(e, stack, 'deletePlayer');
      rethrow;
    }
  }

  /// Pause a player
  Future<void> pausePlayer(Person player, String? pausedUntil, String reason) async {
    if (player.id == null) {
      throw RepositoryException(
        message: 'Player ID is required for pause',
        operation: 'pausePlayer',
      );
    }

    try {
      // Add history entry
      final history = List<Map<String, dynamic>>.from(
        player.history.map((e) => e.toJson()),
      );
      history.add({
        'date': DateTime.now().toIso8601String(),
        'text': reason,
        'type': PlayerHistoryType.paused.value,
      });

      await supabase
          .from('player')
          .update({
            'paused': true,
            'paused_until': pausedUntil,
            'history': history,
          })
          .eq('id', player.id!);

      // Remove from upcoming attendances
      await removeFromUpcomingAttendances(player.id!);
    } catch (e, stack) {
      handleError(e, stack, 'pausePlayer');
      rethrow;
    }
  }

  /// Unpause a player
  Future<void> unpausePlayer(Person player) async {
    if (player.id == null) {
      throw RepositoryException(
        message: 'Player ID is required for unpause',
        operation: 'unpausePlayer',
      );
    }

    try {
      // Add history entry
      final history = List<Map<String, dynamic>>.from(
        player.history.map((e) => e.toJson()),
      );
      history.add({
        'date': DateTime.now().toIso8601String(),
        'text': 'Pause beendet',
        'type': PlayerHistoryType.unpaused.value,
      });

      await supabase
          .from('player')
          .update({
            'paused': false,
            'paused_until': null,
            'history': history,
          })
          .eq('id', player.id!);

      // Add to upcoming attendances
      await addToUpcomingAttendances(player);
    } catch (e, stack) {
      handleError(e, stack, 'unpausePlayer');
      rethrow;
    }
  }

  /// Remove player from all upcoming (future) attendances
  Future<void> removeFromUpcomingAttendances(int playerId) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Get upcoming attendance IDs for this tenant
      final upcomingAttendances = await supabase
          .from('attendance')
          .select('id')
          .eq('tenantId', currentTenantId)
          .gte('date', today);

      final attendanceIds = (upcomingAttendances as List)
          .map((a) => a['id']) // Can be int or String (UUID)
          .toList();

      if (attendanceIds.isEmpty) return;

      // Delete person_attendances for these attendances
      await supabase
          .from('person_attendances')
          .delete()
          .eq('person_id', playerId)
          .inFilter('attendance_id', attendanceIds);
    } catch (e, stack) {
      handleError(e, stack, 'removeFromUpcomingAttendances');
      // Don't rethrow - this is a secondary operation
    }
  }

  /// Add player to all upcoming attendances (based on relevant groups)
  Future<void> addToUpcomingAttendances(Person player) async {
    if (player.id == null) return;

    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Get upcoming attendances for this tenant
      final upcomingAttendances = await supabase
          .from('attendance')
          .select('id, type_id')
          .eq('tenantId', currentTenantId)
          .gte('date', today);

      if ((upcomingAttendances as List).isEmpty) return;

      // Get attendance types to check relevant_groups and default_status
      final types = await supabase
          .from('attendance_types')
          .select('id, relevant_groups, default_status')
          .eq('tenant_id', currentTenantId);

      final typeMap = <dynamic, Map<String, dynamic>>{};
      for (final t in types as List) {
        final id = t['id']; // Can be int or String
        final groups = t['relevant_groups'];
        final defaultStatusRaw = t['default_status'];

        // Convert String name to Integer value (DB stores "present", "neutral", etc.)
        int defaultStatusInt;
        if (defaultStatusRaw is int) {
          defaultStatusInt = defaultStatusRaw;
        } else if (defaultStatusRaw is String) {
          defaultStatusInt = AttendanceStatus.values
              .firstWhere(
                (s) => s.name == defaultStatusRaw,
                orElse: () => AttendanceStatus.neutral,
              )
              .value;
        } else {
          defaultStatusInt = AttendanceStatus.neutral.value;
        }

        typeMap[id] = {
          'relevant_groups': groups is List ? groups : [],
          'default_status': defaultStatusInt,
        };
      }

      for (final attendance in upcomingAttendances) {
        final attendanceId = attendance['id']; // Can be int or String (UUID)
        final typeId = attendance['type_id'];
        final typeData = typeId != null ? typeMap[typeId] : null;
        final relevantGroups = (typeData?['relevant_groups'] as List?) ?? [];
        final defaultStatus = typeData?['default_status'] ?? 0;

        // Check if player's instrument is in relevant groups (or all groups allowed)
        final isRelevant = relevantGroups.isEmpty ||
            relevantGroups.contains(player.instrument);

        if (isRelevant) {
          // Check if entry already exists
          final existing = await supabase
              .from('person_attendances')
              .select('id')
              .eq('attendance_id', attendanceId)
              .eq('person_id', player.id!)
              .maybeSingle();

          if (existing == null) {
            await supabase.from('person_attendances').insert({
              'attendance_id': attendanceId,
              'person_id': player.id,
              'status': defaultStatus, // Use default status from attendance type
            });
          }
        }
      }
    } catch (e, stack) {
      handleError(e, stack, 'addToUpcomingAttendances');
      rethrow; // Rethrow to see error in UI
    }
  }

  /// Check for players whose pause period has ended and unpause them
  Future<void> checkAndUnpausePlayers() async {
    // Skip if tenant is not set yet
    if (!hasTenantId) return;

    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Get players where paused_until has passed
      final pausedPlayers = await supabase
          .from('player')
          .select('*')
          .eq('tenantId', currentTenantId)
          .eq('paused', true)
          .not('paused_until', 'is', null)
          .lte('paused_until', today);

      for (final playerData in pausedPlayers as List) {
        final player = Person.fromJson(playerData as Map<String, dynamic>);

        // Add history entry
        final history = List<Map<String, dynamic>>.from(
          player.history.map((e) => e.toJson()),
        );
        history.add({
          'date': DateTime.now().toIso8601String(),
          'text': 'Automatisch reaktiviert (Pausenzeit abgelaufen)',
          'type': PlayerHistoryType.unpaused.value,
        });

        // Update player
        await supabase.from('player').update({
          'paused': false,
          'paused_until': null,
          'history': history,
        }).eq('id', player.id!);

        // Add to upcoming attendances
        await addToUpcomingAttendances(player);
      }
    } catch (e, stack) {
      handleError(e, stack, 'checkAndUnpausePlayers');
      // Don't rethrow - this runs in the background
    }
  }

  /// Approve a pending player
  Future<void> approvePlayer(int playerId) async {
    try {
      await supabase
          .from('player')
          .update({'pending': false})
          .eq('id', playerId);
    } catch (e, stack) {
      handleError(e, stack, 'approvePlayer');
      rethrow;
    }
  }

  /// Update player's instrument
  Future<void> updatePlayerInstrument(
    Person player,
    int newInstrumentId,
    String? reason,
  ) async {
    if (player.id == null) {
      throw RepositoryException(
        message: 'Player ID is required',
        operation: 'updatePlayerInstrument',
      );
    }

    try {
      // Add history entry
      final history = List<Map<String, dynamic>>.from(
        player.history.map((e) => e.toJson()),
      );
      history.add({
        'date': DateTime.now().toIso8601String(),
        'text': reason ?? 'Instrument gewechselt',
        'type': PlayerHistoryType.instrumentChange.value,
      });

      await supabase
          .from('player')
          .update({
            'instrument': newInstrumentId,
            'history': history,
          })
          .eq('id', player.id!);
    } catch (e, stack) {
      handleError(e, stack, 'updatePlayerInstrument');
      rethrow;
    }
  }

  /// Search players by name
  Future<List<Person>> searchPlayers(String query) async {
    try {
      final response = await supabase
          .from('player')
          .select('*')
          .eq('tenantId', currentTenantId)
          .isFilter('pending', false)
          .isFilter('left', null)
          .or('firstName.ilike.%$query%,lastName.ilike.%$query%')
          .order('lastName')
          .limit(20);

      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'searchPlayers');
      rethrow;
    }
  }

  /// Get player count by instrument
  Future<Map<int, int>> getPlayerCountByInstrument() async {
    try {
      final response = await supabase
          .from('player')
          .select('instrument')
          .eq('tenantId', currentTenantId)
          .isFilter('pending', false)
          .isFilter('left', null);

      final counts = <int, int>{};
      for (final row in response as List) {
        final instrument = row['instrument'] as int?;
        if (instrument != null) {
          counts[instrument] = (counts[instrument] ?? 0) + 1;
        }
      }
      return counts;
    } catch (e, stack) {
      handleError(e, stack, 'getPlayerCountByInstrument');
      rethrow;
    }
  }

  /// Get critical players
  Future<List<Person>> getCriticalPlayers() async {
    try {
      final response = await supabase
          .from('player')
          .select('*')
          .eq('tenantId', currentTenantId)
          .eq('isCritical', true)
          .isFilter('pending', false)
          .isFilter('left', null)
          .order('lastName');

      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getCriticalPlayers');
      rethrow;
    }
  }
}
