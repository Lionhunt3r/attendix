// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'songs_selection_sheet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SongHistoryEntry _$SongHistoryEntryFromJson(Map<String, dynamic> json) {
  return _SongHistoryEntry.fromJson(json);
}

/// @nodoc
mixin _$SongHistoryEntry {
  int get songId => throw _privateConstructorUsedError;
  String get songName => throw _privateConstructorUsedError;
  int? get conductorId => throw _privateConstructorUsedError;
  String? get conductorName => throw _privateConstructorUsedError;
  String? get otherConductor => throw _privateConstructorUsedError;

  /// Serializes this SongHistoryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SongHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SongHistoryEntryCopyWith<SongHistoryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongHistoryEntryCopyWith<$Res> {
  factory $SongHistoryEntryCopyWith(
    SongHistoryEntry value,
    $Res Function(SongHistoryEntry) then,
  ) = _$SongHistoryEntryCopyWithImpl<$Res, SongHistoryEntry>;
  @useResult
  $Res call({
    int songId,
    String songName,
    int? conductorId,
    String? conductorName,
    String? otherConductor,
  });
}

/// @nodoc
class _$SongHistoryEntryCopyWithImpl<$Res, $Val extends SongHistoryEntry>
    implements $SongHistoryEntryCopyWith<$Res> {
  _$SongHistoryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SongHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? songId = null,
    Object? songName = null,
    Object? conductorId = freezed,
    Object? conductorName = freezed,
    Object? otherConductor = freezed,
  }) {
    return _then(
      _value.copyWith(
            songId:
                null == songId
                    ? _value.songId
                    : songId // ignore: cast_nullable_to_non_nullable
                        as int,
            songName:
                null == songName
                    ? _value.songName
                    : songName // ignore: cast_nullable_to_non_nullable
                        as String,
            conductorId:
                freezed == conductorId
                    ? _value.conductorId
                    : conductorId // ignore: cast_nullable_to_non_nullable
                        as int?,
            conductorName:
                freezed == conductorName
                    ? _value.conductorName
                    : conductorName // ignore: cast_nullable_to_non_nullable
                        as String?,
            otherConductor:
                freezed == otherConductor
                    ? _value.otherConductor
                    : otherConductor // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SongHistoryEntryImplCopyWith<$Res>
    implements $SongHistoryEntryCopyWith<$Res> {
  factory _$$SongHistoryEntryImplCopyWith(
    _$SongHistoryEntryImpl value,
    $Res Function(_$SongHistoryEntryImpl) then,
  ) = __$$SongHistoryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int songId,
    String songName,
    int? conductorId,
    String? conductorName,
    String? otherConductor,
  });
}

/// @nodoc
class __$$SongHistoryEntryImplCopyWithImpl<$Res>
    extends _$SongHistoryEntryCopyWithImpl<$Res, _$SongHistoryEntryImpl>
    implements _$$SongHistoryEntryImplCopyWith<$Res> {
  __$$SongHistoryEntryImplCopyWithImpl(
    _$SongHistoryEntryImpl _value,
    $Res Function(_$SongHistoryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SongHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? songId = null,
    Object? songName = null,
    Object? conductorId = freezed,
    Object? conductorName = freezed,
    Object? otherConductor = freezed,
  }) {
    return _then(
      _$SongHistoryEntryImpl(
        songId:
            null == songId
                ? _value.songId
                : songId // ignore: cast_nullable_to_non_nullable
                    as int,
        songName:
            null == songName
                ? _value.songName
                : songName // ignore: cast_nullable_to_non_nullable
                    as String,
        conductorId:
            freezed == conductorId
                ? _value.conductorId
                : conductorId // ignore: cast_nullable_to_non_nullable
                    as int?,
        conductorName:
            freezed == conductorName
                ? _value.conductorName
                : conductorName // ignore: cast_nullable_to_non_nullable
                    as String?,
        otherConductor:
            freezed == otherConductor
                ? _value.otherConductor
                : otherConductor // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SongHistoryEntryImpl implements _SongHistoryEntry {
  const _$SongHistoryEntryImpl({
    required this.songId,
    required this.songName,
    this.conductorId,
    this.conductorName,
    this.otherConductor,
  });

  factory _$SongHistoryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongHistoryEntryImplFromJson(json);

  @override
  final int songId;
  @override
  final String songName;
  @override
  final int? conductorId;
  @override
  final String? conductorName;
  @override
  final String? otherConductor;

  @override
  String toString() {
    return 'SongHistoryEntry(songId: $songId, songName: $songName, conductorId: $conductorId, conductorName: $conductorName, otherConductor: $otherConductor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongHistoryEntryImpl &&
            (identical(other.songId, songId) || other.songId == songId) &&
            (identical(other.songName, songName) ||
                other.songName == songName) &&
            (identical(other.conductorId, conductorId) ||
                other.conductorId == conductorId) &&
            (identical(other.conductorName, conductorName) ||
                other.conductorName == conductorName) &&
            (identical(other.otherConductor, otherConductor) ||
                other.otherConductor == otherConductor));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    songId,
    songName,
    conductorId,
    conductorName,
    otherConductor,
  );

  /// Create a copy of SongHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongHistoryEntryImplCopyWith<_$SongHistoryEntryImpl> get copyWith =>
      __$$SongHistoryEntryImplCopyWithImpl<_$SongHistoryEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SongHistoryEntryImplToJson(this);
  }
}

abstract class _SongHistoryEntry implements SongHistoryEntry {
  const factory _SongHistoryEntry({
    required final int songId,
    required final String songName,
    final int? conductorId,
    final String? conductorName,
    final String? otherConductor,
  }) = _$SongHistoryEntryImpl;

  factory _SongHistoryEntry.fromJson(Map<String, dynamic> json) =
      _$SongHistoryEntryImpl.fromJson;

  @override
  int get songId;
  @override
  String get songName;
  @override
  int? get conductorId;
  @override
  String? get conductorName;
  @override
  String? get otherConductor;

  /// Create a copy of SongHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongHistoryEntryImplCopyWith<_$SongHistoryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
