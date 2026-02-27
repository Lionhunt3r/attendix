import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/supabase_config.dart';
import '../../data/models/tenant/tenant.dart';
import '../constants/enums.dart';
import 'user_preferences_provider.dart';

const _tenantIdKey = 'current_tenant_id';

/// Provider for current selected tenant
final currentTenantProvider =
    StateNotifierProvider<CurrentTenantNotifier, Tenant?>((ref) {
  return CurrentTenantNotifier(ref);
});

/// Convenience provider for just the tenant ID
final currentTenantIdProvider = Provider<int?>((ref) {
  return ref.watch(currentTenantProvider)?.id;
});

/// Notifier for current tenant
/// Uses dual-storage strategy:
/// - SharedPreferences for fast local cache
/// - Supabase user_metadata for cross-device sync
class CurrentTenantNotifier extends StateNotifier<Tenant?> {
  CurrentTenantNotifier(this.ref) : super(null) {
    _initializeTenant();
  }

  final Ref ref;

  /// Initialize tenant from local cache and sync with server
  Future<void> _initializeTenant() async {
    // Step 1: Load from SharedPreferences (fast, instant)
    final prefs = await SharedPreferences.getInstance();
    final cachedTenantId = prefs.getInt(_tenantIdKey);

    // Step 2: Get authoritative value from user_metadata
    final auth = ref.read(supabaseAuthProvider);
    final userMetadata = auth.currentUser?.userMetadata;
    final serverTenantId = userMetadata?['currentTenantId'] as int?;

    // Step 3: Determine which tenant ID to use (server takes precedence)
    final tenantIdToLoad = serverTenantId ?? cachedTenantId;

    if (tenantIdToLoad != null) {
      await _loadAndValidateTenant(tenantIdToLoad);

      // Sync cache if server had different value
      if (serverTenantId != null && serverTenantId != cachedTenantId) {
        await prefs.setInt(_tenantIdKey, serverTenantId);
      }
    }
  }

  /// Load tenant by ID and validate user still has access
  Future<void> _loadAndValidateTenant(int tenantId) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      // Verify user still has access to this tenant
      final tenantUserResponse = await supabase
          .from('tenantUsers')
          .select('tenantId')
          .eq('tenantId', tenantId)
          .eq('userId', userId)
          .maybeSingle();

      // User no longer has access to this tenant
      if (tenantUserResponse == null) {
        debugPrint('User no longer has access to tenant $tenantId');
        await _clearAllStorage();
        return;
      }

      // Load the tenant data
      final response = await supabase
          .from('tenants')
          .select('*')
          .eq('id', tenantId)
          .maybeSingle();

      if (response != null) {
        state = Tenant.fromJson(response);
      } else {
        // Tenant doesn't exist anymore
        await _clearAllStorage();
      }
    } catch (e, stack) {
      debugPrint('Failed to load saved tenant: $e');
      // SEC-008: Only log stack trace in debug mode
      if (kDebugMode) {
        debugPrint('$stack');
      }
    }
  }

  /// Set the current tenant locally without triggering auth sync.
  /// Use this for navigation scenarios where auth events would interrupt navigation.
  /// After navigation completes, call updateCurrentTenantId separately.
  Future<void> setTenantLocal(Tenant? tenant) async {
    state = tenant;

    final prefs = await SharedPreferences.getInstance();
    final tenantId = tenant?.id;
    if (tenantId != null) {
      await prefs.setInt(_tenantIdKey, tenantId);
    } else {
      await prefs.remove(_tenantIdKey);
    }
    // NOTE: Does NOT call updateCurrentTenantId to avoid auth events
  }

  /// Set the current tenant and persist to both storages
  Future<void> setTenant(Tenant? tenant) async {
    await setTenantLocal(tenant);

    // Update user_metadata asynchronously (fire and forget for cross-device sync)
    final tenantId = tenant?.id;
    if (tenantId != null) {
      ref
          .read(userPreferencesNotifierProvider.notifier)
          .updateCurrentTenantId(tenantId);
    }
  }

  /// Clear tenant from state and all storage
  Future<void> clearTenant() async {
    state = null;
    await _clearAllStorage();
  }

  /// Clear tenant from both SharedPreferences and user_metadata
  Future<void> _clearAllStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tenantIdKey);

    // Also clear from user_metadata
    ref.read(userPreferencesNotifierProvider.notifier).clearCurrentTenantId();
  }
}

/// Provider for user's tenants list
final userTenantsProvider = FutureProvider<List<Tenant>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;
  
  if (userId == null) return [];

  // First get tenant user records
  final tenantUsersResponse = await supabase
      .from('tenantUsers')
      .select('tenantId')
      .eq('userId', userId);

  if ((tenantUsersResponse as List).isEmpty) return [];

  // Get tenant IDs
  final tenantIds = (tenantUsersResponse as List)
      .map((item) => item['tenantId'] as int)
      .toList();

  // Then get the tenants
  final tenantsResponse = await supabase
      .from('tenants')
      .select('*')
      .inFilter('id', tenantIds);

  final List<Tenant> tenants = [];
  for (final item in tenantsResponse as List) {
    tenants.add(Tenant.fromJson(item as Map<String, dynamic>));
  }
  return tenants;
});

/// Provider for current user's TenantUser record in the selected tenant
final currentTenantUserProvider = FutureProvider<TenantUser?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  final userId = supabase.auth.currentUser?.id;

  if (tenant == null || userId == null) return null;

  final response = await supabase
      .from('tenantUsers')
      .select('*')
      .eq('tenantId', tenant.id!)
      .eq('userId', userId)
      .maybeSingle();

  if (response == null) return null;
  return TenantUser.fromJson(response);
});

/// Convenience provider for current user's role
final currentRoleProvider = Provider<Role>((ref) {
  final tenantUserAsync = ref.watch(currentTenantUserProvider);
  final tenantUser = tenantUserAsync.valueOrNull;
  if (tenantUser == null) return Role.none;
  return tenantUser.roleEnum;
});
