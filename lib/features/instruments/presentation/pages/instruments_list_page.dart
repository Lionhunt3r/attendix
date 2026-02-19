import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/instrument/instrument.dart';
import '../../../../data/repositories/group_repository.dart';
import '../../../tenant_selection/presentation/pages/tenant_selection_page.dart';

/// Provider for instruments list
final instrumentsListProvider = FutureProvider<List<Instrument>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  
  if (tenant == null) return [];

  final response = await supabase
      .from('instruments')
      .select('*')
      .eq('tenantId', tenant.id!)
      .order('name');

  return (response as List)
      .map((e) => Instrument.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Instruments list page
class InstrumentsListPage extends ConsumerWidget {
  const InstrumentsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instrumentsAsync = ref.watch(instrumentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instrumente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: instrumentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: AppDimensions.paddingM),
              Text('Fehler: $error'),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: () => ref.refresh(instrumentsListProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (instruments) {
          if (instruments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.piano_outlined, size: 80, color: AppColors.medium),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text('Keine Instrumente', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Füge das erste Instrument hinzu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.medium),
                  ),
                ],
              ),
            );
          }

          // Separate sections and instruments
          final sections = instruments.where((i) => i.isSection).toList();
          final regularInstruments = instruments.where((i) => !i.isSection).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(instrumentsListProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              children: [
                if (sections.isNotEmpty) ...[
                  Text(
                    'Sektionen',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.medium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  ...sections.map((instrument) => _InstrumentListItem(
                    instrument: instrument,
                    onTap: () => _showEditDialog(context, ref, instrument),
                  )),
                  const SizedBox(height: AppDimensions.paddingL),
                ],
                Text(
                  'Instrumente',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.medium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                ...regularInstruments.map((instrument) => _InstrumentListItem(
                  instrument: instrument,
                  onTap: () => _showEditDialog(context, ref, instrument),
                )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InstrumentListItem extends StatelessWidget {
  const _InstrumentListItem({
    required this.instrument,
    required this.onTap,
  });

  final Instrument instrument;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = instrument.color != null
        ? Color(int.tryParse(instrument.color!.replaceFirst('#', '0xFF')) ?? 0xFF6366F1)
        : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: Icon(
            instrument.isSection ? Icons.folder : Icons.music_note,
            color: color,
          ),
        ),
        title: Text(
          instrument.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: instrument.shortName != null && instrument.shortName != instrument.name
            ? Text(instrument.shortName!)
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.medium),
      ),
    );
  }
}

/// Show dialog to add a new instrument
Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => const _InstrumentEditDialog(),
  );

  if (result != null && context.mounted) {
    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.createGroup(name: result['name'] as String);
      ref.invalidate(instrumentsListProvider);
      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Instrument erstellt');
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

/// Show dialog to edit an existing instrument
Future<void> _showEditDialog(BuildContext context, WidgetRef ref, Instrument instrument) async {
  final result = await showDialog<Map<String, dynamic>?>(
    context: context,
    builder: (context) => _InstrumentEditDialog(instrument: instrument),
  );

  if (result != null && context.mounted) {
    try {
      final repo = ref.read(groupRepositoryProvider);

      if (result['_delete'] == true) {
        // Delete the instrument
        await repo.deleteGroup(instrument.id!);
        ref.invalidate(instrumentsListProvider);
        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Instrument gelöscht');
        }
      } else {
        // Update the instrument
        await repo.updateGroup(instrument.id!, result);
        ref.invalidate(instrumentsListProvider);
        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Instrument aktualisiert');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

/// Dialog for editing/creating an instrument
class _InstrumentEditDialog extends StatefulWidget {
  const _InstrumentEditDialog({this.instrument});

  final Instrument? instrument;

  @override
  State<_InstrumentEditDialog> createState() => _InstrumentEditDialogState();
}

class _InstrumentEditDialogState extends State<_InstrumentEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _shortNameController;
  late final TextEditingController _notesController;
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.instrument != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.instrument?.name ?? '');
    _shortNameController = TextEditingController(text: widget.instrument?.shortName ?? '');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Instrument bearbeiten' : 'Neues Instrument'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Violine',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name ist erforderlich';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              TextFormField(
                controller: _shortNameController,
                decoration: const InputDecoration(
                  labelText: 'Kurzname (optional)',
                  hintText: 'z.B. Vl.',
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: AppDimensions.paddingM),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notizen (optional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: () => _confirmDelete(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Löschen'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Speichern' : 'Erstellen'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final result = <String, dynamic>{
        'name': _nameController.text.trim(),
      };

      if (_shortNameController.text.trim().isNotEmpty) {
        result['shortName'] = _shortNameController.text.trim();
      }

      if (isEditing && _notesController.text.trim().isNotEmpty) {
        result['notes'] = _notesController.text.trim();
      }

      Navigator.of(context).pop(result);
    }
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Instrument löschen?'),
        content: Text('Möchtest du "${widget.instrument!.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop({'_delete': true});
    }
  }
}