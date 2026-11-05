import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/hive_service.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';

class _LocalHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'secondary API-key rejection does not recover or clear JWT session',
    () async {
      Get.testMode = true;
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp(
        'moviepilot-auth-test-',
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => directory.path);
      addTearDown(() async {
        await server.close(force: true);
        Get.reset();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        await directory.delete(recursive: true);
      });
      server.listen((request) async {
        await request.drain<void>();
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"detail":"Invalid API key"}');
        await request.response.close();
      });
      Get.put(AppService());
      Get.put(HiveService());
      Get.put(AppLog());
      Get.put(IosSharedSessionService());
      final client = HttpOverrides.runWithHttpOverrides(
        () => Get.put(ApiClient()),
        _LocalHttpOverrides(),
      );
      Get.routing.current = '/mcp-tools';
      client.setBaseUrl('http://127.0.0.1:${server.port}');
      client.setToken('retained-jwt');
      var recoveryAttempts = 0;
      client.setAuthRecoveryHandler(() async {
        recoveryAttempts++;
        return false;
      });
      final response = await HttpOverrides.runWithHttpOverrides(
        () => client.post<dynamic>(
          '/api/v1/mcp/tools/call',
          data: {'name': 'example', 'arguments': <String, dynamic>{}},
          headers: {'X-API-KEY': 'invalid-test-key'},
          skipUnauthorizedHandling: true,
        ),
        _LocalHttpOverrides(),
      );
      expect(response.statusCode, HttpStatus.unauthorized);
      expect(response.requestOptions.extra['skipUnauthorizedHandling'], isTrue);
      expect(client.token, 'retained-jwt');
      expect(recoveryAttempts, 0);
    },
  );

  test('401 权限不足的响应体会传达到恢复器，不被当作会话失效', () async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp(
      'moviepilot-auth-perm-test-',
    );
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => directory.path);
    addTearDown(() async {
      await server.close(force: true);
      Get.reset();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await directory.delete(recursive: true);
    });
    server.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"detail":"用户权限不足"}');
      await request.response.close();
    });
    Get.put(AppService());
    Get.put(HiveService());
    Get.put(AppLog());
    Get.put(IosSharedSessionService());
    final client = HttpOverrides.runWithHttpOverrides(
      () => Get.put(ApiClient()),
      _LocalHttpOverrides(),
    );
    Get.routing.current = '/dashboard';
    client.setBaseUrl('http://127.0.0.1:${server.port}');
    client.setToken('valid-jwt');
    var recoveryAttempts = 0;
    client.setAuthRecoveryHandler(() async {
      recoveryAttempts++;
      return false;
    });
    final response = await HttpOverrides.runWithHttpOverrides(
      () => client.get<dynamic>('/api/v1/dashboard/cpu'),
      _LocalHttpOverrides(),
    );
    expect(response.statusCode, HttpStatus.unauthorized);
    // 权限不足不应触发静默重登
    expect(recoveryAttempts, 0);
    expect(client.token, 'valid-jwt');
  });
}
