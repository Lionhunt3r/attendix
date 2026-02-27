import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';

/// Shows a modal bottom sheet explaining all attendance status types
void showAttendanceLegendSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AttendanceLegendSheet(),
  );
}

/// Bottom sheet with legend explaining all attendance statuses
class AttendanceLegendSheet extends StatelessWidget {
  const AttendanceLegendSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.medium.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Legende',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Legend items
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  children: const [
                    _LegendItem(
                      status: AttendanceStatus.present,
                      description: 'Person war bei dem Termin anwesend.',
                    ),
                    _LegendItem(
                      status: AttendanceStatus.excused,
                      description: 'Person hat sich im Voraus abgemeldet.',
                    ),
                    _LegendItem(
                      status: AttendanceStatus.late,
                      description: 'Person kam zu spät zum Termin.',
                    ),
                    _LegendItem(
                      status: AttendanceStatus.lateExcused,
                      description: 'Person kam zu spät, hatte aber vorher Bescheid gegeben.',
                    ),
                    _LegendItem(
                      status: AttendanceStatus.absent,
                      description: 'Person war nicht anwesend und hat sich nicht abgemeldet.',
                    ),
                    _LegendItem(
                      status: AttendanceStatus.neutral,
                      description: 'Status wurde noch nicht eingetragen.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final AttendanceStatus status;
  final String description;

  const _LegendItem({
    required this.status,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              status.icon,
              color: status.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.medium,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
