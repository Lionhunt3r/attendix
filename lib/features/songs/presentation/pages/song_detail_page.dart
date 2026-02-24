import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/providers/song_providers.dart';
import '../../../../core/providers/tenant_providers.dart';
import '../../../../core/services/song_file_service.dart';
import '../../../../core/services/telegram_service.dart';
import '../../../../core/services/zip_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../../../core/utils/instrument_matcher.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/instrument/instrument.dart';
import '../../../../data/models/song/song.dart';
import '../../../../data/models/tenant/tenant.dart';
import '../../../../shared/widgets/sheets/image_viewer_sheet.dart';
import '../widgets/copy_to_tenant_sheet.dart';
import '../widgets/file_upload_sheet.dart';
import '../widgets/pdf_viewer_sheet.dart';
import '../widgets/smart_print_dialog.dart';

/// Song Detail Page - with inline editing like Ionic
class SongDetailPage extends ConsumerStatefulWidget {
  final String songId;

  const SongDetailPage({super.key, required this.songId});

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  // Edit state
  late TextEditingController _prefixController;
  late TextEditingController _numberController;
  late TextEditingController _nameController;
  late TextEditingController _linkController;

  bool _initialized = false;
  bool _isSaving = false;

  // Local state for toggles and selects
  bool _withChoir = false;
  bool _withSolo = false;
  int? _difficulty;
  String? _category;
  List<int> _selectedInstrumentIds = [];

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController();
    _numberController = TextEditingController();
    _nameController = TextEditingController();
    _linkController = TextEditingController();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _numberController.dispose();
    _nameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _initializeFromSong(Song song) {
    if (_initialized) return;
    _prefixController.text = song.prefix ?? '';
    _numberController.text = song.number?.toString() ?? '';
    _nameController.text = song.name;
    _linkController.text = song.link ?? '';
    _withChoir = song.withChoir;
    _withSolo = song.withSolo;
    _difficulty = song.difficulty;
    _category = song.category;
    _selectedInstrumentIds = List.from(song.instrumentIds ?? []);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final songId = int.tryParse(widget.songId);
    if (songId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Werk')),
        body: const Center(child: Text('Ungültige Song-ID')),
      );
    }

    final songAsync = ref.watch(songByIdProvider(songId));
    final role = ref.watch(currentRoleProvider);
    final tenant = ref.watch(currentTenantProvider);
    final isOrchestra = tenant?.type == 'orchestra';

    // ReadOnly mode: only admin/responsible can edit
    final readOnly = !(role.isAdmin || role.isResponsible);

