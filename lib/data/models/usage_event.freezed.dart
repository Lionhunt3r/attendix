// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usage_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UsageEvent _$UsageEventFromJson(Map<String, dynamic> json) {
  return _UsageEvent.fromJson(json);
}

/// @nodoc
mixin _$UsageEvent {
  @JsonKey(name: 'event_name')
  String get eventName => throw _privateConstructorUsedError;
  @JsonKey(name: 'tenant_id')
  int? get tenantId => throw _privateConstructorUsedError;
  @JsonKey(name: 'device_type')
  String get deviceType => throw _privateConstructorUsedError;
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

  /// Serializes this UsageEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UsageEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UsageEventCopyWith<UsageEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UsageEventCopyWith<$Res> {
  factory $UsageEventCopyWith(
    UsageEvent value,
    $Res Function(UsageEvent) then,
  ) = _$UsageEventCopyWithImpl<$Res, UsageEvent>;
  @useResult
  $Res call({
    @JsonKey(name: 'event_name') String eventName,
    @JsonKey(name: 'tenant_id') int? tenantId,
    @JsonKey(name: 'device_type') String deviceType,
    Map<String, dynamic> properties,
  });
}

/// @nodoc
class _$UsageEventCopyWithImpl<$Res, $Val extends UsageEvent>
    implements $UsageEventCopyWith<$Res> {
  _$UsageEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UsageEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventName = null,
    Object? tenantId = freezed,
    Object? deviceType = null,
    Object? properties = null,
  }) {
    return _then(
      _value.copyWith(
            eventName:
                null == eventName
                    ? _value.eventName
                    : eventName // ignore: cast_nullable_to_non_nullable
                        as String,
            tenantId:
                freezed == tenantId
                    ? _value.tenantId
                    : tenantId // ignore: cast_nullable_to_non_nullable
                        as int?,
            deviceType:
                null == deviceType
                    ? _value.deviceType
                    : deviceType // ignore: cast_nullable_to_non_nullable
                        as String,
            properties:
                null == properties
                    ? _value.properties
                    : properties // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UsageEventImplCopyWith<$Res>
    implements $UsageEventCopyWith<$Res> {
  factory _$$UsageEventImplCopyWith(
    _$UsageEventImpl value,
    $Res Function(_$UsageEventImpl) then,
  ) = __$$UsageEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'event_name') String eventName,
    @JsonKey(name: 'tenant_id') int? tenantId,
    @JsonKey(name: 'device_type') String deviceType,
    Map<String, dynamic> properties,
  });
}

/// @nodoc
class __$$UsageEventImplCopyWithImpl<$Res>
    extends _$UsageEventCopyWithImpl<$Res, _$UsageEventImpl>
    implements _$$UsageEventImplCopyWith<$Res> {
  __$$UsageEventImplCopyWithImpl(
    _$UsageEventImpl _value,
    $Res Function(_$UsageEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UsageEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? eventName = null,
    Object? tenantId = freezed,
    Object? deviceType = null,
    Object? properties = null,
  }) {
    return _then(
      _$UsageEventImpl(
        eventName:
            null == eventName
                ? _value.eventName
                : eventName // ignore: cast_nullable_to_non_nullable
                    as String,
        tenantId:
            freezed == tenantId
                ? _value.tenantId
                : tenantId // ignore: cast_nullable_to_non_nullable
                    as int?,
        deviceType:
            null == deviceType
                ? _value.deviceType
                : deviceType // ignore: cast_nullable_to_non_nullable
                    as String,
        properties:
            null == properties
                ? _value._properties
                : properties // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UsageEventImpl implements _UsageEvent {
  const _$UsageEventImpl({
    @JsonKey(name: 'event_name') required this.eventName,
    @JsonKey(name: 'tenant_id') this.tenantId,
    @JsonKey(name: 'device_type') required this.deviceType,
    final Map<String, dynamic> properties = const <String, dynamic>{},
  }) : _properties = properties;

  factory _$UsageEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$UsageEventImplFromJson(json);

  @override
  @JsonKey(name: 'event_name')
  final String eventName;
  @override
  @JsonKey(name: 'tenant_id')
  final int? tenantId;
  @override
  @JsonKey(name: 'device_type')
  final String deviceType;
  final Map<String, dynamic> _properties;
  @override
  @JsonKey()
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'UsageEvent(eventName: $eventName, tenantId: $tenantId, deviceType: $deviceType, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UsageEventImpl &&
            (identical(other.eventName, eventName) ||
                other.eventName == eventName) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.deviceType, deviceType) ||
                other.deviceType == deviceType) &&
            const DeepCollectionEquality().equals(
              other._properties,
              _properties,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    eventName,
    tenantId,
    deviceType,
    const DeepCollectionEquality().hash(_properties),
  );

  /// Create a copy of UsageEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UsageEventImplCopyWith<_$UsageEventImpl> get copyWith =>
      __$$UsageEventImplCopyWithImpl<_$UsageEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UsageEventImplToJson(this);
  }
}

abstract class _UsageEvent implements UsageEvent {
  const factory _UsageEvent({
    @JsonKey(name: 'event_name') required final String eventName,
    @JsonKey(name: 'tenant_id') final int? tenantId,
    @JsonKey(name: 'device_type') required final String deviceType,
    final Map<String, dynamic> properties,
  }) = _$UsageEventImpl;

  factory _UsageEvent.fromJson(Map<String, dynamic> json) =
      _$UsageEventImpl.fromJson;

  @override
  @JsonKey(name: 'event_name')
  String get eventName;
  @override
  @JsonKey(name: 'tenant_id')
  int? get tenantId;
  @override
  @JsonKey(name: 'device_type')
  String get deviceType;
  @override
  Map<String, dynamic> get properties;

  /// Create a copy of UsageEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UsageEventImplCopyWith<_$UsageEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
