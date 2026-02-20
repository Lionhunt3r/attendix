import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/attendance/attendance.dart';
import '../../../../core/providers/tenant_providers.dart';

/// Provider for attendance types
final attendanceTypesProvider = FutureProvider<List<AttendanceType>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  // Guard against null tenant or null tenant.id
  if (tenant?.id == null) return [];

  final response = await supabase
      .from('attendance_types')
      .select('*')
      .eq('tenant_id', tenant!.id!)
      .eq('visible', true)
      .order('index', ascending: true);

  return (response as List)
      .map((e) => AttendanceType.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Page for creating a new attendance
class AttendanceCreatePage extends ConsumerStatefulWidget {
  const AttendanceCreatePage({super.key});

  @override
  ConsumerState<AttendanceCreatePage> createState() => _AttendanceCreatePageState();
}

class _AttendanceCreatePageState extends ConsumerState<AttendanceCreatePage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  AttendanceType? _selectedType;
  String? _notes;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(attendanceTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Anwesenheit'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _createAttendance,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Erstellen'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            _SectionCard(
              title: 'Datum',
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: Text(
                  DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(_selectedDate),
                ),
                subtitle: _isToday(_selectedDate)
                    ? const Text('Heute', style: TextStyle(color: AppColors.success))
                    : null,
                trailing: const Icon(Icons.edit),
                onTap: _pickDate,
              ),
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Attendance type
            _SectionCard(
              title: 'Veranstaltungstyp',
              child: typesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingM),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Text('Fehler: $error'),
                ),
                data: (types) {
                  if (types.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingM),
                      child: Text('Keine Veranstaltungstypen konfiguriert'),
                    );
                  }
                  return Column(
                    children: types.map((type) => RadioListTile<AttendanceType>(
                      value: type,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                          // Set default times from type
                          if (value?.startTime != null) {
                            _startTime = _parseTime(value!.startTime!);
                          }
                          if (value?.endTime != null) {
                            _endTime = _parseTime(value!.endTime!);
                          }
                        });
                      },
                      title: Text(type.name),
                      subtitle: type.startTime != null
                          ? Text('${type.startTime} - ${type.endTime ?? '?'}')
                          : null,
                      secondary: type.color != null
                          ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _parseColor(type.color!),
                                shape: BoxShape.circle,
                              ),
                            )
                          : const Icon(Icons.event),
                    )).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Time range
            _SectionCard(
              title: 'Uhrzeit',
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: AppColors.primary),
                      title: Text(_startTime != null
                          ? _formatTime(_startTime!)
                          : 'Startzeit'),
                      subtitle: const Text('Von'),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppColors.medium),
                  Expanded(
                    child: ListTile(
                      leading: const Icon(Icons.access_time_filled, color: AppColors.primary),
                      title: Text(_endTime != null
                          ? _formatTime(_endTime!)
                          : 'Endzeit'),
                      subtitle: const Text('Bis'),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Notes
            _SectionCard(
              title: 'Notizen (optional)',
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Besondere Hinweise...',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _notes = value,
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingXL),

            // Quick actions
            Text(
              'Schnellauswahl',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Wrap(
              spacing: AppDimensions.paddingS,
              runSpacing: AppDimensions.paddingS,
              children: [
                _QuickDateChip(
                  label: 'Heute',
                  selected: _isToday(_selectedDate),
                  onTap: () => setState(() => _selectedDate = DateTime.now()),
                ),
                _QuickDateChip(
                  label: 'Morgen',
                  selected: _isTomorrow(_selectedDate),
                  onTap: () => setState(() => 
                    _selectedDate = DateTime.now().add(const Duration(days: 1))),
                ),
                _QuickDateChip(
                  label: 'Nächsten Sonntag',
                  selected: false,
                  onTap: () => setState(() => _selectedDate = _nextWeekday(7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('de', 'DE'),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 19, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 21, minute: 0)),
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _createAttendance() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle einen Veranstaltungstyp')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);

      if (tenant == null) throw Exception('Kein Tenant ausgewählt');

      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // 1. Create the attendance record
      final response = await supabase.from('attendance').insert({
        'tenantId': tenant.id,
        'date': dateString,
        'type_id': _selectedType!.id,
        'type': _selectedType!.name,
        'typeInfo': _selectedType!.name,
        'start_time': _startTime != null ? _formatTime(_startTime!) : null,
        'end_time': _endTime != null ? _formatTime(_endTime!) : null,
        'notes': _notes,
        'created_by': supabase.auth.currentUser?.id,
      }).select().single();

      if (!mounted) return;

      final newId = response['id'] as int;

      // 2. Create PersonAttendance records for all active players
      await _createPersonAttendancesForAll(newId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anwesenheit erstellt')),
      );

      // Navigate to the new attendance
      context.go('/attendance/$newId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Create PersonAttendance records for all active players
  Future<void> _createPersonAttendancesForAll(int attendanceId) async {
    final supabase = ref.read(supabaseClientProvider);
    final tenant = ref.read(currentTenantProvider);

    // Guard against null tenant or null tenant.id
    if (tenant?.id == null) return;

    // Get all active players (not left, not pending)
    final players = await supabase
        .from('player')
        .select('id')
        .eq('tenantId', tenant!.id!)
        .isFilter('left', null);  // null = aktiv

    final playerList = players as List;
    if (playerList.isEmpty) return;

    // Get default status from attendance type
    final defaultStatus = _selectedType?.defaultStatus ?? AttendanceStatus.neutral;

    // Create PersonAttendance records
    final records = playerList.map((p) => {
      'attendance_id': attendanceId,
      'person_id': p['id'],
      'status': defaultStatus.value,  // Use integer value, not string name
    }).toList();

    // Batch insert all records
    await supabase.from('person_attendances').insert(records);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  DateTime _nextWeekday(int weekday) {
    final now = DateTime.now();
    int daysUntil = weekday - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return now.add(Duration(days: daysUntil));
  }

  TimeOfDay? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse('FF${colorStr.substring(1)}', radix: 16));
      }
      return AppColors.primary;
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingM,
              AppDimensions.paddingM,
              AppDimensions.paddingM,
              0,
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.medium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  const _QuickDateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: selected ? AppColors.primary.withValues(alpha: 0.2) : null,
      side: selected ? BorderSide(color: AppColors.primary) : null,
      onPressed: onTap,
    );
  }
}