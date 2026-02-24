// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongFilterImpl _$$SongFilterImplFromJson(Map<String, dynamic> json) =>
    _$SongFilterImpl(
      withChoir: json['withChoir'] as bool? ?? false,
      withSolo: json['withSolo'] as bool? ?? false,
      instrumentIds:
          (json['instrumentIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      difficulty: (json['difficulty'] as num?)?.toInt(),
      category: json['category'] as String?,
      sortOption:
          $enumDecodeNullable(_$SongSortOptionEnumMap, json['sortOption']) ??
          SongSortOption.numberAsc,
    );

Map<String, dynamic> _$$SongFilterImplToJson(_$SongFilterImpl instance) =>
    <String, dynamic>{
      'withChoir': instance.withChoir,
      'withSolo': instance.withSolo,
      'instrumentIds': instance.instrumentIds,
      'difficulty': instance.difficulty,
      'category': instance.category,
      'sortOption': _$SongSortOptionEnumMap[instance.sortOption]!,
    };

const _$SongSortOptionEnumMap = {
  SongSortOption.numberAsc: 'numberAsc',
  SongSortOption.numberDesc: 'numberDesc',
  SongSortOption.nameAsc: 'nameAsc',
  SongSortOption.nameDesc: 'nameDesc',
  SongSortOption.lastSungAsc: 'lastSungAsc',
  SongSortOption.lastSungDesc: 'lastSungDesc',
};
