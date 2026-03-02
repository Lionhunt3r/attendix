import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/providers/tenant_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/person/person.dart';
import '../../../../../shared/widgets/editable/editable_info_row.dart';

/// Accordion section displaying account information.
class AccountAccordion extends ConsumerWidget {
  const AccountAccordion({
    super.key,
    required this.person,
    required this.isExpanded,
    required this.onToggle,
    required this.userRole,
    required this.isLoadingRole,
    required this.onRoleChanged,
    required this.onUnlinkAccount,
    required this.canEdit,
  });

  final Person person;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Role? userRole;
  final bool isLoadingRole;
  final ValueChanged<Role> onRoleChanged;
  final VoidCallback onUnlinkAccount;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show if person has email or appId
    if (person.email == null && person.appId == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Account',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: onToggle,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingM,
                0,
                AppDimensions.paddingM,
                AppDimensions.paddingM,
              ),
              child: _buildContent(context, ref),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email
        InfoRow(
          icon: Icons.email,
          label: 'E-Mail',
          value: person.email ?? 'Nicht angegeben',
          onTap: person.email != null
              ? () => _launchEmail(person.email!)
              : null,
        ),

        // Account linked status
        if (person.appId != null) ...[
          const InfoRow(
            icon: Icons.badge,
            label: 'Account',
            value: 'Verknüpft',
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Role selector
          _buildRoleSelector(context, tenant?.id),
          const SizedBox(height: AppDimensions.paddingM),

          // Unlink button
          if (canEdit)
            OutlinedButton.icon(
              onPressed: onUnlinkAccount,
              icon: const Icon(Icons.link_off, color: AppColors.danger),
              label: const Text('Account-Verknüpfung aufheben'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            ),
        ],

        // Info for persons without account
        if (person.appId == null && person.email != null) ...[
          const SizedBox(height: AppDimensions.paddingM),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: AppDimensions.paddingS),
                Expanded(
                  child: Text(
                    'Account-Erstellung ist über die Web-Verwaltung möglich.',
                    style: TextStyle(fontSize: 13, color: AppColors.dark),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (person.appId == null && person.email == null)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                SizedBox(width: AppDimensions.paddingS),
                Expanded(
                  child: Text(
                    'Um einen Account zu erstellen, muss eine E-Mail-Adresse hinterlegt werden.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRoleSelector(BuildContext context, int? tenantId) {
    if (person.appId == null || tenantId == null) {
      return const SizedBox.shrink();
    }

    final availableRoles = [
      Role.player,
      Role.helper,
      Role.viewer,
      Role.responsible,
      Role.admin,
    ];

    if (isLoadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentRole = userRole ?? Role.player;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rolle',
          style: TextStyle(fontSize: 12, color: AppColors.medium),
        ),
        const SizedBox(height: AppDimensions.paddingXS),
        DropdownButtonFormField<Role>(
          value: currentRole,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
          ),
          items: availableRoles.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Row(
                children: [
                  Icon(_getRoleIcon(role), size: 20, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(_getRoleLabel(role)),
                ],
              ),
            );
          }).toList(),
          onChanged: canEdit
              ? (newRole) {
                  if (newRole != null && newRole != currentRole) {
                    onRoleChanged(newRole);
                  }
                }
              : null,
        ),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getRoleLabel(Role role) {
    return switch (role) {
      Role.admin => 'Dirigent (Admin)',
      Role.responsible => 'Verantwortlicher',
      Role.helper => 'Helfer',
      Role.viewer => 'Beobachter',
      Role.player => 'Mitglied',
      Role.voiceLeader => 'Stimmführer',
      Role.voiceLeaderHelper => 'Stimmführer-Helfer',
      Role.parent => 'Eltern',
      Role.applicant => 'Bewerber',
      Role.none => 'Keine Rolle',
    };
  }

  IconData _getRoleIcon(Role role) {
    return switch (role) {
      Role.admin => Icons.admin_panel_settings,
      Role.responsible => Icons.manage_accounts,
      Role.helper => Icons.handshake,
      Role.viewer => Icons.visibility,
      Role.player => Icons.person,
      Role.voiceLeader => Icons.record_voice_over,
      Role.voiceLeaderHelper => Icons.support_agent,
      Role.parent => Icons.family_restroom,
      Role.applicant => Icons.pending,
      Role.none => Icons.person_off,
    };
  }
}