    return songAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Werk')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Werk')),
        body: Center(child: Text('Fehler: $error')),
      ),
      data: (song) {
        if (song == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Werk')),
            body: const Center(child: Text('Werk nicht gefunden')),
          );
        }

        _initializeFromSong(song);

        return Scaffold(
          appBar: AppBar(
            title: Text(readOnly ? song.displayName : 'Werk bearbeiten'),
            actions: [
              // Share link button
              if (tenant?.songSharingId != null)
                IconButton(
                  icon: const Icon(Icons.link),
                  tooltip: 'Link kopieren',
                  onPressed: () => _copyShareLink(context, song.id!, tenant!.songSharingId!),
                ),
              // Delete button (only for non-readOnly)
              if (!readOnly)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteSong(context, song),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            children: [
              // Editable fields section (only shown in edit mode)
              if (!readOnly) ...[
                _EditableFieldsCard(
                  prefixController: _prefixController,
                  numberController: _numberController,
                  nameController: _nameController,
                  linkController: _linkController,
                  withChoir: _withChoir,
                  withSolo: _withSolo,
                  difficulty: _difficulty,
                  category: _category,
                  selectedInstrumentIds: _selectedInstrumentIds,
                  isOrchestra: isOrchestra,
                  isSaving: _isSaving,
                  onWithChoirChanged: (v) => _updateAndSave(song.id!, () => _withChoir = v),
                  onWithSoloChanged: (v) => _updateAndSave(song.id!, () => _withSolo = v),
                  onDifficultyChanged: (v) => _updateAndSave(song.id!, () => _difficulty = v),
                  onCategoryChanged: (v) => _updateAndSave(song.id!, () => _category = v),
                  onInstrumentIdsChanged: (v) => _updateAndSave(song.id!, () => _selectedInstrumentIds = v),
                  onFieldBlur: () => _saveChanges(song.id!),
                ),
                const SizedBox(height: AppDimensions.paddingM),
              ],

              // Read-only header card (shown in readOnly mode)
              if (readOnly) ...[
                _ReadOnlyHeaderCard(song: song),
                const SizedBox(height: AppDimensions.paddingM),
              ],

              // Category chip (read-only mode)
              if (readOnly && song.category != null) ...[
                _SectionHeader(title: 'Kategorie'),
                Wrap(
                  children: [
                    Chip(
                      label: Text(song.category!),
                      backgroundColor: AppColors.secondary.withAlpha(30),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingM),
              ],

              // Besetzungs-Chips section (read-only mode with green/red logic)
              if (readOnly && (song.withChoir || song.withSolo || (isOrchestra && song.instrumentIds?.isNotEmpty == true)))
                _BesetzungsSection(
                  song: song,
                  isOrchestra: isOrchestra,
                ),

              // Instruments section (edit mode - multi-select already in _EditableFieldsCard)
              // Files section
              _FilesSection(
                files: song.files ?? [],
                songId: song.id!,
                songName: song.displayName,
                readOnly: readOnly,
                onFileAdded: () => ref.invalidate(songByIdProvider(songId)),
              ),

              // External link (read-only mode)
              if (readOnly && song.link != null && song.link!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.paddingM),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.link, color: AppColors.primary),
                    title: const Text('Externen Noten-Link öffnen'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openLink(song.link!),
                  ),
                ),
              ],

              // Copy to other instance (only for admin/responsible)
              if (!readOnly) ...[
                const SizedBox(height: AppDimensions.paddingM),
                _CopyToTenantButton(song: song),
              ],

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
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAndSave(int songId, VoidCallback update) async {
    setState(update);
    await _saveChanges(songId);
  }

  Future<void> _saveChanges(int songId) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(songNotifierProvider.notifier);

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'number': int.tryParse(_numberController.text.trim()),
        'prefix': _prefixController.text.trim().isNotEmpty
            ? _prefixController.text.trim()
            : null,
        'link': _linkController.text.trim().isNotEmpty
            ? _linkController.text.trim()
            : null,
        'withChoir': _withChoir,
        'withSolo': _withSolo,
        'difficulty': _difficulty,
        'category': _category,
        'instrument_ids':
            _selectedInstrumentIds.isNotEmpty ? _selectedInstrumentIds : null,
      };

      await notifier.updateSong(songId, updates);
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _copyShareLink(BuildContext context, int songId, String sharingId) {
    final link = '${Uri.base.origin}/$sharingId/$songId';
    Clipboard.setData(ClipboardData(text: link));
    ToastHelper.showSuccess(context, 'Link in Zwischenablage kopiert');
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
      title: 'Werk löschen',
      message: 'Möchtest du "${song.name}" wirklich löschen?',
      confirmText: 'Löschen',
      cancelText: 'Abbrechen',
    );

    if (!confirmed) return;

    try {
      final success =
          await ref.read(songNotifierProvider.notifier).deleteSong(song.id!);

      if (mounted && success) {
        ToastHelper.showSuccess(context, 'Werk gelöscht');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.medium,
        ),
      ),
    );
  }
}

/// Editable fields card for edit mode
class _EditableFieldsCard extends ConsumerWidget {
  final TextEditingController prefixController;
  final TextEditingController numberController;
  final TextEditingController nameController;
  final TextEditingController linkController;
  final bool withChoir;
  final bool withSolo;
  final int? difficulty;
  final String? category;
  final List<int> selectedInstrumentIds;
  final bool isOrchestra;
  final bool isSaving;
  final ValueChanged<bool> onWithChoirChanged;
  final ValueChanged<bool> onWithSoloChanged;
  final ValueChanged<int?> onDifficultyChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<List<int>> onInstrumentIdsChanged;
  final VoidCallback onFieldBlur;

