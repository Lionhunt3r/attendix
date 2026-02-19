import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';

/// Notification config model
class NotificationConfig {
  final bool enabled;
  final String? telegramChatId;
  final bool birthdays;
  final bool signins;
  final bool signouts;
  final bool registrations;
  final bool criticals;
  final bool reminders;
  final bool updates;
  final bool checklist;

  const NotificationConfig({
    this.enabled = true,
    this.telegramChatId,
    this.birthdays = true,
    this.signins = true,
    this.signouts = true,
    this.registrations = true,
    this.criticals = true,
    this.reminders = true,
    this.updates = true,
    this.checklist = true,
  });

  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    return NotificationConfig(
      enabled: json['enabled'] ?? true,
      telegramChatId: json['telegram_chat_id'],
      birthdays: json['birthdays'] ?? true,
      signins: json['signins'] ?? true,
      signouts: json['signouts'] ?? true,
      registrations: json['registrations'] ?? true,
      criticals: json['criticals'] ?? true,
      reminders: json['reminders'] ?? true,
      updates: json['updates'] ?? true,
      checklist: json['checklist'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'telegram_chat_id': telegramChatId,
    'birthdays': birthdays,
    'signins': signins,
    'signouts': signouts,
    'registrations': registrations,
    'criticals': criticals,
    'reminders': reminders,
    'updates': updates,
    'checklist': checklist,
  };

  NotificationConfig copyWith({
    bool? enabled,
    String? telegramChatId,
    bool? birthdays,
    bool? signins,
    bool? signouts,
    bool? registrations,
    bool? criticals,
    bool? reminders,
    bool? updates,
    bool? checklist,
  }) {
    return NotificationConfig(
      enabled: enabled ?? this.enabled,
      telegramChatId: telegramChatId ?? this.telegramChatId,
      birthdays: birthdays ?? this.birthdays,
      signins: signins ?? this.signins,
      signouts: signouts ?? this.signouts,
      registrations: registrations ?? this.registrations,
      criticals: criticals ?? this.criticals,
      reminders: reminders ?? this.reminders,
      updates: updates ?? this.updates,
      checklist: checklist ?? this.checklist,
    );
  }
}

/// Provider for notification config
final notificationConfigProvider = FutureProvider<NotificationConfig?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);
  final userId = supabase.auth.currentUser?.id;

  if (tenantId == null || userId == null) return null;

  try {
    final response = await supabase
        .from('notification_config')
        .select()
        .eq('tenant_id', tenantId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      return const NotificationConfig();
    }

    return NotificationConfig.fromJson(response);
  } catch (e) {
    return const NotificationConfig();
  }
});

