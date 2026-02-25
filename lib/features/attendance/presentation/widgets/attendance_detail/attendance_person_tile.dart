import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/person/person.dart';
import 'status_chip.dart';

/// Tile displaying a person with their attendance status and actions
class AttendancePersonTile extends StatelessWidget {
  const AttendancePersonTile({
    super.key,
    required this.person,
    required this.status,
    required this.notes,
    required this.availableStatuses,
    required this.onStatusChanged,
    required this.onNoteChanged,
    required this.onShowModifierInfo,
    required this.onRemoveFromAttendance,
  });

  final Person person;
  final AttendanceStatus status;
  final String? notes;
  final List<AttendanceStatus> availableStatuses;
  final void Function(AttendanceStatus) onStatusChanged;
  final void Function(String?) onNoteChanged;
  final VoidCallback onShowModifierInfo;
  final VoidCallback onRemoveFromAttendance;

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes?.isNotEmpty == true;

    return Slidable(
      key: ValueKey(person.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onRemoveFromAttendance(),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: Icons.person_remove,
            label: 'Entfernen',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          // Neutral status swipe action (if not already neutral)
          if (status != AttendanceStatus.neutral)
            SlidableAction(
              onPressed: (_) => onStatusChanged(AttendanceStatus.neutral),
              backgroundColor: AppColors.medium,
              foregroundColor: Colors.white,
              icon: Icons.remove_circle_outline,
              label: 'Neutral',
            ),
          SlidableAction(
            onPressed: (_) => _showNoteDialog(context),
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            icon: hasNotes ? Icons.edit_note : Icons.note_add,
            label: 'Notiz',
          ),
          SlidableAction(
            onPressed: (_) => onShowModifierInfo(),
            backgroundColor: AppColors.tertiary,
            foregroundColor: Colors.white,
            icon: Icons.info_outline,
            label: 'Info',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingXS),
        child: InkWell(
          onTap: () => _showStatusPicker(context),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: status.color.withValues(alpha: 0.2),
                  backgroundImage: person.img != null ? NetworkImage(person.img!) : null,
                  child: person.img == null
                      ? Text(
                          person.initials,
                          style: TextStyle(
                            color: status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppDimensions.paddingM),

                // Name and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            person.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (hasNotes) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.sticky_note_2,
                              size: 14,
                              color: AppColors.info,
                            ),
                          ],
                        ],
                      ),
                      if (person.groupName != null)
                        Text(
                          person.groupName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.medium,
                          ),
                        ),
                    ],
                  ),
                ),

                // Status indicator
                StatusChip(
                  status: status,
                  onTap: () => _showStatusPicker(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context) {
    final controller = TextEditingController(text: notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notiz für ${person.fullName}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Notiz eingeben...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          if (notes?.isNotEmpty == true)
            TextButton(
              onPressed: () {
                onNoteChanged(null);
                Navigator.of(ctx).pop();
              },
              child: const Text('Löschen', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final newNotes = controller.text.trim();
              onNoteChanged(newNotes.isEmpty ? null : newNotes);
              Navigator.of(ctx).pop();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                person.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Status auswählen'),
            ),
            const Divider(),
            ...availableStatuses.map((s) => ListTile(
              leading: Icon(
                s.icon,
                color: s.color,
              ),
              title: Text(s.label),
              selected: s == status,
              onTap: () {
                onStatusChanged(s);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: AppDimensions.paddingM),
          ],
        ),
      ),
    );
  }
}
