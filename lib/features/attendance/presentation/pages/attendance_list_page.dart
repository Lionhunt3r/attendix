import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/attendance_type_providers.dart';
import '../../../../core/providers/debug_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/attendance/attendance.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../shared/widgets/loading/loading.dart';
import '../../../../shared/widgets/common/empty_state.dart';
import '../../../../shared/widgets/display/percentage_badge.dart';
import '../../../../shared/widgets/animations/animated_list_item.dart';


/// Provider for attendance list
final attendanceListProvider = FutureProvider<List<Attendance>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  // Guard against null tenant or null tenant.id
  if (tenant?.id == null) return [];

  // Load attendances with person_attendances to calculate percentage
  final response = await supabase
      .from('attendance')
      .select('*, person_attendances(status)')
      .eq('tenantId', tenant!.id!)
      .order('date', ascending: false)
      .limit(50);

  return (response as List).map((e) {
    final attendance = Attendance.fromJson(e as Map<String, dynamic>);

    // Calculate percentage from person_attendances if not already set
    if (attendance.percentage == null || attendance.percentage == 0) {
      final personAttendances = e['person_attendances'] as List?;
      if (personAttendances != null && personAttendances.isNotEmpty) {
        final total = personAttendances.length;
        // Present = status 1, Late = status 4, LateExcused = status 5
        final present = personAttendances.where((pa) {
          final status = pa['status'];
          return status == 1 || status == 4 || status == 5;
        }).length;
        final calculatedPercentage = (present / total * 100).roundToDouble();
        return attendance.copyWith(percentage: calculatedPercentage);
      }
    }
    return attendance;
  }).toList();
});

/// Attendance list page
class AttendanceListPage extends ConsumerWidget {
  const AttendanceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);
    final attendanceAsync = ref.watch(attendanceListProvider);
    // Use effectiveRoleProvider to support debug role override
    final role = ref.watch(effectiveRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anwesenheit'),
            if (tenant != null)
              Text(
                tenant.shortName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.medium,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Kalender',
            onPressed: () => _showCalendarView(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Gruppe wechseln',
            onPressed: () => context.go('/tenants'),
          ),
        ],
      ),
      body: attendanceAsync.when(
        loading: () => const ListSkeleton(
          itemCount: 8,
          showAvatar: true,
          showSubtitle: true,
          showTrailing: true,
        ),
        error: (error, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Fehler beim Laden',
          subtitle: 'Die Anwesenheitsliste konnte nicht geladen werden.',
          actionLabel: 'Erneut versuchen',
          onAction: () => ref.refresh(attendanceListProvider),
        ),
        data: (attendances) {
          if (attendances.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.fact_check_outlined,
              title: 'Keine Anwesenheiten',
              subtitle: 'Erstelle die erste Anwesenheitsliste',
              actionLabel: 'Neue Anwesenheit',
              onAction: () => context.push('/attendance/new'),
            );
          }

          // Get highlighted type IDs from AttendanceTypes (like Ionic)
          final attendanceTypes = ref.watch(attendanceTypesProvider).valueOrNull ?? [];
          final highlightedTypeIds = attendanceTypes
              .where((t) => t.highlight)
              .map((t) => t.id)
              .whereType<String>()
              .toSet();

          // Separate into upcoming and past attendances (like Ionic)
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);

          final upcomingAttendances = <Attendance>[];
          final pastAttendances = <Attendance>[];

          for (final attendance in attendances) {
            final date = DateTime.tryParse(attendance.date);
            if (date == null) {
              pastAttendances.add(attendance);
              continue;
            }
            final dateOnly = DateTime(date.year, date.month, date.day);
            if (dateOnly.isBefore(todayStart)) {
              pastAttendances.add(attendance);
            } else {
              upcomingAttendances.add(attendance);
            }
          }

          // Sort upcoming by date ascending, past by date descending
          upcomingAttendances.sort((a, b) => a.date.compareTo(b.date));
          pastAttendances.sort((a, b) => b.date.compareTo(a.date));

          // Current attendance is the first upcoming one
          Attendance? currentAttendance;
          if (upcomingAttendances.isNotEmpty) {
            currentAttendance = upcomingAttendances.first;
            upcomingAttendances.removeAt(0);
          }

          return RefreshIndicator(
            onRefresh: () async {
              // ignore: unused_result
              ref.refresh(attendanceListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              children: [
                // Current Attendance Section (like Ionic - collapsible)
                if (currentAttendance != null)
                  _CollapsibleSection(
                    title: 'Aktuell',
                    count: 1,
                    initiallyExpanded: true,
                    isPrimary: true,
                    children: [
                      AnimatedListItem(
                        index: 0,
                        child: _AttendanceListItem(
                          attendance: currentAttendance,
                          onTap: () => context.push('/attendance/${currentAttendance!.id}'),
                          isHighlighted: highlightedTypeIds.contains(currentAttendance.typeId),
                        ),
                      ),
                    ],
                  ),

                // Upcoming Attendances Section (collapsible)
                if (upcomingAttendances.isNotEmpty)
                  _CollapsibleSection(
                    title: 'Anstehend',
                    count: upcomingAttendances.length,
                    initiallyExpanded: true,
                    isPrimary: true,
                    children: upcomingAttendances.asMap().entries.map((entry) =>
                      AnimatedListItem(
                        index: entry.key,
                        child: _AttendanceListItem(
                          attendance: entry.value,
                          onTap: () => context.push('/attendance/${entry.value.id}'),
                          isHighlighted: highlightedTypeIds.contains(entry.value.typeId),
                        ),
                      ),
                    ).toList(),
                  ),

                // Past Attendances Section (collapsed by default)
                if (pastAttendances.isNotEmpty)
                  _CollapsibleSection(
                    title: 'Vergangen',
                    count: pastAttendances.length,
                    initiallyExpanded: false,
                    isPrimary: false,
                    children: pastAttendances.asMap().entries.map((entry) =>
                      AnimatedListItem(
                        index: entry.key,
                        child: _AttendanceListItem(
                          attendance: entry.value,
                          onTap: () => context.push('/attendance/${entry.value.id}'),
                          isHighlighted: highlightedTypeIds.contains(entry.value.typeId),
                        ),
                      ),
                    ).toList(),
                  ),
              ],
            ),
          );
        },
      ),
      // FAB only for roles that can add attendances (not VIEWER)
      floatingActionButton: role.canAddAttendance
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/attendance/new'),
              icon: const Icon(Icons.add),
              label: const Text('Neue Anwesenheit'),
            )
          : null,
    );
  }
}

