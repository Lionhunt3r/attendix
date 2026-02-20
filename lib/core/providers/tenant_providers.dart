import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/supabase_config.dart';
import '../../data/models/tenant/tenant.dart';
import '../constants/enums.dart';

const _tenantIdKey = 'current_tenant_id';

/// Provider for current selected tenant
final currentTenantProvider = StateNotifierProvider<CurrentTenantNotifier, Tenant?>((ref) {
  return CurrentTenantNotifier(ref);
});

/// Convenience provider for just the tenant ID
final currentTenantIdProvider = Provider<int?>((ref) {
  return ref.watch(currentTenantProvider)?.id;
});

/// Notifier for current tenant
class CurrentTenantNotifier extends StateNotifier<Tenant?> {
  CurrentTenantNotifier(this.ref) : super(null) {
    _loadSavedTenant();
  }

  final Ref ref;

  Future<void> _loadSavedTenant() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTenantId = prefs.getInt(_tenantIdKey);
    
    if (savedTenantId != null) {
      try {
        final supabase = ref.read(supabaseClientProvider);
        final response = await supabase
            .from('tenants')
            .select('*')
            .eq('id', savedTenantId)
            .maybeSingle();
        
        if (response != null) {
          state = Tenant.fromJson(response);
        }
      } catch (e, stack) {
        // Log error but continue - user will need to select tenant again
        debugPrint('Failed to load saved tenant: $e');
        debugPrint('$stack');
      }
    }
  }

  Future<void> setTenant(Tenant? tenant) async {
    state = tenant;
    final prefs = await SharedPreferences.getInstance();
    if (tenant?.id != null) {
      await prefs.setInt(_tenantIdKey, tenant!.id!);
    } else {
      await prefs.remove(_tenantIdKey);
    }
  }

  Future<void> clearTenant() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tenantIdKey);
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
