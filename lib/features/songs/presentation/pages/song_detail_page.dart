import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/providers/song_providers.dart';
import '../../../../core/services/song_file_service.dart';
import '../../../../core/services/telegram_service.dart';
import '../../../../core/services/zip_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/instrument_matcher.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/instrument/instrument.dart';
import '../../../../data/models/song/song.dart';
import '../../../../shared/widgets/sheets/image_viewer_sheet.dart';
import '../widgets/file_upload_sheet.dart';
import '../widgets/pdf_viewer_sheet.dart';
import '../widgets/smart_print_dialog.dart';

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
    final songId = int.tryParse(widget.songId);
    if (songId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lied')),
        body: const Center(child: Text('Ungültige Song-ID')),
      );
    }

    final songAsync = ref.watch(songByIdProvider(songId));

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
                onPressed: () => context.push('/settings/songs/${widget.songId}/edit'),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            song.fullNumber,
                            style: const TextStyle(
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
                            const Icon(Icons.person,
                                size: 16, color: AppColors.medium),
                            const SizedBox(width: 4),
                            Text(
                              song.conductor!,
                              style: const TextStyle(color: AppColors.medium),
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
                            const Chip(
                              label: Text('Mit Chor'),
                              avatar: Icon(Icons.groups, size: 16),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (song.withSolo)
                            const Chip(
                              label: Text('Mit Solo'),
                              avatar: Icon(Icons.mic, size: 16),
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
                songName: song.displayName,
                onFileAdded: () => ref.invalidate(songByIdProvider(songId)),
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

  Future<void> _deleteSong(BuildContext context, Song song) async {
    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Lied löschen',
      message: 'Möchtest du "${song.name}" wirklich löschen?',
      confirmText: 'Löschen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    try {
      final success =
          await ref.read(songNotifierProvider.notifier).deleteSong(song.id!);

      if (mounted && success) {
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
        final matchedGroups =
            groups.where((g) => instrumentIds.contains(g.id)).toList();

        if (matchedGroups.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
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
  final String songName;
  final VoidCallback onFileAdded;

  const _FilesSection({
    required this.files,
    required this.songId,
    required this.songName,
    required this.onFileAdded,
  });

  @override
  ConsumerState<_FilesSection> createState() => _FilesSectionState();
}

class _FilesSectionState extends ConsumerState<_FilesSection> {
  bool _isDownloadingAll = false;
  bool _isDeletingAll = false;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildContent(context, []),
      data: (groups) => _buildContent(context, groups),
    );
  }

  Widget _buildContent(BuildContext context, List<Group> groups) {
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.medium,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Popover menu for bulk actions
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    tooltip: 'Mehr Aktionen',
                    onSelected: (value) => _handleBulkAction(context, value),
                    itemBuilder: (context) => [
                      if (_hasPdfFiles())
                        const PopupMenuItem(
                          value: 'print_group',
                          child: Row(
                            children: [
                              Icon(Icons.print),
                              SizedBox(width: 8),
                              Text('Gruppen-PDFs drucken'),
                            ],
                          ),
                        ),
                      if (widget.files.length > 1)
                        const PopupMenuItem(
                          value: 'download_all',
                          child: Row(
                            children: [
                              Icon(Icons.download),
                              SizedBox(width: 8),
                              Text('Alle herunterladen (ZIP)'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'upload',
                        child: Row(
                          children: [
                            Icon(Icons.cloud_upload),
                            SizedBox(width: 8),
                            Text('Dateien hochladen'),
                          ],
                        ),
                      ),
                      if (widget.files.isNotEmpty) ...[
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep, color: AppColors.danger),
                              SizedBox(width: 8),
                              Text('Alle löschen',
                                  style: TextStyle(color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Quick upload button
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _showUploadSheet(context, groups),
                    tooltip: 'Dateien hinzufügen',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isDeletingAll || _isDownloadingAll)
          const LinearProgressIndicator(),
        if (widget.files.isEmpty)
          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.insert_drive_file_outlined, color: AppColors.medium),
              title: Text('Keine Dateien'),
              subtitle: Text('Füge Notenblätter oder andere Dateien hinzu'),
            ),
          )
        else
          Card(
            child: Column(
              children: widget.files
                  .map((file) => _FileTile(
                        file: file,
                        songId: widget.songId,
                        songName: widget.songName,
                        groups: groups,
                        onDeleted: widget.onFileAdded,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  bool _hasPdfFiles() {
    return widget.files.any((f) => f.fileType.toLowerCase() == 'pdf');
  }

  Future<void> _handleBulkAction(BuildContext context, String action) async {
    switch (action) {
      case 'print_group':
        await _printGroupPdfs(context);
        break;
      case 'download_all':
        await _downloadAllFiles(context);
        break;
      case 'upload':
        final groupsAsync = ref.read(groupsProvider);
        final groups = groupsAsync.valueOrNull ?? [];
        await _showUploadSheet(context, groups);
        break;
      case 'delete_all':
        await _deleteAllFiles(context);
        break;
    }
  }

  Future<void> _printGroupPdfs(BuildContext context) async {
    final pdfFiles = widget.files.where((f) => f.fileType.toLowerCase() == 'pdf').toList();
    if (pdfFiles.isEmpty) return;

    // Show smart print dialog for first PDF (user can select instruments)
    await showSmartPrintDialog(
      context,
      ref: ref,
      url: pdfFiles.first.url,
      fileName: pdfFiles.first.fileName,
      instrumentId: pdfFiles.first.instrumentId,
    );
  }

  Future<void> _downloadAllFiles(BuildContext context) async {
    setState(() => _isDownloadingAll = true);

    try {
      final zipService = ref.read(zipServiceProvider);
      await zipService.downloadSongFilesAsZip(
        files: widget.files,
        songName: widget.songName,
      );

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'ZIP-Download gestartet');
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler beim Erstellen der ZIP: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingAll = false);
      }
    }
  }

  Future<void> _deleteAllFiles(BuildContext context) async {
    final confirmed = await DialogHelper.showConfirmation(
      context,
      title: 'Alle Dateien löschen',
      message:
          'Möchtest du wirklich alle ${widget.files.length} Dateien löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
      confirmText: 'Alle löschen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    setState(() => _isDeletingAll = true);

    try {
      final songFileService = ref.read(songFileServiceProvider);
      await songFileService.deleteAllFiles(songId: widget.songId);

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Alle Dateien gelöscht');
        widget.onFileAdded();
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler beim Löschen: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingAll = false);
      }
    }
  }

  Future<void> _showUploadSheet(BuildContext context, List<Group> groups) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FileUploadSheet(
        songId: widget.songId,
        groups: groups,
      ),
    );

    if (result == true) {
      widget.onFileAdded();
    }
  }
}

class _FileTile extends ConsumerWidget {
  final SongFile file;
  final int songId;
  final String songName;
  final List<Group> groups;
  final VoidCallback onDeleted;

  const _FileTile({
    required this.file,
    required this.songId,
    required this.songName,
    required this.groups,
    required this.onDeleted,
  });

  bool get _isPdf => file.fileType.toLowerCase() == 'pdf';
  bool get _isImage => ['png', 'jpg', 'jpeg'].contains(file.fileType.toLowerCase());
  bool get _canDownload => !kIsWeb && !(Platform.isIOS);

  String _getInstrumentLabel() {
    final instruments = groups
        .map((g) => InstrumentInfo(id: g.id!, name: g.name))
        .toList();

    return InstrumentMatcher.getFileLabel(
      instrumentId: file.instrumentId,
      note: file.note,
      instruments: instruments,
    );
  }

  Color _getBadgeColor() {
    if (file.instrumentId == InstrumentMatcher.recordingId) {
      return AppColors.primary;
    }
    if (file.instrumentId == InstrumentMatcher.lyricsId) {
      return AppColors.success;
    }
    if (file.instrumentId != null) {
      return AppColors.secondary;
    }
    return AppColors.medium;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _getInstrumentLabel();
    final badgeColor = _getBadgeColor();

    return ListTile(
      leading: Icon(
        _getFileIcon(file.fileType),
        color: AppColors.primary,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.fileName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeColor.withAlpha(80)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(context, ref, value),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility),
                SizedBox(width: 8),
                Text('Ansehen'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'open_external',
            child: Row(
              children: [
                Icon(Icons.open_in_new),
                SizedBox(width: 8),
                Text('Extern öffnen'),
              ],
            ),
          ),
          if (_isPdf)
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print),
                  SizedBox(width: 8),
                  Text('Drucken'),
                ],
              ),
            ),
          if (_canDownload)
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Herunterladen'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'telegram',
            child: Row(
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text('Per Telegram senden'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'change_category',
            child: Row(
              children: [
                Icon(Icons.category),
                SizedBox(width: 8),
                Text('Kategorie ändern'),
              ],
            ),
          ),
          const PopupMenuDivider(),
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
      onTap: () => _openInAppViewer(context),
    );
  }

  Future<void> _handleMenuAction(
      BuildContext context, WidgetRef ref, String value) async {
    switch (value) {
      case 'view':
        await _openInAppViewer(context);
        break;
      case 'open_external':
        await _openExternally(context);
        break;
      case 'print':
        await _showPrintDialog(context, ref);
        break;
      case 'download':
        await _downloadFile(context, ref);
        break;
      case 'telegram':
        await _sendViaTelegram(context, ref);
        break;
      case 'change_category':
        await _changeCategory(context, ref);
        break;
      case 'delete':
        await _deleteFile(context, ref);
        break;
    }
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

  Future<void> _openInAppViewer(BuildContext context) async {
    if (file.url.isEmpty) return;

    if (_isPdf) {
      await showPdfViewerSheet(
        context,
        url: file.url,
        fileName: file.fileName,
      );
    } else if (_isImage) {
      await showImageViewerSheet(
        context,
        url: file.url,
        fileName: file.fileName,
      );
    } else {
      // For other file types, open externally
      await _openExternally(context);
    }
  }

  Future<void> _openExternally(BuildContext context) async {
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

  Future<void> _showPrintDialog(BuildContext context, WidgetRef ref) async {
    if (!_isPdf) {
      ToastHelper.showError(context, 'Nur PDF-Dateien können gedruckt werden');
      return;
    }

    await showSmartPrintDialog(
      context,
      ref: ref,
      url: file.url,
      fileName: file.fileName,
      instrumentId: file.instrumentId,
    );
  }

  Future<void> _sendViaTelegram(BuildContext context, WidgetRef ref) async {
    final telegramService = ref.read(telegramServiceProvider);
    final notificationConfig = await ref.read(notificationConfigProvider.future);

    if (notificationConfig == null || !notificationConfig.isConnected) {
      if (context.mounted) {
        ToastHelper.showError(
          context,
          'Telegram nicht verbunden. Bitte zuerst in den Einstellungen verbinden.',
        );
      }
      return;
    }

    try {
      await telegramService.sendDocumentPerTelegram(
        url: file.url,
        chatId: notificationConfig.telegramChatId!,
      );

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Datei per Telegram gesendet');
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler beim Senden: $e');
      }
    }
  }

  Future<void> _downloadFile(BuildContext context, WidgetRef ref) async {
    try {
      final songFileService = ref.read(songFileServiceProvider);
      final bytes = await songFileService.downloadFileBytes(file.url);

      if (bytes == null) {
        if (context.mounted) {
          ToastHelper.showError(context, 'Datei konnte nicht heruntergeladen werden');
        }
        return;
      }

      // Save to temp directory and share
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.fileName}');
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: file.fileName,
      );

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Datei heruntergeladen');
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler beim Herunterladen: $e');
      }
    }
  }

  Future<void> _changeCategory(BuildContext context, WidgetRef ref) async {
    // Build category options
    final categories = <_CategoryOption>[
      _CategoryOption(
        id: InstrumentMatcher.recordingId,
        name: 'Aufnahme',
        icon: Icons.audiotrack,
      ),
      _CategoryOption(
        id: InstrumentMatcher.lyricsId,
        name: 'Liedtext',
        icon: Icons.text_snippet,
      ),
      ...groups.map((g) => _CategoryOption(
            id: g.id!,
            name: g.name,
            icon: Icons.music_note,
          )),
      _CategoryOption(
        id: null,
        name: 'Sonstige',
        icon: Icons.more_horiz,
      ),
    ];

    // Show selection dialog
    final selectedId = await showDialog<int?>(
      context: context,
      builder: (context) => _CategorySelectionDialog(
        categories: categories,
        currentId: file.instrumentId,
      ),
    );

    // User cancelled
    if (selectedId == -1) return;

    try {
      final songFileService = ref.read(songFileServiceProvider);
      await songFileService.updateFileCategory(
        songId: songId,
        storageName: file.storageName ?? '',
        instrumentId: selectedId,
        note: null, // Clear note when changing category
      );

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Kategorie geändert');
        onDeleted(); // Refresh the list
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler beim Ändern: $e');
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

/// Category option for selection dialog
class _CategoryOption {
  final int? id;
  final String name;
  final IconData icon;

  const _CategoryOption({
    required this.id,
    required this.name,
    required this.icon,
  });
}

/// Dialog for selecting file category
class _CategorySelectionDialog extends StatefulWidget {
  final List<_CategoryOption> categories;
  final int? currentId;

  const _CategorySelectionDialog({
    required this.categories,
    required this.currentId,
  });

  @override
  State<_CategorySelectionDialog> createState() => _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<_CategorySelectionDialog> {
  late int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kategorie wählen'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.categories.length,
          itemBuilder: (context, index) {
            final category = widget.categories[index];
            final isSelected = category.id == _selectedId;

            return RadioListTile<int?>(
              value: category.id,
              groupValue: _selectedId,
              onChanged: (value) {
                setState(() => _selectedId = value);
              },
              title: Row(
                children: [
                  Icon(
                    category.icon,
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.medium,
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
              activeColor: AppColors.primary,
              dense: true,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, -1),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedId),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
