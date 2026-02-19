import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/attendance/attendance.dart';

/// Provider for attendance types
final attendanceTypesProvider = FutureProvider<List<AttendanceType>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenantId = ref.watch(currentTenantIdProvider);

  if (tenantId == null) return [];

  final response = await supabase
      .from('attendance_types')
      .select()
      .eq('tenant_id', tenantId)
      .order('index', ascending: true);

  return (response as List).map((e) => AttendanceType.fromJson(e)).toList();
});

/// Attendance Types List Page
///
/// Shows all attendance types with reordering and CRUD capabilities.
class AttendanceTypesPage extends ConsumerStatefulWidget {
  const AttendanceTypesPage({super.key});

  @override
  ConsumerState<AttendanceTypesPage> createState() => _AttendanceTypesPageState();
}

class _AttendanceTypesPageState extends ConsumerState<AttendanceTypesPage> {
  bool _isReordering = false;
  List<AttendanceType> _localTypes = [];

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(attendanceTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anwesenheitstypen'),
        actions: [
          if (_isReordering)
            TextButton(
              onPressed: _saveOrder,
              child: const Text('Speichern'),
            )
          else
            IconButton(
              icon: const Icon(Icons.reorder),
              tooltip: 'Reihenfolge ändern',
              onPressed: () {
                setState(() {
                  _isReordering = true;
                  _localTypes = [...(typesAsync.valueOrNull ?? [])];
                });
              },
            ),
        ],
      ),
      body: typesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
        data: (types) {
          final displayTypes = _isReordering ? _localTypes : types;

          if (displayTypes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_outlined, size: 64, color: AppColors.medium),
                  const SizedBox(height: 16),
                  const Text('Keine Anwesenheitstypen vorhanden'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Typ erstellen'),
                  ),
                ],
              ),
            );
          }

          return _isReordering
              ? ReorderableListView.builder(
                  itemCount: displayTypes.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _localTypes.removeAt(oldIndex);
                      _localTypes.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    return _AttendanceTypeTile(
                      key: ValueKey(displayTypes[index].id),
                      type: displayTypes[index],
                      onTap: null,
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                )
              : ListView.builder(
                  itemCount: displayTypes.length,
                  itemBuilder: (context, index) {
                    return _AttendanceTypeTile(
                      type: displayTypes[index],
                      onTap: () => _openTypeDetail(displayTypes[index]),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                );
        },
      ),
      floatingActionButton: !_isReordering
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(context),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isReordering = false;
                  _localTypes = [];
                });
              },
              backgroundColor: AppColors.medium,
              child: const Icon(Icons.close),
            ),
    );
  }

  Future<void> _saveOrder() async {
    final supabase = ref.read(supabaseClientProvider);

    try {
      for (int i = 0; i < _localTypes.length; i++) {
        final type = _localTypes[i];
        if (type.id != null) {
          await supabase
              .from('attendance_types')
              .update({'index': i})
              .eq('id', type.id!);
        }
      }

      if (mounted) {
        ToastHelper.showSuccess(context, 'Reihenfolge gespeichert');
      }

      ref.invalidate(attendanceTypesProvider);
      setState(() {
        _isReordering = false;
        _localTypes = [];
      });
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

  void _openTypeDetail(AttendanceType type) {
    context.push('/settings/types/${type.id}');
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neuer Anwesenheitstyp'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'z.B. Probe, Konzert, Generalprobe',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await _createType(result.trim());
    }
  }

  Future<void> _createType(String name) async {
    final supabase = ref.read(supabaseClientProvider);
    final tenantId = ref.read(currentTenantIdProvider);

    if (tenantId == null) return;

    try {
      final currentTypes = ref.read(attendanceTypesProvider).valueOrNull ?? [];

      await supabase.from('attendance_types').insert({
        'name': name,
        'tenant_id': tenantId,
        'default_status': 'present',
        'available_statuses': ['neutral', 'present', 'absent', 'excused', 'late'],
        'manage_songs': false,
        'start_time': '19:00',
        'end_time': '20:30',
        'relevant_groups': [],
        'index': currentTypes.length,
        'visible': true,
        'color': 'primary',
        'highlight': false,
        'hide_name': false,
        'include_in_average': true,
      });

      ref.invalidate(attendanceTypesProvider);

      if (mounted) {
        ToastHelper.showSuccess(context, 'Anwesenheitstyp "$name" erstellt');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Erstellen: $e');
      }
    }
  }
}

class _AttendanceTypeTile extends StatelessWidget {
  final AttendanceType type;
  final VoidCallback? onTap;
  final Widget trailing;

  const _AttendanceTypeTile({
    super.key,
    required this.type,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(type.color);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.event,
          color: color,
        ),
      ),
      title: Text(type.name),
      subtitle: Text(
        _getSubtitle(),
        style: TextStyle(color: AppColors.medium, fontSize: 12),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  String _getSubtitle() {
    final parts = <String>[];

    if (type.startTime != null && type.endTime != null) {
      parts.add('${type.startTime} - ${type.endTime}');
    }

    if (type.manageSongs) {
      parts.add('Mit Programm');
    }

    if (!type.visible) {
      parts.add('Ausgeblendet');
    }

    return parts.isEmpty ? 'Standard' : parts.join(' • ');
  }

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'primary':
        return AppColors.primary;
      case 'secondary':
        return AppColors.secondary;
      case 'tertiary':
        return Colors.purple;
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return AppColors.danger;
      case 'rosa':
        return Colors.pink;
      case 'mint':
        return Colors.teal;
      case 'orange':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}
