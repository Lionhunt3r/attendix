import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../tenant_selection/presentation/pages/tenant_selection_page.dart';

/// Settings page
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          // Tenant info section
          if (tenant != null) ...[
            _SettingsSection(
              title: 'Aktuelle Gruppe',
              children: [
                _SettingsTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      tenant.shortName.isNotEmpty 
                          ? tenant.shortName.substring(0, 2).toUpperCase()
                          : tenant.longName.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: tenant.shortName.isNotEmpty ? tenant.shortName : tenant.longName,
                  subtitle: tenant.longName != tenant.shortName ? tenant.longName : null,
                  trailing: TextButton(
                    onPressed: () => context.go('/tenants'),
                    child: const Text('Wechseln'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),
          ],

          // Content management section
          _SettingsSection(
            title: 'Verwaltung',
            children: [
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.category),
                title: 'Terminarten',
                subtitle: 'Proben, Auftritte, etc. verwalten',
                onTap: () => context.push('/settings/types'),
              ),
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.music_note),
                title: 'Lieder',
                subtitle: 'Lieder und Notenblätter verwalten',
                onTap: () => context.push('/settings/songs'),
              ),
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.piano),
                title: 'Instrumente',
                subtitle: 'Instrumentenliste verwalten',
                onTap: () => context.push('/settings/instruments'),
              ),
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.school),
                title: 'Lehrer',
                subtitle: 'Lehrer und Ausbilder verwalten',
                onTap: () => context.push('/settings/teachers'),
              ),
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.event),
                title: 'Sitzungen',
                subtitle: 'Vorstandssitzungen verwalten',
                onTap: () => context.push('/settings/meetings'),
              ),
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.people),
                title: 'Benutzer',
                subtitle: 'Rollen und Berechtigungen verwalten',
                onTap: () => context.push('/settings/users'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Member management section
          _SettingsSection(
            title: 'Mitgliederverwaltung',
            children: [
              _SettingsTile(
                leading: _SettingsIcon(
                  icon: Icons.hourglass_empty,
                  color: AppColors.warning,
                ),
                title: 'Ausstehende Registrierungen',
                subtitle: 'Neue Selbst-Registrierungen prüfen',
                onTap: () => context.push('/settings/pending'),
              ),
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.history),
                title: 'Ehemalige Mitglieder',
                subtitle: 'Archivierte Mitglieder verwalten',
                onTap: () => context.push('/settings/left'),
              ),
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.calendar_month),
                title: 'Kalender-Abo',
                subtitle: 'Termine im eigenen Kalender anzeigen',
                onTap: () => context.push('/settings/calendar'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // App settings section
          _SettingsSection(
            title: 'App-Einstellungen',
            children: [
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.notifications),
                title: 'Benachrichtigungen',
                subtitle: 'Push-Benachrichtigungen konfigurieren',
                onTap: () => context.push('/settings/notifications'),
              ),
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.tune),
                title: 'Allgemein',
                subtitle: 'Sprache, Theme und weitere Optionen',
                onTap: () => context.push('/settings/general'),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Account section
          _SettingsSection(
            title: 'Konto',
            children: [
              _SettingsTile(
                leading: const _SettingsIcon(icon: Icons.person),
                title: 'Profil',
                subtitle: 'Persönliche Daten bearbeiten',
                onTap: () => context.push('/settings/profile'),
              ),
              _SettingsTile(
                leading: _SettingsIcon(
                  icon: Icons.logout,
                  color: AppColors.danger,
                ),
                title: 'Abmelden',
                titleColor: AppColors.danger,
                onTap: () async {
                  // Store refs before async gap to avoid using ref after dispose
                  final supabase = ref.read(supabaseClientProvider);
                  final tenantNotifier = ref.read(currentTenantProvider.notifier);
                  
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Abmelden'),
                      content: const Text('Möchtest du dich wirklich abmelden?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Abmelden'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await supabase.auth.signOut();
                    await tenantNotifier.clearTenant();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  'Attendix',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.medium,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.medium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingXS,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.medium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.medium,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.medium)
              : null),
      onTap: onTap,
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({
    required this.icon,
    this.color,
  });

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }
}