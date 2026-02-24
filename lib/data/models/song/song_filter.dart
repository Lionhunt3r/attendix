import 'package:freezed_annotation/freezed_annotation.dart';

part 'song_filter.freezed.dart';
part 'song_filter.g.dart';

/// Sort options for songs list
enum SongSortOption {
  numberAsc,    // Nummer ↑
  numberDesc,   // Nummer ↓
  nameAsc,      // Name ↑
  nameDesc,     // Name ↓
  lastSungAsc,  // Zuletzt gespielt ↑
  lastSungDesc, // Zuletzt gespielt ↓
}

extension SongSortOptionX on SongSortOption {
  String get label {
    switch (this) {
      case SongSortOption.numberAsc:
        return 'Nummer ↑';
      case SongSortOption.numberDesc:
        return 'Nummer ↓';
      case SongSortOption.nameAsc:
        return 'Name ↑';
      case SongSortOption.nameDesc:
        return 'Name ↓';
      case SongSortOption.lastSungAsc:
        return 'Zuletzt gespielt ↑';
      case SongSortOption.lastSungDesc:
        return 'Zuletzt gespielt ↓';
    }
  }
}

/// Filter and sort settings for songs list
@freezed
class SongFilter with _$SongFilter {
  const SongFilter._();

  const factory SongFilter({
    @Default(false) bool withChoir,
    @Default(false) bool withSolo,
    @Default([]) List<int> instrumentIds,
    int? difficulty,
    String? category,
    @Default(SongSortOption.numberAsc) SongSortOption sortOption,
  }) = _SongFilter;

  factory SongFilter.fromJson(Map<String, dynamic> json) =>
      _$SongFilterFromJson(json);

  /// Check if any filter is active (excluding sort)
  bool get hasActiveFilters =>
      withChoir ||
      withSolo ||
      instrumentIds.isNotEmpty ||
      difficulty != null ||
      (category != null && category!.isNotEmpty);

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (withChoir) count++;
    if (withSolo) count++;
    if (instrumentIds.isNotEmpty) count++;
    if (difficulty != null) count++;
    if (category != null && category!.isNotEmpty) count++;
    return count;
  }
}
