import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_organize/models/media_organize_models.dart';
import 'package:moviepilot_mobile/modules/storage/controllers/storage_list_controller.dart';
import 'package:moviepilot_mobile/modules/storage/pages/storage_manage_sheet.dart';
import 'package:moviepilot_mobile/modules/storage/services/storage_configuration_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';
// ignore: depend_on_referenced_packages
import 'package:qr_flutter/qr_flutter.dart';

class _Call {
  _Call(this.method, this.path, this.body, this.query, this.skipUnwrap);
  final String method;
  final String path;
  final Object? body;
  final Map<String, dynamic>? query;
  final bool skipUnwrap;
}

class _Api extends GetxService implements ApiClient {
  final calls = <_Call>[];
  dynamic payload = {'success': true};
  int status = 200;
  Future<void> Function(_Call)? beforeResponse;
  dynamic Function(_Call)? respond;

  @override
  String? get baseUrl => 'https://storage.test';

  Future<Response<T>> _reply<T>(_Call call) async {
    calls.add(call);
    await beforeResponse?.call(call);
    return Response<T>(
      requestOptions: RequestOptions(path: call.path),
      statusCode: status,
      data: (respond?.call(call) ?? payload) as T?,
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
  }) => _reply(_Call('GET', path, null, queryParameters, skipV3EnvelopeUnwrap));

