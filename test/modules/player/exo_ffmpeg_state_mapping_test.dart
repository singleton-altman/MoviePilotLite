import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanplayer_player/player/core/player_engine.dart';
import 'package:lanplayer_player/player/exo/exo_ffmpeg_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.lanplayer/exo_ffmpeg');
  const stateChannel = MethodChannel('com.lanplayer/exo_ffmpeg_state');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ExoFFmpegEngine engine;
  late Map<String, dynamic> openResult;
  late Map<String, dynamic> polledState;
  late int pollCount;

  Future<void> pushState(Map<String, dynamic> state) async {
    final delivered = Completer<void>();
    messenger.handlePlatformMessage(
      stateChannel.name,
      const StandardMethodCodec().encodeSuccessEnvelope(state),
      (_) => delivered.complete(),
    );
    await delivered.future;
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    engine = ExoFFmpegEngine();
    openResult = <String, dynamic>{'durationMs': 120000};
    polledState = <String, dynamic>{};
    pollCount = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isFFmpegAvailable':
          return false;
        case 'open':
          return openResult;
        case 'getState':
          pollCount++;
          return polledState;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(stateChannel, (_) async => null);
  });

  tearDown(() async {
    await engine.dispose();
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(stateChannel, null);
  });

  test(
    'open maps buffering, intent and completion independently of isPlaying',
    () async {
      openResult = {
        'isPlaying': false,
        'isBuffering': true,
        'playWhenReady': true,
        'isCompleted': false,
      };
      await engine.open(url: 'https://example.test/video', autoPlay: false);
      expect(engine.currentState.isPlaying, isFalse);
      expect(engine.currentState.isBuffering, isTrue);
      expect(engine.currentState.playWhenReady, isTrue);
      expect(engine.currentState.isCompleted, isFalse);

      openResult = {
        'isPlaying': false,
        'isBuffering': false,
        'playWhenReady': false,
        'isCompleted': true,
      };
      await engine.open(url: 'https://example.test/ended');
      expect(engine.currentState.playWhenReady, isFalse);
      expect(engine.currentState.isBuffering, isFalse);
      expect(engine.currentState.isCompleted, isTrue);
    },
  );

  test(
    'legacy open uses this request and clears previous completion and buffering',
    () async {
      openResult = {
        'playWhenReady': true,
        'isBuffering': true,
        'isCompleted': true,
      };
      await engine.open(url: 'https://example.test/first');
      openResult = {};
      await engine.open(url: 'https://example.test/second', autoPlay: false);
      expect(engine.currentState.playWhenReady, isFalse);
      expect(engine.currentState.isPlaying, isFalse);
      expect(engine.currentState.isBuffering, isFalse);
      expect(engine.currentState.isCompleted, isFalse);

      await engine.open(url: 'https://example.test/third');
      expect(engine.currentState.playWhenReady, isTrue);
    },
  );

  test(
    'events distinguish playing, buffering, paused buffering and ended',
    () async {
      await engine.open(url: 'https://example.test/video');
      for (final state in <Map<String, dynamic>>[
        {
          'isPlaying': true,
          'isBuffering': false,
          'playWhenReady': true,
          'isCompleted': false,
        },
        {
          'isPlaying': false,
          'isBuffering': true,
          'playWhenReady': true,
          'isCompleted': false,
        },
        {
          'isPlaying': false,
          'isBuffering': true,
          'playWhenReady': false,
          'isCompleted': false,
        },
        {
          'isPlaying': false,
          'isBuffering': false,
          'playWhenReady': true,
          'isCompleted': true,
        },
      ]) {
        await pushState(state);
        expect(engine.currentState.isPlaying, state['isPlaying']);
        expect(engine.currentState.isBuffering, state['isBuffering']);
        expect(engine.currentState.playWhenReady, state['playWhenReady']);
        expect(engine.currentState.isCompleted, state['isCompleted']);
      }
    },
  );

  test(
    'legacy events reset intent and completion instead of retaining old values',
    () async {
      await engine.open(url: 'https://example.test/video');
      await pushState({'playWhenReady': true, 'isCompleted': true});
      await pushState({'isPlaying': false, 'isBuffering': true});
      expect(engine.currentState.playWhenReady, isFalse);
      expect(engine.currentState.isCompleted, isFalse);

      await pushState({'isPlaying': true});
      expect(engine.currentState.playWhenReady, isTrue);
      expect(engine.currentState.isCompleted, isFalse);
      await pushState({});
      expect(engine.currentState.playWhenReady, isFalse);
    },
  );

  test('null optional fields use explicit compatibility defaults', () async {
    openResult = {
      'playWhenReady': null,
      'isCompleted': null,
      'isBuffering': null,
    };
    await engine.open(url: 'https://example.test/video', autoPlay: false);
    expect(engine.currentState.playWhenReady, isFalse);
    expect(engine.currentState.isCompleted, isFalse);
    expect(engine.currentState.isBuffering, isFalse);

    await pushState({
      'isPlaying': true,
      'playWhenReady': null,
      'isCompleted': null,
    });
    expect(engine.currentState.playWhenReady, isTrue);
    expect(engine.currentState.isCompleted, isFalse);
  });

  test('copyWith preserves omitted errors and clears explicit null', () {
    const state = PlayerState(error: 'decode failed', playWhenReady: true);
    expect(state.copyWith(isBuffering: true).error, 'decode failed');
    expect(state.copyWith(error: null).error, isNull);
    expect(state.copyWith(error: 'new failure').error, 'new failure');
    expect(state.copyWith(error: null).playWhenReady, isTrue);
  });

  test('successful new open clears the previous media error', () async {
    await engine.open(url: 'https://example.test/video');
    await pushState({'error': 'decode failed', 'playWhenReady': false});
    expect(engine.currentState.error, 'decode failed');

    openResult = {'isBuffering': true, 'playWhenReady': true};
    await engine.open(url: 'https://example.test/transcoded');
    expect(engine.currentState.error, isNull);
    expect(engine.currentState.playWhenReady, isTrue);
    expect(engine.currentState.isBuffering, isTrue);
  });

  test(
    'healthy snapshots clear errors for null and missing error fields',
    () async {
      await engine.open(url: 'https://example.test/video');
      for (final healthy in <Map<String, dynamic>>[
        {'isPlaying': true, 'playWhenReady': true, 'error': null},
        {'isPlaying': false, 'isBuffering': true, 'playWhenReady': true},
      ]) {
        await pushState({'error': 'decode failed', 'playWhenReady': false});
        expect(engine.currentState.error, 'decode failed');
        await pushState(healthy);
        expect(engine.currentState.error, isNull);
        expect(engine.currentState.playWhenReady, isTrue);
      }
    },
  );

  test('fallback polling uses the same native state mapping', () async {
    await engine.open(url: 'https://example.test/video');
    polledState = {
      'isPlaying': false,
      'isBuffering': true,
      'playWhenReady': false,
      'isCompleted': true,
    };
    final deadline = DateTime.now().add(const Duration(seconds: 4));
    while (pollCount == 0 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(pollCount, greaterThan(0));
    expect(engine.currentState.isPlaying, isFalse);
    expect(engine.currentState.isBuffering, isTrue);
    expect(engine.currentState.playWhenReady, isFalse);
    expect(engine.currentState.isCompleted, isTrue);
  });
}
