import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/teacher_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/repositories/teacher_repository.dart';

/// Teacher List Page
class TeachersListPage extends ConsumerWidget {
  const TeachersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lehrer / Dirigenten'),
      ),
      body: teachersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
        data: (teachers) {
          if (teachers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined, size: 64, color: AppColors.medium),
                  const SizedBox(height: 16),
                  const Text('Keine Lehrer vorhanden'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Lehrer hinzufügen'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teachersProvider);
              await ref.read(teachersProvider.future);
            },
            child: ListView.builder(
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                return _TeacherTile(
                  teacher: teacher,
                  onTap: () => _showEditDialog(context, ref, teacher),
                  onDelete: () => _deleteTeacher(context, ref, teacher),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Teacher>(
      context: context,
      builder: (context) => const _TeacherEditDialog(),
    );

    if (result != null) {
      try {
        await ref.read(teacherNotifierProvider.notifier).createTeacher(result);

        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Lehrer "${result.name}" erstellt');
        }
      } catch (e) {
        if (context.mounted) {
          ToastHelper.showError(context, 'Fehler: $e');
        }
      }
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Teacher teacher,
  ) async {
    final result = await showDialog<Teacher>(
      context: context,
      builder: (context) => _TeacherEditDialog(teacher: teacher),
    );

    if (result != null && teacher.id != null) {
      try {
        await ref.read(teacherNotifierProvider.notifier).updateTeacher(
              teacher.id!,
              {
                'name': result.name,
                'number': result.number,
                'notes': result.notes,
                'private': result.isPrivate,
                'instruments': result.instruments,
              },
            );

        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Änderungen gespeichert');
        }
      } catch (e) {
        if (context.mounted) {
          ToastHelper.showError(context, 'Fehler: $e');
        }
      }
    }
  }

  Future<void> _deleteTeacher(
    BuildContext context,
    WidgetRef ref,
    Teacher teacher,
  ) async {
    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Lehrer löschen',
      message: 'Möchtest du "${teacher.name}" wirklich löschen?',
      confirmText: 'Löschen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    if (teacher.id == null) return;

    try {
      await ref.read(teacherNotifierProvider.notifier).deleteTeacher(teacher.id!);

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Lehrer gelöscht');
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

class _TeacherTile extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TeacherTile({
    required this.teacher,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(teacher.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(teacher.name),
        subtitle: teacher.number.isNotEmpty
            ? Text('Tel: ${teacher.number}')
            : teacher.notes.isNotEmpty
                ? Text(
                    teacher.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
        trailing: teacher.isPrivate
            ? const Icon(Icons.lock_outline, size: 16, color: AppColors.medium)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _TeacherEditDialog extends StatefulWidget {
  final Teacher? teacher;

  const _TeacherEditDialog({this.teacher});

  @override
  State<_TeacherEditDialog> createState() => _TeacherEditDialogState();
}

class _TeacherEditDialogState extends State<_TeacherEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _numberController;
  late final TextEditingController _notesController;
  late bool _private;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher?.name ?? '');
    _numberController =
        TextEditingController(text: widget.teacher?.number ?? '');
    _notesController = TextEditingController(text: widget.teacher?.notes ?? '');
    _private = widget.teacher?.isPrivate ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.teacher == null;

    return AlertDialog(
      title: Text(isNew ? 'Neuer Lehrer' : 'Lehrer bearbeiten'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'z.B. Max Mustermann',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bitte einen Namen eingeben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  hintText: 'z.B. +49 123 456789',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notizen',
                  hintText: 'Zusätzliche Informationen...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Privat'),
                subtitle: const Text('Nur für Admins sichtbar'),
                value: _private,
                onChanged: (value) => setState(() => _private = value),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isNew ? 'Erstellen' : 'Speichern'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = Teacher(
      id: widget.teacher?.id,
      name: _nameController.text.trim(),
      number: _numberController.text.trim(),
      notes: _notesController.text.trim(),
      isPrivate: _private,
      instruments: widget.teacher?.instruments ?? [],
      tenantId: widget.teacher?.tenantId,
    );

    Navigator.pop(context, result);
  }
}