  const _EditableFieldsCard({
    required this.prefixController,
    required this.numberController,
    required this.nameController,
    required this.linkController,
    required this.withChoir,
    required this.withSolo,
    required this.difficulty,
    required this.category,
    required this.selectedInstrumentIds,
    required this.isOrchestra,
    required this.isSaving,
    required this.onWithChoirChanged,
    required this.onWithSoloChanged,
    required this.onDifficultyChanged,
    required this.onCategoryChanged,
    required this.onInstrumentIdsChanged,
    required this.onFieldBlur,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final categoriesAsync = ref.watch(songCategoriesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saving indicator
            if (isSaving)
              const LinearProgressIndicator(),

            // Prefix input
            TextFormField(
              controller: prefixController,
              decoration: const InputDecoration(
                labelText: 'Präfix (optional)',
                helperText: 'z.B. W für Weihnachten → W1',
              ),
              onEditingComplete: onFieldBlur,
            ),
            const SizedBox(height: AppDimensions.paddingS),

            // Number input
            TextFormField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Nummer',
              ),
              keyboardType: TextInputType.number,
              onEditingComplete: onFieldBlur,
            ),
            const SizedBox(height: AppDimensions.paddingS),

            // Name input
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              onEditingComplete: onFieldBlur,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Difficulty dropdown
            DropdownButtonFormField<int?>(
              value: difficulty,
              decoration: const InputDecoration(
                labelText: 'Schwierigkeitsgrad',
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Nicht definiert')),
                DropdownMenuItem(value: 1, child: Text('1 - Leicht')),
                DropdownMenuItem(value: 2, child: Text('2 - Mittel')),
                DropdownMenuItem(value: 3, child: Text('3 - Schwer')),
              ],
              onChanged: onDifficultyChanged,
            ),
            const SizedBox(height: AppDimensions.paddingS),

            // Toggles
            SwitchListTile(
              title: const Text('Chor & Orchester'),
              value: withChoir,
              onChanged: onWithChoirChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Mit Solo-Gesang'),
              value: withSolo,
              onChanged: onWithSoloChanged,
              contentPadding: EdgeInsets.zero,
            ),

            // Instruments multi-select (Orchestra only)
            if (isOrchestra)
              groupsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (groups) {
                  final instruments = groups.where((g) => g.maingroup != true).toList();
                  if (instruments.isEmpty) return const SizedBox.shrink();

                  return _InstrumentMultiSelect(
                    instruments: instruments,
                    selectedIds: selectedInstrumentIds,
                    onChanged: onInstrumentIdsChanged,
                  );
                },
              ),

            const SizedBox(height: AppDimensions.paddingS),

