import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/player_providers.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/person/person.dart';
import '../../../../data/services/auth_service.dart';

/// Page for batch creating accounts for players without accounts
class BatchAccountCreationPage extends ConsumerStatefulWidget {
  const BatchAccountCreationPage({super.key});

  @override
  ConsumerState<BatchAccountCreationPage> createState() =>
      _BatchAccountCreationPageState();
}

class _BatchAccountCreationPageState
    extends ConsumerState<BatchAccountCreationPage> {
  bool _isRunning = false;
  int _processed = 0;
  int _total = 0;
  int _succeeded = 0;
  int _failed = 0;
  final List<String> _errors = [];

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts erstellen'),
      ),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (players) {
          final eligible = players
              .where((p) =>
                  (p.appId == null || p.appId!.isEmpty) &&
                  p.email != null &&
                  p.email!.isNotEmpty)
              .toList();

          final noEmail = players
              .where((p) =>
                  (p.appId == null || p.appId!.isEmpty) &&
                  (p.email == null || p.email!.isEmpty))
              .toList();

          final withAccount = players
              .where((p) => p.appId != null && p.appId!.isNotEmpty)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Übersicht',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        icon: Icons.check_circle,
                        color: AppColors.success,
                        label: 'Mit Account',
                        count: withAccount.length,
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        icon: Icons.person_add,
                        color: AppColors.primary,
                        label: 'Account erstellbar (mit E-Mail)',
                        count: eligible.length,
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        icon: Icons.warning,
                        color: AppColors.warning,
                        label: 'Ohne E-Mail (manuell nötig)',
                        count: noEmail.length,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Progress indicator when running
              if (_isRunning) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _total > 0 ? _processed / _total : 0,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_processed / $_total verarbeitet',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_succeeded > 0 || _failed > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: AppColors.success, size: 16),
                              const SizedBox(width: 4),
                              Text('$_succeeded erfolgreich'),
                              const SizedBox(width: 16),
                              Icon(Icons.close, color: AppColors.danger, size: 16),
                              const SizedBox(width: 4),
                              Text('$_failed fehlgeschlagen'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Results after completion
              if (!_isRunning && _errors.isNotEmpty) ...[
                Card(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fehler',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_errors.map((e) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Eligible players list
              if (eligible.isNotEmpty) ...[
                Text(
                  'Spieler ohne Account (${eligible.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: eligible.asMap().entries.map((entry) {
                      final index = entry.key;
                      final player = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const Divider(height: 1),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                _getInitials(player),
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              '${player.firstName} ${player.lastName}',
                            ),
                            subtitle: Text(
                              player.email ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRunning
                        ? null
                        : () => _confirmAndCreateAccounts(eligible),
                    icon: const Icon(Icons.person_add),
                    label: Text(
                        'Accounts für ${eligible.length} Spieler erstellen'),
                  ),
                ),
              ],

              if (eligible.isEmpty && !_isRunning) ...[
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: AppColors.success),
                      const SizedBox(height: 16),
                      Text(
                        'Alle Spieler mit E-Mail haben bereits einen Account.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.medium),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _getInitials(Person player) {
    final first = player.firstName.isNotEmpty ? player.firstName[0] : '';
    final last = player.lastName.isNotEmpty ? player.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  Future<void> _confirmAndCreateAccounts(List<Person> players) async {
    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Accounts erstellen',
      message: 'Für ${players.length} Spieler werden Accounts erstellt. '
          'Jeder Spieler erhält eine E-Mail zum Setzen des Passworts.',
      confirmText: 'Erstellen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed || !mounted) return;
    await _createAccounts(players);
  }

  Future<void> _createAccounts(List<Person> players) async {
    final tenantId = ref.read(currentTenantIdProvider);
    if (tenantId == null) return;

    setState(() {
      _isRunning = true;
      _processed = 0;
      _total = players.length;
      _succeeded = 0;
      _failed = 0;
      _errors.clear();
    });

    final authService = ref.read(authServiceProvider);

    for (final player in players) {
      try {
        await authService.createAccountForPerson(
          person: player,
          role: Role.player,
          tenantId: tenantId,
        );
        if (mounted) {
          setState(() {
            _succeeded++;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _failed++;
            _errors.add(
                '${player.firstName} ${player.lastName}: $e');
          });
        }
      }
      if (mounted) {
        setState(() => _processed++);
      }
    }

    // Refresh player list
    ref.invalidate(playersProvider);

    if (mounted) {
      setState(() => _isRunning = false);
      if (_failed == 0) {
        ToastHelper.showSuccess(
            context, '$_succeeded Accounts erfolgreich erstellt');
      } else {
        ToastHelper.showError(
            context, '$_succeeded erstellt, $_failed fehlgeschlagen');
      }
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          '$count',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
