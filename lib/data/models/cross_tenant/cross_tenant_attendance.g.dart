// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cross_tenant_attendance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CrossTenantPersonAttendanceImpl _$$CrossTenantPersonAttendanceImplFromJson(
  Map<String, dynamic> json,
) => _$CrossTenantPersonAttendanceImpl(
  attendance: PersonAttendance.fromJson(
    json['attendance'] as Map<String, dynamic>,
  ),
  tenantId: (json['tenantId'] as num).toInt(),
  tenantName: json['tenantName'] as String,
  tenantColor: json['tenantColor'] as String,
  attendanceType:
      json['attendanceType'] == null
          ? null
          : AttendanceType.fromJson(
            json['attendanceType'] as Map<String, dynamic>,
          ),
  date: json['date'] as String?,
  startTime: json['startTime'] as String?,
  endTime: json['endTime'] as String?,
  title: json['title'] as String?,
);

Map<String, dynamic> _$$CrossTenantPersonAttendanceImplToJson(
  _$CrossTenantPersonAttendanceImpl instance,
) => <String, dynamic>{
  'attendance': instance.attendance,
  'tenantId': instance.tenantId,
  'tenantName': instance.tenantName,
  'tenantColor': instance.tenantColor,
  'attendanceType': instance.attendanceType,
  'date': instance.date,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
  'title': instance.title,
};
