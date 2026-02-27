import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/providers/player_providers.dart';
import '../../../../core/providers/realtime_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/person/person.dart';
import '../../../../data/models/tenant/tenant.dart';
import '../../../../core/providers/tenant_providers.dart';

/// Provider for single person with group name
final personProvider =
    FutureProvider.family<Person?, int>((ref, personId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  final groups = await ref.watch(groupsMapProvider.future);

  if (tenant == null) return null;

  final response = await supabase
      .from('player')
      .select('*')
      .eq('id', personId)
      .eq('tenantId', tenant.id!)
      .maybeSingle();

  if (response == null) return null;
  final person = Person.fromJson(response);

  // Add group name from the groups map
  final groupName = person.instrument != null ? groups[person.instrument] : null;
  return person.copyWith(groupName: groupName);
});

/// Provider for person attendance statistics
/// FN-010: Added tenantId filter for Multi-Tenant Security
final personAttendanceStatsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, personId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  // Guard against null tenant - Multi-Tenant Security
  if (tenant?.id == null) {
    return {
      'total': 0,
      'attended': 0,
      'percentage': 0,
      'lateCount': 0,
    };
  }

  // BL-001: person_attendances has no tenantId column
  // Filter via inner join on attendance table which has tenantId
  final response = await supabase
      .from('person_attendances')
      .select('status, attendance:attendance_id!inner(id, date, tenantId)')
      .eq('person_id', personId)
      .eq('attendance.tenantId', tenant!.id!);

  final attendances = response as List;
  final now = DateTime.now();

  // Filter to only past attendances
  final pastAttendances = attendances.where((a) {
    final attendance = a['attendance'] as Map<String, dynamic>?;
    final date = DateTime.tryParse(attendance?['date'] ?? '');
    return date != null && date.isBefore(now);
  }).toList();

  final total = pastAttendances.length;
  final attended = pastAttendances.where((a) => a['attended'] == true).length;
  final percentage = total > 0 ? (attended / total * 100).round() : 0;
  
  // Count late arrivals (status 3 = late, 5 = lateExcused)
  final lateCount = pastAttendances.where((a) {
    final status = a['status'];
    if (status is int) {
      return status == 3 || status == 5; // AttendanceStatus.late or lateExcused
    }
    return false;
  }).length;

  return {
    'total': total,
    'attended': attended,
    'percentage': percentage,
    'lateCount': lateCount,
  };
});

/// Provider for person history (attendance + player history combined)
final personHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, personId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final person = await ref.watch(personProvider(personId).future);
  final tenant = ref.watch(currentTenantProvider);

  if (person == null || tenant == null) return [];

  // Get today's date in ISO format for comparison
  final today = DateTime.now().toIso8601String().substring(0, 10);

  // Get attendance history - use attendance_id join like Ionic does
  // BL-003/SEC: person_attendances has no tenantId - use inner join (!inner) to filter
  final attendanceResponse = await supabase
      .from('person_attendances')
      .select('*, attendance:attendance_id!inner(id, date, type, typeInfo, type_id, tenantId)')
      .eq('person_id', personId)
      .eq('attendance.tenantId', tenant.id!);

  // Get attendance types for title lookup
  List<Map<String, dynamic>> attendanceTypes = [];
  final typesResponse = await supabase
      .from('attendance_types')
      .select('*')
      .eq('tenant_id', tenant.id!);
  attendanceTypes = List<Map<String, dynamic>>.from(typesResponse as List);

  final attendanceHistory = (attendanceResponse as List)
      .where((a) => a['attendance'] != null) // Filter out null attendance
      .where((a) {
        // Only past dates
        final attendance = a['attendance'] as Map<String, dynamic>?;
        final dateStr = attendance?['date']?.toString();
        if (dateStr == null) return false;
        return dateStr.compareTo(today) <= 0;
      })
      .map((a) {
    final attendance = a['attendance'] as Map<String, dynamic>?;
    final typeId = attendance?['type_id'];
    // typeInfo is a String in the database, not a Map
    final typeInfo = attendance?['typeInfo']?.toString();

    // Get title from attendance type (like Ionic's Utils.getTypeTitle)
    String meetingName = '';
    final attType = attendanceTypes.firstWhere(
      (t) => t['id'] == typeId,
      orElse: () => <String, dynamic>{},
    );
    if (attType.isNotEmpty) {
      final typeName = attType['name']?.toString() ?? '';
      // typeInfo is the title if provided, otherwise use type name
      meetingName = (typeInfo != null && typeInfo.isNotEmpty) ? typeInfo : typeName;
    } else {
      // Fallback to typeInfo or old type field
      meetingName = typeInfo ?? attendance?['type']?.toString() ?? 'Anwesenheit';
    }

    // Determine status text based on integer status value
    // Status values: 0=neutral, 1=present, 2=excused, 3=late, 4=absent, 5=lateExcused
    final statusValue = a['status'];
    int statusInt = 0;
    if (statusValue is int) {
      statusInt = statusValue;
    } else if (statusValue != null) {
      statusInt = int.tryParse(statusValue.toString()) ?? 0;
    }

    String displayStatus;
    switch (statusInt) {
      case 1: // present
        displayStatus = 'X';
        break;
      case 2: // excused
        displayStatus = 'E';
        break;
      case 3: // late
        displayStatus = 'L';
        break;
      case 4: // absent
        displayStatus = 'A';
        break;
      case 5: // lateExcused
        displayStatus = 'L';
        break;
      case 0: // neutral
      default:
        displayStatus = 'N';
    }

    return {
      'date': attendance?['date']?.toString(),
      'meetingName': meetingName,
      'text': displayStatus,
      'type': PlayerHistoryType.attendance.value,
      'notes': a['notes'],
      'status': statusInt,
    };
  }).toList();

  // Get player history from person model
  final playerHistory = person.history.map((h) {
    return {
      'date': h.date,
      'title': h.typeLabel,
      'text': h.text ?? '',
      'type': h.type,
      'notes': null,
    };
  }).toList();

  // Combine and sort by date descending
  final allHistory = [...attendanceHistory, ...playerHistory];
  allHistory.sort((a, b) {
    final dateA = DateTime.tryParse(a['date']?.toString() ?? '') ?? DateTime(1900);
    final dateB = DateTime.tryParse(b['date']?.toString() ?? '') ?? DateTime(1900);
    return dateB.compareTo(dateA);
  });

  return allHistory.take(100).toList();
});

