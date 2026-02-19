import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/services/song_file_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/song/song.dart';

/// Provider for single song by ID
final songByIdProvider = FutureProvider.family<Song?, String>((ref, id) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('songs')
      .select('*, files:song_files(*)')
      .eq('id', id)
      .maybeSingle();

  if (response == null) return null;
  return Song.fromJson(response);
});

/// Song Detail Page
class SongDetailPage extends ConsumerStatefulWidget {
  final String songId;

  const SongDetailPage({super.key, required this.songId});

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(songByIdProvider(widget.songId));

    return songAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Lied')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Lied')),
        body: Center(child: Text('Fehler: $error')),
      ),
      data: (song) {
        if (song == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lied')),
            body: const Center(child: Text('Lied nicht gefunden')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(song.displayName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, song),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteSong(context, song),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            children: [
              // Song header card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (song.fullNumber.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            song.fullNumber,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        song.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (song.conductor != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 16, color: AppColors.medium),
                            const SizedBox(width: 4),
                            Text(
                              song.conductor!,
                              style: TextStyle(color: AppColors.medium),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (song.withChoir)
                            Chip(
                              label: const Text('Mit Chor'),
                              avatar: const Icon(Icons.groups, size: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (song.withSolo)
                            Chip(
                              label: const Text('Mit Solo'),
                              avatar: const Icon(Icons.mic, size: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (song.difficultyLabel != null)
                            Chip(
                              label: Text(song.difficultyLabel!),
                              avatar: const Icon(Icons.speed, size: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (song.category != null)
                            Chip(
                              label: Text(song.category!),
                              avatar: const Icon(Icons.category, size: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Instruments section
              if (song.instrumentIds != null && song.instrumentIds!.isNotEmpty)
                _InstrumentsSection(instrumentIds: song.instrumentIds!),

              // Files section
              _FilesSection(
                files: song.files ?? [],
                songId: song.id!,
                onFileAdded: () => ref.invalidate(songByIdProvider(widget.songId)),
              ),

              // Last sung
              if (song.lastSung != null) ...[
                const SizedBox(height: AppDimensions.paddingM),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Zuletzt gespielt'),
                    subtitle: Text(song.lastSung!),
                  ),
                ),
              ],

              // External link
              if (song.link != null && song.link!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.paddingM),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Externer Link'),
                    subtitle: Text(
                      song.link!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openLink(song.link!),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showEditDialog(BuildContext context, Song song) async {
    final nameController = TextEditingController(text: song.name);
    final numberController = TextEditingController(text: song.number?.toString() ?? '');
    final prefixController = TextEditingController(text: song.prefix ?? '');
    final conductorController = TextEditingController(text: song.conductor ?? '');
    final linkController = TextEditingController(text: song.link ?? '');
    bool withChoir = song.withChoir;
    bool withSolo = song.withSolo;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lied bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: prefixController,
                        decoration: const InputDecoration(labelText: 'Präfix'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: numberController,
                        decoration: const InputDecoration(labelText: 'Nummer'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: conductorController,
                  decoration: const InputDecoration(labelText: 'Dirigent'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(labelText: 'Link'),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Mit Chor'),
                  value: withChoir,
                  onChanged: (v) => setDialogState(() => withChoir = v ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Mit Solo'),
                  value: withSolo,
                  onChanged: (v) => setDialogState(() => withSolo = v ?? false),
                  contentPadding: EdgeInsets.zero,
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
              onPressed: () async {
                final supabase = ref.read(supabaseClientProvider);
                try {
                  await supabase.from('songs').update({
                    'name': nameController.text.trim(),
                    'number': int.tryParse(numberController.text.trim()),
                    'prefix': prefixController.text.trim(),
                    'conductor': conductorController.text.trim(),
                    'link': linkController.text.trim(),
                    'withChoir': withChoir,
                    'withSolo': withSolo,
                  }).eq('id', song.id!);
                  Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) {
                    ToastHelper.showError(context, 'Fehler: $e');
                  }
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      ref.invalidate(songByIdProvider(widget.songId));
      if (mounted) {
        ToastHelper.showSuccess(context, 'Änderungen gespeichert');
      }
    }
  }

  Future<void> _deleteSong(BuildContext context, Song song) async {
    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Lied löschen',
      message: 'Möchtest du "${song.name}" wirklich löschen?',
      confirmText: 'Löschen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    final supabase = ref.read(supabaseClientProvider);

    try {
      await supabase.from('songs').delete().eq('id', song.id!);

      if (mounted) {
        ToastHelper.showSuccess(context, 'Lied gelöscht');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

class _InstrumentsSection extends ConsumerWidget {
  final List<int> instrumentIds;

  const _InstrumentsSection({required this.instrumentIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return groupsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (groups) {
        final matchedGroups = groups
            .where((g) => instrumentIds.contains(g.id))
            .toList();

        if (matchedGroups.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Instrumente/Gruppen',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.medium,
                ),
              ),
            ),
            Card(
              child: Column(
                children: matchedGroups
                    .map((g) => ListTile(
                          leading: const Icon(Icons.music_note),
                          title: Text(g.name),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
          ],
        );
      },
    );
  }
}

class _FilesSection extends ConsumerStatefulWidget {
  final List<SongFile> files;
  final int songId;
  final VoidCallback onFileAdded;

  const _FilesSection({
    required this.files,
    required this.songId,
    required this.onFileAdded,
  });

  @override
  ConsumerState<_FilesSection> createState() => _FilesSectionState();
}

class _FilesSectionState extends ConsumerState<_FilesSection> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dateien (${widget.files.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.medium,
                ),
              ),
              _isUploading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton.icon(
                      onPressed: () => _addFile(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Hinzufügen'),
                    ),
            ],
          ),
        ),
        if (widget.files.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.medium),
              title: const Text('Keine Dateien'),
              subtitle: const Text('Füge Notenblätter oder andere Dateien hinzu'),
            ),
          )
        else
          Card(
            child: Column(
              children: widget.files
                  .map((file) => _FileTile(
                        file: file,
                        songId: widget.songId,
                        onDeleted: widget.onFileAdded,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _addFile(BuildContext context) async {
    final songFileService = ref.read(songFileServiceProvider);

    // Show dialog to get optional note
    final noteController = TextEditingController();
    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Datei hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wähle eine PDF, PNG oder JPG Datei aus.'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Notiz (optional)',
                hintText: 'z.B. "Partitur" oder "Klarinette"',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Datei wählen'),
          ),
        ],
      ),
    );

    if (shouldUpload != true) return;

    // Pick file
    final file = await songFileService.pickFile();
    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      await songFileService.uploadFile(
        songId: widget.songId,
        file: file,
        note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
      );

      if (mounted) {
        ToastHelper.showSuccess(context, 'Datei hochgeladen');
        widget.onFileAdded();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Hochladen: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

class _FileTile extends ConsumerWidget {
  final SongFile file;
  final int songId;
  final VoidCallback onDeleted;

  const _FileTile({required this.file, required this.songId, required this.onDeleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        _getFileIcon(file.fileType),
        color: AppColors.primary,
      ),
      title: Text(file.fileName),
      subtitle: file.note != null ? Text(file.note!) : null,
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'open') {
            await _openFile(context);
          } else if (value == 'delete') {
            await _deleteFile(context, ref);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'open',
            child: Row(
              children: [
                Icon(Icons.open_in_new),
                SizedBox(width: 8),
                Text('Öffnen'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: AppColors.danger),
                SizedBox(width: 8),
                Text('Löschen', style: TextStyle(color: AppColors.danger)),
              ],
            ),
          ),
        ],
      ),
      onTap: () => _openFile(context),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _openFile(BuildContext context) async {
    if (file.url.isEmpty) return;

    final uri = Uri.parse(file.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ToastHelper.showError(context, 'Konnte Datei nicht öffnen');
      }
    }
  }

  Future<void> _deleteFile(BuildContext context, WidgetRef ref) async {
    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Datei löschen',
      message: 'Möchtest du "${file.fileName}" wirklich löschen?',
      confirmText: 'Löschen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    try {
      final songFileService = ref.read(songFileServiceProvider);
      await songFileService.deleteFile(
        songId: songId,
        storageName: file.storageName ?? '',
      );

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Datei gelöscht');
        onDeleted();
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler beim Löschen: $e');
      }
    }
  }
}
