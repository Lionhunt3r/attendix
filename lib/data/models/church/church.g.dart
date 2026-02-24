// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'church.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChurchImpl _$$ChurchImplFromJson(Map<String, dynamic> json) => _$ChurchImpl(
  id: json['id'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  createdFrom: json['created_from'] as String?,
  name: json['name'] as String,
);

Map<String, dynamic> _$$ChurchImplToJson(_$ChurchImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt?.toIso8601String(),
      'created_from': instance.createdFrom,
      'name': instance.name,
    };
