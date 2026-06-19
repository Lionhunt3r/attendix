import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_player_state.dart';

/// Factory for the underlying `just_audio` `AudioPlayer`.
///
/// Tests override this with a fake; production uses the real player.
final audioPlayerFactoryProvider = Provider<AudioPlayer Function()>(
  (_) => AudioPlayer.new,
);

/// Cross-cutting audio playback service.
///
/// Mirrors Ionic v4.0.5 `AudioPlayerService` (`audio-player.service.ts`).
/// Exactly one file plays at a time. Calling `play`/`playFromUrl` while
/// another file is loaded stops the current playback first.
class AudioPlayerService extends Notifier<AudioPlayerState> {
  AudioPlayer? _player;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<ProcessingState>? _processingSub;

  static const _audioExtensions = [
    '.mp3',
    '.wav',
    '.ogg',
    '.m4a',
    '.aac',
    '.flac',
    '.wma',
    '.webm',
    '.opus',
  ];

  /// True if the file name ends with any recognized audio extension.
  static bool isAudioFile(String fileName) {
    final lower = fileName.toLowerCase();
    return _audioExtensions.any(lower.endsWith);
  }

  /// `m:ss` formatting for slider labels (e.g. `1:30`, `12:45`).
  static String formatTime(Duration d) {
    if (d == Duration.zero) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  AudioPlayerState build() {
    ref.onDispose(_disposePlayer);
    return const AudioPlayerState();
  }

  Future<void> playFromUrl(
    String url,
    String fileName,
    String songName,
  ) async {
    await _stopInternal();

    final player = ref.read(audioPlayerFactoryProvider)();
    _player = player;
    _wireStreams(player);

    final loadedDuration = await player.setUrl(url);
    state = state.copyWith(
      currentUrl: url,
      currentFileName: fileName,
      currentSongName: songName,
      duration: loadedDuration ?? Duration.zero,
      currentTime: Duration.zero,
      isSeeking: false,
    );
    await player.play();
  }

  Future<void> togglePlayPause() async {
    final player = _player;
    if (player == null) return;
    if (state.isPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> stop() => _stopInternal();

  Future<void> seek(Duration position) async {
    final player = _player;
    if (player == null) return;
    await player.seek(position);
    state = state.copyWith(currentTime: position);
  }

  void startSeeking() {
    state = state.copyWith(isSeeking: true);
  }

  Future<void> stopSeeking(Duration position) async {
    state = state.copyWith(isSeeking: false);
    await seek(position);
  }

  void _wireStreams(AudioPlayer player) {
    _playingSub = player.playingStream.listen((p) {
      state = state.copyWith(isPlaying: p);
    });
    _positionSub = player.positionStream.listen((pos) {
      // Anti-flicker: while the user drags the slider, ignore the player's
      // own position updates so the knob doesn't snap back.
      if (state.isSeeking) return;
      state = state.copyWith(currentTime: pos);
    });
    _durationSub = player.durationStream.listen((d) {
      if (d != null) state = state.copyWith(duration: d);
    });
    _processingSub = player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) {
        state = state.copyWith(
          isPlaying: false,
          currentTime: Duration.zero,
        );
      }
    });
  }

  Future<void> _stopInternal() async {
    await _playingSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _processingSub?.cancel();
    _playingSub = null;
    _positionSub = null;
    _durationSub = null;
    _processingSub = null;

    final player = _player;
    if (player != null) {
      await player.stop();
      await player.dispose();
      _player = null;
    }
    state = const AudioPlayerState();
  }

  void _disposePlayer() {
    // Best-effort fire-and-forget; a Notifier's onDispose can't await.
    unawaited(_stopInternal());
  }
}

final audioPlayerServiceProvider =
    NotifierProvider<AudioPlayerService, AudioPlayerState>(
  AudioPlayerService.new,
);
