import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/organisation/organisation.dart';
import '../models/person/person.dart';
import '../models/tenant/tenant.dart';
import 'base_repository.dart';

/// Provider for OrganisationRepository
final organisationRepositoryProvider = Provider<OrganisationRepository>((ref) {
  return OrganisationRepository(ref);
});

/// Repository for organisation (tenant_groups) operations
/// NOTE: This repository does NOT use TenantAwareRepository as tenant_groups are global
class OrganisationRepository extends BaseRepository {
  OrganisationRepository(super.ref);

  /// Create a new organisation
  Future<Organisation> create(String name) async {
    try {
      final response = await supabase
          .from('tenant_groups')
          .insert({'name': name})
          .select()
          .single();

      return Organisation.fromJson(response);
    } catch (e, stack) {
      handleError(e, stack, 'create');
      rethrow;
    }
  }

  /// Link a tenant to an organisation
  Future<void> linkTenantToOrganisation(int tenantId, int organisationId) async {
    try {
      await supabase.from('tenant_group_tenants').insert({
        'tenant_id': tenantId,
        'tenant_group': organisationId,
      });
    } catch (e, stack) {
      handleError(e, stack, 'linkTenantToOrganisation');
      rethrow;
    }
  }

  /// Unlink a tenant from an organisation
  /// If no tenants remain in the organisation, the organisation is deleted
  Future<void> unlinkTenantFromOrganisation(int tenantId, int organisationId) async {
    try {
      // Remove the link
      await supabase
          .from('tenant_group_tenants')
          .delete()
          .eq('tenant_id', tenantId)
          .eq('tenant_group', organisationId);

      // Check if there are still tenants in the organisation
      final remaining = await supabase
          .from('tenant_group_tenants')
          .select('id')
          .eq('tenant_group', organisationId);

      // If no tenants remain, delete the organisation
      if ((remaining as List).isEmpty) {
        await supabase.from('tenant_groups').delete().eq('id', organisationId);
      }
    } catch (e, stack) {
      handleError(e, stack, 'unlinkTenantFromOrganisation');
      rethrow;
    }
  }

  /// Get the organisation for a specific tenant
  Future<Organisation?> getOrganisationFromTenant(int tenantId) async {
    try {
      final response = await supabase
          .from('tenant_group_tenants')
          .select('tenant_group, tenant_group_data:tenant_group(*)')
          .eq('tenant_id', tenantId)
          .maybeSingle();

      if (response == null || response['tenant_group_data'] == null) {
        return null;
      }

      return Organisation.fromJson(
          response['tenant_group_data'] as Map<String, dynamic>);
    } catch (e, stack) {
      handleError(e, stack, 'getOrganisationFromTenant');
      rethrow;
    }
  }

  /// Get all tenants of an organisation
  Future<List<Tenant>> getInstancesOfOrganisation(int organisationId) async {
    try {
      final response = await supabase
          .from('tenant_group_tenants')
          .select('tenant:tenant_id(*)')
          .eq('tenant_group', organisationId);

      return (response as List)
          .where((e) => e['tenant'] != null)
          .map((e) => Tenant.fromJson(e['tenant'] as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getInstancesOfOrganisation');
      rethrow;
    }
  }

  /// Get all persons from all tenants of an organisation
  Future<List<Person>> getAllPersonsFromOrganisation(List<Tenant> tenants) async {
    try {
      final tenantIds = tenants.map((t) => t.id).whereType<int>().toList();
      if (tenantIds.isEmpty) return [];

      final response = await supabase
          .from('player')
          .select('*')
          .inFilter('tenantId', tenantIds)
          .eq('pending', false)
          .isFilter('left', null)
          .order('lastName')
          .order('firstName');

      return (response as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getAllPersonsFromOrganisation');
      rethrow;
    }
  }

  /// Get all organisations that a user has access to
  Future<List<Organisation>> getOrganisationsFromUser(String userId) async {
    try {
      // First get all tenants the user has access to (as admin or responsible)
      final tenantsResponse = await supabase
          .from('tenantUsers')
          .select('tenantId')
          .eq('userId', userId)
          .or('role.eq.1,role.eq.5'); // Admin or Responsible

      final tenantIds = (tenantsResponse as List)
          .map((e) => e['tenantId'] as int)
          .toList();

      if (tenantIds.isEmpty) return [];

      // Get all organisations for these tenants
      final response = await supabase
          .from('tenant_group_tenants')
          .select('tenant_group_data:tenant_group(*)')
          .inFilter('tenant_id', tenantIds);

      // Remove duplicates
      final Map<int, Organisation> uniqueOrgs = {};
      for (final item in response as List) {
        final orgData = item['tenant_group_data'];
        if (orgData != null) {
          final org = Organisation.fromJson(orgData as Map<String, dynamic>);
          if (org.id != null) {
            uniqueOrgs[org.id!] = org;
          }
        }
      }

      return uniqueOrgs.values.toList();
    } catch (e, stack) {
      handleError(e, stack, 'getOrganisationsFromUser');
      rethrow;
    }
  }

  /// Get other tenants from the same organisation (excluding current tenant)
  Future<List<Tenant>> getTenantsFromOrganisation(int tenantId) async {
    try {
      final organisation = await getOrganisationFromTenant(tenantId);
      if (organisation?.id == null) return [];

      final response = await supabase
          .from('tenant_group_tenants')
          .select('tenant:tenant_id(*)')
          .eq('tenant_group', organisation!.id!);

      return (response as List)
          .where((e) => e['tenant'] != null)
          .map((e) => Tenant.fromJson(e['tenant'] as Map<String, dynamic>))
          .where((t) => t.id != tenantId) // Exclude current tenant
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getTenantsFromOrganisation');
      rethrow;
    }
  }

  /// Get all linked tenants (from all organisations the tenant belongs to)
  Future<List<Tenant>> getLinkedTenants(int tenantId) async {
    try {
      // Get all tenant_group_tenants
      final response = await supabase
          .from('tenant_group_tenants')
          .select('tenant_id, tenant_group, tenant:tenant_id(*)');

      final allLinks = response as List;

      // Find all groups that the current tenant belongs to
      final myGroups = allLinks
          .where((link) => link['tenant_id'] == tenantId)
          .map((link) => link['tenant_group'] as int)
          .toSet();

      // Find all tenants in those groups (excluding current tenant)
      return allLinks
          .where((link) =>
              myGroups.contains(link['tenant_group']) &&
              link['tenant_id'] != tenantId &&
              link['tenant'] != null)
          .map((link) => Tenant.fromJson(link['tenant'] as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      handleError(e, stack, 'getLinkedTenants');
      rethrow;
    }
  }
}
