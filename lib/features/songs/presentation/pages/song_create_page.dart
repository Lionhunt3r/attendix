import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/group_providers.dart';
import '../../../../core/providers/song_providers.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/song/song.dart';

/// Page for creating a new song
class SongCreatePage extends ConsumerStatefulWidget {
  const SongCreatePage({super.key});

  @override
  ConsumerState<SongCreatePage> createState() => _SongCreatePageState();
}

class _SongCreatePageState extends ConsumerState<SongCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _prefixController = TextEditingController();
  final _linkController = TextEditingController();
  final _conductorController = TextEditingController();

  bool _withChoir = false;
  bool _withSolo = false;
  int? _difficulty;
  String? _category;
  final List<int> _selectedInstrumentIds = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _prefixController.dispose();
    _linkController.dispose();
    _conductorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final categoriesAsync = ref.watch(songCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neues Lied'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Speichern'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            // Name (required)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'z.B. Amazing Grace',
                prefixIcon: Icon(Icons.music_note),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name ist erforderlich';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Prefix and Number row
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Präfix',
                      hintText: 'GL',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      labelText: 'Nummer',
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Conductor
            TextFormField(
              controller: _conductorController,
              decoration: const InputDecoration(
                labelText: 'Dirigent (optional)',
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Link
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Link (optional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Category dropdown
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const SizedBox.shrink(),
              data: (categories) => categories.isNotEmpty
                  ? DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Keine Kategorie'),
                        ),
                        ...categories.map((c) => DropdownMenuItem<String>(
                              value: c.name,
                              child: Text(c.name),
                            )),
                      ],
                      onChanged: (value) => setState(() => _category = value),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Difficulty dropdown
            DropdownButtonFormField<int>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Schwierigkeit',
                prefixIcon: Icon(Icons.speed),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Nicht angegeben')),
                DropdownMenuItem(value: 1, child: Text('Leicht')),
                DropdownMenuItem(value: 2, child: Text('Mittel')),
                DropdownMenuItem(value: 3, child: Text('Schwer')),
                DropdownMenuItem(value: 4, child: Text('Sehr schwer')),
              ],
              onChanged: (value) => setState(() => _difficulty = value),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Toggles
            SwitchListTile(
              title: const Text('Mit Chor'),
              value: _withChoir,
              onChanged: (value) => setState(() => _withChoir = value),
              secondary: const Icon(Icons.groups),
            ),
            SwitchListTile(
              title: const Text('Mit Solo'),
              value: _withSolo,
              onChanged: (value) => setState(() => _withSolo = value),
              secondary: const Icon(Icons.mic),
            ),

            // Instruments/Groups multi-select
            const SizedBox(height: AppDimensions.paddingM),
            groupsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => const SizedBox.shrink(),
              data: (groups) => groups.isNotEmpty
                  ? ExpansionTile(
                      title: Text('Instrumente (${_selectedInstrumentIds.length})'),
                      leading: const Icon(Icons.music_note_outlined),
                      children: groups
                          .map((g) => CheckboxListTile(
                                title: Text(g.name),
                                value: _selectedInstrumentIds.contains(g.id),
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected == true && g.id != null) {
                                      _selectedInstrumentIds.add(g.id!);
                                    } else {
                                      _selectedInstrumentIds.remove(g.id);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: AppDimensions.paddingL),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(songNotifierProvider.notifier);

      final song = Song(
        name: _nameController.text.trim(),
        number: int.tryParse(_numberController.text.trim()),
        prefix: _prefixController.text.trim().isNotEmpty
            ? _prefixController.text.trim()
            : null,
        link: _linkController.text.trim().isNotEmpty
            ? _linkController.text.trim()
            : null,
        conductor: _conductorController.text.trim().isNotEmpty
            ? _conductorController.text.trim()
            : null,
        withChoir: _withChoir,
        withSolo: _withSolo,
        difficulty: _difficulty,
        category: _category,
        instrumentIds:
            _selectedInstrumentIds.isNotEmpty ? _selectedInstrumentIds : null,
      );

      final result = await notifier.createSong(song);

      if (mounted && result != null) {
        ToastHelper.showSuccess(context, 'Lied erstellt');
        // Navigate to detail page
        context.pushReplacement('/settings/songs/${result.id}');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
