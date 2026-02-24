import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/providers/player_providers.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/instrument/instrument.dart';
import '../../../../data/models/person/person.dart';
import '../../../../data/models/tenant/tenant.dart';

/// Sheet for transferring players to another tenant (handover)
class HandoverSheet extends ConsumerStatefulWidget {
  final List<Person> selectedPlayers;

  const HandoverSheet({
    super.key,
    required this.selectedPlayers,
  });

  @override
  ConsumerState<HandoverSheet> createState() => _HandoverSheetState();
}

class _HandoverSheetState extends ConsumerState<HandoverSheet> {
  int? _targetTenantId;
  bool _stayInInstance = false; // false = transfer, true = copy
  bool _isTransferring = false;
  String _progressMessage = '';
  Map<int, int?> _groupMapping = {};
  List<Group> _targetGroups = [];

  @override
  Widget build(BuildContext context) {
    final tenantsAsync = ref.watch(userTenantsProvider);
    final currentTenant = ref.watch(currentTenantProvider);
    final sourceGroupsAsync = ref.watch(groupsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            AppBar(
              title: Text(
                _stayInInstance ? 'Spieler kopieren' : 'Spieler übertragen',
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              automaticallyImplyLeading: false,
            ),

            // Content
            Expanded(
              child: tenantsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Fehler: $e')),
                data: (tenants) {
                  // Filter out current tenant
                  final availableTenants = tenants
                      .where((t) => t.id != currentTenant?.id)
                      .toList();

                  if (availableTenants.isEmpty) {
                    return _buildNoTenantsMessage();
                  }

                  // Initialize target tenant if not set (using addPostFrameCallback to avoid setState during build)
                  if (_targetTenantId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _targetTenantId == null) {
                        setState(() {
                          _targetTenantId = availableTenants.first.id;
                        });
                        _loadTargetGroups();
                      }
                    });
                  }

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    children: [
                      // Players summary
                      _buildPlayersSummary(),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Mode toggle (copy vs transfer)
                      _buildModeToggle(),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Target tenant dropdown
                      _buildTargetTenantDropdown(availableTenants),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Group mapping section
                      if (_targetTenantId != null)
                        _buildGroupMappingSection(
                          sourceGroupsAsync.valueOrNull ?? [],
                        ),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Info card
                      _buildInfoCard(),
                      const SizedBox(height: AppDimensions.paddingM),

                      // Progress indicator
                      if (_isTransferring) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: AppDimensions.paddingS),
                        Center(
                          child: Text(
                            _progressMessage,
                            style: const TextStyle(color: AppColors.medium),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                      ],

                      // Transfer button
                      ElevatedButton.icon(
                        onPressed: _isTransferring
                            ? null
                            : () => _performHandover(currentTenant),
                        icon: _isTransferring
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_stayInInstance
                                ? Icons.copy
                                : Icons.swap_horiz),
                        label: Text(_isTransferring
                            ? 'Wird übertragen...'
                            : _stayInInstance
                                ? 'Kopieren'
                                : 'Übertragen'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor:
                              _stayInInstance ? null : AppColors.warning,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoTenantsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_outlined,
                size: 64, color: AppColors.medium),
            const SizedBox(height: AppDimensions.paddingM),
            const Text(
              'Keine anderen Instanzen verfügbar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Du hast nur Zugriff auf eine Instanz. '
              'Um Spieler zu übertragen, benötigst du Zugriff auf mindestens zwei Instanzen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.medium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: AppColors.primary),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  '${widget.selectedPlayers.length} Spieler ausgewählt',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Wrap(
              spacing: AppDimensions.paddingS,
              runSpacing: AppDimensions.paddingXS,
              children: widget.selectedPlayers.take(10).map((p) {
                return Chip(
                  label: Text(p.fullName),
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(50),
                    child: Text(
                      p.initials,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (widget.selectedPlayers.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.paddingS),
                child: Text(
                  '... und ${widget.selectedPlayers.length - 10} weitere',
                  style: const TextStyle(color: AppColors.medium),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modus',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.medium,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Spieler in dieser Instanz behalten'),
              subtitle: Text(
                _stayInInstance
                    ? 'Spieler werden kopiert (bleiben hier aktiv)'
                    : 'Spieler werden übertragen (hier archiviert)',
                style: TextStyle(
                  color: _stayInInstance ? AppColors.success : AppColors.warning,
                ),
              ),
              value: _stayInInstance,
              onChanged: _isTransferring
                  ? null
                  : (value) {
                      setState(() => _stayInInstance = value);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetTenantDropdown(List<Tenant> tenants) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ziel-Instanz',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.medium,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            DropdownButtonFormField<int>(
              value: _targetTenantId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.business),
              ),
              items: tenants
                  .map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.longName),
                      ))
                  .toList(),
              onChanged: _isTransferring
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _targetTenantId = value;
                          _groupMapping.clear();
                          _targetGroups = [];
                        });
                        _loadTargetGroups();
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupMappingSection(List<Group> sourceGroups) {
    // Get unique instrument IDs from selected players
    final instrumentIds = widget.selectedPlayers
        .map((p) => p.instrument)
        .where((id) => id != null)
        .cast<int>()
        .toSet();

    if (instrumentIds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Load target groups if not loaded
    if (_targetGroups.isEmpty && _targetTenantId != null) {
      _loadTargetGroups();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gruppen-Zuordnung',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.medium,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            const Text(
              'Ordne die Gruppen der Quell-Instanz den Gruppen der Ziel-Instanz zu:',
              style: TextStyle(color: AppColors.medium, fontSize: 12),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            ...instrumentIds.map((instrumentId) {
              final sourceGroup = sourceGroups.firstWhere(
                (g) => g.id == instrumentId,
                orElse: () => Group(id: instrumentId, name: 'Unbekannt'),
              );

              // Auto-map if not already mapped
              if (!_groupMapping.containsKey(instrumentId)) {
                _groupMapping[instrumentId] = _autoMapGroup(
                  sourceGroup,
                  _targetGroups,
                );
              }

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        sourceGroup.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: AppColors.medium),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _groupMapping[instrumentId],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('-- Nicht zuordnen --'),
                          ),
                          ..._targetGroups.map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name),
                              )),
                        ],
                        onChanged: _isTransferring
                            ? null
                            : (value) {
                                setState(() {
                                  _groupMapping[instrumentId] = value;
                                });
                              },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: (_stayInInstance ? AppColors.info : AppColors.warning)
          .withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _stayInInstance ? Icons.info_outline : Icons.warning_amber,
                  color: _stayInInstance ? AppColors.info : AppColors.warning,
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  _stayInInstance ? 'Hinweis' : 'Achtung',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        _stayInInstance ? AppColors.info : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              _stayInInstance
                  ? 'Die ausgewählten Spieler werden in die Ziel-Instanz kopiert. '
                      'Sie bleiben in dieser Instanz aktiv. '
                      'Der App-Zugang muss in der Ziel-Instanz neu verknüpft werden.'
                  : 'Die ausgewählten Spieler werden in die Ziel-Instanz übertragen. '
                      'Sie werden in dieser Instanz archiviert und der App-Zugang wird getrennt. '
                      'Dieser Vorgang kann nicht rückgängig gemacht werden.',
              style: const TextStyle(color: AppColors.medium),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTargetGroups() async {
    if (_targetTenantId == null) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase
          .from('instruments')
          .select('*')
          .eq('tenantId', _targetTenantId!);

      if (!mounted) return;

      setState(() {
        _targetGroups = (response as List)
            .map((g) => Group.fromJson(g as Map<String, dynamic>))
            .toList();

        // Re-auto-map all groups
        final sourceGroups = ref.read(groupsProvider).valueOrNull ?? [];
        final instrumentIds = widget.selectedPlayers
            .map((p) => p.instrument)
            .where((id) => id != null)
            .cast<int>()
            .toSet();

        for (final instrumentId in instrumentIds) {
          final sourceGroup = sourceGroups.firstWhere(
            (g) => g.id == instrumentId,
            orElse: () => Group(id: instrumentId, name: 'Unbekannt'),
          );
          _groupMapping[instrumentId] = _autoMapGroup(sourceGroup, _targetGroups);
        }
      });
    } catch (e) {
      debugPrint('Error loading target groups: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Laden der Gruppen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int? _autoMapGroup(Group sourceGroup, List<Group> targetGroups) {
    if (targetGroups.isEmpty) return null;

    // Exact name match (case-insensitive)
    for (final target in targetGroups) {
      if (target.name.toLowerCase() == sourceGroup.name.toLowerCase()) {
        return target.id;
      }
    }

    // Partial match
    for (final target in targetGroups) {
      if (target.name.toLowerCase().contains(sourceGroup.name.toLowerCase()) ||
          sourceGroup.name.toLowerCase().contains(target.name.toLowerCase())) {
        return target.id;
      }
    }

    return null;
  }

  Future<void> _performHandover(Tenant? currentTenant) async {
    if (_targetTenantId == null || currentTenant == null) return;

    setState(() {
      _isTransferring = true;
      _progressMessage = 'Bereite Übertragung vor...';
    });

    try {
      final playerRepo = ref.read(playerRepositoryWithTenantProvider);
      final tenants = ref.read(userTenantsProvider).valueOrNull ?? [];
      final targetTenant = tenants.firstWhere(
        (t) => t.id == _targetTenantId,
        orElse: () => Tenant(id: _targetTenantId, longName: '', shortName: ''),
      );

      final results = await playerRepo.handoverPlayers(
        players: widget.selectedPlayers,
        targetTenantId: _targetTenantId!,
        groupMapping: _groupMapping,
        targetTenantName: targetTenant.longName,
        sourceTenantName: currentTenant.longName,
        stayInInstance: _stayInInstance,
        onProgress: (current, total, name) {
          if (mounted) {
            setState(() {
              _progressMessage = 'Übertrage $name ($current/$total)...';
            });
          }
        },
      );

      // Invalidate players provider to refresh list
      ref.invalidate(playersProvider);

      if (mounted) {
        final action = _stayInInstance ? 'kopiert' : 'übertragen';
        if (results['error']! > 0 || results['duplicate']! > 0) {
          ToastHelper.showWarning(
            context,
            '${results['success']} $action, '
            '${results['duplicate']} bereits vorhanden, '
            '${results['error']} fehlgeschlagen',
          );
        } else {
          ToastHelper.showSuccess(
            context,
            '${results['success']} Spieler erfolgreich $action',
          );
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }
}

/// Shows the handover sheet
Future<bool?> showHandoverSheet(
  BuildContext context, {
  required List<Person> selectedPlayers,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => HandoverSheet(selectedPlayers: selectedPlayers),
  );
}
