import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/song_file_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/instrument_matcher.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/instrument/instrument.dart';

/// File upload sheet with multi-file selection and instrument assignment
class FileUploadSheet extends ConsumerStatefulWidget {
  final int songId;
  final List<Group> groups;

  const FileUploadSheet({
    super.key,
    required this.songId,
    required this.groups,
  });

  @override
  ConsumerState<FileUploadSheet> createState() => _FileUploadSheetState();
}

class _FileUploadSheetState extends ConsumerState<FileUploadSheet> {
  final List<_FileToUpload> _files = [];
  bool _isUploading = false;
  double _uploadProgress = 0;

  List<InstrumentInfo> get _instruments => widget.groups
      .map((g) => InstrumentInfo(id: g.id!, name: g.name))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Dateien hochladen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Info card
            if (_files.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: AppColors.primary.withAlpha(20),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Hinweis',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Wähle PDF, PNG, JPG oder Audio-Dateien aus. '
                          'Die Kategorie wird automatisch erkannt, kann aber '
                          'manuell angepasst werden.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // File list
            if (_files.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) => _FileItem(
                    file: _files[index],
                    groups: widget.groups,
                    onCategoryChanged: (categoryId) {
                      setState(() {
                        _files[index] = _files[index].copyWith(
                          instrumentId: categoryId,
                          clearInstrumentId: categoryId == null,
                        );
                      });
                    },
                    onRemove: () {
                      setState(() {
                        _files.removeAt(index);
                      });
                    },
                  ),
                ),
              ),

            // Upload progress
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      'Hochladen... ${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickFiles,
                      icon: const Icon(Icons.add),
                      label: Text(_files.isEmpty ? 'Dateien wählen' : 'Weitere'),
                    ),
                  ),
                  if (_files.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadFiles,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: Text(
                          _isUploading
                              ? 'Lade hoch...'
                              : '${_files.length} hochladen',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final songFileService = ref.read(songFileServiceProvider);
    final files = await songFileService.pickMultipleFiles();

    if (files == null || files.isEmpty) return;

    setState(() {
      for (final file in files) {
        // Try to match instrument from filename
        final matchedId = InstrumentMatcher.matchInstrument(
          file.name,
          _instruments,
        );

        _files.add(_FileToUpload(
          platformFile: file,
          instrumentId: matchedId,
        ));
      }
    });
  }

  Future<void> _uploadFiles() async {
    if (_files.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    final songFileService = ref.read(songFileServiceProvider);
    var uploadedCount = 0;
    var failedCount = 0;

    for (var i = 0; i < _files.length; i++) {
      final file = _files[i];

      try {
        await songFileService.uploadFile(
          songId: widget.songId,
          file: file.platformFile,
          instrumentId: file.instrumentId,
        );
        uploadedCount++;
      } catch (e) {
        failedCount++;
      }

      setState(() {
        _uploadProgress = (i + 1) / _files.length;
      });
    }

    setState(() {
      _isUploading = false;
    });

    if (mounted) {
      if (failedCount == 0) {
        ToastHelper.showSuccess(
          context,
          '$uploadedCount ${uploadedCount == 1 ? 'Datei' : 'Dateien'} hochgeladen',
        );
      } else {
        ToastHelper.showError(
          context,
          '$failedCount von ${_files.length} Dateien fehlgeschlagen',
        );
      }
      Navigator.pop(context, uploadedCount > 0);
    }
  }
}

/// File to upload with metadata
class _FileToUpload {
  final PlatformFile platformFile;
  final int? instrumentId;

  const _FileToUpload({
    required this.platformFile,
    this.instrumentId,
  });

  /// Create a copy with optionally updated fields.
  /// Use [clearInstrumentId] = true to explicitly set instrumentId to null.
  _FileToUpload copyWith({
    PlatformFile? platformFile,
    int? instrumentId,
    bool clearInstrumentId = false,
  }) {
    return _FileToUpload(
      platformFile: platformFile ?? this.platformFile,
      instrumentId: clearInstrumentId ? null : (instrumentId ?? this.instrumentId),
    );
  }
}

/// Single file item in the upload list
class _FileItem extends StatelessWidget {
  final _FileToUpload file;
  final List<Group> groups;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback onRemove;

  const _FileItem({
    required this.file,
    required this.groups,
    required this.onCategoryChanged,
    required this.onRemove,
  });

  IconData _getFileIcon() {
    final ext = file.platformFile.extension?.toLowerCase() ?? '';
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['png', 'jpg', 'jpeg'].contains(ext)) return Icons.image;
    if (['mp3', 'wav', 'ogg', 'm4a'].contains(ext)) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(file.platformFile.name + file.platformFile.size.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.danger,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(_getFileIcon(), color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.platformFile.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _CategoryDropdown(
                      groups: groups,
                      selectedId: file.instrumentId,
                      onChanged: onCategoryChanged,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown for selecting file category
class _CategoryDropdown extends StatelessWidget {
  final List<Group> groups;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  const _CategoryDropdown({
    required this.groups,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem(
        value: InstrumentMatcher.recordingId,
        child: Text('Aufnahme'),
      ),
      const DropdownMenuItem(
        value: InstrumentMatcher.lyricsId,
        child: Text('Liedtext'),
      ),
      ...groups.map((g) => DropdownMenuItem(
            value: g.id,
            child: Text(g.name),
          )),
      const DropdownMenuItem(
        value: null,
        child: Text('Sonstige'),
      ),
    ];

    return DropdownButtonFormField<int?>(
      value: selectedId,
      items: items,
      onChanged: onChanged,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(),
      ),
      style: Theme.of(context).textTheme.bodySmall,
      isExpanded: true,
    );
  }
}