            // Category dropdown
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (categories) => categories.isNotEmpty
                  ? DropdownButtonFormField<String?>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Keine Kategorie')),
                        ...categories.map((c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.name),
                            )),
                      ],
                      onChanged: onCategoryChanged,
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: AppDimensions.paddingS),

            // Link textarea
            TextFormField(
              controller: linkController,
              decoration: const InputDecoration(
                labelText: 'Link',
              ),
              maxLines: 2,
              onEditingComplete: onFieldBlur,
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select for instruments with modal interface
class _InstrumentMultiSelect extends StatelessWidget {
  final List<Group> instruments;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;

  const _InstrumentMultiSelect({
    required this.instruments,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Besetzung'),
      subtitle: Text(
        selectedIds.isEmpty
            ? 'Keine Instrumente ausgewählt'
            : '${selectedIds.length} Instrumente ausgewählt',
      ),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: () => _showSelectionDialog(context),
    );
  }

  Future<void> _showSelectionDialog(BuildContext context) async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => _InstrumentSelectionDialog(
        instruments: instruments,
        initialSelection: selectedIds,
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}

/// Dialog for instrument multi-selection
class _InstrumentSelectionDialog extends StatefulWidget {
  final List<Group> instruments;
  final List<int> initialSelection;

  const _InstrumentSelectionDialog({
    required this.instruments,
    required this.initialSelection,
  });

  @override
  State<_InstrumentSelectionDialog> createState() => _InstrumentSelectionDialogState();
}

class _InstrumentSelectionDialogState extends State<_InstrumentSelectionDialog> {
  late List<int> _selection;

  @override
  void initState() {
    super.initState();
    _selection = List.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Besetzung'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.instruments.length,
          itemBuilder: (context, index) {
            final instrument = widget.instruments[index];
            final isSelected = _selection.contains(instrument.id);

            return CheckboxListTile(
              title: Text(instrument.name),
              value: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked == true && instrument.id != null) {
                    _selection.add(instrument.id!);
                  } else {
                    _selection.remove(instrument.id);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selection),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

/// Read-only header card showing song info
class _ReadOnlyHeaderCard extends StatelessWidget {
  final Song song;

  const _ReadOnlyHeaderCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  const Icon(Icons.person, size: 16, color: AppColors.medium),
                  const SizedBox(width: 4),
                  Text(
                    song.conductor!,
                    style: const TextStyle(color: AppColors.medium),
                  ),
                ],
              ),
            ],
            if (song.difficultyLabel != null) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text(song.difficultyLabel!),
                avatar: const Icon(Icons.speed, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Besetzungs-Chips section with green/red color logic
class _BesetzungsSection extends ConsumerWidget {
  final Song song;
  final bool isOrchestra;

  const _BesetzungsSection({
    required this.song,
    required this.isOrchestra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Besetzung'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (song.withChoir)
              const Chip(
                label: Text('Chor & Orchester'),
                backgroundColor: Color(0xFFE3F2FD), // Light blue
              ),
            if (song.withSolo)
              const Chip(
                label: Text('Mit Solo-Gesang'),
                backgroundColor: Color(0xFFE3F2FD), // Light blue
              ),
          ],
        ),
        if (isOrchestra && song.instrumentIds?.isNotEmpty == true)
          groupsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (groups) {
              // Filter to only instruments (not main groups)
              final instruments = groups.where((g) => g.maingroup != true).toList();

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: instruments.map((instrument) {
                    // Green if song has this instrument, red if not
                    final hasInstrument = song.instrumentIds!.contains(instrument.id);
                    final color = hasInstrument ? AppColors.success : AppColors.danger;

                    return Chip(
                      label: Text(
                        instrument.name,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: color.withAlpha(30),
                      side: BorderSide(color: color.withAlpha(80)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        const SizedBox(height: AppDimensions.paddingM),
      ],
    );
  }
}

/// Copy to Tenant button
class _CopyToTenantButton extends ConsumerWidget {
  final Song song;

  const _CopyToTenantButton({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(userTenantsProvider);
    final currentTenantId = ref.watch(currentTenantIdProvider);

    return tenantsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tenants) {
        // Filter out current tenant
        final otherTenants = tenants.where((t) => t.id != currentTenantId).toList();
        if (otherTenants.isEmpty) return const SizedBox.shrink();

        return Card(
          child: ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Werk in andere Instanz kopieren'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCopySheet(context, otherTenants),
          ),
        );
      },
    );
  }

  Future<void> _showCopySheet(BuildContext context, List<Tenant> tenants) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CopyToTenantSheet(
        song: song,
        availableTenants: tenants,
      ),
    );
  }
}

// ============================================================================
// FILES SECTION
// ============================================================================

class _FilesSection extends ConsumerStatefulWidget {
  final List<SongFile> files;
  final int songId;
  final String songName;
  final bool readOnly;
  final VoidCallback onFileAdded;

  const _FilesSection({
    required this.files,
    required this.songId,
    required this.songName,
    required this.readOnly,
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
                      if (_hasPdfFiles() && !widget.readOnly)
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
                      if (!widget.readOnly)
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
                      if (widget.files.isNotEmpty && !widget.readOnly) ...[
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
                  // Quick upload button (only for non-readOnly)
                  if (!widget.readOnly)
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
                        readOnly: widget.readOnly,
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
  final bool readOnly;
  final VoidCallback onDeleted;

  const _FileTile({
    required this.file,
    required this.songId,
    required this.songName,
    required this.groups,
    required this.readOnly,
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
          if (!readOnly) ...[
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
