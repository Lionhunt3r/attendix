// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AudioPlayerState {
  String? get currentUrl => throw _privateConstructorUsedError;
  String get currentSongName => throw _privateConstructorUsedError;
  String? get currentFileName => throw _privateConstructorUsedError;
  bool get isPlaying => throw _privateConstructorUsedError;
  Duration get currentTime => throw _privateConstructorUsedError;
  Duration get duration => throw _privateConstructorUsedError;
  bool get isSeeking => throw _privateConstructorUsedError;

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AudioPlayerStateCopyWith<AudioPlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioPlayerStateCopyWith<$Res> {
  factory $AudioPlayerStateCopyWith(
    AudioPlayerState value,
    $Res Function(AudioPlayerState) then,
  ) = _$AudioPlayerStateCopyWithImpl<$Res, AudioPlayerState>;
  @useResult
  $Res call({
    String? currentUrl,
    String currentSongName,
    String? currentFileName,
    bool isPlaying,
    Duration currentTime,
    Duration duration,
    bool isSeeking,
  });
}

/// @nodoc
class _$AudioPlayerStateCopyWithImpl<$Res, $Val extends AudioPlayerState>
    implements $AudioPlayerStateCopyWith<$Res> {
  _$AudioPlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentUrl = freezed,
    Object? currentSongName = null,
    Object? currentFileName = freezed,
    Object? isPlaying = null,
    Object? currentTime = null,
    Object? duration = null,
    Object? isSeeking = null,
  }) {
    return _then(
      _value.copyWith(
            currentUrl:
                freezed == currentUrl
                    ? _value.currentUrl
                    : currentUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            currentSongName:
                null == currentSongName
                    ? _value.currentSongName
                    : currentSongName // ignore: cast_nullable_to_non_nullable
                        as String,
            currentFileName:
                freezed == currentFileName
                    ? _value.currentFileName
                    : currentFileName // ignore: cast_nullable_to_non_nullable
                        as String?,
            isPlaying:
                null == isPlaying
                    ? _value.isPlaying
                    : isPlaying // ignore: cast_nullable_to_non_nullable
                        as bool,
            currentTime:
                null == currentTime
                    ? _value.currentTime
                    : currentTime // ignore: cast_nullable_to_non_nullable
                        as Duration,
            duration:
                null == duration
                    ? _value.duration
                    : duration // ignore: cast_nullable_to_non_nullable
                        as Duration,
            isSeeking:
                null == isSeeking
                    ? _value.isSeeking
                    : isSeeking // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AudioPlayerStateImplCopyWith<$Res>
    implements $AudioPlayerStateCopyWith<$Res> {
  factory _$$AudioPlayerStateImplCopyWith(
    _$AudioPlayerStateImpl value,
    $Res Function(_$AudioPlayerStateImpl) then,
  ) = __$$AudioPlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? currentUrl,
    String currentSongName,
    String? currentFileName,
    bool isPlaying,
    Duration currentTime,
    Duration duration,
    bool isSeeking,
  });
}

/// @nodoc
class __$$AudioPlayerStateImplCopyWithImpl<$Res>
    extends _$AudioPlayerStateCopyWithImpl<$Res, _$AudioPlayerStateImpl>
    implements _$$AudioPlayerStateImplCopyWith<$Res> {
  __$$AudioPlayerStateImplCopyWithImpl(
    _$AudioPlayerStateImpl _value,
    $Res Function(_$AudioPlayerStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentUrl = freezed,
    Object? currentSongName = null,
    Object? currentFileName = freezed,
    Object? isPlaying = null,
    Object? currentTime = null,
    Object? duration = null,
    Object? isSeeking = null,
  }) {
    return _then(
      _$AudioPlayerStateImpl(
        currentUrl:
            freezed == currentUrl
                ? _value.currentUrl
                : currentUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        currentSongName:
            null == currentSongName
                ? _value.currentSongName
                : currentSongName // ignore: cast_nullable_to_non_nullable
                    as String,
        currentFileName:
            freezed == currentFileName
                ? _value.currentFileName
                : currentFileName // ignore: cast_nullable_to_non_nullable
                    as String?,
        isPlaying:
            null == isPlaying
                ? _value.isPlaying
                : isPlaying // ignore: cast_nullable_to_non_nullable
                    as bool,
        currentTime:
            null == currentTime
                ? _value.currentTime
                : currentTime // ignore: cast_nullable_to_non_nullable
                    as Duration,
        duration:
            null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                    as Duration,
        isSeeking:
            null == isSeeking
                ? _value.isSeeking
                : isSeeking // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$AudioPlayerStateImpl extends _AudioPlayerState {
  const _$AudioPlayerStateImpl({
    this.currentUrl,
    this.currentSongName = '',
    this.currentFileName,
    this.isPlaying = false,
    this.currentTime = Duration.zero,
    this.duration = Duration.zero,
    this.isSeeking = false,
  }) : super._();

  @override
  final String? currentUrl;
  @override
  @JsonKey()
  final String currentSongName;
  @override
  final String? currentFileName;
  @override
  @JsonKey()
  final bool isPlaying;
  @override
  @JsonKey()
  final Duration currentTime;
  @override
  @JsonKey()
  final Duration duration;
  @override
  @JsonKey()
  final bool isSeeking;

  @override
  String toString() {
    return 'AudioPlayerState(currentUrl: $currentUrl, currentSongName: $currentSongName, currentFileName: $currentFileName, isPlaying: $isPlaying, currentTime: $currentTime, duration: $duration, isSeeking: $isSeeking)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioPlayerStateImpl &&
            (identical(other.currentUrl, currentUrl) ||
                other.currentUrl == currentUrl) &&
            (identical(other.currentSongName, currentSongName) ||
                other.currentSongName == currentSongName) &&
            (identical(other.currentFileName, currentFileName) ||
                other.currentFileName == currentFileName) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.currentTime, currentTime) ||
                other.currentTime == currentTime) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.isSeeking, isSeeking) ||
                other.isSeeking == isSeeking));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currentUrl,
    currentSongName,
    currentFileName,
    isPlaying,
    currentTime,
    duration,
    isSeeking,
  );

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioPlayerStateImplCopyWith<_$AudioPlayerStateImpl> get copyWith =>
      __$$AudioPlayerStateImplCopyWithImpl<_$AudioPlayerStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AudioPlayerState extends AudioPlayerState {
  const factory _AudioPlayerState({
    final String? currentUrl,
    final String currentSongName,
    final String? currentFileName,
    final bool isPlaying,
    final Duration currentTime,
    final Duration duration,
    final bool isSeeking,
  }) = _$AudioPlayerStateImpl;
  const _AudioPlayerState._() : super._();

  @override
  String? get currentUrl;
  @override
  String get currentSongName;
  @override
  String? get currentFileName;
  @override
  bool get isPlaying;
  @override
  Duration get currentTime;
  @override
  Duration get duration;
  @override
  bool get isSeeking;

  /// Create a copy of AudioPlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AudioPlayerStateImplCopyWith<_$AudioPlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
