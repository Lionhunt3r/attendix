// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'viewer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Viewer _$ViewerFromJson(Map<String, dynamic> json) {
  return _Viewer.fromJson(json);
}

/// @nodoc
mixin _$Viewer {
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String get appId => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  int? get tenantId => throw _privateConstructorUsedError;

  /// Serializes this Viewer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Viewer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ViewerCopyWith<Viewer> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViewerCopyWith<$Res> {
  factory $ViewerCopyWith(Viewer value, $Res Function(Viewer) then) =
      _$ViewerCopyWithImpl<$Res, Viewer>;
  @useResult
  $Res call({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String appId,
    String email,
    String firstName,
    String lastName,
    int? tenantId,
  });
}

/// @nodoc
class _$ViewerCopyWithImpl<$Res, $Val extends Viewer>
    implements $ViewerCopyWith<$Res> {
  _$ViewerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Viewer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = freezed,
    Object? appId = null,
    Object? email = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? tenantId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                freezed == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as int?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            appId:
                null == appId
                    ? _value.appId
                    : appId // ignore: cast_nullable_to_non_nullable
                        as String,
            email:
                null == email
                    ? _value.email
                    : email // ignore: cast_nullable_to_non_nullable
                        as String,
            firstName:
                null == firstName
                    ? _value.firstName
                    : firstName // ignore: cast_nullable_to_non_nullable
                        as String,
            lastName:
                null == lastName
                    ? _value.lastName
                    : lastName // ignore: cast_nullable_to_non_nullable
                        as String,
            tenantId:
                freezed == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ViewerImplCopyWith<$Res> implements $ViewerCopyWith<$Res> {
  factory _$$ViewerImplCopyWith(
    _$ViewerImpl value,
    $Res Function(_$ViewerImpl) then,
  ) = __$$ViewerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String appId,
    String email,
    String firstName,
    String lastName,
    int? tenantId,
  });
}

/// @nodoc
class __$$ViewerImplCopyWithImpl<$Res>
    extends _$ViewerCopyWithImpl<$Res, _$ViewerImpl>
    implements _$$ViewerImplCopyWith<$Res> {
  __$$ViewerImplCopyWithImpl(
    _$ViewerImpl _value,
    $Res Function(_$ViewerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Viewer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = freezed,
    Object? appId = null,
    Object? email = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? tenantId = freezed,
  }) {
    return _then(
      _$ViewerImpl(
        id:
            freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as int?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        appId:
            null == appId
                ? _value.appId
                : appId // ignore: cast_nullable_to_non_nullable
                    as String,
        email:
            null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                    as String,
        firstName:
            null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                    as String,
        lastName:
            null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                    as String,
        tenantId:
            freezed == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ViewerImpl implements _Viewer {
  const _$ViewerImpl({
    this.id,
    @JsonKey(name: 'created_at') this.createdAt,
    required this.appId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.tenantId,
  });

  factory _$ViewerImpl.fromJson(Map<String, dynamic> json) =>
      _$$ViewerImplFromJson(json);

  @override
  final int? id;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  final String appId;
  @override
  final String email;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final int? tenantId;

  @override
  String toString() {
    return 'Viewer(id: $id, createdAt: $createdAt, appId: $appId, email: $email, firstName: $firstName, lastName: $lastName, tenantId: $tenantId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ViewerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.appId, appId) || other.appId == appId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    createdAt,
    appId,
    email,
    firstName,
    lastName,
    tenantId,
  );

  /// Create a copy of Viewer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ViewerImplCopyWith<_$ViewerImpl> get copyWith =>
      __$$ViewerImplCopyWithImpl<_$ViewerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ViewerImplToJson(this);
  }
}

abstract class _Viewer implements Viewer {
  const factory _Viewer({
    final int? id,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    required final String appId,
    required final String email,
    required final String firstName,
    required final String lastName,
    final int? tenantId,
  }) = _$ViewerImpl;

  factory _Viewer.fromJson(Map<String, dynamic> json) = _$ViewerImpl.fromJson;

  @override
  int? get id;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  String get appId;
  @override
  String get email;
  @override
  String get firstName;
  @override
  String get lastName;
  @override
  int? get tenantId;

  /// Create a copy of Viewer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ViewerImplCopyWith<_$ViewerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
