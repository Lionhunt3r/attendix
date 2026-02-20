import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../data/models/person/person.dart';
import '../../../../data/models/tenant/tenant.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../instruments/presentation/pages/instruments_list_page.dart';
import 'people_list_page.dart';

/// Page for creating a new person
class PersonCreatePage extends ConsumerStatefulWidget {
  const PersonCreatePage({super.key});

  @override
  ConsumerState<PersonCreatePage> createState() => _PersonCreatePageState();
}

class _PersonCreatePageState extends ConsumerState<PersonCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedInstrument;
  DateTime? _birthday;
  bool _isLoading = false;
  final Map<String, dynamic> _additionalFieldValues = {};
  bool _extraFieldsInitialized = false;

  /// Returns the default value for a field type (like Utils.getFieldTypeDefaultValue in Ionic)
  /// For NEW person: defaultValue is NOT used (only type-based defaults)
  /// For EXISTING person: defaultValue IS used if provided
  dynamic _getFieldTypeDefaultValue(String fieldType, {dynamic defaultValue, List<String>? options}) {
    // 1. If explicit defaultValue is provided, use it
    if (defaultValue != null) {
      return defaultValue;
    }

    // 2. SELECT → first option
    if (fieldType == 'select') {
      return (options?.isNotEmpty ?? false) ? options!.first : '';
    }

    // 3. Type-based defaults (matching Ionic behavior)
    switch (fieldType) {
      case 'text':
      case 'textarea':
        return '';
      case 'number':
        return 0;
      case 'date':
        return DateTime.now().toIso8601String().split('T')[0];
      case 'boolean':
        return true; // Ionic uses TRUE as default!
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final instrumentsAsync = ref.watch(instrumentsListProvider);
    final tenant = ref.watch(currentTenantProvider);
    final extraFields = tenant?.additionalFields ?? [];

    // Initialize additional_fields with defaults (like Ionic lines 166-174)
    // For NEW person: use type-based defaults only (NO field.defaultValue)
    if (!_extraFieldsInitialized && extraFields.isNotEmpty) {
      for (final field in extraFields) {
        _additionalFieldValues[field.id] ??= _getFieldTypeDefaultValue(
          field.type,
          options: field.options,
          // NOTE: NOT passing field.defaultValue for new person (matches Ionic!)
        );
      }
      _extraFieldsInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Person'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Speichern'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            // First Name
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Vorname *',
                hintText: 'Max',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vorname ist erforderlich';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Last Name
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nachname *',
                hintText: 'Mustermann',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nachname ist erforderlich';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Instrument Dropdown
            instrumentsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Fehler: $e'),
              data: (instruments) => DropdownButtonFormField<int>(
                value: _selectedInstrument,
                decoration: const InputDecoration(
                  labelText: 'Instrument',
                  prefixIcon: Icon(Icons.music_note),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Kein Instrument'),
                  ),
                  ...instruments.map((i) => DropdownMenuItem<int>(
                    value: i.id,
                    child: Text(i.name),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedInstrument = value),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Birthday
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake),
              title: const Text('Geburtstag'),
              subtitle: Text(
                _birthday != null
                    ? '${_birthday!.day.toString().padLeft(2, '0')}.${_birthday!.month.toString().padLeft(2, '0')}.${_birthday!.year}'
                    : 'Nicht angegeben',
                style: TextStyle(
                  color: _birthday != null ? null : AppColors.medium,
                ),
              ),
              trailing: _birthday != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _birthday = null),
                    )
                  : null,
              onTap: _pickBirthday,
            ),
            const Divider(),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-Mail (optional)',
                hintText: 'max@example.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Ungültige E-Mail-Adresse';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon (optional)',
                hintText: '+49 123 456789',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notizen (optional)',
                hintText: 'Zusätzliche Informationen...',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),

            // Extra Fields Section - as ExpansionTile like Ionic Accordion
            if (extraFields.isNotEmpty)
              ExpansionTile(
                title: const Text('Zusatzfelder'),
                initiallyExpanded: true,
                tilePadding: EdgeInsets.zero,
                children: extraFields.map((field) => _buildExtraFieldInput(field)).toList(),
              ),

            const SizedBox(height: AppDimensions.paddingL),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraFieldInput(ExtraField field) {
    switch (field.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            decoration: InputDecoration(labelText: field.name),
            initialValue: _additionalFieldValues[field.id]?.toString() ?? '',
            onChanged: (value) => _additionalFieldValues[field.id] = value,
          ),
        );

      case 'textarea':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: field.name,
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            initialValue: _additionalFieldValues[field.id]?.toString() ?? '',
            onChanged: (value) => _additionalFieldValues[field.id] = value,
          ),
        );

      case 'number':
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            decoration: InputDecoration(labelText: field.name),
            keyboardType: TextInputType.number,
            initialValue: _additionalFieldValues[field.id]?.toString() ?? '0',
            onChanged: (value) => _additionalFieldValues[field.id] = int.tryParse(value) ?? 0,
          ),
        );

      case 'boolean':
        return SwitchListTile(
          title: Text(field.name),
          value: _additionalFieldValues[field.id] as bool? ?? true,
          onChanged: (value) => setState(() => _additionalFieldValues[field.id] = value),
        );

      case 'date':
        final currentValue = _additionalFieldValues[field.id]?.toString();
        final currentDate = currentValue != null ? DateTime.tryParse(currentValue) : null;
        return ListTile(
          title: Text(field.name),
          subtitle: Text(
            currentDate != null
                ? DateFormat('dd.MM.yyyy').format(currentDate)
                : 'Nicht angegeben',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: currentDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              setState(() => _additionalFieldValues[field.id] = date.toIso8601String().split('T')[0]);
            }
          },
        );

      case 'select':
        final options = field.options ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: field.name),
            value: _additionalFieldValues[field.id]?.toString(),
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: (value) => setState(() => _additionalFieldValues[field.id] = value),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(playerRepositoryProvider);

      final person = Person(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        instrument: _selectedInstrument,
        birthday: _birthday?.toIso8601String().split('T').first,
        joined: DateTime.now().toIso8601String().split('T').first,
        additionalFields: _additionalFieldValues.isNotEmpty ? _additionalFieldValues : null,
      );

      await repo.createPlayer(person);

      // Invalidate the people list to trigger refresh
      ref.invalidate(peopleListProvider);

      if (mounted) {
        ToastHelper.showSuccess(context, 'Person erstellt');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
