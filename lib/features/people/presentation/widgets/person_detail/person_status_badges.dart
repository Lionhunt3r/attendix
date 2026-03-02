import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/person/person.dart';

/// Widget displaying status badges for a person (archived, paused, critical, etc.).
class PersonStatusBadges extends StatelessWidget {
  const PersonStatusBadges({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final badges = _buildBadges();
    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Wrap(
        spacing: AppDimensions.paddingS,
        runSpacing: AppDimensions.paddingS,
        children: badges,
      ),
    );
  }

  bool get hasStatusBadges =>
      person.archived ||
      person.paused ||
      person.isCritical ||
      person.pending ||
      person.isLeader;

  List<Widget> _buildBadges() {
    final badges = <Widget>[];
    if (person.archived) {
      badges.add(const _StatusBadge(
        label: 'Archiviert',
        color: AppColors.medium,
        icon: Icons.archive,
      ));
    }
    if (person.paused) {
      final label = person.pausedUntil != null
          ? 'Pausiert bis ${_formatDate(person.pausedUntil!)}'
          : 'Pausiert';
      badges.add(_StatusBadge(
        label: label,
        color: AppColors.warning,
        icon: Icons.pause_circle,
      ));
    }
    if (person.isCritical) {
      badges.add(const _StatusBadge(
        label: 'Kritisch',
        color: AppColors.danger,
        icon: Icons.warning,
      ));
    }
    if (person.pending) {
      badges.add(const _StatusBadge(
        label: 'Ausstehend',
        color: AppColors.info,
        icon: Icons.hourglass_empty,
      ));
    }
    if (person.isLeader) {
      badges.add(const _StatusBadge(
        label: 'Stimmführer',
        color: AppColors.success,
        icon: Icons.star,
      ));
    }
    return badges;
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return DateFormat('dd.MM.yyyy').format(date);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