/// Person detail page
class PersonDetailPage extends ConsumerWidget {
  const PersonDetailPage({super.key, required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(personProvider(personId));

    return personAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Person')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Person')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: AppDimensions.paddingM),
              Text('Fehler: $error'),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton(
                onPressed: () => ref.refresh(personProvider(personId)),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
      data: (person) {
        if (person == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Person')),
            body: const Center(child: Text('Person nicht gefunden')),
          );
        }
        return _PersonDetailContent(person: person, personId: personId);
      },
    );
  }
}

class _PersonDetailContent extends ConsumerStatefulWidget {
  const _PersonDetailContent({required this.person, required this.personId});

  final Person person;
  final int personId;

  @override
  ConsumerState<_PersonDetailContent> createState() =>
      _PersonDetailContentState();
}

class _PersonDetailContentState extends ConsumerState<_PersonDetailContent> {
  bool _isEditing = false;
  bool _hasChanges = false;
  bool _isSaving = false;
  
  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;
  late TextEditingController _otherExerciseController;
  
  // Form values
  late int? _selectedGroupId;
  late DateTime? _birthday;
  late DateTime? _playsSince;
  late DateTime? _joined;
  late bool _isLeader;
  late bool _hasTeacher;
  late Map<String, dynamic> _additionalFieldValues;

  // Section states
  bool _showAllgemein = false;
  bool _showAccount = false;
  bool _showHistorie = true;
  bool _showProblemfall = true;

  // Problem person state
  bool _problemSolved = false;
  String _problemNotes = '';

  @override
  void initState() {
    super.initState();
    _initFormData();
  }
  
  void _initFormData() {
    final p = widget.person;
    _firstNameController = TextEditingController(text: p.firstName);
    _lastNameController = TextEditingController(text: p.lastName);
    _phoneController = TextEditingController(text: p.phone ?? '');
    _emailController = TextEditingController(text: p.email ?? '');
    _notesController = TextEditingController(text: p.notes ?? '');
    _otherExerciseController = TextEditingController(text: p.otherExercise ?? '');
    
    _selectedGroupId = p.instrument;
    _birthday = p.birthday != null ? DateTime.tryParse(p.birthday!) : null;
    _playsSince = p.playsSince != null ? DateTime.tryParse(p.playsSince!) : null;
    _joined = p.joined != null ? DateTime.tryParse(p.joined!) : null;
    _isLeader = p.isLeader;
    _hasTeacher = p.hasTeacher;
    _additionalFieldValues = Map.from(p.additionalFields ?? {});
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _otherExerciseController.dispose();
    super.dispose();
  }
  
  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  Future<void> _saveChanges() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      final supabase = ref.read(supabaseClientProvider);
      final person = widget.person;
      
      // Build history entry if group changed
      final List<Map<String, dynamic>> newHistoryEntries = [];
      if (_selectedGroupId != person.instrument) {
        final groups = await ref.read(groupsMapProvider.future);
        final oldGroupName = groups[person.instrument] ?? 'Unbekannt';
        final newGroupName = groups[_selectedGroupId] ?? 'Unbekannt';
        newHistoryEntries.add({
          'date': DateTime.now().toIso8601String(),
          'text': '$oldGroupName -> $newGroupName',
          'type': PlayerHistoryType.instrumentChange.value,
        });
      }
      
      // Build history entry if notes changed
      if (_notesController.text != (person.notes ?? '')) {
        newHistoryEntries.add({
          'date': DateTime.now().toIso8601String(),
          'text': person.notes ?? 'Keine Notiz',
          'type': PlayerHistoryType.notes.value,
        });
      }
      
      final existingHistory = person.history.map((h) => h.toJson()).toList();
      final updatedHistory = [...existingHistory, ...newHistoryEntries];
      final tenant = ref.read(currentTenantProvider);

