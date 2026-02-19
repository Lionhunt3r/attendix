import 'package:flutter/material.dart';
import '../../../core/constants/enums.dart';

/// Badge that displays attendance status with appropriate color and text
///
/// Based on Ionic overview.page.ts lines 388-401
class StatusBadge extends StatelessWidget {
  final AttendanceStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getText(),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.excused:
        return Colors.orange;
      case AttendanceStatus.late:
        return Colors.purple;
      case AttendanceStatus.lateExcused:
        return Colors.pink;
      case AttendanceStatus.neutral:
        return Colors.grey;
    }
  }

  String _getText() {
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
}