/// Notification Settings Page
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  NotificationConfig? _config;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await ref.read(notificationConfigProvider.future);
    if (mounted) {
      setState(() {
        _config = config ?? const NotificationConfig();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Benachrichtigungen')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          // Master toggle
          Card(
            child: SwitchListTile(
              title: const Text('Benachrichtigungen aktiviert'),
              subtitle: Text(
                _config!.enabled ? 'Du erhältst Benachrichtigungen' : 'Alle Benachrichtigungen deaktiviert',
              ),
              value: _config!.enabled,
              onChanged: (value) => _updateConfig(_config!.copyWith(enabled: value)),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Telegram connection
          _buildSection(
            title: 'Telegram',
            icon: Icons.telegram,
            children: [
              ListTile(
                title: const Text('Telegram verbinden'),
                subtitle: Text(
                  _config!.telegramChatId != null
                      ? 'Verbunden (ID: ${_config!.telegramChatId})'
                      : 'Nicht verbunden',
                ),
                trailing: _config!.telegramChatId != null
                    ? IconButton(
                        icon: const Icon(Icons.link_off, color: AppColors.danger),
                        onPressed: _disconnectTelegram,
                      )
                    : ElevatedButton(
                        onPressed: _showTelegramInstructions,
                        child: const Text('Verbinden'),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Notification categories
          _buildSection(
            title: 'Benachrichtigungskategorien',
            icon: Icons.category,
            children: [
              _buildCategoryToggle(
                title: 'Geburtstage',
                subtitle: 'Bei anstehenden Geburtstagen',
                icon: Icons.cake,
                value: _config!.birthdays,
                onChanged: (v) => _updateConfig(_config!.copyWith(birthdays: v)),
              ),
              _buildCategoryToggle(
                title: 'Anmeldungen',
                subtitle: 'Wenn sich jemand anmeldet',
                icon: Icons.login,
                value: _config!.signins,
                onChanged: (v) => _updateConfig(_config!.copyWith(signins: v)),
              ),
              _buildCategoryToggle(
                title: 'Abmeldungen',
                subtitle: 'Wenn sich jemand abmeldet',
                icon: Icons.logout,
                value: _config!.signouts,
                onChanged: (v) => _updateConfig(_config!.copyWith(signouts: v)),
              ),
              _buildCategoryToggle(
                title: 'Registrierungen',
                subtitle: 'Bei neuen Registrierungen',
                icon: Icons.person_add,
                value: _config!.registrations,
                onChanged: (v) => _updateConfig(_config!.copyWith(registrations: v)),
              ),
              _buildCategoryToggle(
                title: 'Kritische Personen',
                subtitle: 'Bei Regelverletzungen',
                icon: Icons.warning,
                value: _config!.criticals,
                onChanged: (v) => _updateConfig(_config!.copyWith(criticals: v)),
              ),
              _buildCategoryToggle(
                title: 'Erinnerungen',
                subtitle: 'Termin-Erinnerungen',
                icon: Icons.alarm,
                value: _config!.reminders,
                onChanged: (v) => _updateConfig(_config!.copyWith(reminders: v)),
              ),
              _buildCategoryToggle(
                title: 'Updates',
                subtitle: 'App-Updates und Ankündigungen',
                icon: Icons.system_update,
                value: _config!.updates,
                onChanged: (v) => _updateConfig(_config!.copyWith(updates: v)),
              ),
              _buildCategoryToggle(
                title: 'Checklisten',
                subtitle: 'Erinnerungen für Checklisten-Aufgaben',
                icon: Icons.checklist,
                value: _config!.checklist,
                onChanged: (v) => _updateConfig(_config!.copyWith(checklist: v)),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _hasChanges
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveConfig,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Änderungen speichern'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.medium,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildCategoryToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      secondary: Icon(icon, color: value ? AppColors.primary : AppColors.medium),
      value: value && _config!.enabled,
      onChanged: _config!.enabled ? onChanged : null,
    );
  }

  void _updateConfig(NotificationConfig newConfig) {
    setState(() {
      _config = newConfig;
      _hasChanges = true;
    });
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    final supabase = ref.read(supabaseClientProvider);
    final tenantId = ref.read(currentTenantIdProvider);
    final userId = supabase.auth.currentUser?.id;

    if (tenantId == null || userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      await supabase.from('notification_config').upsert({
        'tenant_id': tenantId,
        'user_id': userId,
        ..._config!.toJson(),
      }, onConflict: 'tenant_id,user_id');

      ref.invalidate(notificationConfigProvider);

      if (mounted) {
        setState(() {
          _hasChanges = false;
          _isSaving = false;
        });
        ToastHelper.showSuccess(context, 'Einstellungen gespeichert');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ToastHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

  void _showTelegramInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telegram verbinden'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('So verbindest du Telegram:'),
            const SizedBox(height: 12),
            const Text('1. Öffne Telegram'),
            const SizedBox(height: 8),
            const Text('2. Suche nach @AttendixBot'),
            const SizedBox(height: 8),
            const Text('3. Starte den Bot mit /start'),
            const SizedBox(height: 8),
            const Text('4. Der Bot sendet dir deine Chat-ID'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Chat-ID eingeben',
                hintText: 'z.B. 123456789',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                Navigator.pop(context);
                _connectTelegram(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectTelegram(String chatId) async {
    if (chatId.trim().isEmpty) return;

    _updateConfig(_config!.copyWith(telegramChatId: chatId.trim()));
    await _saveConfig();
  }

  Future<void> _disconnectTelegram() async {
    setState(() {
      _config = NotificationConfig(
        enabled: _config!.enabled,
        telegramChatId: null,
        birthdays: _config!.birthdays,
        signins: _config!.signins,
        signouts: _config!.signouts,
        registrations: _config!.registrations,
        criticals: _config!.criticals,
        reminders: _config!.reminders,
        updates: _config!.updates,
        checklist: _config!.checklist,
      );
      _hasChanges = true;
    });
  }
}
