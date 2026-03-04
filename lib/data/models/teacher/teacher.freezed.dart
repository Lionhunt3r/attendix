// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'teacher.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Teacher _$TeacherFromJson(Map<String, dynamic> json) {
  return _Teacher.fromJson(json);
}

/// @nodoc
mixin _$Teacher {
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<int> get instruments => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;
  String get number => throw _privateConstructorUsedError;
  @JsonKey(name: 'private')
  bool get isPrivate => throw _privateConstructorUsedError;
  int? get tenantId => throw _privateConstructorUsedError;
  int? get legacyId =>
      throw _privateConstructorUsedError; // Computed fields (not in DB)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get insNames => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? get playerCount => throw _privateConstructorUsedError;

  /// Serializes this Teacher to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeacherCopyWith<Teacher> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeacherCopyWith<$Res> {
  factory $TeacherCopyWith(Teacher value, $Res Function(Teacher) then) =
      _$TeacherCopyWithImpl<$Res, Teacher>;
  @useResult
  $Res call({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String name,
    List<int> instruments,
    String notes,
    String number,
    @JsonKey(name: 'private') bool isPrivate,
    int? tenantId,
    int? legacyId,
    @JsonKey(includeFromJson: false, includeToJson: false) String? insNames,
    @JsonKey(includeFromJson: false, includeToJson: false) int? playerCount,
  });
}

/// @nodoc
class _$TeacherCopyWithImpl<$Res, $Val extends Teacher>
    implements $TeacherCopyWith<$Res> {
  _$TeacherCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = freezed,
    Object? name = null,
    Object? instruments = null,
    Object? notes = null,
    Object? number = null,
    Object? isPrivate = null,
    Object? tenantId = freezed,
    Object? legacyId = freezed,
    Object? insNames = freezed,
    Object? playerCount = freezed,
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
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            instruments:
                null == instruments
                    ? _value.instruments
                    : instruments // ignore: cast_nullable_to_non_nullable
                        as List<int>,
            notes:
                null == notes
                    ? _value.notes
                    : notes // ignore: cast_nullable_to_non_nullable
                        as String,
            number:
                null == number
                    ? _value.number
                    : number // ignore: cast_nullable_to_non_nullable
                        as String,
            isPrivate:
                null == isPrivate
                    ? _value.isPrivate
                    : isPrivate // ignore: cast_nullable_to_non_nullable
                        as bool,
            tenantId:
                freezed == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as int?,
            legacyId:
                freezed == legacyId
                    ? _value.legacyId
                    : legacyId // ignore: cast_nullable_to_non_nullable
                        as int?,
            insNames:
                freezed == insNames
                    ? _value.insNames
                    : insNames // ignore: cast_nullable_to_non_nullable
                        as String?,
            playerCount:
                freezed == playerCount
                    ? _value.playerCount
                    : playerCount // ignore: cast_nullable_to_non_nullable
                        as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TeacherImplCopyWith<$Res> implements $TeacherCopyWith<$Res> {
  factory _$$TeacherImplCopyWith(
    _$TeacherImpl value,
    $Res Function(_$TeacherImpl) then,
  ) = __$$TeacherImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String name,
    List<int> instruments,
    String notes,
    String number,
    @JsonKey(name: 'private') bool isPrivate,
    int? tenantId,
    int? legacyId,
    @JsonKey(includeFromJson: false, includeToJson: false) String? insNames,
    @JsonKey(includeFromJson: false, includeToJson: false) int? playerCount,
  });
}

