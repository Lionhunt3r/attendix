import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/providers/attendance_providers.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/attendance/attendance.dart';
import '../../../../data/models/person/person.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../widgets/songs_selection_sheet.dart';

/// Provider for attendance detail
/// FN-004: Added tenantId filter for multi-tenant security
final attendanceDetailProvider = FutureProvider.autoDispose.family<Attendance?, int>((ref, attendanceId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant?.id == null) return null;

  final response = await supabase
      .from('attendance')
      .select('*')
      .eq('id', attendanceId)
      .eq('tenantId', tenant!.id!)
      .maybeSingle();

  if (response == null) return null;
  // response is already Map<String, dynamic> from maybeSingle()
  return Attendance.fromJson(response);
});

/// Provider for attendance type of a specific attendance
/// FN-005: Added tenant_id filter for multi-tenant security
final attendanceTypeForAttendanceProvider = FutureProvider.autoDispose.family<AttendanceType?, int>((ref, attendanceId) async {
  final attendance = await ref.watch(attendanceDetailProvider(attendanceId).future);
  if (attendance?.typeId == null) return null;

  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant?.id == null) return null;

  final response = await supabase
      .from('attendance_types')
      .select('*')
      .eq('id', attendance!.typeId!)
      .eq('tenant_id', tenant!.id!)
      .maybeSingle();

  if (response == null) return null;
  return AttendanceType.fromJson(response);
});

/// Provider for person attendances for a specific attendance
/// NOTE: This is different from personAttendancesProvider in attendance_providers.dart
/// which gets attendances for a specific PERSON. This one gets persons for a specific ATTENDANCE.
/// SEC-017: Added tenant filter via inner join with attendance table
final personAttendancesForAttendanceProvider = FutureProvider.autoDispose.family<List<PersonAttendance>, int>((ref, attendanceId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  // Get all persons with their attendance status for this attendance
  // SEC-017: Use inner join with attendance to filter by tenant
  final response = await supabase
      .from('person_attendances')
      .select('*, player:person_id(firstName, lastName, img, instrument, left, paused), attendance:attendance_id!inner(tenantId)')
      .eq('attendance_id', attendanceId)
      .eq('attendance.tenantId', tenant.id!);

  return (response as List).map((e) {
    // Extract player data from nested structure - handle potential type mismatch
    final playerData = e['player'];
    final playerMap = playerData is Map<String, dynamic> ? playerData : null;
    return PersonAttendance.fromJson({
      ...e,
      'firstName': playerMap?['firstName'],
      'lastName': playerMap?['lastName'],
      'img': playerMap?['img'],
      'instrument': playerMap?['instrument'],
      'left': playerMap?['left'],
      'paused': playerMap?['paused'],
    });
  }).toList();
});

/// Provider that returns filtered person attendances based on attendance date
/// - Past attendances: Show all persons (including archived/paused for historical correctness)
/// - Future attendances: Only show active persons
final filteredPersonAttendancesForAttendanceProvider = FutureProvider.autoDispose.family<List<PersonAttendance>, int>((ref, attendanceId) async {
  final personAttendances = await ref.watch(personAttendancesForAttendanceProvider(attendanceId).future);
  final attendance = await ref.watch(attendanceDetailProvider(attendanceId).future);

  if (attendance == null) return personAttendances;

  final attendanceDate = DateTime.tryParse(attendance.date);
  final isPast = attendanceDate != null &&
      attendanceDate.isBefore(DateTime.now().subtract(const Duration(hours: 12)));

  if (isPast) {
    // Past attendances: Show all persons
    return personAttendances;
  } else {
    // Future attendances: Only show active persons
    return personAttendances.where((pa) => pa.isActive).toList();
  }
});

/// Provider for all persons in tenant (for attendance taking)
final allPersonsForAttendanceProvider = FutureProvider.autoDispose<List<Person>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('player')
      .select('*, instrument:instrument(id, name)')
      .eq('tenantId', tenant.id!)
      .order('lastName', ascending: true);

  return (response as List).map((e) {
    final instrumentData = e['instrument'] as Map<String, dynamic>?;
    return Person.fromJson(e as Map<String, dynamic>).copyWith(
      groupName: instrumentData?['name'] as String?,
    );
  }).toList();
});

/// Provider for filtered persons based on attendance date
/// - Past attendances: Show all persons
/// - Future attendances: Only show active persons (not left, not paused)
final filteredPersonsForAttendanceProvider = FutureProvider.autoDispose.family<List<Person>, int>((ref, attendanceId) async {
  final allPersons = await ref.watch(allPersonsForAttendanceProvider.future);
  final attendance = await ref.watch(attendanceDetailProvider(attendanceId).future);

  if (attendance == null) return allPersons;

  final attendanceDate = DateTime.tryParse(attendance.date);
  final isPast = attendanceDate != null &&
      attendanceDate.isBefore(DateTime.now().subtract(const Duration(hours: 12)));

  if (isPast) {
    // Past attendances: Show all persons
    return allPersons;
  } else {
    // Future attendances: Only show active persons
    return allPersons.where((p) => p.isActive).toList();
  }
});

/// Attendance detail/taking page
class AttendanceDetailPage extends ConsumerStatefulWidget {
  const AttendanceDetailPage({super.key, required this.attendanceId});

  final int attendanceId;

