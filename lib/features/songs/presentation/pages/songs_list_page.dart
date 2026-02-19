import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/toast_helper.dart';
import '../../../../data/models/song/song.dart';
import '../../../tenant_selection/presentation/pages/tenant_selection_page.dart';

/// Provider for songs list
final songsListProvider = FutureProvider<List<Song>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final tenant = ref.watch(currentTenantProvider);
  
  if (tenant == null) return [];

  final response = await supabase
      .from('songs')
      .select('*')
      .eq('tenantId', tenant.id!)
      .order('number')
      .order('name');

  return (response as List)
      .map((e) => Song.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Songs list page
class SongsListPage extends ConsumerStatefulWidget {
  const SongsListPage({super.key});

  @override
  ConsumerState<SongsListPage> createState() => _SongsListPageState();
}

class _SongsListPageState extends ConsumerState<SongsListPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _filterSongs(List<Song> songs) {
    if (_searchQuery.isEmpty) return songs;
    
    final query = _searchQuery.toLowerCase();
    return songs.where((song) {
      return song.name.toLowerCase().contains(query) ||
          (song.fullNumber.toLowerCase().contains(query)) ||
          (song.conductor?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lieder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
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
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Songs list
          Expanded(
            child: songsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text('Fehler: $error'),
                    const SizedBox(height: AppDimensions.paddingM),
                    ElevatedButton(
                      onPressed: () => ref.refresh(songsListProvider),
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
              data: (songs) {
                final filteredSongs = _filterSongs(songs);

                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.music_note_outlined,
                          size: 80,
                          color: AppColors.medium,
                        ),
                        const SizedBox(height: AppDimensions.paddingL),
                        Text(
                          'Keine Lieder',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        Text(
                          'Füge das erste Lied hinzu',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.medium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredSongs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.medium,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          'Keine Ergebnisse für "$_searchQuery"',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.refresh(songsListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                    ),
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      return _SongListItem(
                        song: song,
                        onTap: () => context.push('/settings/songs/${song.id}'),
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
        onPressed: () => _showAddSongDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SongListItem extends StatelessWidget {
  const _SongListItem({
    required this.song,
    required this.onTap,
  });

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: Center(
            child: song.fullNumber.isNotEmpty
                ? Text(
                    song.fullNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.music_note,
                    color: AppColors.primary,
                  ),
          ),
        ),
        title: Text(
          song.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (song.conductor != null)
              Text(
                song.conductor!,
                style: const TextStyle(fontSize: 13),
              ),
            Row(
              children: [
                if (song.withChoir)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text('Chor'),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (song.withSolo)
                  const Chip(
                    label: Text('Solo'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
        ),
        trailing: song.lastSung != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Zuletzt',
                    style: TextStyle(fontSize: 11, color: AppColors.medium),
                  ),
                  Text(
                    song.lastSung!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              )
            : const Icon(
                Icons.chevron_right,
                color: AppColors.medium,
              ),
      ),
    );
  }
}

/// Show dialog to add a new song
Future<void> _showAddSongDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => const _AddSongDialog(),
  );

  if (result != null && context.mounted) {
    try {
      final supabase = ref.read(supabaseClientProvider);
      final tenant = ref.read(currentTenantProvider);

      if (tenant == null) {
        ToastHelper.showError(context, 'Kein Tenant ausgewählt');
        return;
      }

      final response = await supabase
          .from('songs')
          .insert({
            'name': result['name'],
            'number': result['number'],
            'prefix': result['prefix'],
            'link': result['link'],
            'conductor': result['conductor'],
            'withChoir': result['withChoir'] ?? false,
            'withSolo': result['withSolo'] ?? false,
            'tenantId': tenant.id,
          })
          .select()
          .single();

      ref.invalidate(songsListProvider);

      if (context.mounted) {
        ToastHelper.showSuccess(context, 'Lied erstellt');
        // Navigate to the new song's detail page
        final songId = response['id'];
        if (songId != null) {
          context.push('/settings/songs/$songId');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastHelper.showError(context, 'Fehler: $e');
      }
    }
  }
}

/// Dialog for adding a new song
class _AddSongDialog extends StatefulWidget {
  const _AddSongDialog();

  @override
  State<_AddSongDialog> createState() => _AddSongDialogState();
}

class _AddSongDialogState extends State<_AddSongDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _prefixController = TextEditingController();
  final _linkController = TextEditingController();
  final _conductorController = TextEditingController();
  bool _withChoir = false;
  bool _withSolo = false;

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
    return AlertDialog(
      title: const Text('Neues Lied'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'z.B. Amazing Grace',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name ist erforderlich';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Number and Prefix in a row
              Row(
                children: [
                  // Prefix
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _prefixController,
                      decoration: const InputDecoration(
                        labelText: 'Präfix',
                        hintText: 'z.B. GL',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  // Number
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _numberController,
                      decoration: const InputDecoration(
                        labelText: 'Nummer',
                        hintText: 'z.B. 123',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Link
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Conductor
              TextFormField(
                controller: _conductorController,
                decoration: const InputDecoration(
                  labelText: 'Dirigent (optional)',
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Toggles
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Mit Chor'),
                      value: _withChoir,
                      onChanged: (value) => setState(() => _withChoir = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      title: const Text('Mit Solo'),
                      value: _withSolo,
                      onChanged: (value) => setState(() => _withSolo = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Erstellen'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'number': int.tryParse(_numberController.text.trim()),
        'prefix': _prefixController.text.trim().isNotEmpty
            ? _prefixController.text.trim()
            : null,
        'link': _linkController.text.trim().isNotEmpty
            ? _linkController.text.trim()
            : null,
        'conductor': _conductorController.text.trim().isNotEmpty
            ? _conductorController.text.trim()
            : null,
        'withChoir': _withChoir,
        'withSolo': _withSolo,
      });
    }
  }
}