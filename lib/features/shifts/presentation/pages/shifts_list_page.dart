import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/shift_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/shift/shift_plan.dart';

/// Shifts List Page
///
/// Shows all shift plans with CRUD capabilities.
class ShiftsListPage extends ConsumerStatefulWidget {
  const ShiftsListPage({super.key});

  @override
  ConsumerState<ShiftsListPage> createState() => _ShiftsListPageState();
}

class _ShiftsListPageState extends ConsumerState<ShiftsListPage> {
  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schichtpläne'),
      ),
      body: Column(
        children: [
          // Info card explaining the feature
          _buildInfoCard(context),

          // Shifts list
          Expanded(
            child: shiftsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Fehler: $error')),
              data: (shifts) {
                if (shifts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 64, color: AppColors.medium),
                        const SizedBox(height: 16),
                        const Text('Keine Schichtpläne vorhanden'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Schichtplan erstellen'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    return _ShiftPlanTile(
                      shift: shifts[index],
                      onTap: () => _openShiftDetail(shifts[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Card(
        color: AppColors.info.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.info),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatische Entschuldigungen',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      'Schichtpläne ermöglichen automatische Entschuldigungen basierend auf Arbeitsschichten. '
                      'Weise einem Mitglied einen Schichtplan zu, um Konflikte mit Terminen automatisch zu erkennen.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.medium,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openShiftDetail(ShiftPlan shift) {
    if (shift.id != null) {
      context.push('/settings/shifts/${shift.id}');
    }
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neuer Schichtplan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'z.B. 3-Schicht-System',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                hintText: 'z.B. Früh, Spät, Nacht',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text,
              'description': descriptionController.text,
            }),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (result != null && result['name']!.trim().isNotEmpty) {
      await _createShift(result['name']!.trim(), result['description']?.trim() ?? '');
    }
  }

  Future<void> _createShift(String name, String description) async {
    final notifier = ref.read(shiftNotifierProvider.notifier);

    final plan = ShiftPlan(
      name: name,
      description: description,
    );

    final result = await notifier.createShift(plan);

    if (mounted) {
      if (result != null) {
        ToastHelper.showSuccess(context, 'Schichtplan "$name" erstellt');
        // Navigate to detail page
        if (result.id != null) {
          context.push('/settings/shifts/${result.id}');
        }
      } else {
        final error = ref.read(shiftNotifierProvider);
        if (error.hasError) {
          ToastHelper.showError(context, 'Fehler beim Erstellen: ${error.error}');
        }
      }
    }
  }
}

class _ShiftPlanTile extends StatelessWidget {
  final ShiftPlan shift;
  final VoidCallback? onTap;

  const _ShiftPlanTile({
    required this.shift,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.schedule,
          color: AppColors.primary,
        ),
      ),
      title: Text(shift.name),
      subtitle: Text(
        _getSubtitle(),
        style: TextStyle(color: AppColors.medium, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.medium),
      onTap: onTap,
    );
  }

  String _getSubtitle() {
    final parts = <String>[];

    if (shift.description.isNotEmpty) {
      parts.add(shift.description);
    }

    final cycleDays = shift.cycleLengthDays;
    if (cycleDays > 1) {
      parts.add('$cycleDays-Tage-Zyklus');
    }

    if (shift.definition.isNotEmpty) {
      final segments = shift.definition.length;
      parts.add('$segments Segment${segments != 1 ? 'e' : ''}');
    }

    return parts.isEmpty ? 'Keine Definition' : parts.join(' • ');
  }
}
