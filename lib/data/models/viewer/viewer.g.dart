// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ViewerImpl _$$ViewerImplFromJson(Map<String, dynamic> json) => _$ViewerImpl(
  id: (json['id'] as num?)?.toInt(),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  appId: json['appId'] as String,
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  tenantId: (json['tenantId'] as num?)?.toInt(),
);

Map<String, dynamic> _$$ViewerImplToJson(_$ViewerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_at': instance.createdAt?.toIso8601String(),
      'appId': instance.appId,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'tenantId': instance.tenantId,
    };