  @override
  ConsumerState<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends ConsumerState<AttendanceDetailPage> {
  final Map<int, AttendanceStatus> _localStatuses = {};
  final Map<int, String?> _personAttendanceIds = {}; // Map personId -> personAttendanceId
  final Map<int, String?> _personNotes = {}; // Map personId -> notes
  final Map<int, String?> _changedBy = {}; // Map personId -> changedBy userId
  final Map<int, String?> _changedAt = {}; // Map personId -> changedAt timestamp
  bool _hasChanges = false;
  final Set<int> _selectedPersonIds = {};
  bool _isSelectionMode = false;
  bool _isDisposed = false; // Track disposal state for realtime callbacks

  // Realtime channel - typed for proper cleanup
  RealtimeChannel? _personAttChannel;

  // Provider subscription - managed separately from realtime
  ProviderSubscription? _providerSubscription;

  // View mode state (click vs select)
  AttendanceViewMode _viewMode = AttendanceViewMode.click;

  // Local checklist state - maintained separately to allow editing
  List<ChecklistItem> _localChecklist = [];
  bool _checklistLoaded = false;

  // Local songs/history entries
  List<SongHistoryEntry> _songEntries = [];

  @override
  void initState() {
    super.initState();
    // Load saved view mode preference
    _loadViewMode();
    // Subscribe to realtime changes and ensure PersonAttendances exist after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToRealtimeChanges();
      _ensurePersonAttendancesExist();
      _setupProviderListener();
      _loadChecklistFromAttendance();
      _loadSongEntries();
    });
  }

  /// Load view mode preference from SharedPreferences
  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('attendanceViewMode');
      if (modeStr != null && mounted) {
        setState(() {
          _viewMode = AttendanceViewMode.fromValue(modeStr);
        });
      }
    } catch (_) {
      // Ignore errors, use default
    }
  }

  /// Save view mode preference to SharedPreferences
  Future<void> _saveViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('attendanceViewMode', _viewMode.value);
    } catch (_) {
      // Ignore errors
    }
  }

  /// Load checklist from attendance data
  void _loadChecklistFromAttendance() {
    final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
    if (attendance != null && !_checklistLoaded) {
      setState(() {
        _localChecklist = List.from(attendance.checklist ?? []);
        _checklistLoaded = true;
      });
    }
  }

  /// Load song entries from attendance data
  void _loadSongEntries() {
    final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
    if (attendance == null) return;

    // Convert from attendance.songs and attendance.conductors to SongHistoryEntry list
    // This is a simplified version - in practice we'd need to load song names
    final songIds = attendance.songs ?? [];
    final conductorIds = attendance.conductors ?? [];

    // For now, create placeholder entries - they'll be populated when songs load
    final entries = <SongHistoryEntry>[];
    for (var i = 0; i < songIds.length; i++) {
      entries.add(SongHistoryEntry(
        songId: songIds[i],
        songName: 'Laden...', // Will be updated when songs provider loads
        conductorId: i < conductorIds.length ? conductorIds[i] : null,
      ));
    }
    setState(() {
      _songEntries = entries;
    });
  }

  @override
  void dispose() {
    _isDisposed = true; // Mark as disposed BEFORE unsubscribing
    _providerSubscription?.close();
    _unsubscribeFromRealtimeChanges();
    super.dispose();
  }

  /// Setup provider listener to sync data from server to local state.
  /// This is called once in initState() instead of in build() to avoid
  /// registering multiple listeners on each rebuild.
  void _setupProviderListener() {
    _providerSubscription = ref.listenManual(
      filteredPersonAttendancesForAttendanceProvider(widget.attendanceId),
      (previous, next) {
        // Guard against setState after dispose
        if (!mounted || _isDisposed) return;

        // RT-009: Use local variable for thread safety
        final value = next.value;
        if (value != null) {
          // Only update if we don't have local changes, or this is the first load
          final isFirstLoad = _localStatuses.isEmpty;
          if (isFirstLoad || !_hasChanges) {
            setState(() {
              for (final pa in value) {
                if (pa.personId != null) {
                  _localStatuses[pa.personId!] = pa.status;
                  _personAttendanceIds[pa.personId!] = pa.id;
                  _personNotes[pa.personId!] = pa.notes;
                  _changedBy[pa.personId!] = pa.changedBy;
                  _changedAt[pa.personId!] = pa.changedAt;
                }
              }
            });
          }
        }
      },
      fireImmediately: true,
    );
  }

  void _subscribeToRealtimeChanges() {
    final supabase = ref.read(supabaseClientProvider);

    // Subscribe to PersonAttendance changes for this attendance
    _personAttChannel = supabase
        .channel('person-att-${widget.attendanceId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'person_attendances',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'attendance_id',
            value: widget.attendanceId,
          ),
          callback: _onPersonAttendanceChange,
        )
        .subscribe();
  }

  void _unsubscribeFromRealtimeChanges() {
    final channel = _personAttChannel;
    if (channel != null) {
      final supabase = ref.read(supabaseClientProvider);
      supabase.removeChannel(channel);
      _personAttChannel = null;
    }
  }

  /// Ensures PersonAttendance records exist for this attendance.
  /// For legacy attendances created before this feature was implemented,
  /// this creates the missing records with default status.
  Future<void> _ensurePersonAttendancesExist() async {
    // IMPORTANT: Wait for the provider to FINISH loading before checking
    // Using .future instead of .valueOrNull to avoid race condition
    final personAttendances = await ref.read(personAttendancesForAttendanceProvider(widget.attendanceId).future);

    // If records already exist, nothing to do
    if (personAttendances.isNotEmpty) return;

    final supabase = ref.read(supabaseClientProvider);
    final tenant = ref.read(currentTenantProvider);

    if (tenant == null) return;

    // Get default status from AttendanceType or use neutral
    final attendanceType = ref.read(attendanceTypeForAttendanceProvider(widget.attendanceId)).valueOrNull;
    final defaultStatus = attendanceType?.defaultStatus ?? AttendanceStatus.neutral;

    // Load all active players (not left and not paused)
    final players = await supabase
        .from('player')
        .select('id')
        .eq('tenantId', tenant.id!)
        .isFilter('left', null)
        .eq('paused', false);

    final playerList = players as List;
    if (playerList.isEmpty) return;

    // Create PersonAttendance records
    final records = playerList.map((p) => {
      'attendance_id': widget.attendanceId,
      'person_id': p['id'],
      'status': defaultStatus.value,  // Use integer value, not string name
    }).toList();

    await supabase.from('person_attendances').insert(records);

    // Invalidate provider to reload new records
    ref.invalidate(personAttendancesForAttendanceProvider(widget.attendanceId));
  }

  void _onPersonAttendanceChange(dynamic payload) {
    // Guard against setState after dispose - check _isDisposed first (more reliable than mounted)
    if (_isDisposed) return;

    // Check if this is an update we made ourselves (to avoid double updates)
    if (_hasChanges) return;

    final newRecord = payload.newRecord as Map<String, dynamic>?;
    if (newRecord == null || newRecord.isEmpty) return;

    final personId = newRecord['person_id'] as int?;
    final statusValue = newRecord['status'];
    final notes = newRecord['notes'] as String?;
    final changedBy = newRecord['changed_by'] as String?;
    final changedAt = newRecord['changed_at'] as String?;

    if (personId != null && statusValue != null) {
      AttendanceStatus status;
      if (statusValue is int) {
        status = AttendanceStatus.fromValue(statusValue);
      } else {
        final statusStr = statusValue.toString();
        final intValue = int.tryParse(statusStr);
        if (intValue != null) {
          status = AttendanceStatus.fromValue(intValue);
        } else {
          status = AttendanceStatus.values.firstWhere(
            (s) => s.name.toLowerCase() == statusStr.toLowerCase(),
            orElse: () => AttendanceStatus.neutral,
          );
        }
      }

      // Double-check mounted and disposed state before setState
      if (_isDisposed || !mounted) return;

      try {
        setState(() {
          _localStatuses[personId] = status;
          _personNotes[personId] = notes;
          _changedBy[personId] = changedBy;
          _changedAt[personId] = changedAt;
        });
      } catch (e) {
        // Ignore setState errors if widget was disposed during callback
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(attendanceDetailProvider(widget.attendanceId));
    final personsAsync = ref.watch(filteredPersonsForAttendanceProvider(widget.attendanceId));
    // Watch the provider to trigger rebuilds when data changes
    ref.watch(filteredPersonAttendancesForAttendanceProvider(widget.attendanceId));
    final attendanceTypeAsync = ref.watch(attendanceTypeForAttendanceProvider(widget.attendanceId));

    // Get available statuses from attendance type, or use all statuses as default
    // Handle empty list case: if list is empty, fallback to all statuses
    final typeStatuses = attendanceTypeAsync.valueOrNull?.availableStatuses;
    final availableStatuses = (typeStatuses?.isNotEmpty == true) ? typeStatuses! : AttendanceStatus.values;

    return attendanceAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Anwesenheit')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Anwesenheit')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: AppDimensions.paddingM),
              Text('Fehler: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(attendanceDetailProvider(widget.attendanceId)),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
      data: (attendance) {
        if (attendance == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Anwesenheit')),
            body: const Center(child: Text('Anwesenheit nicht gefunden')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attendance.displayTitle),
                Text(
                  attendance.formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.medium,
                  ),
                ),
              ],
            ),
            actions: [
              if (_isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                  tooltip: 'Auswahl beenden',
                ),
                PopupMenuButton<AttendanceStatus>(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Status für Auswahl setzen',
                  onSelected: _batchUpdateSelected,
                  itemBuilder: (context) => availableStatuses.map((s) =>
                    PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(_getStatusIcon(s), color: _getStatusColor(s)),
                          const SizedBox(width: 8),
                          Text(_getStatusLabel(s)),
                        ],
                      ),
                    ),
                  ).toList(),
                ),
              ] else ...[
                if (_hasChanges)
                  TextButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save),
                    label: const Text('Speichern'),
                  ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'all_present',
                      child: ListTile(
                        leading: Icon(Icons.check_circle, color: AppColors.success),
                        title: Text('Alle anwesend'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'all_absent',
                      child: ListTile(
                        leading: Icon(Icons.cancel, color: AppColors.danger),
                        title: Text('Alle abwesend'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'switchMode',
                      child: ListTile(
                        leading: Icon(
                          _viewMode == AttendanceViewMode.click
                              ? Icons.touch_app
                              : Icons.checklist,
                        ),
                        title: Text(
                          _viewMode == AttendanceViewMode.click
                              ? 'Auswahl-Modus'
                              : 'Klick-Modus',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'stats',
                      child: ListTile(
                        leading: Icon(Icons.bar_chart),
                        title: Text('Statistik'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'notes',
                      child: ListTile(
                        leading: Icon(Icons.note_add),
                        title: Text('Notizen'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'photo',
                      child: ListTile(
                        leading: Icon(Icons.camera_alt),
                        title: Text('Foto'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'export_excel',
                      child: ListTile(
                        leading: Icon(Icons.table_chart),
                        title: Text('Excel exportieren'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: personsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Fehler: $error')),
            data: (persons) {
              // Load checklist if not yet loaded
              if (!_checklistLoaded && attendance.checklist != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_checklistLoaded) {
                    setState(() {
                      _localChecklist = List.from(attendance.checklist!);
                      _checklistLoaded = true;
                    });
                  }
                });
              }

              final attendanceType = attendanceTypeAsync.valueOrNull;
              final hasChecklist = _localChecklist.isNotEmpty || (attendanceType?.checklist?.isNotEmpty ?? false);
              final hasSongs = attendanceType?.manageSongs ?? false;
              final hasPlan = attendance.plan != null && attendance.plan!.isNotEmpty;

              return CustomScrollView(
                slivers: [
                  // Accordions section
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: AppDimensions.paddingS),

                        // General Info Accordion (always shown)
                        _GeneralInfoAccordion(
                          attendance: attendance,
                          attendanceType: attendanceType,
                          onTypeInfoChanged: _updateTypeInfo,
                          onNotesChanged: (value) async {
                            try {
                              final supabase = ref.read(supabaseClientProvider);
                              final tenant = ref.read(currentTenantProvider);
                              if (tenant?.id == null) return;
                              await supabase
                                  .from('attendance')
                                  .update({'notes': value.isEmpty ? null : value})
                                  .eq('id', widget.attendanceId)
                                  .eq('tenantId', tenant!.id!);
                              ref.invalidate(attendanceDetailProvider(widget.attendanceId));
                            } catch (e) {
                              if (mounted) {
                                ToastHelper.showError(context, 'Fehler: $e');
                              }
                            }
                          },
                          onStartTimeSelect: _selectStartTime,
                          onEndTimeSelect: _selectEndTime,
                          onDeadlineToggle: _toggleDeadline,
                          onDeadlineSelect: _selectDeadline,
                          onExportExcel: _exportAttendanceToExcel,
                        ),

                        // Checklist Accordion (if type has checklist or items exist)
                        if (hasChecklist)
                          _ChecklistAccordion(
                            checklist: _localChecklist,
                            onToggle: _toggleChecklistItem,
                            onAdd: _addChecklistItem,
                            onRemove: _removeChecklistItem,
                            onRestore: _restoreChecklist,
                            getDeadlineStatus: _getDeadlineStatus,
                            formatDeadlineRelative: _formatDeadlineRelative,
                          ),

                        // Songs/Works Accordion (if type manages songs)
                        if (hasSongs)
                          _SongsHistoryAccordion(
                            entries: _songEntries,
                            onAdd: _openSongsSelection,
                            onRemove: _removeSongEntry,
                          ),

                        // Plan Accordion (if plan exists)
                        if (hasPlan)
                          _PlanAccordion(
                            attendance: attendance,
                            onEdit: () {
                              context.push('/planning/${widget.attendanceId}');
                            },
                            onExportPdf: () async {
                              ToastHelper.showInfo(context, 'PDF-Export wird vorbereitet...');
                              // TODO: Implement PDF export using ExportService
                            },
                          ),

                        const SizedBox(height: AppDimensions.paddingS),
                      ],
                    ),
                  ),

                  // Persons list
                  SliverToBoxAdapter(
                    child: _AttendanceGrid(
                      persons: persons,
                      localStatuses: _localStatuses,
                      personNotes: _personNotes,
                      changedBy: _changedBy,
                      changedAt: _changedAt,
                      selectedPersonIds: _selectedPersonIds,
                      isSelectionMode: _isSelectionMode,
                      availableStatuses: availableStatuses,
                      onStatusChanged: (personId, status) {
                        setState(() {
                          _localStatuses[personId] = status;
                          _hasChanges = true;
                        });
                      },
                      onLongPress: _enterSelectionMode,
                      onSelectionToggle: _toggleSelection,
                      onNoteChanged: _updatePersonNote,
                      onShowModifierInfo: _showModifierInfo,
                      onRemoveFromAttendance: _removePersonFromAttendance,
                    ),
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: _AttendanceStatusBar(
            persons: personsAsync.valueOrNull ?? [],
            localStatuses: _localStatuses,
            selectedCount: _selectedPersonIds.length,
            isSelectionMode: _isSelectionMode,
          ),
        );
      },
    );
  }

  void _enterSelectionMode(int personId) {
    setState(() {
      _isSelectionMode = true;
      _selectedPersonIds.add(personId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedPersonIds.clear();
    });
  }

  void _toggleSelection(int personId) {
    setState(() {
      if (_selectedPersonIds.contains(personId)) {
        _selectedPersonIds.remove(personId);
        if (_selectedPersonIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedPersonIds.add(personId);
      }
    });
  }

  /// Validate that a personAttendance belongs to current tenant
  /// SEC-021: Validate tenant ownership before person_attendances operations
  Future<bool> _validatePersonAttendanceTenant(String personAttendanceId) async {
    final supabase = ref.read(supabaseClientProvider);
    final tenant = ref.read(currentTenantProvider);
    if (tenant?.id == null) return false;

    try {
      final validation = await supabase
          .from('person_attendances')
          .select('id, attendance:attendance_id(tenantId)')
          .eq('id', personAttendanceId)
          .maybeSingle();

      if (validation == null) return false;
      final attendanceTenantId = validation['attendance']?['tenantId'];
      return attendanceTenantId == tenant!.id;
    } catch (_) {
      return false;
    }
  }

  /// Update notes for a specific person
  /// SEC-022: Added tenant validation before update
  Future<void> _updatePersonNote(int personId, String? notes) async {
    final personAttendanceId = _personAttendanceIds[personId];
    if (personAttendanceId == null) {
      ToastHelper.showError(context, 'Kein Anwesenheitseintrag gefunden');
      return;
    }

    // SEC-022: Validate tenant ownership
    final isValid = await _validatePersonAttendanceTenant(personAttendanceId);
    if (!isValid) {
      if (mounted) {
        ToastHelper.showError(context, 'Keine Berechtigung');
      }
      return;
    }

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('person_attendances')
          .update({
            'notes': notes,
            'changed_at': DateTime.now().toIso8601String(),
            'changed_by': supabase.auth.currentUser?.id,
          })
          .eq('id', personAttendanceId);

      setState(() {
        _personNotes[personId] = notes;
      });

      if (mounted) {
        ToastHelper.showSuccess(context, notes?.isNotEmpty == true ? 'Notiz gespeichert' : 'Notiz gelöscht');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  /// Show modifier info (who changed, when)
  Future<void> _showModifierInfo(int personId) async {
    final changedBy = _changedBy[personId];
    final changedAt = _changedAt[personId];

    String message;
    if (changedBy == null) {
      message = 'Der Status wurde bisher nicht verändert.';
    } else {
      // Try to get the user name from players
      final persons = ref.read(allPersonsForAttendanceProvider).valueOrNull ?? [];
      final modifier = persons.firstWhere(
        (p) => p.appId == changedBy,
        orElse: () => Person(firstName: 'Unbekannt', lastName: ''),
      );

      final modifierName = modifier.fullName.isNotEmpty ? modifier.fullName : 'Unbekannt';
      message = 'Zuletzt geändert von $modifierName';

      if (changedAt != null) {
        final date = DateTime.tryParse(changedAt);
        if (date != null) {
          message += '\nam ${DateFormat('dd.MM.yyyy').format(date)} um ${DateFormat('HH:mm').format(date)} Uhr';
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _batchUpdateSelected(AttendanceStatus status) async {
    // Get the personAttendanceIds for selected persons
    final ids = _selectedPersonIds
        .map((personId) => _personAttendanceIds[personId])
        .whereType<String>()
        .toList();

    if (ids.isEmpty) {
      ToastHelper.showError(context, 'Keine Personen mit Anwesenheitseinträgen ausgewählt');
      return;
    }

    // Update local state immediately
    setState(() {
      for (final personId in _selectedPersonIds) {
        _localStatuses[personId] = status;
      }
      _hasChanges = true;
    });

    // Save to backend
    await ref.read(attendanceNotifierProvider.notifier).batchUpdatePersonAttendances(
      ids,
      widget.attendanceId,
      status,
    );

    if (mounted) {
      ToastHelper.showSuccess(context, '${_selectedPersonIds.length} Einträge aktualisiert');
      _exitSelectionMode();
      ref.invalidate(personAttendancesForAttendanceProvider(widget.attendanceId));
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'all_present':
        _setAllStatus(AttendanceStatus.present);
        break;
      case 'all_absent':
        _setAllStatus(AttendanceStatus.absent);
        break;
      case 'stats':
        _showStatsDialog();
        break;
      case 'notes':
        _showNotesDialog();
        break;
      case 'photo':
        _takePhoto();
        break;
      case 'switchMode':
        _toggleViewMode();
        break;
      case 'export_excel':
        _exportAttendanceToExcel();
        break;
    }
  }

  /// Toggle between click and select view modes
  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == AttendanceViewMode.click
          ? AttendanceViewMode.select
          : AttendanceViewMode.click;
    });
    _saveViewMode();
    ToastHelper.showInfo(
      context,
      _viewMode == AttendanceViewMode.click
          ? 'Klick-Modus aktiviert'
          : 'Auswahl-Modus aktiviert',
    );
  }

  // ============== CHECKLIST METHODS ==============

  /// Toggle checklist item completion
  Future<void> _toggleChecklistItem(int index) async {
    if (index < 0 || index >= _localChecklist.length) return;

    final item = _localChecklist[index];
    final updatedItem = ChecklistItem(
      id: item.id,
      text: item.text,
      deadlineHours: item.deadlineHours,
      completed: !item.completed,
      dueDate: item.dueDate,
    );

    setState(() {
      _localChecklist[index] = updatedItem;
    });

    // Persist to database
    await _saveChecklist();
  }

  /// Add a new checklist item
  Future<void> _addChecklistItem() async {
    final result = await DialogHelper.showTextInput(
      context,
      title: 'To-Do hinzufügen',
      hint: 'Beschreibung eingeben...',
      confirmText: 'Hinzufügen',
    );

    if (result != null && result.trim().isNotEmpty && mounted) {
      final newItem = ChecklistItem(
        id: const Uuid().v4(),
        text: result.trim(),
        completed: false,
      );

      setState(() {
        _localChecklist.add(newItem);
      });

      await _saveChecklist();
      ToastHelper.showSuccess(context, 'To-Do hinzugefügt');
    }
  }

  /// Remove a checklist item
  Future<void> _removeChecklistItem(int index) async {
    if (index < 0 || index >= _localChecklist.length) return;

    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'To-Do löschen?',
      message: 'Möchtest du dieses To-Do wirklich löschen?',
      confirmText: 'Löschen',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() {
        _localChecklist.removeAt(index);
      });

      await _saveChecklist();
      ToastHelper.showSuccess(context, 'To-Do gelöscht');
    }
  }

  /// Restore default checklist from AttendanceType
  Future<void> _restoreChecklist() async {
    final attendanceType = ref.read(attendanceTypeForAttendanceProvider(widget.attendanceId)).valueOrNull;
    if (attendanceType?.checklist == null || attendanceType!.checklist!.isEmpty) {
      ToastHelper.showInfo(context, 'Keine Standard-Checkliste für diesen Typ verfügbar');
      return;
    }

    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Checkliste wiederherstellen?',
      message: 'Die aktuelle Checkliste wird durch die Standard-Checkliste ersetzt.',
      confirmText: 'Wiederherstellen',
    );

    if (confirmed == true && mounted) {
      // Clone checklist items with new IDs and reset completion status
      final restoredList = attendanceType.checklist!.map((item) {
        // Calculate due date based on deadlineHours and attendance date
        String? dueDate;
        if (item.deadlineHours != null) {
          final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
          if (attendance != null) {
            final attendanceDate = DateTime.tryParse(attendance.date);
            if (attendanceDate != null) {
              final deadline = attendanceDate.subtract(Duration(hours: item.deadlineHours!));
              dueDate = deadline.toIso8601String();
            }
          }
        }

        return ChecklistItem(
          id: const Uuid().v4(),
          text: item.text,
          deadlineHours: item.deadlineHours,
          completed: false,
          dueDate: dueDate,
        );
      }).toList();

      setState(() {
        _localChecklist = restoredList;
      });

      await _saveChecklist();
      ToastHelper.showSuccess(context, 'Checkliste wiederhergestellt');
    }
  }

  /// Save checklist to database
  /// SEC-018: Added tenantId filter for multi-tenant security
  Future<void> _saveChecklist() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);
      if (tenant?.id == null) return;
      final checklistJson = _localChecklist.map((item) => item.toJson()).toList();

      await supabase
          .from('attendance')
          .update({'checklist': checklistJson})
          .eq('id', widget.attendanceId)
          .eq('tenantId', tenant!.id!);

      ref.invalidate(attendanceDetailProvider(widget.attendanceId));
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

  /// Get deadline status for a checklist item
  _DeadlineStatus _getDeadlineStatus(ChecklistItem item) {
    if (item.completed) return _DeadlineStatus.normal;
    if (item.dueDate == null) return _DeadlineStatus.normal;

    final dueDate = DateTime.tryParse(item.dueDate!);
    if (dueDate == null) return _DeadlineStatus.normal;

    final now = DateTime.now();
    if (now.isAfter(dueDate)) {
      return _DeadlineStatus.overdue;
    }

    final warningThreshold = dueDate.subtract(const Duration(hours: 24));
    if (now.isAfter(warningThreshold)) {
      return _DeadlineStatus.warning;
    }

    return _DeadlineStatus.normal;
  }

  /// Format deadline relative to now
  String _formatDeadlineRelative(ChecklistItem item) {
    if (item.dueDate == null) return '';

    final dueDate = DateTime.tryParse(item.dueDate!);
    if (dueDate == null) return '';

    final now = DateTime.now();
    final diff = dueDate.difference(now);

    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inDays > 0) {
        return '${absDiff.inDays} Tag(e) überfällig';
      } else if (absDiff.inHours > 0) {
        return '${absDiff.inHours} Std. überfällig';
      } else {
        return 'überfällig';
      }
    } else {
      if (diff.inDays > 0) {
        return 'in ${diff.inDays} Tag(en)';
      } else if (diff.inHours > 0) {
        return 'in ${diff.inHours} Std.';
      } else {
        return 'in ${diff.inMinutes} Min.';
      }
    }
  }

  // ============== DEADLINE METHODS ==============

  /// Toggle deadline on/off
  Future<void> _toggleDeadline(bool enabled) async {
    String? deadlineStr;

    if (enabled) {
      // Set default deadline to day before attendance
      final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
      if (attendance != null) {
        final attendanceDate = DateTime.tryParse(attendance.date);
        if (attendanceDate != null) {
          final defaultDeadline = attendanceDate.subtract(const Duration(days: 1));
          deadlineStr = defaultDeadline.toIso8601String();
        }
      }
    }

    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);
      if (tenant?.id == null) return;
      await supabase
          .from('attendance')
          .update({'deadline': deadlineStr})
          .eq('id', widget.attendanceId)
          .eq('tenantId', tenant!.id!);

      ref.invalidate(attendanceDetailProvider(widget.attendanceId));

      if (mounted) {
        ToastHelper.showSuccess(
          context,
          enabled ? 'Anmeldefrist aktiviert' : 'Anmeldefrist deaktiviert',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  /// Select deadline date
  Future<void> _selectDeadline() async {
    final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
    if (attendance == null) return;

    final attendanceDate = DateTime.tryParse(attendance.date);
    final currentDeadline = attendance.deadline != null
        ? DateTime.tryParse(attendance.deadline!)
        : null;

    final now = DateTime.now();
    final initialDate = currentDeadline ?? attendanceDate?.subtract(const Duration(days: 1)) ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: attendanceDate ?? now.add(const Duration(days: 365)),
      helpText: 'Anmeldefrist wählen',
    );

    if (selectedDate == null || !mounted) return;

    // Also allow time selection
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (!mounted) return;

    final finalDeadline = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime?.hour ?? 23,
      selectedTime?.minute ?? 59,
    );

    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);
      if (tenant?.id == null) return;
      await supabase
          .from('attendance')
          .update({'deadline': finalDeadline.toIso8601String()})
          .eq('id', widget.attendanceId)
          .eq('tenantId', tenant!.id!);

      ref.invalidate(attendanceDetailProvider(widget.attendanceId));

      if (mounted) {
        ToastHelper.showSuccess(context, 'Anmeldefrist aktualisiert');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  // ============== SONGS/HISTORY METHODS ==============

  /// Open songs selection sheet
  Future<void> _openSongsSelection() async {
    final result = await SongsSelectionSheet.show(
      context,
      existingEntries: _songEntries,
    );

    if (result != null && mounted) {
      setState(() {
        _songEntries = result;
      });
      await _saveSongEntries();
    }
  }

  /// Remove a song entry
  Future<void> _removeSongEntry(int index) async {
    if (index < 0 || index >= _songEntries.length) return;

    setState(() {
      _songEntries.removeAt(index);
    });

    await _saveSongEntries();
    if (mounted) {
      ToastHelper.showSuccess(context, 'Werk entfernt');
    }
  }

  /// Save song entries to database
  /// SEC-019: Added tenantId filter for multi-tenant security
  Future<void> _saveSongEntries() async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);
      if (tenant?.id == null) return;
      final songIds = _songEntries.map((e) => e.songId).toList();
      final conductorIds = _songEntries
          .map((e) => e.conductorId)
          .where((id) => id != null)
          .toList();

      await supabase
          .from('attendance')
          .update({
            'songs': songIds,
            'conductors': conductorIds,
          })
          .eq('id', widget.attendanceId)
          .eq('tenantId', tenant!.id!);

      ref.invalidate(attendanceDetailProvider(widget.attendanceId));
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

  // ============== GENERAL INFO METHODS ==============

  /// Update typeInfo field
  /// SEC-020: Added tenantId filter for multi-tenant security
  Future<void> _updateTypeInfo(String value) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);
      if (tenant?.id == null) return;
      await supabase
          .from('attendance')
          .update({'typeInfo': value.isEmpty ? null : value})
          .eq('id', widget.attendanceId)
          .eq('tenantId', tenant!.id!);

      ref.invalidate(attendanceDetailProvider(widget.attendanceId));
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  /// Update start time
  Future<void> _selectStartTime() async {
    final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
    if (attendance == null) return;

    final currentTime = attendance.startTime != null
        ? TimeOfDay(
            hour: int.tryParse(attendance.startTime!.split(':')[0]) ?? 17,
            minute: int.tryParse(attendance.startTime!.split(':')[1]) ?? 0,
          )
        : const TimeOfDay(hour: 17, minute: 0);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (selectedTime == null || !mounted) return;

    final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);
      if (tenant?.id == null) return;
      await supabase
          .from('attendance')
          .update({'start_time': timeStr})
          .eq('id', widget.attendanceId)
          .eq('tenantId', tenant!.id!);

      ref.invalidate(attendanceDetailProvider(widget.attendanceId));
      ToastHelper.showSuccess(context, 'Startzeit aktualisiert');
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  /// Update end time
  Future<void> _selectEndTime() async {
    final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
    if (attendance == null) return;

    final currentTime = attendance.endTime != null
        ? TimeOfDay(
            hour: int.tryParse(attendance.endTime!.split(':')[0]) ?? 20,
            minute: int.tryParse(attendance.endTime!.split(':')[1]) ?? 0,
          )
        : const TimeOfDay(hour: 20, minute: 0);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (selectedTime == null || !mounted) return;

    final timeStr = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);
      if (tenant?.id == null) return;
      await supabase
          .from('attendance')
          .update({'end_time': timeStr})
          .eq('id', widget.attendanceId)
          .eq('tenantId', tenant!.id!);

      ref.invalidate(attendanceDetailProvider(widget.attendanceId));
      ToastHelper.showSuccess(context, 'Endzeit aktualisiert');
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  /// Export attendance to Excel
  Future<void> _exportAttendanceToExcel() async {
    try {
      final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
      final persons = ref.read(filteredPersonsForAttendanceProvider(widget.attendanceId)).valueOrNull;
      final tenant = ref.read(currentTenantProvider);

      if (attendance == null || persons == null || tenant == null) {
        ToastHelper.showError(context, 'Daten nicht verfügbar');
        return;
      }

      ToastHelper.showInfo(context, 'Erstelle Excel-Export...');

      final exportService = ExportService();
      await exportService.exportAttendanceToExcel(
        context: context,
        attendance: attendance,
        persons: persons,
        statuses: _localStatuses,
        tenantName: tenant.shortName,
      );
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Export: $e');
      }
    }
  }

  // ============== PERSON REMOVE METHOD ==============

  /// Remove a person from this attendance
  /// SEC-023: Added tenant validation before delete
  Future<void> _removePersonFromAttendance(int personId) async {
    final personAttendanceId = _personAttendanceIds[personId];
    if (personAttendanceId == null) {
      ToastHelper.showError(context, 'Kein Anwesenheitseintrag gefunden');
      return;
    }

    // SEC-023: Validate tenant ownership
    final isValid = await _validatePersonAttendanceTenant(personAttendanceId);
    if (!isValid) {
      if (mounted) {
        ToastHelper.showError(context, 'Keine Berechtigung');
      }
      return;
    }

    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Person entfernen?',
      message: 'Möchtest du diese Person aus der Anwesenheitsliste entfernen?',
      confirmText: 'Entfernen',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('person_attendances')
          .delete()
          .eq('id', personAttendanceId);

      // Remove from local state
      setState(() {
        _localStatuses.remove(personId);
        _personAttendanceIds.remove(personId);
        _personNotes.remove(personId);
        _changedBy.remove(personId);
        _changedAt.remove(personId);
      });

      // Refresh data
      ref.invalidate(personAttendancesForAttendanceProvider(widget.attendanceId));
      ref.invalidate(filteredPersonsForAttendanceProvider(widget.attendanceId));

      ToastHelper.showSuccess(context, 'Person entfernt');
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  void _setAllStatus(AttendanceStatus status) {
    final persons = ref.read(allPersonsForAttendanceProvider).valueOrNull ?? [];
    setState(() {
      for (final person in persons) {
        if (person.id != null) {
          _localStatuses[person.id!] = status;
        }
      }
      _hasChanges = true;
    });
  }

  /// Show statistics dialog
  void _showStatsDialog() {
    final persons = ref.read(allPersonsForAttendanceProvider).valueOrNull ?? [];
    final total = persons.length;
    final present = _localStatuses.values.where((s) => s == AttendanceStatus.present).length;
    final excused = _localStatuses.values.where((s) => s.isExcused).length;
    final absent = _localStatuses.values.where((s) => s == AttendanceStatus.absent).length;
    final late = _localStatuses.values.where((s) => s == AttendanceStatus.late || s == AttendanceStatus.lateExcused).length;
    final unknown = total - present - excused - absent - late;
    final percentage = total > 0 ? (present / total * 100) : 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Statistik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Gesamt', total, AppColors.primary),
            const Divider(),
            _buildStatRow('Anwesend', present, AppColors.success,
                percentage: total > 0 ? present / total * 100 : 0),
            _buildStatRow('Entschuldigt', excused, AppColors.info,
                percentage: total > 0 ? excused / total * 100 : 0),
            _buildStatRow('Abwesend', absent, AppColors.danger,
                percentage: total > 0 ? absent / total * 100 : 0),
            _buildStatRow('Verspätet', late, AppColors.warning,
                percentage: total > 0 ? late / total * 100 : 0),
            _buildStatRow('Offen', unknown, AppColors.medium,
                percentage: total > 0 ? unknown / total * 100 : 0),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, color: AppColors.success),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    'Anwesenheitsrate: ${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color, {double? percentage}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXS),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(child: Text(label)),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (percentage != null) ...[
            const SizedBox(width: AppDimensions.paddingS),
            SizedBox(
              width: 50,
              child: Text(
                '(${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(color: AppColors.medium, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Show notes dialog
  Future<void> _showNotesDialog() async {
    final attendance = ref.read(attendanceDetailProvider(widget.attendanceId)).valueOrNull;
    final currentNotes = attendance?.notes ?? '';

    final result = await DialogHelper.showTextInput(
      context,
      title: 'Notizen',
      initialValue: currentNotes,
      hint: 'Notizen zur Anwesenheit...',
      maxLines: 5,
      confirmText: 'Speichern',
    );

    if (result != null && mounted) {
      try {
        final supabase = ref.read(supabaseClientProvider);
        final tenant = ref.read(currentTenantProvider);
        if (tenant?.id == null) return;
        await supabase
            .from('attendance')
            .update({'notes': result})
            .eq('id', widget.attendanceId)
            .eq('tenantId', tenant!.id!);

        ref.invalidate(attendanceDetailProvider(widget.attendanceId));
        if (mounted) {
          ToastHelper.showSuccess(context, 'Notizen gespeichert');
        }
      } catch (e) {
        if (mounted) {
          ToastHelper.showError(context, 'Fehler: $e');
        }
      }
    }
  }

  /// Take or select a photo for this attendance
  Future<void> _takePhoto() async {
    // Show source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Foto hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      ToastHelper.showInfo(context, 'Lade Foto hoch...');

      // Read file bytes
      final bytes = await image.readAsBytes();
      final fileName = 'attendance_${widget.attendanceId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase storage
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);

      if (tenant == null) {
        if (mounted) {
          ToastHelper.showError(context, 'Kein Tenant ausgewählt');
        }
        return;
      }

      final storagePath = '${tenant.id}/attendance/$fileName';

      await supabase.storage
          .from('attendance-images')
          .uploadBinary(storagePath, bytes);

      // Get the public URL
      final publicUrl = supabase.storage
          .from('attendance-images')
          .getPublicUrl(storagePath);

      // Update attendance with image URL
      await supabase
          .from('attendance')
          .update({'img': publicUrl})
          .eq('id', widget.attendanceId)
          .eq('tenantId', tenant.id!);

      // Refresh the attendance data
      ref.invalidate(attendanceDetailProvider(widget.attendanceId));

      if (mounted) {
        ToastHelper.showSuccess(context, 'Foto hochgeladen');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Hochladen: $e');
      }
    }
  }

  Future<void> _saveChanges() async {
    // Get all changed entries
    final changedEntries = <MapEntry<int, AttendanceStatus>>[];

    for (final entry in _localStatuses.entries) {
      final personAttendanceId = _personAttendanceIds[entry.key];
      if (personAttendanceId != null) {
        changedEntries.add(entry);
      }
    }

    if (changedEntries.isEmpty) {
      ToastHelper.showInfo(context, 'Keine Änderungen vorhanden');
      return;
    }

    // Update each person attendance
    final notifier = ref.read(attendanceNotifierProvider.notifier);

    for (final entry in changedEntries) {
      final personAttendanceId = _personAttendanceIds[entry.key];
      if (personAttendanceId != null) {
        await notifier.updatePersonAttendance(
          personAttendanceId,
          widget.attendanceId,
          entry.key,
          {'status': entry.value.value},
        );
      }
    }

    // Recalculate percentage
    await notifier.recalculatePercentage(widget.attendanceId);

    if (mounted) {
      ToastHelper.showSuccess(context, 'Änderungen gespeichert');
      setState(() => _hasChanges = false);
      ref.invalidate(personAttendancesForAttendanceProvider(widget.attendanceId));
      ref.invalidate(attendanceDetailProvider(widget.attendanceId));
    }
  }

  // Status UI helpers - use extension properties from AttendanceStatus
  Color _getStatusColor(AttendanceStatus status) => status.color;
  IconData _getStatusIcon(AttendanceStatus status) => status.icon;
  String _getStatusLabel(AttendanceStatus status) => status.label;
}

class _AttendanceGrid extends StatelessWidget {
  const _AttendanceGrid({
    required this.persons,
    required this.localStatuses,
    required this.personNotes,
    required this.changedBy,
    required this.changedAt,
    required this.selectedPersonIds,
    required this.isSelectionMode,
    required this.availableStatuses,
    required this.onStatusChanged,
    required this.onLongPress,
    required this.onSelectionToggle,
    required this.onNoteChanged,
    required this.onShowModifierInfo,
    required this.onRemoveFromAttendance,
  });

  final List<Person> persons;
  final Map<int, AttendanceStatus> localStatuses;
  final Map<int, String?> personNotes;
  final Map<int, String?> changedBy;
  final Map<int, String?> changedAt;
  final Set<int> selectedPersonIds;
  final bool isSelectionMode;
  final List<AttendanceStatus> availableStatuses;
  final void Function(int personId, AttendanceStatus status) onStatusChanged;
  final void Function(int personId) onLongPress;
  final void Function(int personId) onSelectionToggle;
  final void Function(int personId, String? notes) onNoteChanged;
  final void Function(int personId) onShowModifierInfo;
  final void Function(int personId) onRemoveFromAttendance;

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return const Center(
        child: Text('Keine Personen gefunden'),
      );
    }

    // Group persons by instrument/group
    final grouped = _groupByInstrument(persons);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        return _InstrumentGroupSection(
          groupName: group.groupName,
          persons: group.persons,
          localStatuses: localStatuses,
          personNotes: personNotes,
          changedBy: changedBy,
          changedAt: changedAt,
          selectedPersonIds: selectedPersonIds,
          isSelectionMode: isSelectionMode,
          availableStatuses: availableStatuses,
          onStatusChanged: onStatusChanged,
          onLongPress: onLongPress,
          onSelectionToggle: onSelectionToggle,
          onNoteChanged: onNoteChanged,
          onShowModifierInfo: onShowModifierInfo,
          onRemoveFromAttendance: onRemoveFromAttendance,
        );
      },
    );
  }

  List<_InstrumentGroup> _groupByInstrument(List<Person> persons) {
    final Map<String, List<Person>> grouped = {};

    for (final person in persons) {
      final groupName = person.groupName ?? 'Unbekannt';
      grouped.putIfAbsent(groupName, () => []).add(person);
    }

    return grouped.entries
        .map((e) => _InstrumentGroup(groupName: e.key, persons: e.value))
        .toList()
      ..sort((a, b) => a.groupName.compareTo(b.groupName));
  }
}

