import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/debug_providers.dart';
import '../../../../core/providers/meeting_providers.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/meeting/meeting.dart';

/// Meetings list page
class MeetingsListPage extends ConsumerWidget {
  const MeetingsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(meetingsProvider);
    // BL-003: Add role check for FAB visibility
    final role = ref.watch(effectiveRoleProvider);

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
                onPressed: () => ref.invalidate(meetingsProvider),
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
                  // FN-012: Show role-appropriate empty state text
                  if (role.canEdit)
                    Text(
                      'Erstelle die erste Sitzung',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.medium),
                    )
                  else
                    Text(
                      'Noch keine Sitzungen vorhanden',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.medium),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            // FN-006: await provider.future to show spinner until data loads
            onRefresh: () async {
              ref.invalidate(meetingsProvider);
              await ref.read(meetingsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                final meeting = meetings[index];
                return _MeetingListItem(
                  meeting: meeting,
                  onTap: () => context.push('/settings/meetings/${meeting.id}'),
                  onDelete: () => _deleteMeeting(context, ref, meeting),
                );
              },
            ),
          );
        },
      ),
      // BL-003: Only show FAB for users who can edit
      floatingActionButton: role.canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateMeetingDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Neue Sitzung'),
            )
          : null,
    );
  }

  Future<void> _showCreateMeetingDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => const _MeetingCreateDialog(),
    );

    if (result != null && context.mounted) {
      final tenant = ref.read(currentTenantProvider);
      if (tenant == null) {
        ToastHelper.showError(context, 'Kein Tenant ausgewählt');
        return;
      }

      final notifier = ref.read(meetingNotifierProvider.notifier);
      final newMeeting = Meeting(
        tenantId: tenant.id!,
        date: result.toIso8601String().split('T')[0],
      );

      final created = await notifier.createMeeting(newMeeting);
      if (created != null && context.mounted) {
        ToastHelper.showSuccess(context, 'Sitzung erstellt');
        // Navigate to detail page to edit
        context.push('/settings/meetings/${created.id}');
      } else if (context.mounted) {
        ToastHelper.showError(context, 'Fehler beim Erstellen');
      }
    }
  }

  Future<void> _deleteMeeting(BuildContext context, WidgetRef ref, Meeting meeting) async {
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
      final notifier = ref.read(meetingNotifierProvider.notifier);
      await notifier.deleteMeeting(meeting.id!);
      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Sitzung gelöscht');
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

  final Meeting meeting;
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
        subtitle: _buildSubtitle(),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final hasNotes = meeting.notes != null && meeting.notes!.isNotEmpty;
    final hasAttendees = meeting.attendeeIds != null && meeting.attendeeIds!.isNotEmpty;

    if (!hasNotes && !hasAttendees) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAttendees)
          Text(
            '${meeting.attendeeIds!.length} Teilnehmer',
            // FN-011: Use const for better performance
            style: const TextStyle(color: AppColors.medium, fontSize: 12),
          ),
        if (hasNotes)
          Text(
            meeting.notes!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // FN-011: Use const for better performance
            style: const TextStyle(color: AppColors.medium),
          ),
      ],
    );
  }
}

class _MeetingCreateDialog extends StatefulWidget {
  const _MeetingCreateDialog();

  @override
  State<_MeetingCreateDialog> createState() => _MeetingCreateDialogState();
}

class _MeetingCreateDialogState extends State<_MeetingCreateDialog> {
  DateTime _selectedDate = DateTime.now();

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
    return AlertDialog(
      title: const Text('Neue Sitzung'),
      content: ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Datum'),
        subtitle: Text(DateFormat('EEEE, dd.MM.yyyy', 'de_DE').format(_selectedDate)),
        trailing: const Icon(Icons.calendar_today),
        onTap: _selectDate,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedDate),
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}
