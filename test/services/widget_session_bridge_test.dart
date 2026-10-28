import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('org.moviepilot/ios_shared_session');
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Android 登录时写入小组件会话并触发刷新', () async {
    final service = IosSharedSessionService();

    await service.syncSession(
      server: ' https://mp.example.com/ ',
      accessToken: ' token ',
    );
    await service.reloadWidgets();

    expect(calls.map((call) => call.method), [
      'saveSharedSession',
      'reloadWidgets',
    ]);
    expect(calls.first.arguments, {
      'server': 'https://mp.example.com/',
      'accessToken': 'token',
    });
  });

  test('Android 退出登录时清理小组件会话', () async {
    final service = IosSharedSessionService();

    await service.clearSession();

    expect(calls.single.method, 'clearSharedSession');
  });

  test('空凭证不会写入小组件会话', () async {
    final service = IosSharedSessionService();

    await service.syncSession(server: '   ', accessToken: 'token');

    expect(calls, isEmpty);
  });
}
