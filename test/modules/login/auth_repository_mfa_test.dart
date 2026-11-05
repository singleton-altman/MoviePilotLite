import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:altman_totp/services/totp_service.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/login/controllers/login_controller.dart';
import 'package:moviepilot_mobile/modules/login/models/login_profile.dart';
import 'package:moviepilot_mobile/modules/login/models/login_response.dart';
import 'package:moviepilot_mobile/modules/login/repositories/auth_repository.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/ios_shared_session_service.dart';
import 'package:moviepilot_mobile/utils/image_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _loginPath = '/api/v1/login/access-token';

Response<T> _json<T>(int status, Object? body, {Map<String, List<String>>? headers}) =>
    Response<T>(
      requestOptions: RequestOptions(path: _loginPath),
      statusCode: status,
      data: body as T,
      headers: headers == null ? Headers() : Headers.fromMap(headers),
    );

class _Api extends GetxController implements ApiClient {
  final postedBodies = <Map<String, dynamic>>[];
  final gotPaths = <String>[];
  Object? postFormError;
  Response<dynamic>? postFormResponse;

  @override
  Future<Response<T>> postForm<T>(
    String path,
    Map<String, dynamic> data, {
    int? timeout,
    bool skipUnauthorizedHandling = false,
  }) async {
    postedBodies.add(data);
    if (postFormError != null) throw postFormError!;
    final source = postFormResponse!;
    return Response<T>(
      requestOptions: source.requestOptions,
      statusCode: source.statusCode,
      statusMessage: source.statusMessage,
      headers: source.headers,
      data: source.data as T,
    );
  }

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
    gotPaths.add(path);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'success': false} as T,
    );
  }

  @override
  void setBaseUrl(String baseUrl) {}

  @override
  void setToken(String token) {}

  @override
  void setAuthRecoveryHandler(Future<bool> Function()? handler) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _App extends GetxService implements AppService {
  @override
  Future<void> onInit() async {
    super.onInit();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Ios extends GetxService implements IosSharedSessionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Totp extends GetxService implements TotpService {
  @override
  Future<void> load() async {}

  @override
  String? generateCurrentCode(String server, String username) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageUtil extends GetxService implements ImageUtil {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Repo extends GetxService implements AuthRepository {
  _Repo(this.outcomes);

  /// 依序消费的登录结果：Exception 则抛出，否则作为 LoginResponse 返回。
  final List<Object> outcomes;
  final loginArgs = <Map<String, dynamic>>[];

  @override
  Future<LoginResponse> login({
    required String server,
    required String username,
    required String password,
    String otpPassword = '',
  }) async {
    loginArgs.add({
      'server': server,
      'username': username,
      'password': password,
      'otpPassword': otpPassword,
    });
    final outcome = outcomes.removeAt(0);
    if (outcome is Exception) throw outcome;
    return outcome as LoginResponse;
  }

  @override
  Future<List<LoginProfile>> getProfilesAsync() async => <LoginProfile>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AuthRepository _repository(_Api api) {
  Get.put<AppLog>(AppLog());
  Get.put<AppService>(_App());
  Get.put<IosSharedSessionService>(_Ios());
  Get.put<ApiClient>(api);
  return Get.put(AuthRepository());
}

LoginResponse _okResponse() => const LoginResponse(
  accessToken: 'token-123',
  tokenType: 'bearer',
  userId: 1,
  userName: 'user',
  level: 1,
  permissions: {},
);

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(() {
    Get.reset();
  });

  group('AuthRepository MFA challenge', () {
    test('401 with X-MFA-Required header and v3 envelope yields MfaRequiredException', () async {
      final api = _Api();
      api.postFormError = DioException.badResponse(
        statusCode: 401,
        requestOptions: RequestOptions(path: _loginPath),
        response: _json(
          401,
          {
            'success': false,
            'message': '需要二次验证',
            'data': {'mfa_methods': ['otp']},
          },
          headers: {'X-MFA-Required': ['true']},
        ),
      );
      final repo = _repository(api);

      await expectLater(
        repo.requestLoginToken(
          server: 'https://demo.example',
          username: 'user',
          password: 'pass',
        ),
        throwsA(
          isA<MfaRequiredException>()
              .having((e) => e.mfaMethods, 'mfaMethods', ['otp'])
              .having((e) => e.message, 'message', '需要二次验证'),
        ),
      );
    });

    test('v2 top-level mfa_methods with mixed-case header is recognized', () async {
      final api = _Api();
      api.postFormError = DioException.badResponse(
        statusCode: 401,
        requestOptions: RequestOptions(path: _loginPath),
        response: _json(
          401,
          {'detail': '需要二次验证', 'mfa_methods': ['otp', 'passkey']},
          headers: {'X-Mfa-Required': ['True']},
        ),
      );
      final repo = _repository(api);

      await expectLater(
        repo.requestLoginToken(
          server: 'https://demo.example',
          username: 'user',
          password: 'pass',
        ),
        throwsA(
          isA<MfaRequiredException>()
              .having((e) => e.mfaMethods, 'mfaMethods', ['otp', 'passkey'])
              .having((e) => e.message, 'message', '需要二次验证'),
        ),
      );
    });

    test('401 with non-empty body mfa_methods alone marks the challenge', () async {
      final api = _Api();
      api.postFormError = DioException.badResponse(
        statusCode: 401,
        requestOptions: RequestOptions(path: _loginPath),
        response: _json(401, {
          'success': false,
          'message': '需要二次验证',
          'data': {'mfa_methods': ['otp']},
        }),
      );
      final repo = _repository(api);

      await expectLater(
        repo.requestLoginToken(
          server: 'https://demo.example',
          username: 'user',
          password: 'pass',
        ),
        throwsA(isA<MfaRequiredException>()),
      );
    });

    test('401 without MFA marker stays a credential error carrying server message', () async {
      final api = _Api();
      api.postFormError = DioException.badResponse(
        statusCode: 401,
        requestOptions: RequestOptions(path: _loginPath),
        response: _json(401, {'detail': '用户名或密码错误'}),
      );
      final repo = _repository(api);

      await expectLater(
        repo.requestLoginToken(
          server: 'https://demo.example',
          username: 'user',
          password: 'pass',
        ),
        throwsA(
          isA<LoginCredentialException>()
              .having((e) => e.message, 'message', '用户名或密码错误'),
        ),
      );

      // Web 端 401 响应体可能是未解码字符串
      api.postFormResponse = _json<String>(
        401,
        '{"success": false, "message": "用户名或密码错误"}',
      );
      await expectLater(
        repo.requestLoginToken(
          server: 'https://demo.example',
          username: 'user',
          password: 'pass',
        ),
        throwsA(isA<LoginCredentialException>()),
      );

      // 空标记头与空 mfa_methods 不构成 challenge
      api.postFormError = DioException.badResponse(
        statusCode: 401,
        requestOptions: RequestOptions(path: _loginPath),
        response: _json(
          401,
          {'detail': '用户名或密码错误', 'data': {'mfa_methods': <String>[]}},
          headers: {'X-MFA-Required': ['false']},
        ),
      );
      await expectLater(
        repo.requestLoginToken(
          server: 'https://demo.example',
          username: 'user',
          password: 'pass',
        ),
        throwsA(
          isA<LoginCredentialException>()
              .having((e) => e.message, 'message', '用户名或密码错误'),
        ),
      );
      expect(
        api.gotPaths.where((p) => p.contains('/mfa/status')),
        isEmpty,
      );
    });

    test('non-401 HTTP errors are rethrown untouched', () async {
      final api = _Api();
      final throttled = DioException.badResponse(
        statusCode: 429,
        requestOptions: RequestOptions(path: _loginPath),
        response: _json(429, {'detail': '登录尝试过于频繁，请稍后重试'}),
      );
      api.postFormError = throttled;
      final repo = _repository(api);

      await expectLater(
        repo.requestLoginToken(
          server: 'https://demo.example',
          username: 'user',
          password: 'pass',
        ),
        throwsA(same(throttled)),
      );
    });

    test('successful login parses token and always posts otp_password', () async {
      final api = _Api();
      api.postFormResponse = _json(
        200,
        {
          'access_token': 'token-123',
          'token_type': 'bearer',
          'user_id': 1,
          'user_name': 'user',
          'level': 1,
          'permissions': <String, dynamic>{},
        },
      );
      final repo = _repository(api);

      final login = await repo.requestLoginToken(
        server: 'https://demo.example/',
        username: 'user',
        password: 'pass',
      );
      expect(login.accessToken, 'token-123');
      expect(api.postedBodies.single, {
        'username': 'user',
        'password': 'pass',
        'otp_password': '',
      });
    });

    test('retry after challenge carries otp_password and never probes mfa/status', () async {
      final api = _Api();
      api.postFormError = DioException.badResponse(
        statusCode: 401,
        requestOptions: RequestOptions(path: _loginPath),
        response: _json(
          401,
          {
            'success': false,
            'message': '需要二次验证',
            'data': {'mfa_methods': ['otp']},
          },
          headers: {'X-MFA-Required': ['true']},
        ),
      );
      final repo = _repository(api);

      Object? firstError;
      try {
        await repo.requestLoginToken(
          server: 'https://demo.example',
          username: 'user',
          password: 'pass',
        );
      } catch (e) {
        firstError = e;
      }
      expect(firstError, isA<MfaRequiredException>());

      api.postFormError = null;
      api.postFormResponse = _json(
        200,
        {
          'access_token': 'token-456',
          'token_type': 'bearer',
          'user_id': 1,
          'user_name': 'user',
          'level': 1,
          'permissions': <String, dynamic>{},
        },
      );
      final login = await repo.requestLoginToken(
        server: 'https://demo.example',
        username: 'user',
        password: 'pass',
        otpPassword: '654321',
      );
      expect(login.accessToken, 'token-456');
      expect(api.postedBodies.length, 2);
      expect(api.postedBodies.last['otp_password'], '654321');
      expect(
        api.gotPaths.where((p) => p.contains('/mfa/status')),
        isEmpty,
      );
    });
  });

  testWidgets('LoginController surfaces MFA challenge then retries with the code', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Repo([
      MfaRequiredException(mfaMethods: ['otp'], message: '需要二次验证'),
      LoginCredentialException('用户名或密码错误'),
      _okResponse(),
    ]);
    Get.put<AppLog>(AppLog());
    Get.put<ImageUtil>(_ImageUtil());
    Get.put<TotpService>(_Totp());
    Get.put<AuthRepository>(repo);
    await tester.pumpWidget(
      GetMaterialApp(
        getPages: [
          GetPage(name: '/main', page: () => const SizedBox.shrink()),
        ],
        home: const SizedBox.shrink(),
      ),
    );
    final controller = Get.put(LoginController());
    await tester.pumpAndSettle();

    controller.serverController.text = 'https://demo.example';
    controller.usernameController.text = 'user';
    controller.passwordController.text = 'pass';

    // 第一次提交：服务端返回 MFA challenge，进入待验证码状态且不跳转
    await controller.submitLogin();
    await tester.pump();
    expect(controller.mfaRequired.value, isTrue);
    expect(controller.mfaMethods.toList(), ['otp']);
    expect(Get.currentRoute, isNot('/main'));

    // 未带验证码重试：普通凭据错误清掉 challenge 状态
    await controller.submitLogin();
    await tester.pump();
    expect(controller.mfaRequired.value, isFalse);
    expect(Get.currentRoute, isNot('/main'));

    // 携带验证码重试：登录成功并跳转主页
    controller.otpController.text = '654321';
    await controller.submitLogin();
    await tester.pumpAndSettle();
    expect(repo.loginArgs.last['otpPassword'], '654321');
    expect(repo.loginArgs.last['server'], 'https://demo.example');
    expect(Get.currentRoute, '/main');
    expect(tester.takeException(), isNull);

    // 主动销毁控制器以取消壁纸轮播定时器
    await Get.delete<LoginController>(force: true);
    await tester.pumpAndSettle();
  });
}
