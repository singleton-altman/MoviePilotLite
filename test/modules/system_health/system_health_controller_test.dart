import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/system_health/controllers/system_health_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';

Response<dynamic> _reply(String path, dynamic data, [int status = 200]) =>
    Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
      data: data,
    );

class _Api implements ApiClient {
  String? token = 'test-token';
  final paths = <String>[];
  Response<dynamic> Function(String path)? responder;

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
    return responder!(path) as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _App implements AppService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('V2 module list runs per-module tests and skips ping fallback', () async {
    final api = _Api()
      ..responder = (path) {
        if (path == '/api/v1/system/modulelist') {
          return _reply(path, {
            'success': true,
            'data': {
              'modules': [
                {'id': 'themoviedb', 'name': 'TheMovieDb'},
                {'id': 'douban', 'name': '豆瓣'},
              ],
            },
          });
        }
        if (path.startsWith('/api/v1/system/moduletest/')) {
          return _reply(path, {'success': true, 'message': ''});
        }
        fail('不应请求 $path');
      };
    final controller = SystemHealthController(
      apiClient: api,
      log: AppLog(),
      appService: _App(),
    );

    await controller.fetchHealth();

    expect(controller.items.length, 2);
    expect(
      controller.items.every((item) => item.status == SystemHealthStatus.ok),
      isTrue,
    );
    expect(controller.errorMessage.value, isNull);
    expect(controller.lastRunAt.value, isNotNull);
    expect(api.paths.any((p) => p.endsWith('/ping')), isFalse);
    expect(api.paths.any((p) => p.contains('versions')), isFalse);
  });

  test('failed module test maps to error unless message proves disabled',
      () async {
    final api = _Api()
      ..responder = (path) {
        if (path == '/api/v1/system/modulelist') {
          return _reply(path, {
            'success': true,
            'data': {
              'modules': [
                {'id': 'broken', 'name': 'Broken'},
                {'id': 'off', 'name': 'Off'},
              ],
            },
          });
        }
        if (path == '/api/v1/system/moduletest/broken') {
          return _reply(path, {'success': false, 'message': ''});
        }
        if (path == '/api/v1/system/moduletest/off') {
          return _reply(path, {'success': false, 'message': '模块未启用'});
        }
        fail('不应请求 $path');
      };
    final controller = SystemHealthController(
      apiClient: api,
      log: AppLog(),
      appService: _App(),
    );

    await controller.fetchHealth();

    expect(controller.errorMessage.value, contains('部分模块检测失败'));
    final broken = controller.items.firstWhere((i) => i.id == 'broken');
    final off = controller.items.firstWhere((i) => i.id == 'off');
    expect(broken.status, SystemHealthStatus.error);
    expect(off.status, SystemHealthStatus.disabled);
  });

  test('V3 without module endpoints falls back to ping as connectivity only',
      () async {
    final api = _Api()
      ..responder = (path) {
        if (path == '/api/v1/system/modulelist') {
          return _reply(path, {'detail': 'Not Found'}, 404);
        }
        if (path == '/api/v1/system/ping') {
          return _reply(path, {'success': true});
        }
        fail('不应请求 $path');
      };
    final controller = SystemHealthController(
      apiClient: api,
      log: AppLog(),
      appService: _App(),
    );

    await controller.fetchHealth();

    expect(controller.items.length, 1);
    final item = controller.items.single;
    expect(item.title, '服务连接');
    expect(item.status, SystemHealthStatus.ok);
    expect(item.detail, contains('不提供模块级健康检查'));
    expect(controller.errorMessage.value, isNull);
    expect(controller.lastRunAt.value, isNotNull);
    expect(api.paths, contains('/api/v1/system/ping'));
    expect(api.paths.any((p) => p.contains('versions')), isFalse);
  });

  test('ping business failure and HTTP errors never look healthy', () async {
    final failing = _Api()
      ..responder = (path) =>
          _reply(path, {'success': false, 'message': '服务维护中'});
    final controller = SystemHealthController(
      apiClient: failing,
      log: AppLog(),
      appService: _App(),
    );
    await controller.fetchHealth();
    expect(controller.items.single.status, SystemHealthStatus.error);
    expect(controller.items.single.message, '服务维护中');
    expect(controller.errorMessage.value, isNotNull);

    final httpError = _Api()
      ..responder = (path) => _reply(path, null, 500);
    final controller2 = SystemHealthController(
      apiClient: httpError,
      log: AppLog(),
      appService: _App(),
    );
    await controller2.fetchHealth();
    expect(controller2.items.single.status, SystemHealthStatus.error);
    expect(controller2.items.single.message, 'HTTP 500');

    final malformed = _Api()..responder = (path) => _reply(path, 'not-json');
    final controller3 = SystemHealthController(
      apiClient: malformed,
      log: AppLog(),
      appService: _App(),
    );
    await controller3.fetchHealth();
    expect(controller3.items.single.status, SystemHealthStatus.unknown);
  });
}
