// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ShiftDefinition _$ShiftDefinitionFromJson(Map<String, dynamic> json) {
  return _ShiftDefinition.fromJson(json);
}

/// @nodoc
mixin _$ShiftDefinition {
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  String get startTime => throw _privateConstructorUsedError;
  double get duration => throw _privateConstructorUsedError;
  bool get free => throw _privateConstructorUsedError;
  @JsonKey(name: 'index')
  int get index => throw _privateConstructorUsedError;
  @JsonKey(name: 'repeat_count')
  int get repeatCount => throw _privateConstructorUsedError;

  /// Serializes this ShiftDefinition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShiftDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShiftDefinitionCopyWith<ShiftDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShiftDefinitionCopyWith<$Res> {
  factory $ShiftDefinitionCopyWith(
    ShiftDefinition value,
    $Res Function(ShiftDefinition) then,
  ) = _$ShiftDefinitionCopyWithImpl<$Res, ShiftDefinition>;
  @useResult
  $Res call({
    int? id,
    @JsonKey(name: 'start_time') String startTime,
    double duration,
    bool free,
    @JsonKey(name: 'index') int index,
    @JsonKey(name: 'repeat_count') int repeatCount,
  });
}

/// @nodoc
class _$ShiftDefinitionCopyWithImpl<$Res, $Val extends ShiftDefinition>
    implements $ShiftDefinitionCopyWith<$Res> {
  _$ShiftDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShiftDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? startTime = null,
    Object? duration = null,
    Object? free = null,
    Object? index = null,
    Object? repeatCount = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                freezed == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as int?,
            startTime:
                null == startTime
                    ? _value.startTime
                    : startTime // ignore: cast_nullable_to_non_nullable
                        as String,
            duration:
                null == duration
                    ? _value.duration
                    : duration // ignore: cast_nullable_to_non_nullable
                        as double,
            free:
                null == free
                    ? _value.free
                    : free // ignore: cast_nullable_to_non_nullable
                        as bool,
            index:
                null == index
                    ? _value.index
                    : index // ignore: cast_nullable_to_non_nullable
                        as int,
            repeatCount:
                null == repeatCount
                    ? _value.repeatCount
                    : repeatCount // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShiftDefinitionImplCopyWith<$Res>
    implements $ShiftDefinitionCopyWith<$Res> {
  factory _$$ShiftDefinitionImplCopyWith(
    _$ShiftDefinitionImpl value,
    $Res Function(_$ShiftDefinitionImpl) then,
  ) = __$$ShiftDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    @JsonKey(name: 'start_time') String startTime,
    double duration,
    bool free,
    @JsonKey(name: 'index') int index,
    @JsonKey(name: 'repeat_count') int repeatCount,
  });
}

/// @nodoc
class __$$ShiftDefinitionImplCopyWithImpl<$Res>
    extends _$ShiftDefinitionCopyWithImpl<$Res, _$ShiftDefinitionImpl>
    implements _$$ShiftDefinitionImplCopyWith<$Res> {
  __$$ShiftDefinitionImplCopyWithImpl(
    _$ShiftDefinitionImpl _value,
    $Res Function(_$ShiftDefinitionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShiftDefinition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? startTime = null,
    Object? duration = null,
    Object? free = null,
    Object? index = null,
    Object? repeatCount = null,
  }) {
    return _then(
      _$ShiftDefinitionImpl(
        id:
            freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as int?,
        startTime:
            null == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                    as String,
        duration:
            null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                    as double,
        free:
            null == free
                ? _value.free
                : free // ignore: cast_nullable_to_non_nullable
                    as bool,
        index:
            null == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                    as int,
        repeatCount:
            null == repeatCount
                ? _value.repeatCount
                : repeatCount // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShiftDefinitionImpl implements _ShiftDefinition {
  const _$ShiftDefinitionImpl({
    this.id,
    @JsonKey(name: 'start_time') this.startTime = '08:00',
    this.duration = 8.0,
    this.free = false,
    @JsonKey(name: 'index') this.index = 0,
    @JsonKey(name: 'repeat_count') this.repeatCount = 1,
  });

  factory _$ShiftDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShiftDefinitionImplFromJson(json);

  @override
  final int? id;
  @override
  @JsonKey(name: 'start_time')
  final String startTime;
  @override
  @JsonKey()
  final double duration;
  @override
  @JsonKey()
  final bool free;
  @override
  @JsonKey(name: 'index')
  final int index;
  @override
  @JsonKey(name: 'repeat_count')
  final int repeatCount;

  @override
  String toString() {
    return 'ShiftDefinition(id: $id, startTime: $startTime, duration: $duration, free: $free, index: $index, repeatCount: $repeatCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShiftDefinitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.free, free) || other.free == free) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.repeatCount, repeatCount) ||
                other.repeatCount == repeatCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    startTime,
    duration,
    free,
    index,
    repeatCount,
  );

  /// Create a copy of ShiftDefinition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShiftDefinitionImplCopyWith<_$ShiftDefinitionImpl> get copyWith =>
      __$$ShiftDefinitionImplCopyWithImpl<_$ShiftDefinitionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ShiftDefinitionImplToJson(this);
  }
}

abstract class _ShiftDefinition implements ShiftDefinition {
  const factory _ShiftDefinition({
    final int? id,
    @JsonKey(name: 'start_time') final String startTime,
    final double duration,
    final bool free,
    @JsonKey(name: 'index') final int index,
    @JsonKey(name: 'repeat_count') final int repeatCount,
  }) = _$ShiftDefinitionImpl;

  factory _ShiftDefinition.fromJson(Map<String, dynamic> json) =
      _$ShiftDefinitionImpl.fromJson;

  @override
  int? get id;
  @override
  @JsonKey(name: 'start_time')
  String get startTime;
  @override
  double get duration;
  @override
  bool get free;
  @override
  @JsonKey(name: 'index')
  int get index;
  @override
  @JsonKey(name: 'repeat_count')
  int get repeatCount;

  /// Create a copy of ShiftDefinition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShiftDefinitionImplCopyWith<_$ShiftDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