/// @nodoc
class __$$TeacherImplCopyWithImpl<$Res>
    extends _$TeacherCopyWithImpl<$Res, _$TeacherImpl>
    implements _$$TeacherImplCopyWith<$Res> {
  __$$TeacherImplCopyWithImpl(
    _$TeacherImpl _value,
    $Res Function(_$TeacherImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = freezed,
    Object? name = null,
    Object? instruments = null,
    Object? notes = null,
    Object? number = null,
    Object? isPrivate = null,
    Object? tenantId = freezed,
    Object? legacyId = freezed,
    Object? insNames = freezed,
    Object? playerCount = freezed,
  }) {
    return _then(
      _$TeacherImpl(
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
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        instruments:
            null == instruments
                ? _value._instruments
                : instruments // ignore: cast_nullable_to_non_nullable
                    as List<int>,
        notes:
            null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                    as String,
        number:
            null == number
                ? _value.number
                : number // ignore: cast_nullable_to_non_nullable
                    as String,
        isPrivate:
            null == isPrivate
                ? _value.isPrivate
                : isPrivate // ignore: cast_nullable_to_non_nullable
                    as bool,
        tenantId:
            freezed == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as int?,
        legacyId:
            freezed == legacyId
                ? _value.legacyId
                : legacyId // ignore: cast_nullable_to_non_nullable
                    as int?,
        insNames:
            freezed == insNames
                ? _value.insNames
                : insNames // ignore: cast_nullable_to_non_nullable
                    as String?,
        playerCount:
            freezed == playerCount
                ? _value.playerCount
                : playerCount // ignore: cast_nullable_to_non_nullable
                    as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TeacherImpl implements _Teacher {
  const _$TeacherImpl({
    this.id,
    @JsonKey(name: 'created_at') this.createdAt,
    required this.name,
    final List<int> instruments = const [],
    this.notes = '',
    this.number = '',
    @JsonKey(name: 'private') this.isPrivate = false,
    this.tenantId,
    this.legacyId,
    @JsonKey(includeFromJson: false, includeToJson: false) this.insNames,
    @JsonKey(includeFromJson: false, includeToJson: false) this.playerCount,
  }) : _instruments = instruments;

  factory _$TeacherImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeacherImplFromJson(json);

  @override
  final int? id;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  final String name;
  final List<int> _instruments;
  @override
  @JsonKey()
  List<int> get instruments {
    if (_instruments is EqualUnmodifiableListView) return _instruments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_instruments);
  }

  @override
  @JsonKey()
  final String notes;
  @override
  @JsonKey()
  final String number;
  @override
  @JsonKey(name: 'private')
  final bool isPrivate;
  @override
  final int? tenantId;
  @override
  final int? legacyId;
  // Computed fields (not in DB)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? insNames;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final int? playerCount;

  @override
  String toString() {
    return 'Teacher(id: $id, createdAt: $createdAt, name: $name, instruments: $instruments, notes: $notes, number: $number, isPrivate: $isPrivate, tenantId: $tenantId, legacyId: $legacyId, insNames: $insNames, playerCount: $playerCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeacherImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(
              other._instruments,
              _instruments,
            ) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.legacyId, legacyId) ||
                other.legacyId == legacyId) &&
            (identical(other.insNames, insNames) ||
                other.insNames == insNames) &&
            (identical(other.playerCount, playerCount) ||
                other.playerCount == playerCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    createdAt,
    name,
    const DeepCollectionEquality().hash(_instruments),
    notes,
    number,
    isPrivate,
    tenantId,
    legacyId,
    insNames,
    playerCount,
  );

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeacherImplCopyWith<_$TeacherImpl> get copyWith =>
      __$$TeacherImplCopyWithImpl<_$TeacherImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeacherImplToJson(this);
  }
}

abstract class _Teacher implements Teacher {
  const factory _Teacher({
    final int? id,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    required final String name,
    final List<int> instruments,
    final String notes,
    final String number,
    @JsonKey(name: 'private') final bool isPrivate,
    final int? tenantId,
    final int? legacyId,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final String? insNames,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final int? playerCount,
  }) = _$TeacherImpl;

  factory _Teacher.fromJson(Map<String, dynamic> json) = _$TeacherImpl.fromJson;

  @override
  int? get id;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  String get name;
  @override
  List<int> get instruments;
  @override
  String get notes;
  @override
  String get number;
  @override
  @JsonKey(name: 'private')
  bool get isPrivate;
  @override
  int? get tenantId;
  @override
  int? get legacyId; // Computed fields (not in DB)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get insNames;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? get playerCount;

  /// Create a copy of Teacher
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeacherImplCopyWith<_$TeacherImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
