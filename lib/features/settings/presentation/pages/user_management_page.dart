import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';

/// TenantUser model
class TenantUser {
  final String id;
  final int tenantId;
  final String userId;
  final int role;
  final int? personId;
  final String? email;

  const TenantUser({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.role,
    this.personId,
    this.email,
  });

  factory TenantUser.fromJson(Map<String, dynamic> json) {
    return TenantUser(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenantId'] ?? json['tenant_id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? '',
      role: json['role'] ?? 99,
      personId: json['personId'] ?? json['person_id'],
      email: json['email'],
    );
  }

  Role get roleEnum => Role.fromValue(role);
}

/// Provider for tenant users
final tenantUsersProvider = FutureProvider<List<TenantUser>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);

  if (tenantId == null) return [];

  // Get tenant users with auth user email
  final response = await supabase
      .from('tenantUsers')
      .select('*, email:auth.users!userId(email)')
      .eq('tenantId', tenantId)
      .order('role', ascending: true);

  return (response as List).map((e) {
    // Extract email from nested structure
    final emailData = e['email'];
    String? email;
    if (emailData is Map) {
      email = emailData['email'] as String?;
    } else if (emailData is String) {
      email = emailData;
    }
    return TenantUser.fromJson({...e, 'email': email});
  }).toList();
});

/// User Management Page
class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);
    final showParents = tenant?.parents ?? false;

    return DefaultTabController(
      length: showParents ? 4 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Benutzerverwaltung'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Admins'),
              const Tab(text: 'Betrachter'),
              if (showParents) const Tab(text: 'Eltern'),
              const Tab(text: 'Alle Benutzer'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AdminsTab(),
            _ViewersTab(),
            if (showParents) _ParentsTab(),
            const _AllUsersTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddUserDialog(context, ref),
          child: const Icon(Icons.person_add),
        ),
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context, WidgetRef ref) async {
    final tenant = ref.read(currentTenantProvider);
    final showParents = tenant?.parents ?? false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _AddUserDialog(showParents: showParents),
    );

    if (result != null && context.mounted) {
      await _addUser(context, ref, result['email'], Role.fromValue(result['role']));
    }
  }

  Future<void> _addUser(BuildContext context, WidgetRef ref, String email, Role role) async {
    final supabase = ref.read(supabaseClientProvider);
    final tenantId = ref.read(currentTenantIdProvider);

    if (tenantId == null) return;

    try {
      // First check if user exists
      final existingUser = await supabase
          .from('auth.users')
          .select('id')
          .eq('email', email.toLowerCase().trim())
          .maybeSingle();

      if (existingUser != null) {
        // User exists, add to tenant
        await supabase.from('tenantUsers').insert({
          'tenantId': tenantId,
          'userId': existingUser['id'],
          'role': role.value,
        });

        ref.invalidate(tenantUsersProvider);

        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Benutzer hinzugefügt');
        }
      } else {
        // User doesn't exist - show invitation message
        if (context.mounted) {
          ToastHelper.showInfo(
            context,
            'Benutzer mit dieser E-Mail nicht gefunden. Bitte lade ihn ein, sich zu registrieren.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

/// Dialog for adding a new user
class _AddUserDialog extends StatefulWidget {
  final bool showParents;

  const _AddUserDialog({required this.showParents});

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _emailController = TextEditingController();
  Role _selectedRole = Role.viewer;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Benutzer hinzufügen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-Mail-Adresse',
              hintText: 'email@beispiel.de',
            ),
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          DropdownButtonFormField<Role>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: 'Rolle'),
            items: [
              const DropdownMenuItem(value: Role.admin, child: Text('Administrator')),
              const DropdownMenuItem(value: Role.responsible, child: Text('Verantwortlich')),
              const DropdownMenuItem(value: Role.viewer, child: Text('Betrachter')),
              if (widget.showParents)
                const DropdownMenuItem(value: Role.parent, child: Text('Elternteil')),
            ],
            onChanged: (role) {
              if (role != null) setState(() => _selectedRole = role);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            final email = _emailController.text.trim();
            if (email.isEmpty || !email.contains('@')) {
              ToastHelper.showError(context, 'Bitte gültige E-Mail eingeben');
              return;
            }
            Navigator.of(context).pop({
              'email': email,
              'role': _selectedRole.value,
            });
          },
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}

/// Tab showing admins only
class _AdminsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(tenantUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (users) {
        final admins = users.where((u) => u.roleEnum == Role.admin).toList();

        if (admins.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, size: 64, color: AppColors.medium),
                SizedBox(height: 16),
                Text('Keine Administratoren'),
                SizedBox(height: 8),
                Text(
                  'Füge Admins über den + Button hinzu',
                  style: TextStyle(color: AppColors.medium, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tenantUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: admins.length,
            itemBuilder: (context, index) => _UserTile(user: admins[index]),
          ),
        );
      },
    );
  }
}

