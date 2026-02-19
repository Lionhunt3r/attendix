import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/telegram_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/toast_helper.dart';

/// Notifications Page - Telegram connection and notification settings
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  NotificationConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = supabase.auth.currentUser;

      if (user != null) {
        final telegramService = ref.read(telegramServiceProvider);
        final config = await telegramService.getNotificationConfig(user.id);
        setState(() => _config = config);
      }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Benachrichtigungen')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Benachrichtigungen')),
        body: const Center(child: Text('Konfiguration nicht gefunden')),
      );
    }

    final isConnected = _config!.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benachrichtigungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          // Telegram connection card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.medium.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.telegram,
                          size: 32,
                          color: isConnected ? AppColors.success : AppColors.medium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Telegram',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isConnected ? 'Verbunden' : 'Nicht verbunden',
                              style: TextStyle(
                                color: isConnected ? AppColors.success : AppColors.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isConnected) ...[
                    const Text(
                      'Verbinde dein Telegram-Konto, um Benachrichtigungen zu erhalten.',
                      style: TextStyle(color: AppColors.medium),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _connectTelegram,
                        icon: const Icon(Icons.link),
                        label: const Text('Mit Telegram verbinden'),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Dein Telegram-Konto ist verbunden. Du erhältst Benachrichtigungen über den Attendix Bot.',
                      style: TextStyle(color: AppColors.medium),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _disconnectTelegram,
                        icon: const Icon(Icons.link_off, color: AppColors.danger),
                        label: const Text(
                          'Verbindung trennen',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Master switch
          Card(
            child: SwitchListTile(
              title: const Text('Benachrichtigungen aktiviert'),
              subtitle: const Text('Alle Telegram-Benachrichtigungen ein-/ausschalten'),
              value: _config!.enabled,
              onChanged: isConnected ? (v) => _updateConfig(_config!.copyWith(enabled: v)) : null,
            ),
          ),

          const SizedBox(height: 16),

          // Notification categories
          if (_config!.enabled && isConnected) ...[
            Text(
              'Benachrichtigungstypen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  _NotificationToggle(
                    title: 'Geburtstage',
                    subtitle: 'Benachrichtigung bei Geburtstagen',
                    icon: Icons.cake,
                    value: _config!.birthdays,
                    onChanged: (v) => _updateConfig(_config!.copyWith(birthdays: v)),
                  ),
                  const Divider(height: 1),
                  _NotificationToggle(
                    title: 'Anmeldungen',
                    subtitle: 'Wenn sich jemand anmeldet',
                    icon: Icons.login,
                    value: _config!.signins,
                    onChanged: (v) => _updateConfig(_config!.copyWith(signins: v)),
                  ),
                  const Divider(height: 1),
                  _NotificationToggle(
                    title: 'Abmeldungen',
                    subtitle: 'Wenn sich jemand abmeldet',
                    icon: Icons.logout,
                    value: _config!.signouts,
                    onChanged: (v) => _updateConfig(_config!.copyWith(signouts: v)),
                  ),
                  const Divider(height: 1),
                  _NotificationToggle(
                    title: 'Registrierungen',
                    subtitle: 'Neue Benutzer-Registrierungen',
                    icon: Icons.person_add,
                    value: _config!.registrations,
                    onChanged: (v) => _updateConfig(_config!.copyWith(registrations: v)),
                  ),
                  const Divider(height: 1),
                  _NotificationToggle(
                    title: 'Kritische Regelverletzungen',
                    subtitle: 'Bei wichtigen Verstößen',
                    icon: Icons.warning,
                    value: _config!.criticals,
                    onChanged: (v) => _updateConfig(_config!.copyWith(criticals: v)),
                  ),
                  const Divider(height: 1),
                  _NotificationToggle(
                    title: 'Erinnerungen',
                    subtitle: 'Termin-Erinnerungen',
                    icon: Icons.notifications,
                    value: _config!.reminders,
                    onChanged: (v) => _updateConfig(_config!.copyWith(reminders: v)),
                  ),
                  const Divider(height: 1),
                  _NotificationToggle(
                    title: 'Checklisten',
                    subtitle: 'Checklisten-Updates',
                    icon: Icons.checklist,
                    value: _config!.checklist,
                    onChanged: (v) => _updateConfig(_config!.copyWith(checklist: v)),
                  ),
                  const Divider(height: 1),
                  _NotificationToggle(
                    title: 'Updates',
                    subtitle: 'App- und System-Updates',
                    icon: Icons.system_update,
                    value: _config!.updates,
                    onChanged: (v) => _updateConfig(_config!.copyWith(updates: v)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _connectTelegram() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;

    if (user == null) {
      ToastHelper.showError(context, 'Nicht eingeloggt');
      return;
    }

    final telegramService = ref.read(telegramServiceProvider);
    final botLink = telegramService.getBotLink(user.id);

    final uri = Uri.parse(botLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Show info dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Telegram verbinden'),
            content: const Text(
              'Klicke im Telegram-Chat auf "Start", um die Verbindung abzuschließen. '
              'Die Seite wird automatisch aktualisiert, sobald die Verbindung hergestellt ist.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadConfig(); // Refresh
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ToastHelper.showError(context, 'Konnte Telegram nicht öffnen');
      }
    }
  }

  Future<void> _disconnectTelegram() async {
    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Verbindung trennen',
      message: 'Möchtest du die Telegram-Verbindung wirklich trennen? '
          'Die Verbindung kann jederzeit wiederhergestellt werden.',
      confirmText: 'Trennen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    try {
      final telegramService = ref.read(telegramServiceProvider);
      await telegramService.disconnectTelegram(_config!.id);

      setState(() {
        _config = _config!.copyWith(telegramChatId: '');
      });

      if (mounted) {
        ToastHelper.showSuccess(context, 'Verbindung getrennt');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  Future<void> _updateConfig(NotificationConfig newConfig) async {
    setState(() => _config = newConfig);

    try {
      final telegramService = ref.read(telegramServiceProvider);
      await telegramService.updateNotificationConfig(newConfig);
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }
}

class _NotificationToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
