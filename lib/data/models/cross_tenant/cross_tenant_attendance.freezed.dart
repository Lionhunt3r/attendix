// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cross_tenant_attendance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CrossTenantPersonAttendance _$CrossTenantPersonAttendanceFromJson(
  Map<String, dynamic> json,
) {
  return _CrossTenantPersonAttendance.fromJson(json);
}

/// @nodoc
mixin _$CrossTenantPersonAttendance {
  /// The base attendance record
  PersonAttendance get attendance => throw _privateConstructorUsedError;

  /// Tenant ID this attendance belongs to
  int get tenantId => throw _privateConstructorUsedError;

  /// Display name of the tenant (shortName or longName)
  String get tenantName => throw _privateConstructorUsedError;

  /// Deterministic color for UI differentiation
  String get tenantColor => throw _privateConstructorUsedError;

  /// Optional: Attendance type configuration for this tenant
  AttendanceType? get attendanceType => throw _privateConstructorUsedError;

  /// Date string for sorting (from the attendance record)
  String? get date => throw _privateConstructorUsedError;

  /// Start time of the attendance
  String? get startTime => throw _privateConstructorUsedError;

  /// End time of the attendance
  String? get endTime => throw _privateConstructorUsedError;

  /// Title/description of the attendance
  String? get title => throw _privateConstructorUsedError;

  /// Serializes this CrossTenantPersonAttendance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CrossTenantPersonAttendance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CrossTenantPersonAttendanceCopyWith<CrossTenantPersonAttendance>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CrossTenantPersonAttendanceCopyWith<$Res> {
  factory $CrossTenantPersonAttendanceCopyWith(
    CrossTenantPersonAttendance value,
    $Res Function(CrossTenantPersonAttendance) then,
  ) =
      _$CrossTenantPersonAttendanceCopyWithImpl<
        $Res,
        CrossTenantPersonAttendance
      >;
  @useResult
  $Res call({
    PersonAttendance attendance,
    int tenantId,
    String tenantName,
    String tenantColor,
    AttendanceType? attendanceType,
    String? date,
    String? startTime,
    String? endTime,
    String? title,
  });

  $PersonAttendanceCopyWith<$Res> get attendance;
  $AttendanceTypeCopyWith<$Res>? get attendanceType;
}

/// @nodoc
class _$CrossTenantPersonAttendanceCopyWithImpl<
  $Res,
  $Val extends CrossTenantPersonAttendance
