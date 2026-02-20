import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/song/song.dart';
import '../../../../core/providers/tenant_providers.dart';

/// Song history entry
class HistoryEntry {
  final int? id;
  final int songId;
  final String? songName;
  final String? songNumber;
  final int? personId;
  final String? conductorName;
  final String? otherConductor;
  final String date;
  final int? attendanceId;
  final int count;

  HistoryEntry({
    this.id,
    required this.songId,
    this.songName,
    this.songNumber,
    this.personId,
    this.conductorName,
    this.otherConductor,
    required this.date,
    this.attendanceId,
    this.count = 0,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as int?,
        songId: json['song_id'] as int,
        songName: json['name'] as String?,
        songNumber: json['number']?.toString(),
        personId: json['person_id'] as int?,
        conductorName: json['conductorName'] as String?,
        otherConductor: json['otherConductor'] as String?,
        date: json['date'] as String? ?? DateTime.now().toIso8601String(),
        attendanceId: json['attendance_id'] as int?,
        count: json['count'] as int? ?? 0,
      );

  String get displayConductor => conductorName ?? otherConductor ?? 'Unbekannt';

  String get formattedDate {
    final dateObj = DateTime.tryParse(date);
    if (dateObj == null) return date;
    return '${dateObj.day.toString().padLeft(2, '0')}.${dateObj.month.toString().padLeft(2, '0')}.${dateObj.year}';
  }
}

/// Provider for song history
final songHistoryProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('song_history')
      .select('*, song:songs(name, number)')
      .eq('tenant_id', tenant.id!)
      .order('date', ascending: false)
      .limit(200);

  return (response as List).map((e) {
    final songData = e['song'] as Map<String, dynamic>?;
    return HistoryEntry(
      id: e['id'] as int?,
      songId: e['song_id'] as int,
      songName: songData?['name'] as String?,
      songNumber: songData?['number']?.toString(),
      personId: e['person_id'] as int?,
      conductorName: e['conductorName'] as String?,
      otherConductor: e['otherConductor'] as String?,
      date: e['date'] as String? ?? DateTime.now().toIso8601String(),
      attendanceId: e['attendance_id'] as int?,
      count: e['count'] as int? ?? 1,
    );
  }).toList();
});

/// Provider for conductors (persons who can conduct)
final conductorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);

  if (tenant == null) return [];

  final response = await supabase
      .from('persons')
      .select('id, firstName, lastName, left')
      .eq('tenant_id', tenant.id!)
      .eq('conductor', true);

  return (response as List).cast<Map<String, dynamic>>();
});

