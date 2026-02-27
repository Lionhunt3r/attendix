// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SongFilter _$SongFilterFromJson(Map<String, dynamic> json) {
  return _SongFilter.fromJson(json);
}

/// @nodoc
mixin _$SongFilter {
  bool get withChoir => throw _privateConstructorUsedError;
  bool get withSolo => throw _privateConstructorUsedError;
  List<int> get instrumentIds => throw _privateConstructorUsedError;
  int? get difficulty => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  SongSortOption get sortOption => throw _privateConstructorUsedError;

  /// Serializes this SongFilter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SongFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SongFilterCopyWith<SongFilter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongFilterCopyWith<$Res> {
  factory $SongFilterCopyWith(
    SongFilter value,
    $Res Function(SongFilter) then,
  ) = _$SongFilterCopyWithImpl<$Res, SongFilter>;
  @useResult
  $Res call({
    bool withChoir,
    bool withSolo,
    List<int> instrumentIds,
    int? difficulty,
    String? category,
    SongSortOption sortOption,
  });
}

/// @nodoc
class _$SongFilterCopyWithImpl<$Res, $Val extends SongFilter>
    implements $SongFilterCopyWith<$Res> {
  _$SongFilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SongFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? withChoir = null,
    Object? withSolo = null,
    Object? instrumentIds = null,
    Object? difficulty = freezed,
    Object? category = freezed,
    Object? sortOption = null,
  }) {
    return _then(
      _value.copyWith(
            withChoir:
                null == withChoir
                    ? _value.withChoir
                    : withChoir // ignore: cast_nullable_to_non_nullable
                        as bool,
            withSolo:
                null == withSolo
                    ? _value.withSolo
                    : withSolo // ignore: cast_nullable_to_non_nullable
                        as bool,
            instrumentIds:
                null == instrumentIds
                    ? _value.instrumentIds
                    : instrumentIds // ignore: cast_nullable_to_non_nullable
                        as List<int>,
            difficulty:
                freezed == difficulty
                    ? _value.difficulty
                    : difficulty // ignore: cast_nullable_to_non_nullable
                        as int?,
            category:
                freezed == category
                    ? _value.category
                    : category // ignore: cast_nullable_to_non_nullable
                        as String?,
            sortOption:
                null == sortOption
                    ? _value.sortOption
                    : sortOption // ignore: cast_nullable_to_non_nullable
                        as SongSortOption,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SongFilterImplCopyWith<$Res>
    implements $SongFilterCopyWith<$Res> {
  factory _$$SongFilterImplCopyWith(
    _$SongFilterImpl value,
    $Res Function(_$SongFilterImpl) then,
  ) = __$$SongFilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool withChoir,
    bool withSolo,
    List<int> instrumentIds,
    int? difficulty,
    String? category,
    SongSortOption sortOption,
  });
}

/// @nodoc
class __$$SongFilterImplCopyWithImpl<$Res>
    extends _$SongFilterCopyWithImpl<$Res, _$SongFilterImpl>
    implements _$$SongFilterImplCopyWith<$Res> {
  __$$SongFilterImplCopyWithImpl(
    _$SongFilterImpl _value,
    $Res Function(_$SongFilterImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SongFilter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? withChoir = null,
    Object? withSolo = null,
    Object? instrumentIds = null,
    Object? difficulty = freezed,
    Object? category = freezed,
    Object? sortOption = null,
  }) {
    return _then(
      _$SongFilterImpl(
        withChoir:
            null == withChoir
                ? _value.withChoir
                : withChoir // ignore: cast_nullable_to_non_nullable
                    as bool,
        withSolo:
            null == withSolo
                ? _value.withSolo
                : withSolo // ignore: cast_nullable_to_non_nullable
                    as bool,
        instrumentIds:
            null == instrumentIds
                ? _value._instrumentIds
                : instrumentIds // ignore: cast_nullable_to_non_nullable
                    as List<int>,
        difficulty:
            freezed == difficulty
                ? _value.difficulty
                : difficulty // ignore: cast_nullable_to_non_nullable
                    as int?,
        category:
            freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                    as String?,
        sortOption:
            null == sortOption
                ? _value.sortOption
                : sortOption // ignore: cast_nullable_to_non_nullable
                    as SongSortOption,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SongFilterImpl extends _SongFilter {
  const _$SongFilterImpl({
    this.withChoir = false,
    this.withSolo = false,
    final List<int> instrumentIds = const [],
    this.difficulty,
    this.category,
    this.sortOption = SongSortOption.numberAsc,
  }) : _instrumentIds = instrumentIds,
       super._();

  factory _$SongFilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongFilterImplFromJson(json);

  @override
  @JsonKey()
  final bool withChoir;
  @override
  @JsonKey()
  final bool withSolo;
  final List<int> _instrumentIds;
  @override
  @JsonKey()
  List<int> get instrumentIds {
    if (_instrumentIds is EqualUnmodifiableListView) return _instrumentIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_instrumentIds);
  }

  @override
  final int? difficulty;
  @override
  final String? category;
  @override
  @JsonKey()
  final SongSortOption sortOption;

  @override
  String toString() {
    return 'SongFilter(withChoir: $withChoir, withSolo: $withSolo, instrumentIds: $instrumentIds, difficulty: $difficulty, category: $category, sortOption: $sortOption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongFilterImpl &&
            (identical(other.withChoir, withChoir) ||
                other.withChoir == withChoir) &&
            (identical(other.withSolo, withSolo) ||
                other.withSolo == withSolo) &&
            const DeepCollectionEquality().equals(
              other._instrumentIds,
              _instrumentIds,
            ) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    withChoir,
    withSolo,
    const DeepCollectionEquality().hash(_instrumentIds),
    difficulty,
    category,
    sortOption,
  );

  /// Create a copy of SongFilter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongFilterImplCopyWith<_$SongFilterImpl> get copyWith =>
      __$$SongFilterImplCopyWithImpl<_$SongFilterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongFilterImplToJson(this);
  }
}

abstract class _SongFilter extends SongFilter {
  const factory _SongFilter({
    final bool withChoir,
    final bool withSolo,
    final List<int> instrumentIds,
    final int? difficulty,
    final String? category,
    final SongSortOption sortOption,
  }) = _$SongFilterImpl;
  const _SongFilter._() : super._();

  factory _SongFilter.fromJson(Map<String, dynamic> json) =
      _$SongFilterImpl.fromJson;

  @override
  bool get withChoir;
  @override
  bool get withSolo;
  @override
  List<int> get instrumentIds;
  @override
  int? get difficulty;
  @override
  String? get category;
  @override
  SongSortOption get sortOption;

  /// Create a copy of SongFilter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongFilterImplCopyWith<_$SongFilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SongViewOptions _$SongViewOptionsFromJson(Map<String, dynamic> json) {
  return _SongViewOptions.fromJson(json);
}

/// @nodoc
mixin _$SongViewOptions {
  bool get showChoirBadge => throw _privateConstructorUsedError;
  bool get showSoloBadge => throw _privateConstructorUsedError;
  bool get showMissingInstruments => throw _privateConstructorUsedError;
  bool get showLink => throw _privateConstructorUsedError;
  bool get showLastSung => throw _privateConstructorUsedError;

  /// Serializes this SongViewOptions to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SongViewOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SongViewOptionsCopyWith<SongViewOptions> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongViewOptionsCopyWith<$Res> {
  factory $SongViewOptionsCopyWith(
    SongViewOptions value,
    $Res Function(SongViewOptions) then,
  ) = _$SongViewOptionsCopyWithImpl<$Res, SongViewOptions>;
  @useResult
  $Res call({
    bool showChoirBadge,
    bool showSoloBadge,
    bool showMissingInstruments,
    bool showLink,
    bool showLastSung,
  });
}

/// @nodoc
class _$SongViewOptionsCopyWithImpl<$Res, $Val extends SongViewOptions>
    implements $SongViewOptionsCopyWith<$Res> {
  _$SongViewOptionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SongViewOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showChoirBadge = null,
    Object? showSoloBadge = null,
    Object? showMissingInstruments = null,
    Object? showLink = null,
    Object? showLastSung = null,
  }) {
    return _then(
      _value.copyWith(
            showChoirBadge:
                null == showChoirBadge
                    ? _value.showChoirBadge
                    : showChoirBadge // ignore: cast_nullable_to_non_nullable
                        as bool,
            showSoloBadge:
                null == showSoloBadge
                    ? _value.showSoloBadge
                    : showSoloBadge // ignore: cast_nullable_to_non_nullable
                        as bool,
            showMissingInstruments:
                null == showMissingInstruments
                    ? _value.showMissingInstruments
                    : showMissingInstruments // ignore: cast_nullable_to_non_nullable
                        as bool,
            showLink:
                null == showLink
                    ? _value.showLink
                    : showLink // ignore: cast_nullable_to_non_nullable
                        as bool,
            showLastSung:
                null == showLastSung
                    ? _value.showLastSung
                    : showLastSung // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SongViewOptionsImplCopyWith<$Res>
    implements $SongViewOptionsCopyWith<$Res> {
  factory _$$SongViewOptionsImplCopyWith(
    _$SongViewOptionsImpl value,
    $Res Function(_$SongViewOptionsImpl) then,
  ) = __$$SongViewOptionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool showChoirBadge,
    bool showSoloBadge,
    bool showMissingInstruments,
    bool showLink,
    bool showLastSung,
  });
}

/// @nodoc
class __$$SongViewOptionsImplCopyWithImpl<$Res>
    extends _$SongViewOptionsCopyWithImpl<$Res, _$SongViewOptionsImpl>
    implements _$$SongViewOptionsImplCopyWith<$Res> {
  __$$SongViewOptionsImplCopyWithImpl(
    _$SongViewOptionsImpl _value,
    $Res Function(_$SongViewOptionsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SongViewOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showChoirBadge = null,
    Object? showSoloBadge = null,
    Object? showMissingInstruments = null,
    Object? showLink = null,
    Object? showLastSung = null,
  }) {
    return _then(
      _$SongViewOptionsImpl(
        showChoirBadge:
            null == showChoirBadge
                ? _value.showChoirBadge
                : showChoirBadge // ignore: cast_nullable_to_non_nullable
                    as bool,
        showSoloBadge:
            null == showSoloBadge
                ? _value.showSoloBadge
                : showSoloBadge // ignore: cast_nullable_to_non_nullable
                    as bool,
        showMissingInstruments:
            null == showMissingInstruments
                ? _value.showMissingInstruments
                : showMissingInstruments // ignore: cast_nullable_to_non_nullable
                    as bool,
        showLink:
            null == showLink
                ? _value.showLink
                : showLink // ignore: cast_nullable_to_non_nullable
                    as bool,
        showLastSung:
            null == showLastSung
                ? _value.showLastSung
                : showLastSung // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SongViewOptionsImpl implements _SongViewOptions {
  const _$SongViewOptionsImpl({
    this.showChoirBadge = true,
    this.showSoloBadge = true,
    this.showMissingInstruments = true,
    this.showLink = true,
    this.showLastSung = true,
  });

  factory _$SongViewOptionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongViewOptionsImplFromJson(json);

  @override
  @JsonKey()
  final bool showChoirBadge;
  @override
  @JsonKey()
  final bool showSoloBadge;
  @override
  @JsonKey()
  final bool showMissingInstruments;
  @override
  @JsonKey()
  final bool showLink;
  @override
  @JsonKey()
  final bool showLastSung;

  @override
  String toString() {
    return 'SongViewOptions(showChoirBadge: $showChoirBadge, showSoloBadge: $showSoloBadge, showMissingInstruments: $showMissingInstruments, showLink: $showLink, showLastSung: $showLastSung)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongViewOptionsImpl &&
            (identical(other.showChoirBadge, showChoirBadge) ||
                other.showChoirBadge == showChoirBadge) &&
            (identical(other.showSoloBadge, showSoloBadge) ||
                other.showSoloBadge == showSoloBadge) &&
            (identical(other.showMissingInstruments, showMissingInstruments) ||
                other.showMissingInstruments == showMissingInstruments) &&
            (identical(other.showLink, showLink) ||
                other.showLink == showLink) &&
            (identical(other.showLastSung, showLastSung) ||
                other.showLastSung == showLastSung));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    showChoirBadge,
    showSoloBadge,
    showMissingInstruments,
    showLink,
    showLastSung,
  );

  /// Create a copy of SongViewOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongViewOptionsImplCopyWith<_$SongViewOptionsImpl> get copyWith =>
      __$$SongViewOptionsImplCopyWithImpl<_$SongViewOptionsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SongViewOptionsImplToJson(this);
  }
}

abstract class _SongViewOptions implements SongViewOptions {
  const factory _SongViewOptions({
    final bool showChoirBadge,
    final bool showSoloBadge,
    final bool showMissingInstruments,
    final bool showLink,
    final bool showLastSung,
  }) = _$SongViewOptionsImpl;

  factory _SongViewOptions.fromJson(Map<String, dynamic> json) =
      _$SongViewOptionsImpl.fromJson;

  @override
  bool get showChoirBadge;
  @override
  bool get showSoloBadge;
  @override
  bool get showMissingInstruments;
  @override
  bool get showLink;
  @override
  bool get showLastSung;

  /// Create a copy of SongViewOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongViewOptionsImplCopyWith<_$SongViewOptionsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
