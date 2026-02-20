import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/attendance/attendance.dart';
import '../../../../core/providers/tenant_providers.dart';

/// Provider for attendance list
final attendanceListProvider = FutureProvider<List<Attendance>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('attendance')
      .select('*')
      .eq('tenantId', tenant.id!)
      .order('date', ascending: false)
      .limit(50);

  return (response as List)
      .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Attendance list page
class AttendanceListPage extends ConsumerWidget {
  const AttendanceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenant = ref.watch(currentTenantProvider);
    final attendanceAsync = ref.watch(attendanceListProvider);

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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.danger,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Text('Fehler: $error'),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: () => ref.refresh(attendanceListProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (attendances) {
          if (attendances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 80,
                    color: AppColors.medium,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(
                    'Keine Anwesenheiten',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    'Erstelle die erste Anwesenheitsliste',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.medium,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final groupedAttendances = <String, List<Attendance>>{};
          for (final attendance in attendances) {
            final dateKey = attendance.formattedDate;
            groupedAttendances.putIfAbsent(dateKey, () => []).add(attendance);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(attendanceListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              itemCount: groupedAttendances.length,
              itemBuilder: (context, index) {
                final dateKey = groupedAttendances.keys.elementAt(index);
                final items = groupedAttendances[dateKey]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0) const SizedBox(height: AppDimensions.paddingM),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.paddingS,
                        horizontal: AppDimensions.paddingXS,
                      ),
                      child: Text(
                        _getDateLabel(items.first.date),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.medium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...items.map((attendance) => _AttendanceListItem(
                      attendance: attendance,
                      onTap: () => context.push('/attendance/${attendance.id}'),
                    )),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/attendance/new'),
        icon: const Icon(Icons.add),
        label: const Text('Neue Anwesenheit'),
      ),
    );
  }

  String _getDateLabel(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return dateString;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Heute';
    } else if (dateOnly == yesterday) {
      return 'Gestern';
    } else {
      final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      final weekday = weekdays[date.weekday - 1];
      return '$weekday, ${date.day}.${date.month}.${date.year}';
    }
  }
}

class _AttendanceListItem extends StatelessWidget {
  const _AttendanceListItem({
    required this.attendance,
    required this.onTap,
  });

  final Attendance attendance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rate = attendance.percentage ?? 0.0;
    final rateColor = rate >= 80
        ? AppColors.success
        : rate >= 60
            ? AppColors.warning
            : AppColors.danger;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: attendance.isToday
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                attendance.weekdayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: attendance.isToday ? AppColors.primary : AppColors.dark,
                ),
              ),
              Text(
                _getDayNumber(attendance.date),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: attendance.isToday ? AppColors.primary : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          attendance.typeInfo ?? 'Anwesenheit',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attendance.startTime != null || attendance.endTime != null)
              Text(
                _formatTimeRange(attendance.startTime, attendance.endTime),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.medium,
                ),
              ),
            if (attendance.notes != null && attendance.notes!.isNotEmpty)
              Text(
                attendance.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.medium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: attendance.percentage != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${rate.round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: rateColor,
                    ),
                  ),
                ],
              )
            : const Icon(
                Icons.chevron_right,
                color: AppColors.medium,
              ),
      ),
    );
  }

  String _getDayNumber(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return '';
    return date.day.toString();
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
              title: Text(attendance.typeInfo ?? 'Anwesenheit'),
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