/// History Page - Song performance history
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(songHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aufführungshistorie'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // History list
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                    const SizedBox(height: 16),
                    Text('Fehler: $e'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(songHistoryProvider),
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
              data: (history) {
                final filtered = _filterHistory(history);
                final grouped = _groupByDate(filtered);

                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 80, color: AppColors.medium),
                        const SizedBox(height: 16),
                        Text(
                          'Keine Aufführungen',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Füge die erste Aufführung hinzu',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.medium,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: AppColors.medium),
                        const SizedBox(height: 16),
                        Text('Keine Ergebnisse für "$_searchQuery"'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(songHistoryProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final group = grouped[index];
                      return _HistoryGroup(
                        date: group.date,
                        entries: group.entries,
                        onDelete: (entry) => _deleteEntry(entry),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<HistoryEntry> _filterHistory(List<HistoryEntry> history) {
    if (_searchQuery.isEmpty) return history;

    final query = _searchQuery.toLowerCase();
    return history.where((entry) {
      return (entry.songName?.toLowerCase().contains(query) ?? false) ||
          (entry.songNumber?.toLowerCase().contains(query) ?? false) ||
          entry.displayConductor.toLowerCase().contains(query);
    }).toList();
  }

  List<_GroupedHistory> _groupByDate(List<HistoryEntry> history) {
    final Map<String, List<HistoryEntry>> grouped = {};

    for (final entry in history) {
      final date = entry.formattedDate;
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(entry);
    }

    return grouped.entries
        .map((e) => _GroupedHistory(date: e.key, entries: e.value))
        .toList();
  }

  Future<void> _showAddDialog() async {
    final songsAsync = ref.read(planSongsProviderHistory);
    final conductorsAsync = ref.read(conductorsProvider);

    final songs = songsAsync.valueOrNull ?? [];
    final conductors = conductorsAsync.valueOrNull ?? [];

    if (songs.isEmpty) {
      ToastHelper.showWarning(context, 'Keine Lieder vorhanden');
      return;
    }

    int? selectedSongId;
    int? selectedConductorId;
    String? otherConductor;
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Aufführung hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Song selector
                DropdownButtonFormField<int>(
                  value: selectedSongId,
                  decoration: const InputDecoration(labelText: 'Werk *'),
                  items: songs.map((song) {
                    return DropdownMenuItem(
                      value: song.id,
                      child: Text(
                        song.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedSongId = v),
                ),
                const SizedBox(height: 16),

                // Conductor selector
                DropdownButtonFormField<int>(
                  value: selectedConductorId,
                  decoration: const InputDecoration(labelText: 'Dirigent'),
                  items: [
                    ...conductors
                        .where((c) => c['left'] != true)
                        .map((c) => DropdownMenuItem(
                              value: c['id'] as int,
                              child: Text('${c['firstName']} ${c['lastName']}'),
                            )),
                    const DropdownMenuItem(
                      value: -1,
                      child: Text('Andere...'),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v == -1) {
                      final controller = TextEditingController();
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Dirigent eingeben'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(labelText: 'Name'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Abbrechen'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, controller.text),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        setDialogState(() {
                          selectedConductorId = null;
                          otherConductor = result;
                        });
                      }
                    } else {
                      setDialogState(() {
                        selectedConductorId = v;
                        otherConductor = null;
                      });
                    }
                  },
                ),
                if (otherConductor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Dirigent: $otherConductor'),
                  ),
                const SizedBox(height: 16),

                // Date selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Datum'),
                  subtitle: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
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
                if (selectedSongId == null) {
                  ToastHelper.showWarning(context, 'Bitte ein Werk auswählen');
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedSongId != null) {
      await _addEntry(
        songId: selectedSongId!,
        conductorId: selectedConductorId,
        otherConductor: otherConductor,
        date: selectedDate,
      );
    }
  }

  Future<void> _addEntry({
    required int songId,
    int? conductorId,
    String? otherConductor,
    required DateTime date,
  }) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);

      await supabase.from('song_history').insert({
        'tenant_id': tenant?.id,
        'song_id': songId,
        'person_id': conductorId,
        'otherConductor': otherConductor,
        'date': date.toIso8601String().substring(0, 10),
      });

      ref.invalidate(songHistoryProvider);
      if (mounted) {
        ToastHelper.showSuccess(context, 'Aufführung hinzugefügt');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  Future<void> _deleteEntry(HistoryEntry entry) async {
    if (entry.id == null) return;

    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Eintrag löschen',
      message: 'Möchtest du diesen Eintrag wirklich löschen?',
      confirmText: 'Löschen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('song_history').delete().eq('id', entry.id!);

      ref.invalidate(songHistoryProvider);
      if (mounted) {
        ToastHelper.showSuccess(context, 'Eintrag gelöscht');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

/// Provider for songs (for history page)
final planSongsProviderHistory = FutureProvider<List<Song>>((ref) async {
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

/// Grouped history helper
class _GroupedHistory {
  final String date;
  final List<HistoryEntry> entries;

  _GroupedHistory({required this.date, required this.entries});
}

/// History group widget
class _HistoryGroup extends StatelessWidget {
  final String date;
  final List<HistoryEntry> entries;
  final Function(HistoryEntry) onDelete;

  const _HistoryGroup({
    required this.date,
    required this.entries,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            date,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
        ),
        ...entries.map((entry) => Dismissible(
              key: ValueKey(entry.id ?? '${entry.songId}_${entry.date}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: AppColors.danger,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                onDelete(entry);
                return false; // Don't auto-dismiss, we handle it in onDelete
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: entry.songNumber != null
                      ? CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            entry.songNumber!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.music_note),
                        ),
                  title: Text(
                    entry.songName ?? 'Unbekanntes Werk',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(entry.displayConductor),
                  trailing: entry.count > 1
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.count}x',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            )),
      ],
    );
  }
}
