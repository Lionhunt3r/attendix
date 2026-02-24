// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holiday_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HolidayDataImpl _$$HolidayDataImplFromJson(Map<String, dynamic> json) =>
    _$HolidayDataImpl(
      publicHolidays:
          (json['publicHolidays'] as List<dynamic>?)
              ?.map((e) => Holiday.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      schoolHolidays:
          (json['schoolHolidays'] as List<dynamic>?)
              ?.map((e) => Holiday.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$HolidayDataImplToJson(_$HolidayDataImpl instance) =>
    <String, dynamic>{
      'publicHolidays': instance.publicHolidays,
      'schoolHolidays': instance.schoolHolidays,
    };

_$HolidayImpl _$$HolidayImplFromJson(Map<String, dynamic> json) =>
    _$HolidayImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isPast: json['isPast'] as bool? ?? false,
    );

Map<String, dynamic> _$$HolidayImplToJson(_$HolidayImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'isPast': instance.isPast,
    };
