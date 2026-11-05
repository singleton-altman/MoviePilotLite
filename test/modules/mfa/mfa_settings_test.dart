import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/modules/login/models/login_response.dart';
import 'package:moviepilot_mobile/modules/mfa/controllers/mfa_settings_controller.dart';
import 'package:moviepilot_mobile/modules/mfa/pages/mfa_settings_page.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

class _App implements AppService {
  @override
  LoginResponse get loginResponse => const LoginResponse(
    accessToken: 'token',
    tokenType: 'bearer',
    userId: 1,
    userName: 'a/b #',
    level: 1,
    permissions: {},
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Version implements ServerApiVersionService {
  _Version([this.v3 = true]);
  final bool v3;
  @override
  Future<bool> isV3() async => v3;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api implements ApiClient {
  final paths = <String>[];
  final bodies = <Map<String, dynamic>?>[];
  final responses = <String, dynamic>{};
  final statuses = <String, int>{};
  Completer<Response<dynamic>>? pendingPost;
  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
    bool skipV3EnvelopeUnwrap = false,
  }) async {
    paths.add(path);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: statuses[path] ?? 200,
      data: responses[path] as T,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
  }) async {
    paths.add(path);
    bodies.add(data);
    if (pendingPost != null) return await pendingPost!.future as Response<T>;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: statuses[path] ?? 200,
      data: responses[path] as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Api api;
  MfaSettingsController controller({bool v3 = true}) => MfaSettingsController(
    apiClient: api,
    appService: _App(),
    versionService: _Version(v3),
  );
  setUp(() {
    api = _Api();
    Get.testMode = true;
  });
  tearDown(() {
    Get.reset();
  });

  for (final enabled in [true, false]) {
    test(
      'V2 OTP success=$enabled represents state and encodes username',
      () async {
        api.responses['/api/v1/mfa/status/a%2Fb%20%23'] = {'success': enabled};
        api.responses['/api/v1/mfa/passkey/list'] = {
          'success': true,
          'data': [],
        };
        final c = controller(v3: false);
        await c.loadAll();
        expect(c.otpEnabled.value, enabled);
        expect(c.otpError.value, isNull);
        expect(api.paths, isNot(contains('/api/v1/user/current')));
      },
    );
  }

  test('V3 parses enveloped current-user and passkey list', () async {
    api.responses['/api/v1/user/current'] = {
      'success': true,
      'data': {'is_otp': true},
    };
    api.responses['/api/v1/mfa/passkey/list'] = {
      'success': true,
      'data': [
        {'id': 3, 'name': 'key'},
      ],
    };
    final c = controller();
    await c.loadAll();
    expect(c.otpEnabled.value, isTrue);
    expect(c.passkeys.single.id, 3);
    expect(api.paths.any((p) => p.contains('/status/')), isFalse);
  });

  test(
    'HTTP, business and malformed failures stay distinct from disabled/empty',
    () async {
      api.statuses['/api/v1/user/current'] = 503;
      api.responses['/api/v1/mfa/passkey/list'] = {
        'success': false,
        'message': 'list unavailable',
      };
      final c = controller();
      c.passkeys.add(const MfaPasskeyItem(id: 4));
      await c.loadAll();
      expect(c.otpEnabled.value, isNull);
      expect(c.otpError.value, contains('503'));
      expect(c.passkeyError.value, 'list unavailable');
      expect(c.passkeys.single.id, 4);
      api.statuses.clear();
      api.responses['/api/v1/user/current'] = {'name': 'missing is_otp'};
      api.responses['/api/v1/mfa/passkey/list'] = {'unexpected': []};
      await c.loadAll();
      expect(c.otpEnabled.value, isNull);
      expect(c.otpError.value, contains('数据格式'));
      expect(c.passkeyError.value, contains('数据格式'));
      api.responses['/api/v1/user/current'] = {'is_otp': false};
      api.responses['/api/v1/mfa/passkey/list'] = [];
      await c.loadAll();
      expect(c.otpError.value, isNull);
      expect(c.passkeyError.value, isNull);
      expect(c.otpEnabled.value, isFalse);
      expect(c.passkeys, isEmpty);
    },
  );

  test(
    'busy verify/disable/delete never return success or perform another request',
    () async {
      final c = controller();
      c.otpEnabled.value = false;
      api.pendingPost = Completer<Response<dynamic>>();
      final generation = c.generateOtp();
      expect(c.isSubmitting.value, isTrue);
      expect(await c.verifyOtp('123456'), isNotNull);
      expect(await c.disableOtp('password'), isNotNull);
      expect(
        await c.deletePasskey(const MfaPasskeyItem(id: 1), 'password'),
        isNotNull,
      );
      expect(api.bodies.length, 1);
      api.pendingPost!.complete(
        Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {'success': false, 'message': 'cannot generate'},
        ),
      );
      expect(await generation, isFalse);
      expect(c.operationError.value, 'cannot generate');
      expect(c.pendingSecret.value, isNull);
    },
  );

