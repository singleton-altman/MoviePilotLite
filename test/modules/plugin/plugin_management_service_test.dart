import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/modules/plugin/models/plugin_folder_models.dart';
import 'package:moviepilot_mobile/modules/plugin/services/plugin_management_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class _FakeApi extends Fake implements ApiClient {
  @override
  String? baseUrl = 'https://moviepilot.test';
  @override
  String? token = 'test-session';

  final calls =
      <
        ({
          String method,
          String path,
          Object? body,
          Map<String, dynamic>? query,
          bool raw,
        })
      >[];
  Future<Response<dynamic>> Function(String method, String path)? respond;

  Future<Response<T>> _request<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool raw = false,
  }) async {
    calls.add((method: method, path: path, body: body, query: query, raw: raw));
    final response = await respond!(method, path);
    return Response<T>(
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      data: response.data as T?,
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
  }) => _request<T>(
    'GET',
    path,
    query: queryParameters,
    raw: skipV3EnvelopeUnwrap,
  );

  @override
  Future<Response<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool skipUnauthorizedHandling = false,
  }) => _request<T>('POST', path, body: data, query: queryParameters);
}

Response<dynamic> _response(Object? data, [int? status = 200]) => Response(
  requestOptions: RequestOptions(path: '/test'),
  data: data,
  statusCode: status,
);