class _InstrumentGroup {
  final String groupName;
  final List<Person> persons;

  _InstrumentGroup({required this.groupName, required this.persons});
}

class _InstrumentGroupSection extends StatelessWidget {
  const _InstrumentGroupSection({
    required this.groupName,
    required this.persons,
    required this.localStatuses,
    required this.personNotes,
    required this.changedBy,
    required this.changedAt,
    required this.selectedPersonIds,
    required this.isSelectionMode,
    required this.availableStatuses,
    required this.onStatusChanged,
    required this.onLongPress,
    required this.onSelectionToggle,
    required this.onNoteChanged,
    required this.onShowModifierInfo,
    required this.onRemoveFromAttendance,
  });

  final String groupName;
  final List<Person> persons;
  final Map<int, AttendanceStatus> localStatuses;
  final Map<int, String?> personNotes;
  final Map<int, String?> changedBy;
  final Map<int, String?> changedAt;
  final Set<int> selectedPersonIds;
  final bool isSelectionMode;
  final List<AttendanceStatus> availableStatuses;
  final void Function(int personId, AttendanceStatus status) onStatusChanged;
  final void Function(int personId) onLongPress;
  final void Function(int personId) onSelectionToggle;
  final void Function(int personId, String? notes) onNoteChanged;
  final void Function(int personId) onShowModifierInfo;
  final void Function(int personId) onRemoveFromAttendance;

