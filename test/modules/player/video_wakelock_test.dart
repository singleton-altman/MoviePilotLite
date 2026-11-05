import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanplayer_player/player/core/player_engine.dart';
import 'package:lanplayer_player/player/core/player_screen_awake.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus/wakelock_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _PlayerEngineFake implements PlayerEngine {
  _PlayerEngineFake([this._currentState = const PlayerState()]);

  final _states = StreamController<PlayerState>.broadcast();
  PlayerState _currentState;
  int currentStateReads = 0;

  @override
  PlayerState get currentState {
    currentStateReads++;
    return _currentState;
  }

  @override
  Stream<PlayerState> get stateStream => _states.stream;

  bool get hasListener => _states.hasListener;

  void emit(PlayerState state) {
    _currentState = state;
    _states.add(state);
  }

  void emitError() => _states.addError(StateError('state stream failed'));

  Future<void> close() => _states.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WakelockFake extends WakelockPlusPlatformInterface {
  final calls = <bool>[];
  Future<void> Function(bool enabled)? beforeApply;
  bool isEnabled = false;

  Future<void> setEnabled(bool enabled) async {
    calls.add(enabled);
    await beforeApply?.call(enabled);
    isEnabled = enabled;
  }

  @override
  Future<void> toggle({required bool enable}) => setEnabled(enable);

  @override
  Future<bool> get enabled async => isEnabled;
}

const _playing = PlayerState(isPlaying: true, playWhenReady: true);
const _paused = PlayerState(playWhenReady: false);

// Broadcast delivery is asynchronous; wait for it before observing output work.
Future<void> _settle(PlayerScreenAwake awake) async {
  await Future<void>.delayed(Duration.zero);
  await awake.settled;
}

