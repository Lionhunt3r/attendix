// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'instrument.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Instrument _$InstrumentFromJson(Map<String, dynamic> json) {
  return _Instrument.fromJson(json);
}

/// @nodoc
mixin _$Instrument {
  int? get id => throw _privateConstructorUsedError;
  int? get tenantId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get shortName => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  bool get isSection => throw _privateConstructorUsedError;
  int? get sectionIndex => throw _privateConstructorUsedError;
  int? get parentId => throw _privateConstructorUsedError;
  int? get legacyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Instrument to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Instrument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InstrumentCopyWith<Instrument> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InstrumentCopyWith<$Res> {
  factory $InstrumentCopyWith(
    Instrument value,
    $Res Function(Instrument) then,
  ) = _$InstrumentCopyWithImpl<$Res, Instrument>;
  @useResult
  $Res call({
    int? id,
    int? tenantId,
    String name,
    String? shortName,
    String? color,
    bool isSection,
    int? sectionIndex,
    int? parentId,
    int? legacyId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$InstrumentCopyWithImpl<$Res, $Val extends Instrument>
    implements $InstrumentCopyWith<$Res> {
  _$InstrumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Instrument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? tenantId = freezed,
    Object? name = null,
    Object? shortName = freezed,
    Object? color = freezed,
    Object? isSection = null,
    Object? sectionIndex = freezed,
    Object? parentId = freezed,
    Object? legacyId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                freezed == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as int?,
            tenantId:
                freezed == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as int?,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            shortName:
                freezed == shortName
                    ? _value.shortName
                    : shortName // ignore: cast_nullable_to_non_nullable
                        as String?,
            color:
                freezed == color
                    ? _value.color
                    : color // ignore: cast_nullable_to_non_nullable
                        as String?,
            isSection:
                null == isSection
                    ? _value.isSection
                    : isSection // ignore: cast_nullable_to_non_nullable
                        as bool,
            sectionIndex:
                freezed == sectionIndex
                    ? _value.sectionIndex
                    : sectionIndex // ignore: cast_nullable_to_non_nullable
                        as int?,
            parentId:
                freezed == parentId
                    ? _value.parentId
                    : parentId // ignore: cast_nullable_to_non_nullable
                        as int?,
            legacyId:
                freezed == legacyId
                    ? _value.legacyId
                    : legacyId // ignore: cast_nullable_to_non_nullable
                        as int?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InstrumentImplCopyWith<$Res>
    implements $InstrumentCopyWith<$Res> {
  factory _$$InstrumentImplCopyWith(
    _$InstrumentImpl value,
    $Res Function(_$InstrumentImpl) then,
  ) = __$$InstrumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    int? tenantId,
    String name,
    String? shortName,
    String? color,
    bool isSection,
    int? sectionIndex,
    int? parentId,
    int? legacyId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$InstrumentImplCopyWithImpl<$Res>
    extends _$InstrumentCopyWithImpl<$Res, _$InstrumentImpl>
    implements _$$InstrumentImplCopyWith<$Res> {
  __$$InstrumentImplCopyWithImpl(
    _$InstrumentImpl _value,
    $Res Function(_$InstrumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Instrument
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? tenantId = freezed,
    Object? name = null,
    Object? shortName = freezed,
    Object? color = freezed,
    Object? isSection = null,
    Object? sectionIndex = freezed,
    Object? parentId = freezed,
    Object? legacyId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$InstrumentImpl(
        id:
            freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as int?,
        tenantId:
            freezed == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as int?,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        shortName:
            freezed == shortName
                ? _value.shortName
                : shortName // ignore: cast_nullable_to_non_nullable
                    as String?,
        color:
            freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                    as String?,
        isSection:
            null == isSection
                ? _value.isSection
                : isSection // ignore: cast_nullable_to_non_nullable
                    as bool,
        sectionIndex:
            freezed == sectionIndex
                ? _value.sectionIndex
                : sectionIndex // ignore: cast_nullable_to_non_nullable
                    as int?,
        parentId:
            freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                    as int?,
        legacyId:
            freezed == legacyId
                ? _value.legacyId
                : legacyId // ignore: cast_nullable_to_non_nullable
                    as int?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InstrumentImpl implements _Instrument {
  const _$InstrumentImpl({
    this.id,
    this.tenantId,
    required this.name,
    this.shortName,
    this.color,
    this.isSection = false,
    this.sectionIndex,
    this.parentId,
    this.legacyId,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$InstrumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$InstrumentImplFromJson(json);

  @override
  final int? id;
  @override
  final int? tenantId;
  @override
  final String name;
  @override
  final String? shortName;
  @override
  final String? color;
  @override
  @JsonKey()
  final bool isSection;
  @override
  final int? sectionIndex;
  @override
  final int? parentId;
  @override
  final int? legacyId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Instrument(id: $id, tenantId: $tenantId, name: $name, shortName: $shortName, color: $color, isSection: $isSection, sectionIndex: $sectionIndex, parentId: $parentId, legacyId: $legacyId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InstrumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isSection, isSection) ||
                other.isSection == isSection) &&
            (identical(other.sectionIndex, sectionIndex) ||
                other.sectionIndex == sectionIndex) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.legacyId, legacyId) ||
                other.legacyId == legacyId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tenantId,
    name,
    shortName,
    color,
    isSection,
    sectionIndex,
    parentId,
    legacyId,
    createdAt,
  );

  /// Create a copy of Instrument
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InstrumentImplCopyWith<_$InstrumentImpl> get copyWith =>
      __$$InstrumentImplCopyWithImpl<_$InstrumentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InstrumentImplToJson(this);
  }
}

abstract class _Instrument implements Instrument {
  const factory _Instrument({
    final int? id,
    final int? tenantId,
    required final String name,
    final String? shortName,
    final String? color,
    final bool isSection,
    final int? sectionIndex,
    final int? parentId,
    final int? legacyId,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$InstrumentImpl;

  factory _Instrument.fromJson(Map<String, dynamic> json) =
      _$InstrumentImpl.fromJson;

  @override
  int? get id;
  @override
  int? get tenantId;
  @override
  String get name;
  @override
  String? get shortName;
  @override
  String? get color;
  @override
  bool get isSection;
  @override
  int? get sectionIndex;
  @override
  int? get parentId;
  @override
  int? get legacyId;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Instrument
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InstrumentImplCopyWith<_$InstrumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Group _$GroupFromJson(Map<String, dynamic> json) {
  return _Group.fromJson(json);
}

/// @nodoc
mixin _$Group {
  int? get id => throw _privateConstructorUsedError;
  int? get tenantId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get shortName => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  int? get index => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_id')
  int? get categoryId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Group to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Group
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupCopyWith<Group> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCopyWith<$Res> {
  factory $GroupCopyWith(Group value, $Res Function(Group) then) =
      _$GroupCopyWithImpl<$Res, Group>;
  @useResult
  $Res call({
    int? id,
    int? tenantId,
    String name,
    String? shortName,
    String? color,
    int? index,
    @JsonKey(name: 'category_id') int? categoryId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$GroupCopyWithImpl<$Res, $Val extends Group>
    implements $GroupCopyWith<$Res> {
  _$GroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Group
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? tenantId = freezed,
    Object? name = null,
    Object? shortName = freezed,
    Object? color = freezed,
    Object? index = freezed,
    Object? categoryId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                freezed == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as int?,
            tenantId:
                freezed == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as int?,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            shortName:
                freezed == shortName
                    ? _value.shortName
                    : shortName // ignore: cast_nullable_to_non_nullable
                        as String?,
            color:
                freezed == color
                    ? _value.color
                    : color // ignore: cast_nullable_to_non_nullable
                        as String?,
            index:
                freezed == index
                    ? _value.index
                    : index // ignore: cast_nullable_to_non_nullable
                        as int?,
            categoryId:
                freezed == categoryId
                    ? _value.categoryId
                    : categoryId // ignore: cast_nullable_to_non_nullable
                        as int?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GroupImplCopyWith<$Res> implements $GroupCopyWith<$Res> {
  factory _$$GroupImplCopyWith(
    _$GroupImpl value,
    $Res Function(_$GroupImpl) then,
  ) = __$$GroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    int? tenantId,
    String name,
    String? shortName,
    String? color,
    int? index,
    @JsonKey(name: 'category_id') int? categoryId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$GroupImplCopyWithImpl<$Res>
    extends _$GroupCopyWithImpl<$Res, _$GroupImpl>
    implements _$$GroupImplCopyWith<$Res> {
  __$$GroupImplCopyWithImpl(
    _$GroupImpl _value,
    $Res Function(_$GroupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Group
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? tenantId = freezed,
    Object? name = null,
    Object? shortName = freezed,
    Object? color = freezed,
    Object? index = freezed,
    Object? categoryId = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$GroupImpl(
        id:
            freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as int?,
        tenantId:
            freezed == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as int?,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        shortName:
            freezed == shortName
                ? _value.shortName
                : shortName // ignore: cast_nullable_to_non_nullable
                    as String?,
        color:
            freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                    as String?,
        index:
            freezed == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                    as int?,
        categoryId:
            freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                    as int?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupImpl implements _Group {
  const _$GroupImpl({
    this.id,
    this.tenantId,
    required this.name,
    this.shortName,
    this.color,
    this.index,
    @JsonKey(name: 'category_id') this.categoryId,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$GroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupImplFromJson(json);

  @override
  final int? id;
  @override
  final int? tenantId;
  @override
  final String name;
  @override
  final String? shortName;
  @override
  final String? color;
  @override
  final int? index;
  @override
  @JsonKey(name: 'category_id')
  final int? categoryId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Group(id: $id, tenantId: $tenantId, name: $name, shortName: $shortName, color: $color, index: $index, categoryId: $categoryId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.shortName, shortName) ||
                other.shortName == shortName) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    tenantId,
    name,
    shortName,
    color,
    index,
    categoryId,
    createdAt,
  );

  /// Create a copy of Group
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupImplCopyWith<_$GroupImpl> get copyWith =>
      __$$GroupImplCopyWithImpl<_$GroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupImplToJson(this);
  }
}

abstract class _Group implements Group {
  const factory _Group({
    final int? id,
    final int? tenantId,
    required final String name,
    final String? shortName,
    final String? color,
    final int? index,
    @JsonKey(name: 'category_id') final int? categoryId,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$GroupImpl;

  factory _Group.fromJson(Map<String, dynamic> json) = _$GroupImpl.fromJson;

  @override
  int? get id;
  @override
  int? get tenantId;
  @override
  String get name;
  @override
  String? get shortName;
  @override
  String? get color;
  @override
  int? get index;
  @override
  @JsonKey(name: 'category_id')
  int? get categoryId;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Group
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupImplCopyWith<_$GroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupCategory _$GroupCategoryFromJson(Map<String, dynamic> json) {
  return _GroupCategory.fromJson(json);
}

/// @nodoc
mixin _$GroupCategory {
  int? get id => throw _privateConstructorUsedError;
  int? get tenantId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int? get index => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this GroupCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupCategoryCopyWith<GroupCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupCategoryCopyWith<$Res> {
  factory $GroupCategoryCopyWith(
    GroupCategory value,
    $Res Function(GroupCategory) then,
  ) = _$GroupCategoryCopyWithImpl<$Res, GroupCategory>;
  @useResult
  $Res call({
    int? id,
    int? tenantId,
    String name,
    int? index,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$GroupCategoryCopyWithImpl<$Res, $Val extends GroupCategory>
    implements $GroupCategoryCopyWith<$Res> {
  _$GroupCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? tenantId = freezed,
    Object? name = null,
    Object? index = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                freezed == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as int?,
            tenantId:
                freezed == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as int?,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            index:
                freezed == index
                    ? _value.index
                    : index // ignore: cast_nullable_to_non_nullable
                        as int?,
            createdAt:
                freezed == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GroupCategoryImplCopyWith<$Res>
    implements $GroupCategoryCopyWith<$Res> {
  factory _$$GroupCategoryImplCopyWith(
    _$GroupCategoryImpl value,
    $Res Function(_$GroupCategoryImpl) then,
  ) = __$$GroupCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    int? tenantId,
    String name,
    int? index,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$GroupCategoryImplCopyWithImpl<$Res>
    extends _$GroupCategoryCopyWithImpl<$Res, _$GroupCategoryImpl>
    implements _$$GroupCategoryImplCopyWith<$Res> {
  __$$GroupCategoryImplCopyWithImpl(
    _$GroupCategoryImpl _value,
    $Res Function(_$GroupCategoryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroupCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? tenantId = freezed,
    Object? name = null,
    Object? index = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$GroupCategoryImpl(
        id:
            freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as int?,
        tenantId:
            freezed == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as int?,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        index:
            freezed == index
                ? _value.index
                : index // ignore: cast_nullable_to_non_nullable
                    as int?,
        createdAt:
            freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupCategoryImpl implements _GroupCategory {
  const _$GroupCategoryImpl({
    this.id,
    this.tenantId,
    required this.name,
    this.index,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$GroupCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupCategoryImplFromJson(json);

  @override
  final int? id;
  @override
  final int? tenantId;
  @override
  final String name;
  @override
  final int? index;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'GroupCategory(id: $id, tenantId: $tenantId, name: $name, index: $index, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, tenantId, name, index, createdAt);

  /// Create a copy of GroupCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupCategoryImplCopyWith<_$GroupCategoryImpl> get copyWith =>
      __$$GroupCategoryImplCopyWithImpl<_$GroupCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupCategoryImplToJson(this);
  }
}

abstract class _GroupCategory implements GroupCategory {
  const factory _GroupCategory({
    final int? id,
    final int? tenantId,
    required final String name,
    final int? index,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$GroupCategoryImpl;

  factory _GroupCategory.fromJson(Map<String, dynamic> json) =
      _$GroupCategoryImpl.fromJson;

  @override
  int? get id;
  @override
  int? get tenantId;
  @override
  String get name;
  @override
  int? get index;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of GroupCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupCategoryImplCopyWith<_$GroupCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
