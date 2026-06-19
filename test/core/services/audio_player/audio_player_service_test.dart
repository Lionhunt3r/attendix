import 'dart:async';

import 'package:attendix/core/services/audio_player/audio_player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

class _FakeAudioPlayer implements AudioPlayer {
  final _playingCtrl = StreamController<bool>.broadcast();
  final _positionCtrl = StreamController<Duration>.broadcast();
  final _durationCtrl = StreamController<Duration?>.broadcast();
  final _processingStateCtrl = StreamController<ProcessingState>.broadcast();

  @override
  bool playing = false;
  @override
  Duration position = Duration.zero;
  String? lastUrl;
  bool disposed = false;

  @override
  Stream<bool> get playingStream => _playingCtrl.stream;

  @override
  Stream<Duration> get positionStream => _positionCtrl.stream;

  @override
  Stream<Duration?> get durationStream => _durationCtrl.stream;

  @override
  Stream<ProcessingState> get processingStateStream =>
      _processingStateCtrl.stream;

  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    lastUrl = url;
    return const Duration(minutes: 3);
  }

  @override
  Future<void> play() async {
    playing = true;
    _playingCtrl.add(true);
  }

  @override
  Future<void> pause() async {
    playing = false;
    _playingCtrl.add(false);
  }

  @override
  Future<void> stop() async {
    playing = false;
    _playingCtrl.add(false);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    this.position = position ?? Duration.zero;
    _positionCtrl.add(this.position);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _playingCtrl.close();
    await _positionCtrl.close();
    await _durationCtrl.close();
    await _processingStateCtrl.close();
  }

  // Test helpers
  void emitPosition(Duration p) => _positionCtrl.add(p);
  void emitProcessingState(ProcessingState s) => _processingStateCtrl.add(s);

  // Unused members throw to keep the test honest about coverage.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  group('AudioPlayerService.isAudioFile', () {
    test('matches all 9 supported extensions, case-insensitive', () {
      const cases = [
        'foo.mp3',
        'FOO.WAV',
        'piece.ogg',
        'voice.m4a',
        'note.aac',
        'tune.flac',
        'old.wma',
        'web.webm',
        'opus.opus',
        'CAPS.MP3',
      ];
      for (final c in cases) {
        expect(AudioPlayerService.isAudioFile(c), isTrue, reason: c);
      }
    });

    test('rejects non-audio extensions', () {
      expect(AudioPlayerService.isAudioFile('score.pdf'), isFalse);
      expect(AudioPlayerService.isAudioFile('cover.jpg'), isFalse);
      expect(AudioPlayerService.isAudioFile(''), isFalse);
    });
  });

  group('AudioPlayerService.formatTime', () {
    test('formats Duration as m:ss', () {
      expect(AudioPlayerService.formatTime(Duration.zero), '0:00');
      expect(
        AudioPlayerService.formatTime(const Duration(seconds: 5)),
        '0:05',
      );
      expect(
        AudioPlayerService.formatTime(const Duration(minutes: 1, seconds: 30)),
        '1:30',
      );
      expect(
        AudioPlayerService.formatTime(
          const Duration(minutes: 12, seconds: 45),
        ),
        '12:45',
      );
    });
  });

  group('AudioPlayerService notifier', () {
    late _FakeAudioPlayer fake;

    ProviderContainer makeContainer() {
      fake = _FakeAudioPlayer();
      return ProviderContainer(
        overrides: [
          audioPlayerFactoryProvider.overrideWithValue(() => fake),
        ],
      );
    }

    test('initial state has no file and is not playing', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      final state = c.read(audioPlayerServiceProvider);
      expect(state.hasFile, isFalse);
      expect(state.isPlaying, isFalse);
    });

    test('playFromUrl sets currentUrl, currentSongName and starts playback',
        () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final svc = c.read(audioPlayerServiceProvider.notifier);

      await svc.playFromUrl(
        'https://example.com/song.mp3',
        'song.mp3',
        'Test Song',
      );

      final state = c.read(audioPlayerServiceProvider);
      expect(state.currentUrl, 'https://example.com/song.mp3');
      expect(state.currentSongName, 'Test Song');
      expect(state.currentFileName, 'song.mp3');
      expect(fake.lastUrl, 'https://example.com/song.mp3');
      expect(fake.playing, isTrue);
    });

    test('togglePlayPause flips between play and pause', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final svc = c.read(audioPlayerServiceProvider.notifier);

      await svc.playFromUrl('https://example.com/a.mp3', 'a.mp3', 'A');
      expect(fake.playing, isTrue);

      await svc.togglePlayPause();
      expect(fake.playing, isFalse);

      await svc.togglePlayPause();
      expect(fake.playing, isTrue);
    });

    test('stop clears state and stops the underlying player', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final svc = c.read(audioPlayerServiceProvider.notifier);

      await svc.playFromUrl('https://example.com/a.mp3', 'a.mp3', 'A');
      await svc.stop();

      final state = c.read(audioPlayerServiceProvider);
      expect(state.hasFile, isFalse);
      expect(state.isPlaying, isFalse);
    });

    test('isSeeking suppresses position updates while user drags', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      final svc = c.read(audioPlayerServiceProvider.notifier);

      await svc.playFromUrl('https://example.com/a.mp3', 'a.mp3', 'A');
      svc.startSeeking();

      // Simulate a position event from just_audio while seeking
      fake.emitPosition(const Duration(seconds: 30));
      await Future<void>.delayed(Duration.zero);

      // currentTime must NOT have followed the event — anti-flicker.
      expect(c.read(audioPlayerServiceProvider).currentTime, Duration.zero);

      // Releasing the slider seeks AND re-enables position updates.
      await svc.stopSeeking(const Duration(seconds: 90));
      expect(fake.position, const Duration(seconds: 90));
      expect(c.read(audioPlayerServiceProvider).isSeeking, isFalse);
    });
  });
}
