import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/tenant/tenant.dart';

/// Page showing tenant details and danger zone (delete)
class TenantDetailPage extends ConsumerWidget {
  const TenantDetailPage({super.key, required this.tenantId});

  final int tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(userTenantsProvider);

    return tenantsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Instanz-Details')),
        body: const Center(child: Text('Fehler beim Laden der Instanz-Details')),
      ),
      data: (tenants) {
        final tenant = tenants.where((t) => t.id == tenantId).firstOrNull;
        if (tenant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Instanz-Details')),
            body: const Center(child: Text('Instanz nicht gefunden')),
          );
        }

        final role = Role.fromValue(tenant.role ?? 99);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Instanz-Details'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            children: [
              _TenantHeader(tenant: tenant),
              const SizedBox(height: AppDimensions.paddingL),
              _TenantInfoSection(tenant: tenant, tenantId: tenantId, role: role),
              if (role.isAdmin) ...[
                const SizedBox(height: AppDimensions.paddingXL),
                _DangerZone(tenant: tenant),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TenantHeader extends StatelessWidget {
  const _TenantHeader({required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context) {
    final displayName = tenant.name;
    final initials = StringUtils.getTenantInitials(tenant.shortName, tenant.longName);

    final typeLabel = switch (tenant.type) {
      'choir' => 'Chor',
      'orchestra' => 'Orchester',
      _ => 'Gruppe',
    };

    return Column(
      children: [
        const SizedBox(height: AppDimensions.paddingM),
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Text(
          displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        if (tenant.description != null) ...[
          const SizedBox(height: AppDimensions.paddingXS),
          Text(
            tenant.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.medium,
                ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppDimensions.paddingXS),
        Text(
          typeLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _TenantInfoSection extends ConsumerWidget {
  const _TenantInfoSection({
    required this.tenant,
    required this.tenantId,
    required this.role,
  });

  final Tenant tenant;
  final int tenantId;
  final Role role;

  String _roleName(Role role) {
    return switch (role) {
      Role.admin => 'Administrator',
      Role.responsible => 'Verantwortlicher',
      Role.helper => 'Helfer',
      Role.viewer => 'Beobachter',
      Role.player => 'Mitglied',
      Role.voiceLeader => 'Stimmführer',
      Role.voiceLeaderHelper => 'Stimmführer-Helfer',
      Role.parent => 'Elternteil',
      Role.applicant => 'Bewerber',
      Role.none => 'Keine Rolle',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberCountAsync = ref.watch(tenantMemberCountProvider(tenantId));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingXS,
              ),
              child: Text(
                'Informationen',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.medium,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            _InfoRow(
              icon: Icons.people,
              label: 'Mitglieder',
              value: memberCountAsync.when(
                data: (count) => '$count',
                loading: () => '...',
                error: (_, __) => '-',
              ),
            ),
            if (tenant.createdAt != null)
              _InfoRow(
                icon: Icons.calendar_today,
                label: 'Erstellt am',
                value: DateFormat('dd.MM.yyyy').format(tenant.createdAt!),
              ),
            if (tenant.region != null && tenant.region!.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on,
                label: 'Region',
                value: tenant.region!,
              ),
            _InfoRow(
              icon: Icons.badge,
              label: 'Deine Rolle',
              value: _roleName(role),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.medium),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingXS,
          ),
          child: Text(
            'Gefahrenzone',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
            side: BorderSide(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.danger),
            title: Text(
              'Instanz löschen',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Diese Gruppe unwiderruflich löschen',
              style: TextStyle(fontSize: 13, color: AppColors.medium),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.medium),
            onTap: () => _showDeleteTenantDialog(context, ref, tenant),
          ),
        ),
      ],
    );
  }
}

/// Show safety dialog for deleting a tenant instance
Future<void> _showDeleteTenantDialog(
  BuildContext context,
  WidgetRef ref,
  Tenant tenant,
) async {
  final tenantName = tenant.name;
  final controller = TextEditingController();

  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final matches = controller.text.trim() == tenantName;
            return AlertDialog(
              title: const Text('Instanz löschen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diese Aktion kann nicht rückgängig gemacht werden! '
                    'Alle Daten dieser Instanz werden unwiderruflich gelöscht.',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bitte gib den Namen der Instanz ein, um das Löschen zu bestätigen:',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tenantName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Name eingeben...',
                    ),
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: matches ? () => Navigator.of(context).pop(true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Endgültig löschen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final id = tenant.id;
      if (id == null) return;
      await deleteTenant(ref, id);
      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Instanz gelöscht');
        context.go('/tenants');
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler beim Löschen');
      }
    }
  } finally {
    controller.dispose();
  }
}
