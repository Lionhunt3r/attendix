import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/attendance/attendance.dart';

/// Accordion widget for displaying attendance plan/schedule
class PlanAccordion extends StatelessWidget {
  const PlanAccordion({
    super.key,
    required this.attendance,
    required this.onEdit,
    required this.onExportPdf,
    required this.onSharePlanChanged,
  });

  final Attendance attendance;
  final VoidCallback onEdit;
  final VoidCallback onExportPdf;
  final void Function(bool) onSharePlanChanged;

  @override
  Widget build(BuildContext context) {
    final plan = attendance.plan;
    final hasPlan = plan != null && plan.isNotEmpty;

    // Parse plan fields
    List<Map<String, dynamic>> fields = [];
    if (hasPlan && plan['fields'] != null) {
      fields = (plan['fields'] as List).cast<Map<String, dynamic>>();
    }

    final startTime = plan?['startTime'] as String? ?? attendance.startTime ?? '17:00';
    final endTime = plan?['endTime'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.schedule, color: AppColors.primary),
        title: Row(
          children: [
            const Text('Ablaufplan'),
            const SizedBox(width: 8),
            if (hasPlan && startTime.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  endTime != null ? '$startTime - $endTime' : startTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
            const Spacer(),
            // Share plan toggle indicator
            if (attendance.sharePlan)
              Tooltip(
                message: 'Plan wird mit Mitgliedern geteilt',
                child: Icon(
                  Icons.share,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
        children: [
          // Share plan toggle
          SwitchListTile(
            secondary: const Icon(Icons.share),
            title: const Text('Plan teilen'),
            subtitle: Text(
              attendance.sharePlan
                  ? 'Plan ist für Mitglieder sichtbar'
                  : 'Plan ist nur für Dirigenten sichtbar',
              style: TextStyle(fontSize: 12, color: AppColors.medium),
            ),
            value: attendance.sharePlan,
            onChanged: onSharePlanChanged,
          ),
          const Divider(height: 1),
          if (!hasPlan || fields.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingM),
              child: Text(
                'Kein Ablaufplan vorhanden',
                style: TextStyle(color: AppColors.medium),
              ),
            )
          else
            ...fields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              final name = field['name'] as String? ?? 'Unbekannt';
              final time = field['time'] as String? ?? '0';
              final conductor = field['conductor'] as String?;

              // Calculate start time for this field
              String calculatedTime = _calculateFieldTime(startTime, fields, index);

              return ListTile(
                leading: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.medium.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    calculatedTime,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                title: Text(name),
                subtitle: conductor != null ? Text(conductor) : null,
                trailing: Text(
                  '$time Min.',
                  style: const TextStyle(color: AppColors.medium),
                ),
                dense: true,
              );
            }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Bearbeiten'),
                ),
                TextButton.icon(
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF exportieren'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate the start time for a field at given index
  String _calculateFieldTime(String startTime, List<Map<String, dynamic>> fields, int index) {
    final parts = startTime.split(':');
    if (parts.length != 2) return startTime;

    int hours = int.tryParse(parts[0]) ?? 17;
    int minutes = int.tryParse(parts[1]) ?? 0;

    // Add up all previous field times
    for (var i = 0; i < index; i++) {
      final fieldTime = int.tryParse(fields[i]['time']?.toString() ?? '0') ?? 0;
      minutes += fieldTime;
    }

    // Convert overflow minutes to hours
    hours += minutes ~/ 60;
    minutes = minutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
