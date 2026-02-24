import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/conductor_providers.dart';
import '../../../../core/providers/song_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/person/person.dart';
import '../../../../data/models/song/song.dart';

part 'songs_selection_sheet.freezed.dart';
part 'songs_selection_sheet.g.dart';

/// Entry representing a song-conductor pair to be saved with attendance
@freezed
class SongHistoryEntry with _$SongHistoryEntry {
  const factory SongHistoryEntry({
    required int songId,
    required String songName,
    int? conductorId,
    String? conductorName,
    String? otherConductor,
  }) = _SongHistoryEntry;

  factory SongHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$SongHistoryEntryFromJson(json);
}

/// Extension for SongHistoryEntry
extension SongHistoryEntryExtension on SongHistoryEntry {
  /// Get display name for conductor
  String get displayConductor {
    if (otherConductor != null && otherConductor!.isNotEmpty) {
      return otherConductor!;
    }
    return conductorName ?? 'Unbekannt';
  }
}

/// Bottom sheet for selecting songs to add to attendance
class SongsSelectionSheet extends ConsumerStatefulWidget {
  final List<SongHistoryEntry> existingEntries;
  final ValueChanged<List<SongHistoryEntry>> onEntriesChanged;

  const SongsSelectionSheet({
    super.key,
    required this.existingEntries,
    required this.onEntriesChanged,
  });

  /// Show the bottom sheet and return updated entries
  static Future<List<SongHistoryEntry>?> show(
    BuildContext context, {
    required List<SongHistoryEntry> existingEntries,
  }) async {
    List<SongHistoryEntry>? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SongsSelectionSheet(
        existingEntries: existingEntries,
        onEntriesChanged: (entries) {
          result = entries;
        },
      ),
    );

    return result;
  }

  @override
  ConsumerState<SongsSelectionSheet> createState() => _SongsSelectionSheetState();
}

class _SongsSelectionSheetState extends ConsumerState<SongsSelectionSheet> {
  final Set<int> _selectedSongIds = {};
  int? _selectedConductorId;
  String? _otherConductorName;
  bool _useOtherConductor = false;

  @override
  void initState() {
    super.initState();
    // Pre-select first conductor if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conductors = ref.read(activeConductorsProvider).valueOrNull;
      if (conductors != null && conductors.isNotEmpty) {
        setState(() {
          _selectedConductorId = conductors.first.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);
    final conductorsAsync = ref.watch(activeConductorsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Werk(e) hinzufügen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song selection
                  const Text(
                    'Werk(e)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  songsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Fehler: $error'),
                    data: (songs) => _buildSongsList(songs),
                  ),

                  const SizedBox(height: AppDimensions.paddingL),

                  // Conductor selection
                  const Text(
                    'Dirigent',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  conductorsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Text('Fehler: $error'),
                    data: (conductors) => _buildConductorSelection(conductors),
                  ),

                  // Other conductor text field
                  if (_useOtherConductor) ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Name des Dirigenten',
                        border: OutlineInputBorder(),
                        hintText: 'Name eingeben...',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _otherConductorName = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _canAdd() ? _addSongs : null,
                  child: const Text('Hinzufügen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList(List<Song> songs) {
    if (songs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Keine Werke vorhanden'),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isSelected = _selectedSongIds.contains(song.id);

          return CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true && song.id != null) {
                  _selectedSongIds.add(song.id!);
                } else if (song.id != null) {
                  _selectedSongIds.remove(song.id);
                }
              });
            },
            title: Text(song.displayName),
            subtitle: song.conductor != null
                ? Text(song.conductor!, style: const TextStyle(fontSize: 12))
                : null,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
    );
  }

  Widget _buildConductorSelection(List<Person> conductors) {
    return Column(
      children: [
        // Conductor radio buttons
        ...conductors.map((conductor) {
          return RadioListTile<int?>(
            value: conductor.id,
            groupValue: _useOtherConductor ? null : _selectedConductorId,
            onChanged: (value) {
              setState(() {
                _selectedConductorId = value;
                _useOtherConductor = false;
                _otherConductorName = null;
              });
            },
            title: Text(conductor.fullName),
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }),
        // Other conductor option
        RadioListTile<bool>(
          value: true,
          groupValue: _useOtherConductor,
          onChanged: (value) {
            setState(() {
              _useOtherConductor = value ?? false;
              _selectedConductorId = null;
            });
          },
          title: const Text('Anderer Dirigent'),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  bool _canAdd() {
    if (_selectedSongIds.isEmpty) return false;
    if (_useOtherConductor) {
      return _otherConductorName != null && _otherConductorName!.isNotEmpty;
    }
    return _selectedConductorId != null;
  }

  void _addSongs() {
    final songsAsync = ref.read(songsProvider);
    final conductorsAsync = ref.read(activeConductorsProvider);

    final songs = songsAsync.valueOrNull ?? [];
    final conductors = conductorsAsync.valueOrNull ?? [];

    // Create entries for each selected song
    final newEntries = <SongHistoryEntry>[];
    for (final songId in _selectedSongIds) {
      final song = songs.firstWhere(
        (s) => s.id == songId,
        orElse: () => const Song(name: 'Unbekannt'),
      );

      String? conductorName;
      if (!_useOtherConductor && _selectedConductorId != null) {
        final conductor = conductors.firstWhere(
          (c) => c.id == _selectedConductorId,
          orElse: () => const Person(),
        );
        conductorName = conductor.fullName;
      }

      newEntries.add(SongHistoryEntry(
        songId: songId,
        songName: song.displayName,
        conductorId: _useOtherConductor ? null : _selectedConductorId,
        conductorName: conductorName,
        otherConductor: _useOtherConductor ? _otherConductorName : null,
      ));
    }

    // Add to existing entries
    final allEntries = [...widget.existingEntries, ...newEntries];
    widget.onEntriesChanged(allEntries);

    Navigator.of(context).pop();
  }
}

/// Widget to display selected songs in a list
class SelectedSongsList extends StatelessWidget {
  final List<SongHistoryEntry> entries;
  final ValueChanged<List<SongHistoryEntry>>? onEntriesChanged;
  final bool readOnly;

  const SelectedSongsList({
    super.key,
    required this.entries,
    this.onEntriesChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Keine Werke ausgewählt',
          style: TextStyle(color: AppColors.medium),
        ),
      );
    }

    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final songEntry = entry.value;

        return ListTile(
          title: Text(songEntry.songName),
          subtitle: Text(songEntry.displayConductor),
          trailing: readOnly
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    final newEntries = List<SongHistoryEntry>.from(entries);
                    newEntries.removeAt(index);
                    onEntriesChanged?.call(newEntries);
                  },
                ),
          dense: true,
        );
      }).toList(),
    );
  }
}