/// Tab showing viewers only
class _ViewersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(tenantUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (users) {
        final viewers = users.where((u) => u.roleEnum == Role.viewer).toList();

        if (viewers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, size: 64, color: AppColors.medium),
                SizedBox(height: 16),
                Text('Keine Betrachter'),
                SizedBox(height: 8),
                Text(
                  'Betrachter können Anwesenheit sehen, aber nicht bearbeiten',
                  style: TextStyle(color: AppColors.medium, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tenantUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: viewers.length,
            itemBuilder: (context, index) => _UserTile(user: viewers[index]),
          ),
        );
      },
    );
  }
}

/// Tab showing parents only
class _ParentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(tenantUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (users) {
        final parents = users.where((u) => u.roleEnum == Role.parent).toList();

        if (parents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.family_restroom, size: 64, color: AppColors.medium),
                SizedBox(height: 16),
                Text('Keine Eltern'),
                SizedBox(height: 8),
                Text(
                  'Eltern können ihre Kinder an-/abmelden',
                  style: TextStyle(color: AppColors.medium, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tenantUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            itemCount: parents.length,
            itemBuilder: (context, index) => _UserTile(user: parents[index]),
          ),
        );
      },
    );
  }
}

/// Tab showing all tenant users
class _AllUsersTab extends ConsumerWidget {
  const _AllUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(tenantUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppColors.medium),
                SizedBox(height: 16),
                Text('Keine Benutzer vorhanden'),
              ],
            ),
          );
        }

        // Group by role
        final admins = users.where((u) => u.roleEnum == Role.admin).toList();
        final responsibles = users.where((u) => u.roleEnum == Role.responsible).toList();
        final players = users.where((u) => u.roleEnum == Role.player).toList();
        final viewers = users.where((u) => u.roleEnum == Role.viewer).toList();
        final others = users.where((u) =>
          ![Role.admin, Role.responsible, Role.player, Role.viewer].contains(u.roleEnum)
        ).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tenantUsersProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            children: [
              if (admins.isNotEmpty) ...[
                _buildRoleSection(context, ref, 'Administratoren', admins, Icons.admin_panel_settings),
              ],
              if (responsibles.isNotEmpty) ...[
                _buildRoleSection(context, ref, 'Verantwortliche', responsibles, Icons.supervisor_account),
              ],
              if (players.isNotEmpty) ...[
                _buildRoleSection(context, ref, 'Spieler', players, Icons.person),
              ],
              if (viewers.isNotEmpty) ...[
                _buildRoleSection(context, ref, 'Betrachter', viewers, Icons.visibility),
              ],
              if (others.isNotEmpty) ...[
                _buildRoleSection(context, ref, 'Sonstige', others, Icons.person_outline),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<TenantUser> users,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.medium),
              const SizedBox(width: 8),
              Text(
                '$title (${users.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.medium,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: Column(
            children: users.map((user) => _UserTile(user: user)).toList(),
          ),
        ),
      ],
    );
  }
}

class _UserTile extends ConsumerWidget {
  final TenantUser user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getRoleColor(user.roleEnum).withAlpha(30),
        child: Icon(
          _getRoleIcon(user.roleEnum),
          color: _getRoleColor(user.roleEnum),
          size: 20,
        ),
      ),
      title: Text(user.email ?? 'Unbekannt'),
      subtitle: Text(_getRoleLabel(user.roleEnum)),
      trailing: PopupMenuButton<Role>(
        onSelected: (role) => _changeRole(context, ref, role),
        itemBuilder: (context) => Role.values
            .where((r) => r != Role.none && r != Role.applicant)
            .map((role) => PopupMenuItem(
                  value: role,
                  child: Text(_getRoleLabel(role)),
                ))
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(user.roleEnum).withAlpha(20),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getRoleLabel(user.roleEnum),
                style: TextStyle(
                  color: _getRoleColor(user.roleEnum),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                color: _getRoleColor(user.roleEnum),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeRole(BuildContext context, WidgetRef ref, Role newRole) async {
    if (newRole.value == user.role) return;

    final supabase = ref.read(supabaseClientProvider);

    try {
      await supabase
          .from('tenantUsers')
          .update({'role': newRole.value})
          .eq('id', user.id);

      ref.invalidate(tenantUsersProvider);

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Rolle geändert zu ${_getRoleLabel(newRole)}');
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  Color _getRoleColor(Role role) {
    return switch (role) {
      Role.admin => Colors.red,
      Role.responsible => Colors.orange,
      Role.player => AppColors.primary,
      Role.viewer => Colors.grey,
      Role.helper => Colors.green,
      Role.parent => Colors.purple,
      _ => AppColors.medium,
    };
  }

  IconData _getRoleIcon(Role role) {
    return switch (role) {
      Role.admin => Icons.admin_panel_settings,
      Role.responsible => Icons.supervisor_account,
      Role.player => Icons.person,
      Role.viewer => Icons.visibility,
      Role.helper => Icons.handshake,
      Role.parent => Icons.family_restroom,
      _ => Icons.person_outline,
    };
  }

  String _getRoleLabel(Role role) {
    return switch (role) {
      Role.admin => 'Administrator',
      Role.responsible => 'Verantwortlich',
      Role.player => 'Spieler',
      Role.viewer => 'Betrachter',
      Role.helper => 'Helfer',
      Role.parent => 'Elternteil',
      Role.applicant => 'Bewerber',
      Role.none => 'Keine Rolle',
    };
  }
}
