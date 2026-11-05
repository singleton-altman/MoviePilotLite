import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/modules/settings/controllers/notification_wechat_controller.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class _Call {
  _Call(this.method, this.path, this.body, this.query);
  final String method;
  final String path;
  final Object? body;
  final Map<String, dynamic>? query;
}

class _Api extends GetxService implements ApiClient {
  final calls = <_Call>[];
  int status = 200;
  Object? Function(_Call call)? respond;

  @override
  String? get baseUrl => 'https://wechat.test';

  Future<Response<T>> _reply<T>(_Call call) async {
    calls.add(call);
    return Response<T>(
      requestOptions: RequestOptions(path: call.path),
      statusCode: status,
      data: respond?.call(call) as T?,
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
  }) => _reply(_Call('GET', path, null, queryParameters));

  @override
  Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
  }) => _reply(_Call('POST', path, data, queryParameters));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _channel = <String, dynamic>{
  'id': 'chan-1',
  'name': '爪爪机器人',
  'type': 'wechatclawbot',
  'enabled': true,
  'config': <String, dynamic>{
    'WECHATCLAWBOT_BASE_URL': 'https://ilinkai.weixin.qq.com',
    'WECHATCLAWBOT_DEFAULT_TARGET': '',
    'WECHATCLAWBOT_ADMINS': '',
    'WECHATCLAWBOT_POLL_TIMEOUT': 25,
  },
};

Map<String, dynamic> _settingsPayload() => {
  'success': true,
  'data': {
    'value': [Map<String, dynamic>.from(_channel)],
  },
};

/// 与 v3 wechatclawbot 模块 get_status 的返回字段一一对应。
Map<String, dynamic> _statusPayload({
  bool connected = false,
  String? qrcodeUrl = 'https://liteapp.weixin.qq.com/q/7GiQu1?qrcode=abc&bot_type=3',
  String? qrcodeStatus = 'waiting',
  int? updatedAt = 1760000000,
}) => {
  'success': true,
  'connected': connected,
  'account_id': connected ? 'acc-1' : null,
  'qrcode': qrcodeUrl == null ? null : 'abc',
  'qrcode_url': qrcodeUrl,
  'qrcode_status': qrcodeStatus,
  'qrcode_updated_at': updatedAt,
  'known_targets': <Object>[],
  'default_target': null,
  'base_url': 'https://ilinkai.weixin.qq.com',
};

/// 模拟真实链路里 V3 信封解包拦截器的改写结果：
/// data 为 Map 时合并回顶层，data 为 null 时保留完整信封。
Object? _afterV3Unwrap(Map<String, dynamic> envelope) {
  final data = envelope['data'];
  if (data == null) return envelope;
  if (data is Map) {
    final merged = Map<String, dynamic>.from(data);
    merged.putIfAbsent('success', () => envelope['success']);
    merged.putIfAbsent('message', () => envelope['message']);
    merged.putIfAbsent('data', () => data);
    return merged;
  }
  return data;
}

NotificationWechatController _controller(_Api api, {bool v3 = true}) =>
    NotificationWechatController(
      apiClient: api,
      detectV3: () async => v3,
      isAdmin: () => true,
    );

/// 组装 v3 控制器：配置读取走设置接口，manage 请求按 action 分发。
Future<NotificationWechatController> _readyV3Controller(
  _Api api, {
  required Object? Function(String action) manage,
}) async {
  final controller = _controller(api);
  api.respond = (call) {
    if (call.path == '/api/v1/system/setting/Notifications') {
      return _settingsPayload();
    }
    if (call.path == '/api/v1/notification/manage') {
      return manage((call.body as Map<String, dynamic>)['action'] as String);
    }
    return null;
  };
  await controller.initialize();
  return controller;
}