/// Collapsible section widget (like Ionic accordion)
class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.title,
    required this.count,
    required this.children,
    this.initiallyExpanded = true,
    this.isPrimary = true,
  });

  final String title;
  final int count;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool isPrimary;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isPrimary ? AppColors.primary : AppColors.medium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingS,
              horizontal: AppDimensions.paddingXS,
            ),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.chevron_right,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.paddingXS),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...widget.children,
        if (_isExpanded) const SizedBox(height: AppDimensions.paddingM),
      ],
    );
  }
}

class _AttendanceListItem extends StatelessWidget {
  const _AttendanceListItem({
    required this.attendance,
    required this.onTap,
    this.isHighlighted = false,
  });

  final Attendance attendance;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: attendance.isToday
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getMonthShort(attendance.date),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  color: attendance.isToday ? AppColors.primary : AppColors.medium,
                ),
              ),
              Text(
                _getDayNumber(attendance.date),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: attendance.isToday ? AppColors.primary : AppColors.dark,
                ),
              ),
              Text(
                attendance.weekdayName,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  color: attendance.isToday ? AppColors.primary : AppColors.medium,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          attendance.displayTitle,
          style: TextStyle(
            // Dezentes Highlighting: nur fetter Text (wie Ionic)
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attendance.startTime != null || attendance.endTime != null)
              Text(
                _formatTimeRange(attendance.startTime, attendance.endTime),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.medium,
                ),
              ),
            if (attendance.notes != null && attendance.notes!.isNotEmpty)
              Text(
                attendance.notes!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.medium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PercentageBadge(
          percentage: attendance.percentage ?? 0,
          showBackground: true,
        ),
      ),
    );
  }

  String _getDayNumber(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    return date.day.toString();
  }

  String _getMonthShort(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    const months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    return months[date.month - 1];
  }

  String _formatTimeRange(String? start, String? end) {
    if (start == null && end == null) return '';
    if (start != null && end != null) return '$start - $end';
    if (start != null) return 'ab $start';
    return 'bis $end';
  }
}

/// Show calendar view modal
void _showCalendarView(BuildContext context, WidgetRef ref) {
  final attendances = ref.read(attendanceListProvider).valueOrNull ?? [];

  // Build a map of dates to attendances
  final Map<DateTime, List<Attendance>> attendanceMap = {};
  for (final attendance in attendances) {
    final date = DateTime.tryParse(attendance.date);
    if (date != null) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      attendanceMap.putIfAbsent(normalizedDate, () => []).add(attendance);
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CalendarViewSheet(
      attendanceMap: attendanceMap,
      onDateSelected: (date, attendances) {
        Navigator.of(context).pop();
        if (attendances.length == 1) {
          context.push('/attendance/${attendances.first.id}');
        } else if (attendances.length > 1) {
          // Show selection dialog
          _showAttendanceSelectionDialog(context, attendances);
        }
      },
    ),
  );
}

/// Show dialog to select an attendance when multiple exist on the same date
void _showAttendanceSelectionDialog(BuildContext context, List<Attendance> attendances) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('${attendances.length} Anwesenheiten'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: attendances.length,
          itemBuilder: (context, index) {
            final attendance = attendances[index];
            return ListTile(
              title: Text(attendance.displayTitle),
              subtitle: attendance.startTime != null
                  ? Text(attendance.startTime!)
                  : null,
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('/attendance/${attendance.id}');
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Abbrechen'),
        ),
      ],
    ),
  );
}

/// Calendar view sheet widget
class _CalendarViewSheet extends StatefulWidget {
  const _CalendarViewSheet({
    required this.attendanceMap,
    required this.onDateSelected,
  });

  final Map<DateTime, List<Attendance>> attendanceMap;
  final void Function(DateTime date, List<Attendance> attendances) onDateSelected;

  @override
  State<_CalendarViewSheet> createState() => _CalendarViewSheetState();
}

class _CalendarViewSheetState extends State<_CalendarViewSheet> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Attendance> _getAttendancesForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return widget.attendanceMap[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.medium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kalender',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Calendar
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: TableCalendar<Attendance>(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  locale: 'de_DE',
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getAttendancesForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    final attendances = _getAttendancesForDay(selectedDay);
                    if (attendances.isNotEmpty) {
                      widget.onDateSelected(selectedDay, attendances);
                    }
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      return Positioned(
                        bottom: 1,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: events.take(3).map((event) {
                            return Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _getAttendanceColor(event),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getAttendanceColor(Attendance attendance) {
    // Color based on percentage if available
    if (attendance.percentage != null) {
      if (attendance.percentage! >= 80) return AppColors.success;
      if (attendance.percentage! >= 60) return AppColors.warning;
      return AppColors.danger;
    }
    return AppColors.primary;
  }
}