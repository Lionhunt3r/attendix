// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_instance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ShiftInstance _$ShiftInstanceFromJson(Map<String, dynamic> json) {
  return _ShiftInstance.fromJson(json);
}

/// @nodoc
mixin _$ShiftInstance {
  String get date => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this ShiftInstance to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShiftInstance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShiftInstanceCopyWith<ShiftInstance> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShiftInstanceCopyWith<$Res> {
  factory $ShiftInstanceCopyWith(
    ShiftInstance value,
    $Res Function(ShiftInstance) then,
  ) = _$ShiftInstanceCopyWithImpl<$Res, ShiftInstance>;
  @useResult
  $Res call({String date, String name});
}

/// @nodoc
class _$ShiftInstanceCopyWithImpl<$Res, $Val extends ShiftInstance>
    implements $ShiftInstanceCopyWith<$Res> {
  _$ShiftInstanceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShiftInstance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? date = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            date:
                null == date
                    ? _value.date
                    : date // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShiftInstanceImplCopyWith<$Res>
    implements $ShiftInstanceCopyWith<$Res> {
  factory _$$ShiftInstanceImplCopyWith(
    _$ShiftInstanceImpl value,
    $Res Function(_$ShiftInstanceImpl) then,
  ) = __$$ShiftInstanceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String date, String name});
}

/// @nodoc
class __$$ShiftInstanceImplCopyWithImpl<$Res>
    extends _$ShiftInstanceCopyWithImpl<$Res, _$ShiftInstanceImpl>
    implements _$$ShiftInstanceImplCopyWith<$Res> {
  __$$ShiftInstanceImplCopyWithImpl(
    _$ShiftInstanceImpl _value,
    $Res Function(_$ShiftInstanceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShiftInstance
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? date = null, Object? name = null}) {
    return _then(
      _$ShiftInstanceImpl(
        date:
            null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShiftInstanceImpl implements _ShiftInstance {
  const _$ShiftInstanceImpl({required this.date, required this.name});

  factory _$ShiftInstanceImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShiftInstanceImplFromJson(json);

  @override
  final String date;
  @override
  final String name;

  @override
  String toString() {
    return 'ShiftInstance(date: $date, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShiftInstanceImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, name);

  /// Create a copy of ShiftInstance
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShiftInstanceImplCopyWith<_$ShiftInstanceImpl> get copyWith =>
      __$$ShiftInstanceImplCopyWithImpl<_$ShiftInstanceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShiftInstanceImplToJson(this);
  }
}

abstract class _ShiftInstance implements ShiftInstance {
  const factory _ShiftInstance({
    required final String date,
    required final String name,
  }) = _$ShiftInstanceImpl;

  factory _ShiftInstance.fromJson(Map<String, dynamic> json) =
      _$ShiftInstanceImpl.fromJson;

  @override
  String get date;
  @override
  String get name;

  /// Create a copy of ShiftInstance
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShiftInstanceImplCopyWith<_$ShiftInstanceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
