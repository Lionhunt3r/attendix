import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/song/song.dart';

/// Bottom sheet showing options for a song (view, download, etc.)
class SongOptionsSheet extends StatelessWidget {
  const SongOptionsSheet({
    super.key,
    required this.song,
    this.playerInstrumentId,
  });

  final Song song;
  final int? playerInstrumentId;

  @override
  Widget build(BuildContext context) {
    final files = song.files ?? [];
    final hasLink = song.link != null && song.link!.isNotEmpty;

    // Filter files by instrument
    final instrumentFiles = playerInstrumentId != null
        ? files.where((f) => f.instrumentId == playerInstrumentId).toList()
        : files;

    // Recording files (instrumentId == 1)
    final recordingFiles = files.where((f) => f.instrumentId == 1).toList();

    // Lyrics files (instrumentId == 2)
    final lyricsFiles = files.where((f) => f.instrumentId == 2).toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                song.fullNumber.isEmpty ? '?' : song.fullNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              song.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: song.conductor != null
                ? Text('Dirigent: ${song.conductor}')
                : null,
          ),
          const Divider(),

          // External link
          if (hasLink)
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primary),
              title: const Text('Notenlink öffnen'),
              onTap: () async {
                final uri = Uri.parse(song.link!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ToastHelper.showError(
                        context, 'Link konnte nicht geöffnet werden');
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),

          // Instrument-specific files
          if (instrumentFiles.isNotEmpty) ...[
            if (instrumentFiles.length == 1) ...[
              ListTile(
                leading:
                    const Icon(Icons.visibility, color: AppColors.primary),
                title: const Text('Noten anzeigen'),
                subtitle: Text(instrumentFiles.first.fileName),
                onTap: () => _openFile(context, instrumentFiles.first),
              ),
            ] else ...[
              ListTile(
                leading:
                    const Icon(Icons.visibility, color: AppColors.primary),
                title: const Text('Noten anzeigen'),
                subtitle: Text('${instrumentFiles.length} Dateien verfügbar'),
                onTap: () => _showFileSelector(
                  context,
                  instrumentFiles,
                  'Noten auswählen',
                ),
              ),
            ],
          ],

          // Recording
          if (recordingFiles.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.headphones, color: AppColors.success),
              title: const Text('Aufnahme anhören'),
              subtitle: recordingFiles.length > 1
                  ? Text('${recordingFiles.length} Aufnahmen')
                  : Text(recordingFiles.first.fileName),
              onTap: () {
                if (recordingFiles.length == 1) {
                  _openFile(context, recordingFiles.first);
                } else {
                  _showFileSelector(
                      context, recordingFiles, 'Aufnahme auswählen');
                }
              },
            ),

          // Lyrics
          if (lyricsFiles.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.text_snippet, color: AppColors.info),
              title: const Text('Liedtext ansehen'),
              subtitle: lyricsFiles.length > 1
                  ? Text('${lyricsFiles.length} Dateien')
                  : Text(lyricsFiles.first.fileName),
              onTap: () {
                if (lyricsFiles.length == 1) {
                  _openFile(context, lyricsFiles.first);
                } else {
                  _showFileSelector(context, lyricsFiles, 'Liedtext auswählen');
                }
              },
            ),

          // No files available message
          if (instrumentFiles.isEmpty &&
              recordingFiles.isEmpty &&
              lyricsFiles.isEmpty &&
              !hasLink)
            const ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.medium),
              title: Text('Keine Dateien verfügbar'),
              subtitle: Text('Für dieses Stück sind keine Noten hinterlegt.'),
            ),

          const SizedBox(height: AppDimensions.paddingM),

          // Cancel button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Schließen'),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, SongFile file) async {
    final uri = Uri.parse(file.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ToastHelper.showError(context, 'Datei konnte nicht geöffnet werden');
      }
    }
    if (context.mounted) Navigator.pop(context);
  }

  void _showFileSelector(
    BuildContext context,
    List<SongFile> files,
    String title,
  ) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ...files.map((file) => ListTile(
                  leading: Icon(_getFileIcon(file.fileType)),
                  title: Text(file.fileName),
                  subtitle: file.note != null ? Text(file.note!) : null,
                  onTap: () => _openFile(context, file),
                )),
            const SizedBox(height: AppDimensions.paddingM),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('audio') || type.contains('mp3') || type.contains('wav')) {
      return Icons.audio_file;
    }
    if (type.contains('image') ||
        type.contains('png') ||
        type.contains('jpg') ||
        type.contains('jpeg')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }
}

/// Shows the song options sheet as a bottom sheet
Future<void> showSongOptionsSheet(
  BuildContext context, {
  required Song song,
  int? playerInstrumentId,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (context) => SongOptionsSheet(
      song: song,
      playerInstrumentId: playerInstrumentId,
    ),
  );
}
