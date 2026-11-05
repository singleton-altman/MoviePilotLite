import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviepilot_mobile/applog/app_log.dart';
import 'package:moviepilot_mobile/modules/media_organize/services/transfer_assist_service.dart';
import 'package:moviepilot_mobile/services/api_client.dart';

class _Api extends Fake implements ApiClient {
  dynamic body;
  int status = 200;
  final calls = <({String method, String path, Map<String, dynamic>? data})>[];
  bool? skippedUnwrap;
  Object? error;

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
    calls.add((method: 'POST', path: path, data: data));
    if (error != null) throw error!;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
      data: body as T,
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
    calls.add((method: 'GET', path: path, data: null));
    skippedUnwrap = skipV3EnvelopeUnwrap;
    if (error != null) throw error!;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: status,
      data: body as T,
    );
  }
}

void main() {
  late _Api api;
  late TransferAssistService service;
  const file = {'path': '/downloads/show', 'storage': 'local', 'type': 'dir'};
  const target = {
    'target_storage': 'local',
    'target_path': '/media/tv',
    'transfer_type': 'copy',
    'scrape': false,
    'library_type_folder': true,
    'library_category_folder': false,
  };

  setUp(() {
    api = _Api();
    service = TransferAssistService(apiClient: api, log: AppLog());
  });

  test('target response is a single configuration, not a list', () async {
    api.body = {'success': true, 'data': target};
    final result = await service.matchTargetPath(
      fileitem: file,
      targetStorage: 'local',
    );
    expect(result.ok, isTrue);
    expect(result.target, target);
    expect(api.calls.single.method, 'POST');
    expect(api.calls.single.path, '/api/v1/transfer/manual/target-path');
    expect(api.calls.single.data, {
      'fileitem': file,
      'target_storage': 'local',
    });
  });

  test('v3 object unwrapped by ApiClient retains envelope data', () async {
    api.body = {...target, 'success': true, 'message': null, 'data': target};
    expect((await service.matchTargetPath(fileitem: file)).target, target);
  });

  test('null target represents no matching configuration', () async {
    api.body = {
      'success': true,
      'data': {
        'target_storage': null,
        'target_path': null,
        'scrape': false,
        'library_type_folder': false,
        'library_category_folder': false,
      },
    };
    final result = await service.matchTargetPath(fileitem: file);
    expect(result.ok, isTrue);
    expect(result.target!['target_path'], isNull);
  });

  test('history is a count/reorganize summary, never records', () async {
    api.body = {
      'success': true,
      'data': {'history_count': 3, 'reorganize': true},
    };
    final result = await service.fetchManualHistory(file);
    expect(result.ok, isTrue);
    expect(result.historyCount, 3);
    expect(result.reorganize, isTrue);
    expect(api.calls.single.path, '/api/v1/transfer/manual/history');
    expect(api.calls.single.data, {'fileitem': file});
  });

  test(
    'history business failure must not turn into an empty history',
    () async {
      api.body = {'success': false, 'message': '拒绝访问', 'data': null};
      final result = await service.fetchManualHistory(file);
      expect(result.ok, isFalse);
      expect(result.historyCount, isNull);
      expect(result.message, '拒绝访问');
    },
  );

  test(
    'recommendation uses episode_format plus rule/sample metadata',
    () async {
      const recommendation = {
        'episode_format': '{ep}',
        'rule_name': '智能分析',
        'sample_file': 'show.01.mkv',
        'confidence': 'high',
      };
      api.body = {'success': true, 'data': recommendation};
      final result = await service.recommendEpisodeFormat(file);
      expect(result.ok, isTrue);
      expect(result.recommendation, recommendation);
      expect(
        api.calls.single.path,
        '/api/v1/transfer/episode-format/recommend',
      );
      expect(api.calls.single.data, {'fileitem': file});
    },
  );

  test('do not guess recommendation field aliases', () async {
    api.body = {
      'success': true,
      'data': {'format': 'wrong', 'template': 'wrong'},
    };
    expect((await service.recommendEpisodeFormat(file)).ok, isFalse);
  });

  test('malformed successful responses fail closed', () async {
    for (final body in [
      null,
      '<html>error</html>',
      {'data': target},
      {'success': true, 'data': []},
      {
        'success': true,
        'data': {'target_path': 123},
      },
    ]) {
      api.body = body;
      expect((await service.matchTargetPath(fileitem: file)).ok, isFalse);
    }
    api.body = {
      'success': true,
      'data': {'history_count': '3', 'reorganize': true},
    };
    expect((await service.fetchManualHistory(file)).ok, isFalse);
  });

  test('non-2xx and transport failures are reported', () async {
    for (final status in [0, 302, 403, 404, 500]) {
      api.status = status;
      api.body = {'success': true, 'data': target};
      expect((await service.matchTargetPath(fileitem: file)).ok, isFalse);
    }
    api.error = Exception('offline');
    expect((await service.fetchManualHistory(file)).ok, isFalse);
  });

  test(
    'AI capability comes from the current published POST contract',
    () async {
      api.body = {
        'paths': {
          TransferAssistService.aiRedoEndpoint: {'post': {}},
        },
      };
      expect(await service.supportsAiRedo(), isTrue);
      expect(api.calls.single.path, '/api/v1/openapi.json');
      expect(api.skippedUnwrap, isTrue);
      api.body = {
        'paths': {
          TransferAssistService.aiRedoEndpoint: {'get': {}},
        },
      };
      expect(await service.supportsAiRedo(), isFalse);
      api.status = 404;
      expect(await service.supportsAiRedo(), isFalse);
      api.error = Exception('offline');
      expect(await service.supportsAiRedo(), isFalse);
    },
  );

  test(
    'AI redo posts unique history_ids and retains progress receipt',
    () async {
      api.body = {
        'success': true,
        'data': {
          'progress_key': 'ai_redo_batch_1',
          'history_ids': [7, 8],
        },
      };
      final result = await service.aiRedoTransfer([7, 7, 8]);
      expect(result.ok, isTrue);
      expect(result.progressKey, 'ai_redo_batch_1');
      expect(api.calls.single.path, TransferAssistService.aiRedoEndpoint);
      expect(api.calls.single.data, {
        'history_ids': [7, 8],
      });
    },
  );

  test(
    'AI rejects invalid IDs before any request and requires a receipt',
    () async {
      for (final ids in <List<int>>[
        [],
        [0],
        [-1],
        [1, 0],
      ]) {
        expect((await service.aiRedoTransfer(ids)).ok, isFalse);
      }
      expect(api.calls, isEmpty);
      api.body = {'success': true, 'data': {}};
      expect((await service.aiRedoTransfer([1])).ok, isFalse);
      api.body = {'success': false, 'message': '智能助手未启用'};
      expect((await service.aiRedoTransfer([1])).message, '智能助手未启用');
    },
  );
}