Map<String, dynamic> _v3Success(Object data) =>
    _afterV3Unwrap({'success': true, 'message': null, 'data': data})
        as Map<String, dynamic>;

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  group('V3 notification/manage contract', () {
    test('status hits manage with target, action and channel params', () async {
      final api = _Api();
      final controller = await _readyV3Controller(
        api,
        manage: (action) =>
            action == 'status' ? _v3Success(_statusPayload()) : null,
      );
      final statusCall = api.calls.last;
      expect(statusCall.method, 'POST');
      expect(statusCall.path, '/api/v1/notification/manage');
      expect(statusCall.body, {
        'target': 'WechatClawBot',
        'action': 'status',
        'params': {
          'source': 'chan-1',
          'fallback_source': '爪爪机器人',
          'WECHATCLAWBOT_BASE_URL': 'https://ilinkai.weixin.qq.com',
          'WECHATCLAWBOT_DEFAULT_TARGET': '',
          'WECHATCLAWBOT_ADMINS': '',
          'WECHATCLAWBOT_POLL_TIMEOUT': 25,
          'refresh_remote': true,
          'auto_generate_qrcode': true,
        },
      });
      expect(controller.supported.value, true);
      expect(controller.errorText.value, isNull);
      expect(controller.loggedIn, false);
      expect(controller.qrStatus, 'waiting');
      expect(controller.qrcodeUrl, isNotNull);
      controller.onClose();
    });

    test('refresh_qrcode hits manage and applies returned status', () async {
      final api = _Api();
      const refreshedUrl =
          'https://liteapp.weixin.qq.com/q/7GiQu1?qrcode=def&bot_type=3';
      final controller = await _readyV3Controller(
        api,
        manage: (action) => switch (action) {
          'status' => _v3Success(_statusPayload()),
          'refresh_qrcode' => _v3Success(
            _statusPayload(qrcodeUrl: refreshedUrl),
          ),
          _ => null,
        },
      );
      final result = await controller.refreshQrcode();
      expect(result.ok, true);
      expect(result.message, '刷新二维码成功');
      expect(api.calls.last.body, {
        'target': 'WechatClawBot',
        'action': 'refresh_qrcode',
        'params': {
          'source': 'chan-1',
          'fallback_source': '爪爪机器人',
          'WECHATCLAWBOT_BASE_URL': 'https://ilinkai.weixin.qq.com',
          'WECHATCLAWBOT_DEFAULT_TARGET': '',
          'WECHATCLAWBOT_ADMINS': '',
          'WECHATCLAWBOT_POLL_TIMEOUT': 25,
        },
      });
      expect(controller.qrcodeUrl, refreshedUrl);
      controller.onClose();
    });

    test('logout hits manage and clears local login state', () async {
      final api = _Api();
      final controller = await _readyV3Controller(
        api,
        manage: (action) => switch (action) {
          'status' => _v3Success(_statusPayload(connected: true)),
          'logout' => _v3Success({
            'success': true,
            'message': '已退出微信 ClawBot 登录',
          }),
          _ => null,
        },
      );
      expect(controller.loggedIn, true);
      final result = await controller.logout();
      expect(result.ok, true);
      expect(result.message, '退出登录成功');
      expect((api.calls.last.body as Map)['action'], 'logout');
      expect(controller.loggedIn, false);
      controller.onClose();
    });

    test('test_connection accepts envelope without data', () async {
      final api = _Api();
      final controller = await _readyV3Controller(
        api,
        manage: (action) => switch (action) {
          'status' => _v3Success(_statusPayload()),
          'test_connection' => {
            'success': true,
            'message': '连接正常',
            'data': null,
          },
          _ => null,
        },
      );
      final result = await controller.test();
      expect(result.ok, true);
      expect(result.message, '测试连通性成功');
      expect((api.calls.last.body as Map)['action'], 'test_connection');
      controller.onClose();
    });

    test('migrate_cache sends old_name/new_name params', () async {
      final api = _Api();
      final controller = await _readyV3Controller(
        api,
        manage: (action) => switch (action) {
          'status' => _v3Success(_statusPayload()),
          'migrate_cache' => {
            'success': true,
            'message': '缓存迁移完成',
            'data': null,
          },
          _ => null,
        },
      );
      final result = await controller.migrate(
        oldSource: ' 旧渠道 ',
        newSource: '新渠道',
        cleanupOld: true,
        overwrite: true,
      );
      expect(result.ok, true);
      expect(result.message, '迁移缓存成功');
      expect(api.calls.last.body, {
        'target': 'WechatClawBot',
        'action': 'migrate_cache',
        'params': {
          'old_name': '旧渠道',
          'new_name': '新渠道',
          'cleanup_old': true,
          'overwrite': true,
        },
      });
      controller.onClose();
    });

    test('action failure surfaces unified envelope message', () async {
      const serverMessage = '微信 ClawBot 通知未启用或配置尚未保存，请先保存并启用当前渠道';
      final api = _Api();
      final controller = await _readyV3Controller(
        api,
        manage: (action) => switch (action) {
          'status' => _v3Success(_statusPayload()),
          'test_connection' => {
            'success': false,
            'message': serverMessage,
            'data': null,
          },
          _ => null,
        },
      );
      final result = await controller.test();
      expect(result.ok, false);
      expect(result.message, serverMessage);
      controller.onClose();
    });

    test('action failure without envelope message keeps generic hint', () async {
      final api = _Api();
      final controller = await _readyV3Controller(
        api,
        manage: (action) => switch (action) {
          'status' => _v3Success(_statusPayload()),
          'test_connection' => {
            'success': false,
            'message': null,
            'data': null,
          },
          _ => null,
        },
      );
      final result = await controller.test();
      expect(result.ok, false);
      expect(result.message, '测试连通性失败，请检查渠道配置或稍后重试');
      controller.onClose();
    });

    test('status failure surfaces envelope message in errorText', () async {
      const serverMessage = '该通知渠道未启用或不支持此管理动作';
      final api = _Api();
      final controller = _controller(api);
      api.respond = (call) {
        if (call.path == '/api/v1/system/setting/Notifications') {
          return _settingsPayload();
        }
        if (call.path == '/api/v1/notification/manage') {
          return {'success': false, 'message': serverMessage, 'data': null};
        }
        return null;
      };
      await controller.initialize();
      expect(controller.errorText.value, serverMessage);
      expect(controller.status.value, isNull);
      controller.onClose();
    });
  });

  group('V2 legacy routes regression', () {
    test('all five operations keep hitting the dedicated routes', () async {
      final api = _Api();
      final controller = _controller(api, v3: false);
      api.respond = (call) => switch (call.path) {
        '/api/v1/notification/wechatclawbot/status' ||
        '/api/v1/notification/wechatclawbot/refresh' => {
          'success': true,
          'data': _statusPayload(),
        },
        '/api/v1/notification/wechatclawbot/test' => {
          'success': true,
          'message': '连接正常',
        },
        '/api/v1/notification/wechatclawbot/logout' => {
          'success': true,
          'message': '已退出微信 ClawBot 登录',
        },
        '/api/v1/notification/wechatclawbot/migrate' => {
          'success': true,
          'message': '缓存迁移完成',
        },
        _ => null,
      };
      await controller.initialize();

      // v2 不读取通知配置，直接查询默认渠道状态。
      expect(api.calls, hasLength(1));
      final statusCall = api.calls.single;
      expect(statusCall.method, 'GET');
      expect(statusCall.path, '/api/v1/notification/wechatclawbot/status');
      expect(statusCall.query, {
        'refresh_remote': true,
        'auto_generate_qrcode': true,
      });
      expect(controller.qrStatus, 'waiting');

      await controller.refreshQrcode();
      expect(api.calls.last.method, 'POST');
      expect(api.calls.last.path, '/api/v1/notification/wechatclawbot/refresh');
      expect(controller.qrcodeUrl, isNotNull);

      await controller.test();
      expect(api.calls.last.method, 'GET');
      expect(api.calls.last.path, '/api/v1/notification/wechatclawbot/test');

      await controller.logout();
      expect(api.calls.last.method, 'POST');
      expect(api.calls.last.path, '/api/v1/notification/wechatclawbot/logout');
      expect(controller.loggedIn, false);

      await controller.migrate(
        oldSource: '旧渠道',
        newSource: '新渠道',
        cleanupOld: true,
        overwrite: true,
      );
      final migrateCall = api.calls.last;
      expect(migrateCall.method, 'POST');
      expect(migrateCall.path, '/api/v1/notification/wechatclawbot/migrate');
      expect(migrateCall.query, {
        'old_source': '旧渠道',
        'new_source': '新渠道',
        'cleanup_old': true,
        'overwrite': true,
      });
      controller.onClose();
    });

    test('v2 failure surfaces envelope message', () async {
      const serverMessage = '未找到名为 ghost 的微信 ClawBot 通知配置';
      final api = _Api();
      final controller = _controller(api, v3: false);
      api.respond = (call) => call.path.endsWith('/test')
          ? {'success': false, 'message': serverMessage}
          : {'success': true, 'data': _statusPayload()};
      await controller.initialize();
      final result = await controller.test();
      expect(result.ok, false);
      expect(result.message, serverMessage);
      controller.onClose();
    });
  });
}