  @override
  Future<Response<T>> postJson<T>(
    String path,
    Object? data, {
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
  }) => _reply(_Call('POST', path, data, queryParameters, false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _App extends AppService {
  bool allowed = true;
  @override
  // Avoid AppService's platform initialization in isolated contract tests.
  // ignore: must_call_super
  Future<void> onInit() async {}
  @override
  bool get canManage => allowed;
}

class _Version extends ServerApiVersionService {
  _Version(this.v3);
  final bool v3;
  @override
  Future<bool> isV3() async => v3;
}

const _original = StorageSetting(
  type: 'u115',
  name: '115网盘',
  config: {
    'access_token': 'existing',
    'nested': {'keep': true},
  },
);

Map<String, dynamic> _settings([StorageSetting storage = _original]) => {
  'success': true,
  'data': {
    'value': [storage.toJson()],
  },
};

StorageListController _controller(_Api api, _App app, bool v3) {
  Get.put<ApiClient>(api);
  Get.put<AppService>(app);
  Get.put<AppLog>(AppLog());
  Get.put<ServerApiVersionService>(_Version(v3));
  return StorageListController();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  for (final v3 in [false, true]) {
    group(v3 ? 'V3.1.5 source contract' : 'V2 Swagger contract', () {
      late _Api api;
      late StorageConfigurationService service;
      bool allowed = true;
      setUp(() {
        api = _Api();
        allowed = true;
        service = StorageConfigurationService(
          apiClient: api,
          isV3: () async => v3,
          canManage: () => allowed,
        );
      });

      void expectAction(
        String legacy,
        String action, {
        Map<String, dynamic> params = const {},
      }) {
        final call = api.calls.last;
        if (v3) {
          expect(call.method, 'POST');
          expect(call.path, '/api/v1/storage/manage');
          expect(call.body, {
            'target': 'u115',
            'action': action,
            'params': params,
          });
          expect(call.query, isNull);
        } else {
          expect(call.method, 'GET');
          expect(call.path, '/api/v1/storage/$legacy/u115');
          expect(call.query, params.isEmpty ? null : params);
          expect(call.skipUnwrap, true);
        }
      }

      test(
        'acquires raw QR content and provider image without aliases',
        () async {
          api.payload = {
            'success': true,
            'data': {'codeContent': '115://scan/session'},
          };
          final qr = await service.acquireQrCode('u115');
          expect(qr.content, '115://scan/session');
          expectAction('qrcode', 'generate_qrcode');
          api.payload = {
            'success': true,
            'data': {'codeUrl': 'https://alipan.test/qr.png'},
          };
          expect(
            (await service.acquireQrCode('u115')).imageUrl,
            'https://alipan.test/qr.png',
          );
          for (final data in [
            {},
            {'url': 'https://wrong.test'},
            {'codeUrl': 'file:///secret'},
          ]) {
            api.payload = {'success': true, 'data': data};
            await expectLater(
              service.acquireQrCode('u115'),
              throwsFormatException,
            );
          }
        },
      );

      test(
        'OAuth uses authUrl and state, check sends no invented state',
        () async {
          api.payload = {
            'success': true,
            'data': {'authUrl': 'https://115.test/auth?x=1', 'state': 'opaque'},
          };
          expect(
            await service.acquireAuthUrl('u115'),
            'https://115.test/auth?x=1',
          );
          expectAction('auth_url', 'generate_auth_url');
          api.payload = {
            'success': true,
            'data': {'status': 0, 'tip': '等待用户授权'},
          };
          expect((await service.checkLogin('u115')).complete, false);
          expectAction('check', 'check_login');
          await service.checkLogin('u115', ck: 'a&b', t: '123');
          expectAction(
            'check',
            'check_login',
            params: {'ck': 'a&b', 't': '123'},
          );
          for (final data in [
            {'auth_url': 'https://115.test', 'state': 's'},
            {'authUrl': 'javascript:alert(1)', 'state': 's'},
            {'authUrl': 'https://115.test'},
          ]) {
            api.payload = {'success': true, 'data': data};
            await expectLater(
              service.acquireAuthUrl('u115'),
              throwsFormatException,
            );
          }
        },
      );

      test(
        'all login states stay status-only; never save a check response',
        () async {
          for (final type in ['u115', 'alipan']) {
            final states = type == 'u115'
                ? <Object>[0, 1, 2, -1, -2, '2', 'unknown']
                : <Object>[
                    'WaitLogin',
                    'ScanSuccess',
                    'LoginSuccess',
                    'QRCodeExpired',
                    'unknown',
                  ];
            for (final status in states) {
              api.payload = {
                'success': true,
                'data': {'status': status, 'tip': 'server tip'},
              };
              final result = await service.checkLogin(type);
              expect(
                result.complete,
                type == 'u115' ? status == 2 : status == 'LoginSuccess',
              );
              expect(result.tip, 'server tip');
            }
          }
          expect(
            api.calls.every(
              (call) =>
                  call.method == 'GET' ||
                  (call.body as Map)['action'] == 'check_login',
            ),
            true,
          );
        },
      );

      test(
        'save sends complete config using exact raw/conf body and preserves input',
        () async {
          final config = {
            'access_token': 'new',
            'nested': {'keep': true},
            'extra': [1, false],
          };
          api.respond = (call) =>
              call.path.endsWith('/Storages') ? _settings() : {'success': true};
          await service.saveConfiguration(_original, config);
          expect(api.calls, hasLength(2));
          expect(api.calls.first.skipUnwrap, true);
          final call = api.calls.last;
          expect(call.method, 'POST');
          if (v3) {
            expect(call.path, '/api/v1/storage/manage');
            expect(call.body, {
              'target': 'u115',
              'action': 'save_config',
              'params': {'conf': config},
            });
          } else {
            expect(call.path, '/api/v1/storage/save/u115');
            expect(call.body, config);
          }
          expect(_original.config['access_token'], 'existing');
          expect(config['nested'], {'keep': true});
        },
      );

      test(
        'empty/status config and stale editor never overwrite existing credentials',
        () async {
          for (final config in <Map<String, dynamic>>[
            {},
            {'status': 2, 'tip': 'ok'},
            {'success': true},
          ]) {
            await expectLater(
              service.saveConfiguration(_original, config),
              throwsFormatException,
            );
          }
          expect(api.calls, isEmpty);
          api.payload = _settings(
            _original.copyWith(config: {'access_token': 'refreshed'}),
          );
          await expectLater(
            service.saveConfiguration(_original, {'access_token': 'stale'}),
            throwsStateError,
          );
          expect(api.calls.single.path, '/api/v1/system/setting/Storages');
          api.payload = _settings();
          api.status = 500;
          await expectLater(
            service.saveConfiguration(_original, {'access_token': 'new'}),
            throwsStateError,
          );
          expect(api.calls.every((call) => call.method == 'GET'), true);
        },
      );

      test(
        'reset needs explicit confirmation and exact reset action',
        () async {
          await expectLater(
            service.reset('u115', confirmed: false),
            throwsStateError,
          );
          expect(api.calls, isEmpty);
          await service.reset('u115', confirmed: true);
          expectAction('reset', 'reset_config');
        },
      );

      test(
        'HTTP/business/malformed/transport errors rejected for every action',
        () async {
          final actions = <Future<dynamic> Function()>[
            () => service.acquireQrCode('u115'),
            () => service.acquireAuthUrl('u115'),
            () => service.checkLogin('u115'),
            () => service.reset('u115', confirmed: true),
          ];
          for (final action in actions) {
            api.status = 403;
            await expectLater(action(), throwsStateError);
            api.status = 200;
            api.payload = {'success': false, 'message': 'unsupported'};
            await expectLater(action(), throwsStateError);
            api.payload = {
              'data': {'status': 2},
            };
            await expectLater(action(), throwsFormatException);
            api.beforeResponse = (_) async => throw TimeoutException('timeout');
            await expectLater(action(), throwsA(isA<TimeoutException>()));
            api.beforeResponse = null;
          }
          for (final body in [
            {'success': false, 'message': 'save refused'},
            {'data': {}},
          ]) {
            api.respond = (call) =>
                call.path.endsWith('/Storages') ? _settings() : body;
            await expectLater(
              service.saveConfiguration(_original, {'token': 'new'}),
              throwsA(anyOf(isA<FormatException>(), isA<StateError>())),
            );
          }
        },
      );

      test(
        'permissions checked before all requests and again after version detection',
        () async {
          allowed = false;
          for (final action in <Future<dynamic> Function()>[
            () => service.acquireQrCode('u115'),
            () => service.acquireAuthUrl('u115'),
            () => service.checkLogin('u115'),
            () => service.saveConfiguration(_original, {'token': 'new'}),
            () => service.reset('u115', confirmed: true),
            service.loadStorages,
          ]) {
            await expectLater(action(), throwsStateError);
          }
          expect(api.calls, isEmpty);
          allowed = true;
          service = StorageConfigurationService(
            apiClient: api,
            isV3: () async {
              allowed = false;
              return v3;
            },
            canManage: () => allowed,
          );
          await expectLater(service.acquireQrCode('u115'), throwsStateError);
          expect(api.calls, isEmpty);
        },
      );

      test('real ApiClient merged V3 envelope shape remains safe', () async {
        api.payload = {
          'status': 2,
          'tip': 'ok',
          'success': true,
          'message': null,
          'data': {'status': 2, 'tip': 'ok'},
        };
        expect((await service.checkLogin('u115')).complete, true);
        api.payload = {
          'status': 2,
          'tip': 'not ok',
          'success': false,
          'data': {'status': 2, 'tip': 'not ok'},
        };
        await expectLater(service.checkLogin('u115'), throwsStateError);
      });

      test(
        'controller keeps original usage version detection and data on load failure',
        () async {
          final app = _App();
          final controller = _controller(api, app, v3);
          api.respond = (call) => call.path.endsWith('/Storages')
              ? _settings()
              : v3
              ? {
                  'success': true,
                  'data': {'total': 100, 'available': 60},
                }
              : {'total': 100, 'available': 60};
          await controller.loadStorages();
          expect(controller.usageMap['u115']?.available, 60);
          final usage = api.calls.last;
          expect(
            usage.path,
            v3 ? '/api/v1/storage/manage' : '/api/v1/storage/usage/u115',
          );
          if (v3) {
            expect(usage.body, {
              'target': 'u115',
              'action': 'usage',
              'params': {},
            });
          }
          api.status = 500;
          await controller.loadStorages();
          expect(controller.storages.single, _original);
          expect(controller.errorText.value, isNotNull);
          controller.onClose();
        },
      );

      test(
        'controller suppresses duplicate and competing submissions, checks never save',
        () async {
          final controller = _controller(api, _App(), v3);
          final gate = Completer<void>();
          api.beforeResponse = (_) => gate.future;
          api.respond = (call) => call.path.endsWith('/Storages')
              ? _settings()
              : {
                  'success': true,
                  'data': {'status': 2, 'tip': '登录成功'},
                };
          final first = controller.checkLogin('u115');
          await Future<void>.delayed(Duration.zero);
          expect(controller.isSubmitting.value, true);
          expect(await controller.checkLogin('u115'), isNull);
          expect(
            await controller.resetStorage('u115', confirmed: true),
            isNull,
          );
          expect(
            await controller.saveConfiguration(_original, {'token': 'new'}),
            isNull,
          );
          expect(api.calls, hasLength(1));
          gate.complete();
          expect((await first)?.complete, true);
          expect(controller.isSubmitting.value, false);
          expect(
            api.calls
                .where((call) => call.method == 'POST')
                .every(
                  (call) => [
                    'check_login',
                    'usage',
                  ].contains((call.body as Map)['action']),
                ),
            true,
          );
          api.status = 500;
          expect(await controller.checkLogin('u115'), isNull);
          expect(controller.operationError.value, isNotNull);
          expect(controller.isSubmitting.value, false);
          controller.onClose();
        },
      );
      test('failed save HTTP response is not reported as success', () async {
        api.respond = (call) => call.path.endsWith('/Storages') ? _settings() : {'success': true};
        api.beforeResponse = (call) async {
          api.status = call.path.endsWith('/Storages') ? 200 : 503;
        };
        await expectLater(service.saveConfiguration(_original, {'token': 'new'}), throwsStateError);
        expect(api.calls, hasLength(2));
      });

      for (final action in ['save', 'reset', 'qrcode']) {
        test('controller serializes duplicate $action submissions', () async {
          final controller = _controller(api, _App(), v3);
          final gate = Completer<void>();
          api.beforeResponse = (_) => gate.future;
          api.respond = (call) => call.path.endsWith('/Storages')
              ? _settings()
              : {'success': true, 'data': {'codeContent': '115://scan/test'}};
          Future<dynamic> submit() => switch (action) {
            'save' => controller.saveConfiguration(_original, {'token': 'new'}),
            'reset' => controller.resetStorage('u115', confirmed: true),
            _ => controller.acquireQrCode('u115'),
          };
          final first = submit();
          await Future<void>.delayed(Duration.zero);
          expect(controller.isSubmitting.value, true);
          expect(await submit(), isNull);
          expect(api.calls, hasLength(1));
          gate.complete();
          expect(await first, isNotNull);
          expect(controller.isSubmitting.value, false);
          const mutatingActions = {
            'save': 'save_config',
            'reset': 'reset_config',
            'qrcode': 'generate_qrcode',
          };
          final mutatingCalls = api.calls.where((call) {
            if (v3) {
              return (call.body as Map?)?['action'] == mutatingActions[action];
            }
            final segment = action == 'qrcode' ? 'qrcode' : action;
            return call.path.contains('/$segment/');
          });
          expect(mutatingCalls, hasLength(1));
          controller.onClose();
        });
      }

      test('malformed login status cannot complete or trigger a save', () async {
        for (final data in [null, {}, {'status': true, 'tip': 'ok'}, {'status': 2}, ['token']]) {
          api.payload = {'success': true, 'data': data};
          await expectLater(service.checkLogin('u115'), throwsFormatException);
        }
      });
    });
  }

  Future<StorageListController> mountSheet(
    WidgetTester tester,
    _Api api,
    _App app,
  ) async {
    final controller = _controller(api, app, true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StorageManageSheet(
              storage: _original,
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    'renders QR content with existing QR package and handles provider image',
    (tester) async {
      final api = _Api()
        ..payload = {
          'success': true,
          'data': {'codeContent': '115://scan/test'},
        };
      final controller = await mountSheet(tester, api, _App());
      await tester.tap(find.text('获取登录二维码'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<QrImageView>(find.byType(QrImageView)).semanticsLabel,
        '网盘登录二维码',
      );
      api.payload = {
        'success': true,
        'data': {'status': 0, 'tip': '等待扫码'},
      };
      await tester.ensureVisible(find.text('检查扫码/授权结果'));
      await tester.tap(find.text('检查扫码/授权结果'));
      await tester.pumpAndSettle();
      expect(find.text('等待扫码'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      controller.onClose();
    },
  );

  testWidgets(
    'reset cancellation sends nothing; failed reset preserves QR and permits retry',
    (tester) async {
      final api = _Api()
        ..payload = {
          'success': true,
          'data': {'codeContent': '115://scan/test'},
        };
      final controller = await mountSheet(tester, api, _App());
      await tester.tap(find.text('获取登录二维码'));
      await tester.pumpAndSettle();
      api.calls.clear();
      await tester.ensureVisible(find.text('重置存储配置'));
      await tester.tap(find.text('重置存储配置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(api.calls, isEmpty);
      await tester.tap(find.text('重置存储配置'));
      await tester.pumpAndSettle();
      api.payload = {'success': false, 'message': 'reset refused'};
      await tester.tap(find.text('确认重置'));
      await tester.pumpAndSettle();
      expect(api.calls.single.body, {
        'target': 'u115',
        'action': 'reset_config',
        'params': {},
      });
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('reset refused'), findsOneWidget);
      controller.onClose();
    },
  );

  testWidgets('editor keeps draft after failed save and confirms discard', (
    tester,
  ) async {
    final api = _Api()
      ..respond = (call) => call.path.endsWith('/Storages')
          ? _settings()
          : {'success': false, 'message': 'save refused'};
    final controller = await mountSheet(tester, api, _App());
    await tester.tap(find.text('编辑存储配置'));
    await tester.pumpAndSettle();
    const draft = '{"access_token":"new","nested":{"keep":true}}';
    await tester.enterText(find.byType(TextField), draft);
    await tester.pump();
    await tester.tap(find.text('保存配置'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      draft,
    );
    expect(find.text('save refused'), findsWidgets);
    expect(jsonDecode(draft)['nested'], {'keep': true});
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    await tester.tap(find.text('继续编辑'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      draft,
    );
    controller.onClose();
  });

  testWidgets(
    'no manage permission disables all management actions without requests',
    (tester) async {
      final api = _Api();
      final controller = await mountSheet(tester, api, _App()..allowed = false);
      for (final title in [
        '获取登录二维码',
        'OAuth 授权链接',
        '检查扫码/授权结果',
        '编辑存储配置',
        '重置存储配置',
      ]) {
        await tester.ensureVisible(find.text(title));
        await tester.tap(find.text(title));
      }
      await tester.pumpAndSettle();
      expect(api.calls, isEmpty);
      controller.onClose();
    },
  );
}
