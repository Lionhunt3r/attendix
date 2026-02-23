import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/instrument/instrument.dart';
import '../../data/repositories/repositories.dart';
import 'tenant_providers.dart';

/// Initialized group repository with tenant context
final groupRepositoryWithTenantProvider = Provider<GroupRepository>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  final tenant = ref.watch(currentTenantIdProvider);
  
  if (tenant != null) {
    repo.setTenantId(tenant);
  }
  
  return repo;
});

/// Provider for groups/instruments list
final groupsProvider = FutureProvider<List<Group>>((ref) async {
  // Keep data in memory - groups rarely change during a session
  ref.keepAlive();

  final repo = ref.watch(groupRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return [];

  return repo.getGroups();
});

/// Provider for groups as a map (id -> name)
final groupsMapProvider = FutureProvider<Map<int, String>>((ref) async {
  // Keep data in memory - groups rarely change during a session
  ref.keepAlive();

  final repo = ref.watch(groupRepositoryWithTenantProvider);

  if (!repo.hasTenantId) return {};

  return repo.getGroupsMap();
});

/// Provider for the main group
final mainGroupProvider = FutureProvider<Group?>((ref) async {
  final repo = ref.watch(groupRepositoryWithTenantProvider);
  
  if (!repo.hasTenantId) return null;
  
  return repo.getMainGroup();
});

/// Provider for group categories
final groupCategoriesProvider = FutureProvider<List<GroupCategory>>((ref) async {
  final repo = ref.watch(groupRepositoryWithTenantProvider);
  
  if (!repo.hasTenantId) return [];
  
  return repo.getGroupCategories();
});

/// Notifier for group mutations
class GroupNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  GroupRepository get _repo => ref.read(groupRepositoryWithTenantProvider);

  Future<Group?> createGroup(String name, {bool maingroup = false}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createGroup(name: name, maingroup: maingroup);
      state = const AsyncValue.data(null);
      ref.invalidate(groupsProvider);
      ref.invalidate(groupsMapProvider);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<Group?> updateGroup(int id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.updateGroup(id, updates);
      state = const AsyncValue.data(null);
      ref.invalidate(groupsProvider);
      ref.invalidate(groupsMapProvider);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> deleteGroup(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteGroup(id);
      state = const AsyncValue.data(null);
      ref.invalidate(groupsProvider);
      ref.invalidate(groupsMapProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<GroupCategory?> createGroupCategory(String name, {int? index}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.createGroupCategory(name: name, index: index);
      state = const AsyncValue.data(null);
      ref.invalidate(groupCategoriesProvider);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> deleteGroupCategory(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteGroupCategory(id);
      state = const AsyncValue.data(null);
      ref.invalidate(groupCategoriesProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final groupNotifierProvider = NotifierProvider<GroupNotifier, AsyncValue<void>>(() {
  return GroupNotifier();
});
