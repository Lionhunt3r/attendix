import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/providers/user_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';

/// Profile page for viewing and editing user profile
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;
      final tenant = ref.read(currentTenantProvider);

      if (user == null) {
        throw Exception('Nicht angemeldet');
      }

      // Load tenant user profile
      Map<String, dynamic>? tenantUser;
      if (tenant?.id != null) {
        final response = await supabase
            .from('tenantUsers')
            .select('*')
            .eq('userId', user.id)
            .eq('tenantId', tenant!.id!)
            .maybeSingle();
        tenantUser = response;
      }

      // Load player profile if exists
      Map<String, dynamic>? player;
      // RT-007: Safe playerId extraction
      final playerId = tenantUser?['playerId'];
      if (playerId != null) {
        // FN-002: Use correct table name 'player' (not 'players')
        final playerResponse = await supabase
            .from('player')
            .select('*')
            .eq('id', playerId)
            .maybeSingle();
        player = playerResponse;
      }

      _profileData = {
        'email': user.email,
        'userId': user.id,
        'firstName': player?['firstName'] ?? tenantUser?['firstName'] ?? '',
        'lastName': player?['lastName'] ?? tenantUser?['lastName'] ?? '',
        'phone': player?['phone'] ?? tenantUser?['phone'] ?? '',
        'tenantRole': tenantUser?['role'],
        'playerId': tenantUser?['playerId'],
      };

      _firstNameController.text = _profileData!['firstName'] ?? '';
      _lastNameController.text = _profileData!['lastName'] ?? '';
      _phoneController.text = _profileData!['phone'] ?? '';

    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Laden: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null || tenant?.id == null) {
        throw Exception('Nicht angemeldet');
      }

      // Update tenant user
      await supabase
          .from('tenantUsers')
          .update({
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
          })
          .eq('userId', userId)
          .eq('tenantId', tenant!.id!);

      // Update player if linked
      // RT-006: Extract to local variable for null-safety
      final playerId = _profileData?['playerId'];
      if (playerId != null) {
        // FN-002: Use correct table name 'player' (not 'players')
        await supabase
            .from('player')
            .update({
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'phone': _phoneController.text.trim(),
            })
            .eq('id', playerId)
            .eq('tenantId', tenant!.id!);
      }

      if (mounted) {
        ToastHelper.showSuccess(context, 'Profil gespeichert');
        setState(() => _isEditing = false);
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(),
    );

    if (result == true && mounted) {
      ToastHelper.showSuccess(context, 'Passwort-Reset E-Mail gesendet');
    }
  }

  String _getRoleName(int? role) {
    switch (role) {
      case 5:
        return 'Administrator';
      case 4:
        return 'Verantwortlicher';
      case 3:
        return 'Dirigent';
      case 2:
        return 'Betrachter';
      case 1:
        return 'Elternteil';
      case 0:
        return 'Mitglied';
      default:
        return 'Unbekannt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = ref.watch(currentTenantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!_isLoading && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Bearbeiten',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Abbrechen',
              onPressed: () {
                setState(() => _isEditing = false);
                _loadProfile();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                children: [
                  // Avatar section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            _getInitials(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),

                  // Email (read-only)
                  _buildInfoTile(
                    icon: Icons.email_outlined,
                    label: 'E-Mail',
                    value: _profileData?['email'] ?? '-',
                  ),

                  // Tenant & Role
                  if (tenant != null)
                    _buildInfoTile(
                      icon: Icons.groups_outlined,
                      label: 'Aktuelle Gruppe',
                      value: tenant.shortName,
                      subtitle: _getRoleName(_profileData?['tenantRole']),
                    ),

                  const SizedBox(height: AppDimensions.paddingM),
                  const Divider(),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Editable fields
                  Text(
                    'Persönliche Daten',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // First Name
                  TextFormField(
                    controller: _firstNameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Vorname',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Last Name
                  TextFormField(
                    controller: _lastNameController,
                    enabled: _isEditing,
                    decoration: const InputDecoration(
                      labelText: 'Nachname',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: AppDimensions.paddingL),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Speichern'),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.paddingXL),
                  const Divider(),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Security section
                  Text(
                    'Sicherheit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Passwort ändern'),
                    subtitle: const Text('Sende einen Reset-Link an deine E-Mail'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePassword,
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),
                  const Divider(),
                  const SizedBox(height: AppDimensions.paddingM),

                  // App Settings section
                  Text(
                    'App-Einstellungen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Instance Selection Toggle
                  Consumer(
                    builder: (context, ref, _) {
                      final prefs = ref.watch(userPreferencesProvider);
                      return SwitchListTile(
                        secondary: const Icon(Icons.swap_horiz),
                        title: const Text('Gruppenauswahl beim Start'),
                        subtitle: const Text(
                          'Immer beim Öffnen der App nach der Gruppe fragen',
                        ),
                        value: prefs.wantInstanceSelection,
                        onChanged: (value) async {
                          try {
                            await ref
                                .read(userPreferencesNotifierProvider.notifier)
                                .updatePreferences(wantInstanceSelection: value);
                            if (context.mounted) {
                              ToastHelper.showSuccess(
                                context,
                                value
                                    ? 'Gruppenauswahl aktiviert'
                                    : 'Gruppenauswahl deaktiviert',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ToastHelper.showError(
                                context,
                                'Einstellung konnte nicht gespeichert werden',
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.medium)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 16)),
          if (subtitle != null)
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.medium)),
        ],
      ),
    );
  }

  String _getInitials() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (first.isEmpty && last.isEmpty) {
      return (_profileData?['email'] as String?)?.substring(0, 1).toUpperCase() ?? '?';
    }
    return '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'.toUpperCase();
  }
}

/// Dialog for changing password
class _ChangePasswordDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Passwort ändern'),
      content: const Text(
        'Wir senden dir einen Link zum Zurücksetzen deines Passworts an deine registrierte E-Mail-Adresse.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              final supabase = ref.read(supabaseClientProvider);
              final email = supabase.auth.currentUser?.email;
              if (email != null) {
                await supabase.auth.resetPasswordForEmail(email);
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              }
            } catch (e) {
              if (context.mounted) {
                ToastHelper.showError(context, 'Fehler: $e');
                Navigator.of(context).pop(false);
              }
            }
          },
          child: const Text('Link senden'),
        ),
      ],
    );
  }
}
