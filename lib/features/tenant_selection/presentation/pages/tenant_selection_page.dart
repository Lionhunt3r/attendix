import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/tenant/tenant.dart';

/// Provider for current selected tenant - persisted in SharedPreferences
final currentTenantProvider = StateNotifierProvider<CurrentTenantNotifier, Tenant?>((ref) {
  return CurrentTenantNotifier(ref);
});

class CurrentTenantNotifier extends StateNotifier<Tenant?> {
  CurrentTenantNotifier(this.ref) : super(null) {
    _loadSavedTenant();
  }

  final Ref ref;
  static const _tenantIdKey = 'current_tenant_id';

  Future<void> _loadSavedTenant() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTenantId = prefs.getInt(_tenantIdKey);
    
    if (savedTenantId != null) {
      // Load the tenant from the server
      try {
        final supabase = ref.read(supabaseClientProvider);
        final response = await supabase
            .from('tenants')
            .select('*')
            .eq('id', savedTenantId)
            .maybeSingle();
        
        if (response != null) {
          state = Tenant.fromJson(response as Map<String, dynamic>);
        }
      } catch (e) {
        // Ignore errors, user will need to select tenant again
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

/// Tenant selection page
class TenantSelectionPage extends ConsumerWidget {
  const TenantSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(userTenantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruppe auswählen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final supabase = ref.read(supabaseClientProvider);
              await supabase.auth.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: tenantsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Fehler beim Laden',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              ElevatedButton(
                onPressed: () => ref.refresh(userTenantsProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (tenants) {
          if (tenants.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.group_off_outlined,
                      size: 80,
                      color: AppColors.medium,
                    ),
                    const SizedBox(height: AppDimensions.paddingL),
                    Text(
                      'Keine Gruppen',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppDimensions.paddingS),
                    Text(
                      'Du bist noch keiner Gruppe zugeordnet. '
                      'Bitte wende dich an einen Administrator oder erstelle eine neue Gruppe.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.medium,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.paddingXL),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/tenants/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Neue Gruppe erstellen'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: tenants.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.paddingS),
            itemBuilder: (context, index) {
              final tenant = tenants[index];
              return _TenantCard(
                tenant: tenant,
                onTap: () {
                  ref.read(currentTenantProvider.notifier).setTenant(tenant);
                  context.go('/people');
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({
    required this.tenant,
    required this.onTap,
  });

  final Tenant tenant;
  final VoidCallback onTap;

  String get _displayName => tenant.shortName.isNotEmpty ? tenant.shortName : tenant.longName;
  String? get _description => tenant.longName != tenant.shortName ? tenant.longName : null;
  String get _initials => _displayName.length >= 2 
      ? _displayName.substring(0, 2).toUpperCase()
      : _displayName.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // Tenant avatar/image
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              
              // Tenant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_description != null) ...[
                      const SizedBox(height: AppDimensions.paddingXS),
                      Text(
                        _description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.medium,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              const Icon(
                Icons.chevron_right,
                color: AppColors.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
