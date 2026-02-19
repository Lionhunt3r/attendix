import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../tenant_selection/presentation/pages/tenant_selection_page.dart';

/// Simple meeting data class (avoiding code generation for simplicity)
class MeetingData {
  final int? id;
  final int tenantId;
  final String date;
  final String? notes;

  MeetingData({
    this.id,
    required this.tenantId,
    required this.date,
    this.notes,
  });

  factory MeetingData.fromJson(Map<String, dynamic> json) {
    return MeetingData(
      id: json['id'] as int?,
      tenantId: json['tenantId'] as int,
      date: json['date'] as String,
      notes: json['notes'] as String?,
    );
  }

  String get formattedDate {
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    return DateFormat('dd.MM.yyyy').format(d);
  }

  String get weekdayName {
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    return DateFormat('E', 'de_DE').format(d);
  }
}

/// Provider for meetings list
final meetingsListProvider = FutureProvider<List<MeetingData>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('meetings')
      .select('*')
      .eq('tenantId', tenant.id!)
      .order('date', ascending: false);

  return (response as List).map((e) => MeetingData.fromJson(e as Map<String, dynamic>)).toList();
});

/// Meetings list page
class MeetingsListPage extends ConsumerWidget {
  const MeetingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sitzungen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: AppDimensions.paddingM),
              Text('Fehler: $e'),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: () => ref.invalidate(meetingsListProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (meetings) {
          if (meetings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_note_outlined, size: 80, color: AppColors.medium),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(
                    'Keine Sitzungen',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Erstelle die erste Sitzung',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.medium),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(meetingsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                final meeting = meetings[index];
                return _MeetingListItem(
                  meeting: meeting,
                  onTap: () => _showMeetingDialog(context, ref, meeting),
                  onDelete: () => _deleteMeeting(context, ref, meeting),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMeetingDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Neue Sitzung'),
      ),
    );
  }

  Future<void> _showMeetingDialog(BuildContext context, WidgetRef ref, MeetingData? meeting) async {
    final result = await showDialog<MeetingData>(
      context: context,
      builder: (ctx) => _MeetingEditDialog(meeting: meeting),
    );

    if (result != null && context.mounted) {
      try {
        final supabase = ref.read(supabaseClientProvider);
        final tenant = ref.read(currentTenantProvider);

        if (tenant == null) {
          ToastHelper.showError(context, 'Kein Tenant ausgewählt');
          return;
        }

        if (meeting == null) {
          // Create new
          await supabase.from('meetings').insert({
            'tenantId': tenant.id,
            'date': result.date,
            'notes': result.notes,
          });
          if (context.mounted) {
            ToastHelper.showSuccess(context, 'Sitzung erstellt');
          }
        } else {
          // Update existing
          await supabase.from('meetings').update({
            'date': result.date,
            'notes': result.notes,
          }).eq('id', meeting.id!);
          if (context.mounted) {
            ToastHelper.showSuccess(context, 'Sitzung aktualisiert');
          }
        }

        ref.invalidate(meetingsListProvider);
      } catch (e) {
        if (context.mounted) {
          ToastHelper.showError(context, 'Fehler: $e');
        }
      }
    }
  }

  Future<void> _deleteMeeting(BuildContext context, WidgetRef ref, MeetingData meeting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sitzung löschen?'),
        content: Text('Möchtest du die Sitzung vom ${meeting.formattedDate} wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final supabase = ref.read(supabaseClientProvider);
        await supabase.from('meetings').delete().eq('id', meeting.id!);
        ref.invalidate(meetingsListProvider);
        if (context.mounted) {
          ToastHelper.showSuccess(context, 'Sitzung gelöscht');
        }
      } catch (e) {
        if (context.mounted) {
          ToastHelper.showError(context, 'Fehler: $e');
        }
      }
    }
  }
}

class _MeetingListItem extends StatelessWidget {
  const _MeetingListItem({
    required this.meeting,
    required this.onTap,
    required this.onDelete,
  });

  final MeetingData meeting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(meeting.date);

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                meeting.weekdayName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                date?.day.toString() ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          meeting.formattedDate,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: meeting.notes != null && meeting.notes!.isNotEmpty
            ? Text(
                meeting.notes!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.medium),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _MeetingEditDialog extends StatefulWidget {
  const _MeetingEditDialog({this.meeting});

  final MeetingData? meeting;

  @override
  State<_MeetingEditDialog> createState() => _MeetingEditDialogState();
}

class _MeetingEditDialogState extends State<_MeetingEditDialog> {
  late DateTime _selectedDate;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.meeting != null
        ? DateTime.tryParse(widget.meeting!.date) ?? DateTime.now()
        : DateTime.now();
    _notesController.text = widget.meeting?.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('de', 'DE'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.meeting != null;

    return AlertDialog(
      title: Text(isEditing ? 'Sitzung bearbeiten' : 'Neue Sitzung'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Datum'),
              subtitle: Text(DateFormat('EEEE, dd.MM.yyyy', 'de_DE').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notizen (optional)',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(MeetingData(
              id: widget.meeting?.id,
              tenantId: widget.meeting?.tenantId ?? 0,
              date: _selectedDate.toIso8601String().split('T')[0],
              notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
            ));
          },
          child: Text(isEditing ? 'Speichern' : 'Erstellen'),
        ),
      ],
    );
  }
}
