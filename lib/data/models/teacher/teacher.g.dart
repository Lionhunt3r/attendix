// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeacherImpl _$$TeacherImplFromJson(Map<String, dynamic> json) =>
    _$TeacherImpl(
      id: (json['id'] as num?)?.toInt(),
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      name: json['name'] as String,
      instruments:
          (json['instruments'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      notes: json['notes'] as String? ?? '',
      number: json['number'] as String? ?? '',
      isPrivate: json['private'] as bool? ?? false,
      tenantId: (json['tenantId'] as num?)?.toInt(),
      legacyId: (json['legacyId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$TeacherImplToJson(_$TeacherImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt?.toIso8601String(),
      'name': instance.name,
      'instruments': instance.instruments,
      'notes': instance.notes,
      'number': instance.number,
      'private': instance.isPrivate,
      'tenantId': instance.tenantId,
      'legacyId': instance.legacyId,
    };
