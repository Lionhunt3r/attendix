import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/tenant/tenant.dart';
import 'tenant_selection_page.dart';

/// Page for creating a new tenant/group
class TenantCreatePage extends ConsumerStatefulWidget {
  const TenantCreatePage({super.key});

  @override
  ConsumerState<TenantCreatePage> createState() => _TenantCreatePageState();
}

class _TenantCreatePageState extends ConsumerState<TenantCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _shortNameController = TextEditingController();
  final _longNameController = TextEditingController();
  String _selectedType = 'orchestra';
  bool _isLoading = false;

  @override
  void dispose() {
    _shortNameController.dispose();
    _longNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Gruppe erstellen'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            // Info card
            Card(
              color: AppColors.info.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.all(AppDimensions.paddingM),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    SizedBox(width: AppDimensions.paddingM),
                    Expanded(
                      child: Text(
                        'Du wirst automatisch als Administrator der neuen Gruppe eingetragen.',
                        style: TextStyle(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Short Name
            TextFormField(
              controller: _shortNameController,
              decoration: const InputDecoration(
                labelText: 'Kurzname *',
                hintText: 'z.B. JON oder Chor St. Peter',
                helperText: 'Wird in der Navigation angezeigt',
                prefixIcon: Icon(Icons.short_text),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kurzname ist erforderlich';
                }
                if (value.trim().length < 2) {
                  return 'Mindestens 2 Zeichen';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Long Name
            TextFormField(
              controller: _longNameController,
              decoration: const InputDecoration(
                labelText: 'Vollständiger Name (optional)',
                hintText: 'z.B. Jugendorchester Nürnberg',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Type selection
            Text(
              'Art der Gruppe',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.medium,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            _buildTypeOption(
              value: 'orchestra',
              icon: Icons.music_note,
              label: 'Orchester',
              description: 'Für Orchester mit Instrumentengruppen',
            ),
            _buildTypeOption(
              value: 'choir',
              icon: Icons.mic,
              label: 'Chor',
              description: 'Für Chöre mit Stimmgruppen',
            ),
            _buildTypeOption(
              value: 'general',
              icon: Icons.groups,
              label: 'Allgemein',
              description: 'Für andere Gruppen oder Vereine',
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTenant,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gruppe erstellen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String value,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = _selectedType == value;
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedType = value),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.medium.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.medium,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.medium,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Nicht angemeldet');
      }

      final shortName = _shortNameController.text.trim();
      final longName = _longNameController.text.trim().isNotEmpty
          ? _longNameController.text.trim()
          : shortName;

      // Create the tenant
      final tenantResponse = await supabase
          .from('tenants')
          .insert({
            'shortName': shortName,
            'longName': longName,
            'type': _selectedType,
          })
          .select()
          .single();

      final tenantId = tenantResponse['id'] as int;

      // Create tenant user association as ADMIN (role = 5)
      await supabase.from('tenantUsers').insert({
        'tenantId': tenantId,
        'userId': userId,
        'role': 5, // ADMIN
      });

      // Create default instrument/section group
      final defaultGroupName = switch (_selectedType) {
        'orchestra' => 'Streicher',
        'choir' => 'Sopran',
        _ => 'Gruppe 1',
      };

      await supabase.from('instruments').insert({
        'tenantId': tenantId,
        'name': defaultGroupName,
        'isSection': true,
      });

      // Refresh the tenants list
      ref.invalidate(userTenantsProvider);

      // Set as current tenant
      final newTenant = Tenant.fromJson(tenantResponse);
      await ref.read(currentTenantProvider.notifier).setTenant(newTenant);

      if (mounted) {
        ToastHelper.showSuccess(context, 'Gruppe "$shortName" erstellt!');
        context.go('/people');
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
