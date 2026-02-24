// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShiftDefinitionImpl _$$ShiftDefinitionImplFromJson(
  Map<String, dynamic> json,
) => _$ShiftDefinitionImpl(
  id: (json['id'] as num?)?.toInt(),
  startTime: json['start_time'] as String? ?? '08:00',
  duration: (json['duration'] as num?)?.toDouble() ?? 8.0,
  free: json['free'] as bool? ?? false,
  index: (json['index'] as num?)?.toInt() ?? 0,
  repeatCount: (json['repeat_count'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$$ShiftDefinitionImplToJson(
  _$ShiftDefinitionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'start_time': instance.startTime,
  'duration': instance.duration,
  'free': instance.free,
  'index': instance.index,
  'repeat_count': instance.repeatCount,
};
