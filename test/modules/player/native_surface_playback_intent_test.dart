import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanplayer_player/player/native_surface/native_surface_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('lanplayer/mpv_surface_110');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late NativeSurfaceEngine engine;
  late List<MethodCall> calls;
  Completer<bool>? createResponse;
  late bool createSucceeds;
  late bool nativePlaying;
  late bool nativeReady;

  List<MethodCall> getCreates() =>
      calls.where((call) => call.method == 'create').toList();
  List<dynamic> getCommands() => calls
      .where((call) => call.method == 'command')
      .map((call) => call.arguments)
      .toList();

  setUp(() {
    engine = NativeSurfaceEngine();
    calls = [];
    createResponse = null;
    createSucceeds = true;
    nativePlaying = false;
    nativeReady = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'create':
          final ok = await (createResponse?.future ?? Future.value(createSucceeds));
          if (ok) {
            nativeReady = true;
            nativePlaying = (call.arguments as Map)['autoPlay'] as bool;
          }
          return ok;
        case 'command':
          // Model the native contract: commands before create succeeds are lost.
          if (!nativeReady) return false;
          nativePlaying = call.arguments == 'set pause no';
          return true;
        case 'destroy':
          nativeReady = false;
          nativePlaying = false;
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    await engine.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('foreground autoplay starts after delayed platform view creation',
      (tester) async {
    final opening = engine.open(url: 'https://example.test/video');
    expect(engine.currentState.playWhenReady, isTrue);
    await opening;
    expect(calls, isEmpty);

    engine.attachPlatformChannel(110);
    await tester.pump();

    expect(getCreates(), hasLength(1));
    // Even autoplay creates paused; only the latest intent can start playback.
    expect((getCreates().single.arguments as Map)['autoPlay'], isFalse);
    expect(getCommands(), ['set pause no']);
    expect(nativePlaying, isTrue);
    await engine.dispose();
  });

  testWidgets('autoplay false stays paused and preserves pending media arguments',
      (tester) async {
    const headers = {'Authorization': 'test-only-token'};
    await engine.open(
      url: 'https://example.test/paused',
      httpHeaders: headers,
      autoPlay: false,
    );
    expect(engine.currentState.playWhenReady, isFalse);

    engine.attachPlatformChannel(110);
    await tester.pump();

    final args = getCreates().single.arguments as Map;
    expect(args['url'], 'https://example.test/paused');
    expect(args['headers'], headers);
    expect(args['autoPlay'], isFalse);
    expect(getCommands(), ['set pause yes']);
    expect(nativePlaying, isFalse);
    await engine.dispose();
  });

  testWidgets('pause before channel readiness synchronously replaces autoplay',
      (tester) async {
    await engine.open(url: 'https://example.test/video');
    final pausing = engine.pause();
    expect(engine.currentState.playWhenReady, isFalse);
    await pausing;
    expect(calls, isEmpty);

    engine.attachPlatformChannel(110);
    await tester.pump();

    expect(getCommands(), ['set pause yes']);
    expect(nativePlaying, isFalse);
    await engine.dispose();
  });

  testWidgets('play before readiness synchronously replaces paused open intent',
      (tester) async {
    await engine.open(url: 'https://example.test/video', autoPlay: false);
    final playing = engine.play();
    expect(engine.currentState.playWhenReady, isTrue);
    await playing;

    engine.attachPlatformChannel(110);
    await tester.pump();

    expect(getCommands(), ['set pause no']);
    expect(nativePlaying, isTrue);
    await engine.dispose();
  });

  testWidgets('pause during async create cannot briefly start stale autoplay',
      (tester) async {
    createResponse = Completer<bool>();
    engine.attachPlatformChannel(110);
    final opening = engine.open(url: 'https://example.test/video');
    await tester.pump();
    expect(getCreates(), hasLength(1));

    final pausing = engine.pause();
    expect(engine.currentState.playWhenReady, isFalse);
    await pausing;
    expect(getCommands(), isEmpty);

    createResponse!.complete(true);
    await tester.pump();
    await opening;

    expect((getCreates().single.arguments as Map)['autoPlay'], isFalse);
    expect(getCommands(), ['set pause yes']);
    expect(nativePlaying, isFalse);
    await engine.dispose();
  });

  testWidgets('pending platform view create uses the last play and pause intent',
      (tester) async {
    createResponse = Completer<bool>();
    await engine.open(url: 'https://example.test/video', autoPlay: false);
    engine.attachPlatformChannel(110);
    await tester.pump();

    await engine.play();
    await engine.pause();
    final playing = engine.play();
    expect(engine.currentState.playWhenReady, isTrue);
    await playing;
    expect(getCommands(), isEmpty);

    createResponse!.complete(true);
    await tester.pump();

    expect(getCommands(), ['set pause no']);
    expect(nativePlaying, isTrue);
    await engine.dispose();
  });

  testWidgets('ready engine continues to forward play and pause normally',
      (tester) async {
    engine.attachPlatformChannel(110);
    await engine.open(url: 'https://example.test/video');
    final pausing = engine.pause();
    expect(engine.currentState.playWhenReady, isFalse);
    await pausing;
    expect(nativePlaying, isFalse);

    final playing = engine.play();
    expect(engine.currentState.playWhenReady, isTrue);
    await playing;
    expect(nativePlaying, isTrue);
    expect(getCommands(), ['set pause no', 'set pause yes', 'set pause no']);
    await engine.dispose();
  });

  testWidgets('a newer pending open replaces both media and playback intent',
      (tester) async {
    await engine.open(url: 'https://example.test/old');
    await engine.pause();
    await engine.open(url: 'https://example.test/new');
    expect(engine.currentState.playWhenReady, isTrue);
    await engine.open(url: 'https://example.test/latest', autoPlay: false);

    engine.attachPlatformChannel(110);
    await tester.pump();

    expect(getCreates(), hasLength(1));
    expect((getCreates().single.arguments as Map)['url'],
        'https://example.test/latest');
    expect(engine.currentState.playWhenReady, isFalse);
    expect(getCommands(), ['set pause yes']);
    expect(nativePlaying, isFalse);
    await engine.dispose();
  });

  testWidgets('failed create does not send playback commands or start polling',
      (tester) async {
    createSucceeds = false;
    engine.attachPlatformChannel(110);
    await engine.open(url: 'https://example.test/video');
    await engine.play();
    await tester.pump(const Duration(seconds: 1));

    expect(calls.map((call) => call.method), ['create']);
    expect(nativePlaying, isFalse);
    await engine.dispose();
  });

  testWidgets('dispose before view readiness prevents late attach and playback',
      (tester) async {
    await engine.open(url: 'https://example.test/video');
    await engine.dispose();
    engine.attachPlatformChannel(110);
    await engine.play();
    await engine.pause();
    await engine.open(url: 'https://example.test/after-dispose');
    await tester.pump(const Duration(seconds: 1));

    expect(calls, isEmpty);
    expect(nativePlaying, isFalse);
  });

  testWidgets('dispose during create prevents completion from playing or polling',
      (tester) async {
    createResponse = Completer<bool>();
    engine.attachPlatformChannel(110);
    final opening = engine.open(url: 'https://example.test/video');
    await tester.pump();
    await engine.dispose();

    createResponse!.complete(true);
    await tester.pump();
    await opening;
    await tester.pump(const Duration(seconds: 1));

    expect(calls.map((call) => call.method), ['create', 'destroy']);
    expect(getCommands(), isEmpty);
    expect(nativePlaying, isFalse);
  });

  testWidgets('stale create completion cannot start a newer pending open',
      (tester) async {
    final firstResponse = Completer<bool>();
    createResponse = firstResponse;
    engine.attachPlatformChannel(110);
    final firstOpen = engine.open(url: 'https://example.test/old');
    await tester.pump();

    final latestResponse = Completer<bool>();
    createResponse = latestResponse;
    final latestOpen = engine.open(url: 'https://example.test/latest');
    await tester.pump();
    firstResponse.complete(true);
    await tester.pump();
    await firstOpen;
    expect(getCommands(), isEmpty);
    expect(nativePlaying, isFalse);

    latestResponse.complete(true);
    await tester.pump();
    await latestOpen;
    expect(getCommands(), ['set pause no']);
    expect(nativePlaying, isTrue);
    await engine.dispose();
  });
}
