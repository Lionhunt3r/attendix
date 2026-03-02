import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';

/// Accordion section displaying person history (attendance + changes).
class HistorieAccordion extends ConsumerWidget {
  const HistorieAccordion({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.historyAsync,
    required this.statsAsync,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final AsyncValue<List<Map<String, dynamic>>> historyAsync;
  final AsyncValue<Map<String, dynamic>> statsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Historie',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: onToggle,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingM,
                0,
                AppDimensions.paddingM,
                AppDimensions.paddingM,
              ),
              child: _buildContent(context),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return historyAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingL),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (history) {
        if (history.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.paddingL),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: AppColors.medium),
                  SizedBox(height: AppDimensions.paddingS),
                  Text('Keine Historie vorhanden'),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Stats summary row
            _buildStatsRow(),

            // History items
            ...history.take(20).map((item) => _buildHistoryItem(item)),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final percentage = stats['percentage'] as int;
        final lateCount = stats['lateCount'] as int;
        final lateText = lateCount > 0 ? ' (${lateCount}x zu spät)' : '';
        final badgeColor = percentage >= 75
            ? AppColors.success
            : percentage >= 50
                ? AppColors.warning
                : AppColors.danger;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Durchschnitt$lateText',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final date = DateTime.tryParse(item['date'] ?? '');
    final type = item['type'] as int?;
    final text = item['text']?.toString() ?? '';
    final meetingName = item['meetingName']?.toString();
    final notes = item['notes']?.toString();

    // Determine display title
    String displayTitle = '';
    if (type == PlayerHistoryType.attendance.value) {
      displayTitle = meetingName ?? '';
    } else {
      switch (type) {
        case 0: // paused
          displayTitle = 'Pausiert';
          break;
        case 5: // active
          displayTitle = 'Wieder aktiv';
          break;
        case 6: // instrumentChange
          displayTitle = 'Gruppenwechsel';
          break;
        case 7: // archived
          displayTitle = 'Archiviert';
          break;
        default:
          displayTitle = item['title']?.toString() ?? 'Eintrag';
      }
    }

    // Build badge for attendance status
    String? badgeText;
    Color? badgeColor;
    if (type == PlayerHistoryType.attendance.value) {
      if (text == 'X') {
        badgeText = '✓';
        badgeColor = AppColors.success;
      } else if (text == 'L') {
        badgeText = 'L';
        badgeColor = AppColors.tertiary;
      } else if (text == 'E') {
        badgeText = 'E';
        badgeColor = AppColors.warning;
      } else if (text == 'N') {
        badgeText = 'N';
        badgeColor = AppColors.medium;
      } else {
        badgeText = 'A';
        badgeColor = AppColors.danger;
      }
    }

    final dateStr = date != null ? DateFormat('dd.MM.yyyy').format(date) : '';
    final titleStr = displayTitle.isNotEmpty ? '$dateStr | $displayTitle' : dateStr;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titleStr, style: const TextStyle(fontSize: 15)),
                if (notes != null && notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      notes,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                if (type != PlayerHistoryType.attendance.value && text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      text,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
          ),
          if (badgeText != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
