import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/tenant/tenant.dart';
import '../../data/providers/registration_providers.dart';

/// Public tenant registration page
class TenantRegistrationPage extends ConsumerStatefulWidget {
  const TenantRegistrationPage({
    super.key,
    required this.registerId,
  });

  final String registerId;

  @override
  ConsumerState<TenantRegistrationPage> createState() => _TenantRegistrationPageState();
}

class _TenantRegistrationPageState extends ConsumerState<TenantRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _formData = RegistrationFormData();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _isLoggedIn => ref.read(supabaseClientProvider).auth.currentUser != null;

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(tenantByRegisterIdProvider(widget.registerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrierung'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: tenantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState('Fehler beim Laden: $error'),
        data: (tenant) {
          if (tenant == null) {
            return _buildErrorState('Ungültiger Registrierungslink.');
          }
          return _buildForm(tenant);
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingL),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Zur Anmeldung'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(Tenant tenant) {
    final groupsAsync = ref.watch(registrationGroupsProvider(tenant.id!));
    final registrationFields = tenant.registrationFields ?? [];
    final additionalFields = tenant.additionalFields ?? [];

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          // Tenant info header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      StringUtils.getTenantInitials(
                        tenant.shortName,
                        tenant.longName,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrierung bei',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.medium,
                              ),
                        ),
                        Text(
                          tenant.shortName.isNotEmpty ? tenant.shortName : tenant.longName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingL),

          // Account section (only if not logged in)
          if (!_isLoggedIn) ...[
            Text(
              'Konto erstellen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'E-Mail *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'E-Mail ist erforderlich';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Ungültige E-Mail-Adresse';
                }
                return null;
              },
              onSaved: (value) => _formData.email = value ?? '',
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Passwort *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Passwort ist erforderlich';
                }
                if (value.length < 6) {
                  return 'Mindestens 6 Zeichen';
                }
                return null;
              },
              onChanged: (value) => _formData.password = value,
              onSaved: (value) => _formData.password = value ?? '',
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Passwort bestätigen *',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              obscureText: _obscureConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Passwort bestätigen ist erforderlich';
                }
                if (value != _formData.password) {
                  return 'Passwörter stimmen nicht überein';
                }
                return null;
              },
              onSaved: (value) => _formData.confirmPassword = value ?? '',
            ),
            const SizedBox(height: AppDimensions.paddingL),
          ],

          // Personal data section
          Text(
            'Persönliche Daten',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Vorname *',
              prefixIcon: Icon(Icons.person_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vorname ist erforderlich';
              }
              return null;
            },
            onSaved: (value) => _formData.firstName = value ?? '',
          ),
          const SizedBox(height: AppDimensions.paddingM),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nachname *',
              prefixIcon: Icon(Icons.person_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nachname ist erforderlich';
              }
              return null;
            },
            onSaved: (value) => _formData.lastName = value ?? '',
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Group selection
          groupsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Fehler beim Laden der Gruppen'),
            data: (groups) {
              if (groups.isEmpty) {
                return const Text('Keine Gruppen verfügbar');
              }
              return DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Gruppe *',
                  prefixIcon: Icon(Icons.group_outlined),
                ),
                items: groups.map((g) {
                  return DropdownMenuItem<int>(
                    value: g['id'] as int,
                    child: Text(g['name'] as String),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Gruppe ist erforderlich';
                  }
                  return null;
                },
                onChanged: (value) => _formData.groupId = value,
                onSaved: (value) => _formData.groupId = value,
              );
            },
          ),

          // Optional fields based on registration_fields
          if (registrationFields.contains('birthDate')) ...[
            const SizedBox(height: AppDimensions.paddingM),
            _buildBirthdayField(),
          ],

          if (registrationFields.contains('phone')) ...[
            const SizedBox(height: AppDimensions.paddingM),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Handynummer',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              onSaved: (value) => _formData.phone = value,
            ),
          ],

          // Dynamic additional fields
          ..._buildAdditionalFields(registrationFields, additionalFields),

          // Notes field
          const SizedBox(height: AppDimensions.paddingM),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Notizen',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            onSaved: (value) => _formData.notes = value,
          ),

          const SizedBox(height: AppDimensions.paddingL),

          // Submit button
          FilledButton(
            onPressed: _isLoading ? null : () => _submit(tenant),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Registrieren'),
          ),

          const SizedBox(height: AppDimensions.paddingM),

          // Login link
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Bereits registriert? Anmelden'),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingL),
        ],
      ),
    );
  }

  Widget _buildBirthdayField() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Geburtsdatum',
        prefixIcon: const Icon(Icons.cake_outlined),
        suffixIcon: const Icon(Icons.calendar_today),
        hintText: _formData.birthDate != null
            ? dateFormat.format(_formData.birthDate!)
            : null,
      ),
      readOnly: true,
      controller: TextEditingController(
        text: _formData.birthDate != null
            ? dateFormat.format(_formData.birthDate!)
            : '',
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _formData.birthDate ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _formData.birthDate = date);
        }
      },
    );
  }

  List<Widget> _buildAdditionalFields(
    List<String> registrationFields,
    List<ExtraField> additionalFields,
  ) {
    final widgets = <Widget>[];

    for (final field in additionalFields) {
      // Only show if in registration_fields
      if (!registrationFields.contains(field.id)) continue;

      widgets.add(const SizedBox(height: AppDimensions.paddingM));

      switch (field.type) {
        case 'text':
        case 'textarea':
          widgets.add(
            TextFormField(
              decoration: InputDecoration(
                labelText: field.name,
                prefixIcon: const Icon(Icons.text_fields),
              ),
              maxLines: field.type == 'textarea' ? 3 : 1,
              initialValue: field.defaultValue?.toString(),
              onSaved: (value) {
                if (value != null && value.isNotEmpty) {
                  _formData.additionalFields[field.id] = value;
                }
              },
            ),
          );
          break;

        case 'number':
          widgets.add(
            TextFormField(
              decoration: InputDecoration(
                labelText: field.name,
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              initialValue: field.defaultValue?.toString(),
              onSaved: (value) {
                if (value != null && value.isNotEmpty) {
                  _formData.additionalFields[field.id] = int.tryParse(value) ?? value;
                }
              },
            ),
          );
          break;

        case 'boolean':
          widgets.add(
            StatefulBuilder(
              builder: (context, setFieldState) {
                final value = _formData.additionalFields[field.id] as bool? ??
                    field.defaultValue as bool? ??
                    false;
                return SwitchListTile(
                  title: Text(field.name),
                  value: value,
                  onChanged: (newValue) {
                    setFieldState(() {
                      _formData.additionalFields[field.id] = newValue;
                    });
                  },
                );
              },
            ),
          );
          break;

        case 'select':
          if (field.options != null && field.options!.isNotEmpty) {
            widgets.add(
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: field.name,
                  prefixIcon: const Icon(Icons.list),
                ),
                value: _formData.additionalFields[field.id] as String? ??
                    field.defaultValue?.toString(),
                items: field.options!.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  _formData.additionalFields[field.id] = value;
                },
                onSaved: (value) {
                  if (value != null) {
                    _formData.additionalFields[field.id] = value;
                  }
                },
              ),
            );
          }
          break;

        case 'date':
          widgets.add(
            StatefulBuilder(
              builder: (context, setFieldState) {
                final dateFormat = DateFormat('dd.MM.yyyy');
                final currentValue = _formData.additionalFields[field.id];
                final currentDate = currentValue != null
                    ? DateTime.tryParse(currentValue.toString())
                    : null;

                return TextFormField(
                  decoration: InputDecoration(
                    labelText: field.name,
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: currentDate != null ? dateFormat.format(currentDate) : '',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: currentDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setFieldState(() {
                        _formData.additionalFields[field.id] =
                            date.toIso8601String().split('T').first;
                      });
                    }
                  },
                );
              },
            ),
          );
          break;
      }
    }

    return widgets;
  }

  Future<void> _submit(Tenant tenant) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final service = ref.read(registrationServiceProvider);
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;

    // If logged in, use current user's email
    if (_isLoggedIn && _formData.email.isEmpty) {
      _formData.email = supabase.auth.currentUser?.email ?? '';
    }

    final result = await service.register(
      tenant: tenant,
      formData: _formData,
      isLoggedIn: _isLoggedIn,
      existingUserId: userId,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      String message;
      if (result.autoApproved) {
        message = result.isNewAccount
            ? 'Registrierung erfolgreich! Bitte bestätige deine E-Mail-Adresse.'
            : 'Registrierung erfolgreich! Du bist nun Mitglied.';
      } else {
        message = result.isNewAccount
            ? 'Registrierung erfolgreich! Bitte bestätige deine E-Mail-Adresse und warte auf die Genehmigung.'
            : 'Registrierung erfolgreich! Bitte warte auf die Genehmigung durch einen Administrator.';
      }

      ToastHelper.showSuccess(context, message);
      context.go('/login');
    } else {
      ToastHelper.showError(
        context,
        result.errorMessage ?? 'Registrierung fehlgeschlagen.',
      );
    }
  }
}
