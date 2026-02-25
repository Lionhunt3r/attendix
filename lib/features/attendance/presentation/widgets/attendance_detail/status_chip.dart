import 'package:flutter/material.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/enums.dart';

/// Compact status indicator chip for person tiles
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    required this.onTap,
  });

  final AttendanceStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final icon = _getCompactIcon(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingS,
          vertical: AppDimensions.paddingXS,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  /// Compact icons for status chip (smaller, simpler than full icons)
  IconData _getCompactIcon(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.present => Icons.check,
      AttendanceStatus.absent => Icons.close,
      AttendanceStatus.excused => Icons.event_busy,
      AttendanceStatus.late => Icons.schedule,
      AttendanceStatus.lateExcused => Icons.schedule,
      AttendanceStatus.neutral => Icons.remove,
    };
  }
}
