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
import '../../../../core/providers/tenant_providers.dart';
import '../../../../data/models/tenant/tenant.dart';

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
  bool _showMembersList = false;

  // Sharing
  bool _songSharingEnabled = false;
  String? _songSharingId;
  bool _registrationEnabled = false;
  String? _registerId;
  bool _autoApproveRegistrations = false;

  // Extra fields
  List<ExtraField> _extraFields = [];

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
      _showMembersList = tenant.showMembersList;
      _songSharingEnabled = tenant.songSharingId != null && tenant.songSharingId!.isNotEmpty;
      _songSharingId = tenant.songSharingId;
      _registrationEnabled = tenant.registerId != null && tenant.registerId!.isNotEmpty;
      _registerId = tenant.registerId;
      _autoApproveRegistrations = tenant.autoApproveRegistrations;
      _extraFields = List.from(tenant.additionalFields ?? []);

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
        'show_members_list': _showMembersList,
        'song_sharing_id': _songSharingEnabled ? (_songSharingId ?? const Uuid().v4()) : null,
        'register_id': _registrationEnabled ? (_registerId ?? const Uuid().v4()) : null,
        'auto_approve_registrations': _autoApproveRegistrations,
        'additional_fields': _extraFields.map((f) => {
          'id': f.id,
          'name': f.name,
          'type': f.type,
          'defaultValue': f.defaultValue,
          if (f.options != null) 'options': f.options,
        }).toList(),
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mitgliederliste für alle'),
                    subtitle: const Text('Aktivieren, um Mitgliedern (Spieler, Helfer, Stimmführer) eine Übersicht aller Personen anzuzeigen'),
                    value: _showMembersList,
                    onChanged: (v) {
                      setState(() => _showMembersList = v);
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

                  // Extra fields section
                  _buildSectionHeader('Zusatzfelder für Personen'),
                  Text(
                    'Definiere zusätzliche Felder für Personendaten.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.medium,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // List of extra fields
                  if (_extraFields.isNotEmpty) ...[
                    ...List.generate(_extraFields.length, (index) {
                      final field = _extraFields[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                        child: ListTile(
                          leading: Icon(_getFieldTypeIcon(field.type)),
                          title: Text(field.name),
                          subtitle: Text(
                            field.type == 'select' && field.options != null
                                ? '${_getFieldTypeLabel(field.type)} (${field.options!.length} Optionen)'
                                : _getFieldTypeLabel(field.type),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditExtraFieldDialog(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.danger),
                                onPressed: () => _confirmDeleteExtraField(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  // Add field button
                  OutlinedButton.icon(
                    onPressed: _showAddExtraFieldDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Feld hinzufügen'),
                  ),

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

  // Extra field helper methods
  IconData _getFieldTypeIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'textarea':
        return Icons.notes;
      case 'number':
        return Icons.numbers;
      case 'date':
        return Icons.calendar_today;
      case 'boolean':
        return Icons.toggle_on;
      case 'select':
        return Icons.list;
      default:
        return Icons.text_fields;
    }
  }

  String _getFieldTypeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Text';
      case 'textarea':
        return 'Mehrzeiliger Text';
      case 'number':
        return 'Zahl';
      case 'date':
        return 'Datum';
      case 'boolean':
        return 'Ja/Nein';
      case 'select':
        return 'Auswahl';
      default:
        return type;
    }
  }

  String _generateFieldId(String name) {
    return name.trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  Future<void> _showAddExtraFieldDialog() async {
    String selectedType = 'text';
    final nameController = TextEditingController();
    List<String> options = [];
    final optionController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppDimensions.paddingM,
            right: AppDimensions.paddingM,
            top: AppDimensions.paddingM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Neues Zusatzfeld',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Type selector
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Feldtyp',
                ),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'textarea', child: Text('Mehrzeiliger Text')),
                  DropdownMenuItem(value: 'number', child: Text('Zahl')),
                  DropdownMenuItem(value: 'date', child: Text('Datum')),
                  DropdownMenuItem(value: 'boolean', child: Text('Ja/Nein')),
                  DropdownMenuItem(value: 'select', child: Text('Auswahl')),
                ],
                onChanged: (v) {
                  setSheetState(() {
                    selectedType = v ?? 'text';
                    options = [];
                  });
                },
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Name input
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Feldname *',
                  hintText: 'z.B. Mitgliedsnummer',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Options for select type
              if (selectedType == 'select') ...[
                Text(
                  'Optionen',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ...options.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.paddingXS),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.value)),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () {
                          setSheetState(() => options.removeAt(entry.key));
                        },
                      ),
                    ],
                  ),
                )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: optionController,
                        decoration: const InputDecoration(
                          hintText: 'Neue Option',
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setSheetState(() {
                              options.add(value.trim());
                              optionController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (optionController.text.trim().isNotEmpty) {
                          setSheetState(() {
                            options.add(optionController.text.trim());
                            optionController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ToastHelper.showError(ctx, 'Bitte gib einen Namen ein');
                      return;
                    }

                    final id = _generateFieldId(name);
                    if (_extraFields.any((f) => f.id == id)) {
                      ToastHelper.showError(ctx, 'Ein Feld mit dieser ID existiert bereits');
                      return;
                    }

                    if (selectedType == 'select' && options.isEmpty) {
                      ToastHelper.showError(ctx, 'Bitte füge mindestens eine Option hinzu');
                      return;
                    }

                    dynamic defaultValue;
                    switch (selectedType) {
                      case 'text':
                      case 'textarea':
                        defaultValue = '';
                        break;
                      case 'number':
                        defaultValue = 0;
                        break;
                      case 'boolean':
                        defaultValue = false;
                        break;
                      case 'date':
                        defaultValue = DateTime.now().toIso8601String().split('T')[0];
                        break;
                      case 'select':
                        // Safe access with guard (Issue #7)
                        defaultValue = options.isNotEmpty ? options.first : '';
                        break;
                    }

                    setState(() {
                      _extraFields.add(ExtraField(
                        id: id,
                        name: name,
                        type: selectedType,
                        defaultValue: defaultValue,
                        options: selectedType == 'select' ? options : null,
                      ));
                      _markChanged();
                    });

                    Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ToastHelper.showSuccess(context, 'Feld hinzugefügt');
                    }
                  },
                  child: const Text('Feld hinzufügen'),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditExtraFieldDialog(int index) async {
    final field = _extraFields[index];
    final nameController = TextEditingController(text: field.name);
    List<String> options = List.from(field.options ?? []);
    final optionController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: AppDimensions.paddingM,
            right: AppDimensions.paddingM,
            top: AppDimensions.paddingM,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zusatzfeld bearbeiten',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Type (read-only)
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Feldtyp',
                ),
                child: Row(
                  children: [
                    Icon(_getFieldTypeIcon(field.type), size: 20),
                    const SizedBox(width: AppDimensions.paddingS),
                    Text(_getFieldTypeLabel(field.type)),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Name input
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Feldname *',
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Options for select type
              if (field.type == 'select') ...[
                Text(
                  'Optionen',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ...options.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.paddingXS),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.value)),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: options.length > 1 ? () {
                          setSheetState(() => options.removeAt(entry.key));
                        } : null,
                      ),
                    ],
                  ),
                )),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: optionController,
                        decoration: const InputDecoration(
                          hintText: 'Neue Option',
                          isDense: true,
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            setSheetState(() {
                              options.add(value.trim());
                              optionController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (optionController.text.trim().isNotEmpty) {
                          setSheetState(() {
                            options.add(optionController.text.trim());
                            optionController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ToastHelper.showError(ctx, 'Bitte gib einen Namen ein');
                      return;
                    }

                    if (field.type == 'select' && options.isEmpty) {
                      ToastHelper.showError(ctx, 'Mindestens eine Option erforderlich');
                      return;
                    }

                    setState(() {
                      _extraFields[index] = ExtraField(
                        id: field.id, // Keep original ID
                        name: name,
                        type: field.type,
                        // Safe access with guard (Issue #7)
                        defaultValue: field.type == 'select' && options.isNotEmpty
                            ? options.first
                            : field.defaultValue,
                        options: field.type == 'select' ? options : null,
                      );
                      _markChanged();
                    });

                    Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ToastHelper.showSuccess(context, 'Feld aktualisiert');
                    }
                  },
                  child: const Text('Speichern'),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteExtraField(int index) async {
    final field = _extraFields[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zusatzfeld löschen?'),
        content: Text('Möchtest du das Feld "${field.name}" wirklich löschen? '
            'Die Werte dieses Feldes werden bei allen Personen entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _extraFields.removeAt(index);
        _markChanged();
      });
      if (mounted) {
        ToastHelper.showSuccess(context, 'Feld gelöscht');
      }
    }
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