>
    implements $CrossTenantPersonAttendanceCopyWith<$Res> {
  _$CrossTenantPersonAttendanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CrossTenantPersonAttendance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attendance = null,
    Object? tenantId = null,
    Object? tenantName = null,
    Object? tenantColor = null,
    Object? attendanceType = freezed,
    Object? date = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? title = freezed,
  }) {
    return _then(
      _value.copyWith(
            attendance:
                null == attendance
                    ? _value.attendance
                    : attendance // ignore: cast_nullable_to_non_nullable
                        as PersonAttendance,
            tenantId:
                null == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as int,
            tenantName:
                null == tenantName
                    ? _value.tenantName
                    : tenantName // ignore: cast_nullable_to_non_nullable
                        as String,
            tenantColor:
                null == tenantColor
                    ? _value.tenantColor
                    : tenantColor // ignore: cast_nullable_to_non_nullable
                        as String,
            attendanceType:
                freezed == attendanceType
                    ? _value.attendanceType
                    : attendanceType // ignore: cast_nullable_to_non_nullable
                        as AttendanceType?,
            date:
                freezed == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as String?,
            startTime:
                freezed == startTime
                    ? _value.startTime
                    : startTime // ignore: cast_nullable_to_non_nullable
                        as String?,
            endTime:
                freezed == endTime
                    ? _value.endTime
                    : endTime // ignore: cast_nullable_to_non_nullable
                        as String?,
            title:
                freezed == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of CrossTenantPersonAttendance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PersonAttendanceCopyWith<$Res> get attendance {
    return $PersonAttendanceCopyWith<$Res>(_value.attendance, (value) {
      return _then(_value.copyWith(attendance: value) as $Val);
    });
  }

  /// Create a copy of CrossTenantPersonAttendance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AttendanceTypeCopyWith<$Res>? get attendanceType {
    if (_value.attendanceType == null) {
      return null;
    }

    return $AttendanceTypeCopyWith<$Res>(_value.attendanceType!, (value) {
      return _then(_value.copyWith(attendanceType: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CrossTenantPersonAttendanceImplCopyWith<$Res>
    implements $CrossTenantPersonAttendanceCopyWith<$Res> {
  factory _$$CrossTenantPersonAttendanceImplCopyWith(
    _$CrossTenantPersonAttendanceImpl value,
    $Res Function(_$CrossTenantPersonAttendanceImpl) then,
  ) = __$$CrossTenantPersonAttendanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    PersonAttendance attendance,
    int tenantId,
    String tenantName,
    String tenantColor,
    AttendanceType? attendanceType,
    String? date,
    String? startTime,
    String? endTime,
    String? title,
  });

  @override
  $PersonAttendanceCopyWith<$Res> get attendance;
  @override
  $AttendanceTypeCopyWith<$Res>? get attendanceType;
}

/// @nodoc
class __$$CrossTenantPersonAttendanceImplCopyWithImpl<$Res>
    extends
        _$CrossTenantPersonAttendanceCopyWithImpl<
          $Res,
          _$CrossTenantPersonAttendanceImpl
        >
    implements _$$CrossTenantPersonAttendanceImplCopyWith<$Res> {
  __$$CrossTenantPersonAttendanceImplCopyWithImpl(
    _$CrossTenantPersonAttendanceImpl _value,
    $Res Function(_$CrossTenantPersonAttendanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CrossTenantPersonAttendance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? attendance = null,
    Object? tenantId = null,
    Object? tenantName = null,
    Object? tenantColor = null,
    Object? attendanceType = freezed,
    Object? date = freezed,
    Object? startTime = freezed,
    Object? endTime = freezed,
    Object? title = freezed,
  }) {
    return _then(
      _$CrossTenantPersonAttendanceImpl(
        attendance:
            null == attendance
                ? _value.attendance
                : attendance // ignore: cast_nullable_to_non_nullable
                    as PersonAttendance,
        tenantId:
            null == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as int,
        tenantName:
            null == tenantName
                ? _value.tenantName
                : tenantName // ignore: cast_nullable_to_non_nullable
                    as String,
        tenantColor:
            null == tenantColor
                ? _value.tenantColor
                : tenantColor // ignore: cast_nullable_to_non_nullable
                    as String,
        attendanceType:
            freezed == attendanceType
                ? _value.attendanceType
                : attendanceType // ignore: cast_nullable_to_non_nullable
                    as AttendanceType?,
        date:
            freezed == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as String?,
        startTime:
            freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                    as String?,
        endTime:
            freezed == endTime
                ? _value.endTime
                : endTime // ignore: cast_nullable_to_non_nullable
                    as String?,
        title:
            freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CrossTenantPersonAttendanceImpl
    implements _CrossTenantPersonAttendance {
  const _$CrossTenantPersonAttendanceImpl({
    required this.attendance,
    required this.tenantId,
    required this.tenantName,
    required this.tenantColor,
    this.attendanceType,
    this.date,
    this.startTime,
    this.endTime,
    this.title,
  });

  factory _$CrossTenantPersonAttendanceImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$CrossTenantPersonAttendanceImplFromJson(json);

  /// The base attendance record
  @override
  final PersonAttendance attendance;

  /// Tenant ID this attendance belongs to
  @override
  final int tenantId;

  /// Display name of the tenant (shortName or longName)
  @override
  final String tenantName;

  /// Deterministic color for UI differentiation
  @override
  final String tenantColor;

  /// Optional: Attendance type configuration for this tenant
  @override
  final AttendanceType? attendanceType;

  /// Date string for sorting (from the attendance record)
  @override
  final String? date;

  /// Start time of the attendance
  @override
  final String? startTime;

  /// End time of the attendance
  @override
  final String? endTime;

  /// Title/description of the attendance
  @override
  final String? title;

  @override
  String toString() {
    return 'CrossTenantPersonAttendance(attendance: $attendance, tenantId: $tenantId, tenantName: $tenantName, tenantColor: $tenantColor, attendanceType: $attendanceType, date: $date, startTime: $startTime, endTime: $endTime, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CrossTenantPersonAttendanceImpl &&
            (identical(other.attendance, attendance) ||
                other.attendance == attendance) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.tenantName, tenantName) ||
                other.tenantName == tenantName) &&
            (identical(other.tenantColor, tenantColor) ||
                other.tenantColor == tenantColor) &&
            (identical(other.attendanceType, attendanceType) ||
                other.attendanceType == attendanceType) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.title, title) || other.title == title));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    attendance,
    tenantId,
    tenantName,
    tenantColor,
    attendanceType,
    date,
    startTime,
    endTime,
    title,
  );

  /// Create a copy of CrossTenantPersonAttendance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CrossTenantPersonAttendanceImplCopyWith<_$CrossTenantPersonAttendanceImpl>
  get copyWith => __$$CrossTenantPersonAttendanceImplCopyWithImpl<
    _$CrossTenantPersonAttendanceImpl
  >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CrossTenantPersonAttendanceImplToJson(this);
  }
}

abstract class _CrossTenantPersonAttendance
    implements CrossTenantPersonAttendance {
  const factory _CrossTenantPersonAttendance({
    required final PersonAttendance attendance,
    required final int tenantId,
    required final String tenantName,
    required final String tenantColor,
    final AttendanceType? attendanceType,
    final String? date,
    final String? startTime,
    final String? endTime,
    final String? title,
  }) = _$CrossTenantPersonAttendanceImpl;

  factory _CrossTenantPersonAttendance.fromJson(Map<String, dynamic> json) =
      _$CrossTenantPersonAttendanceImpl.fromJson;

  /// The base attendance record
  @override
  PersonAttendance get attendance;

  /// Tenant ID this attendance belongs to
  @override
  int get tenantId;

  /// Display name of the tenant (shortName or longName)
  @override
  String get tenantName;

  /// Deterministic color for UI differentiation
  @override
  String get tenantColor;

  /// Optional: Attendance type configuration for this tenant
  @override
  AttendanceType? get attendanceType;

  /// Date string for sorting (from the attendance record)
  @override
  String? get date;

  /// Start time of the attendance
  @override
  String? get startTime;

  /// End time of the attendance
  @override
  String? get endTime;

  /// Title/description of the attendance
  @override
  String? get title;

  /// Create a copy of CrossTenantPersonAttendance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CrossTenantPersonAttendanceImplCopyWith<_$CrossTenantPersonAttendanceImpl>
  get copyWith => throw _privateConstructorUsedError;
}
