// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShiftPlanImpl _$$ShiftPlanImplFromJson(Map<String, dynamic> json) =>
    _$ShiftPlanImpl(
      id: json['id'] as String?,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      tenantId: (json['tenant_id'] as num?)?.toInt(),
      definition:
          json['definition'] == null
              ? const []
              : const _ShiftDefinitionListConverter().fromJson(
                json['definition'],
              ),
      shifts:
          json['shifts'] == null
              ? const []
              : const _ShiftInstanceListConverter().fromJson(json['shifts']),
    );

Map<String, dynamic> _$$ShiftPlanImplToJson(_$ShiftPlanImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt?.toIso8601String(),
      'name': instance.name,
      'description': instance.description,
      'tenant_id': instance.tenantId,
      'definition': const _ShiftDefinitionListConverter().toJson(
        instance.definition,
      ),
      'shifts': const _ShiftInstanceListConverter().toJson(instance.shifts),
    };
