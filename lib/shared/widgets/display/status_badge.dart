import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_colors.dart';

/// Badge variant styles
enum StatusBadgeVariant {
  /// Filled background with white text
  filled,

  /// Border only with colored text
  outlined,

  /// Subtle background with colored text
  subtle,
}

/// Badge sizes
enum StatusBadgeSize {
  small,
  medium,
  large,
}

/// Badge that displays attendance status with appropriate color and text
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.variant = StatusBadgeVariant.filled,
    this.size = StatusBadgeSize.medium,
    this.showLabel = false,
    this.showIcon = true,
    @Deprecated('Use size instead') this.compact = false,
  });

  final AttendanceStatus status;
  final StatusBadgeVariant variant;
  final StatusBadgeSize size;
  final bool showLabel;
  final bool showIcon;
  @Deprecated('Use size instead')
  final bool compact;

  Color get _color {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.excused:
        return AppColors.warning;
      case AttendanceStatus.late:
        return AppColors.statusLate;
      case AttendanceStatus.lateExcused:
        return AppColors.statusLateExcused;
      case AttendanceStatus.neutral:
        return AppColors.medium;
    }
  }

  String get _shortText {
    switch (status) {
      case AttendanceStatus.present:
        return '✓';
      case AttendanceStatus.absent:
        return 'A';
      case AttendanceStatus.excused:
        return 'E';
      case AttendanceStatus.late:
        return 'L';
      case AttendanceStatus.lateExcused:
        return 'LE';
      case AttendanceStatus.neutral:
        return 'N';
    }
  }

  String get _label {
    switch (status) {
      case AttendanceStatus.present:
        return 'Anwesend';
      case AttendanceStatus.absent:
        return 'Abwesend';
      case AttendanceStatus.excused:
        return 'Entschuldigt';
      case AttendanceStatus.late:
        return 'Verspätet';
      case AttendanceStatus.lateExcused:
        return 'Versp. entsch.';
      case AttendanceStatus.neutral:
        return 'Neutral';
    }
  }

  EdgeInsets get _padding {
    // Handle deprecated compact parameter
    if (compact) {
      return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
    }

    switch (size) {
      case StatusBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case StatusBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case StatusBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  double get _fontSize {
    // Handle deprecated compact parameter
    if (compact) return 12;

    switch (size) {
      case StatusBadgeSize.small:
        return 11;
      case StatusBadgeSize.medium:
        return 13;
      case StatusBadgeSize.large:
        return 15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = showLabel ? _label : (showIcon ? _shortText : _label);

    switch (variant) {
      case StatusBadgeVariant.filled:
        return _FilledBadge(
          color: _color,
          text: displayText,
          padding: _padding,
          fontSize: _fontSize,
        );
      case StatusBadgeVariant.outlined:
        return _OutlinedBadge(
          color: _color,
          text: displayText,
          padding: _padding,
          fontSize: _fontSize,
        );
      case StatusBadgeVariant.subtle:
        return _SubtleBadge(
          color: _color,
          text: displayText,
          padding: _padding,
          fontSize: _fontSize,
        );
    }
  }
}

class _FilledBadge extends StatelessWidget {
  const _FilledBadge({
    required this.color,
    required this.text,
    required this.padding,
    required this.fontSize,
  });

  final Color color;
  final String text;
  final EdgeInsets padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OutlinedBadge extends StatelessWidget {
  const _OutlinedBadge({
    required this.color,
    required this.text,
    required this.padding,
    required this.fontSize,
  });

  final Color color;
  final String text;
  final EdgeInsets padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SubtleBadge extends StatelessWidget {
  const _SubtleBadge({
    required this.color,
    required this.text,
    required this.padding,
    required this.fontSize,
  });

  final Color color;
  final String text;
  final EdgeInsets padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Interactive status chip for selecting attendance status
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    required this.onTap,
    this.isSelected = false,
    this.size = StatusBadgeSize.medium,
  });

  final AttendanceStatus status;
  final VoidCallback onTap;
  final bool isSelected;
  final StatusBadgeSize size;

  Color get _color {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.excused:
        return AppColors.warning;
      case AttendanceStatus.late:
        return AppColors.statusLate;
      case AttendanceStatus.lateExcused:
        return AppColors.statusLateExcused;
      case AttendanceStatus.neutral:
        return AppColors.medium;
    }
  }

  IconData get _icon {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check;
      case AttendanceStatus.absent:
        return Icons.close;
      case AttendanceStatus.excused:
        return Icons.event_busy;
      case AttendanceStatus.late:
        return Icons.schedule;
      case AttendanceStatus.lateExcused:
        return Icons.history;
      case AttendanceStatus.neutral:
        return Icons.remove;
    }
  }

  double get _iconSize {
    switch (size) {
      case StatusBadgeSize.small:
        return 16;
      case StatusBadgeSize.medium:
        return 20;
      case StatusBadgeSize.large:
        return 24;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case StatusBadgeSize.small:
        return const EdgeInsets.all(6);
      case StatusBadgeSize.medium:
        return const EdgeInsets.all(8);
      case StatusBadgeSize.large:
        return const EdgeInsets.all(10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: _padding,
          decoration: BoxDecoration(
            color: isSelected ? _color.withValues(alpha: 0.2) : _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
            border: Border.all(
              color: isSelected ? _color : _color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Icon(
            _icon,
            size: _iconSize,
            color: _color,
          ),
        ),
      ),
    );
  }
}
