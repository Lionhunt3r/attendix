import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/attendance_type_providers.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/attendance/attendance.dart';

/// Local provider for a single attendance type (with tenant filtering)
final _attendanceTypeByIdProvider = FutureProvider.family<AttendanceType?, String>((ref, id) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);

  if (tenantId == null) return null;

  final response = await supabase
      .from('attendance_types')
      .select()
      .eq('id', id)
      .eq('tenant_id', tenantId)
      .maybeSingle();

  if (response == null) return null;
  return AttendanceType.fromJson(response);
});

/// Attendance Type Edit Page
///
/// Edit an existing attendance type or create a new one.
class AttendanceTypeEditPage extends ConsumerStatefulWidget {
  final String typeId;

  const AttendanceTypeEditPage({
    super.key,
    required this.typeId,
  });

  @override
  ConsumerState<AttendanceTypeEditPage> createState() => _AttendanceTypeEditPageState();
}

class _AttendanceTypeEditPageState extends ConsumerState<AttendanceTypeEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  AttendanceStatus _defaultStatus = AttendanceStatus.present;
  Set<AttendanceStatus> _availableStatuses = {
    AttendanceStatus.neutral,
    AttendanceStatus.present,
    AttendanceStatus.absent,
    AttendanceStatus.excused,
    AttendanceStatus.late,
  };
  bool _manageSongs = false;
  bool _visible = true;
  bool _highlight = false;
  bool _hideName = false;
  bool _includeInAverage = true;
  String _color = 'primary';

  bool _isLoading = true;
  bool _hasChanges = false;
  AttendanceType? _originalType;

  @override
  void initState() {
    super.initState();
    _loadType();
  }

  Future<void> _loadType() async {
    final type = await ref.read(_attendanceTypeByIdProvider(widget.typeId).future);

    if (type != null && mounted) {
      setState(() {
        _originalType = type;
        _nameController.text = type.name;
        _startTimeController.text = type.startTime ?? '19:00';
        _endTimeController.text = type.endTime ?? '20:30';

        // Load available statuses with fallback
        _availableStatuses = type.availableStatuses?.isNotEmpty == true
            ? Set.from(type.availableStatuses!)
            : {AttendanceStatus.present};

        // Validate defaultStatus is in availableStatuses (Issue #5)
        if (_availableStatuses.contains(type.defaultStatus)) {
          _defaultStatus = type.defaultStatus;
        } else if (_availableStatuses.isNotEmpty) {
          _defaultStatus = _availableStatuses.first;
        } else {
          // Fallback: ensure at least one status exists
          _availableStatuses = {AttendanceStatus.present};
          _defaultStatus = AttendanceStatus.present;
        }

        _manageSongs = type.manageSongs;
        _visible = type.visible;
        _highlight = type.highlight;
        _hideName = type.hideName;
        _includeInAverage = type.includeInAverage;
        _color = type.color ?? 'primary';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Anwesenheitstyp')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_originalType == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Anwesenheitstyp')),
        body: const Center(child: Text('Typ nicht gefunden')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_originalType!.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Löschen',
            onPressed: _deleteType,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() => _hasChanges = true),
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'z.B. Probe, Konzert',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte einen Namen eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Color Picker
            _buildSection(
              title: 'Farbe',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ColorUtils.availableColors.map((colorName) {
                  final color = ColorUtils.getColorForPicker(colorName);
                  final isSelected = _color == colorName;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _color = colorName;
                      _hasChanges = true;
                    }),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Time Settings
            _buildSection(
              title: 'Zeiten',
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Beginn',
                        hintText: '19:00',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Ende',
                        hintText: '20:30',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Default Status
            _buildSection(
              title: 'Standard-Status',
              child: DropdownButtonFormField<AttendanceStatus>(
                value: _availableStatuses.contains(_defaultStatus)
                    ? _defaultStatus
                    : _availableStatuses.firstOrNull ?? AttendanceStatus.present,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _defaultStatus = value;
                      _hasChanges = true;
                    });
                  }
                },
                items: _availableStatuses
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(_getStatusName(status)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Available Statuses
            _buildSection(
              title: 'Verfügbare Status',
              child: Column(
                children: AttendanceStatus.values.map((status) {
                  return CheckboxListTile(
                    title: Text(_getStatusName(status)),
                    value: _availableStatuses.contains(status),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _availableStatuses.add(status);
                        } else {
                          // Don't allow removing last status
                          if (_availableStatuses.length > 1) {
                            _availableStatuses.remove(status);
                            // Reset default if removed (Issue #21 - safe .first)
                            if (_defaultStatus == status) {
                              _defaultStatus = _availableStatuses.firstOrNull ?? AttendanceStatus.present;
                            }
                          }
                        }
                        _hasChanges = true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Options
            _buildSection(
              title: 'Optionen',
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Mit Programm/Werke'),
                    subtitle: const Text('Songs können diesem Typ zugeordnet werden'),
                    value: _manageSongs,
                    onChanged: (value) => setState(() {
                      _manageSongs = value;
                      _hasChanges = true;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Sichtbar'),
                    subtitle: const Text('In der Auswahl anzeigen'),
                    value: _visible,
                    onChanged: (value) => setState(() {
                      _visible = value;
                      _hasChanges = true;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Hervorheben'),
                    subtitle: const Text('Visuell hervorheben'),
                    value: _highlight,
                    onChanged: (value) => setState(() {
                      _highlight = value;
                      _hasChanges = true;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('Name verbergen'),
                    subtitle: const Text('Nur Datum anzeigen'),
                    value: _hideName,
                    onChanged: (value) => setState(() {
                      _hideName = value;
                      _hasChanges = true;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('In Durchschnitt einbeziehen'),
                    subtitle: const Text('Für Anwesenheitsstatistiken berücksichtigen'),
                    value: _includeInAverage,
                    onChanged: (value) => setState(() {
                      _includeInAverage = value;
                      _hasChanges = true;
                    }),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingXL),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: ElevatedButton(
            onPressed: _hasChanges ? _save : null,
            child: const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingM),
              child: Text('Speichern'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.medium,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  String _getStatusName(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Anwesend';
      case AttendanceStatus.absent:
        return 'Abwesend';
      case AttendanceStatus.excused:
        return 'Entschuldigt';
      case AttendanceStatus.late:
        return 'Verspätet';
      case AttendanceStatus.lateExcused:
        return 'Verspätet (entsch.)';
      case AttendanceStatus.neutral:
        return 'Neutral';
    }
  }

  Future<void> _onBackPressed() async {
    if (_hasChanges) {
      final result = await DialogHelper.showConfirmation(
        context,
        title: 'Ungespeicherte Änderungen',
        message: 'Möchtest du die Änderungen speichern bevor du gehst?',
        confirmText: 'Speichern',
        cancelText: 'Verwerfen',
      );

      if (result) {
        await _save();
      }
    }

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = ref.read(supabaseClientProvider);
    final tenantId = ref.read(currentTenantIdProvider);

    if (tenantId == null) return;

    try {
      await supabase.from('attendance_types').update({
        'name': _nameController.text.trim(),
        'start_time': _startTimeController.text.trim(),
        'end_time': _endTimeController.text.trim(),
        'default_status': _defaultStatus.name,
        'available_statuses': _availableStatuses.map((s) => s.name).toList(),
        'manage_songs': _manageSongs,
        'visible': _visible,
        'highlight': _highlight,
        'hide_name': _hideName,
        'include_in_average': _includeInAverage,
        'color': _color,
      }).eq('id', widget.typeId).eq('tenant_id', tenantId);

      ref.invalidate(attendanceTypesProvider);
      ref.invalidate(_attendanceTypeByIdProvider(widget.typeId));

      if (mounted) {
        ToastHelper.showSuccess(context, 'Änderungen gespeichert');
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

  Future<void> _deleteType() async {
    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Typ löschen',
      message:
          'Möchtest du "${_originalType!.name}" wirklich löschen? Alle Anwesenheiten dieses Typs werden ebenfalls gelöscht.',
      confirmText: 'Löschen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    final supabase = ref.read(supabaseClientProvider);
    final tenantId = ref.read(currentTenantIdProvider);

    if (tenantId == null) return;

    try {
      await supabase
          .from('attendance_types')
          .delete()
          .eq('id', widget.typeId)
          .eq('tenant_id', tenantId);

      ref.invalidate(attendanceTypesProvider);

      if (mounted) {
        ToastHelper.showSuccess(context, 'Typ gelöscht');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Löschen: $e');
      }
    }
  }
}
