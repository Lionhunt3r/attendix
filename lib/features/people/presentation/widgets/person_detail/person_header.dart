import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/person/person.dart';

/// Header widget displaying person avatar, group, and attendance stats.
class PersonHeader extends StatelessWidget {
  const PersonHeader({
    super.key,
    required this.person,
    required this.statsAsync,
  });

  final Person person;
  final AsyncValue<Map<String, dynamic>> statsAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            person.isCritical ? AppColors.danger : AppColors.primary,
            (person.isCritical ? AppColors.danger : AppColors.primary)
                .withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'person-${person.id}',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage:
                  person.img != null && !person.img!.contains('.svg')
                      ? NetworkImage(person.img!)
                      : null,
              child: person.img == null || person.img!.contains('.svg')
                  ? Text(
                      person.initials,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          if (person.groupName != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
              ),
              child: Text(
                person.groupName!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: AppDimensions.paddingM),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatItem(
                  value: '${stats['percentage']}%',
                  label: stats['lateCount'] > 0
                      ? 'Anwesenheit (${stats['lateCount']}x zu spät)'
                      : 'Anwesenheit',
                  color: stats['percentage'] >= 75
                      ? AppColors.success
                      : stats['percentage'] >= 50
                          ? AppColors.warning
                          : AppColors.danger,
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                  ),
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _StatItem(
                  value: '${stats['attended']}/${stats['total']}',
                  label: 'Termine',
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
