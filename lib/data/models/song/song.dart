import 'package:freezed_annotation/freezed_annotation.dart';

part 'song.freezed.dart';
part 'song.g.dart';

/// Song model - represents a song/piece in the repertoire
@freezed
class Song with _$Song {
  const factory Song({
    int? id,
    int? tenantId,
    required String name,
    int? number,
    String? prefix,
    @Default(false) bool withChoir,
    @Default(false) bool withSolo,
    String? lastSung,
    String? link,
    String? conductor,
    int? legacyId,
    @JsonKey(name: 'instrument_ids') List<int>? instrumentIds,
    List<SongFile>? files,
    int? difficulty,
    String? category,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
}

/// Song file attachment
@freezed
class SongFile with _$SongFile {
  const factory SongFile({
    String? storageName,
    @JsonKey(name: 'created_at') String? createdAt,
    required String fileName,
    required String fileType,
    required String url,
    int? instrumentId,
    String? note,
  }) = _SongFile;

  factory SongFile.fromJson(Map<String, dynamic> json) =>
      _$SongFileFromJson(json);
}

/// Song history - when a song was played
@freezed
class SongHistory with _$SongHistory {
  const factory SongHistory({
    int? id,
    int? tenantId,
    @JsonKey(name: 'song_id') int? songId,
    @JsonKey(name: 'attendance_id') int? attendanceId,
    String? date,
    String? conductorName,
    String? otherConductor,
    int? count,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    Song? song,
  }) = _SongHistory;

  factory SongHistory.fromJson(Map<String, dynamic> json) =>
      _$SongHistoryFromJson(json);
}

/// Song category
@freezed
class SongCategory with _$SongCategory {
  const factory SongCategory({
    String? id,
    @JsonKey(name: 'tenant_id') int? tenantId,
    required String name,
    @Default(0) int index,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SongCategory;

  factory SongCategory.fromJson(Map<String, dynamic> json) =>
      _$SongCategoryFromJson(json);
}

/// Extension for Song
extension SongExtension on Song {
  /// Full song number with prefix
  String get fullNumber {
    final p = prefix ?? '';
    final n = number?.toString() ?? '';
    return '$p$n'.trim();
  }
  
  /// Display name with number
  String get displayName {
    final fn = fullNumber;
    if (fn.isEmpty) return name;
    return '$fn - $name';
  }
  
  /// Difficulty label
  String? get difficultyLabel {
    if (difficulty == null) return null;
    switch (difficulty!) {
      case 1: return 'Leicht';
      case 2: return 'Mittel';
      case 3: return 'Schwer';
      case 4: return 'Sehr schwer';
      default: return null;
    }
  }
}