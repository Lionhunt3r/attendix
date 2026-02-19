// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instrument.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InstrumentImpl _$$InstrumentImplFromJson(Map<String, dynamic> json) =>
    _$InstrumentImpl(
      id: (json['id'] as num?)?.toInt(),
      tenantId: (json['tenantId'] as num?)?.toInt(),
      name: json['name'] as String,
      shortName: json['shortName'] as String?,
      color: json['color'] as String?,
      isSection: json['isSection'] as bool? ?? false,
      sectionIndex: (json['sectionIndex'] as num?)?.toInt(),
      parentId: (json['parentId'] as num?)?.toInt(),
      legacyId: (json['legacyId'] as num?)?.toInt(),
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$InstrumentImplToJson(_$InstrumentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'shortName': instance.shortName,
      'color': instance.color,
      'isSection': instance.isSection,
      'sectionIndex': instance.sectionIndex,
      'parentId': instance.parentId,
      'legacyId': instance.legacyId,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_$GroupImpl _$$GroupImplFromJson(Map<String, dynamic> json) => _$GroupImpl(
  id: (json['id'] as num?)?.toInt(),
  tenantId: (json['tenantId'] as num?)?.toInt(),
  name: json['name'] as String,
  shortName: json['shortName'] as String?,
  color: json['color'] as String?,
  index: (json['index'] as num?)?.toInt(),
  categoryId: (json['category_id'] as num?)?.toInt(),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$GroupImplToJson(_$GroupImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'shortName': instance.shortName,
      'color': instance.color,
      'index': instance.index,
      'category_id': instance.categoryId,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_$GroupCategoryImpl _$$GroupCategoryImplFromJson(Map<String, dynamic> json) =>
    _$GroupCategoryImpl(
      id: (json['id'] as num?)?.toInt(),
      tenantId: (json['tenantId'] as num?)?.toInt(),
      name: json['name'] as String,
      index: (json['index'] as num?)?.toInt(),
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$GroupCategoryImplToJson(_$GroupCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'index': instance.index,
      'created_at': instance.createdAt?.toIso8601String(),
    };