  @override
  Widget build(BuildContext context) {
    // Count present persons (present, late, or lateExcused)
    final presentCount = persons.where((p) {
      final status = localStatuses[p.id];
      return status == AttendanceStatus.present ||
             status == AttendanceStatus.late ||
             status == AttendanceStatus.lateExcused;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            children: [
              Text(
                groupName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$presentCount/${persons.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...persons.map((person) {
          final status = localStatuses[person.id] ?? AttendanceStatus.neutral;
          final isSelected = selectedPersonIds.contains(person.id);
          final notes = personNotes[person.id];

          return _AttendancePersonTile(
            person: person,
            status: status,
            notes: notes,
            isSelected: isSelected,
            isSelectionMode: isSelectionMode,
            availableStatuses: availableStatuses,
            onStatusChanged: (newStatus) {
              if (person.id != null) {
                onStatusChanged(person.id!, newStatus);
              }
            },
            onLongPress: () {
              if (person.id != null) {
                onLongPress(person.id!);
              }
            },
            onSelectionToggle: () {
              if (person.id != null) {
                onSelectionToggle(person.id!);
              }
            },
            onNoteChanged: (newNotes) {
              if (person.id != null) {
                onNoteChanged(person.id!, newNotes);
              }
            },
            onShowModifierInfo: () {
              if (person.id != null) {
                onShowModifierInfo(person.id!);
              }
            },
            onRemoveFromAttendance: () {
              if (person.id != null) {
                onRemoveFromAttendance(person.id!);
              }
            },
          );
        }),
        const SizedBox(height: AppDimensions.paddingS),
      ],
    );
  }
}

class _AttendancePersonTile extends StatelessWidget {
  const _AttendancePersonTile({
    required this.person,
    required this.status,
    required this.notes,
    required this.isSelected,
    required this.isSelectionMode,
    required this.availableStatuses,
    required this.onStatusChanged,
    required this.onLongPress,
    required this.onSelectionToggle,
    required this.onNoteChanged,
    required this.onShowModifierInfo,
    required this.onRemoveFromAttendance,
  });

  final Person person;
  final AttendanceStatus status;
  final String? notes;
  final bool isSelected;
  final bool isSelectionMode;
  final List<AttendanceStatus> availableStatuses;
  final void Function(AttendanceStatus) onStatusChanged;
  final VoidCallback onLongPress;
  final VoidCallback onSelectionToggle;
  final void Function(String?) onNoteChanged;
  final VoidCallback onShowModifierInfo;
  final VoidCallback onRemoveFromAttendance;

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes?.isNotEmpty == true;

    return Slidable(
      key: ValueKey(person.id),
      enabled: !isSelectionMode,
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onRemoveFromAttendance(),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon: Icons.person_remove,
            label: 'Entfernen',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          // Neutral status swipe action (if not already neutral)
          if (status != AttendanceStatus.neutral)
            SlidableAction(
              onPressed: (_) => onStatusChanged(AttendanceStatus.neutral),
              backgroundColor: AppColors.medium,
              foregroundColor: Colors.white,
              icon: Icons.remove_circle_outline,
              label: 'Neutral',
            ),
          SlidableAction(
            onPressed: (_) => _showNoteDialog(context),
            backgroundColor: AppColors.info,
            foregroundColor: Colors.white,
            icon: hasNotes ? Icons.edit_note : Icons.note_add,
            label: 'Notiz',
          ),
          SlidableAction(
            onPressed: (_) => onShowModifierInfo(),
            backgroundColor: AppColors.tertiary,
            foregroundColor: Colors.white,
            icon: Icons.info_outline,
            label: 'Info',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingXS),
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
        child: InkWell(
          onTap: isSelectionMode ? onSelectionToggle : () => _showStatusPicker(context),
          onLongPress: isSelectionMode ? null : onLongPress,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: Row(
              children: [
                // Selection checkbox or Avatar
                if (isSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onSelectionToggle(),
                    activeColor: AppColors.primary,
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getStatusColor(status).withValues(alpha: 0.2),
                    backgroundImage: person.img != null ? NetworkImage(person.img!) : null,
                    child: person.img == null
                        ? Text(
                            person.initials,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                const SizedBox(width: AppDimensions.paddingM),

                // Name and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            person.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (hasNotes) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.sticky_note_2,
                              size: 14,
                              color: AppColors.info,
                            ),
                          ],
                        ],
                      ),
                      if (person.groupName != null && !isSelectionMode)
                        Text(
                          person.groupName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.medium,
                          ),
                        ),
                    ],
                  ),
                ),

                // Status indicator
                _StatusChip(
                  status: status,
                  onTap: () => _showStatusPicker(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context) {
    final controller = TextEditingController(text: notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notiz für ${person.fullName}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Notiz eingeben...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          if (notes?.isNotEmpty == true)
            TextButton(
              onPressed: () {
                onNoteChanged(null);
                Navigator.of(ctx).pop();
              },
              child: const Text('Löschen', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final newNotes = controller.text.trim();
              onNoteChanged(newNotes.isEmpty ? null : newNotes);
              Navigator.of(ctx).pop();
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                person.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Status auswählen'),
            ),
            const Divider(),
            ...availableStatuses.map((s) => ListTile(
              leading: Icon(
                _getStatusIcon(s),
                color: _getStatusColor(s),
              ),
              title: Text(s.label),
              selected: s == status,
              onTap: () {
                onStatusChanged(s);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: AppDimensions.paddingM),
          ],
        ),
      ),
    );
  }

  // Use extension properties from AttendanceStatus
  Color _getStatusColor(AttendanceStatus status) => status.color;
  IconData _getStatusIcon(AttendanceStatus status) => status.icon;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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

class _AttendanceStatusBar extends StatelessWidget {
  const _AttendanceStatusBar({
    required this.persons,
    required this.localStatuses,
    required this.selectedCount,
    required this.isSelectionMode,
  });

  final List<Person> persons;
  final Map<int, AttendanceStatus> localStatuses;
  final int selectedCount;
  final bool isSelectionMode;

  @override
  Widget build(BuildContext context) {
    final total = persons.length;
    // Count present (including late as they are physically present)
    final present = localStatuses.values.where((s) =>
        s == AttendanceStatus.present ||
        s == AttendanceStatus.late ||
        s == AttendanceStatus.lateExcused).length;
    // Count excused (but not lateExcused as those are counted in present)
    final excused = localStatuses.values.where((s) => s == AttendanceStatus.excused).length;
    final absent = localStatuses.values.where((s) => s == AttendanceStatus.absent).length;
    // Unknown = neutral status (not yet recorded)
    final unknown = localStatuses.values.where((s) => s == AttendanceStatus.neutral).length;
    final percentage = total > 0 ? (present / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Anwesend',
              value: '$present',
              color: AppColors.success,
            ),
            _StatItem(
              label: 'Entsch.',
              value: '$excused',
              color: AppColors.info,
            ),
            _StatItem(
              label: 'Abwesend',
              value: '$absent',
              color: AppColors.danger,
            ),
            _StatItem(
              label: 'Offen',
              value: '$unknown',
              color: AppColors.medium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              ),
              child: Text(
                '${percentage.round()}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.medium,
          ),
        ),
      ],
    );
  }
}

