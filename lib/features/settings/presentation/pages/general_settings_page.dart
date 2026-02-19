import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../tenant_selection/presentation/pages/tenant_selection_page.dart';

/// German holiday regions
const _holidayRegions = [
  ('', 'Keine Feiertage'),
  ('BW', 'Baden-Württemberg'),
  ('BY', 'Bayern'),
  ('BE', 'Berlin'),
  ('BB', 'Brandenburg'),
  ('HB', 'Bremen'),
  ('HH', 'Hamburg'),
  ('HE', 'Hessen'),
  ('MV', 'Mecklenburg-Vorpommern'),
  ('NI', 'Niedersachsen'),
  ('NW', 'Nordrhein-Westfalen'),
  ('RP', 'Rheinland-Pfalz'),
  ('SL', 'Saarland'),
  ('SN', 'Sachsen'),
  ('ST', 'Sachsen-Anhalt'),
  ('SH', 'Schleswig-Holstein'),
  ('TH', 'Thüringen'),
];

/// General Settings Page
class GeneralSettingsPage extends ConsumerStatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  ConsumerState<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends ConsumerState<GeneralSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  final _shortNameController = TextEditingController();
  final _longNameController = TextEditingController();

  // Times
  final _practiceStartController = TextEditingController();
  final _practiceEndController = TextEditingController();

  // Settings
  DateTime? _seasonStart;
  String _selectedRegion = '';
  bool _maintainTeachers = false;
  bool _withExcuses = true;
  bool _parents = false;

  // Sharing
  bool _songSharingEnabled = false;
  String? _songSharingId;
  bool _registrationEnabled = false;
  String? _registerId;
  bool _autoApproveRegistrations = false;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _shortNameController.dispose();
    _longNameController.dispose();
    _practiceStartController.dispose();
    _practiceEndController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final tenant = ref.read(currentTenantProvider);
      if (tenant == null) {
        throw Exception('Kein Tenant ausgewählt');
      }

      _shortNameController.text = tenant.shortName;
      _longNameController.text = tenant.longName;
      _practiceStartController.text = tenant.practiceStart ?? '';
      _practiceEndController.text = tenant.practiceEnd ?? '';
      _seasonStart = tenant.seasonStart != null ? DateTime.tryParse(tenant.seasonStart!) : null;
      _selectedRegion = tenant.region ?? '';
      _maintainTeachers = tenant.maintainTeachers;
      _withExcuses = tenant.withExcuses;
      _parents = tenant.parents ?? false;
      _songSharingEnabled = tenant.songSharingId != null && tenant.songSharingId!.isNotEmpty;
      _songSharingId = tenant.songSharingId;
      _registrationEnabled = tenant.registerId != null && tenant.registerId!.isNotEmpty;
      _registerId = tenant.registerId;
      _autoApproveRegistrations = tenant.autoApproveRegistrations;

    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Laden: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);

      if (tenant?.id == null) {
        throw Exception('Kein Tenant ausgewählt');
      }

      await supabase.from('tenants').update({
        'shortName': _shortNameController.text.trim(),
        'longName': _longNameController.text.trim(),
        'practiceStart': _practiceStartController.text.trim().isNotEmpty
            ? _practiceStartController.text.trim() : null,
        'practiceEnd': _practiceEndController.text.trim().isNotEmpty
            ? _practiceEndController.text.trim() : null,
        'seasonStart': _seasonStart?.toIso8601String().split('T')[0],
        'region': _selectedRegion.isNotEmpty ? _selectedRegion : null,
        'maintainTeachers': _maintainTeachers,
        'withExcuses': _withExcuses,
        'parents': _parents,
        'song_sharing_id': _songSharingEnabled ? (_songSharingId ?? const Uuid().v4()) : null,
        'register_id': _registrationEnabled ? (_registerId ?? const Uuid().v4()) : null,
        'auto_approve_registrations': _autoApproveRegistrations,
      }).eq('id', tenant!.id!);

      // Refresh tenant data
      ref.invalidate(currentTenantProvider);
      ref.invalidate(userTenantsProvider);

      if (mounted) {
        ToastHelper.showSuccess(context, 'Einstellungen gespeichert');
        setState(() => _hasChanges = false);
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

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _selectSeasonStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _seasonStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('de', 'DE'),
    );
    if (picked != null) {
      setState(() {
        _seasonStart = picked;
        _markChanged();
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final initialTime = _parseTime(controller.text) ?? const TimeOfDay(hour: 19, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _markChanged();
    }
  }

  TimeOfDay? _parseTime(String time) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _copyLink(String baseUrl, String? id) async {
    if (id == null) return;
    final link = '$baseUrl$id';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ToastHelper.showSuccess(context, 'Link kopiert');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allgemeine Einstellungen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_hasChanges) {
              _showUnsavedChangesDialog();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Speichern'),
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
                  // Basic info section
                  _buildSectionHeader('Grunddaten'),
                  TextFormField(
                    controller: _shortNameController,
                    decoration: const InputDecoration(
                      labelText: 'Kurzname *',
                      helperText: 'Wird in der Navigation angezeigt',
                    ),
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Erforderlich' : null,
                    onChanged: (_) => _markChanged(),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  TextFormField(
                    controller: _longNameController,
                    decoration: const InputDecoration(
                      labelText: 'Vollständiger Name',
                    ),
                    onChanged: (_) => _markChanged(),
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Season section
                  _buildSectionHeader('Saison'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Saisonstart'),
                    subtitle: Text(
                      _seasonStart != null
                          ? DateFormat('dd.MM.yyyy').format(_seasonStart!)
                          : 'Nicht festgelegt',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectSeasonStart,
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Practice times section
                  _buildSectionHeader('Probenzeiten'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _practiceStartController,
                          decoration: const InputDecoration(
                            labelText: 'Beginn',
                            hintText: '19:00',
                          ),
                          readOnly: true,
                          onTap: () => _selectTime(_practiceStartController),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: TextFormField(
                          controller: _practiceEndController,
                          decoration: const InputDecoration(
                            labelText: 'Ende',
                            hintText: '21:30',
                          ),
                          readOnly: true,
                          onTap: () => _selectTime(_practiceEndController),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Holidays section
                  _buildSectionHeader('Feiertage'),
                  DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    decoration: const InputDecoration(
                      labelText: 'Bundesland',
                    ),
                    items: _holidayRegions.map((r) => DropdownMenuItem(
                      value: r.$1,
                      child: Text(r.$2),
                    )).toList(),
                    onChanged: (v) {
                      setState(() => _selectedRegion = v ?? '');
                      _markChanged();
                    },
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Features section
                  _buildSectionHeader('Funktionen'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Entschuldigungen'),
                    subtitle: const Text('Erlaubt "Entschuldigt" als Status'),
                    value: _withExcuses,
                    onChanged: (v) {
                      setState(() => _withExcuses = v);
                      _markChanged();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dirigenten verwalten'),
                    subtitle: const Text('Separate Dirigenten-Liste führen'),
                    value: _maintainTeachers,
                    onChanged: (v) {
                      setState(() => _maintainTeachers = v);
                      _markChanged();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Eltern-Modus'),
                    subtitle: const Text('Erlaubt Eltern ihre Kinder an-/abzumelden'),
                    value: _parents,
                    onChanged: (v) {
                      setState(() => _parents = v);
                      _markChanged();
                    },
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Song sharing section
                  _buildSectionHeader('Lied-Teilen'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktiviert'),
                    subtitle: const Text('Lieder öffentlich über Link teilen'),
                    value: _songSharingEnabled,
                    onChanged: (v) {
                      setState(() {
                        _songSharingEnabled = v;
                        if (v && _songSharingId == null) {
                          _songSharingId = const Uuid().v4();
                        }
                      });
                      _markChanged();
                    },
                  ),
                  if (_songSharingEnabled && _songSharingId != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sharing-Link'),
                      subtitle: Text(
                        'https://attendix.de/songs/$_songSharingId',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyLink('https://attendix.de/songs/', _songSharingId),
                      ),
                    ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Self-registration section
                  _buildSectionHeader('Selbst-Registrierung'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktiviert'),
                    subtitle: const Text('Neue Mitglieder können sich selbst registrieren'),
                    value: _registrationEnabled,
                    onChanged: (v) {
                      setState(() {
                        _registrationEnabled = v;
                        if (v && _registerId == null) {
                          _registerId = const Uuid().v4();
                        }
                      });
                      _markChanged();
                    },
                  ),
                  if (_registrationEnabled) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Registrierungs-Link'),
                      subtitle: Text(
                        'https://attendix.de/register/$_registerId',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () => _copyLink('https://attendix.de/register/', _registerId),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Automatisch genehmigen'),
                      subtitle: const Text('Neue Registrierungen sofort freischalten'),
                      value: _autoApproveRegistrations,
                      onChanged: (v) {
                        setState(() => _autoApproveRegistrations = v);
                        _markChanged();
                      },
                    ),
                  ],

                  const SizedBox(height: AppDimensions.paddingXL),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ungespeicherte Änderungen'),
        content: const Text('Möchtest du die Änderungen verwerfen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      context.pop();
    }
  }
}
