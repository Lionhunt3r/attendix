import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/color_utils.dart';
import '../../../../../data/models/attendance/attendance.dart';

/// Accordion widget for displaying and editing general attendance info
/// Uses StatefulWidget to properly manage TextEditingController lifecycle
class GeneralInfoAccordion extends StatefulWidget {
  const GeneralInfoAccordion({
    super.key,
    required this.attendance,
    required this.attendanceType,
    required this.onTypeInfoChanged,
    required this.onNotesChanged,
    required this.onStartTimeSelect,
    required this.onEndTimeSelect,
    required this.onDeadlineToggle,
    required this.onDeadlineSelect,
    required this.onExportExcel,
  });

  final Attendance attendance;
  final AttendanceType? attendanceType;
  final void Function(String) onTypeInfoChanged;
  final void Function(String) onNotesChanged;
  final VoidCallback onStartTimeSelect;
  final VoidCallback onEndTimeSelect;
  final void Function(bool) onDeadlineToggle;
  final VoidCallback onDeadlineSelect;
  final VoidCallback onExportExcel;

  @override
  State<GeneralInfoAccordion> createState() => _GeneralInfoAccordionState();
}

class _GeneralInfoAccordionState extends State<GeneralInfoAccordion> {
  late TextEditingController _typeInfoController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _typeInfoController = TextEditingController(text: widget.attendance.typeInfo ?? '');
    _notesController = TextEditingController(text: widget.attendance.notes ?? '');
  }

  @override
  void didUpdateWidget(GeneralInfoAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if attendance data changed externally
    if (oldWidget.attendance.typeInfo != widget.attendance.typeInfo) {
      _typeInfoController.text = widget.attendance.typeInfo ?? '';
    }
    if (oldWidget.attendance.notes != widget.attendance.notes) {
      _notesController.text = widget.attendance.notes ?? '';
    }
  }

  @override
  void dispose() {
    _typeInfoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDeadline = widget.attendance.deadline != null;
    final isAllDay = widget.attendanceType?.allDay ?? false;

    String? formattedDeadline;
    if (hasDeadline && widget.attendance.deadline != null) {
      final deadline = DateTime.tryParse(widget.attendance.deadline!);
      if (deadline != null) {
        formattedDeadline = DateFormat('dd.MM.yyyy HH:mm').format(deadline);
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline, color: AppColors.primary),
        title: const Text('Allgemein'),
        children: [
          // Type badge (read-only)
          if (widget.attendanceType != null)
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Typ'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorUtils.parseNamedColor(widget.attendanceType!.color)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  widget.attendanceType!.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              dense: true,
            ),

          // TypeInfo TextField
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Bezeichnung',
                hintText: 'z.B. Generalprobe, Konzert...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              controller: _typeInfoController,
              onSubmitted: widget.onTypeInfoChanged,
            ),
          ),

          // Notes TextField
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Notizen',
                hintText: 'Allgemeine Notizen...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_outlined),
              ),
              controller: _notesController,
              maxLines: 2,
              onSubmitted: widget.onNotesChanged,
            ),
          ),

          // Time pickers (if not all-day)
          if (!isAllDay) ...[
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Beginn'),
              trailing: Text(
                widget.attendance.startTime ?? 'Nicht gesetzt',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: widget.onStartTimeSelect,
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.access_time_filled),
              title: const Text('Ende'),
              trailing: Text(
                widget.attendance.endTime ?? 'Nicht gesetzt',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: widget.onEndTimeSelect,
              dense: true,
            ),
          ],

          // Duration (if all-day)
          if (isAllDay)
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Dauer'),
              trailing: Text(
                '${widget.attendance.durationDays ?? 1} Tag(e)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              dense: true,
            ),

          const Divider(),

          // Deadline toggle
          SwitchListTile(
            secondary: const Icon(Icons.event_busy),
            title: const Text('Anmeldefrist'),
            subtitle: hasDeadline && formattedDeadline != null
                ? Text(formattedDeadline)
                : const Text('Nicht gesetzt'),
            value: hasDeadline,
            onChanged: widget.onDeadlineToggle,
          ),

          // Deadline picker (if enabled)
          if (hasDeadline)
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('Frist ändern'),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onDeadlineSelect,
              dense: true,
            ),

          const Divider(),

          // Export button
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: TextButton.icon(
              onPressed: widget.onExportExcel,
              icon: const Icon(Icons.table_chart),
              label: const Text('Als Excel exportieren'),
            ),
          ),
        ],
      ),
    );
  }
}
