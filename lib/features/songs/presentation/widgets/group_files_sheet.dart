import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/song_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/instrument/instrument.dart';
import '../../../../data/models/song/song.dart';
import 'pdf_viewer_sheet.dart';

/// Bottom sheet showing songs grouped by instrument/group
/// Allows musicians to quickly find their parts
class GroupFilesSheet extends ConsumerStatefulWidget {
  const GroupFilesSheet({super.key});

  @override
  ConsumerState<GroupFilesSheet> createState() => _GroupFilesSheetState();
}

class _GroupFilesSheetState extends ConsumerState<GroupFilesSheet> {
  Group? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final groupsWithFiles = ref.watch(groupsWithFilesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.borderRadiusL),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.medium.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Row(
                  children: [
                    if (_selectedGroup != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setState(() => _selectedGroup = null),
                      )
                    else
                      const Icon(Icons.folder_open, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedGroup?.name ?? 'Gruppenverzeichnis',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (_selectedGroup == null)
                            Text(
                              'Noten nach Instrument',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.medium,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: _selectedGroup == null
                    ? _buildGroupList(context, groupsWithFiles, scrollController)
                    : _buildFilesList(context, _selectedGroup!, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupList(
    BuildContext context,
    List<Group> groups,
    ScrollController scrollController,
  ) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_off,
              size: 64,
              color: AppColors.medium,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'Keine Dateien',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.paddingS),
            const Text(
              'Es sind keine Noten für\nInstrumente hinterlegt',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.medium),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final fileCount = ref.watch(filesForGroupProvider(group.id!)).length;

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          child: ListTile(
            onTap: () => setState(() => _selectedGroup = group),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusS),
              ),
              child: const Center(
                child: Icon(
                  Icons.music_note,
                  color: AppColors.primary,
                ),
              ),
            ),
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '$fileCount ${fileCount == 1 ? 'Datei' : 'Dateien'}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.medium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilesList(
    BuildContext context,
    Group group,
    ScrollController scrollController,
  ) {
    final files = ref.watch(filesForGroupProvider(group.id!));

    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.medium,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const Text(
              'Keine Dateien',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final item = files[index];
        final song = item.song;
        final file = item.file;

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          child: ListTile(
            onTap: () => _openFile(context, file),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getFileColor(file.fileType).withValues(alpha: 0.2),
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusS),
              ),
              child: Center(
                child: Icon(
                  _getFileIcon(file.fileType),
                  color: _getFileColor(file.fileType),
                ),
              ),
            ),
            title: Text(
              song.displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (file.note != null && file.note!.isNotEmpty)
                  Text(
                    file.note!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.medium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: const Icon(
              Icons.open_in_new,
              color: AppColors.medium,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  void _openFile(BuildContext context, SongFile file) {
    if (file.fileType == 'application/pdf') {
      showPdfViewerSheet(context, url: file.url, fileName: file.fileName);
    } else {
      // For non-PDF files, open externally
      // This would typically launch a URL launcher
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öffne ${file.fileName}...')),
      );
    }
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('image')) return Icons.image;
    if (fileType.contains('audio')) return Icons.audio_file;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String fileType) {
    if (fileType.contains('pdf')) return Colors.red;
    if (fileType.contains('image')) return Colors.blue;
    if (fileType.contains('audio')) return Colors.purple;
    return AppColors.medium;
  }
}

/// Shows the group files directory sheet
Future<void> showGroupFilesSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const GroupFilesSheet(),
  );
}
