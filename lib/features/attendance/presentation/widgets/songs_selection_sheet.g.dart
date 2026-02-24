// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'songs_selection_sheet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongHistoryEntryImpl _$$SongHistoryEntryImplFromJson(
  Map<String, dynamic> json,
) => _$SongHistoryEntryImpl(
  songId: (json['songId'] as num).toInt(),
  songName: json['songName'] as String,
  conductorId: (json['conductorId'] as num?)?.toInt(),
  conductorName: json['conductorName'] as String?,
  otherConductor: json['otherConductor'] as String?,
);

Map<String, dynamic> _$$SongHistoryEntryImplToJson(
  _$SongHistoryEntryImpl instance,
) => <String, dynamic>{
  'songId': instance.songId,
  'songName': instance.songName,
  'conductorId': instance.conductorId,
  'conductorName': instance.conductorName,
  'otherConductor': instance.otherConductor,
};
