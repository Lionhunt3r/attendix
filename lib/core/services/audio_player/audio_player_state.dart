import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_player_state.freezed.dart';

/// Immutable snapshot of the audio player.
///
/// Mirrors Ionic v4.0.5 `AudioPlayerService` (`audio-player.service.ts:7-17`)
/// minus `progress` (0-100 for `ion-range`). In Flutter we drive the slider
/// directly off `currentTime / duration` to avoid a redundant state field.
@freezed
class AudioPlayerState with _$AudioPlayerState {
  const factory AudioPlayerState({
    String? currentUrl,
    @Default('') String currentSongName,
    String? currentFileName,
    @Default(false) bool isPlaying,
    @Default(Duration.zero) Duration currentTime,
    @Default(Duration.zero) Duration duration,
    @Default(false) bool isSeeking,
  }) = _AudioPlayerState;

  const AudioPlayerState._();

  /// Whether the bar should be rendered.
  bool get hasFile => currentUrl != null;
}
