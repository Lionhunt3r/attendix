import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/song/song.dart';
import '../../data/models/song/song_filter.dart';
import 'song_providers.dart';
import 'tenant_providers.dart';

/// Key pattern for persisting filter per tenant
String _getSongFilterPrefsKey(int tenantId) => 'songFilter_$tenantId';

/// Search query state for songs
final songSearchQueryProvider = StateProvider<String>((ref) => '');

/// Song filter state with persistence
final songFilterProvider =
    StateNotifierProvider<SongFilterNotifier, SongFilter>((ref) {
  final tenantId = ref.watch(currentTenantIdProvider);
  return SongFilterNotifier(tenantId);
});

/// Notifier for song filter state with SharedPreferences persistence
class SongFilterNotifier extends StateNotifier<SongFilter> {
  SongFilterNotifier(this.tenantId) : super(const SongFilter()) {
    if (tenantId != null) {
      _loadFromPrefs();
    }
  }

  final int? tenantId;

  Future<void> _loadFromPrefs() async {
    if (tenantId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_getSongFilterPrefsKey(tenantId!));
      if (json != null) {
        state = SongFilter.fromJson(jsonDecode(json) as Map<String, dynamic>);
      }
    } catch (_) {
      // If loading fails, use default filter
    }
  }

  Future<void> _saveToPrefs() async {
    if (tenantId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _getSongFilterPrefsKey(tenantId!), jsonEncode(state.toJson()));
    } catch (_) {
      // Ignore save errors
    }
  }

  void setWithChoir(bool value) {
    state = state.copyWith(withChoir: value);
    _saveToPrefs();
  }

  void setWithSolo(bool value) {
    state = state.copyWith(withSolo: value);
    _saveToPrefs();
  }

  void setInstrumentIds(List<int> value) {
    state = state.copyWith(instrumentIds: value);
    _saveToPrefs();
  }

  void toggleInstrumentId(int id) {
    final current = List<int>.from(state.instrumentIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(instrumentIds: current);
    _saveToPrefs();
  }

  void setDifficulty(int? value) {
    state = state.copyWith(difficulty: value);
    _saveToPrefs();
  }

  void setCategory(String? value) {
    state = state.copyWith(category: value);
    _saveToPrefs();
  }

  void setSortOption(SongSortOption value) {
    state = state.copyWith(sortOption: value);
    _saveToPrefs();
  }

  void reset() {
    state = const SongFilter();
    _saveToPrefs();
  }

  void clearCategory() {
    state = state.copyWith(category: null);
    _saveToPrefs();
  }

  void clearDifficulty() {
    state = state.copyWith(difficulty: null);
    _saveToPrefs();
  }

  void clearInstruments() {
    state = state.copyWith(instrumentIds: []);
    _saveToPrefs();
  }
}

/// Filtered and sorted songs provider
final filteredSongsProvider = Provider<List<Song>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  final filter = ref.watch(songFilterProvider);
  final searchQuery = ref.watch(songSearchQueryProvider);

  final songs = songsAsync.valueOrNull ?? [];

  // Apply filters
  var filtered = songs.where((song) {
    // Filter by choir
    if (filter.withChoir && !song.withChoir) return false;

    // Filter by solo
    if (filter.withSolo && !song.withSolo) return false;

    // Filter by difficulty
    if (filter.difficulty != null && song.difficulty != filter.difficulty) {
      return false;
    }

    // Filter by category
    if (filter.category != null &&
        filter.category!.isNotEmpty &&
        song.category != filter.category) {
      return false;
    }

    // Filter by instruments
    if (filter.instrumentIds.isNotEmpty) {
      final songInstruments = song.instrumentIds ?? [];
      if (!filter.instrumentIds.any((id) => songInstruments.contains(id))) {
        return false;
      }
    }

    // Search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      final nameMatch = song.name.toLowerCase().contains(query);
      final numberMatch = song.fullNumber.toLowerCase().contains(query);
      final conductorMatch =
          song.conductor?.toLowerCase().contains(query) ?? false;
      if (!nameMatch && !numberMatch && !conductorMatch) {
        return false;
      }
    }

    return true;
  }).toList();

  // Apply sorting
  switch (filter.sortOption) {
    case SongSortOption.numberAsc:
      filtered.sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
    case SongSortOption.numberDesc:
      filtered.sort((a, b) => (b.number ?? 0).compareTo(a.number ?? 0));
    case SongSortOption.nameAsc:
      filtered
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case SongSortOption.nameDesc:
      filtered
          .sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    case SongSortOption.lastSungAsc:
      filtered.sort((a, b) => _compareDates(a.lastSung, b.lastSung));
    case SongSortOption.lastSungDesc:
      filtered.sort((a, b) => _compareDates(b.lastSung, a.lastSung));
  }

  return filtered;
});

/// Helper for date comparison (null values go to end)
int _compareDates(String? a, String? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
