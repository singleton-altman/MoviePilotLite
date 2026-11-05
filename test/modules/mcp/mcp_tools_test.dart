import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/theme/app_theme.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/mcp/controllers/mcp_tools_controller.dart';
import 'package:moviepilot_mobile/modules/mcp/pages/mcp_tools_page.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/app_service.dart';
import 'package:moviepilot_mobile/widgets/glass_search_floating_bar.dart';

Map<String, dynamic> fullConfig([String id = 'server-a']) => {
  'id': id,
  'name': 'Full config',
  'enabled': true,
  'transport': 'stdio',
  'command': 'npx',
  'args': ['--yes', '@example/mcp', 'argument with spaces'],
  'env': {'SECRET': 'credential', 'EMPTY': ''},
  'headers': {'Authorization': 'Bearer private'},
  'url': null,
  'description': null,
  'timeout': 127,
  'tool_prefix': 'custom_',
  'require_admin': false,
  'future_config': {
    'nested': [
      null,
      false,
      2,
      {'key': 'value'},
    ],
  },
};

Response<dynamic> reply(dynamic data, [int status = 200]) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/test'),
  statusCode: status,
  data: data,
);

class FakeApi implements ApiClient {
  @override
  String? baseUrl = 'https://server-a.example';
  @override
  String? token = 'jwt-a';
  final gets =
      <
        ({
          String path,
          String url,
          String? token,
          Map<String, dynamic>? headers,
          bool skipAuth,
        })
      >[];
  final posts =
      <
        ({
          String path,
          String url,
          String? token,
          Map<String, dynamic>? data,
          Map<String, dynamic>? headers,
          bool skipAuth,
        })
      >[];
  Completer<void>? beforePostDispatch;
  Future<Response<dynamic>> Function(String)? onGet;
  Future<Response<dynamic>> Function(String, Map<String, dynamic>?)? onPost;

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
    final url = path;
    path = path.replaceFirst(RegExp(r'^https?://[^/]+'), '');
    gets.add((
      path: path,
      url: url,
      token: token,
      headers: headers,
      skipAuth: skipUnauthorizedHandling,
    ));
    final response = onGet != null
        ? await onGet!(path)
        : reply(
            path == '/api/v1/system/env'
                ? {'API_TOKEN': 'test-api-key'}
                : path == '/api/v1/mcp/tools'
                ? <dynamic>[]
                : {
                    'success': true,
                    'data': {
                      'servers': [fullConfig(), fullConfig('server-b')],
                    },
                  },
          );
    return response as Response<T>;
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
    final url = path;
    path = path.replaceFirst(RegExp(r'^https?://[^/]+'), '');
    if (beforePostDispatch != null) await beforePostDispatch!.future;
    posts.add((
      path: path,
      url: url,
      token: token,
      data: data,
      headers: headers,
      skipAuth: skipUnauthorizedHandling,
    ));
    return (onPost != null
            ? await onPost!(path, data)
            : reply({'success': true}))
        as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAdminAppService extends GetxService implements AppService {
  @override
  Future<void> onInit() async {
    super.onInit();
  }

  @override
  bool isSuperuser = true;
  @override
  final agentCacheScopeKey = 'server-a|user-a'.obs;
  @override
  String? baseUrl = 'https://server-a.example';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAdminAppService app;
  setUp(() {
    Get.testMode = true;
    app = FakeAdminAppService();
    Get.put<AppService>(app);
  });
  tearDown(() {
    Get.reset();
  });

  group('lossless MCP configuration', () {
    test(
      'all documented and unknown fields round trip without defaults or null loss',
      () {
        final input = fullConfig();
        expect(McpServerConfig.fromJson(input).toJson(), input);
        final minimal = {'id': 'minimal', 'name': 'Minimal'};
        final model = McpServerConfig.fromJson(minimal);
        expect(model.enabled, isTrue);
        expect(model.toJson(), minimal);
      },
    );

    test('enabled copy changes only enabled and keeps original immutable', () {
      final input = fullConfig();
      final original = McpServerConfig.fromJson(input);
      expect(original.withEnabled(false).toJson(), {
        ...input,
        'enabled': false,
      });
      expect(original.toJson(), input);
    });

    test(
      'nested inputs and serialized outputs cannot mutate stored config',
      () {
        final input = fullConfig();
        final model = McpServerConfig.fromJson(input);
        (input['args'] as List).clear();
        (input['env'] as Map)['SECRET'] = 'changed';
        final output = model.toJson();
        (output['headers'] as Map).clear();
        ((output['future_config'] as Map)['nested'] as List).clear();
        expect(model.toJson(), fullConfig());
      },
    );

    test('JSON editor preserves all fields and validates documented types', () {
      expect(
        McpServerConfig.parseEditorJson(jsonEncode(fullConfig())).toJson(),
        fullConfig(),
      );
      for (final patch in [
        {'id': ''},
        {'name': 1},
        {
          'args': ['valid', 3],
        },
        {
          'env': {'a': 3},
        },
        {'headers': []},
        {'timeout': 1.5},
        {'enabled': 'false'},
        {'require_admin': null},
        {'transport': 'invented'},
      ]) {
        expect(
          () => McpServerConfig.parseEditorJson(
            jsonEncode({...fullConfig(), ...patch}),
          ),
          throwsFormatException,
        );
      }
      for (final text in ['[]', 'null', '{']) {
        expect(
          () => McpServerConfig.parseEditorJson(text),
          throwsFormatException,
        );
      }
    });
  });

  group('controller transactions and contracts', () {
    late FakeApi api;
    late McpToolsController controller;
    setUp(() {
      api = FakeApi();
      controller = McpToolsController(apiClient: api, log: AppLog());
    });

    test(
      'toggle POST preserves full target and every unrelated configuration',
      () async {
        await controller.loadServers();
        expect(
          await controller.setServerEnabled(controller.servers.first, false),
          isNull,
        );
        expect(api.posts.single.path, '/api/v1/message/agent/mcp/servers');
        expect(api.posts.single.data, {
          'servers': [
            {...fullConfig(), 'enabled': false},
            fullConfig('server-b'),
          ],
        });
        expect(controller.servers.first.enabled, isFalse);
      },
    );

    test(
      'business and HTTP failures roll back toggles and clear busy state',
      () async {
        await controller.loadServers();
        for (final response in [
          reply({'success': false, 'message': 'denied'}),
          reply(null, 500),
        ]) {
          api.onPost = (_, __) async => response;
          expect(
            await controller.setServerEnabled(controller.servers.first, false),
            isNotNull,
          );
          expect(controller.servers.first.toJson(), fullConfig());
          expect(controller.isSavingServers.value, isFalse);
        }
      },
    );

    test(
      'unknown network outcome rolls back and blocks saves until reload',
      () async {
        await controller.loadServers();
        api.onPost = (_, __) async => throw StateError('network');
        expect(
          await controller.setServerEnabled(controller.servers.first, false),
          contains('未知'),
        );
        expect(controller.servers.first.toJson(), fullConfig());
        expect(
          await controller.deleteServer(controller.servers.first),
          isNotNull,
        );
        expect(api.posts, hasLength(1));
        await controller.loadServers();
        expect(controller.serversError.value, isNull);
      },
    );

    test(
      'overlapping saves fail explicitly and refresh cannot overwrite in-flight save',
      () async {
        await controller.loadServers();
        final pending = Completer<Response<dynamic>>();
        api.onPost = (_, __) => pending.future;
        final first = controller.setServerEnabled(
          controller.servers.first,
          false,
        );
        expect(
          await controller.deleteServer(controller.servers.last),
          contains('正在保存'),
        );
        await controller.loadServers();
        expect(api.gets, hasLength(1));
        expect(api.posts, hasLength(1));
        pending.complete(reply({'success': true}));
        expect(await first, isNull);
      },
    );

    test(
      'add/edit/delete use verified full-list POST and retain unrelated raw fields',
      () async {
        await controller.loadServers();
        expect(
          await controller.upsertServerJson(jsonEncode(fullConfig('new'))),
          isNull,
        );
        final original = controller.servers.first;
        expect(
          await controller.upsertServerJson(
            jsonEncode({...original.toJson(), 'name': 'Edited'}),
            original: original,
          ),
          isNull,
        );
        expect(api.posts.last.data!['servers'], [
          {...fullConfig(), 'name': 'Edited'},
          fullConfig('server-b'),
          fullConfig('new'),
        ]);
        expect(
          await controller.upsertServerJson(jsonEncode(fullConfig('new'))),
          contains('ID'),
        );
        expect(await controller.deleteServer(controller.servers.first), isNull);
        expect(api.posts.last.data, {
          'servers': [fullConfig('server-b'), fullConfig('new')],
        });
      },
    );

    test('failed create and delete both roll back full list', () async {
      await controller.loadServers();
      api.onPost = (_, __) async =>
          reply({'success': false, 'message': 'save rejected'});
      expect(
        await controller.upsertServerJson(jsonEncode(fullConfig('new'))),
        'save rejected',
      );
      expect(controller.servers.map((e) => e.toJson()).toList(), [
        fullConfig(),
        fullConfig('server-b'),
      ]);
      expect(
        await controller.deleteServer(controller.servers.first),
        'save rejected',
      );
      expect(controller.servers, hasLength(2));
    });

    test(
      'malformed or failed list never becomes an editable partial configuration',
      () async {
        api.onGet = (_) async => reply({
          'success': true,
          'data': {
            'servers': [fullConfig(), null],
          },
        });
        await controller.loadServers();
        expect(controller.serversLoaded.value, isFalse);
        expect(
          await controller.upsertServerJson(jsonEncode(fullConfig())),
          isNotNull,
        );
        expect(api.posts, isEmpty);
        api.onGet = (_) async =>
            reply({'success': false, 'message': 'no access'});
        await controller.loadServers();
        expect(controller.serversError.value, 'no access');
      },
    );

    test(
      'initialization single-flights token lookup and accepts valid empty list',
      () async {
        await Future.wait([controller.initialize(), controller.initialize()]);
        expect(
          api.gets.where((r) => r.path == '/api/v1/system/env'),
          hasLength(1),
        );
        expect(
          api.gets.where((r) => r.path == '/api/v1/mcp/tools'),
          hasLength(1),
        );
        expect(controller.tools, isEmpty);
        expect(controller.toolsError.value, isNull);
      },
    );

    test(
      'business errors in tool list and connection tests are not success',
      () async {
        api.onGet = (path) async => reply(
          path == '/api/v1/system/env'
              ? {'API_TOKEN': 'test-key'}
              : {'success': false, 'message': 'tool list denied'},
        );
        await controller.loadTools();
        expect(controller.toolsError.value, 'tool list denied');
        api.onPost = (_, __) async => reply({
          'success': true,
          'data': {'success': false, 'message': 'connection denied'},
        });
        final result = await controller.testServer(
          McpServerConfig.fromJson(fullConfig()),
        );
        expect(result.ok, isFalse);
        expect(result.message, 'connection denied');
        expect(api.posts.single.data, {'server': fullConfig()});
      },
    );

    test(
      'tool requires explicit confirmation and rejects malformed arguments before network',
      () async {
        expect((await controller.callTool('mutate', '{}')).ok, isFalse);
        for (final text in ['[]', 'null', '{']) {
          expect(
            (await controller.callTool('mutate', text, confirmed: true)).ok,
            isFalse,
          );
        }
        expect(api.gets, isEmpty);
        expect(api.posts, isEmpty);
      },
    );

    test('v2 and v3 tool results and v2 business errors are parsed', () async {
      for (final data in [
        {'success': true, 'result': 'v2 text'},
        {
          'success': true,
          'data': {'result': 'v3 text'},
        },
        {'success': false, 'error': 'v2 tool error'},
        {'success': false, 'message': 'v3 tool error'},
      ]) {
        api.onPost = (_, __) async => reply(data);
        final result = await controller.callTool(
          'tool',
          '{"key":1}',
          confirmed: true,
        );
        expect(result.ok, data['success']);
        expect(
          result.result,
          data['result'] ??
              (data['data'] as Map?)?['result'] ??
              data['error'] ??
              data['message'],
        );
      }
      expect(api.posts.every((r) => r.skipAuth), isTrue);
      expect(api.posts.last.headers, {'X-API-KEY': 'test-api-key'});
      expect(api.posts.last.data, {
        'tool_name': 'tool',
        'arguments': {'key': 1},
      });
    });

    test(
      'tool duplicate submission cannot execute twice and API-key errors are isolated',
      () async {
        final pending = Completer<Response<dynamic>>();
        api.onPost = (_, __) => pending.future;
        final first = controller.callTool('tool', '{}', confirmed: true);
        await Future<void>.delayed(Duration.zero);
        expect(
          (await controller.callTool('tool', '{}', confirmed: true)).ok,
          isFalse,
        );
        expect(api.posts, hasLength(1));
        expect(api.posts.single.skipAuth, isTrue);
        pending.complete(reply({'detail': 'Bad API key'}, 401));
        expect((await first).ok, isFalse);
        expect(controller.isCallingTool.value, isFalse);
        await controller.loadTools();
        expect(api.gets.last.skipAuth, isTrue);
      },
    );

    test(
      'schema path is escaped and MCP GET does not clear JWT auth',
      () async {
        api.onGet = (path) async => reply(
          path == '/api/v1/system/env'
              ? {'API_TOKEN': 'key'}
              : {'type': 'object'},
        );
        expect(await controller.fetchToolSchema('tool/name space'), {
          'type': 'object',
        });
        expect(
          api.gets.last.path,
          '/api/v1/mcp/tools/tool%2Fname%20space/schema',
        );
        expect(api.gets.last.skipAuth, isTrue);
      },
    );

    test(
      'missing API token prevents schema/tool requests instead of sending JWT alone',
      () async {
        api.onGet = (_) async =>
            reply({'success': false, 'message': 'forbidden'});
        await controller.loadTools();
        expect(controller.toolsError.value, isNotNull);
        expect(
          (await controller.callTool('tool', '{}', confirmed: true)).ok,
          isFalse,
        );
        expect(await controller.fetchToolSchema('tool'), isNull);
        expect(api.gets.every((r) => r.path == '/api/v1/system/env'), isTrue);
        expect(api.posts, isEmpty);
      },
    );

    test('malformed save response rolls back and requires reload', () async {
      await controller.loadServers();
      api.onPost = (_, __) async => reply({'unexpected': true});
      expect(
        await controller.setServerEnabled(controller.servers.first, false),
        isNotNull,
      );
      expect(controller.servers.first.toJson(), fullConfig());
      expect(controller.serversError.value, isNotNull);
      expect(
        await controller.deleteServer(controller.servers.first),
        isNotNull,
      );
      expect(api.posts, hasLength(1));
    });

    test('connection tests reject duplicates and release busy state', () async {
      final pending = Completer<Response<dynamic>>();
      api.onPost = (_, __) => pending.future;
      final config = McpServerConfig.fromJson(fullConfig());
      final first = controller.testServer(config);
      expect((await controller.testServer(config)).ok, isFalse);
      pending.complete(
        reply({
          'success': true,
          'data': {'success': true, 'tool_count': 3, 'tools': []},
        }),
      );
      expect((await first).message, contains('3'));
      expect(controller.isTestingServer.value, isFalse);
      expect(api.posts, hasLength(1));
    });

    test(
      'schema business failure and malformed tool success never report success',
      () async {
        api.onGet = (path) async => reply(
          path == '/api/v1/system/env'
              ? {'API_TOKEN': 'key'}
              : {'success': false, 'message': 'schema denied'},
        );
        expect(await controller.fetchToolSchema('tool'), isNull);
        api.onPost = (_, __) async => reply({'success': true});
        expect(
          (await controller.callTool('tool', '{}', confirmed: true)).ok,
          isFalse,
        );
      },
    );

    test(
      'unregistered AppService fails closed without any network request',
      () async {
        await Get.delete<AppService>(force: true);
        expect(Get.isRegistered<AppService>(), isFalse);
        await controller.initialize();
        expect(
          (await controller.callTool('tool', '{}', confirmed: true)).ok,
          isFalse,
        );
        expect(
          (await controller.testServer(
            McpServerConfig.fromJson(fullConfig()),
          )).ok,
          isFalse,
        );
        expect(
          await controller.upsertServerJson(jsonEncode(fullConfig())),
          isNotNull,
        );
        expect(api.gets, isEmpty);
        expect(api.posts, isEmpty);
      },
    );

    test(
      'user switch clears cached config and blocks every old-controller command',
      () async {
        await controller.initialize();
        final original = controller.servers.first;
        final requestCount = api.gets.length;
        app.agentCacheScopeKey.value = 'server-a|user-b';
        await Future<void>.delayed(Duration.zero);
        expect(controller.servers, isEmpty);
        expect(controller.tools, isEmpty);
        expect(controller.serversLoaded.value, isFalse);
        expect(controller.apiTokenResolved.value, isFalse);
        expect(await controller.setServerEnabled(original, false), isNotNull);
        expect(await controller.deleteServer(original), isNotNull);
        expect(
          await controller.upsertServerJson(jsonEncode(fullConfig())),
          isNotNull,
        );
        expect((await controller.testServer(original)).ok, isFalse);
        expect(
          (await controller.callTool('tool', '{}', confirmed: true)).ok,
          isFalse,
        );
        expect(await controller.fetchToolSchema('tool'), isNull);
        await controller.loadServers();
        await controller.loadTools();
        expect(api.gets, hasLength(requestCount));
        expect(api.posts, isEmpty);
      },
    );

    for (final change in ['app URL', 'API URL']) {
      test(
        '$change switch alone invalidates cached config and API token',
        () async {
          await controller.initialize();
          final original = controller.servers.first;
          if (change == 'app URL') {
            app.baseUrl = 'https://server-b.example';
          } else {
            api.baseUrl = 'https://server-b.example';
          }
          expect(await controller.setServerEnabled(original, false), isNotNull);
          expect(
            (await controller.callTool('tool', '{}', confirmed: true)).ok,
            isFalse,
          );
          expect(controller.servers, isEmpty);
          expect(controller.apiTokenResolved.value, isFalse);
          expect(api.posts, isEmpty);
        },
      );
    }

    test(
      'late token response cannot authorize a new-server POST; fresh controller gets new key',
      () async {
        final pending = Completer<Response<dynamic>>();
        api.onGet = (_) => pending.future;
        final oldCall = controller.callTool('tool', '{}', confirmed: true);
        await Future<void>.delayed(Duration.zero);
        app.baseUrl = api.baseUrl = 'https://server-b.example';
        api.token = 'jwt-b';
        app.agentCacheScopeKey.value = 'server-b|user-b';
        pending.complete(reply({'API_TOKEN': 'old-server-key'}));
        expect((await oldCall).ok, isFalse);
        expect(api.posts, isEmpty);
        expect(controller.apiTokenResolved.value, isFalse);
        api.onGet = (path) async => reply(
          path == '/api/v1/system/env'
              ? {'API_TOKEN': 'new-server-key'}
              : path == '/api/v1/mcp/tools'
              ? []
              : {
                  'success': true,
                  'data': {
                    'servers': [fullConfig('new-server')],
                  },
                },
        );
        api.onPost = (_, __) async =>
            reply({'success': true, 'result': 'new result'});
        final fresh = McpToolsController(apiClient: api, log: AppLog());
        await fresh.initialize();
        expect(fresh.servers.single.id, 'new-server');
        expect(
          (await fresh.callTool('tool', '{}', confirmed: true)).ok,
          isTrue,
        );
        expect(api.posts.single.headers, {'X-API-KEY': 'new-server-key'});
        expect(
          api.posts.single.url,
          'https://server-b.example/api/v1/mcp/tools/call',
        );
        expect(api.posts.single.token, 'jwt-b');
      },
    );

    test('late old-scope server list cannot populate current state', () async {
      final pending = Completer<Response<dynamic>>();
      api.onGet = (_) => pending.future;
      final load = controller.loadServers();
      app.agentCacheScopeKey.value = 'server-a|other-user';
      pending.complete(
        reply({
          'success': true,
          'data': {
            'servers': [fullConfig()],
          },
        }),
      );
      await load;
      expect(controller.servers, isEmpty);
      expect(controller.serversLoaded.value, isFalse);
      expect(api.posts, isEmpty);
    });

    test(
      'old-scope save rollback never restores cleared credentials or server config',
      () async {
        await controller.loadServers();
        final pending = Completer<Response<dynamic>>();
        api.onPost = (_, __) => pending.future;
        final save = controller.setServerEnabled(
          controller.servers.first,
          false,
        );
        app.agentCacheScopeKey.value = 'server-a|other-user';
        pending.complete(reply({'success': false, 'message': 'rejected'}));
        expect(await save, isNotNull);
        expect(controller.servers, isEmpty);
        expect(controller.serversLoaded.value, isFalse);
        expect(controller.isSavingServers.value, isFalse);
      },
    );

    test(
      'deferred API dispatch pins old config to original server and bearer token',
      () async {
        await controller.loadServers();
        api.beforePostDispatch = Completer<void>();
        final save = controller.setServerEnabled(
          controller.servers.first,
          false,
        );
        app.baseUrl = api.baseUrl = 'https://server-b.example';
        api.token = 'jwt-b';
        app.agentCacheScopeKey.value = 'server-b|user-b';
        api.beforePostDispatch!.complete();
        expect(await save, isNotNull);
        expect(
          api.posts.single.url,
          'https://server-a.example/api/v1/message/agent/mcp/servers',
        );
        expect(api.posts.single.token, 'jwt-a');
        expect(controller.servers, isEmpty);
      },
    );

    test('failed reload makes previously loaded list non-writable', () async {
      await controller.loadServers();
      expect(controller.serversLoaded.value, isTrue);
      api.onGet = (_) async =>
          reply({'success': false, 'message': 'reload denied'});
      await controller.loadServers();
      expect(controller.serversLoaded.value, isFalse);
      expect(
        await controller.setServerEnabled(controller.servers.first, false),
        isNotNull,
      );
      expect(api.posts, isEmpty);
    });

    test('registered non-admin cannot read secrets or mutate MCP', () async {
      app.isSuperuser = false;
      await controller.initialize();
      expect(
        (await controller.callTool('tool', '{}', confirmed: true)).ok,
        isFalse,
      );
      expect(
        (await controller.testServer(
          McpServerConfig.fromJson(fullConfig()),
        )).ok,
        isFalse,
      );
      expect(
        await controller.upsertServerJson(jsonEncode(fullConfig())),
        isNotNull,
      );
      expect(api.gets, isEmpty);
      expect(api.posts, isEmpty);
    });
  });

  testWidgets('tool search matches description and resets without requests', (
    tester,
  ) async {
    final api = FakeApi();
    final controller = Get.put(
      McpToolsController(apiClient: api, log: AppLog()),
    );
    await controller.initialize();
    controller.tools.assignAll(const [
      McpToolInfo(
        name: 'library_query',
        description: '查询媒体库',
        inputSchema: {
          'properties': {
            'title': {'type': 'string'},
          },
        },
      ),
      McpToolInfo(name: 'download_start', description: '创建下载任务'),
    ]);
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.lightTheme, home: const McpToolsPage()),
    );
    await tester.pumpAndSettle();
    final requestCount = api.gets.length;
    expect(find.text('连接能力，扩展可能'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('搜索工具名称或描述'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), '  媒体库  ');
    await tester.pump();
    expect(find.text('download_start'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('library_query'), findsOneWidget);
    expect(find.text('download_start'), findsNothing);
    expect(find.text('1 个参数'), findsOneWidget);
    expect(
      tester
          .widget<GlassSearchFloatingBar>(find.byType(GlassSearchFloatingBar))
          .keyword,
      '媒体库',
    );
    await tester.tap(find.text('媒体库'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'NO_MATCH');
    await tester.tapAt(const Offset(10, 100));
    await tester.pumpAndSettle();
    expect(find.text('library_query'), findsOneWidget);
    expect(find.text('download_start'), findsNothing);
    expect(find.text('媒体库'), findsOneWidget);
    await tester.tap(find.text('服务器'));
    await tester.pumpAndSettle();
    expect(find.text('搜索名称、ID 或传输方式'), findsOneWidget);
    await tester.tap(find.text('工具'));
    await tester.pumpAndSettle();
    expect(find.text('媒体库'), findsOneWidget);
    await tester.tap(find.text('媒体库'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoSearchTextField>(
            find.byType(CupertinoSearchTextField),
          )
          .controller!
          .text,
      '媒体库',
    );
    await tester.enterText(find.byType(CupertinoSearchTextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('library_query'), findsOneWidget);
    expect(find.text('download_start'), findsOneWidget);
    await tester.tap(find.text('搜索工具名称或描述'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'NO_MATCH');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的工具'), findsOneWidget);
    await tester.tap(find.text('清除搜索'));
    await tester.pumpAndSettle();
    expect(find.text('library_query'), findsOneWidget);
    expect(api.gets, hasLength(requestCount));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating search stays clear of content and follows swiped tabs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async {
        tester.view.reset();
        await tester.binding.setSurfaceSize(null);
      });
      final api = FakeApi();
      final controller = Get.put(
        McpToolsController(apiClient: api, log: AppLog()),
      );
      await controller.initialize();
      controller.tools.assignAll(
        List.generate(
          24,
          (index) => McpToolInfo(name: 'tool_$index', description: '工具说明'),
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.lightTheme, home: const McpToolsPage()),
      );
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: find.byKey(const PageStorageKey('mcp-tools')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('tool_23'),
        500,
        scrollable: scrollable,
      );
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.text('tool_23')).dy,
        lessThan(tester.getTopLeft(find.byType(GlassSearchFloatingBar)).dy),
      );
      await tester.drag(find.byType(TabBarView), const Offset(-350, 0));
      await tester.pumpAndSettle();
      expect(find.text('搜索名称、ID 或传输方式'), findsOneWidget);
      expect(find.byTooltip('添加服务器'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoSlidingSegmentedControl<int>>(
              find.byType(CupertinoSlidingSegmentedControl<int>).first,
            )
            .groupValue,
        1,
      );
      await tester.drag(find.byType(TabBarView), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text('搜索工具名称或描述'), findsOneWidget);
      expect(find.byTooltip('添加服务器'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('server filters preserve config and never show credentials', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() async {
      tester.view.reset();
      await tester.binding.setSurfaceSize(null);
    });
    final api = FakeApi();
    final controller = Get.put(
      McpToolsController(apiClient: api, log: AppLog()),
    );
    await controller.initialize();
    controller.servers.assignAll([
      McpServerConfig.fromJson({
        ...fullConfig(),
        'name': 'Library service',
        'url': 'https://private.example?token=do-not-show',
      }),
      McpServerConfig.fromJson({
        ...fullConfig('server-b'),
        'name': 'Archive service',
        'enabled': false,
        'transport': 'sse',
      }),
    ]);
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.darkTheme, home: const McpToolsPage()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('服务器'));
    await tester.pumpAndSettle();
    expect(find.text('服务器配置 · 2/2'), findsOneWidget);
    expect(find.text('管理外部连接'), findsNothing);
    expect(find.textContaining('do-not-show'), findsNothing);
    expect(find.textContaining('Bearer private'), findsNothing);
    final disabledFilter = find.descendant(
      of: find.byType(CupertinoSlidingSegmentedControl<int>).last,
      matching: find.text('已停用'),
    );
    await tester.tap(disabledFilter);
    await tester.pumpAndSettle();
    expect(find.text('Archive service'), findsOneWidget);
    expect(find.text('Library service'), findsNothing);
    expect(find.text('服务器配置 · 1/2'), findsOneWidget);
    await tester.tap(find.text('工具'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('服务器'));
    await tester.pumpAndSettle();
    expect(find.text('Library service'), findsNothing);
    await tester.tap(find.text('搜索名称、ID 或传输方式'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoSearchTextField), 'not-found');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('没有匹配的服务器'), findsOneWidget);
    await tester.tap(find.text('重置筛选'));
    await tester.pumpAndSettle();
    expect(find.text('Library service'), findsOneWidget);
    expect(api.posts, isEmpty);
    expect(controller.servers, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'responsive MCP layout supports ${brightness.name} and large text',
      (tester) async {
        final api = FakeApi();
        final controller = Get.put(
          McpToolsController(apiClient: api, log: AppLog()),
        );
        await controller.initialize();
        controller.tools.assignAll(const [
          McpToolInfo(
            name: 'a_very_long_tool_name_with_many_segments_and_identifiers',
            description: '查询媒体库并获取详细的媒体信息、订阅状态以及相关资源。',
            inputSchema: {
              'properties': {
                'query': {'type': 'string'},
              },
            },
          ),
        ]);
        controller.servers.assignAll([
          McpServerConfig.fromJson({...fullConfig(), 'name': '媒体库服务器与工具集成服务'}),
        ]);
        addTearDown(() async {
          tester.view.reset();
          await tester.binding.setSurfaceSize(null);
        });
        for (final width in [375.0, 768.0, 1024.0, 1440.0]) {
          await tester.binding.setSurfaceSize(Size(width, 1000));
          await tester.pumpWidget(
            GetMaterialApp(
              theme: brightness == Brightness.light
                  ? AppTheme.lightTheme
                  : AppTheme.darkTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(width == 375 ? 1.8 : 1),
                ),
                child: child!,
              ),
              home: const McpToolsPage(),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'tools width $width');
          await tester.tap(find.text('服务器'));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'servers width $width',
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      },
    );
  }

  testWidgets(
    'server editor formats losslessly and keeps save visible above keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() async {
        tester.view.reset();
        await tester.binding.setSurfaceSize(null);
      });
      final api = FakeApi();
      final controller = Get.put(
        McpToolsController(apiClient: api, log: AppLog()),
      );
      await controller.initialize();
      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.lightTheme, home: const McpToolsPage()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('服务器'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('添加服务器'));
      await tester.pumpAndSettle();
      final editor = find.widgetWithText(TextField, '完整 JSON 配置');
      await tester.enterText(editor, jsonEncode(fullConfig()));
      await tester.ensureVisible(find.text('格式化'));
      await tester.tap(find.text('格式化'));
      await tester.pumpAndSettle();
      expect(
        jsonDecode(tester.widget<TextField>(editor).controller!.text),
        fullConfig(),
      );
      tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio,
      );
      await tester.pumpAndSettle();
      final saveButton = find.ancestor(
        of: find.text('保存配置'),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(tester.getBottomLeft(saveButton).dy, lessThanOrEqualTo(544));
      expect(saveButton.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('保存配置'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('保存 MCP 配置？'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(api.posts, isEmpty);
    },
  );

  testWidgets('valid empty tool list does not refetch on rebuild', (
    tester,
  ) async {
    final api = FakeApi();
    final controller = Get.put(
      McpToolsController(apiClient: api, log: AppLog()),
    );
    await controller.initialize();
    await tester.pumpWidget(const GetMaterialApp(home: McpToolsPage()));
    await tester.pumpAndSettle();
    expect(find.text('暂无可用工具，可下拉刷新'), findsOneWidget);
    await tester.pumpWidget(const GetMaterialApp(home: McpToolsPage()));
    await tester.pumpAndSettle();
    expect(api.gets.where((r) => r.path == '/api/v1/mcp/tools'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tool executes only after explicit confirmation, cancel sends nothing',
    (tester) async {
      final api = FakeApi();
      api.onGet = (path) async => reply(
        path == '/api/v1/system/env'
            ? {'API_TOKEN': 'key'}
            : path == '/api/v1/mcp/tools'
            ? [
                {'name': 'mutating-tool'},
              ]
            : {
                'success': true,
                'data': {'servers': []},
              },
      );
      api.onPost = (_, __) async => reply({'success': true, 'result': 'done'});
      final controller = Get.put(
        McpToolsController(apiClient: api, log: AppLog()),
      );
      await controller.initialize();
      await tester.pumpWidget(const GetMaterialApp(home: McpToolsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('mutating-tool'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('调用工具'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('确认执行工具？'), findsOneWidget);
      expect(api.posts, isEmpty);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(api.posts, isEmpty);
      await tester.tap(find.text('调用工具'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('确认执行'));
      await tester.pumpAndSettle();
      expect(api.posts, hasLength(1));
      await tester.scrollUntilVisible(
        find.text('done'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('done'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