  test('generation requires both secret and valid otpauth URI', () async {
    final c = controller();
    c.otpEnabled.value = false;
    api.responses['/api/v1/mfa/otp/generate'] = {
      'success': true,
      'data': {'secret': 'secret'},
    };
    expect(await c.generateOtp(), isFalse);
    expect(c.pendingSecret.value, isNull);
    api.responses['/api/v1/mfa/otp/generate'] = {
      'success': true,
      'data': {'secret': 'secret', 'uri': 'otpauth://totp/test?secret=secret'},
    };
    expect(await c.generateOtp(), isTrue);
    expect(c.pendingUri.value, startsWith('otpauth:'));
    expect(await c.verifyOtp('bad'), isNotNull);
    expect(api.paths.where((e) => e.endsWith('/verify')), isEmpty);
    api.responses['/api/v1/mfa/otp/verify'] = {
      'success': false,
      'message': '验证码错误',
    };
    expect(await c.verifyOtp('123456'), '验证码错误');
    expect(c.pendingSecret.value, 'secret');
    expect(c.otpEnabled.value, isFalse);
    api.responses['/api/v1/mfa/otp/verify'] = {'success': true};
    expect(await c.verifyOtp(' 123456 '), isNull);
    expect(api.bodies.last, {
      'uri': 'otpauth://totp/test?secret=secret',
      'otpPassword': '123456',
    });
    expect(c.otpEnabled.value, isTrue);
    expect(c.pendingSecret.value, isNull);
  });

  test(
    'disable and delete require explicit success; failed mutation preserves state',
    () async {
      final c = controller();
      c.otpEnabled.value = true;
      c.passkeys.add(const MfaPasskeyItem(id: 5));
      api.responses['/api/v1/mfa/otp/disable'] = {};
      expect(await c.disableOtp('password'), isNotNull);
      expect(c.otpEnabled.value, isTrue);
      api.responses['/api/v1/mfa/passkey/delete'] = {
        'success': false,
        'message': 'wrong password',
      };
      expect(
        await c.deletePasskey(c.passkeys.single, 'password'),
        'wrong password',
      );
      expect(c.passkeys.length, 1);
      api.responses['/api/v1/mfa/passkey/delete'] = {'success': true};
      expect(await c.deletePasskey(c.passkeys.single, 'password'), isNull);
      expect(api.bodies.last, {'passkey_id': 5, 'password': 'password'});
      expect(c.passkeys, isEmpty);
    },
  );

  testWidgets(
    'OTP controller persists across reactive rebuild and is disposed with page',
    (tester) async {
      final c = controller();
      Get.put<MfaSettingsController>(c);
      c.otpEnabled.value = false;
      c.pendingSecret.value = 'secret';
      c.pendingUri.value = 'otpauth://totp/test?secret=secret';
      await tester.pumpWidget(const GetMaterialApp(home: MfaSettingsPage()));
      await tester.pumpAndSettle();
      // onReady refresh fails safely; restore a pending setup for this widget lifecycle test.
      c.otpEnabled.value = false;
      await tester.pumpAndSettle();
      final field = find.byType(TextField);
      await tester.enterText(field, '123456');
      final textController = tester.widget<TextField>(field).controller!;
      c.isSubmitting.value = true;
      await tester.pump();
      expect(
        identical(tester.widget<TextField>(field).controller, textController),
        isTrue,
      );
      expect(textController.text, '123456');
      c.isSubmitting.value = false;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(() => textController.addListener(() {}), throwsFlutterError);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed status renders unknown and failed list never renders empty success',
    (tester) async {
      final c = controller();
      Get.put<MfaSettingsController>(c);
      await tester.pumpWidget(const GetMaterialApp(home: MfaSettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('状态未知'), findsOneWidget);
      expect(find.text('未开启'), findsNothing);
      expect(find.text('暂无绑定的通行密钥'), findsNothing);
      expect(find.text('重试'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
