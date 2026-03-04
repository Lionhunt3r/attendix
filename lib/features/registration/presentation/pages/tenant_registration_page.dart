import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/church_providers.dart';
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
  // FN-007: Controller as state variable to prevent memory leak
  final _birthdayController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Uint8List? _profileImageBytes;
  bool _hasCheckedRegistration = false;

  bool get _isLoggedIn => ref.read(supabaseClientProvider).auth.currentUser != null;

  @override
  void dispose() {
    _birthdayController.dispose();
    super.dispose();
  }

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
    // Check if logged-in user is already registered in this tenant
    if (!_hasCheckedRegistration && _isLoggedIn) {
      _hasCheckedRegistration = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkExistingRegistration(tenant);
      });
    }

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

          // Profile picture
          if (registrationFields.contains('picture')) ...[
            const SizedBox(height: AppDimensions.paddingM),
            _buildProfilePictureField(),
          ],

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

          // Login link — inline dialog instead of navigating away
          Center(
            child: TextButton(
              onPressed: () => _showLoginDialog(tenant),
              child: const Text('Account bereits vorhanden? Hier anmelden'),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingL),
        ],
      ),
    );
  }

  Widget _buildBirthdayField() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    // FN-007: Use state-managed controller and update text on date change
    if (_formData.birthDate != null && _birthdayController.text.isEmpty) {
      _birthdayController.text = dateFormat.format(_formData.birthDate!);
    }
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
      controller: _birthdayController,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _formData.birthDate ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _formData.birthDate = date;
            _birthdayController.text = dateFormat.format(date);
          });
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

        case 'bfecg_church':
          widgets.add(_buildChurchField(field));
          break;
      }
    }

    return widgets;
  }

  Widget _buildProfilePictureField() {
    return FormField<Uint8List>(
      validator: (_) {
        if (_profileImageBytes == null) {
          return 'Bitte wähle ein Passbild aus';
        }
        return null;
      },
      builder: (fieldState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                border: Border.all(
                  color: fieldState.hasError ? AppColors.danger : AppColors.light,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : null,
                    child: _profileImageBytes == null
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profileImageBytes != null
                              ? 'Passbild ändern'
                              : 'Passbild auswählen *',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Max. 15 MB',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.medium,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.photo_camera, color: AppColors.primary),
                ],
              ),
            ),
          ),
          if (fieldState.hasError)
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.paddingM,
                top: AppDimensions.paddingXS,
              ),
              child: Text(
                fieldState.errorText!,
                style: TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();

      // Check file size (max 15MB)
      if (bytes.length > 15 * 1024 * 1024) {
        if (mounted) {
          ToastHelper.showError(context, 'Bild ist zu groß (max 15 MB)');
        }
        return;
      }

      setState(() => _profileImageBytes = bytes);
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Auswählen: $e');
      }
    }
  }

  Widget _buildChurchField(ExtraField field) {
    final churchesAsync = ref.watch(churchesProvider);

    return churchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Fehler beim Laden der Gemeinden'),
      data: (churches) {
        return StatefulBuilder(
          builder: (context, setFieldState) {
            final selectedChurchId =
                _formData.additionalFields[field.id]?.toString();
            final isCustom = selectedChurchId == '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: field.name.isNotEmpty ? field.name : 'Gemeinde',
                    prefixIcon: const Icon(Icons.church_outlined),
                  ),
                  value: selectedChurchId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Nicht gelistet'),
                    ),
                    ...churches.map((c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  validator: (value) {
                    if (value == null) {
                      return 'Bitte wähle eine Gemeinde aus';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setFieldState(() {
                      _formData.additionalFields[field.id] = value;
                      if (value != '') {
                        _formData.additionalFields.remove('_custom_church');
                      }
                    });
                  },
                ),
                if (isCustom) ...[
                  const SizedBox(height: AppDimensions.paddingM),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Name der Gemeinde *',
                      prefixIcon: Icon(Icons.edit),
                      helperText: 'Mindestens 5 Zeichen',
                    ),
                    validator: (value) {
                      if (isCustom &&
                          (value == null || value.trim().length < 5)) {
                        return 'Bitte gib den Namen deiner Gemeinde ein (min. 5 Zeichen)';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _formData.additionalFields['_custom_church'] =
                          value?.trim();
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _checkExistingRegistration(Tenant tenant) async {
    if (!_isLoggedIn || tenant.id == null) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existing = await supabase
          .from('tenantUsers')
          .select('id')
          .eq('tenantId', tenant.id!)
          .eq('userId', userId)
          .maybeSingle();

      if (existing != null && mounted) {
        ToastHelper.showWarning(context, 'Du bist bereits in dieser Gruppe registriert.');
        context.go('/tenants');
      }
    } catch (e) {
      debugPrint('Check existing registration failed: $e');
    }
  }

  Future<void> _showLoginDialog(Tenant tenant) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var loginError = '';

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Anmelden'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Melde dich mit deinem bestehenden Account an.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Passwort',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                    obscureText: true,
                  ),
                  if (loginError.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(loginError, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final supabase = ref.read(supabaseClientProvider);
                      await supabase.auth.signInWithPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      setDialogState(() {
                        loginError = 'Anmeldung fehlgeschlagen. Bitte prüfe deine Daten.';
                      });
                    }
                  },
                  child: const Text('Anmelden'),
                ),
              ],
            );
          },
        ),
      );

      if (result == true && mounted) {
        // Rebuild page to show logged-in state
        setState(() => _hasCheckedRegistration = false);
      }
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _submit(Tenant tenant) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    // Handle custom church creation (bfecg_church field)
    final customChurchName = _formData.additionalFields.remove('_custom_church');
    if (_formData.additionalFields['bfecg_church'] == '' &&
        customChurchName != null &&
        customChurchName.toString().isNotEmpty) {
      final churchId = await ref
          .read(churchNotifierProvider.notifier)
          .createChurch(customChurchName.toString());
      if (churchId != null) {
        _formData.additionalFields['bfecg_church'] = churchId;
      } else {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ToastHelper.showError(context, 'Fehler beim Erstellen der Gemeinde.');
        return;
      }
    }

    // Attach profile image bytes if selected
    _formData.profileImageBytes = _profileImageBytes;

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
            ? 'Bitte bestätige deine E-Mail-Adresse, um die Registrierung abzuschließen.'
            : 'Du bist nun Mitglied dieser Gruppe.';
      } else {
        message = result.isNewAccount
            ? 'Bitte bestätige deine E-Mail-Adresse und warte auf die Genehmigung durch einen Administrator.'
            : 'Bitte warte auf die Genehmigung durch einen Administrator.';
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Icon(
            result.autoApproved ? Icons.check_circle : Icons.hourglass_top,
            color: AppColors.success,
            size: 48,
          ),
          title: const Text('Registrierung erfolgreich!'),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(result.isNewAccount ? 'Zum Login' : 'Weiter'),
            ),
          ],
        ),
      );
      if (mounted) context.go(_isLoggedIn ? '/tenants' : '/login');
    } else {
      ToastHelper.showError(
        context,
        result.errorMessage ?? 'Registrierung fehlgeschlagen.',
      );
    }
  }
}
