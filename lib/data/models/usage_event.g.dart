// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UsageEventImpl _$$UsageEventImplFromJson(Map<String, dynamic> json) =>
    _$UsageEventImpl(
      eventName: json['event_name'] as String,
      tenantId: (json['tenant_id'] as num?)?.toInt(),
      deviceType: json['device_type'] as String,
      properties:
          json['properties'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$UsageEventImplToJson(_$UsageEventImpl instance) =>
    <String, dynamic>{
      'event_name': instance.eventName,
      'tenant_id': instance.tenantId,
      'device_type': instance.deviceType,
      'properties': instance.properties,
    };
