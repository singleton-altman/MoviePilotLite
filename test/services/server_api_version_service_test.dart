import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/services/api_client.dart';
import 'package:moviepilot_mobile/services/server_api_version_service.dart';

class _Api implements ApiClient {
  @override
  String? baseUrl = 'https://server.example';
  @override
  String? token = 'initial-token';
  int calls = 0;
  final paths = <String>[];
  final tokens = <String?>[];
  Future<Response<dynamic>> Function()? action;

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
    calls++;
    paths.add(path);
    tokens.add(token);
    expect(skipV3EnvelopeUnwrap, isTrue);
    expect(skipUnauthorizedHandling, isTrue);
    return (await action!()) as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Response<dynamic> _reply(dynamic data, [int status = 200]) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/api/v1/media/source'),
  statusCode: status,
  data: data,
);

void main() {
  test(
    'V2 missing media source is cached without probing discover/source',
    () async {
      final api = _Api()
        ..action = () async => _reply({'detail': 'Not found'}, 404);
      final service = ServerApiVersionService(apiClient: api);
      expect(await service.isV3(), isFalse);
      expect(await service.isV3(), isFalse);
      expect(api.calls, 1);
      expect(api.paths, ['https://server.example/api/v1/media/source']);
    },
  );

  test('accepts bare and enveloped V3 source lists', () async {
    for (final data in [
      [
        {'media_source': 'themoviedb'},
      ],
      {
        'success': true,
        'data': [
          {'name': 'themoviedb'},
        ],
      },
    ]) {
      final api = _Api()..action = () async => _reply(data);
      final service = ServerApiVersionService(apiClient: api);
      expect(await service.isV3(), isTrue);
      expect(await service.mediaSourceValues(), {'themoviedb'});
      expect(api.calls, 1);
    }
  });

  test('transient and business failures do not cache a V2 verdict', () async {
    for (final data in [
      _reply({'success': false, 'data': []}),
      _reply({'unexpected': true}),
      _reply(null, 503),
    ]) {
      final api = _Api()..action = () async => data;
      final service = ServerApiVersionService(apiClient: api);
      expect(await service.mediaSourceValues(), isNull);
      api.action = () async => _reply([
        {'source': 'themoviedb'},
      ]);
      expect(await service.isV3(), isTrue);
      expect(api.calls, 2);
    }
  });

  test(
    'single-flights probes and keeps learned search mode endpoint-local',
    () async {
      final pending = Completer<Response<dynamic>>();
      final api = _Api()..action = () => pending.future;
      final service = ServerApiVersionService(apiClient: api);
      final first = service.mediaSourceValues();
      final second = service.mediaSourceValues();
      expect(api.calls, 1);
      pending.complete(_reply(null, 404));
      expect(await first, isEmpty);
      expect(await second, isEmpty);
      service.markSearchNeedsMediaSource(true);
      expect(service.searchNeedsMediaSource, isTrue);
      expect(await service.isV3(), isFalse);
      service.invalidate(api.baseUrl);
      expect(service.searchNeedsMediaSource, isNull);
    },
  );

  test(
    'pins captured server url and token, discards stale result on switch',
    () async {
      final pending = Completer<Response<dynamic>>();
      final api = _Api()..action = () => pending.future;
      final service = ServerApiVersionService(apiClient: api);
      final first = service.mediaSourceValues();
      // 模拟探测在途时切换服务器:旧响应不得写入旧 baseUrl 缓存,
      // 请求必须钉住捕获时的绝对地址与 token,而不是发往新作用域。
      api.baseUrl = 'https://other.example';
      pending.complete(
        _reply([
          {'media_source': 'themoviedb'},
        ]),
      );
      expect(await first, isNull);
      expect(api.paths.first, 'https://server.example/api/v1/media/source');
      expect(api.tokens.first, 'initial-token');
      // 切回原服务器重新探测,命中该作用域并正常缓存。
      api.baseUrl = 'https://server.example';
      api.action = () async => _reply([
        {'source': 'themoviedb'},
      ]);
      expect(await service.mediaSourceValues(), {'themoviedb'});
      expect(api.calls, 2);
      expect(await service.isV3(), isTrue);
      expect(api.calls, 2);
    },
  );
}
