import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/attendance/attendance.dart';
import '../../../../data/models/song/song.dart';
import '../../../../core/providers/tenant_providers.dart';

/// Field Selection for planning
class FieldSelection {
  String id;
  String name;
  String time;
  String? conductor;
  int? songId;

  FieldSelection({
    required this.id,
    required this.name,
    required this.time,
    this.conductor,
    this.songId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time,
        'conductor': conductor,
        'songId': songId,
      };

  factory FieldSelection.fromJson(Map<String, dynamic> json) => FieldSelection(
        id: json['id'] as String,
        name: json['name'] as String,
        time: json['time'] as String,
        conductor: json['conductor'] as String?,
        songId: json['songId'] as int?,
      );
}

/// Provider for upcoming attendances
final upcomingAttendancesProvider = FutureProvider<List<Attendance>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final now = DateTime.now().toIso8601String().substring(0, 10);
  final response = await supabase
      .from('attendance')
      .select('*')
      .eq('tenantId', tenant.id!)
      .gte('date', now)
      .order('date', ascending: true)
      .limit(20);

  return (response as List).map((e) => Attendance.fromJson(e as Map<String, dynamic>)).toList();
});

/// Provider for songs list (for adding to plan)
final planSongsProvider = FutureProvider<List<Song>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('songs')
      .select('*')
      .eq('tenantId', tenant.id!)
      .order('number')
      .order('name');

  return (response as List).map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
});

/// Planning Page
class PlanningPage extends ConsumerStatefulWidget {
  final int? attendanceId;

  const PlanningPage({super.key, this.attendanceId});