// ============== DEADLINE STATUS ENUM ==============

enum _DeadlineStatus { normal, warning, overdue }

// ============== CHECKLIST ACCORDION ==============

class _ChecklistAccordion extends StatelessWidget {
  const _ChecklistAccordion({
    required this.checklist,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
    required this.onRestore,
    required this.getDeadlineStatus,
    required this.formatDeadlineRelative,
  });

  final List<ChecklistItem> checklist;
  final void Function(int index) onToggle;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onRestore;
  final _DeadlineStatus Function(ChecklistItem) getDeadlineStatus;
  final String Function(ChecklistItem) formatDeadlineRelative;

  @override
  Widget build(BuildContext context) {
    final completedCount = checklist.where((item) => item.completed).length;
    final totalCount = checklist.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.checklist, color: AppColors.primary),
        title: Row(
          children: [
            const Text('Checkliste'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: progress == 1.0
                    ? AppColors.success.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: progress == 1.0 ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        children: [
          if (checklist.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingM),
              child: Text(
                'Keine To-Dos vorhanden',
                style: TextStyle(color: AppColors.medium),
              ),
            )
          else
            ...checklist.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final deadlineStatus = getDeadlineStatus(item);
              final deadlineText = formatDeadlineRelative(item);

              Color? tileColor;
              if (!item.completed) {
                if (deadlineStatus == _DeadlineStatus.overdue) {
                  tileColor = AppColors.danger.withValues(alpha: 0.1);
                } else if (deadlineStatus == _DeadlineStatus.warning) {
                  tileColor = AppColors.warning.withValues(alpha: 0.1);
                }
              }

              return Slidable(
                key: ValueKey(item.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (_) => onRemove(index),
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Löschen',
                    ),
                  ],
                ),
                child: Container(
                  color: tileColor,
                  child: CheckboxListTile(
                    value: item.completed,
                    onChanged: (_) => onToggle(index),
                    title: Text(
                      item.text,
                      style: TextStyle(
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.completed ? AppColors.medium : null,
                      ),
                    ),
                    subtitle: deadlineText.isNotEmpty
                        ? Text(
                            deadlineText,
                            style: TextStyle(
                              fontSize: 12,
                              color: deadlineStatus == _DeadlineStatus.overdue
                                  ? AppColors.danger
                                  : deadlineStatus == _DeadlineStatus.warning
                                      ? AppColors.warning
                                      : AppColors.medium,
                            ),
                          )
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
              );
            }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('To-Do hinzufügen'),
                ),
                TextButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Wiederherstellen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== GENERAL INFO ACCORDION ==============

class _GeneralInfoAccordion extends StatelessWidget {
  const _GeneralInfoAccordion({
    required this.attendance,
    required this.attendanceType,
    required this.onTypeInfoChanged,
    required this.onNotesChanged,
    required this.onStartTimeSelect,
    required this.onEndTimeSelect,
    required this.onDeadlineToggle,
    required this.onDeadlineSelect,
    required this.onExportExcel,
  });

  final Attendance attendance;
  final AttendanceType? attendanceType;
  final void Function(String) onTypeInfoChanged;
  final void Function(String) onNotesChanged;
  final VoidCallback onStartTimeSelect;
  final VoidCallback onEndTimeSelect;
  final void Function(bool) onDeadlineToggle;
  final VoidCallback onDeadlineSelect;
  final VoidCallback onExportExcel;

  @override
  Widget build(BuildContext context) {
    final hasDeadline = attendance.deadline != null;
    final isAllDay = attendanceType?.allDay ?? false;

    String? formattedDeadline;
    if (hasDeadline && attendance.deadline != null) {
      final deadline = DateTime.tryParse(attendance.deadline!);
      if (deadline != null) {
        formattedDeadline = DateFormat('dd.MM.yyyy HH:mm').format(deadline);
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline, color: AppColors.primary),
        title: const Text('Allgemein'),
        children: [
          // Type badge (read-only)
          if (attendanceType != null)
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Typ'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorUtils.parseNamedColor(attendanceType!.color)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  attendanceType!.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              dense: true,
            ),

          // TypeInfo TextField
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Bezeichnung',
                hintText: 'z.B. Generalprobe, Konzert...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              controller: TextEditingController(text: attendance.typeInfo ?? ''),
              onSubmitted: onTypeInfoChanged,
            ),
          ),

          // Notes TextField
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Notizen',
                hintText: 'Allgemeine Notizen...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_outlined),
              ),
              controller: TextEditingController(text: attendance.notes ?? ''),
              maxLines: 2,
              onSubmitted: onNotesChanged,
            ),
          ),

          // Time pickers (if not all-day)
          if (!isAllDay) ...[
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Beginn'),
              trailing: Text(
                attendance.startTime ?? 'Nicht gesetzt',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: onStartTimeSelect,
              dense: true,
            ),
            ListTile(
              leading: const Icon(Icons.access_time_filled),
              title: const Text('Ende'),
              trailing: Text(
                attendance.endTime ?? 'Nicht gesetzt',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: onEndTimeSelect,
              dense: true,
            ),
          ],

          // Duration (if all-day)
          if (isAllDay)
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Dauer'),
              trailing: Text(
                '${attendance.durationDays ?? 1} Tag(e)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              dense: true,
            ),

          const Divider(),

          // Deadline toggle
          SwitchListTile(
            secondary: const Icon(Icons.event_busy),
            title: const Text('Anmeldefrist'),
            subtitle: hasDeadline && formattedDeadline != null
                ? Text(formattedDeadline)
                : const Text('Nicht gesetzt'),
            value: hasDeadline,
            onChanged: onDeadlineToggle,
          ),

          // Deadline picker (if enabled)
          if (hasDeadline)
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('Frist ändern'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onDeadlineSelect,
              dense: true,
            ),

          const Divider(),

          // Export button
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: TextButton.icon(
              onPressed: onExportExcel,
              icon: const Icon(Icons.table_chart),
              label: const Text('Als Excel exportieren'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== SONGS HISTORY ACCORDION ==============

class _SongsHistoryAccordion extends StatelessWidget {
  const _SongsHistoryAccordion({
    required this.entries,
    required this.onAdd,
    required this.onRemove,
  });

  final List<SongHistoryEntry> entries;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.music_note, color: AppColors.primary),
        title: Row(
          children: [
            const Text('Werke'),
            const SizedBox(width: 8),
            if (entries.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entries.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        children: [
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingM),
              child: Text(
                'Keine Werke ausgewählt',
                style: TextStyle(color: AppColors.medium),
              ),
            )
          else
            ...entries.asMap().entries.map((entry) {
              final index = entry.key;
              final songEntry = entry.value;

              return Slidable(
                key: ValueKey('${songEntry.songId}-$index'),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (_) => onRemove(index),
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Entfernen',
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(songEntry.songName),
                  subtitle: Text(songEntry.displayConductor),
                  dense: true,
                ),
              );
            }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Werk(e) hinzufügen'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== PLAN ACCORDION ==============

class _PlanAccordion extends StatelessWidget {
  const _PlanAccordion({
    required this.attendance,
    required this.onEdit,
    required this.onExportPdf,
  });

  final Attendance attendance;
  final VoidCallback onEdit;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final plan = attendance.plan;
    final hasPlan = plan != null && plan.isNotEmpty;

    // Parse plan fields
    List<Map<String, dynamic>> fields = [];
    if (hasPlan && plan['fields'] != null) {
      fields = (plan['fields'] as List).cast<Map<String, dynamic>>();
    }

    final startTime = plan?['startTime'] as String? ?? attendance.startTime ?? '17:00';
    final endTime = plan?['endTime'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.schedule, color: AppColors.primary),
        title: Row(
          children: [
            const Text('Ablaufplan'),
            const SizedBox(width: 8),
            if (hasPlan && startTime.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  endTime != null ? '$startTime - $endTime' : startTime,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
          ],
        ),
        children: [
          if (!hasPlan || fields.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppDimensions.paddingM),
              child: Text(
                'Kein Ablaufplan vorhanden',
                style: TextStyle(color: AppColors.medium),
              ),
            )
          else
            ...fields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              final name = field['name'] as String? ?? 'Unbekannt';
              final time = field['time'] as String? ?? '0';
              final conductor = field['conductor'] as String?;

              // Calculate start time for this field
              String calculatedTime = _calculateFieldTime(startTime, fields, index);

              return ListTile(
                leading: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.medium.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    calculatedTime,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                title: Text(name),
                subtitle: conductor != null ? Text(conductor) : null,
                trailing: Text(
                  '$time Min.',
                  style: const TextStyle(color: AppColors.medium),
                ),
                dense: true,
              );
            }),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Bearbeiten'),
                ),
                TextButton.icon(
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF exportieren'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate the start time for a field at given index
  String _calculateFieldTime(String startTime, List<Map<String, dynamic>> fields, int index) {
    final parts = startTime.split(':');
    if (parts.length != 2) return startTime;

    int hours = int.tryParse(parts[0]) ?? 17;
    int minutes = int.tryParse(parts[1]) ?? 0;

    // Add up all previous field times
    for (var i = 0; i < index; i++) {
      final fieldTime = int.tryParse(fields[i]['time']?.toString() ?? '0') ?? 0;
      minutes += fieldTime;
    }

    // Convert overflow minutes to hours
    hours += minutes ~/ 60;
    minutes = minutes % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}