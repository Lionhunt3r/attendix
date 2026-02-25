import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/person/person.dart';

/// Bottom status bar showing attendance summary statistics
class AttendanceStatusBar extends StatelessWidget {
  const AttendanceStatusBar({
    super.key,
    required this.persons,
    required this.localStatuses,
  });

  final List<Person> persons;
  final Map<int, AttendanceStatus> localStatuses;

  @override
  Widget build(BuildContext context) {
    final total = persons.length;
    // Count present (including late as they are physically present)
    final present = localStatuses.values.where((s) =>
        s == AttendanceStatus.present ||
        s == AttendanceStatus.late ||
        s == AttendanceStatus.lateExcused).length;
    // Count excused (but not lateExcused as those are counted in present)
    final excused = localStatuses.values.where((s) => s == AttendanceStatus.excused).length;
    final absent = localStatuses.values.where((s) => s == AttendanceStatus.absent).length;
    // Unknown = neutral status (not yet recorded)
    final unknown = localStatuses.values.where((s) => s == AttendanceStatus.neutral).length;
    final percentage = total > 0 ? (present / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Anwesend',
              value: '$present',
              color: AppColors.success,
            ),
            _StatItem(
              label: 'Entsch.',
              value: '$excused',
              color: AppColors.info,
            ),
            _StatItem(
              label: 'Abwesend',
              value: '$absent',
              color: AppColors.danger,
            ),
            _StatItem(
              label: 'Offen',
              value: '$unknown',
              color: AppColors.medium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              ),
              child: Text(
                '${percentage.round()}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.medium,
          ),
        ),
      ],
    );
  }
}
