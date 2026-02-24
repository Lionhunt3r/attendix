// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'holiday_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HolidayData _$HolidayDataFromJson(Map<String, dynamic> json) {
  return _HolidayData.fromJson(json);
}

/// @nodoc
mixin _$HolidayData {
  List<Holiday> get publicHolidays => throw _privateConstructorUsedError;
  List<Holiday> get schoolHolidays => throw _privateConstructorUsedError;

  /// Serializes this HolidayData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HolidayData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HolidayDataCopyWith<HolidayData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HolidayDataCopyWith<$Res> {
  factory $HolidayDataCopyWith(
    HolidayData value,
    $Res Function(HolidayData) then,
  ) = _$HolidayDataCopyWithImpl<$Res, HolidayData>;
  @useResult
  $Res call({List<Holiday> publicHolidays, List<Holiday> schoolHolidays});
}

/// @nodoc
class _$HolidayDataCopyWithImpl<$Res, $Val extends HolidayData>
    implements $HolidayDataCopyWith<$Res> {
  _$HolidayDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HolidayData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? publicHolidays = null, Object? schoolHolidays = null}) {
    return _then(
      _value.copyWith(
            publicHolidays:
                null == publicHolidays
                    ? _value.publicHolidays
                    : publicHolidays // ignore: cast_nullable_to_non_nullable
                        as List<Holiday>,
            schoolHolidays:
                null == schoolHolidays
                    ? _value.schoolHolidays
                    : schoolHolidays // ignore: cast_nullable_to_non_nullable
                        as List<Holiday>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HolidayDataImplCopyWith<$Res>
    implements $HolidayDataCopyWith<$Res> {
  factory _$$HolidayDataImplCopyWith(
    _$HolidayDataImpl value,
    $Res Function(_$HolidayDataImpl) then,
  ) = __$$HolidayDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Holiday> publicHolidays, List<Holiday> schoolHolidays});
}

/// @nodoc
class __$$HolidayDataImplCopyWithImpl<$Res>
    extends _$HolidayDataCopyWithImpl<$Res, _$HolidayDataImpl>
    implements _$$HolidayDataImplCopyWith<$Res> {
  __$$HolidayDataImplCopyWithImpl(
    _$HolidayDataImpl _value,
    $Res Function(_$HolidayDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HolidayData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? publicHolidays = null, Object? schoolHolidays = null}) {
    return _then(
      _$HolidayDataImpl(
        publicHolidays:
            null == publicHolidays
                ? _value._publicHolidays
                : publicHolidays // ignore: cast_nullable_to_non_nullable
                    as List<Holiday>,
        schoolHolidays:
            null == schoolHolidays
                ? _value._schoolHolidays
                : schoolHolidays // ignore: cast_nullable_to_non_nullable
                    as List<Holiday>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HolidayDataImpl implements _HolidayData {
  const _$HolidayDataImpl({
    final List<Holiday> publicHolidays = const [],
    final List<Holiday> schoolHolidays = const [],
  }) : _publicHolidays = publicHolidays,
       _schoolHolidays = schoolHolidays;

  factory _$HolidayDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$HolidayDataImplFromJson(json);

  final List<Holiday> _publicHolidays;
  @override
  @JsonKey()
  List<Holiday> get publicHolidays {
    if (_publicHolidays is EqualUnmodifiableListView) return _publicHolidays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_publicHolidays);
  }

  final List<Holiday> _schoolHolidays;
  @override
  @JsonKey()
  List<Holiday> get schoolHolidays {
    if (_schoolHolidays is EqualUnmodifiableListView) return _schoolHolidays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_schoolHolidays);
  }

  @override
  String toString() {
    return 'HolidayData(publicHolidays: $publicHolidays, schoolHolidays: $schoolHolidays)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HolidayDataImpl &&
            const DeepCollectionEquality().equals(
              other._publicHolidays,
              _publicHolidays,
            ) &&
            const DeepCollectionEquality().equals(
              other._schoolHolidays,
              _schoolHolidays,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_publicHolidays),
    const DeepCollectionEquality().hash(_schoolHolidays),
  );

  /// Create a copy of HolidayData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HolidayDataImplCopyWith<_$HolidayDataImpl> get copyWith =>
      __$$HolidayDataImplCopyWithImpl<_$HolidayDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HolidayDataImplToJson(this);
  }
}

abstract class _HolidayData implements HolidayData {
  const factory _HolidayData({
    final List<Holiday> publicHolidays,
    final List<Holiday> schoolHolidays,
  }) = _$HolidayDataImpl;

  factory _HolidayData.fromJson(Map<String, dynamic> json) =
      _$HolidayDataImpl.fromJson;

  @override
  List<Holiday> get publicHolidays;
  @override
  List<Holiday> get schoolHolidays;

  /// Create a copy of HolidayData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HolidayDataImplCopyWith<_$HolidayDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Holiday _$HolidayFromJson(Map<String, dynamic> json) {
  return _Holiday.fromJson(json);
}

/// @nodoc
mixin _$Holiday {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  bool get isPast => throw _privateConstructorUsedError;

  /// Serializes this Holiday to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Holiday
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HolidayCopyWith<Holiday> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HolidayCopyWith<$Res> {
  factory $HolidayCopyWith(Holiday value, $Res Function(Holiday) then) =
      _$HolidayCopyWithImpl<$Res, Holiday>;
  @useResult
  $Res call({
    String id,
    String name,
    DateTime startDate,
    DateTime endDate,
    bool isPast,
  });
}

/// @nodoc
class _$HolidayCopyWithImpl<$Res, $Val extends Holiday>
    implements $HolidayCopyWith<$Res> {
  _$HolidayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Holiday
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? isPast = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            startDate:
                null == startDate
                    ? _value.startDate
                    : startDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            endDate:
                null == endDate
                    ? _value.endDate
                    : endDate // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            isPast:
                null == isPast
                    ? _value.isPast
                    : isPast // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HolidayImplCopyWith<$Res> implements $HolidayCopyWith<$Res> {
  factory _$$HolidayImplCopyWith(
    _$HolidayImpl value,
    $Res Function(_$HolidayImpl) then,
  ) = __$$HolidayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    DateTime startDate,
    DateTime endDate,
    bool isPast,
  });
}

/// @nodoc
class __$$HolidayImplCopyWithImpl<$Res>
    extends _$HolidayCopyWithImpl<$Res, _$HolidayImpl>
    implements _$$HolidayImplCopyWith<$Res> {
  __$$HolidayImplCopyWithImpl(
    _$HolidayImpl _value,
    $Res Function(_$HolidayImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Holiday
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? isPast = null,
  }) {
    return _then(
      _$HolidayImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        startDate:
            null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        endDate:
            null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        isPast:
            null == isPast
                ? _value.isPast
                : isPast // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HolidayImpl implements _Holiday {
  const _$HolidayImpl({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isPast = false,
  });

  factory _$HolidayImpl.fromJson(Map<String, dynamic> json) =>
      _$$HolidayImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  @JsonKey()
  final bool isPast;

  @override
  String toString() {
    return 'Holiday(id: $id, name: $name, startDate: $startDate, endDate: $endDate, isPast: $isPast)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HolidayImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.isPast, isPast) || other.isPast == isPast));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, startDate, endDate, isPast);

  /// Create a copy of Holiday
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HolidayImplCopyWith<_$HolidayImpl> get copyWith =>
      __$$HolidayImplCopyWithImpl<_$HolidayImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HolidayImplToJson(this);
  }
}

abstract class _Holiday implements Holiday {
  const factory _Holiday({
    required final String id,
    required final String name,
    required final DateTime startDate,
    required final DateTime endDate,
    final bool isPast,
  }) = _$HolidayImpl;

  factory _Holiday.fromJson(Map<String, dynamic> json) = _$HolidayImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  bool get isPast;

  /// Create a copy of Holiday
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HolidayImplCopyWith<_$HolidayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