void main() {
  late _FakeApi api;
  late PluginManagementService service;
  final document = <String, dynamic>{
    'data': {
      'plugins': ['A'],
      'order': 7,
      'showIcon': false,
    },
    'Legacy': ['Unknown'],
  };

  setUp(() {
    api = _FakeApi();
    service = PluginManagementService(api);
  });

  test(
    'GET folders preserves a bare document including folder named data',
    () async {
      api.respond = (_, __) async => _response(document);
      final folders = await service.fetchFolders(service.scope);
      expect(folders.toJson(), document);
      expect(api.calls.single.path, '/api/v1/plugin/folders');
      expect(api.calls.single.raw, isTrue);
    },
  );

  test('GET supports V3 success envelopes without losing metadata', () async {
    api.respond = (_, __) async =>
        _response({'success': true, 'data': document});
    expect((await service.fetchFolders(service.scope)).toJson(), document);
  });

  test(
    'failed and malformed folder reads never look like empty success',
    () async {
      for (final response in [
        _response({'detail': 'Forbidden'}, 403),
        _response({'success': false, 'message': 'Rejected', 'data': {}}),
        _response(null),
        _response([]),
        _response({'F': 1}),
        _response({}, null),
      ]) {
        api.respond = (_, __) async => response;
        await expectLater(
          service.fetchFolders(service.scope),
          throwsA(isA<Exception>()),
        );
      }
    },
  );

  test('folder save rechecks snapshot and posts bare full document', () async {
    final expected = PluginFolders.fromJson(document);
    final updated = expected.rename('data', 'Renamed').withPlugins('Renamed', [
      'A',
      'B',
    ]);
    api.respond = (method, _) async =>
        _response(method == 'GET' ? document : {'success': true});
    await service.saveFolders(
      expected: expected,
      updated: updated,
      expectedScope: service.scope,
    );
    expect(api.calls.map((c) => c.method), ['GET', 'POST']);
    expect(api.calls.last.path, '/api/v1/plugin/folders');
    expect(api.calls.last.body, updated.toJson());
    expect((api.calls.last.body as Map)['Renamed'], {
      'plugins': ['A', 'B'],
      'order': 7,
      'showIcon': false,
    });
  });

  test('stale or failed reread sends no folder write', () async {
    final expected = PluginFolders.fromJson(document);
    for (final response in [
      _response({'Other': []}),
      _response({'detail': 'Unavailable'}, 503),
    ]) {
      api.calls.clear();
      api.respond = (_, __) async => response;
      await expectLater(
        service.saveFolders(
          expected: expected,
          updated: expected.create('New'),
          expectedScope: service.scope,
        ),
        throwsA(isA<Exception>()),
      );
      expect(api.calls.map((c) => c.method), ['GET']);
    }
  });

  test(
    'folder mutations require explicit success and propagate business errors',
    () async {
      final expected = PluginFolders.fromJson(document);
      for (final result in [
        null,
        {},
        {'success': false, 'message': 'Conflict'},
      ]) {
        api.respond = (method, _) async =>
            _response(method == 'GET' ? document : result);
        await expectLater(
          service.saveFolders(
            expected: expected,
            updated: expected.create('New'),
            expectedScope: service.scope,
          ),
          throwsA(isA<PluginManagementException>()),
        );
      }
    },
  );

  test(
    'duplicate writes and clone actions are blocked while mutation pending',
    () async {
      final pending = Completer<Response<dynamic>>();
      api.respond = (_, __) => pending.future;
      final first = service.clonePlugin('Plugin', '2');
      await expectLater(
        service.clonePlugin('Plugin', '2'),
        throwsA(isA<PluginManagementException>()),
      );
      final folders = PluginFolders.fromJson(document);
      await expectLater(
        service.saveFolders(
          expected: folders,
          updated: folders.create('New'),
          expectedScope: service.scope,
        ),
        throwsA(isA<PluginManagementException>()),
      );
      pending.complete(_response({'success': true}));
      await first;
      expect(api.calls, hasLength(1));
    },
  );

  test(
    'server/account changes invalidate reads and prevent stale writes',
    () async {
      final scope = service.scope;
      api.respond = (_, __) async {
        api.token = 'other-session';
        return _response(document);
      };
      await expectLater(
        service.fetchFolders(scope),
        throwsA(isA<PluginManagementException>()),
      );
      final count = api.calls.length;
      await expectLater(
        service.fetchFolders(scope),
        throwsA(isA<PluginManagementException>()),
      );
      expect(api.calls, hasLength(count));
    },
  );

  test(
    'clone posts one verified suffix body and accepts V2/V3 acknowledgments',
    () async {
      for (final result in [
        {'success': true, 'message': 'Created'},
        {
          'success': true,
          'message': 'Created',
          'data': {'instance_id': 'Plugin2'},
        },
      ]) {
        api.calls.clear();
        api.respond = (_, __) async => _response(result);
        expect(await service.clonePlugin('Plugin', ' 2 '), 'Created');
        expect(api.calls.single.method, 'POST');
        expect(api.calls.single.path, '/api/v1/plugin/clone/Plugin');
        expect(api.calls.single.body, {'suffix': '2'});
      }
    },
  );

  test('invalid suffix is rejected without requesting the server', () async {
    for (final suffix in ['', '../2', '你好', 'x' * 21]) {
      await expectLater(
        service.clonePlugin('Plugin', suffix),
        throwsA(isA<PluginManagementException>()),
      );
    }
    expect(api.calls, isEmpty);
  });

  test('clone failure never retries a possibly committed operation', () async {
    api.respond = (_, __) async => _response({
      'success': false,
      'message': 'Created but registration failed',
      'data': {'instance_id': 'Plugin2'},
    });
    await expectLater(
      service.clonePlugin('Plugin', '2'),
      throwsA(isA<PluginManagementException>()),
    );
    expect(api.calls, hasLength(1));
  });

  test(
    'remotes sends required token and reads actual metadata fields',
    () async {
      api.respond = (_, __) async => _response({
        'success': true,
        'data': [
          {
            'id': 'P',
            'name': 'Vue',
            'url': 'plugin/file/p/remoteEntry.js',
            'source_plugin_id': 'Source',
          },
        ],
      });
      final remotes = await service.fetchRemotes(service.scope);
      expect(api.calls.single.path, '/api/v1/plugin/remotes');
      expect(api.calls.single.query, {'token': 'moviepilot'});
      expect(remotes.single.sourcePluginId, 'Source');
      expect(remotes.single.url, 'plugin/file/p/remoteEntry.js');
    },
  );

  test('remotes failure and malformed data are not empty success', () async {
    for (final result in [
      null,
      {},
      [1],
      [
        {'name': 'Missing fields'},
      ],
    ]) {
      api.respond = (_, __) async => _response(result);
      await expectLater(
        service.fetchRemotes(service.scope),
        throwsA(isA<Exception>()),
      );
    }
  });

  test(
    'reload uses V2 GET and V3 POST only after method-not-allowed',
    () async {
      api.respond = (_, __) async => _response({'success': true});
      await service.reloadPlugin('P');
      expect(api.calls.map((c) => c.method), ['GET']);
      api.calls.clear();
      api.respond = (method, _) async => method == 'GET'
          ? _response({'detail': 'Method Not Allowed'}, 405)
          : _response({'success': true});
      await service.reloadPlugin('P');
      expect(api.calls.map((c) => c.method), ['GET', 'POST']);
    },
  );

  test('reload does not retry missing plugin or business failure', () async {
    for (final response in [
      _response({}, 404),
      _response({'success': false}),
    ]) {
      api.calls.clear();
      api.respond = (_, __) async => response;
      await expectLater(
        service.reloadPlugin('P'),
        throwsA(isA<PluginManagementException>()),
      );
      expect(api.calls, hasLength(1));
    }
  });
}