  @override
  ConsumerState<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends ConsumerState<PlanningPage> {
  int? _selectedAttendanceId;
  TimeOfDay _startTime = const TimeOfDay(hour: 17, minute: 50);
  TimeOfDay? _endTime;
  List<FieldSelection> _fields = [
    FieldSelection(id: 'default', name: 'Wort', time: '10'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedAttendanceId = widget.attendanceId;
  }

  @override
  Widget build(BuildContext context) {
    final attendancesAsync = ref.watch(upcomingAttendancesProvider);
    final songsAsync = ref.watch(planSongsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Probenplan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _fields = [FieldSelection(id: 'default', name: 'Wort', time: '10')];
              });
              _calculateEnd();
            },
            tooltip: 'Zurücksetzen',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                _exportPlan();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Als PDF exportieren'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Attendance selector
          attendancesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Text('Fehler: $e'),
            ),
            data: (attendances) {
              if (attendances.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppDimensions.paddingM),
                  child: Text('Keine kommenden Termine'),
                );
              }

              // Auto-select first if none selected
              if (_selectedAttendanceId == null && attendances.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _selectedAttendanceId = attendances.first.id;
                    _loadPlanFromAttendance(attendances.first);
                  });
                });
              }

              return Card(
                margin: const EdgeInsets.all(AppDimensions.paddingM),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _navigateAttendance(attendances, -1),
                      ),
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedAttendanceId,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: attendances.map((att) {
                            return DropdownMenuItem(
                              value: att.id,
                              child: Text(
                                '${att.formattedDate} - ${att.typeInfo ?? att.type ?? "Termin"}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedAttendanceId = value);
                              final att = attendances.where((a) => a.id == value).firstOrNull;
                              if (att != null) {
                                _loadPlanFromAttendance(att);
                              }
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _navigateAttendance(attendances, 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Time selector
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectStartTime(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Beginn',
                            style: TextStyle(
                              color: AppColors.medium,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_startTime),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppColors.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Ende',
                          style: TextStyle(
                            color: AppColors.medium,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _endTime != null ? _formatTime(_endTime!) : '--:--',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Fields list
          Expanded(
            child: _fields.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.playlist_add, size: 64, color: AppColors.medium),
                        const SizedBox(height: 16),
                        const Text('Keine Programmpunkte'),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddFieldDialog(songsAsync.valueOrNull ?? []),
                          icon: const Icon(Icons.add),
                          label: const Text('Programmpunkt hinzufügen'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
                    itemCount: _fields.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _fields.removeAt(oldIndex);
                        _fields.insert(newIndex, item);
                      });
                      _calculateEnd();
                      _savePlan();
                    },
                    itemBuilder: (context, index) {
                      final field = _fields[index];
                      final calculatedTime = _calculateTimeAtIndex(index);

                      return Dismissible(
                        key: ValueKey('${field.id}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: AppColors.danger,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() => _fields.removeAt(index));
                          _calculateEnd();
                          _savePlan();
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  calculatedTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${field.time} min',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.medium,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              field.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: field.conductor != null && field.conductor!.isNotEmpty
                                ? Text(field.conductor!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _editField(index),
                                ),
                                const Icon(Icons.drag_handle),
                              ],
                            ),
                            onTap: () => _editField(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFieldDialog(songsAsync.valueOrNull ?? []),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateAttendance(List<Attendance> attendances, int direction) {
    if (_selectedAttendanceId == null) return;

    final currentIndex = attendances.indexWhere((a) => a.id == _selectedAttendanceId);
    final newIndex = currentIndex + direction;

    if (newIndex >= 0 && newIndex < attendances.length) {
      setState(() => _selectedAttendanceId = attendances[newIndex].id);
      _loadPlanFromAttendance(attendances[newIndex]);
    }
  }

  void _loadPlanFromAttendance(Attendance attendance) {
    if (attendance.plan != null) {
      try {
        final plan = attendance.plan as Map<String, dynamic>;
        final fields = (plan['fields'] as List?)
            ?.map((f) => FieldSelection.fromJson(f as Map<String, dynamic>))
            .toList();

        if (fields != null && fields.isNotEmpty) {
          setState(() => _fields = fields);
        }

        // Parse time
        final timeStr = plan['time'] as String?;
        if (timeStr != null && timeStr.isNotEmpty) {
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            setState(() {
              _startTime = TimeOfDay(
                hour: int.tryParse(parts[0]) ?? 17,
                minute: int.tryParse(parts[1]) ?? 50,
              );
            });
          }
        }
      } catch (e) {
        // Plan parsing failed, keep defaults
      }
    } else {
      // No plan, reset to defaults
      setState(() {
        _fields = [FieldSelection(id: 'default', name: 'Wort', time: '10')];
        _startTime = attendance.type == 'uebung'
            ? const TimeOfDay(hour: 17, minute: 50)
            : const TimeOfDay(hour: 10, minute: 0);
      });
    }

    _calculateEnd();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _calculateTimeAtIndex(int index) {
    int totalMinutes = _startTime.hour * 60 + _startTime.minute;

    for (int i = 0; i < index; i++) {
      totalMinutes += int.tryParse(_fields[i].time) ?? 0;
    }

    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  void _calculateEnd() {
    int totalMinutes = _startTime.hour * 60 + _startTime.minute;

    for (final field in _fields) {
      totalMinutes += int.tryParse(field.time) ?? 0;
    }

    setState(() {
      _endTime = TimeOfDay(
        hour: (totalMinutes ~/ 60) % 24,
        minute: totalMinutes % 60,
      );
    });
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (time != null) {
      setState(() => _startTime = time);
      _calculateEnd();
      _savePlan();
    }
  }

  Future<void> _showAddFieldDialog(List<Song> songs) async {
    final result = await showModalBottomSheet<FieldSelection>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddFieldSheet(songs: songs),
    );

    if (result != null) {
      setState(() => _fields.add(result));
      _calculateEnd();
      _savePlan();
    }
  }

  Future<void> _editField(int index) async {
    final field = _fields[index];
    final nameController = TextEditingController(text: field.name);
    final conductorController = TextEditingController(text: field.conductor ?? '');
    final timeController = TextEditingController(text: field.time);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feld bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conductorController,
                decoration: const InputDecoration(labelText: 'Ausführender'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Dauer (Minuten)',
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ToastHelper.showWarning(context, 'Bitte einen Namen eingeben');
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _fields[index] = FieldSelection(
          id: field.id,
          name: nameController.text.trim(),
          conductor: conductorController.text.trim(),
          time: timeController.text.trim().isNotEmpty ? timeController.text.trim() : '10',
          songId: field.songId,
        );
      });
      _calculateEnd();
      _savePlan();
    }
  }

  Future<void> _savePlan() async {
    if (_selectedAttendanceId == null) return;

    // BL-004: Add tenantId filter for security
    final tenant = ref.read(currentTenantProvider);
    if (tenant?.id == null) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('attendance')
          .update({
            'plan': {
              'time': _formatTime(_startTime),
              'end': _endTime != null ? _formatTime(_endTime!) : null,
              'fields': _fields.map((f) => f.toJson()).toList(),
            },
          })
          .eq('id', _selectedAttendanceId!)
          .eq('tenantId', tenant!.id!);
    } catch (e) {
      // Silent fail - auto-save
    }
  }

  Future<void> _exportPlan() async {
    if (_fields.isEmpty) {
      ToastHelper.showWarning(context, 'Keine Programmpunkte zum Exportieren');
      return;
    }

    final tenant = ref.read(currentTenantProvider);
    if (tenant == null) {
      ToastHelper.showError(context, 'Kein Tenant ausgewählt');
      return;
    }

    // Get the selected attendance date if available
    String dateStr = DateTime.now().toIso8601String().substring(0, 10);
    if (_selectedAttendanceId != null) {
      final attendances = ref.read(upcomingAttendancesProvider).valueOrNull ?? [];
      final selected = attendances.where((a) => a.id == _selectedAttendanceId).firstOrNull;
      if (selected != null) {
        dateStr = selected.formattedDate;
      }
    }

    try {
      final exportService = ExportService();
      await exportService.exportPlanPdf(
        context: context,
        tenantName: tenant.shortName,
        date: dateStr,
        startTime: _formatTime(_startTime),
        endTime: _endTime != null ? _formatTime(_endTime!) : null,
        fields: _fields.map((f) => f.toJson()).toList(),
      );
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Export: $e');
      }
    }
  }
}

/// Bottom sheet for adding a new field
class _AddFieldSheet extends StatefulWidget {
  final List<Song> songs;

  const _AddFieldSheet({required this.songs});

  @override
  State<_AddFieldSheet> createState() => _AddFieldSheetState();
}

class _AddFieldSheetState extends State<_AddFieldSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _conductorController = TextEditingController();
  final _timeController = TextEditingController(text: '20');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _conductorController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = widget.songs.where((song) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return song.name.toLowerCase().contains(query) ||
          (song.fullNumber.toLowerCase().contains(query));
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Werk auswählen'),
              Tab(text: 'Freitext'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Songs tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Suchen...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          return ListTile(
                            leading: song.fullNumber.isNotEmpty
                                ? CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      song.fullNumber,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.music_note),
                                  ),
                            title: Text(song.name),
                            subtitle: song.conductor != null ? Text(song.conductor!) : null,
                            onTap: () {
                              Navigator.pop(
                                context,
                                FieldSelection(
                                  id: song.id.toString(),
                                  name: song.displayName,
                                  time: '20',
                                  conductor: song.conductor,
                                  songId: song.id,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Freetext tab
                SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Programmpunkt *',
                          hintText: 'z.B. "Begrüßung", "Pause"',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _conductorController,
                        decoration: const InputDecoration(
                          labelText: 'Ausführender (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Dauer (Minuten)',
                          suffixText: 'min',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_nameController.text.trim().isEmpty) {
                              ToastHelper.showWarning(context, 'Bitte einen Namen eingeben');
                              return;
                            }
                            Navigator.pop(
                              context,
                              FieldSelection(
                                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                name: _nameController.text.trim(),
                                conductor: _conductorController.text.trim(),
                                time: _timeController.text.trim().isNotEmpty
                                    ? _timeController.text.trim()
                                    : '10',
                              ),
                            );
                          },
                          child: const Text('Hinzufügen'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
