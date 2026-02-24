// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shift_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ShiftPlan _$ShiftPlanFromJson(Map<String, dynamic> json) {
  return _ShiftPlan.fromJson(json);
}

/// @nodoc
mixin _$ShiftPlan {
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'tenant_id')
  int? get tenantId => throw _privateConstructorUsedError;
  @_ShiftDefinitionListConverter()
  List<ShiftDefinition> get definition => throw _privateConstructorUsedError;
  @_ShiftInstanceListConverter()
  List<ShiftInstance> get shifts => throw _privateConstructorUsedError;

  /// Serializes this ShiftPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ShiftPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShiftPlanCopyWith<ShiftPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShiftPlanCopyWith<$Res> {
  factory $ShiftPlanCopyWith(ShiftPlan value, $Res Function(ShiftPlan) then) =
      _$ShiftPlanCopyWithImpl<$Res, ShiftPlan>;
  @useResult
  $Res call({
    String? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String name,
    String description,
    @JsonKey(name: 'tenant_id') int? tenantId,
    @_ShiftDefinitionListConverter() List<ShiftDefinition> definition,
    @_ShiftInstanceListConverter() List<ShiftInstance> shifts,
  });
}

/// @nodoc
class _$ShiftPlanCopyWithImpl<$Res, $Val extends ShiftPlan>
    implements $ShiftPlanCopyWith<$Res> {
  _$ShiftPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShiftPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = freezed,
    Object? name = null,
    Object? description = null,
    Object? tenantId = freezed,
    Object? definition = null,
    Object? shifts = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                freezed == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String?,
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
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            tenantId:
                freezed == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as int?,
            definition:
                null == definition
                    ? _value.definition
                    : definition // ignore: cast_nullable_to_non_nullable
                        as List<ShiftDefinition>,
            shifts:
                null == shifts
                    ? _value.shifts
                    : shifts // ignore: cast_nullable_to_non_nullable
                        as List<ShiftInstance>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ShiftPlanImplCopyWith<$Res>
    implements $ShiftPlanCopyWith<$Res> {
  factory _$$ShiftPlanImplCopyWith(
    _$ShiftPlanImpl value,
    $Res Function(_$ShiftPlanImpl) then,
  ) = __$$ShiftPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String name,
    String description,
    @JsonKey(name: 'tenant_id') int? tenantId,
    @_ShiftDefinitionListConverter() List<ShiftDefinition> definition,
    @_ShiftInstanceListConverter() List<ShiftInstance> shifts,
  });
}

/// @nodoc
class __$$ShiftPlanImplCopyWithImpl<$Res>
    extends _$ShiftPlanCopyWithImpl<$Res, _$ShiftPlanImpl>
    implements _$$ShiftPlanImplCopyWith<$Res> {
  __$$ShiftPlanImplCopyWithImpl(
    _$ShiftPlanImpl _value,
    $Res Function(_$ShiftPlanImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ShiftPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? createdAt = freezed,
    Object? name = null,
    Object? description = null,
    Object? tenantId = freezed,
    Object? definition = null,
    Object? shifts = null,
  }) {
    return _then(
      _$ShiftPlanImpl(
        id:
            freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String?,
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
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        tenantId:
            freezed == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as int?,
        definition:
            null == definition
                ? _value._definition
                : definition // ignore: cast_nullable_to_non_nullable
                    as List<ShiftDefinition>,
        shifts:
            null == shifts
                ? _value._shifts
                : shifts // ignore: cast_nullable_to_non_nullable
                    as List<ShiftInstance>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ShiftPlanImpl implements _ShiftPlan {
  const _$ShiftPlanImpl({
    this.id,
    @JsonKey(name: 'created_at') this.createdAt,
    required this.name,
    this.description = '',
    @JsonKey(name: 'tenant_id') this.tenantId,
    @_ShiftDefinitionListConverter()
    final List<ShiftDefinition> definition = const [],
    @_ShiftInstanceListConverter() final List<ShiftInstance> shifts = const [],
  }) : _definition = definition,
       _shifts = shifts;

  factory _$ShiftPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$ShiftPlanImplFromJson(json);

  @override
  final String? id;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  final String name;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey(name: 'tenant_id')
  final int? tenantId;
  final List<ShiftDefinition> _definition;
  @override
  @JsonKey()
  @_ShiftDefinitionListConverter()
  List<ShiftDefinition> get definition {
    if (_definition is EqualUnmodifiableListView) return _definition;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_definition);
  }

  final List<ShiftInstance> _shifts;
  @override
  @JsonKey()
  @_ShiftInstanceListConverter()
  List<ShiftInstance> get shifts {
    if (_shifts is EqualUnmodifiableListView) return _shifts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_shifts);
  }

  @override
  String toString() {
    return 'ShiftPlan(id: $id, createdAt: $createdAt, name: $name, description: $description, tenantId: $tenantId, definition: $definition, shifts: $shifts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShiftPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            const DeepCollectionEquality().equals(
              other._definition,
              _definition,
            ) &&
            const DeepCollectionEquality().equals(other._shifts, _shifts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    createdAt,
    name,
    description,
    tenantId,
    const DeepCollectionEquality().hash(_definition),
    const DeepCollectionEquality().hash(_shifts),
  );

  /// Create a copy of ShiftPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShiftPlanImplCopyWith<_$ShiftPlanImpl> get copyWith =>
      __$$ShiftPlanImplCopyWithImpl<_$ShiftPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ShiftPlanImplToJson(this);
  }
}

abstract class _ShiftPlan implements ShiftPlan {
  const factory _ShiftPlan({
    final String? id,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    required final String name,
    final String description,
    @JsonKey(name: 'tenant_id') final int? tenantId,
    @_ShiftDefinitionListConverter() final List<ShiftDefinition> definition,
    @_ShiftInstanceListConverter() final List<ShiftInstance> shifts,
  }) = _$ShiftPlanImpl;

  factory _ShiftPlan.fromJson(Map<String, dynamic> json) =
      _$ShiftPlanImpl.fromJson;

  @override
  String? get id;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(name: 'tenant_id')
  int? get tenantId;
  @override
  @_ShiftDefinitionListConverter()
  List<ShiftDefinition> get definition;
  @override
  @_ShiftInstanceListConverter()
  List<ShiftInstance> get shifts;

  /// Create a copy of ShiftPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShiftPlanImplCopyWith<_$ShiftPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
