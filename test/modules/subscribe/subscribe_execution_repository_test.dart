import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/subscribe/controllers/subscribe_execution_repository.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class _Call {
  _Call(this.method, this.path, this.query);
  final String method;
  final String path;
  final Map<String, dynamic>? query;
}

/// 只实现本仓库用到的接口，其余经 noSuchMethod 显式失败
class _Api implements ApiClient {
  final calls = <_Call>[];
  Object? getResponse;
  List<String>? streamLinesPayload;

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
    calls.add(_Call('GET', path, queryParameters));
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: getResponse as T?,
    );
  }

  @override
  Future<Stream<String>> streamLines(
    String path, {
    String? token,
    int? timeout,
    Map<String, dynamic>? headers,
    bool handleAuth = true,
  }) async {
    calls.add(_Call('STREAM', path, null));
    return Stream.fromIterable(streamLinesPayload ?? const <String>[]);
  }

  @override
  Future<Response<T>> put<T>(
    String path,
    Map<String, dynamic>? data, {
    Map<String, dynamic>? queryParameters,
    String? token,
    Map<String, dynamic>? headers,
  }) async {
    calls.add(_Call('PUT', path, queryParameters));
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: <String, dynamic>{'success': true, 'message': ''} as T,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SubscribeExecutionRepository _repo(_Api api) {
  Get.put(AppLog());
  return SubscribeExecutionRepository(apiClient: api);
}

void main() {
  setUp(() {
    Get.reset();
    Get.put(AppLog());
  });

  group('fetchLogs 契约', () {
    test('length=-1 请求纯文本接口并把倒序文本翻转回时间正序', () async {
      final api = _Api()
        ..getResponse = '第一行\n第二行\n第三行\n';
      final repo = _repo(api);

      final text = await repo.fetchLogs(9, length: -1);

      final call = api.calls.single;
      expect(call.method, 'GET');
      expect(call.path, '/api/v1/subscribe/9/logs');
      expect(call.query?['length'], -1);
      expect(text, '第三行\n第二行\n第一行');
    });

    test('固定行数走 SSE 快照：解析 data 帧，心跳后停止', () async {
      final api = _Api()
        ..streamLinesPayload = <String>[
          'data: 尾部-1',
          'data: 尾部-2',
          '',
          ': keepalive',
          '',
          'data: 不应到达',
          '',
        ];
      final repo = _repo(api);

      final text = await repo.fetchLogs(9, length: 100);

      expect(api.calls.single.path, '/api/v1/subscribe/9/logs?length=100');
      expect(text, '尾部-1\n尾部-2');
    });

    test('日志尚未生成时只有心跳，兜底返回空文本', () async {
      final api = _Api()
        ..streamLinesPayload = <String>[': keepalive', '', ': keepalive', ''];
      final repo = _repo(api);

      final text = await repo.fetchLogs(9, length: 100);

      expect(text, isEmpty);
    });
  });

  group('fetchActivity / fetchActivityEvent / batches / cancel 契约', () {
    test('活动列表请求携带 history/kind/before/limit', () async {
      final api = _Api()
        ..getResponse = <String, dynamic>{
          'items': [
            {
              'event_id': 'e1',
              'kind': 'search',
              'source': 'user',
              'status': 'completed',
              'started_at': '2026-10-21T08:00:00Z',
            },
          ],
          'next_cursor': 'c2',
        };
      final repo = _repo(api);

      final page = await repo.fetchActivity(
        5,
        history: true,
        kind: 'search',
        before: 'c1',
        limit: 30,
      );

      final call = api.calls.single;
      expect(call.path, '/api/v1/subscribe/5/activity');
      expect(call.query, {
        'history': true,
        'kind': 'search',
        'before': 'c1',
        'limit': 30,
      });
      expect(page.items.single.eventId, 'e1');
      expect(page.nextCursor, 'c2');
    });

    test('活动详情请求携带 history', () async {
      final api = _Api()
        ..getResponse = <String, dynamic>{
          'event_id': 'e1',
          'kind': 'completed',
          'source': 'automatic',
          'status': 'completed',
          'started_at': '2026-10-21T08:00:00Z',
          'details_loaded': true,
        };
      final repo = _repo(api);

      final event = await repo.fetchActivityEvent(5, 'e1', history: false);

      expect(api.calls.single.path, '/api/v1/subscribe/5/activity/e1');
      expect(api.calls.single.query, {'history': false});
      expect(event.kind, 'completed');
    });

    test('批次列表解析与取消请求路径', () async {
      final api = _Api()
        ..getResponse = <Object?>[
          <String, dynamic>{
            'batch_id': 'batch-1',
            'source': 'automatic',
            'state': 'running',
            'phase': 'matching',
            'total_count': 2,
            'processed_count': 1,
            'finished_count': 0,
            'failed_count': 0,
            'cancelled_count': 0,
            'created_at': '2026-10-21T08:00:00Z',
            'updated_at': '2026-10-21T08:01:00Z',
            'can_cancel': true,
          },
        ];
      final repo = _repo(api);

      final batches = await repo.fetchBatches(limit: 10);
      expect(api.calls.single.query, {'limit': 10});
      expect(batches.single.isActive, isTrue);

      final result = await repo.cancelBatch('batch-1');
      final putCall = api.calls.last;
      expect(putCall.method, 'PUT');
      expect(putCall.path, '/api/v1/subscribe/execution/batches/batch-1/cancel');
      expect(result.ok, isTrue);
    });

    test('HTTP 错误抛出 StateError 携带状态码', () async {
      final failing = _FailingApi(status: 404);
      final repo = _repo(failing);

      await expectLater(
        repo.fetchActivity(5, history: false),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('404'),
          ),
        ),
      );
    });
  });
}

class _FailingApi extends _Api {
  _FailingApi({required this.status});
  final int status;

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
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
    );
  }
}
