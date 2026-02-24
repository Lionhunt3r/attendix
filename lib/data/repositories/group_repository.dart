import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/instrument/instrument.dart';
import 'base_repository.dart';

/// Provider for GroupRepository
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref);
});

/// Repository for groups/instruments operations
class GroupRepository extends BaseRepository with TenantAwareRepository {
  GroupRepository(super.ref);

  /// Get all groups/instruments for the current tenant
  Future<List<Group>> getGroups() async {
    try {
      final response = await supabase
          .from('instruments')
          .select('*, categoryData:category(*)')
          .eq('tenantId', currentTenantId)
          .order('category')
          .order('name');

      return (response as List)
          .map((e) => Group.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getGroups');
      rethrow;
    }
  }

  /// Get groups as a map (id -> name)
  Future<Map<int, String>> getGroupsMap() async {
    try {
      final response = await supabase
          .from('instruments')
          .select('id, name')
          .eq('tenantId', currentTenantId);

      final map = <int, String>{};
      for (final row in response as List) {
        map[row['id'] as int] = row['name'] as String;
      }
      return map;
    } catch (e, stack) {
      handleError(e, stack, 'getGroupsMap');
      rethrow;
    }
  }

  /// Get the main group for the tenant
  Future<Group?> getMainGroup() async {
    try {
      final response = await supabase
          .from('instruments')
          .select('*')
          .eq('tenantId', currentTenantId)
          .eq('maingroup', true)
          .maybeSingle();

      if (response == null) return null;
      return Group.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'getMainGroup');
      rethrow;
    }
  }

  /// Get a single group by ID
  Future<Group?> getGroupById(int id) async {
    try {
      final response = await supabase
          .from('instruments')
          .select('*')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Group.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'getGroupById');
      rethrow;
    }
  }

  /// Create a new group
  Future<Group> createGroup({
    required String name,
    bool maingroup = false,
  }) async {
    try {
      final response = await supabase
          .from('instruments')
          .insert({
            'name': name,
            'tuning': 'C',
            'clefs': ['g'],
            'tenantId': currentTenantId,
            'maingroup': maingroup,
          })
          .select()
          .single();

      return Group.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'createGroup');
      rethrow;
    }
  }

  /// Update a group
  Future<Group> updateGroup(int id, Map<String, dynamic> updates) async {
    try {
      // Remove read-only fields
      updates.remove('id');
      updates.remove('created_at');
      updates.remove('tenantId');
      updates.remove('categoryData');
      updates.remove('count');

      final response = await supabase
          .from('instruments')
          .update(updates)
          .eq('id', id)
          .eq('tenantId', currentTenantId)
          .select()
          .single();

      return Group.fromJson(response);
    } catch (e, stack) {
      // Handle unique constraint violation (only one maingroup)
      if (e.toString().contains('23505')) {
        throw RepositoryException(
          message: 'Es kann nur eine Hauptgruppe existieren',
          operation: 'updateGroup',
          code: '23505',
        );
      }
      handleError(e, stack, 'updateGroup');
      rethrow;
    }
  }

  /// Delete a group
  Future<void> deleteGroup(int id) async {
    try {
      await supabase
          .from('instruments')
          .delete()
          .eq('id', id)
          .eq('tenantId', currentTenantId);
    } catch (e, stack) {
      handleError(e, stack, 'deleteGroup');
      rethrow;
    }
  }

  // --- Group Categories ---

  /// Get all group categories
  Future<List<GroupCategory>> getGroupCategories() async {
    try {
      final response = await supabase
          .from('group_categories')
          .select('*')
          .eq('tenant_id', currentTenantId)
          .order('index');

      return (response as List)
          .map((e) => GroupCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getGroupCategories');
      rethrow;
    }
  }

  /// Create a group category
  Future<GroupCategory> createGroupCategory({
    required String name,
    int? index,
  }) async {
    try {
      final response = await supabase
          .from('group_categories')
          .insert({
            'name': name,
            'index': index,
            'tenant_id': currentTenantId,
          })
          .select()
          .single();

      return GroupCategory.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'createGroupCategory');
      rethrow;
    }
  }

  /// Update a group category
  Future<GroupCategory> updateGroupCategory(int id, Map<String, dynamic> updates) async {
    try {
      updates.remove('id');
      updates.remove('created_at');
      updates.remove('tenant_id');

      final response = await supabase
          .from('group_categories')
          .update(updates)
          .eq('id', id)
          .eq('tenant_id', currentTenantId)
          .select()
          .single();

      return GroupCategory.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'updateGroupCategory');
      rethrow;
    }
  }

  /// Delete a group category
  Future<void> deleteGroupCategory(int id) async {
    try {
      await supabase
          .from('group_categories')
          .delete()
          .eq('id', id)
          .eq('tenant_id', currentTenantId);
    } catch (e, stack) {
      handleError(e, stack, 'deleteGroupCategory');
      rethrow;
    }
  }
}
