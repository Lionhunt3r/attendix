import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/shift_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/shift/shift_definition.dart';
import '../../../../data/models/shift/shift_plan.dart';
import '../widgets/shift_preview_sheet.dart';

/// Shift Detail Page
///
/// Shows and edits a single shift plan with definition segments.
class ShiftDetailPage extends ConsumerStatefulWidget {
  final String shiftId;

  const ShiftDetailPage({super.key, required this.shiftId});

  @override
  ConsumerState<ShiftDetailPage> createState() => _ShiftDetailPageState();
}

class _ShiftDetailPageState extends ConsumerState<ShiftDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  List<ShiftDefinition> _definitions = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFromShift(ShiftPlan shift) {
    if (_nameController.text.isEmpty) {
      _nameController.text = shift.name;
      _descriptionController.text = shift.description;
      _definitions = List.from(shift.definition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftAsync = ref.watch(shiftByIdProvider(widget.shiftId));
    final usageCount = ref.watch(shiftUsageCountProvider(widget.shiftId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schichtplan bearbeiten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Löschen',
            onPressed: () => _confirmDelete(context, usageCount.valueOrNull ?? 0),
          ),
        ],
      ),
      body: shiftAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
        data: (shift) {
          if (shift == null) {
            return const Center(child: Text('Schichtplan nicht gefunden'));
          }

          _initializeFromShift(shift);

          return _buildContent(context, shift, usageCount.valueOrNull ?? 0);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveChanges,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: const Text('Speichern'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ShiftPlan shift, int usageCount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General section
          _buildSectionHeader(context, 'Allgemein'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'z.B. 3-Schicht-System',
                    ),
                    onChanged: (_) => _markChanged(),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Beschreibung',
                      hintText: 'z.B. Früh, Spät, Nacht',
                    ),
                    maxLines: 2,
                    onChanged: (_) => _markChanged(),
                  ),
                ],
              ),
            ),
          ),

          // Usage info
          if (usageCount > 0) ...[
            const SizedBox(height: AppDimensions.paddingM),
            Card(
              color: AppColors.info.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Row(
                  children: [
                    Icon(Icons.people, color: AppColors.info),
                    const SizedBox(width: AppDimensions.paddingM),
                    Text(
                      '$usageCount Mitglied${usageCount != 1 ? 'er' : ''} nutzen diesen Schichtplan',
                      style: TextStyle(color: AppColors.info),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.paddingL),

          // Definition section
          _buildSectionHeader(
            context,
            'Definition',
            action: TextButton.icon(
              onPressed: _addSegment,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Segment hinzufügen'),
            ),
          ),

          if (_definitions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.timeline_outlined,
                          size: 48, color: AppColors.medium),
                      const SizedBox(height: AppDimensions.paddingM),
                      const Text(
                        'Keine Schicht-Segmente definiert',
                        style: TextStyle(color: AppColors.medium),
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      ElevatedButton.icon(
                        onPressed: _addSegment,
                        icon: const Icon(Icons.add),
                        label: const Text('Erstes Segment'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _definitions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _definitions.removeAt(oldIndex);
                  _definitions.insert(newIndex, item);
                  _markChanged();
                });
              },
              itemBuilder: (context, index) {
                return _DefinitionSegmentTile(
                  key: ValueKey('segment_$index'),
                  definition: _definitions[index],
                  index: index,
                  onEdit: () => _editSegment(index),
                  onDelete: () => _deleteSegment(index),
                );
              },
            ),

          const SizedBox(height: AppDimensions.paddingL),

          // Cycle info
          if (_definitions.isNotEmpty) ...[
            Card(
              color: AppColors.success.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Row(
                  children: [
                    Icon(Icons.repeat, color: AppColors.success),
                    const SizedBox(width: AppDimensions.paddingM),
                    Expanded(
                      child: Text(
                        'Zyklus: ${_calculateCycleLength()} Tage',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showPreview(context, shift),
                      child: const Text('Beispiel-Rechnung'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  int _calculateCycleLength() {
    return _definitions.fold(0, (sum, def) => sum + def.repeatCount);
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _addSegment() {
    setState(() {
      _definitions.add(ShiftDefinition(
        index: _definitions.length,
        startTime: '08:00',
        duration: 8.0,
        free: false,
        repeatCount: 1,
      ));
      _markChanged();
    });
  }

  Future<void> _editSegment(int index) async {
    final segment = _definitions[index];
    final result = await _showSegmentDialog(context, segment);

    if (result != null) {
      setState(() {
        _definitions[index] = result;
        _markChanged();
      });
    }
  }

  void _deleteSegment(int index) {
    setState(() {
      _definitions.removeAt(index);
      _markChanged();
    });
  }

  Future<ShiftDefinition?> _showSegmentDialog(
      BuildContext context, ShiftDefinition segment) async {
    final startTimeController = TextEditingController(text: segment.startTime);
    final durationController =
        TextEditingController(text: segment.duration.toString());
    final repeatController =
        TextEditingController(text: segment.repeatCount.toString());
    bool isFree = segment.free;

    return showDialog<ShiftDefinition>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Segment bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Free toggle
                SwitchListTile(
                  title: const Text('Frei'),
                  subtitle: const Text('Mitarbeiter ist an diesem Tag frei'),
                  value: isFree,
                  onChanged: (value) {
                    setDialogState(() => isFree = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                // Start time
                if (!isFree) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Startzeit'),
                    subtitle: Text(startTimeController.text),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final parts = startTimeController.text.split(':');
                      final initialTime = TimeOfDay(
                        hour: int.tryParse(parts[0]) ?? 8,
                        minute: int.tryParse(parts[1]) ?? 0,
                      );
                      final time = await showTimePicker(
                        context: context,
                        initialTime: initialTime,
                      );
                      if (time != null) {
                        setDialogState(() {
                          startTimeController.text =
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                  // Duration
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Dauer (in Stunden)',
                      hintText: 'z.B. 8.0',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                ],
                // Repeat count
                TextField(
                  controller: repeatController,
                  decoration: const InputDecoration(
                    labelText: 'Wiederholungen',
                    hintText: 'Anzahl aufeinanderfolgender Tage',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final duration = double.tryParse(durationController.text) ?? 8.0;
                final repeatCount = int.tryParse(repeatController.text) ?? 1;

                Navigator.pop(
                  context,
                  segment.copyWith(
                    startTime: startTimeController.text,
                    duration: duration,
                    free: isFree,
                    repeatCount: repeatCount,
                  ),
                );
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ToastHelper.showError(context, 'Name ist erforderlich');
      return;
    }

    setState(() => _isLoading = true);

    final notifier = ref.read(shiftNotifierProvider.notifier);
    final updatedPlan = ShiftPlan(
      id: widget.shiftId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      definition: _definitions,
    );

    final result = await notifier.updateShift(updatedPlan);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result != null) {
        setState(() => _hasChanges = false);
        ToastHelper.showSuccess(context, 'Änderungen gespeichert');
      } else {
        final error = ref.read(shiftNotifierProvider);
        if (error.hasError) {
          ToastHelper.showError(context, 'Fehler: ${error.error}');
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, int usageCount) async {
    String message = 'Möchtest du diesen Schichtplan wirklich löschen?';
    if (usageCount > 0) {
      message =
          '$usageCount Mitglied${usageCount != 1 ? 'er' : ''} nutzen diesen Schichtplan. '
          'Möchtest du ihn trotzdem löschen?';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schichtplan löschen'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(shiftNotifierProvider.notifier);
      final success = await notifier.deleteShift(widget.shiftId);

      if (mounted) {
        if (success) {
          ToastHelper.showSuccess(context, 'Schichtplan gelöscht');
          context.pop();
        } else {
          ToastHelper.showError(context, 'Fehler beim Löschen');
        }
      }
    }
  }

  void _showPreview(BuildContext context, ShiftPlan shift) {
    // Create a plan with current edits
    final previewPlan = shift.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      definition: _definitions,
    );

    showShiftPreviewSheet(context, previewPlan);
  }
}

class _DefinitionSegmentTile extends StatelessWidget {
  final ShiftDefinition definition;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DefinitionSegmentTile({
    super.key,
    required this.definition,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: definition.free
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.warning.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            definition.free ? Icons.beach_access : Icons.work,
            color: definition.free ? AppColors.success : AppColors.warning,
          ),
        ),
        title: Text(
          definition.free
              ? 'Frei'
              : '${definition.startTime} - ${definition.endTime}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _getSubtitle(),
          style: TextStyle(color: AppColors.medium, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Bearbeiten',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onDelete,
              tooltip: 'Löschen',
            ),
            const Icon(Icons.drag_handle, color: AppColors.medium),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  String _getSubtitle() {
    final parts = <String>[];

    if (!definition.free) {
      parts.add('${definition.duration}h');
    }

    if (definition.repeatCount > 1) {
      parts.add('${definition.repeatCount}x wiederholen');
    } else {
      parts.add('1 Tag');
    }

    return parts.join(' • ');
  }
}