Completer<void> _gate() {
  final gate = Completer<void>();
  addTearDown(() {
    if (!gate.isCompleted) gate.complete();
  });
  return gate;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'PlayerState preserves and changes playback intent through copyWith',
    () {
      expect(const PlayerState().playWhenReady, isNull);
      final buffering = const PlayerState(
        isBuffering: true,
      ).copyWith(playWhenReady: true);
      expect(buffering.playWhenReady, isTrue);
      expect(
        buffering.copyWith(position: const Duration(seconds: 1)).playWhenReady,
        isTrue,
      );
      expect(buffering.copyWith(playWhenReady: false).playWhenReady, isFalse);
      expect(buffering.isBuffering, isTrue);
    },
  );

  group('PlayerScreenAwake', () {
    late _PlayerEngineFake engine;
    late _WakelockFake output;
    late PlayerScreenAwake awake;

    setUp(() {
      engine = _PlayerEngineFake();
      output = _WakelockFake();
      awake = PlayerScreenAwake(setEnabled: output.setEnabled);
      addTearDown(() async {
        awake.dispose();
        await awake.settled;
        await engine.close();
      });
    });

    test('bind immediately enables an already playing video', () async {
      engine.emit(_playing);
      awake.bind(engine, isAudio: false);
      await _settle(awake);
      expect(output.calls, [true]);
      expect(output.isEnabled, isTrue);
      expect(engine.currentStateReads, 1);
      expect(engine.hasListener, isTrue);
    });

    test('idle does not enable; playback enables and pause releases', () async {
      awake.bind(engine, isAudio: false);
      await _settle(awake);
      expect(output.calls, isEmpty);
      engine.emit(_playing);
      await _settle(awake);
      expect(output.calls, [true]);
      engine.emit(_paused);
      await _settle(awake);
      expect(output.calls, [true, false]);
      expect(output.isEnabled, isFalse);
    });

    for (final intent in <bool?>[true, false, null]) {
      test(
        'initial buffering requires explicit playWhenReady=$intent',
        () async {
          engine.emit(PlayerState(isBuffering: true, playWhenReady: intent));
          awake.bind(engine, isAudio: false);
          await _settle(awake);
          expect(output.isEnabled, intent == true);
          expect(output.calls, intent == true ? [true] : isEmpty);
        },
      );
    }

    test(
      'buffering retains playing intent but releases for paused intent',
      () async {
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        engine.emit(const PlayerState(isBuffering: true, playWhenReady: true));
        await _settle(awake);
        expect(output.calls, [true]);
        engine.emit(const PlayerState(isBuffering: true, playWhenReady: false));
        await _settle(awake);
        expect(output.calls, [true, false]);
        engine.emit(const PlayerState(isBuffering: true, playWhenReady: true));
        await _settle(awake);
        expect(output.calls, [true, false, true]);
        engine.emit(const PlayerState(isBuffering: true));
        await _settle(awake);
        expect(output.calls, [true, false, true, false]);
      },
    );

    for (final terminal in <String, PlayerState>{
      'completion': _playing.copyWith(isCompleted: true),
      'playback error': _playing.copyWith(error: 'decoder failed'),
      'buffering completion': const PlayerState(
        isBuffering: true,
        playWhenReady: true,
        isCompleted: true,
      ),
      'buffering error': const PlayerState(
        isBuffering: true,
        playWhenReady: true,
        error: 'network failed',
      ),
    }.entries) {
      test('${terminal.key} overrides playback intent and releases', () async {
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        engine.emit(terminal.value);
        await _settle(awake);
        expect(output.calls, [true, false]);
        expect(output.isEnabled, isFalse);
      });
    }

    test('an empty error is not a playback failure', () async {
      engine.emit(_playing.copyWith(error: ''));
      awake.bind(engine, isAudio: false);
      await _settle(awake);
      expect(output.calls, [true]);
    });

    test(
      'stream error releases and a subsequent playing state can recover',
      () async {
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        engine.emitError();
        await _settle(awake);
        expect(output.calls, [true, false]);
        engine.emit(_playing);
        await _settle(awake);
        expect(output.calls, [true, false, true]);
      },
    );

    test('closing the engine state stream releases', () async {
      engine.emit(_playing);
      awake.bind(engine, isAudio: false);
      await _settle(awake);
      await engine.close();
      await _settle(awake);
      expect(output.calls, [true, false]);
      expect(output.isEnabled, isFalse);
    });

    test('audio never enables for playing or buffering events', () async {
      engine.emit(_playing);
      awake.bind(engine, isAudio: true);
      await _settle(awake);
      engine.emit(const PlayerState(isBuffering: true, playWhenReady: true));
      await _settle(awake);
      engine.emit(_playing);
      await _settle(awake);
      expect(output.calls, isEmpty);
    });

    test(
      'changing video to audio releases and changing back reacquires',
      () async {
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        awake.bind(engine, isAudio: true);
        await _settle(awake);
        expect(output.calls, [true, false]);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        expect(output.calls, [true, false, true]);
      },
    );

    test(
      'inactive does not release and still accepts new playback state',
      () async {
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        awake.didChangeAppLifecycleState(AppLifecycleState.inactive);
        await _settle(awake);
        expect(output.calls, [true]);
        engine.emit(_paused);
        await _settle(awake);
        expect(output.calls, [true, false]);
        engine.emit(_playing);
        await _settle(awake);
        expect(output.calls, [true, false, true]);
      },
    );

    for (final lifecycle in <AppLifecycleState>[
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    ]) {
      test(
        '$lifecycle releases and ignores late playing/buffering events',
        () async {
          engine.emit(_playing);
          awake.bind(engine, isAudio: false);
          await _settle(awake);
          awake.didChangeAppLifecycleState(lifecycle);
          await _settle(awake);
          expect(output.calls, [true, false]);
          engine.emit(_playing);
          engine.emit(
            const PlayerState(isBuffering: true, playWhenReady: true),
          );
          await _settle(awake);
          awake.didChangeAppLifecycleState(AppLifecycleState.inactive);
          await _settle(awake);
          expect(output.calls, [true, false]);
          expect(output.isEnabled, isFalse);
        },
      );

      test('initial $lifecycle ignores cached and streamed playback', () async {
        awake.dispose();
        awake = PlayerScreenAwake(
          setEnabled: output.setEnabled,
          initialLifecycleState: lifecycle,
        );
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        engine.emit(_playing);
        await _settle(awake);
        expect(engine.currentStateReads, 0);
        expect(output.calls, isEmpty);
        awake.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await _settle(awake);
        expect(output.calls, [false]);
        engine.emit(_playing);
        await _settle(awake);
        expect(output.calls, [false, true]);
      });
    }

    test(
      'resuming waits for fresh state rather than cached playing state',
      () async {
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        awake.didChangeAppLifecycleState(AppLifecycleState.paused);
        await _settle(awake);
        engine.emit(_playing);
        await _settle(awake);
        awake.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await _settle(awake);
        expect(output.calls, [true, false, false]);
        expect(output.isEnabled, isFalse);
        expect(engine.currentStateReads, 1);
        engine.emit(_paused);
        await _settle(awake);
        expect(output.calls, [true, false, false]);
        engine.emit(_playing);
        await _settle(awake);
        expect(output.calls, [true, false, false, true]);
      },
    );

    test('resuming invalidates an active output and reapplies it', () async {
      engine.emit(_playing);
      awake.bind(engine, isAudio: false);
      await _settle(awake);
      awake.didChangeAppLifecycleState(AppLifecycleState.inactive);
      awake.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _settle(awake);
      expect(output.calls, [true, true]);
    });

    test(
      'replacing engine ignores queued old data, errors and stream close',
      () async {
        final replacement = _PlayerEngineFake(_paused);
        addTearDown(replacement.close);
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        engine.emit(_playing);
        engine.emitError();
        awake.bind(replacement, isAudio: false);
        await _settle(awake);
        expect(output.calls, [true, false]);
        expect(engine.hasListener, isFalse);
        replacement.emit(_playing);
        await _settle(awake);
        engine.emit(_paused);
        engine.emitError();
        await engine.close();
        await _settle(awake);
        expect(output.calls, [true, false, true]);
        expect(output.isEnabled, isTrue);
      },
    );

    test('unbinding releases and stops listening to the old engine', () async {
      engine.emit(_playing);
      awake.bind(engine, isAudio: false);
      await _settle(awake);
      awake.bind(null, isAudio: false);
      await _settle(awake);
      expect(engine.hasListener, isFalse);
      engine.emit(_playing);
      await _settle(awake);
      expect(output.calls, [true, false]);
    });

    test(
      'dispose is idempotent and ignores events, lifecycle and later binds',
      () async {
        final replacement = _PlayerEngineFake(_playing);
        addTearDown(replacement.close);
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        awake.dispose();
        awake.dispose();
        await _settle(awake);
        expect(engine.hasListener, isFalse);
        engine.emit(_playing);
        engine.emitError();
        awake.didChangeAppLifecycleState(AppLifecycleState.resumed);
        awake.bind(replacement, isAudio: false);
        await _settle(awake);
        expect(output.calls, [true, false]);
        expect(replacement.hasListener, isFalse);
        expect(replacement.currentStateReads, 0);
      },
    );

    test(
      'disposing before binding does not issue a platform request',
      () async {
        awake.dispose();
        awake.dispose();
        await _settle(awake);
        expect(output.calls, isEmpty);
      },
    );

    test(
      'repeated states and identical binds deduplicate successful output',
      () async {
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        awake.bind(engine, isAudio: false);
        for (var i = 0; i < 3; i++) {
          engine.emit(_playing.copyWith(position: Duration(seconds: i)));
          await _settle(awake);
        }
        expect(output.calls, [true]);
        expect(engine.currentStateReads, 1);
        for (var i = 0; i < 3; i++) {
          engine.emit(_paused);
          await _settle(awake);
        }
        expect(output.calls, [true, false]);
      },
    );

    for (final exiting in ['dispose', 'background', 'unbind']) {
      test('pending enable followed by $exiting finishes disabled', () async {
        final gate = _gate();
        output.beforeApply = (enabled) async {
          if (enabled) await gate.future;
        };
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        expect(output.calls, [true]);
        switch (exiting) {
          case 'dispose':
            awake.dispose();
          case 'background':
            awake.didChangeAppLifecycleState(AppLifecycleState.hidden);
          case 'unbind':
            awake.bind(null, isAudio: false);
        }
        expect(output.calls, [true]);
        gate.complete();
        await _settle(awake);
        expect(output.calls, [true, false]);
        expect(output.isEnabled, isFalse);
      });
    }

    test(
      'enable failure is swallowed and the next playing event retries',
      () async {
        var fail = true;
        output.beforeApply = (enabled) async {
          if (enabled && fail) {
            fail = false;
            throw StateError('enable failed');
          }
        };
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        expect(output.calls, [true]);
        expect(output.isEnabled, isFalse);
        engine.emit(_playing);
        await _settle(awake);
        expect(output.calls, [true, true]);
        expect(output.isEnabled, isTrue);
        engine.emit(_playing);
        await _settle(awake);
        expect(output.calls, [true, true]);
      },
    );

    test(
      'disable failure is swallowed and the next paused event retries',
      () async {
        engine.emit(_playing);
        awake.bind(engine, isAudio: false);
        await _settle(awake);
        var fail = true;
        output.beforeApply = (enabled) async {
          if (!enabled && fail) {
            fail = false;
            throw StateError('disable failed');
          }
        };
        engine.emit(_paused);
        await _settle(awake);
        expect(output.calls, [true, false]);
        expect(output.isEnabled, isTrue);
        engine.emit(_paused);
        await _settle(awake);
        expect(output.calls, [true, false, false]);
        expect(output.isEnabled, isFalse);
      },
    );

    test('enable failing after disposal still sends a final disable', () async {
      final gate = _gate();
      output.beforeApply = (enabled) async {
        if (enabled) {
          await gate.future;
          throw StateError('late enable failure');
        }
      };
      engine.emit(_playing);
      awake.bind(engine, isAudio: false);
      awake.dispose();
      gate.complete();
      await _settle(awake);
      expect(output.calls, [true, false]);
      expect(output.isEnabled, isFalse);
    });
  });

  group('default shared wakelock output', () {
    late _WakelockFake platform;
    late WakelockPlusPlatformInterface previousPlatform;
    late List<PlayerScreenAwake> owners;
    late List<_PlayerEngineFake> engines;

    setUp(() {
      previousPlatform = wakelockPlusPlatformInstance;
      wakelockPlusPlatformInstance = platform = _WakelockFake();
      owners = [];
      engines = [];
      addTearDown(() async {
        try {
          for (final owner in owners) {
            owner.dispose();
          }
          for (final owner in owners) {
            await owner.settled;
          }
          for (final engine in engines) {
            await engine.close();
          }
        } finally {
          wakelockPlusPlatformInstance = previousPlatform;
        }
      });
    });

    PlayerScreenAwake createOwner({bool isAudio = false}) {
      final engine = _PlayerEngineFake(_playing);
      engines.add(engine);
      final owner = PlayerScreenAwake();
      owners.add(owner);
      owner.bind(engine, isAudio: isAudio);
      return owner;
    }

    test(
      'releasing one owner does not disable another playing owner',
      () async {
        final first = createOwner();
        await _settle(first);
        final second = createOwner();
        await _settle(second);
        expect(platform.calls, [true]);
        engines.first.emit(_paused);
        await _settle(first);
        first.dispose();
        await _settle(first);
        expect(platform.calls, [true]);
        expect(platform.isEnabled, isTrue);
        second.dispose();
        await _settle(second);
        expect(platform.calls, [true, false]);
        expect(platform.isEnabled, isFalse);
      },
    );

    test(
      'an audio owner cannot retain or release a video owner lock',
      () async {
        final video = createOwner();
        await _settle(video);
        final audio = createOwner(isAudio: true);
        await _settle(audio);
        audio.didChangeAppLifecycleState(AppLifecycleState.hidden);
        audio.dispose();
        await _settle(audio);
        expect(platform.calls, [true]);
        video.dispose();
        await _settle(video);
        expect(platform.calls, [true, false]);
      },
    );

    test(
      'late enable from disposed old owner respects the new owner',
      () async {
        final gate = _gate();
        platform.beforeApply = (enabled) async {
          if (enabled) await gate.future;
        };
        final oldOwner = createOwner();
        oldOwner.dispose();
        final newOwner = createOwner();
        expect(platform.calls, [true]);
        gate.complete();
        await _settle(newOwner);
        expect(platform.calls, [true]);
        expect(platform.isEnabled, isTrue);
        newOwner.dispose();
        await _settle(newOwner);
        expect(platform.calls, [true, false]);
        expect(platform.isEnabled, isFalse);
      },
    );

    test(
      'pending old-owner disable is followed by enable for the new owner',
      () async {
        final oldOwner = createOwner();
        await _settle(oldOwner);
        final gate = _gate();
        platform.beforeApply = (enabled) async {
          if (!enabled) await gate.future;
        };
        oldOwner.dispose();
        expect(platform.calls, [true, false]);
        final newOwner = createOwner();
        gate.complete();
        await _settle(newOwner);
        expect(platform.calls, [true, false, true]);
        expect(platform.isEnabled, isTrue);
        newOwner.dispose();
        await _settle(newOwner);
        expect(platform.calls, [true, false, true, false]);
        expect(platform.isEnabled, isFalse);
      },
    );
  });
}