      await supabase.from('player').update({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'otherExercise': _otherExerciseController.text.isEmpty ? null : _otherExerciseController.text,
        'instrument': _selectedGroupId,
        'birthday': _birthday?.toIso8601String(),
        'playsSince': _playsSince?.toIso8601String(),
        'joined': _joined?.toIso8601String(),
        'isLeader': _isLeader,
        'hasTeacher': _hasTeacher,
        'correctBirthday': true,
        'history': updatedHistory,
        'additional_fields': _additionalFieldValues.isNotEmpty ? _additionalFieldValues : null,
      }).eq('id', person.id!).eq('tenantId', tenant!.id!);
      
      ref.invalidate(personProvider(widget.personId));
      ref.invalidate(realtimePlayersProvider);
      
      setState(() {
        _hasChanges = false;
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Änderungen gespeichert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showPauseDialog() async {
    final reasonController = TextEditingController();
    DateTime? pauseUntil;

    try {
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: AppDimensions.paddingL,
              right: AppDimensions.paddingL,
              top: AppDimensions.paddingL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pause_circle, color: AppColors.warning, size: 28),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Text(
                        '${widget.person.firstName} pausieren',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingL),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Grund *',
                    hintText: 'Warum wird pausiert?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  autofocus: true,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: const Text('Pausiert bis (optional)'),
                  subtitle: Text(
                    pauseUntil != null
                        ? DateFormat('dd.MM.yyyy').format(pauseUntil!)
                        : 'Kein Enddatum',
                    style: TextStyle(
                      color: pauseUntil != null ? AppColors.primary : AppColors.medium,
                    ),
                  ),
                  trailing: pauseUntil != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.medium),
                          onPressed: () => setDialogState(() => pauseUntil = null),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => pauseUntil = date);
                    }
                  },
                ),
                const SizedBox(height: AppDimensions.paddingL),
                FilledButton.icon(
                  onPressed: () {
                    if (reasonController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bitte Grund angeben')),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'reason': reasonController.text,
                      'until': pauseUntil?.toIso8601String(),
                    });
                  },
                  icon: const Icon(Icons.pause),
                  label: const Text('Pausieren'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
              ],
            ),
          ),
        ),
      );

      if (result != null && mounted) {
        await _pausePerson(result['reason'], result['until']);
      }
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _pausePerson(String reason, String? until) async {
    final repository = ref.read(playerRepositoryWithTenantProvider);
    final person = widget.person;

    // Format reason with date if provided
    final reasonText = until != null
        ? '$reason (bis ${DateFormat('dd.MM.yyyy').format(DateTime.parse(until))})'
        : reason;

    try {
      await repository.pausePlayer(person, until, reasonText);

      ref.invalidate(personProvider(widget.personId));
      ref.invalidate(realtimePlayersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Person wurde pausiert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _unpausePerson() async {
    final repository = ref.read(playerRepositoryWithTenantProvider);
    final person = widget.person;

    try {
      await repository.unpausePlayer(person);

      ref.invalidate(personProvider(widget.personId));
      ref.invalidate(realtimePlayersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person wurde reaktiviert'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _showArchiveDialog() async {
    final noteController = TextEditingController();
    DateTime archiveDate = DateTime.now();

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Person archivieren'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Austrittsdatum'),
                  subtitle: Text(DateFormat('dd.MM.yyyy').format(archiveDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: archiveDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => archiveDate = date);
                    }
                  },
                ),
                const SizedBox(height: AppDimensions.paddingM),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Grund (optional)',
                    hintText: 'Warum verlässt die Person?',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () {
                  Navigator.pop(context, {'date': archiveDate.toIso8601String(), 'note': noteController.text});
                },
                child: const Text('Archivieren'),
              ),
            ],
          ),
        ),
      );

      if (result != null && mounted) {
        await _archivePerson(result['date'], result['note']);
      }
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _archivePerson(String date, String note) async {
    final repository = ref.read(playerRepositoryWithTenantProvider);
    final person = widget.person;

    try {
      await repository.archivePlayer(person, date, note.isNotEmpty ? note : null);

      ref.invalidate(personProvider(widget.personId));
      ref.invalidate(realtimePlayersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Person wurde archiviert'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _resetLateCount() async {
    final notifier = ref.read(playerNotifierProvider.notifier);
    final person = widget.person;

    try {
      await notifier.resetLateCount(person);

      ref.invalidate(personProvider(widget.personId));
      ref.invalidate(personAttendanceStatsProvider(widget.personId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verspätungen zurückgesetzt'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _resolveProblem() async {
    if (!_problemSolved) return;

    final notifier = ref.read(playerNotifierProvider.notifier);
    final person = widget.person;

    try {
      await notifier.resolveCritical(person, _problemNotes.isNotEmpty ? _problemNotes : null);

      ref.invalidate(personProvider(widget.personId));

      if (mounted) {
        setState(() {
          _problemSolved = false;
          _problemNotes = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Problemfall gelöst'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showMoreActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.person.paused)
              ListTile(
                leading: const Icon(Icons.play_arrow, color: AppColors.success),
                title: const Text('Wieder aktivieren'),
                onTap: () { Navigator.pop(context); _unpausePerson(); },
              )
            else
              ListTile(
                leading: const Icon(Icons.pause_circle, color: AppColors.warning),
                title: const Text('Pausieren'),
                onTap: () { Navigator.pop(context); _showPauseDialog(); },
              ),
            ListTile(
              leading: const Icon(Icons.archive, color: AppColors.danger),
              title: const Text('Archivieren'),
              onTap: () { Navigator.pop(context); _showArchiveDialog(); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Abbrechen'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectDate(String field) async {
    DateTime initialDate;
    switch (field) {
      case 'birthday':
        initialDate = _birthday ?? DateTime(2000, 1, 1);
        break;
      case 'playsSince':
        initialDate = _playsSince ?? DateTime.now();
        break;
      case 'joined':
        initialDate = _joined ?? DateTime.now();
        break;
      default:
        return;
    }
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        switch (field) {
          case 'birthday':
            _birthday = date;
            break;
          case 'playsSince':
            _playsSince = date;
            break;
          case 'joined':
            _joined = date;
            break;
        }
      });
      _markChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final statsAsync = ref.watch(personAttendanceStatsProvider(widget.personId));
    final groupsAsync = ref.watch(groupsMapProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // User tried to pop but canPop was false (has unsaved changes)
        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Änderungen verwerfen?'),
            content: const Text('Du hast ungespeicherte Änderungen. Möchtest du diese verwerfen?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verwerfen')),
            ],
          ),
        );
        if (shouldDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Person bearbeiten' : person.fullName),
          backgroundColor: person.isCritical ? AppColors.danger : null,
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Bearbeiten',
                onPressed: () => setState(() => _isEditing = true),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Mehr',
              onPressed: _showMoreActions,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // Header with avatar and stats
            _buildHeader(person, statsAsync),
            
            // Status badges
            if (_hasStatusBadges(person))
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Wrap(
                  spacing: AppDimensions.paddingS,
                  runSpacing: AppDimensions.paddingS,
                  children: _buildStatusBadges(person),
                ),
              ),

            // Edit Form or View Mode
            if (_isEditing)
              _buildEditForm(groupsAsync)
            else ...[
              // Late Warning Card
              _buildLateWarningCard(person, statsAsync),
              _buildNameSection(person),
              // Problem Person Accordion (only for critical persons)
              if (person.isCritical)
                _buildAccordionSection(
                  title: 'Problemfall',
                  isExpanded: _showProblemfall,
                  onToggle: () => setState(() => _showProblemfall = !_showProblemfall),
                  child: _buildProblemfallContent(person),
                ),
              _buildAccordionSection(
                title: 'Allgemein',
                isExpanded: _showAllgemein,
                onToggle: () => setState(() => _showAllgemein = !_showAllgemein),
                child: _buildAllgemeinContent(person),
              ),
              if (person.email != null || person.appId != null)
                _buildAccordionSection(
                  title: 'Account',
                  isExpanded: _showAccount,
                  onToggle: () => setState(() => _showAccount = !_showAccount),
                  child: _buildAccountContent(person),
                ),
              _buildAccordionSection(
                title: 'Historie',
                isExpanded: _showHistorie,
                onToggle: () => setState(() => _showHistorie = !_showHistorie),
                child: _buildHistoryContent(),
              ),
            ],
          ],
        ),
        floatingActionButton: _isEditing
            ? FloatingActionButton.extended(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Speichern...' : 'Speichern'),
                backgroundColor: _hasChanges ? AppColors.primary : AppColors.medium,
              )
            : null,
      ),
    );
  }
  
  Widget _buildEditForm(AsyncValue<Map<int, String>> groupsAsync) {
    final tenant = ref.watch(currentTenantProvider);
    final extraFields = tenant?.additionalFields ?? [];

    return Card(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'Vorname'),
                    onChanged: (_) => _markChanged(),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Nachname'),
                    onChanged: (_) => _markChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notizen'),
              maxLines: 3,
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Group Dropdown
            Text('Gruppe', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: AppDimensions.paddingXS),
            groupsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Fehler: $e'),
              data: (groups) => DropdownButtonFormField<int>(
                value: _selectedGroupId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: groups.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (value) {
                  setState(() => _selectedGroupId = value);
                  _markChanged();
                },
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Phone
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefon-/Handynummer'),
              keyboardType: TextInputType.phone,
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Birthday
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Geburtsdatum'),
              subtitle: Text(_birthday != null ? DateFormat('dd.MM.yyyy').format(_birthday!) : 'Nicht angegeben'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate('birthday'),
            ),

            // Plays Since
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Spielt auf dem Instrument seit'),
              subtitle: Text(_playsSince != null ? DateFormat('dd.MM.yyyy').format(_playsSince!) : 'Nicht angegeben'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate('playsSince'),
            ),

            // Joined
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Beigetreten am'),
              subtitle: Text(_joined != null ? DateFormat('dd.MM.yyyy').format(_joined!) : 'Nicht angegeben'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate('joined'),
            ),

            // Is Leader
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Stimmführer'),
              value: _isLeader,
              onChanged: (value) {
                setState(() => _isLeader = value);
                _markChanged();
              },
            ),

            // Has Teacher
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Spielt beim Lehrer'),
              value: _hasTeacher,
              onChanged: (value) {
                setState(() => _hasTeacher = value);
                _markChanged();
              },
            ),

            // Other Exercise
            TextField(
              controller: _otherExerciseController,
              decoration: const InputDecoration(labelText: 'Sonstige Dienste'),
              onChanged: (_) => _markChanged(),
            ),

            // Extra Fields Section
            if (extraFields.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingL),
              const Divider(),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                'Zusatzfelder',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              ...extraFields.map((field) => _buildExtraFieldInput(field)),
            ],

            const SizedBox(height: AppDimensions.paddingL),

            // Cancel button
            OutlinedButton(
              onPressed: () {
                _initFormData();
                setState(() {
                  _isEditing = false;
                  _hasChanges = false;
                });
              },
              child: const Text('Abbrechen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraFieldInput(ExtraField field) {
    final currentValue = _additionalFieldValues[field.id] ?? field.defaultValue;

    switch (field.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: TextField(
            decoration: InputDecoration(labelText: field.name),
            controller: TextEditingController(text: currentValue?.toString() ?? ''),
            onChanged: (value) {
              _additionalFieldValues[field.id] = value;
              _markChanged();
            },
          ),
        );

      case 'textarea':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: TextField(
            decoration: InputDecoration(labelText: field.name),
            maxLines: 3,
            controller: TextEditingController(text: currentValue?.toString() ?? ''),
            onChanged: (value) {
              _additionalFieldValues[field.id] = value;
              _markChanged();
            },
          ),
        );

      case 'number':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: TextField(
            decoration: InputDecoration(labelText: field.name),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: currentValue?.toString() ?? ''),
            onChanged: (value) {
              _additionalFieldValues[field.id] = int.tryParse(value) ?? 0;
              _markChanged();
            },
          ),
        );

      case 'boolean':
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(field.name),
            value: currentValue == true,
            onChanged: (value) {
              setState(() {
                _additionalFieldValues[field.id] = value;
              });
              _markChanged();
            },
          ),
        );

      case 'date':
        final dateValue = currentValue != null ? DateTime.tryParse(currentValue.toString()) : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(field.name),
            subtitle: Text(dateValue != null ? DateFormat('dd.MM.yyyy').format(dateValue) : 'Nicht angegeben'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: dateValue ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() {
                  _additionalFieldValues[field.id] = date.toIso8601String().split('T')[0];
                });
                _markChanged();
              }
            },
          ),
        );

      case 'select':
        final options = field.options ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: field.name),
            value: options.contains(currentValue) ? currentValue?.toString() : (options.isNotEmpty ? options.first : null),
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            onChanged: (value) {
              setState(() {
                _additionalFieldValues[field.id] = value;
              });
              _markChanged();
            },
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader(Person person, AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            person.isCritical ? AppColors.danger : AppColors.primary,
            (person.isCritical ? AppColors.danger : AppColors.primary).withValues(alpha: 0.7),
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
              backgroundImage: person.img != null && !person.img!.contains('.svg')
                  ? NetworkImage(person.img!)
                  : null,
              child: person.img == null || person.img!.contains('.svg')
                  ? Text(person.initials, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary))
                  : null,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          if (person.groupName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingXS),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS)),
              child: Text(person.groupName!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
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
                  label: stats['lateCount'] > 0 ? 'Anwesenheit (${stats['lateCount']}x zu spät)' : 'Anwesenheit',
                  color: stats['percentage'] >= 75 ? AppColors.success : stats['percentage'] >= 50 ? AppColors.warning : AppColors.danger,
                ),
                Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL), color: Colors.white.withValues(alpha: 0.3)),
                _StatItem(value: '${stats['attended']}/${stats['total']}', label: 'Termine', color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLateWarningCard(Person person, AsyncValue<Map<String, dynamic>> statsAsync) {
    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final lateCount = stats['lateCount'] as int? ?? 0;
        // Get threshold from tenant's critical rules - find first rule for late status (3 = late)
        final tenant = ref.watch(currentTenantProvider);
        // Default threshold of 3
        int threshold = 3;
        // Try to find a late-specific rule
        if (tenant?.criticalRules != null) {
          for (final rule in tenant!.criticalRules!) {
            // Status 3 = late
            if (rule.statuses.contains(3)) {
              threshold = rule.thresholdValue;
              break;
            }
          }
        }

        if (lateCount < threshold) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.all(AppDimensions.paddingM),
          color: Colors.orange.shade50,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.schedule, color: Colors.orange),
            ),
            title: const Text(
              'Häufige Verspätungen',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '$lateCount× unentschuldigt zu spät (Schwelle: $threshold)',
              style: TextStyle(color: Colors.orange.shade800),
            ),
            trailing: FilledButton.tonal(
              onPressed: _resetLateCount,
              child: const Text('Zurücksetzen'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProblemfallContent(Person person) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (person.criticalReason != null && person.criticalReason!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grund',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Text(
                  person.criticalReason!,
                  style: const TextStyle(color: AppColors.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mit Person gesprochen'),
          subtitle: const Text('Bestätigen, dass das Problem besprochen wurde'),
          value: _problemSolved,
          onChanged: (value) => setState(() => _problemSolved = value),
          activeColor: AppColors.success,
        ),
        if (_problemSolved) ...[
          const SizedBox(height: AppDimensions.paddingM),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Anmerkungen (optional)',
              hintText: 'Was wurde besprochen?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => _problemNotes = value,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _resolveProblem,
              icon: const Icon(Icons.check_circle),
              label: const Text('Problem als gelöst markieren'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        ],
      ],
    );
  }

  bool _hasStatusBadges(Person person) => person.archived || person.paused || person.isCritical || person.pending || person.isLeader;

  List<Widget> _buildStatusBadges(Person person) {
    final badges = <Widget>[];
    if (person.archived) badges.add(_StatusBadge(label: 'Archiviert', color: AppColors.medium, icon: Icons.archive));
    if (person.paused) badges.add(_StatusBadge(label: person.pausedUntil != null ? 'Pausiert bis ${_formatDate(person.pausedUntil!)}' : 'Pausiert', color: AppColors.warning, icon: Icons.pause_circle));
    if (person.isCritical) badges.add(_StatusBadge(label: 'Kritisch', color: AppColors.danger, icon: Icons.warning));
    if (person.pending) badges.add(_StatusBadge(label: 'Ausstehend', color: AppColors.info, icon: Icons.hourglass_empty));
    if (person.isLeader) badges.add(_StatusBadge(label: 'Stimmführer', color: AppColors.success, icon: Icons.star));
    return badges;
  }

  Widget _buildNameSection(Person person) {
    return Card(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Vorname', style: TextStyle(fontSize: 12, color: AppColors.medium)),
                  Text(person.firstName, style: const TextStyle(fontSize: 16)),
                ])),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nachname', style: TextStyle(fontSize: 12, color: AppColors.medium)),
                  Text(person.lastName, style: const TextStyle(fontSize: 16)),
                ])),
              ],
            ),
            if (person.notes != null && person.notes!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.paddingM),
              const Text('Notizen', style: TextStyle(fontSize: 12, color: AppColors.medium)),
              const SizedBox(height: AppDimensions.paddingXS),
              Text(person.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccordionSection({required String title, required bool isExpanded, required VoidCallback onToggle, required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM, vertical: AppDimensions.paddingXS),
      child: Column(
        children: [
          ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more), onTap: onToggle),
          if (isExpanded) Padding(padding: const EdgeInsets.fromLTRB(AppDimensions.paddingM, 0, AppDimensions.paddingM, AppDimensions.paddingM), child: child),
        ],
      ),
    );
  }

  Widget _buildAllgemeinContent(Person person) {
    final tenant = ref.watch(currentTenantProvider);
    final extraFields = tenant?.additionalFields ?? [];
    final additionalFieldValues = person.additionalFields ?? {};

    return Column(
      children: [
        _InfoRow(icon: Icons.group, label: 'Gruppe', value: person.groupName ?? 'Nicht zugewiesen'),
        if (person.phone != null && person.phone!.isNotEmpty)
          _InfoRow(icon: Icons.phone, label: 'Telefon', value: person.phone!, onTap: () => _launchUrl('tel:${person.phone}')),
        if (person.birthday != null && person.birthday!.isNotEmpty)
          _InfoRow(icon: Icons.cake, label: 'Geburtsdatum', value: _formatDate(person.birthday!), highlight: !person.correctBirthday, highlightColor: AppColors.warning),
        if (person.playsSince != null && person.playsSince!.isNotEmpty)
          _InfoRow(icon: Icons.music_note, label: 'Spielt auf dem Instrument seit', value: _formatDate(person.playsSince!)),
        if (person.joined != null && person.joined!.isNotEmpty)
          _InfoRow(icon: Icons.login, label: 'Beigetreten am', value: _formatDate(person.joined!)),
        if (person.hasTeacher)
          _InfoRow(icon: Icons.school, label: 'Spielt beim Lehrer', value: person.teacherName ?? 'Ja'),
        _InfoRow(icon: Icons.star, label: 'Stimmführer', value: person.isLeader ? 'Ja' : 'Nein'),
        if (person.otherExercise != null && person.otherExercise!.isNotEmpty)
          _InfoRow(icon: Icons.work, label: 'Sonstige Dienste', value: person.otherExercise!),

        // Extra Fields Section
        if (extraFields.isNotEmpty) ...[
          const Divider(height: 32),
          Text(
            'Zusatzfelder',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          ...extraFields.map((field) {
            final value = additionalFieldValues[field.id];
            String displayValue = _formatExtraFieldValue(field, value);
            return _InfoRow(
              icon: _getExtraFieldIcon(field.type),
              label: field.name,
              value: displayValue,
            );
          }),
        ],
      ],
    );
  }

  IconData _getExtraFieldIcon(String type) {
    switch (type) {
      case 'text':
        return Icons.text_fields;
      case 'textarea':
        return Icons.notes;
      case 'number':
        return Icons.numbers;
      case 'date':
        return Icons.calendar_today;
      case 'boolean':
        return Icons.toggle_on;
      case 'select':
        return Icons.list;
      default:
        return Icons.text_fields;
    }
  }

  String _formatExtraFieldValue(ExtraField field, dynamic value) {
    if (value == null) {
      return 'Nicht angegeben';
    }

    switch (field.type) {
      case 'boolean':
        return value == true ? 'Ja' : 'Nein';
      case 'date':
        final date = DateTime.tryParse(value.toString());
        if (date != null) {
          return DateFormat('dd.MM.yyyy').format(date);
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  Widget _buildAccountContent(Person person) {
    final tenant = ref.watch(currentTenantProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.email,
          label: 'E-Mail',
          value: person.email ?? 'Nicht angegeben',
          onTap: person.email != null ? () => _launchUrl('mailto:${person.email}') : null,
        ),
        if (person.appId != null) ...[
          _InfoRow(icon: Icons.badge, label: 'Account', value: 'Verknüpft'),
          const SizedBox(height: AppDimensions.paddingM),
          // Role selector
          _buildRoleSelector(person, tenant),
          const SizedBox(height: AppDimensions.paddingM),
          // Unlink account button
          OutlinedButton.icon(
            onPressed: () => _showUnlinkAccountDialog(person),
            icon: const Icon(Icons.link_off, color: AppColors.danger),
            label: const Text('Account-Verknüpfung aufheben'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          ),
        ],
        if (person.appId == null && person.email != null) ...[
          const SizedBox(height: AppDimensions.paddingM),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showCreateAccountDialog(person, tenant),
              icon: const Icon(Icons.person_add),
              label: const Text('Account erstellen'),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXS),
          const Text(
            'Die Person erhält eine E-Mail mit dem Link zur Passwort-Einrichtung.',
            style: TextStyle(fontSize: 12, color: AppColors.medium),
          ),
        ],
        if (person.appId == null && person.email == null)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                SizedBox(width: AppDimensions.paddingS),
                Expanded(
                  child: Text(
                    'Um einen Account zu erstellen, muss eine E-Mail-Adresse hinterlegt werden.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRoleSelector(Person person, Tenant? tenant) {
    if (person.appId == null || tenant?.id == null) {
      return const SizedBox.shrink();
    }

    // Available roles for selection
    final availableRoles = [
      Role.player,
      Role.helper,
      Role.viewer,
      Role.responsible,
      Role.admin,
    ];

    return FutureBuilder<Role?>(
      future: _getUserRole(person.appId!, tenant!.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentRole = snapshot.data ?? Role.player;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rolle',
              style: TextStyle(fontSize: 12, color: AppColors.medium),
            ),
            const SizedBox(height: AppDimensions.paddingXS),
            DropdownButtonFormField<Role>(
              value: currentRole,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
              ),
              items: availableRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      Icon(_getRoleIcon(role), size: 20, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.paddingS),
                      Text(_getRoleLabel(role)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newRole) async {
                if (newRole != null && newRole != currentRole) {
                  await _updateUserRole(person.appId!, tenant.id!, newRole);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<Role?> _getUserRole(String userId, int tenantId) async {
    final supabase = ref.read(supabaseClientProvider);
    try {
      final response = await supabase
          .from('tenant_users')
          .select('role')
          .eq('user_id', userId)
          .eq('tenant_id', tenantId)
          .maybeSingle();

      if (response == null) return null;
      return Role.fromValue(response['role'] as int);
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateUserRole(String userId, int tenantId, Role newRole) async {
    // Authorization check - only conductors can change roles
    final currentUserRole = ref.read(currentRoleProvider);
    if (!currentUserRole.isConductor) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Berechtigung zum Ändern von Rollen'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    final supabase = ref.read(supabaseClientProvider);

    try {
      await supabase
          .from('tenant_users')
          .update({'role': newRole.value})
          .eq('user_id', userId)
          .eq('tenant_id', tenantId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rolle auf "${_getRoleLabel(newRole)}" geändert'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  String _getRoleLabel(Role role) {
    return switch (role) {
      Role.admin => 'Dirigent (Admin)',
      Role.responsible => 'Verantwortlicher',
      Role.helper => 'Helfer',
      Role.viewer => 'Beobachter',
      Role.player => 'Mitglied',
      Role.voiceLeader => 'Stimmführer',
      Role.voiceLeaderHelper => 'Stimmführer-Helfer',
      Role.parent => 'Eltern',
      Role.applicant => 'Bewerber',
      Role.none => 'Keine Rolle',
    };
  }

  IconData _getRoleIcon(Role role) {
    return switch (role) {
      Role.admin => Icons.admin_panel_settings,
      Role.responsible => Icons.manage_accounts,
      Role.helper => Icons.handshake,
      Role.viewer => Icons.visibility,
      Role.player => Icons.person,
      Role.voiceLeader => Icons.record_voice_over,
      Role.voiceLeaderHelper => Icons.support_agent,
      Role.parent => Icons.family_restroom,
      Role.applicant => Icons.pending,
      Role.none => Icons.person_off,
    };
  }

  Future<void> _showCreateAccountDialog(Person person, Tenant? tenant) async {
    if (tenant?.id == null) return;

    Role selectedRole = Role.player;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Account erstellen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account für ${person.fullName} erstellen?'),
              const SizedBox(height: AppDimensions.paddingM),
              Text('E-Mail: ${person.email}'),
              const SizedBox(height: AppDimensions.paddingL),
              const Text('Rolle:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppDimensions.paddingS),
              DropdownButtonFormField<Role>(
                value: selectedRole,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                ),
                items: [
                  Role.player,
                  Role.helper,
                  Role.viewer,
                  Role.responsible,
                ].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(_getRoleLabel(role)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedRole = value);
                  }
                },
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.info),
                    SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Text(
                        'Die Person erhält eine E-Mail zum Setzen des Passworts.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Account erstellen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _createAccount(person, tenant!.id!, selectedRole);
    }
  }

  Future<void> _createAccount(Person person, int tenantId, Role role) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: AppDimensions.paddingL),
            Text('Account wird erstellt...'),
          ],
        ),
      ),
    );

    try {
      // Note: In production, this should be done via a server-side function
      // to properly handle auth.admin.createUser
      // For now, we show a message that this feature requires server setup

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account-Erstellung erfordert Server-Setup. Bitte an Administrator wenden.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Ideal implementation would be:
      // 1. Call a Supabase Edge Function that creates the user
      // 2. The function uses service_role to call auth.admin.createUser
      // 3. Update player.appId with the new user ID
      // 4. Create tenant_users entry
      // 5. Send password reset email

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _showUnlinkAccountDialog(Person person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account-Verknüpfung aufheben?'),
        content: Text(
          'Die Account-Verknüpfung für ${person.fullName} wird aufgehoben. '
          'Die Person kann sich dann nicht mehr in der App anmelden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verknüpfung aufheben'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _unlinkAccount(person);
    }
  }

  Future<void> _unlinkAccount(Person person) async {
    // Authorization check - only conductors can unlink accounts
    final currentUserRole = ref.read(currentRoleProvider);
    if (!currentUserRole.isConductor) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Berechtigung zum Aufheben von Account-Verknüpfungen'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    final notifier = ref.read(playerNotifierProvider.notifier);
    final tenant = ref.read(currentTenantProvider);  // Use ref.read in async methods

    try {
      // Remove appId from player
      await notifier.unlinkAccount(person);

      // Also remove from tenant_users if possible
      if (person.appId != null && tenant?.id != null) {
        final supabase = ref.read(supabaseClientProvider);
        await supabase
            .from('tenant_users')
            .delete()
            .eq('user_id', person.appId!)
            .eq('tenant_id', tenant!.id!);
      }

      ref.invalidate(personProvider(widget.personId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account-Verknüpfung aufgehoben'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _buildHistoryContent() {
    final historyAsync = ref.watch(personHistoryProvider(widget.personId));
    final statsAsync = ref.watch(personAttendanceStatsProvider(widget.personId));
    
    return historyAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(AppDimensions.paddingL), child: CircularProgressIndicator())),
      error: (error, _) => Center(child: Text('Fehler: $error')),
      data: (history) {
        if (history.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.paddingL),
            child: Center(child: Column(children: [
              Icon(Icons.history, size: 48, color: AppColors.medium),
              SizedBox(height: AppDimensions.paddingS),
              Text('Keine Historie vorhanden'),
            ])),
          );
        }
        
        return Column(
          children: [
            // Durchschnitt Row (like Ionic)
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                final percentage = stats['percentage'] as int;
                final lateCount = stats['lateCount'] as int;
                final lateText = lateCount > 0 ? ' (${lateCount}x zu spät)' : '';
                Color badgeColor = percentage >= 75 ? AppColors.success : percentage >= 50 ? AppColors.warning : AppColors.danger;
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
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // History items
            ...history.take(20).map((item) {
              final date = DateTime.tryParse(item['date'] ?? '');
              final type = item['type'] as int?;
              final text = item['text']?.toString() ?? '';
              final meetingName = item['meetingName']?.toString();
              final notes = item['notes']?.toString();
              
              // For attendance items, use meeting name if available
              String displayTitle = '';
              if (type == 4) {
                // Attendance entry - show meeting name if present
                displayTitle = meetingName ?? '';
              } else {
                // Other history types
                switch (type) {
                  case 0:
                    displayTitle = 'Pausiert';
                    break;
                  case 5:
                    displayTitle = 'Wieder aktiv';
                    break;
                  case 6:
                    displayTitle = 'Gruppenwechsel';
                    break;
                  case 7:
                    displayTitle = 'Archiviert';
                    break;
                  default:
                    displayTitle = item['title']?.toString() ?? 'Eintrag';
                }
              }
              
              // Build badge for attendance status
              String? badgeText;
              Color? badgeColor;
              if (type == 4) {
                // Attendance badge - X=present, L=late, E=excused, A=absent
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
              
              // Format: "DD.MM.YYYY" or "DD.MM.YYYY | Meeting Name"
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
                              child: Text(notes, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ),
                          if (type != 4 && text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return dateString;
    return DateFormat('dd.MM.yyyy').format(date);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color, required this.icon});
  final String label;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingS, vertical: AppDimensions.paddingXS),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.onTap, this.highlight = false, this.highlightColor});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool highlight;
  final Color? highlightColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: highlight ? BoxDecoration(color: (highlightColor ?? AppColors.warning).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS)) : null,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.medium)),
        subtitle: Text(value, style: const TextStyle(fontSize: 14)),
        trailing: onTap != null ? const Icon(Icons.chevron_right, size: 20) : null,
        onTap: onTap,
      ),
    );
  }
}